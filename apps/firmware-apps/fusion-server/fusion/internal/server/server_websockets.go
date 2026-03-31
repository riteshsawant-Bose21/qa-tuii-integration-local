package server

import (
	"fmt"
	"net/http"
	"sync"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/server/handler"

	"github.com/gorilla/websocket"
)

const (
	wsBufferSize     = 1024        // Increased buffer size for better performance
	wsPingTime       = 30          // Ping interval in seconds
	wsPongTime       = 60          // Pong timeout in seconds
	wsTimeout        = 10          // Connection timeout in seconds
	wsMaxMessageSize = 1024 * 1024 // Max message size (1MB)
	wsMaxConnections = 1000        // Max concurrent connections
)

// safeWriteJSON safely writes JSON to a WebSocket connection using per-connection mutex
func (s *FusionServer) safeWriteJSON(conn *websocket.Conn, v interface{}) error {
	s.wsLock.RLock()
	mutex, exists := s.wsWriteMutex[conn]
	s.wsLock.RUnlock()

	if !exists {
		return fmt.Errorf("connection not found")
	}

	mutex.Lock()
	defer mutex.Unlock()
	return conn.WriteJSON(v)
}

// safeWriteControl safely writes control messages to a WebSocket connection using per-connection mutex
func (s *FusionServer) safeWriteControl(conn *websocket.Conn, messageType int, data []byte, deadline time.Time) error {
	s.wsLock.RLock()
	mutex, exists := s.wsWriteMutex[conn]
	s.wsLock.RUnlock()

	if !exists {
		return fmt.Errorf("connection not found")
	}

	mutex.Lock()
	defer mutex.Unlock()
	return conn.WriteControl(messageType, data, deadline)
}

// HandleWebSocket upgrades an HTTP connection to a WebSocket connection.
func (s *FusionServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	logger := logging.GetLogger()

	// Upgrade the HTTP connection to a WebSocket connection
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Error("Failed to upgrade connection: %v", err)
		return
	}

	// Set message size limit
	conn.SetReadLimit(wsMaxMessageSize)

	// Set up ping/pong handlers for connection keepalive
	conn.SetReadDeadline(time.Now().Add(wsPongTime * time.Second))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(wsPongTime * time.Second))
		return nil
	})

	// Atomically check connection limit and add connection
	s.wsLock.Lock()
	if len(s.wsClients) >= s.maxConnections {
		s.wsLock.Unlock()
		logger.Warn("WebSocket connection refused: connection limit reached")
		conn.Close()
		return
	}
	s.wsClients[conn] = true
	s.wsWriteMutex[conn] = &sync.Mutex{}
	s.wsLock.Unlock()

	// Ensure cleanup when the function returns
	defer func() {
		conn.Close()
		s.wsLock.Lock()
		delete(s.wsClients, conn)
		delete(s.wsWriteMutex, conn)
		// Clean up all topic subscriptions for this connection
		for topic, subscribers := range s.subscriptions {
			delete(subscribers, conn)
			// Clean up empty topic maps
			if len(subscribers) == 0 {
				delete(s.subscriptions, topic)
			}
		}
		s.wsLock.Unlock()
		logger.Info("WebSocket connection closed")
	}()

	logger.Info("WebSocket connection established")

	// Send initial state to the client
	initialState, err := s.handler.GetInitialState()
	if err != nil {
		logger.Error("Failed to get initial state: %v", err)
		return
	}

	// Send welcome message with connection info
	welcomeResponse := &api.WebSocketResponse{
		ID:        nil, // null for server push
		Version:   api.WSCurrentVersion,
		Type:      "welcome",
		Code:      api.WSCodeConnected,
		Status:    api.WSStatusEvent,
		Message:   "Connected successfully",
		Data:      initialState,
		Timestamp: time.Now(),
	}

	if err := s.safeWriteJSON(conn, welcomeResponse); err != nil {
		logger.Error("Failed to send welcome message: %v", err)
		return
	}

	// Start ping ticker for connection keepalive
	pingTicker := time.NewTicker(wsPingTime * time.Second)
	defer pingTicker.Stop()

	// Channel to signal when to stop the ping goroutine
	done := make(chan struct{})
	defer close(done)

	// Start ping goroutine
	go func() {
		for {
			select {
			case <-pingTicker.C:
				// Use WriteControl for thread-safe ping messages
				deadline := time.Now().Add(10 * time.Second)
				if err := s.safeWriteControl(conn, websocket.PingMessage, nil, deadline); err != nil {
					logger.Error("Failed to send ping: %v", err)
					return
				}
			case <-done:
				return
			}
		}
	}()

	// Listen for messages from the WebSocket client
	for {
		messageType, data, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logger.Error("WebSocket error: %v", err)
			}
			break
		}

		if messageType == websocket.TextMessage {
			// Process the message
			s.handleWebSocketMessage(conn, data)
		}
	}
}

// handleWebSocketMessage processes a message received over the WebSocket connection.
// It delegates the message handling to the handler and sends the response back to the client.
func (s *FusionServer) handleWebSocketMessage(conn *websocket.Conn, data []byte) {
	logger := logging.GetLogger()

	// Handle the WebSocket message
	response, err := s.handler.HandleWebSocketMessageWithConn(data, conn, s)
	if err != nil {
		logger.Error("WebSocket handler error: %v", err)
		s.sendErrorToConnection(conn, "", api.WSCodeApplicationError, err.Error(), "error")
		return
	}

	if err := s.safeWriteJSON(conn, response); err != nil {
		logger.Error("Error sending response: %v", err)
	}
}

