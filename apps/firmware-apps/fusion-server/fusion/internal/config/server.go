package config

import (
	"encoding/json"
	"fmt"
	"fusion/internal/logging"
	"io"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type ConfigServer struct {
	nodeName  string
	handler   *ConfigHandler
	wsClients map[*websocket.Conn]bool
	wsLock    sync.RWMutex
	upgrader  websocket.Upgrader
}

func NewConfigServer(nodeName string, handler *ConfigHandler) *ConfigServer {
	server := &ConfigServer{
		nodeName:  nodeName,
		handler:   handler,
		wsClients: make(map[*websocket.Conn]bool),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
			HandshakeTimeout:  10 * time.Second,
			EnableCompression: true,
			ReadBufferSize:    1024,
			WriteBufferSize:   1024,
		},
	}
	handler.AddBroadcaster(server)
	return server
}

func (s *ConfigServer) BroadcastUpdate(update map[string]interface{}) error {
	message := map[string]interface{}{
		"type":    "update",
		"update":  update,
		"version": time.Now().UnixNano(),
	}

	s.wsLock.RLock()
	defer s.wsLock.RUnlock()

	for conn := range s.wsClients {
		if err := conn.WriteJSON(message); err != nil {
			logging.GetLogger(s.nodeName).Error("Error broadcasting to WebSocket client: %v", err)
			conn.Close()
			delete(s.wsClients, conn)
		}
	}
	return nil
}

func (s *ConfigServer) SetValue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var update map[string]interface{}
	if err := json.Unmarshal(body, &update); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	response, err := s.handler.HandleHTTPSet(update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *ConfigServer) GetValue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	key := r.URL.Query().Get("key")
	response, err := s.handler.HandleHTTPGet(key)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *ConfigServer) DumpState(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	state, err := s.handler.HandleDumpState()
	if err != nil {
		logging.GetLogger(s.nodeName).Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=config_export_%s.json",
		time.Now().UTC().Format("20060102_150405")))

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(state); err != nil {
		logging.GetLogger(s.nodeName).Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

func (s *ConfigServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		logging.GetLogger(s.nodeName).Error("Failed to upgrade connection: %v", err)
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
				logging.GetLogger(s.nodeName).Error("Ping failed: %v", err)
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

	// Get initial state through handler
	state, err := s.handler.GetInitialState()
	if err != nil {
		logging.GetLogger(s.nodeName).Error("Failed to get initial state: %v", err)
		return
	}

	if err := conn.WriteJSON(state); err != nil {
		logging.GetLogger(s.nodeName).Error("Failure sending initial state: %v", err)
		return
	}

	for {
		messageType, data, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logging.GetLogger(s.nodeName).Error("WebSocket error: %v", err)
			}
			break
		}
		if messageType == websocket.TextMessage {
			s.handleWebSocketMessage(conn, data)
		}
	}
}

func (s *ConfigServer) handleWebSocketMessage(conn *websocket.Conn, data []byte) {
	response, err := s.handler.HandleWebSocketMessage(data)
	if err != nil {
		if err := conn.WriteJSON(map[string]interface{}{
			"type":    "error",
			"message": err.Error(),
		}); err != nil {
			logging.GetLogger(s.nodeName).Error("Error sending error response: %v", err)
		}
		return
	}

	if err := conn.WriteJSON(response); err != nil {
		logging.GetLogger(s.nodeName).Error("Error sending response: %v", err)
	}
}

func (s *ConfigServer) DownloadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response, err := s.handler.HandleDownload()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=config_export_%s.json",
		time.Now().UTC().Format("20060102_150405")))

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(response); err != nil {
		logging.GetLogger(s.nodeName).Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

func (s *ConfigServer) UploadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response, err := s.handler.HandleUpload(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *ConfigServer) HandleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	info, err := s.handler.GetServerInfo()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}
