package server

import (
	"fmt"
	"net/http"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"

	"github.com/gorilla/websocket"
)

const (
	wsBufferSize           = 1024        // Increased buffer size for better performance
	wsPingTime             = 30          // Ping interval in seconds
	wsPongTime             = 60          // Pong timeout in seconds
	wsTimeout              = 10          // Connection timeout in seconds
	wsMaxMessageSize       = 1024 * 1024 // Max message size (1MB)
	wsMaxConnections       = 1000        // Max concurrent connections
	wsConfigUpdateDebounce = 50 * time.Millisecond
)

// safeWriteJSON safely marshals with go-json and writes a text frame using the
// per-connection mutex. This avoids gorilla/websocket's stdlib JSON path.
func (s *FusionServer) safeWriteProto(conn *websocket.Conn, msg *model.WebSocketResponse) error {
	data, err := marshalWebSocketProto(msg)
	if err != nil {
		return err
	}
	return s.safeWriteRaw(conn, data)
}

// safeWritePrepared writes a prepared text message to a WebSocket connection.
func (s *FusionServer) safeWritePrepared(conn *websocket.Conn, message *websocket.PreparedMessage) error {
	client := s.getWSClient(conn)
	if client == nil {
		return fmt.Errorf("connection not found")
	}

	client.writeMu.Lock()
	defer client.writeMu.Unlock()
	return conn.WritePreparedMessage(message)
}

// safeWriteRaw writes pre-serialized bytes to a WebSocket connection as a text message.
func (s *FusionServer) safeWriteRaw(conn *websocket.Conn, data []byte) error {
	client := s.getWSClient(conn)
	if client == nil {
		return fmt.Errorf("connection not found")
	}

	client.writeMu.Lock()
	defer client.writeMu.Unlock()
	return conn.WriteMessage(websocket.TextMessage, data)
}

