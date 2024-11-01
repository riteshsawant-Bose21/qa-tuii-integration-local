package config

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"fusion/internal/api"

	"github.com/gorilla/websocket"
	"github.com/hashicorp/memberlist"
)

// ConfigServer handles HTTP requests for configuration management
type ConfigServer struct {
	list         *memberlist.Memberlist
	stateManager *StateManager
	wsClients    map[*websocket.Conn]bool
	wsLock       sync.RWMutex
	upgrader     websocket.Upgrader
}

// NewConfigServer creates a new config server instance
func NewConfigServer(list *memberlist.Memberlist, stateManager *StateManager) *ConfigServer {
	return &ConfigServer{
		list:         list,
		stateManager: stateManager,
		wsClients:    make(map[*websocket.Conn]bool),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all connections
			},
		},
	}
}

// SetValue handles requests to update configuration values
func (s *ConfigServer) SetValue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var update struct {
		Key   string      `json:"key"`
		Value interface{} `json:"value"`
	}

	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if update.Key == "" {
		http.Error(w, "Key cannot be empty", http.StatusBadRequest)
		return
	}

	if err := s.broadcastUpdate(update.Key, update.Value); err != nil {
		log.Printf("Error broadcasting update: %v", err)
		http.Error(w, "Error broadcasting update", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "update stored and broadcasted",
		"key":    update.Key,
	})
}

// GetValue handles requests to retrieve configuration values
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
			"key":    key,
			"value":  value,
		})
		return
	}

	// Return full state if no key specified
	state := s.stateManager.GetFullState()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"version": s.stateManager.GetVersion(),
		"state":   state,
	})
}

// HandleWebSocket manages WebSocket connections
func (s *ConfigServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection: %v", err)
		return
	}

	s.wsLock.Lock()
	s.wsClients[conn] = true
	s.wsLock.Unlock()

	defer func() {
		conn.Close()
		s.wsLock.Lock()
		delete(s.wsClients, conn)
		s.wsLock.Unlock()
	}()

	// Send current state to new client
	state := s.stateManager.GetFullState()
	if err := conn.WriteJSON(map[string]interface{}{
		"type":    "initial_state",
		"version": s.stateManager.GetVersion(),
		"state":   state,
	}); err != nil {
		log.Printf("Error sending initial state: %v", err)
		return
	}

	for {
		messageType, data, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
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
		Type  string          `json:"type"`
		Key   string          `json:"key"`
		Value json.RawMessage `json:"value"`
	}

	if err := json.Unmarshal(data, &msg); err != nil {
		log.Printf("Invalid WebSocket message: %v", err)
		return
	}

	switch msg.Type {
	case "update":
		var value interface{}
		if err := json.Unmarshal(msg.Value, &value); err != nil {
			log.Printf("Invalid value in WebSocket message: %v", err)
			return
		}
		if err := s.broadcastUpdate(msg.Key, value); err != nil {
			log.Printf("Error broadcasting WebSocket update: %v", err)
		}
	default:
		log.Printf("Unknown WebSocket message type: %s", msg.Type)
	}
}

func (s *ConfigServer) broadcastUpdate(key string, value interface{}) error {
	update := api.ConfigUpdate{
		Key:     key,
		Value:   value,
		Version: time.Now().UnixNano(),
		NodeID:  s.list.LocalNode().Name,
		Time:    time.Now().UTC(),
	}

	// Apply locally first
	if err := s.stateManager.ApplyUpdate(update); err != nil {
		return fmt.Errorf("failed to apply update: %v", err)
	}

	// Broadcast to cluster
	data, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %v", err)
	}

	for _, node := range s.list.Members() {
		if node.Name != s.list.LocalNode().Name {
			if err := s.list.SendReliable(node, data); err != nil {
				log.Printf("Failed to send to node %s: %v", node.Name, err)
			}
		}
	}

	// Broadcast to WebSocket clients
	s.broadcastToWebSocketClients(update)
	return nil
}

func (s *ConfigServer) broadcastToWebSocketClients(update api.ConfigUpdate) {
	message := map[string]interface{}{
		"type":    "update",
		"key":     update.Key,
		"value":   update.Value,
		"version": update.Version,
		"node_id": update.NodeID,
		"time":    update.Time,
	}

	s.wsLock.RLock()
	defer s.wsLock.RUnlock()

	for conn := range s.wsClients {
		if err := conn.WriteJSON(message); err != nil {
			log.Printf("Error sending to WebSocket client: %v", err)
			conn.Close()
			delete(s.wsClients, conn)
		}
	}
}

// DownloadJSON handles state export requests
func (s *ConfigServer) DownloadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	state := s.stateManager.GetFullState()
	export := map[string]interface{}{
		"version":   s.stateManager.GetVersion(),
		"timestamp": time.Now().UTC(),
		"node_id":   s.list.LocalNode().Name,
		"state":     state,
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=config_export_%s.json",
		time.Now().UTC().Format("20060102_150405")))

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(export); err != nil {
		log.Printf("Error exporting state: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

// UploadJSON handles state import requests
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
		if err := s.broadcastUpdate(key, entry.Value); err != nil {
			log.Printf("Error importing key %s: %v", key, err)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "import complete",
		"version": s.stateManager.GetVersion(),
	})
}

// HandleRoot provides basic server information
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
		},
		"cluster_size": len(s.list.Members()),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}
