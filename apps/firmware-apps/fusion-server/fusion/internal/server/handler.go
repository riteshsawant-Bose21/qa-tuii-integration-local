package server

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/hashicorp/memberlist"
)

// Common handler for both UDP and HTTP servers
type Handler struct {
	stateManager *StateManager
	persistence  *ConfigPersistence
	list         *memberlist.Memberlist
	broadcasters []Broadcaster
	updater      *Updater
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
func (h *Handler) handleConfigUpdate(data map[string]interface{}) error {
	configUpdate := api.ConfigUpdate{
		Data:    data,
		Version: time.Now().UnixNano(),
		NodeID:  h.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	return h.broadcastUpdate(configUpdate)
}

func (h *Handler) transformState(state map[string]*api.StateEntry) map[string]interface{} {
	result := make(map[string]interface{})
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
	transformed := TransformState(state)

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

	// Always broadcast to local clients
	for _, broadcaster := range h.broadcasters {
		if err := broadcaster.BroadcastUpdate(transformed); err != nil {
			logger.Error("Failed to broadcast update: %v", err)
		}
	}

	return nil
}

func (h *Handler) GetInitialState() (WebSocketResponse, error) {
	data := h.transformState(h.stateManager.GetFullState())
	return WebSocketResponse{
		Type: "initial_state",
		Data: data,
	}, nil
}

func (h *Handler) HandleHTTPGet(key string) (interface{}, error) {
	if key != "" {
		value, exists := h.stateManager.Get(key)
		if !exists {
			return map[string]interface{}{
				"exists": false,
				"error":  "key not found",
			}, nil
		}
		return map[string]interface{}{
			"exists": true,
			"value":  value,
		}, nil
	}

	state := h.transformState(h.stateManager.GetFullState())
	return state, nil
}

// HTTP Server methods
func (h *Handler) HandleHTTPSet(update map[string]interface{}) (interface{}, error) {
	if err := h.handleConfigUpdate(update); err != nil {
		return nil, fmt.Errorf("failed to handle update: %v", err)
	}

	return map[string]interface{}{
		"status":  "success",
		"updates": update,
	}, nil
}

// UDP Server methods
func (h *Handler) HandleUDPMessage(data []byte) (interface{}, error) {

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
		return map[string]interface{}{
			"status": "success",
			"data":   transformed,
		}, nil

	case "set":
		var update map[string]interface{}
		if err := json.Unmarshal(data, &update); err != nil {
			return nil, fmt.Errorf("invalid JSON: %v", err)
		}
		delete(update, "action")

		// Create update with original node ID
		configUpdate := api.ConfigUpdate{
			Data:    update,
			Version: time.Now().UnixNano(),
			NodeID:  h.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := h.broadcastUpdate(configUpdate); err != nil {
			return nil, fmt.Errorf("failed to handle update: %v", err)
		}

		return map[string]interface{}{
			"status":  "success",
			"message": "Update applied successfully",
		}, nil

	default:
		return nil, fmt.Errorf("unknown action: %s", msg.Action)
	}
}

func (h *Handler) HandleClearAllData() error {
	configUpdate := api.ConfigUpdate{
		Data:    map[string]interface{}{},
		Version: time.Now().UnixNano(),
		NodeID:  h.list.LocalNode().Name,
		Time:    time.Now().UTC(),
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

	w.Header().Set(contentType, jsonContentType)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"message": "All data cleared successfully",
	})
}

func (h *Handler) HandleDumpState() (map[string]interface{}, error) {
	return map[string]interface{}{
		"state": h.stateManager.GetFullState(),
	}, nil
}

func (h *Handler) ValidateState() error {
	return h.persistence.ValidateStateFile()
}

// HandleWebSocketMessage handles incoming websocket messages
func (h *Handler) HandleWebSocketMessage(data []byte) (*WebSocketResponse, error) {
	var msg WebSocketMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid WebSocket message: %v", err)
	}

	switch msg.Type {
	case "update":
		var data map[string]interface{}
		if err := json.Unmarshal(msg.Data, &data); err != nil {
			return nil, fmt.Errorf("invalid update in WebSocket message: %v", err)
		}

		configUpdate := api.ConfigUpdate{
			Data:    data,
			Version: time.Now().UnixNano(),
			NodeID:  h.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := h.broadcastUpdate(configUpdate); err != nil {
			return nil, fmt.Errorf("broadcastUpdate failed: %v", err)
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
func (h *Handler) HandleDownload() (map[string]interface{}, error) {
	state := h.transformState(h.stateManager.GetFullState())
	return map[string]interface{}{
		"state": state,
	}, nil
}

// HandleUpload handles the upload of a new config state
func (h *Handler) HandleUpload(reader io.Reader) (map[string]interface{}, error) {
	var jsonImport struct {
		Version   int64                      `json:"version"`
		Timestamp time.Time                  `json:"timestamp"`
		NodeID    string                     `json:"node_id"`
		State     map[string]*api.StateEntry `json:"state"`
	}

	if err := json.NewDecoder(reader).Decode(&jsonImport); err != nil {
		return nil, fmt.Errorf("invalid JSON: %v", err)
	}

	for key, entry := range jsonImport.State {
		update := api.ConfigUpdate{
			Data: map[string]interface{}{
				key: entry.Data,
			},
			Version: time.Now().UnixNano(),
			NodeID:  h.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := h.broadcastUpdate(update); err != nil {
			logging.GetLogger().Error("Import key failed: %s: %v", key, err)
		}
	}

	return map[string]interface{}{
		"status":  "import complete",
		"version": h.stateManager.GetVersion(),
	}, nil
}

// GetServerInfo returns information about the server
func (h *Handler) GetServerInfo() (map[string]interface{}, error) {
	info := map[string]interface{}{
		"name":    "Fusion Config Server",
		"version": "1.0.0",
		"node_id": h.list.LocalNode().Name,
		"endpoints": []string{
			"/setValue",
			"/getValue",
			"/clear",
			"/ws",
			"/download",
			"/upload",
			"/updateBinary",
			"/rollbackBinary",
			"/dump",
		},
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

// HandleBinaryUpdate handles HTTP binary update requests
func (h *Handler) HandleBinaryUpdate(w http.ResponseWriter, r *http.Request) {
	// Read the uploaded binary
	updateFile, header, err := r.FormFile("binary")
	if err != nil {
		logging.GetLogger().Error("Error reading binary: %v", err)
		http.Error(w, "Error reading binary", http.StatusBadRequest)
		return
	}
	defer updateFile.Close()

	// Verify checksum/signature
	if !VerifyChecksum(updateFile, r.FormValue("checksum")) {
		logging.GetLogger().Error("Invalid checksum")
		http.Error(w, "Invalid checksum", http.StatusBadRequest)
		return
	}

	// Reset file pointer after checksum verification
	if _, err := updateFile.Seek(0, 0); err != nil {
		logging.GetLogger().Error("Error resetting file pointer: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Create a temporary file
	tempPath := filepath.Join(os.TempDir(), header.Filename)
	tempFile, err := os.Create(tempPath)
	if err != nil {
		logging.GetLogger().Error("Error creating temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}
	defer tempFile.Close()

	// Copy uploaded binary to temporary file location
	if _, err := io.Copy(tempFile, updateFile); err != nil {
		logging.GetLogger().Error("Error moving binary to temporary file: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// After verifying and saving the binary, initiate cluster-wide update
	if err := h.InitiateBinaryUpdate(tempPath); err != nil {
		logging.GetLogger().Error("Failed to initiate cluster update: %v", err)
		// Don't return error to client since local update will proceed
	}

	// Schedule the update
	go func() {
		if err := h.updater.PerformUpdate(tempPath); err != nil {
			logging.GetLogger().Error("Update failed: %v", err)
		}
	}()

	w.WriteHeader(http.StatusOK)
}

// HandleBinaryUpdate handles HTTP binary rollback requests
func (h *Handler) HandleBinaryRollback(w http.ResponseWriter, r *http.Request) {
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

	currentBinaryPath, err := os.Executable()
	if err != nil {
		logger.Error("Failed to get current binary path: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	go func() {
		if err := h.updater.PerformRollback(currentBinaryPath, index); err != nil {
			logger.Error("Rollback failed: %v", err)
		}
	}()

	w.WriteHeader(http.StatusOK)
}

// InitiateBinaryUpdate starts a cluster-wide binary update process
func (h *Handler) InitiateBinaryUpdate(newBinaryPath string) error {
	logger := logging.GetLogger()

	// Generate update metadata
	hash, size, err := getBinaryMetadata(newBinaryPath)
	if err != nil {
		return fmt.Errorf("failed to get binary metadata: %w", err)
	}

	update := BinaryUpdate{
		NodeID:     h.list.LocalNode().Name,
		Time:       time.Now().UTC(),
		BinaryHash: hash,
		BinarySize: size,
	}

	// Broadcast to cluster members
	data, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %w", err)
	}

	message := BinaryMessage{
		Type:    UpdateBinary,
		Payload: data,
	}

	messageData, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	for _, node := range h.list.Members() {
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

		message := BinaryMessage{
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

	message := BinaryMessage{
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
