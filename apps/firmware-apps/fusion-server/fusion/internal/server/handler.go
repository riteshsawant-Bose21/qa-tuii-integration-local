package server

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/hashicorp/memberlist"
)

// Handler is the common handler for both UDP and HTTP servers.
type Handler struct {
	stateManager *StateManager
	persistence  *ConfigPersistence
	list         *memberlist.Memberlist
	broadcasters []Broadcaster
	updater      *Updater
	endpoints    []string
}

func NewHandler(list *memberlist.Memberlist, stateManager *StateManager,
	persistence *ConfigPersistence, updater *Updater) *Handler {
	return &Handler{
		stateManager: stateManager,
		persistence:  persistence,
		list:         list,
		updater:      updater,
	}
}

// broadcastToNodes sends the given JSON message to all nodes except the local one.
func (h *Handler) broadcastToNodes(messageData []byte) {
	logger := logging.GetLogger()
	for _, node := range h.list.Members() {
		if node.Name == h.list.LocalNode().Name {
			continue
		}
		if err := h.list.SendReliable(node, messageData); err != nil {
			logger.Error("Failed to send message to node %s: %v", node.Name, err)
		}
	}
}

func (h *Handler) handleConfigUpdate(data map[string]any) error {
	update := api.ConfigUpdate{
		Data:    data,
		Version: time.Now().UnixNano(),
		NodeID:  h.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	return h.broadcastUpdate(update)
}

func (h *Handler) handleSnapshotOperation(name string, op api.SnapshotOp, data map[string]any) error {
	snapshotUpdate := api.SnapshotUpdate{
		Op:        op,
		Name:      name,
		Data:      data,
		Node:      h.list.LocalNode().Name,
		Timestamp: time.Now().UTC(),
	}

	return h.broadcastSnapshotUpdate(snapshotUpdate)
}

func (h *Handler) transformState(state map[string]*api.StateEntry) map[string]any {
	result := make(map[string]any)
	for key, entry := range state {
		result[key] = entry.Data
	}
	return result
}

func (h *Handler) broadcastUpdate(update api.ConfigUpdate) error {
	logger := logging.GetLogger()

	if err := h.stateManager.ApplyUpdate(update); err != nil {
		return fmt.Errorf("failed to apply update: %w", err)
	}

	// Mark state as dirty so it will be persisted.
	h.persistence.MarkDirty()

	// Prepare state entries for broadcast.
	state := make(map[string]*api.StateEntry)
	for k, v := range update.Data {
		state[k] = &api.StateEntry{
			Data:      v,
			Version:   update.Version,
			Timestamp: update.Time,
		}
	}

	// If this is the originating node, broadcast to other nodes.
	if update.NodeID == h.list.LocalNode().Name {
		data, err := json.Marshal(update)
		if err != nil {
			return fmt.Errorf("failed to marshal update: %w", err)
		}
		h.broadcastToNodes(data)
	}

	// Always broadcast update to local clients.
	transformed := TransformState(state)
	for _, broadcaster := range h.broadcasters {
		if err := broadcaster.BroadcastUpdate(transformed); err != nil {
			logger.Error("Failed to broadcast update to local clients: %v", err)
		}
	}

	return nil
}

func (h *Handler) broadcastSnapshotUpdate(snapshotUpdate api.SnapshotUpdate) error {
	bytes, err := json.Marshal(snapshotUpdate)
	if err != nil {
		return fmt.Errorf("failed to marshal snapshot update: %w", err)
	}

	h.broadcastToNodes(bytes)
	return nil
}

func (h *Handler) SetEndpoints(endpoints []string) {
	h.endpoints = endpoints
}

func (h *Handler) GetInitialState() (WebSocketResponse, error) {
	data := h.transformState(h.stateManager.GetFullState())
	return WebSocketResponse{
		Type: "initial_state",
		Data: data,
	}, nil
}

func (h *Handler) HandleHTTPGet(key string) (any, error) {
	if key != "" {
		value, exists := h.stateManager.Get(key)
		if !exists {
			return map[string]any{
				"exists": false,
				"error":  "key not found",
			}, nil
		}
		return map[string]any{
			"exists": true,
			"value":  value,
		}, nil
	}

	state := h.transformState(h.stateManager.GetFullState())
	return state, nil
}

// HandleHTTPSet replaces the entire configuration state with the new data.
func (h *Handler) HandleHTTPSet(update map[string]any) (any, error) {
	// Clear all existing data before applying the update.
	h.HandleClearAllData()

	if err := h.handleConfigUpdate(update); err != nil {
		return nil, fmt.Errorf("failed to handle update: %w", err)
	}

	return map[string]any{
		"status":  "success",
		"updates": update,
	}, nil
}

// HandleHTTPPatch updates only the specified fields.
func (h *Handler) HandleHTTPPatch(value map[string]any) (any, error) {
	existingData := h.transformState(h.stateManager.GetFullState())
	if err := applyPatch(existingData, value); err != nil {
		return nil, fmt.Errorf("failed to apply patch: %w", err)
	}

	if err := h.handleConfigUpdate(existingData); err != nil {
		return nil, fmt.Errorf("failed to handle update after patch: %w", err)
	}

	return existingData, nil
}

func applyPatch(data map[string]any, changes map[string]any) error {
	for key, value := range changes {
		switch {
		case value == nil:
			removeNestedField(data, key)
		case isMap(value):
			subChanges := value.(map[string]any)
			if subData, ok := getNestedValue(data, key).(map[string]any); ok {
				if err := applyPatch(subData, subChanges); err != nil {
					return err
				}
			} else {
				newSubData := make(map[string]any)
				setNestedValue(data, key, newSubData)
				if err := applyPatch(newSubData, subChanges); err != nil {
					return err
				}
			}
		case isArray(value):
			subArray := value.([]any)
			existingValue := getNestedValue(data, key)
			if _, isExistingArray := existingValue.([]any); isExistingArray && !isIndexedKey(key) {
				setNestedValue(data, key, subArray)
			} else {
				if existingArray, ok := existingValue.([]any); ok {
					for i, v := range subArray {
						if i < len(existingArray) {
							existingArray[i] = v
						} else {
							return fmt.Errorf("index %d out of bounds for array %s", i, key)
						}
					}
					setNestedValue(data, key, existingArray)
				} else {
					setNestedValue(data, key, subArray)
				}
			}
		default:
			if err := updateNestedField(data, key, value); err != nil {
				return err
			}
		}
	}
	return nil
}

func isMap(v any) bool {
	_, ok := v.(map[string]any)
	return ok
}

func isArray(v any) bool {
	_, ok := v.([]any)
	return ok
}

// updateNestedField updates a nested field (supporting array indices) in a map.
func updateNestedField(data map[string]any, key string, value any) error {
	keys := parseKeyPath(key)
	for i := 0; i < len(keys)-1; i++ {
		subKey := keys[i]
		if index, isIndex := parseArrayIndex(subKey); isIndex {
			parentKey := keys[i-1]
			array, ok := data[parentKey].([]any)
			if !ok || index >= len(array) {
				return fmt.Errorf("index %d out of bounds for array %s", index, parentKey)
			}
			nestedMap, ok := array[index].(map[string]any)
			if !ok {
				return fmt.Errorf("expected map at index %d in array %s", index, parentKey)
			}
			data = nestedMap
		} else {
			if _, exists := data[subKey]; !exists {
				data[subKey] = make(map[string]any)
			}
			subData, ok := data[subKey].(map[string]any)
			if !ok {
				return fmt.Errorf("intermediate value for key %s is not a map", subKey)
			}
			data = subData
		}
	}

	finalKey := keys[len(keys)-1]
	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		parentKey := keys[len(keys)-2]
		parentVal, exists := data[parentKey]
		if !exists {
			return fmt.Errorf("parent key %s does not exist", parentKey)
		}
		array, ok := parentVal.([]any)
		if !ok || index >= len(array) {
			return fmt.Errorf("index %d out of bounds for array %s", index, parentKey)
		}
		array[index] = value
	} else {
		data[finalKey] = value
	}
	return nil
}

