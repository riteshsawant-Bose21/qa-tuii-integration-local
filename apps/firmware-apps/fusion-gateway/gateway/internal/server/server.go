package server

import (
	"net/http"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"gateway/internal/api"
	"fusion-services-core/logging"
	"gateway/internal/server/handler"

	"github.com/gorilla/websocket"
)

const (
	wsBufferSize = 1024
	wsPingTime   = 30
	wsPongTime   = 60
	wsTimeout    = 10
)

type FusionGateway struct {
	node      string
	handler   *handler.Handler
	wsClients map[*websocket.Conn]bool
	wsLock    sync.RWMutex
	upgrader  websocket.Upgrader
}

func NewFusionGateway(node string, handler *handler.Handler) *FusionGateway {
	server := &FusionGateway{
		handler:   handler,
		wsClients: make(map[*websocket.Conn]bool),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
			HandshakeTimeout:  wsTimeout * time.Second,
			EnableCompression: true,
			ReadBufferSize:    wsBufferSize,
			WriteBufferSize:   wsBufferSize,
		},
	}
	return server
}

// HandleWebSocket upgrades an HTTP connection to a WebSocket connection, sets up ping handlers,
// sends an initial state to the client, and listens for incoming messages.
func (s *FusionGateway) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Upgrade the HTTP connection to a WebSocket connection.
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		logging.GetLogger().Error("Failed to upgrade connection: %v", err)
		return
	}

	// Set initial read deadline and pong handler for connection keep-alive.
	conn.SetReadDeadline(time.Now().Add(wsPongTime * time.Second))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(wsPongTime * time.Second))
		return nil
	})

	// Start a ticker to periodically send ping messages.
	pingTicker := time.NewTicker(wsPingTime * time.Second)
	go func() {
		defer pingTicker.Stop()
		for range pingTicker.C {
			if err := conn.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(10*time.Second)); err != nil {
				logging.GetLogger().Error("Ping failed: %v", err)
				return
			}
		}
	}()

	// Add the connection to the list of WebSocket clients.
	s.wsLock.Lock()
	s.wsClients[conn] = true
	s.wsLock.Unlock()

	// Ensure cleanup when the function returns.
	defer func() {
		pingTicker.Stop()
		conn.Close()
		s.wsLock.Lock()
		delete(s.wsClients, conn)
		s.wsLock.Unlock()
	}()

	// Send the initial state to the client.
	state, err := s.handler.HandleHTTPGet("")
	if err != nil {
		logging.GetLogger().Error("Failed to get data: %v", err)
		return
	}

	if err := conn.WriteJSON(state); err != nil {
		logging.GetLogger().Error("Failure sending initial state: %v", err)
		return
	}

	// Listen for messages from the WebSocket client.
	for {
		messageType, data, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logging.GetLogger().Error("WebSocket error: %v", err)
			}
			break
		}
		if messageType == websocket.TextMessage {
			s.handleWebSocketMessage(conn, data)
		}
	}
}

// HandleRoot handles requests to the root URL ("/") and returns server information.
func (s *FusionGateway) HandleRoot(w http.ResponseWriter, r *http.Request) {
	// Only serve the root path.
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	// Write the JSON response
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode("")
}

// handleWebSocketMessage processes a message received over the WebSocket connection.
// It delegates the message handling to the handler and sends the response back to the client.
func (s *FusionGateway) handleWebSocketMessage(conn *websocket.Conn, data []byte) {
	response, err := s.handler.HandleWebSocketMessage(data)
	if err != nil {
		if err := conn.WriteJSON(map[string]any{
			"type":    "error",
			"message": err.Error(),
		}); err != nil {
			logging.GetLogger().Error("Error sending error response: %v", err)
		}
		return
	}

	if err := conn.WriteJSON(response); err != nil {
		logging.GetLogger().Error("Error sending response: %v", err)
	}
}
