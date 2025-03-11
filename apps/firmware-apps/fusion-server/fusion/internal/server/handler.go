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
	"go.etcd.io/bbolt"
)

// Common handler for both UDP and HTTP servers
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

// Shared update handling logic
func (h *Handler) handleConfigUpdate(data map[string]any) error {
	configUpdate := api.ConfigUpdate{
		Data:    data,
		Version: time.Now().UnixNano(),
		NodeID:  h.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	return h.broadcastUpdate(configUpdate)
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
		return fmt.Errorf("failed to apply update: %v", err)
	}

	// Always persist state changes, regardless of source
	h.persistence.MarkDirty()

	// Transform state for broadcasting
	state := make(map[string]*api.StateEntry)
	for k, v := range update.Data {
		state[k] = &api.StateEntry{
			Data:      v,
			Version:   update.Version,
			Timestamp: update.Time,
		}
	}

	// Only broadcast to other nodes if we're the origin
	if update.NodeID == h.list.LocalNode().Name {
		// Broadcast to cluster members
		data, err := json.Marshal(update)
		if err != nil {
			return fmt.Errorf("failed to marshal update: %v", err)
		}

		for _, node := range h.list.Members() {
			if node.Name != h.list.LocalNode().Name {
				if err := h.list.SendReliable(node, data); err != nil {
					logger.Error("Failed to send to node %s: %v", node.Name, err)
				}
			}
		}
	}

	transformed := TransformState(state)

	// Always broadcast to local clients
	for _, broadcaster := range h.broadcasters {
		if err := broadcaster.BroadcastUpdate(transformed); err != nil {
			logger.Error("Failed to broadcast update: %v", err)
		}
	}

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

// HandleHTTPSet will replace existing values with the updated values.
// A PUT request is idempotent and is intended to fully replace the
// resource at the target URI with the data provided in the request body.
func (h *Handler) HandleHTTPSet(update map[string]any) (any, error) {

	h.HandleClearAllData()

	if err := h.handleConfigUpdate(update); err != nil {
		return nil, fmt.Errorf("failed to handle update: %v", err)
	}

	return map[string]any{
		"status":  "success",
		"updates": update,
	}, nil
}

// HandleHTTPPatch will update existing values, add new values and remove values
// that are null.
func (h *Handler) HandleHTTPPatch(value map[string]any) (any, error) {

	existingData := h.transformState(h.stateManager.GetFullState())

	applyPatch(existingData, value)

	if err := h.handleConfigUpdate(existingData); err != nil {
		return nil, fmt.Errorf("failed to handle update: %v", err)
	}

	return existingData, nil
}

func applyPatch(data map[string]any, changes map[string]any) error {
	for key, value := range changes {
		if value == nil {
			removeNestedField(data, key)
		} else if subChanges, ok := value.(map[string]any); ok {
			if subData, exists := getNestedValue(data, key).(map[string]any); exists {
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
		} else if subArray, ok := value.([]any); ok {
			existingValue := getNestedValue(data, key)

			if _, isExistingArray := existingValue.([]any); isExistingArray && !isIndexedKey(key) {
				setNestedValue(data, key, subArray)
			} else {
				existingArray, exists := existingValue.([]any)
				if exists {
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
		} else {
			if err := updateNestedField(data, key, value); err != nil {
				return err
			}
		}
	}
	return nil
}

// updateNestedField updates a nested value in a map, supporting array indexing and slicing
func updateNestedField(data map[string]any, key string, value any) error {
	keys := parseKeyPath(key)

	for i := range len(keys) - 1 {
		subKey := keys[i]

		if index, isIndex := parseArrayIndex(subKey); isIndex {
			parentKey := keys[i-1]
			if array, ok := data[parentKey].([]any); ok {
				if index >= len(array) {
					return fmt.Errorf("index %d out of bounds for array %s", index, parentKey)
				}
				if nestedMap, isMap := array[index].(map[string]any); isMap {
					data = nestedMap
				} else {
					return fmt.Errorf("expected map at index %d in array %s", index, parentKey)
				}
			} else {
				return fmt.Errorf("expected array at key %s", parentKey)
			}
		} else {
			if _, exists := data[subKey]; !exists {
				data[subKey] = make(map[string]any)
			}
			if subData, ok := data[subKey].(map[string]any); ok {
				data = subData
			} else {
				return fmt.Errorf("intermediate value for key %s is not a map", subKey)
			}
		}
	}

	finalKey := keys[len(keys)-1]

	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		parentKey := keys[len(keys)-2]
		parentVal, exists := data[parentKey]

		if !exists {
			return fmt.Errorf("parent key %s does not exist", parentKey)
		}

		array, isArray := parentVal.([]any)
		if !isArray {
			return fmt.Errorf("expected an array at key %s but found %T", parentKey, parentVal)
		}

		if index >= len(array) {
			return fmt.Errorf("index %d out of bounds for array %s", index, parentKey)
		}

		array[index] = value
	} else {
		data[finalKey] = value
	}

	return nil
}

// Helper function to remove a nested field, including array elements and slices
func removeNestedField(data map[string]any, key string) {
	keys := parseKeyPath(key)

	// Traverse to the last key before deletion
	for i := range len(keys) - 1 {
		subKey := keys[i]
		if subData, ok := data[subKey].(map[string]any); ok {
			data = subData
		} else {
			return // Key not found
		}
	}

	finalKey := keys[len(keys)-1]

	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		if array, ok := data[keys[len(keys)-2]].([]any); ok {
			if index >= 0 && index < len(array) {
				data[keys[len(keys)-2]] = append(array[:index], array[index+1:]...)
			}
		}
	} else if start, end, isSlice := parseArraySlice(finalKey); isSlice {
		if array, ok := data[keys[len(keys)-2]].([]any); ok {
			if start >= 0 && end <= len(array) && start < end {
				data[keys[len(keys)-2]] = append(array[:start], array[end:]...)
			}
		}
	} else {
		// Normal field removal
		delete(data, finalKey)
	}
}

// getNestedValue retrieves a nested value from a map[string]any, supporting arrays and slices.
func getNestedValue(data map[string]any, key string) any {
	keys := parseKeyPath(key)

	var current any = data

	for _, part := range keys {
		switch c := current.(type) {
		case map[string]any:
			// Traverse into the map
			if val, exists := c[part]; exists {
				current = val
			} else {
				// Key not found
				return nil
			}
		case []any:
			// Handle array indexing and slicing
			if index, isIndex := parseArrayIndex(part); isIndex {
				if index >= 0 && index < len(c) {
					current = c[index]
				} else {
					// Out of bounds index
					return nil
				}
			} else if start, end, isSlice := parseArraySlice(part); isSlice {
				if start >= 0 && end <= len(c) && start < end {
					return c[start:end] // Return the slice
				}
				// Invalid slice range
				return nil
			} else {
				// Invalid key for an array
				return nil
			}
		default:
			// Unexpected type (not a map or slice)
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
		newArray := make([]any, index+1)
		parent[parentKey] = newArray
		return
	}

	if index < len(existingArray) {
		return
	}

	// Expand array while keeping existing values
	newArray := make([]any, index+1)
	copy(newArray, existingArray) // Preserve existing values

	parent[parentKey] = newArray
}

func setNestedValue(data map[string]any, key string, value any) {

	logger := logging.GetLogger()

	keys := parseKeyPath(key)
	current := data

	// Traverse the path and ensure maps/arrays exist
	for i := range len(keys) - 1 {
		subKey := keys[i]

		// Detecting an array key
		if index, isIndex := parseArrayIndex(subKey); isIndex {
			if i == 0 {
				logger.Error("Array index cannot be at root level.")
				return
			}

			parentKey := keys[i-1]
			parentVal, exists := current[parentKey]

			if !exists {
				logger.Warn("Parent key does not exist, skipping update.")
				return
			}

			// Check if an array already exists before creating a new one
			if _, isArray := parentVal.([]any); !isArray {
				logger.Error("Expected an array at key %s but found %T", parentKey, fmt.Sprintf("%T", parentVal))
				return
			}

			ensureArrayCapacity(current, parentKey, index)

			arrayRef := current[parentKey].([]any)

			if index >= len(arrayRef) {
				logger.Error("Index out of bounds after ensureArrayCapacity %d", index)
				return
			}

			arrayRef[index] = value
			return
		} else {
			// Ensure key exists and check its type
			existingValue, exists := current[subKey]

			// If the key exists, ensure we don't replace an existing array
			if exists {
				switch existingValue.(type) {
				case []any, map[string]any:
					// Value is already an array or a map, proceed
				default:
					logger.Error("Key %s exists but is not a map or array. Found %T", subKey, existingValue)
					return
				}
			} else {
				// Key does not exist, create a new structure
				nextKey := keys[i+1]
				if nextIndex, isIndex := parseArrayIndex(nextKey); isIndex {
					// Only create a new array if it doesn't exist
					if _, alreadyExists := current[subKey]; !alreadyExists {
						current[subKey] = make([]any, nextIndex+1)
					}
				} else {
					current[subKey] = make(map[string]any)
				}
			}

			// Move to the next level
			if subData, ok := current[subKey].(map[string]any); ok {
				current = subData
			} else if _, isArray := current[subKey].([]any); isArray {
				break
			} else {
				logger.Error("Intermediate value for key %s is not a map. Found %T", subKey, fmt.Sprintf("%T", current[subKey]))
				return
			}
		}
	}

	// Final key update
	finalKey := keys[len(keys)-1]
	if index, isIndex := parseArrayIndex(finalKey); isIndex {
		parentKey := keys[len(keys)-2]
		parentVal, exists := current[parentKey]

		if !exists {
			logger.Error("Parent key does not exist, skipping update.")
			return
		}

		_, isArray := parentVal.([]any)
		if !isArray {
			logger.Error("Expected an array at key %s but found %T", parentKey, fmt.Sprintf("%T", parentVal))
			return
		}

		ensureArrayCapacity(current, parentKey, index)

		arrayRef := current[parentKey].([]any)
		arrayRef[index] = value

	} else {
		current[finalKey] = value
	}
}

// Utility function to parse array indices (e.g., "3")
func parseArrayIndex(key string) (int, bool) {
	if i, err := strconv.Atoi(key); err == nil {
		return i, true
	}
	return -1, false
}

// Utility function to parse array slices (e.g., "1:3")
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

// Utility function to parse key paths, handling dots and array brackets
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
		return nil, fmt.Errorf("invalid JSON: %v", err)
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
			return nil, fmt.Errorf("invalid JSON: %v", err)
		}
		delete(update, "action")

		if err := h.handleConfigUpdate(update); err != nil {
			return nil, fmt.Errorf("failed to handle update: %v", err)
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
		return fmt.Errorf("failed to clear all data: %v", err)
	}

	// Ensure the cleared state is persisted
	if err := h.persistence.SaveState(); err != nil {
		return fmt.Errorf("failed to persist cleared state: %v", err)
	}

	return nil
}

// HTTP handler in ConfigServer that uses it:
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

func (h *Handler) HandleDumpState() (map[string]any, error) {
	return map[string]any{
		"state": h.stateManager.GetFullState(),
	}, nil
}

// HandleWebSocketMessage handles incoming websocket messages
func (h *Handler) HandleWebSocketMessage(data []byte) (*WebSocketResponse, error) {
	var msg WebSocketMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid WebSocket message: %v", err)
	}

	switch msg.Type {
	case "update":
		var data map[string]any
		if err := json.Unmarshal(msg.Data, &data); err != nil {
			return nil, fmt.Errorf("invalid update in WebSocket message: %v", err)
		}

		if err := h.handleConfigUpdate(data); err != nil {
			return nil, fmt.Errorf("failed to handle update: %v", err)
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

// HandleDownload handles the download of the current state
func (h *Handler) HandleDownload() (map[string]any, error) {
	state := h.transformState(h.stateManager.GetFullState())
	return map[string]any{
		"state": state,
	}, nil
}

// GetServerInfo returns information about the server
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

// AddBroadcaster registers a new broadcaster with the Handler
func (h *Handler) AddBroadcaster(broadcaster Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcaster)
}

// AddBroadcasters registers multiple broadcasters with the Handler
func (h *Handler) AddBroadcasters(broadcasters ...Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcasters...)
}

// HandleVersionUpdate handles HTTP binary update requests
func (h *Handler) HandleVersionUpdate(w http.ResponseWriter, r *http.Request) {

	logger := logging.GetLogger()

	// Parse the multipart form data
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		logger.Error("Error parsing multipart form: %v", err)
		http.Error(w, "Error parsing form data", http.StatusBadRequest)
		return
	}

	// Retrieve the file from the posted form-data.
	updateFile, header, err := r.FormFile("binary")
	if err != nil {
		logger.Error("Error reading binary: %v", err)
		http.Error(w, "Error reading binary", http.StatusBadRequest)
		return
	}
	defer updateFile.Close()

	// Verify checksum/signature
	if !VerifyChecksum(updateFile, r.FormValue("checksum")) {
		logger.Error("Invalid checksum")
		http.Error(w, "Invalid checksum", http.StatusBadRequest)
		return
	}

	// Reset file pointer after checksum verification
	if _, err := updateFile.Seek(0, 0); err != nil {
		logger.Error("Error resetting file pointer: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Create a temporary file
	tempPath := filepath.Join(os.TempDir(), header.Filename)
	tempFile, err := os.Create(tempPath)
	if err != nil {
		logger.Error("Error creating temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tempFile.Close()

	// Copy uploaded binary to temporary file location
	if _, err := io.Copy(tempFile, updateFile); err != nil {
		logger.Error("Error moving binary to temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// After verifying and saving the binary, initiate cluster-wide update
	if err := h.InitiateVersionUpdate(tempPath); err != nil {
		logger.Error("Failed to initiate cluster update: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
	}

	// Schedule the update
	go func() {
		if err := h.updater.PerformUpdate(tempPath); err != nil {
			logger.Error("Update failed: %v", err)
		}
	}()

	w.WriteHeader(http.StatusOK)
}

// HandleVersionRollback handles HTTP binary rollback requests
func (h *Handler) HandleVersionRollback(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	// Get rollback index from query parameter
	indexStr := r.URL.Query().Get("index")
	if indexStr == "" {
		logger.Error("No rollback index provided")
		http.Error(w, "Rollback index required", http.StatusBadRequest)
		return
	}

	// Convert string to integer
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

	// Initiate cluster-wide rollback
	if err := h.InitiateBinaryRollback(currentBinaryPath, index); err != nil {
		logging.GetLogger().Error("Failed to initiate cluster rollback: %v", err)
		// Don't return error to client since local rollback will proceed
	}

	// Schedule the update
	go func() {
		if err := h.updater.PerformRollback(currentBinaryPath, index); err != nil {
			logger.Error("Rollback failed: %v", err)
		}
	}()

	w.WriteHeader(http.StatusOK)
}

// InitiateVersionUpdate starts a cluster-wide binary update process
func (h *Handler) InitiateVersionUpdate(newBinaryPath string) error {
	logger := logging.GetLogger()

	// Generate update metadata
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

	// Broadcast to cluster members
	for _, node := range h.list.Members() {
		// Only update the remote members. The local node will update itself.
		if node.Name != h.list.LocalNode().Name {
			// First send metadata
			if err := h.list.SendReliable(node, messageData); err != nil {
				logger.Error("Failed to send update metadata to node %s: %v", node.Name, err)
				continue
			}

			// Then stream the binary in chunks
			if err := h.streamBinaryToNode(node, newBinaryPath); err != nil {
				logger.Error("Failed to stream binary to node %s: %v", node.Name, err)
				continue
			}
		}
	}

	return nil
}

// InitiateBinaryRollback starts a cluster-wide binary rollback process
func (h *Handler) InitiateBinaryRollback(currentBinaryPath string, index int) error {
	logger := logging.GetLogger()

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

	// Broadcast to cluster members
	for _, node := range h.list.Members() {
		if node.Name != h.list.LocalNode().Name {
			if err := h.list.SendReliable(node, messageData); err != nil {
				logger.Error("Failed to send rollback data to node %s: %v", node.Name, err)
				continue
			}
		}
	}

	return nil
}

// streamBinaryToNode sends a binary file to a cluster node in chunks
func (h *Handler) streamBinaryToNode(node *memberlist.Node, binaryPath string) error {
	const chunkSize = 1024 * 1024 // 1MB chunks

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
			return fmt.Errorf("failed to send message: %w", err)
		}
	}

	// Send final chunk to indicate completion
	finalChunk := BinaryChunk{
		Data:   nil,
		Offset: offset,
		Final:  true,
	}
	chunkData, err := json.Marshal(finalChunk)
	if err != nil {
		return fmt.Errorf("failed to marshal final chunk: %w", err)
	}

	if err := h.list.SendReliable(node, chunkData); err != nil {
		return fmt.Errorf("failed to send final chunk: %w", err)
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
		return fmt.Errorf("failed to send message: %w", err)
	}

	return nil
}

// HandleAudioUpload handles HTTP audio file update requests.
func (h *Handler) HandleAudioUpload(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	// Parse the multipart form data
	if err := r.ParseMultipartForm(32 << 20); err != nil {
		logger.Error("Error parsing multipart form: %v", err)
		http.Error(w, "Error parsing form data", http.StatusBadRequest)
		return
	}

	// Retrieve the file from the posted form-data.
	audioFile, header, err := r.FormFile("binary")
	if err != nil {
		logger.Error("Error reading binary: %v", err)
		http.Error(w, "Error reading binary", http.StatusBadRequest)
		return
	}
	defer audioFile.Close()

	// Define the destination directory and file path.
	destDir := "/var/lib/fusion/audio"
	destPath := filepath.Join(destDir, header.Filename)

	// Ensure that the destination directory exists.
	if err := os.MkdirAll(destDir, 0755); err != nil {
		logger.Error("Error creating destination directory: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Create the destination file.
	dstFile, err := os.Create(destPath)
	if err != nil {
		logger.Error("Error creating destination file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer dstFile.Close()

	// Copy the uploaded file's content to the destination file.
	if _, err := io.Copy(dstFile, audioFile); err != nil {
		logger.Error("Error copying file to destination: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	existingData := h.transformState(h.stateManager.GetFullState())
	addAudioFilesToConfig(destDir, existingData)

	if err := h.handleConfigUpdate(existingData); err != nil {
		logger.Error("Failed to handle update: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

// HandleListSnapshots retrieves a list of snapshot keys from the persistence layer.
// It lists all keys in the default bucket except the default state key.
func (h *Handler) HandleListSnapshots() ([]string, error) {
	var snapshots []string
	err := h.persistence.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			// No bucket means no snapshots.
			return nil
		}
		// Iterate over all keys in the bucket.
		return b.ForEach(func(k, v []byte) error {
			key := string(k)
			// Exclude the default state key (which holds the active state).
			if key != defaultStateKey {
				snapshots = append(snapshots, key)
			}
			return nil
		})
	})
	return snapshots, err
}

// HandleCreateSnapshot saves the current state as a snapshot with the given name.
func (h *Handler) HandleCreateSnapshot(name string) error {
	return h.persistence.SaveSnapshot(name)
}

// HandleActivateSnapshot sets the given snapshot as active.
func (h *Handler) HandleActivateSnapshot(name string) error {
	return h.persistence.ActivateSnapshot(name)
}

// HandleDeleteSnapshot deletes a snapshot with the given name from persistence.
func (h *Handler) HandleDeleteSnapshot(name string) error {
	return h.persistence.DeleteSnapshot(name)
}

// getBinaryMetadata calculates hash and size of a binary file
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

// addAudioFilesToConfig calculates hash and size of a binary file
func addAudioFilesToConfig(audioDir string, existingData map[string]any) {

	// Read the directory entries.
	entries, err := os.ReadDir(audioDir)
	if err != nil {
		log.Printf("Error reading directory %s: %v", audioDir, err)
		return
	}

	// Collect file names (ignoring subdirectories).
	var fileNames []string
	for _, entry := range entries {
		if !entry.IsDir() {
			fileNames = append(fileNames, entry.Name())
		}
	}

	// Add the "audio_files" section to the settings.
	existingData["audio_files"] = map[string]any{
		"location": audioDir,
		"files":    fileNames,
	}
}