func removeNestedField(data map[string]any, key string) {
	keys := parseKeyPath(key)
	// Traverse to the parent of the target key.
	for i := 0; i < len(keys)-1; i++ {
		subKey := keys[i]
		if subData, ok := data[subKey].(map[string]any); ok {
			data = subData
		} else {
			return // Key not found or not a map.
		}
	}
	finalKey := keys[len(keys)-1]
	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		if array, ok := data[keys[len(keys)-2]].([]any); ok && index >= 0 && index < len(array) {
			data[keys[len(keys)-2]] = append(array[:index], array[index+1:]...)
		}
	} else if start, end, isSlice := parseArraySlice(finalKey); isSlice {
		if array, ok := data[keys[len(keys)-2]].([]any); ok && start >= 0 && end <= len(array) && start < end {
			data[keys[len(keys)-2]] = append(array[:start], array[end:]...)
		}
	} else {
		delete(data, finalKey)
	}
}

func getNestedValue(data map[string]any, key string) any {
	keys := parseKeyPath(key)
	current := any(data)
	for _, part := range keys {
		switch c := current.(type) {
		case map[string]any:
			val, exists := c[part]
			if !exists {
				return nil
			}
			current = val
		case []any:
			if index, isIndex := parseArrayIndex(part); isIndex {
				if index < 0 || index >= len(c) {
					return nil
				}
				current = c[index]
			} else if start, end, isSlice := parseArraySlice(part); isSlice {
				if start < 0 || end > len(c) || start >= end {
					return nil
				}
				return c[start:end]
			} else {
				return nil
			}
		default:
			return nil
		}
	}
	return current
}