// sendErrorToConnection sends an error response to a specific WebSocket connection
func (s *FusionServer) sendErrorToConnection(conn *websocket.Conn, requestID string, code int, message, status string) {
	var id *string
	if requestID != "" {
		id = &requestID
	}

	errorResponse := &api.WebSocketResponse{
		ID:        id, // null for server errors
		Version:   api.WSCurrentVersion,
		Type:      api.WSMsgTypeError,
		Code:      code,
		Status:    status,
		Message:   message,
		Data:      nil,
		Timestamp: time.Now(),
	}

	if err := s.safeWriteJSON(conn, errorResponse); err != nil {
		logging.GetLogger().Error("Failed to send error response: %v", err)
	}
}

// BroadcastMessage sends a notification message to all connected WebSocket clients.
// It acquires a read lock on the clients list to ensure thread-safe access.
func (s *FusionServer) BroadcastMessage(message *api.NotifyMessage) error {
	// Convert NotifyMessage to appropriate WebSocket format based on operation
	switch message.Operation {
	case api.NotifyOpDeviceUpdate:
		if message.DeviceInfo != nil {
			// Convert device update to WebSocket response format
			updateMessage := &api.WebSocketResponse{
				ID:        nil, // Push notifications have null ID
				Version:   api.WSCurrentVersion,
				Type:      api.WSMsgTypeDeviceUpdate,
				Code:      api.WSCodeDeviceUpdated,
				Status:    api.WSStatusEvent,
				Message:   fmt.Sprintf("Device %s updated", message.DeviceInfo.Id),
				Data:      message.DeviceInfo,
				Timestamp: time.Now(),
			}
			// Send to topic-based subscribers
			return s.BroadcastToTopic(handler.TopicDeviceUpdates, updateMessage)
		}
	default:
		// For other message types, wrap in WebSocketResponse format for consistency
		broadcastMessage := &api.WebSocketResponse{
			ID:        nil, // Push notifications have null ID
			Version:   api.WSCurrentVersion,
			Type:      "notification",
			Code:      api.WSCodeDeviceUpdated, // Use event code for notifications
			Status:    api.WSStatusEvent,
			Message:   fmt.Sprintf("System notification: %s", message.Operation),
			Data:      message, // Include the original NotifyMessage as data
			Timestamp: time.Now(),
		}

		s.wsLock.RLock()
		clients := make([]*websocket.Conn, 0, len(s.wsClients))
		for conn := range s.wsClients {
			clients = append(clients, conn)
		}
		s.wsLock.RUnlock()

		var failedConnections []*websocket.Conn
		for _, conn := range clients {
			if err := s.safeWriteJSON(conn, broadcastMessage); err != nil {
				logging.GetLogger().Error("Error broadcasting to WebSocket client: %v", err)
				failedConnections = append(failedConnections, conn)
			}
		}

		// Clean up failed connections
		if len(failedConnections) > 0 {
			s.wsLock.Lock()
			for _, conn := range failedConnections {
				delete(s.wsClients, conn)
				delete(s.wsWriteMutex, conn)
				conn.Close()
			}
			s.wsLock.Unlock()
		}
	}
	return nil
}

// SubscribeToTopic subscribes a WebSocket connection to a specific topic
func (s *FusionServer) SubscribeToTopic(conn *websocket.Conn, topic string) {
	s.wsLock.Lock()
	if s.subscriptions[topic] == nil {
		s.subscriptions[topic] = make(map[*websocket.Conn]bool)
	}
	s.subscriptions[topic][conn] = true
	s.wsLock.Unlock()
	logging.GetLogger().Info("WebSocket client subscribed to topic: %s", topic)
}

// UnsubscribeFromTopic unsubscribes a WebSocket connection from a specific topic
func (s *FusionServer) UnsubscribeFromTopic(conn *websocket.Conn, topic string) {
	s.wsLock.Lock()
	if s.subscriptions[topic] != nil {
		delete(s.subscriptions[topic], conn)
		// Clean up empty topic maps
		if len(s.subscriptions[topic]) == 0 {
			delete(s.subscriptions, topic)
		}
	}
	s.wsLock.Unlock()
	logging.GetLogger().Info("WebSocket client unsubscribed from topic: %s", topic)
}

// BroadcastToTopic sends a message to all clients subscribed to a specific topic
func (s *FusionServer) BroadcastToTopic(topic string, message *api.WebSocketResponse) error {
	s.wsLock.RLock()
	subscribers := s.subscriptions[topic]
	if len(subscribers) == 0 {
		s.wsLock.RUnlock()
		return nil // No subscribers
	}

	// Copy subscribers to a slice under lock to avoid concurrent map access
	connections := make([]*websocket.Conn, 0, len(subscribers))
	for conn := range subscribers {
		connections = append(connections, conn)
	}
	s.wsLock.RUnlock()

	// Send to all subscribers of this topic
	var failedConnections []*websocket.Conn
	for _, conn := range connections {
		if err := s.safeWriteJSON(conn, message); err != nil {
			logging.GetLogger().Error("Error sending message to WebSocket client on topic %s: %v", topic, err)
			failedConnections = append(failedConnections, conn)
		}
	}

	// Clean up failed connections
	if len(failedConnections) > 0 {
		s.wsLock.Lock()
		for _, conn := range failedConnections {
			if s.subscriptions[topic] != nil {
				delete(s.subscriptions[topic], conn)
			}
			delete(s.wsWriteMutex, conn)
			delete(s.wsClients, conn)
			conn.Close()
		}
		// Clean up empty topic maps
		if len(s.subscriptions[topic]) == 0 {
			delete(s.subscriptions, topic)
		}
		s.wsLock.Unlock()
	}

	return nil
}
