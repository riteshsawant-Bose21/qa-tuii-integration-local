package server

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"net/http"
	"time"

	"github.com/hashicorp/memberlist"
)

// Common handler for both UDP and HTTP servers
type Handler struct {
	stateManager *StateManager
	persistence  *ConfigPersistence
	list         *memberlist.Memberlist
	broadcasters []Broadcaster
}

func NewHandler(list *memberlist.Memberlist, stateManager *StateManager,
	persistence *ConfigPersistence) *Handler {
	return &Handler{
		stateManager: stateManager,
		persistence:  persistence,
		list:         list,
	}
}

// Shared update handling logic
func (h *Handler) handleUpdate(data map[string]interface{}) error {
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
	if err := h.handleUpdate(update); err != nil {
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

// HandleUpload handles the upload of a new state
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
	return map[string]interface{}{
		"name":    "Fusion Config Server",
		"version": "1.0.0",
		"node_id": h.list.LocalNode().Name,
		"endpoints": []string{
			"/setValue",
			"/getValue",
			"/ws",
			"/download",
			"/upload",
			"/dump",
		},
		"cluster_size": len(h.list.Members()),
	}, nil
}

// AddBroadcaster registers a new broadcaster with the Handler
func (h *Handler) AddBroadcaster(broadcaster Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcaster)
}

// AddBroadcasters registers multiple broadcasters with the Handler
func (h *Handler) AddBroadcasters(broadcasters ...Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcasters...)
}