func isIndexedKey(key string) bool {
	keys := parseKeyPath(key)
	lastKey := keys[len(keys)-1]
	_, isIndex := parseArrayIndex(lastKey)
	return isIndex
}

func ensureArrayCapacity(parent map[string]any, parentKey string, index int) {
	existingArray, exists := parent[parentKey].([]any)
	if !exists {
		parent[parentKey] = make([]any, index+1)
		return
	}
	if index < len(existingArray) {
		return
	}
	newArray := make([]any, index+1)
	copy(newArray, existingArray)
	parent[parentKey] = newArray
}

func setNestedValue(data map[string]any, key string, value any) {
	logger := logging.GetLogger()
	keys := parseKeyPath(key)
	current := data
	for i := 0; i < len(keys)-1; i++ {
		subKey := keys[i]
		if index, isIndex := parseArrayIndex(subKey); isIndex {
			if i == 0 {
				logger.Error("Array index cannot be at the root level.")
				return
			}
			parentKey := keys[i-1]
			parentVal, exists := current[parentKey]
			if !exists {
				logger.Warn("Parent key %s does not exist, skipping update.", parentKey)
				return
			}
			if _, ok := parentVal.([]any); !ok {
				logger.Error("Expected an array at key %s but got %T", parentKey, parentVal)
				return
			}
			ensureArrayCapacity(current, parentKey, index)
			arrayRef := current[parentKey].([]any)
			if index >= len(arrayRef) {
				logger.Error("Index %d out of bounds after ensureArrayCapacity", index)
				return
			}
			arrayRef[index] = value
			return
		} else {
			if _, exists := current[subKey]; !exists {
				// Create new container based on the next key.
				nextKey := keys[i+1]
				if _, isNextIndex := parseArrayIndex(nextKey); isNextIndex {
					current[subKey] = make([]any, 0)
				} else {
					current[subKey] = make(map[string]any)
				}
			}
			if subData, ok := current[subKey].(map[string]any); ok {
				current = subData
			} else if _, ok := current[subKey].([]any); ok {
				break
			} else {
				logger.Error("Intermediate value for key %s is not a map", subKey)
				return
			}
		}
	}
	finalKey := keys[len(keys)-1]
	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		parentKey := keys[len(keys)-2]
		parentVal, exists := current[parentKey]
		if !exists {
			logger.Error("Parent key %s does not exist, skipping update.", parentKey)
			return
		}
		if _, ok := parentVal.([]any); !ok {
			logger.Error("Expected an array at key %s but got %T", parentKey, parentVal)
			return
		}
		ensureArrayCapacity(current, parentKey, index)
		arrayRef := current[parentKey].([]any)
		arrayRef[index] = value
	} else {
		current[finalKey] = value
	}
}

func parseArrayIndex(key string) (int, bool) {
	if i, err := strconv.Atoi(key); err == nil {
		return i, true
	}
	return -1, false
}

func parseArraySlice(key string) (int, int, bool) {
	if strings.Contains(key, ":") {
		parts := strings.Split(key, ":")
		start, err1 := strconv.Atoi(parts[0])
		end, err2 := strconv.Atoi(parts[1])
		if err1 == nil && err2 == nil {
			return start, end, true
		}
	}
	return -1, -1, false
}

func parseKeyPath(key string) []string {
	return strings.FieldsFunc(key, func(r rune) bool {
		return r == '.' || r == '[' || r == ']'
	})
}

