package config

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/broadcast"
	"fusion/internal/logging"
	"io"
	"net/http"
	"time"

	"github.com/hashicorp/memberlist"
)

// Common handler for both UDP and HTTP servers
type ConfigHandler struct {
	nodeName     string
	stateManager *StateManager
	persistence  *ConfigPersistence
	list         *memberlist.Memberlist
	broadcasters []broadcast.Broadcaster
}

func NewConfigHandler(nodeName string, list *memberlist.Memberlist, stateManager *StateManager,
	persistence *ConfigPersistence) *ConfigHandler {
	return &ConfigHandler{
		nodeName:     nodeName,
		stateManager: stateManager,
		persistence:  persistence,
		list:         list,
	}
}

// Shared update handling logic
func (h *ConfigHandler) handleUpdate(update map[string]interface{}) error {
	configUpdate := api.ConfigUpdate{
		Update:  update,
		Version: time.Now().UnixNano(),
		NodeID:  h.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	return h.broadcastUpdate(configUpdate, true)
}

func (h *ConfigHandler) transformState(state map[string]*api.StateEntry) map[string]interface{} {
	result := make(map[string]interface{})
	for key, entry := range state {
		result[key] = entry.Data
	}
	return result
}

func (h *ConfigHandler) broadcastUpdate(update api.ConfigUpdate, applyUpdate bool) error {
	if applyUpdate {
		if err := h.stateManager.ApplyUpdate(update); err != nil {
			return fmt.Errorf("failed to apply update: %v", err)
		}
		h.persistence.MarkDirty()
	}

	// Transform update directly without the "key" wrapper
	state := make(map[string]*api.StateEntry)
	for k, v := range update.Update {
		state[k] = &api.StateEntry{Data: v}
	}
	transformed := h.transformState(state)

	// Broadcast to cluster members
	data, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %v", err)
	}

	for _, node := range h.list.Members() {
		if node.Name != h.list.LocalNode().Name {
			if err := h.list.SendReliable(node, data); err != nil {
				logging.GetLogger(h.nodeName).Error("Failed to send to node %s: %v", node.Name, err)
			}
		}
	}

	// Broadcast to websocket clients and other broadcasters
	for _, broadcaster := range h.broadcasters {
		if err := broadcaster.BroadcastUpdate(transformed); err != nil {
			logging.GetLogger(h.nodeName).Error("Failed to broadcast update: %v", err)
		}
	}

	return nil
}

func (h *ConfigHandler) GetInitialState() (WebSocketResponse, error) {
	state := h.transformState(h.stateManager.GetFullState())
	return WebSocketResponse{
		Type:    "initial_state",
		Version: h.stateManager.GetVersion(),
		State:   state,
	}, nil
}

func (h *ConfigHandler) HandleHTTPGet(key string) (interface{}, error) {
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
func (h *ConfigHandler) HandleHTTPSet(update map[string]interface{}) (interface{}, error) {
	if err := h.handleUpdate(update); err != nil {
		return nil, fmt.Errorf("failed to handle update: %v", err)
	}

	return map[string]interface{}{
		"status":  "success",
		"updates": update,
	}, nil
}

// UDP Server methods
func (h *ConfigHandler) HandleUDPMessage(data []byte) (interface{}, error) {
	var msg struct {
		Action string          `json:"action"`
		Raw    json.RawMessage `json:",omitempty"`
	}

	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid JSON: %v", err)
	}

	switch msg.Action {
	case "get":
		// Transform the full state before returning it
		fullState := h.stateManager.GetFullState()
		transformed := make(map[string]interface{})

		// Transform each state entry
		for key, entry := range fullState {
			transformed[key] = entry.Data
		}

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

		if err := h.handleUpdate(update); err != nil {
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

func (h *ConfigHandler) HandleClearAllData() error {
	// Create an empty update to clear all data
	configUpdate := api.ConfigUpdate{
		Update:  map[string]interface{}{},
		Version: time.Now().UnixNano(),
		NodeID:  h.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	// Use broadcastUpdate with apply=true to clear and notify all clients
	if err := h.broadcastUpdate(configUpdate, true); err != nil {
		return fmt.Errorf("failed to clear all data: %v", err)
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

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "success",
		"message": "All data cleared successfully",
	})
}

func (h *ConfigHandler) HandleDumpState() (map[string]interface{}, error) {
	return map[string]interface{}{
		"state": h.stateManager.GetFullState(),
	}, nil
}

// HandleWebSocketMessage handles incoming websocket messages
func (h *ConfigHandler) HandleWebSocketMessage(data []byte) (*WebSocketResponse, error) {
	var msg WebSocketMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid WebSocket message: %v", err)
	}

	switch msg.Type {
	case "update":
		var update map[string]interface{}
		if err := json.Unmarshal(msg.Update, &update); err != nil {
			return nil, fmt.Errorf("invalid update in WebSocket message: %v", err)
		}

		configUpdate := api.ConfigUpdate{
			Update:  update,
			Version: time.Now().UnixNano(),
			NodeID:  h.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := h.broadcastUpdate(configUpdate, true); err != nil {
			return nil, fmt.Errorf("broadcastUpdate failed: %v", err)
		}

		return &WebSocketResponse{
			Type:    "update_success",
			Status:  "success",
			Message: "Update applied successfully",
		}, nil

	case "volume":
		if msg.Volume < 0.0 || msg.Volume > 1.0 {
			return nil, fmt.Errorf("invalid volume value: %v (must be between 0.0 and 1.0)", msg.Volume)
		}

		update := api.VolumeUpdate{
			Channel: msg.Channel,
			Volume:  msg.Volume,
		}

		volumeKey := fmt.Sprintf("volume:%d", msg.Channel)
		volumeUpdate := api.ConfigUpdate{
			Update: map[string]interface{}{
				volumeKey: update,
			},
			Version: time.Now().UnixNano(),
			NodeID:  h.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := h.broadcastUpdate(volumeUpdate, false); err != nil {
			return nil, fmt.Errorf("error broadcasting volume update: %v", err)
		}

		return &WebSocketResponse{
			Type:    "volume_success",
			Status:  "success",
			Message: "Volume updated successfully",
		}, nil

	default:
		return nil, fmt.Errorf("unknown WebSocket message type: %s", msg.Type)
	}
}

// HandleDownload handles the download of the current state
func (h *ConfigHandler) HandleDownload() (map[string]interface{}, error) {
	state := h.transformState(h.stateManager.GetFullState())
	return map[string]interface{}{
		"state": state,
	}, nil
}

// HandleUpload handles the upload of a new state
func (h *ConfigHandler) HandleUpload(reader io.Reader) (map[string]interface{}, error) {
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
			Update: map[string]interface{}{
				key: entry.Data,
			},
			Version: time.Now().UnixNano(),
			NodeID:  h.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := h.broadcastUpdate(update, true); err != nil {
			logging.GetLogger(h.nodeName).Error("Import key failed: %s: %v", key, err)
		}
	}

	return map[string]interface{}{
		"status":  "import complete",
		"version": h.stateManager.GetVersion(),
	}, nil
}

// GetServerInfo returns information about the server
func (h *ConfigHandler) GetServerInfo() (map[string]interface{}, error) {
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

// AddBroadcaster registers a new broadcaster with the ConfigHandler
func (h *ConfigHandler) AddBroadcaster(broadcaster broadcast.Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcaster)
}

// Optional: Add a method to add multiple broadcasters at once
func (h *ConfigHandler) AddBroadcasters(broadcasters ...broadcast.Broadcaster) {
	h.broadcasters = append(h.broadcasters, broadcasters...)
}
