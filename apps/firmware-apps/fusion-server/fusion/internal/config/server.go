package config

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/broadcast"

	"github.com/gorilla/websocket"
	"github.com/hashicorp/memberlist"
)

type ConfigServer struct {
	list         *memberlist.Memberlist
	stateManager *StateManager
	persistence  *ConfigPersistence
	wsClients    map[*websocket.Conn]bool
	wsLock       sync.RWMutex
	upgrader     websocket.Upgrader
	broadcasters []broadcast.Broadcaster
}

func NewConfigServer(list *memberlist.Memberlist, stateManager *StateManager, persistence *ConfigPersistence,
	broadcasters ...broadcast.Broadcaster) *ConfigServer {
	return &ConfigServer{
		list:         list,
		stateManager: stateManager,
		persistence:  persistence,
		wsClients:    make(map[*websocket.Conn]bool),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		},
		broadcasters: broadcasters,
	}
}

func (s *ConfigServer) SetValue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Read request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Validate JSON format
	var update map[string]interface{}
	if err := json.Unmarshal(body, &update); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	// Create config update
	configUpdate := api.ConfigUpdate{
		Update:  update,
		Version: time.Now().UnixNano(),
		NodeID:  s.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	// Broadcast update
	if err := s.broadcastUpdate(configUpdate, true); err != nil {
		log.Printf("[ERROR] Error broadcasting update: %v", err)
		http.Error(w, "Error broadcasting update", http.StatusInternalServerError)
		return
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"status":  "success",
		"updates": update,
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Printf("[ERROR] Error encoding response: %v", err)
		http.Error(w, "Error encoding response", http.StatusInternalServerError)
		return
	}
}

func (s *ConfigServer) GetValue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	key := r.URL.Query().Get("key")
	if key != "" {
		value, exists := s.stateManager.Get(key)
		if !exists {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"exists": false,
				"error":  "key not found",
			})
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"exists": true,
			"value":  value,
		})
		return
	}

	state := transformState(s.stateManager.GetFullState())
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(state)
}

func (s *ConfigServer) ClearAllData(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	configUpdate := api.ConfigUpdate{
		Update:  map[string]interface{}{},
		Version: time.Now().UnixNano(),
		NodeID:  s.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	if err := s.broadcastUpdate(configUpdate, true); err != nil {
		log.Printf("[ERROR] Error broadcasting clear update: %v", err)
		http.Error(w, "Error clearing all data", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (s *ConfigServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	s.upgrader.HandshakeTimeout = 10 * time.Second
	s.upgrader.EnableCompression = true
	s.upgrader.ReadBufferSize = 1024
	s.upgrader.WriteBufferSize = 1024

	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[ERROR] Failed to upgrade connection: %v", err)
		return
	}

	conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	pingTicker := time.NewTicker(30 * time.Second)
	go func() {
		defer pingTicker.Stop()
		for range pingTicker.C {
			if err := conn.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(10*time.Second)); err != nil {
				log.Printf("[ERROR] Ping failed: %v", err)
				return
			}
		}
	}()

	s.wsLock.Lock()
	s.wsClients[conn] = true
	s.wsLock.Unlock()

	defer func() {
		pingTicker.Stop()
		conn.Close()
		s.wsLock.Lock()
		delete(s.wsClients, conn)
		s.wsLock.Unlock()
	}()

	state := transformState(s.stateManager.GetFullState())
	if err := conn.WriteJSON(map[string]interface{}{
		"type":    "initial_state",
		"version": s.stateManager.GetVersion(),
		"state":   state,
	}); err != nil {
		log.Printf("[ERROR] Failure sending initial state: %v", err)
		return
	}

	for {
		messageType, data, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("[ERROR] WebSocket error: %v", err)
			}
			break
		}
		if messageType == websocket.TextMessage {
			s.handleWebSocketMessage(data)
		}
	}
}