// UDP Server methods
func (h *Handler) HandleUDPMessage(data []byte) (any, error) {
	var msg struct {
		Action string          `json:"action"`
		Raw    json.RawMessage `json:",omitempty"`
	}

	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid JSON: %w", err)
	}

	switch msg.Action {
	case "get":
		fullState := h.stateManager.GetFullState()
		transformed := TransformState(fullState)
		return map[string]any{
			"status": "success",
			"data":   transformed,
		}, nil

	case "set":
		var update map[string]any
		if err := json.Unmarshal(data, &update); err != nil {
			return nil, fmt.Errorf("invalid JSON: %w", err)
		}
		delete(update, "action")
		if err := h.handleConfigUpdate(update); err != nil {
			return nil, fmt.Errorf("failed to handle update: %w", err)
		}
		return map[string]any{
			"status":  "success",
			"message": "Update applied successfully",
		}, nil

	default:
		return nil, fmt.Errorf("unknown action: %s", msg.Action)
	}
}

func (h *Handler) HandleClearAllData() error {
	configUpdate := api.ConfigUpdate{
		Data:    map[string]any{},
		Version: time.Now().UnixNano(),
		NodeID:  h.list.LocalNode().Name,
		Time:    time.Now().UTC(),
		Clear:   true,
	}

	if err := h.broadcastUpdate(configUpdate); err != nil {
		return fmt.Errorf("failed to clear all data: %w", err)
	}

	if err := h.persistence.SaveState(); err != nil {
		return fmt.Errorf("failed to persist cleared state: %w", err)
	}
	return nil
}

func (s *ConfigServer) ClearAllData(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if err := s.handler.HandleClearAllData(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(map[string]any{
		"status":  "success",
		"message": "All data cleared successfully",
	})
}

func (s *ConfigServer) GetMembers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	members := s.handler.list.Members()
	w.Header().Set(api.ContentType, api.JsonContentType)
	if err := json.NewEncoder(w).Encode(members); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func (h *Handler) HandleWebSocketMessage(data []byte) (*WebSocketResponse, error) {
	var msg WebSocketMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid WebSocket message: %w", err)
	}

	switch msg.Type {
	case "update":
		var updateData map[string]any
		if err := json.Unmarshal(msg.Data, &updateData); err != nil {
			return nil, fmt.Errorf("invalid update in WebSocket message: %w", err)
		}
		if err := h.handleConfigUpdate(updateData); err != nil {
			return nil, fmt.Errorf("failed to handle update: %w", err)
		}
		return &WebSocketResponse{
			Type:    "update_success",
			Status:  "success",
			Message: "Update applied successfully",
		}, nil

	default:
		return nil, fmt.Errorf("unknown WebSocket message type: %s", msg.Type)
	}
}

func (h *Handler) HandleDownload() (map[string]any, error) {
	state := h.transformState(h.stateManager.GetFullState())
	return map[string]any{"state": state}, nil
}

func (h *Handler) GetServerInfo() (map[string]interface{}, error) {
	info := map[string]interface{}{
		"name":               "Fusion Config Server",
		"version":            "1.0.0",
		"node_id":            h.list.LocalNode().Name,
		"endpoints":          h.endpoints,
		"cluster_size":       len(h.list.Members()),
		"update_in_progress": h.updater.currentUpdate != nil,
	}

	if h.updater.currentUpdate != nil {
		info["update_status"] = map[string]interface{}{
			"source_node": h.updater.currentUpdate.NodeID,
			"time":        h.updater.currentUpdate.Time,
			"progress":    float64(h.updater.currentAssembler.received) / float64(h.updater.currentAssembler.size) * 100,
		}
	}
	return info, nil
}

func (h *Handler) AddBroadcaster(broadcaster Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcaster)
}

func (h *Handler) AddBroadcasters(broadcasters ...Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcasters...)
}