// safeWriteControl safely writes control messages to a WebSocket connection using per-connection mutex
func (s *FusionServer) safeWriteControl(conn *websocket.Conn, messageType int, data []byte, deadline time.Time) error {
	client := s.getWSClient(conn)
	if client == nil {
		return fmt.Errorf("connection not found")
	}

	client.writeMu.Lock()
	defer client.writeMu.Unlock()
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
	s.wsClients[conn] = &wsClientState{topics: make(map[string]struct{})}
	s.wsLock.Unlock()

	// Ensure cleanup when the function returns
	defer func() {
		s.meterFilterManager.RemoveFilter(conn, s.clusterMemberFilterAddrs())
		s.removeConnection(conn)
		logger.Debug("WebSocket connection closed")
	}()

	logger.Debug("WebSocket connection established")

	// Send initial state to the client
	initialState, err := s.handler.GetInitialState()
	if err != nil {
		logger.Error("Failed to get initial state: %v", err)
		return
	}

	// Send welcome message with connection info
	welcomeResponse := websocketResponse(nil, "welcome", api.WSCodeConnected, api.WSStatusEvent, "Connected successfully", initialState)

	if err := s.safeWriteProto(conn, welcomeResponse); err != nil {
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

		if messageType != websocket.TextMessage {
			logger.Warn("Unsupported WebSocket message type: %d", messageType)
			deadline := time.Now().Add(10 * time.Second)
			if err := s.safeWriteControl(conn, websocket.CloseMessage,
				websocket.FormatCloseMessage(websocket.CloseUnsupportedData, "text messages only"), deadline); err != nil {
				logger.Error("Failed to send close frame for unsupported message type: %v", err)
			}
			break
		}

		// Process the message
		s.handleWebSocketMessage(conn, data)
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

	if err := s.safeWriteProto(conn, response); err != nil {
		logger.Error("Error sending response: %v", err)
	}
}

// sendErrorToConnection sends an error response to a specific WebSocket connection
func (s *FusionServer) sendErrorToConnection(conn *websocket.Conn, requestID string, code int, message, status string) {
	var id *string
	if requestID != "" {
		id = &requestID
	}

	errorResponse := websocketResponse(id, api.WSMsgTypeError, code, status, message, nil)

	if err := s.safeWriteProto(conn, errorResponse); err != nil {
		logging.GetLogger().Error("Failed to send error response: %v", err)
	}
}

// SetMeterFilter replaces the meter ID filter for a WebSocket connection and updates
// the master filter sent to all cluster device telemetry cores.
func (s *FusionServer) SetMeterFilter(conn *websocket.Conn, ids []string) {
	s.meterFilterManager.SetFilter(conn, ids, s.clusterMemberFilterAddrs())
}

// RemoveMeterFilter removes the meter ID filter for a WebSocket connection and updates
// the master filter sent to all cluster device telemetry cores.
func (s *FusionServer) RemoveMeterFilter(conn *websocket.Conn) {
	s.meterFilterManager.RemoveFilter(conn, s.clusterMemberFilterAddrs())
}

// BroadcastMessage sends a notification message to all connected WebSocket clients.
// It acquires a read lock on the clients list to ensure thread-safe access.
func (s *FusionServer) BroadcastMessage(message *api.NotifyMessage) error {
	// Convert NotifyMessage to appropriate WebSocket format based on operation
	switch message.Operation {
	case api.NotifyOpMeterData:
		if message.MeterData != nil {
			return s.routeMeterData(message.MeterData)
		}
	case api.NotifyOpConfigUpdate:
		if message.ConfigUpdate != nil {
			return s.broadcastConfigUpdate(message)
		}
	case api.NotifyOpDeviceUpdate:
		if message.DeviceInfo != nil {
			// Convert device update to WebSocket response format
			updateMessage := websocketResponse(nil, api.WSMsgTypeDeviceUpdate, api.WSCodeDeviceUpdated, api.WSStatusEvent, fmt.Sprintf("Device %s updated", message.DeviceInfo.Id), message.DeviceInfo)
			// Send to topic-based subscribers
			return s.BroadcastToTopic(api.WSTopicDeviceUpdates, updateMessage)
		}
	case api.NotifyOpSoftwareUpdateProgress:
		return s.broadcastSoftwareUpdateProgress(message)
	}
	return s.broadcastGenericNotification(message)
}

func (s *FusionServer) BroadcastToClusterObservers(message *api.NotifyMessage) error {
	return s.BroadcastMessage(message)
}

func (s *FusionServer) broadcastConfigUpdate(message *api.NotifyMessage) error {
	s.enqueueConfigUpdate(message)
	return nil
}

func (s *FusionServer) enqueueConfigUpdate(message *api.NotifyMessage) {
	update := message.ConfigUpdate
	if update == nil {
		return
	}

	s.configUpdateMu.Lock()
	s.configUpdatePending = true
	s.mergeQueuedConfigUpdateLocked(update)
	if s.configUpdateDebounceTimer == nil {
		s.configUpdateDebounceTimer = time.AfterFunc(wsConfigUpdateDebounce, s.flushConfigUpdateQueue)
	}
	s.configUpdateMu.Unlock()
}

func (s *FusionServer) flushConfigUpdateQueue() {
	s.configUpdateMu.Lock()
	pending := s.configUpdatePending
	s.configUpdatePending = false
	data := s.configUpdateData
	snapshot := s.configUpdateSnapshot
	clear := s.configUpdateClear
	s.configUpdateData = nil
	s.configUpdateSnapshot = false
	s.configUpdateClear = false
	s.configUpdateMu.Unlock()

	if !pending {
		s.configUpdateMu.Lock()
		s.configUpdateDebounceTimer = nil
		s.configUpdateMu.Unlock()
		return
	}

	message := websocketResponse(nil, api.WSMsgTypeConfigUpdate, api.WSCodeUpdated, api.WSStatusEvent, "Configuration updated", wsConfigUpdatePayload(data, snapshot, clear))

	payloadBytes, err := marshalWebSocketProto(message)
	if err != nil {
		logging.GetLogger().Error("Error marshaling coalesced config update: %v", err)
	} else if err := s.BroadcastRawToTopic(api.WSTopicConfigUpdates, payloadBytes); err != nil {
		logging.GetLogger().Error("Error broadcasting coalesced config update: %v", err)
	}

	s.configUpdateMu.Lock()
	defer s.configUpdateMu.Unlock()
	if s.configUpdatePending {
		s.configUpdateDebounceTimer = time.AfterFunc(wsConfigUpdateDebounce, s.flushConfigUpdateQueue)
		return
	}
	s.configUpdateDebounceTimer = nil
}

func (s *FusionServer) mergeQueuedConfigUpdateLocked(update *api.ConfigUpdate) {
	payload, snapshot, clear := wsConfigUpdatePayloadData(update)
	if payload == nil {
		payload = map[string]any{}
	}

	if s.configUpdateSnapshot {
		if clear {
			s.configUpdateData = payload
			s.configUpdateClear = true
			return
		}
		mergeObserverDiffInto(s.configUpdateData, payload)
		return
	}

	if snapshot {
		s.configUpdateData = payload
		s.configUpdateSnapshot = true
		s.configUpdateClear = clear
		return
	}

	if s.configUpdateData == nil {
		s.configUpdateData = make(map[string]any)
	}
	mergeObserverDiffInto(s.configUpdateData, payload)
}

func wsConfigUpdatePayloadData(update *api.ConfigUpdate) (map[string]any, bool, bool) {
	if update == nil {
		return nil, true, false
	}
	if len(update.ObserverData) > 0 && !update.Clear {
		return cloneObserverDiff(update.ObserverData), false, false
	}
	return cloneObserverDiff(update.Data), true, update.Clear
}

func wsConfigUpdatePayload(data map[string]any, snapshot bool, clear bool) *model.WebSocketConfigUpdateEvent {
	if snapshot {
		state, _ := websocketStructFromMap(data)
		return &model.WebSocketConfigUpdateEvent{
			Mode:  "snapshot",
			State: state,
			Clear: clear,
		}
	}

	updates, _ := websocketStructFromMap(data)
	return &model.WebSocketConfigUpdateEvent{
		Mode:    "patch",
		Updates: updates,
	}
}

func mergeObserverDiffInto(dst, src map[string]any) {
	for key, value := range src {
		srcMap, srcIsMap := value.(map[string]any)
		if !srcIsMap {
			dst[key] = cloneObserverValue(value)
			continue
		}

		if existing, ok := dst[key].(map[string]any); ok {
			mergeObserverDiffInto(existing, srcMap)
			continue
		}
		dst[key] = cloneObserverDiff(srcMap)
	}
}

func cloneObserverDiff(src map[string]any) map[string]any {
	if src == nil {
		return nil
	}
	dst := make(map[string]any, len(src))
	for key, value := range src {
		dst[key] = cloneObserverValue(value)
	}
	return dst
}

func cloneObserverValue(v any) any {
	switch x := v.(type) {
	case map[string]any:
		return cloneObserverDiff(x)
	case []any:
		out := make([]any, len(x))
		for i := range x {
			out[i] = cloneObserverValue(x[i])
		}
		return out
	default:
		return v
	}
}

// SubscribeToTopic subscribes a WebSocket connection to a specific topic
func (s *FusionServer) SubscribeToTopic(conn *websocket.Conn, topic string) {
	s.wsLock.Lock()
	client := s.wsClients[conn]
	if client == nil {
		s.wsLock.Unlock()
		return
	}
	if s.subscriptions[topic] == nil {
		s.subscriptions[topic] = make(map[*websocket.Conn]bool)
	}
	s.subscriptions[topic][conn] = true
	client.topics[topic] = struct{}{}
	s.wsLock.Unlock()
	logging.GetLogger().Debug("WebSocket client subscribed to topic: %s", topic)
}

// UnsubscribeFromTopic unsubscribes a WebSocket connection from a specific topic
func (s *FusionServer) UnsubscribeFromTopic(conn *websocket.Conn, topic string) {
	s.wsLock.Lock()
	if client := s.wsClients[conn]; client != nil {
		delete(client.topics, topic)
	}
	if s.subscriptions[topic] != nil {
		delete(s.subscriptions[topic], conn)
		// Clean up empty topic maps
		if len(s.subscriptions[topic]) == 0 {
			delete(s.subscriptions, topic)
		}
	}
	s.wsLock.Unlock()
	logging.GetLogger().Debug("WebSocket client unsubscribed from topic: %s", topic)
}

// BroadcastToTopic sends a message to all clients subscribed to a specific topic
func (s *FusionServer) BroadcastToTopic(topic string, message *model.WebSocketResponse) error {
	data, err := marshalWebSocketProto(message)
	if err != nil {
		return fmt.Errorf("failed to marshal WebSocket message: %w", err)
	}
	return s.BroadcastRawToTopic(topic, data)
}

// BroadcastRawToTopic sends a pre-serialized WebSocket text payload to all
// clients subscribed to a specific topic.
func (s *FusionServer) BroadcastRawToTopic(topic string, data []byte) error {
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

	prepared, err := websocket.NewPreparedMessage(websocket.TextMessage, data)
	if err != nil {
		return fmt.Errorf("failed to prepare WebSocket message: %w", err)
	}

	var failedConnections []*websocket.Conn
	for _, conn := range connections {
		if err := s.safeWritePrepared(conn, prepared); err != nil {
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
			s.removeConnectionLocked(conn)
		}
		// Clean up empty topic maps
		if len(s.subscriptions[topic]) == 0 {
			delete(s.subscriptions, topic)
		}
		s.wsLock.Unlock()
	}

	return nil
}

// routeMeterData fans out meter data to each subscribed WebSocket connection,
// sending only the subset of samples that each client has registered a filter for.
// The sent payload preserves the original telemetry message structure.
func (s *FusionServer) routeMeterData(msg *api.MeterDataMessage) error {
	s.wsLock.RLock()
	subscribers := s.subscriptions[api.WSTopicMeterData]
	conns := make([]*websocket.Conn, 0, len(subscribers))
	for conn := range subscribers {
		conns = append(conns, conn)
	}
	s.wsLock.RUnlock()

	if len(conns) == 0 {
		return nil
	}

	var failedConnections []*websocket.Conn
	for _, conn := range conns {
		filtered := s.meterFilterManager.FilterMeterDataForConn(conn, msg)
		if filtered == nil {
			continue
		}
		wsMsg := websocketResponse(nil, api.WSMsgTypeMeterData, api.WSCodeDeviceUpdated, api.WSStatusEvent, "meter_data", filtered)
		if err := s.safeWriteProto(conn, wsMsg); err != nil {
			logging.GetLogger().Error("Error routing meter data to WebSocket client: %v", err)
			failedConnections = append(failedConnections, conn)
		}
	}

	if len(failedConnections) > 0 {
		addrs := s.clusterMemberFilterAddrs()
		for _, conn := range failedConnections {
			s.meterFilterManager.RemoveFilter(conn, addrs)
		}

		s.wsLock.Lock()
		for _, conn := range failedConnections {
			s.removeConnectionLocked(conn)
		}
		s.wsLock.Unlock()
	}

	return nil
}

func (s *FusionServer) broadcastGenericNotification(message *api.NotifyMessage) error {
	broadcastMessage := websocketResponse(nil, "notification", api.WSCodeDeviceUpdated, api.WSStatusEvent, fmt.Sprintf("System notification: %s", message.Operation), message)
	return s.broadcastToAllClients(broadcastMessage)
}

// broadcastToAllClients sends a WebSocket response to every connected client,
// cleaning up any connections that fail during the send.
func (s *FusionServer) broadcastToAllClients(message *model.WebSocketResponse) error {
	s.wsLock.RLock()
	clients := make([]*websocket.Conn, 0, len(s.wsClients))
	for conn := range s.wsClients {
		clients = append(clients, conn)
	}
	s.wsLock.RUnlock()

	// Pre-serialize once for all clients.
	data, err := marshalWebSocketProto(message)
	if err != nil {
		return fmt.Errorf("failed to marshal WebSocket broadcast: %w", err)
	}
	prepared, err := websocket.NewPreparedMessage(websocket.TextMessage, data)
	if err != nil {
		return fmt.Errorf("failed to prepare WebSocket broadcast: %w", err)
	}

	var failedConnections []*websocket.Conn
	for _, conn := range clients {
		if err := s.safeWritePrepared(conn, prepared); err != nil {
			logging.GetLogger().Error("Error broadcasting to WebSocket client: %v", err)
			failedConnections = append(failedConnections, conn)
		}
	}

	if len(failedConnections) > 0 {
		s.wsLock.Lock()
		for _, conn := range failedConnections {
			s.removeConnectionLocked(conn)
		}
		s.wsLock.Unlock()
	}

	return nil
}

func (s *FusionServer) getWSClient(conn *websocket.Conn) *wsClientState {
	s.wsLock.RLock()
	client := s.wsClients[conn]
	s.wsLock.RUnlock()
	return client
}

func (s *FusionServer) removeConnection(conn *websocket.Conn) {
	s.wsLock.Lock()
	s.removeConnectionLocked(conn)
	s.wsLock.Unlock()
}

func (s *FusionServer) removeConnectionLocked(conn *websocket.Conn) {
	client := s.wsClients[conn]
	if client != nil {
		for topic := range client.topics {
			if subscribers := s.subscriptions[topic]; subscribers != nil {
				delete(subscribers, conn)
				if len(subscribers) == 0 {
					delete(s.subscriptions, topic)
				}
			}
		}
	}
	delete(s.wsClients, conn)
	conn.Close()
}