func (s *ConfigServer) handleWebSocketMessage(data []byte) {
	var msg struct {
		Type    string          `json:"type"`
		Update  json.RawMessage `json:"update,omitempty"`
		Channel int             `json:"channel,omitempty"`
		Volume  float64         `json:"volume,omitempty"`
	}

	if err := json.Unmarshal(data, &msg); err != nil {
		log.Printf("[ERROR] Invalid WebSocket message: %v", err)
		return
	}

	switch msg.Type {
	case "update":
		var update map[string]interface{}
		if err := json.Unmarshal(msg.Update, &update); err != nil {
			log.Printf("[ERROR] Invalid update in WebSocket message: %v", err)
			return
		}

		configUpdate := api.ConfigUpdate{
			Update:  update,
			Version: time.Now().UnixNano(),
			NodeID:  s.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := s.broadcastUpdate(configUpdate, true); err != nil {
			log.Printf("[ERROR] broadcastUpdate failed: %v", err)
		}

	case "volume":
		if msg.Volume < 0.0 || msg.Volume > 1.0 {
			log.Printf("[ERROR] Invalid volume value: %v (must be between 0.0 and 1.0)", msg.Volume)
			return
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
			NodeID:  s.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := s.broadcastUpdate(volumeUpdate, false); err != nil {
			log.Printf("[ERROR] Error broadcasting volume update: %v", err)
		}

	default:
		log.Printf("[ERROR] Unknown WebSocket message type: %s", msg.Type)
	}
}

func (s *ConfigServer) broadcastUpdate(update api.ConfigUpdate, applyUpdate bool) error {
	if applyUpdate {
		if err := s.stateManager.ApplyUpdate(update); err != nil {
			return fmt.Errorf("failed to apply update: %v", err)
		}

		s.persistence.MarkDirty()
	}

	data, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %v", err)
	}

	for _, node := range s.list.Members() {
		if node.Name != s.list.LocalNode().Name {
			if err := s.list.SendReliable(node, data); err != nil {
				log.Printf("[ERROR] Failed to send to node %s: %v", node.Name, err)
			}
		}
	}

	transformed := transformState(map[string]*api.StateEntry{"key": {Data: update.Update}})

	s.broadcastToWebSocketClients(transformed)

	for _, broadcaster := range s.broadcasters {
		if err := broadcaster.BroadcastUpdate(transformed); err != nil {
			log.Printf("[ERROR] Failed to broadcast update: %v", err)
		}
	}
	return nil
}

func (s *ConfigServer) broadcastToWebSocketClients(update map[string]interface{}) {
	message := map[string]interface{}{
		"type":   "update",
		"update": update,
	}

	s.wsLock.RLock()
	defer s.wsLock.RUnlock()

	for conn := range s.wsClients {
		if err := conn.WriteJSON(message); err != nil {
			log.Printf("[ERROR] Error sending to WebSocket client: %v", err)
			conn.Close()
			delete(s.wsClients, conn)
		}
	}
}

func (s *ConfigServer) DownloadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	state := transformState(s.stateManager.GetFullState())
	export := map[string]interface{}{
		"state": state,
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=config_export_%s.json",
		time.Now().UTC().Format("20060102_150405")))

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(export); err != nil {
		log.Printf("[ERROR] Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

func (s *ConfigServer) DumpState(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	export := map[string]interface{}{
		"state": s.stateManager.GetFullState(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=config_export_%s.json",
		time.Now().UTC().Format("20060102_150405")))

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(export); err != nil {
		log.Printf("[ERROR] Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

func (s *ConfigServer) UploadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var jsonImport struct {
		Version   int64                      `json:"version"`
		Timestamp time.Time                  `json:"timestamp"`
		NodeID    string                     `json:"node_id"`
		State     map[string]*api.StateEntry `json:"state"`
	}

	if err := json.NewDecoder(r.Body).Decode(&jsonImport); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	for key, entry := range jsonImport.State {
		update := api.ConfigUpdate{
			Update: map[string]interface{}{
				key: entry.Data,
			},
			Version: time.Now().UnixNano(),
			NodeID:  s.list.LocalNode().Name,
			Time:    time.Now().UTC(),
		}

		if err := s.broadcastUpdate(update, true); err != nil {
			log.Printf("[ERROR] Import key failed: %s: %v", key, err)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "import complete",
		"version": s.stateManager.GetVersion(),
	})
}

func (s *ConfigServer) HandleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	info := map[string]interface{}{
		"name":    "Fusion Config Server",
		"version": "1.0.0",
		"node_id": s.list.LocalNode().Name,
		"endpoints": []string{
			"/setValue",
			"/getValue",
			"/ws",
			"/download",
			"/upload",
			"/dump",
		},
		"cluster_size": len(s.list.Members()),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}

// transformState converts a state map with metadata into a plain key-value map
func transformState(state map[string]*api.StateEntry) map[string]interface{} {
	result := make(map[string]interface{})
	for key, entry := range state {
		result[key] = entry.Data
	}
	return result
}