func (h *Handler) HandleVersionUpdate(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		logger.Error("Error parsing multipart form: %v", err)
		http.Error(w, "Error parsing form data", http.StatusBadRequest)
		return
	}

	updateFile, header, err := r.FormFile("binary")
	if err != nil {
		logger.Error("Error reading binary: %v", err)
		http.Error(w, "Error reading binary", http.StatusBadRequest)
		return
	}
	defer updateFile.Close()

	if !VerifyChecksum(updateFile, r.FormValue("checksum")) {
		logger.Error("Invalid checksum")
		http.Error(w, "Invalid checksum", http.StatusBadRequest)
		return
	}

	if _, err := updateFile.Seek(0, 0); err != nil {
		logger.Error("Error resetting file pointer: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	tempPath := filepath.Join(os.TempDir(), header.Filename)
	tempFile, err := os.Create(tempPath)
	if err != nil {
		logger.Error("Error creating temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tempFile.Close()

	if _, err := io.Copy(tempFile, updateFile); err != nil {
		logger.Error("Error moving binary to temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if err := h.InitiateVersionUpdate(tempPath); err != nil {
		logger.Error("Failed to initiate cluster update: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	go func() {
		if err := h.updater.PerformUpdate(tempPath); err != nil {
			logger.Error("Update failed: %v", err)
		}
	}()

	w.WriteHeader(http.StatusOK)
}

func (h *Handler) HandleVersionRollback(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	indexStr := r.URL.Query().Get("index")
	if indexStr == "" {
		logger.Error("No rollback index provided")
		http.Error(w, "Rollback index required", http.StatusBadRequest)
		return
	}

	index, err := strconv.Atoi(indexStr)
	if err != nil {
		logger.Error("Invalid rollback index: %v", err)
		http.Error(w, "Invalid rollback index", http.StatusBadRequest)
		return
	}

	if !h.updater.IsValidRollbackIndex(index) {
		logger.Error("Rollback index out of range: %d", index)
		http.Error(w, fmt.Sprintf("Rollback index must be between -%d and -1, got: %d", MaxBackups, index), http.StatusBadRequest)
		return
	}

	currentBinaryPath, err := os.Executable()
	if err != nil {
		logger.Error("Failed to get current binary path: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	if err := h.InitiateBinaryRollback(currentBinaryPath, index); err != nil {
		logger.Error("Failed to initiate cluster rollback: %v", err)
	}

	go func() {
		if err := h.updater.PerformRollback(currentBinaryPath, index); err != nil {
			logger.Error("Rollback failed: %v", err)
		}
	}()

	w.WriteHeader(http.StatusOK)
}

func (h *Handler) InitiateVersionUpdate(newBinaryPath string) error {
	logger := logging.GetLogger()
	hash, size, err := getBinaryMetadata(newBinaryPath)
	if err != nil {
		return fmt.Errorf("failed to get binary metadata: %w", err)
	}

	update := BinaryUpdate{
		BinaryHeader: BinaryHeader{
			NodeID: h.list.LocalNode().Name,
			Time:   time.Now().UTC(),
		},
		BinaryHash: hash,
		BinarySize: size,
	}

	data, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %w", err)
	}

	message := VersionMessage{
		Type:    VersionUpdate,
		Payload: data,
	}

	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	h.broadcastToNodes(messageData)

	// Stream the binary to each node.
	for _, node := range h.list.Members() {
		if node.Name == h.list.LocalNode().Name {
			continue
		}
		if err := h.streamBinaryToNode(node, newBinaryPath); err != nil {
			logger.Error("Failed to stream binary to node %s: %v", node.Name, err)
		}
	}
	return nil
}

func (h *Handler) InitiateBinaryRollback(currentBinaryPath string, index int) error {

	rollback := BinaryRollback{
		BinaryHeader: BinaryHeader{
			NodeID: h.list.LocalNode().Name,
			Time:   time.Now().UTC(),
		},
		BinaryPath: currentBinaryPath,
		Index:      index,
	}

	data, err := json.Marshal(rollback)
	if err != nil {
		return fmt.Errorf("failed to marshal rollback: %w", err)
	}

	message := VersionMessage{
		Type:    VersionRollback,
		Payload: data,
	}

	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	h.broadcastToNodes(messageData)
	return nil
}

func (h *Handler) streamBinaryToNode(node *memberlist.Node, binaryPath string) error {
	const chunkSize = 1024 * 1024 // 1MB
	file, err := os.Open(binaryPath)
	if err != nil {
		return fmt.Errorf("failed to open binary: %w", err)
	}
	defer file.Close()

	buf := make([]byte, chunkSize)
	var offset int64
	for {
		n, err := file.Read(buf)
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("failed to read binary: %w", err)
		}

		chunk := BinaryChunk{
			Data:   buf[:n],
			Offset: offset,
			Final:  false,
		}
		offset += int64(n)

		chunkData, err := json.Marshal(chunk)
		if err != nil {
			return fmt.Errorf("failed to marshal chunk: %w", err)
		}

		message := VersionMessage{
			Type:    UpdateChunk,
			Payload: chunkData,
		}
		messageData, err := json.Marshal(message)
		if err != nil {
			return fmt.Errorf("failed to marshal message: %w", err)
		}

		if err := h.list.SendReliable(node, messageData); err != nil {
			return fmt.Errorf("failed to send chunk message: %w", err)
		}
	}

	finalChunk := BinaryChunk{
		Data:   nil,
		Offset: offset,
		Final:  true,
	}
	chunkData, err := json.Marshal(finalChunk)
	if err != nil {
		return fmt.Errorf("failed to marshal final chunk: %w", err)
	}

	message := VersionMessage{
		Type:    UpdateChunk,
		Payload: chunkData,
	}
	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal final message: %w", err)
	}
	if err := h.list.SendReliable(node, messageData); err != nil {
		return fmt.Errorf("failed to send final chunk message: %w", err)
	}

	return nil
}

func (h *Handler) HandleAudioUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		logger.Error("Error parsing multipart form: %v", err)
		http.Error(w, "Error parsing form data", http.StatusBadRequest)
		return
	}

	audioFile, header, err := r.FormFile("binary")
	if err != nil {
		logger.Error("Error reading binary: %v", err)
		http.Error(w, "Error reading binary", http.StatusBadRequest)
		return
	}
	defer audioFile.Close()

	destDir := "/var/lib/fusion/audio"
	destPath := filepath.Join(destDir, header.Filename)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		logger.Error("Error creating destination directory: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	dstFile, err := os.Create(destPath)
	if err != nil {
		logger.Error("Error creating destination file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer dstFile.Close()

	if _, err := io.Copy(dstFile, audioFile); err != nil {
		logger.Error("Error copying file to destination: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	existingData := h.transformState(h.stateManager.GetFullState())
	addAudioFilesToConfig(destDir, existingData)
	if err := h.handleConfigUpdate(existingData); err != nil {
		logger.Error("Failed to handle audio config update: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}

func (h *Handler) HandleListSnapshots() ([]string, error) {
	return h.persistence.ListSnapshots()
}

func (h *Handler) HandleCreateSnapshot(name string) error {
	if err := h.persistence.SaveSnapshot(name); err != nil {
		return fmt.Errorf("failed to create snapshot: %w", err)
	}

	data := h.transformState(h.stateManager.GetFullState())
	if err := h.handleSnapshotOperation(name, api.SnapshotOpCreate, data); err != nil {
		return fmt.Errorf("failed to handle snapshot update: %w", err)
	}
	return nil
}

func (h *Handler) HandleActivateSnapshot(name string) error {
	if err := h.persistence.ActivateSnapshot(name); err != nil {
		return fmt.Errorf("failed to activate snapshot: %w", err)
	}
	if err := h.handleSnapshotOperation(name, api.SnapshotOpActivate, nil); err != nil {
		return fmt.Errorf("failed to handle snapshot activate: %w", err)
	}
	return nil
}

func (h *Handler) HandleDeleteSnapshot(name string) error {
	if err := h.persistence.DeleteSnapshot(name); err != nil {
		return fmt.Errorf("failed to delete snapshot: %w", err)
	}
	if err := h.handleSnapshotOperation(name, api.SnapshotOpDelete, nil); err != nil {
		return fmt.Errorf("failed to handle snapshot delete: %w", err)
	}
	return nil
}

func (h *Handler) HandleSnapshotExists(name string) (bool, error) {
	return h.persistence.SnapshotExists(name)
}

func (h *Handler) HandleGetSnapshotMetadata() (api.SnapshotMetadata, error) {
	return h.persistence.GetSnapshotMetadata()
}

func getBinaryMetadata(path string) (hash string, size int64, err error) {
	file, err := os.Open(path)
	if err != nil {
		return "", 0, err
	}
	defer file.Close()

	hasher := sha256.New()
	size, err = io.Copy(hasher, file)
	if err != nil {
		return "", 0, err
	}
	return hex.EncodeToString(hasher.Sum(nil)), size, nil
}

func addAudioFilesToConfig(audioDir string, existingData map[string]any) {
	entries, err := os.ReadDir(audioDir)
	if err != nil {
		log.Printf("Error reading directory %s: %v", audioDir, err)
		return
	}
	var fileNames []string
	for _, entry := range entries {
		if !entry.IsDir() {
			fileNames = append(fileNames, entry.Name())
		}
	}
	existingData["audio_files"] = map[string]any{
		"location": audioDir,
		"files":    fileNames,
	}
}
