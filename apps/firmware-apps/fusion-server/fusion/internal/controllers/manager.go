package controllers

import (
	"encoding/json"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/pubsub"
	"net"
	"time"
)

func NewControllerManager(hub *pubsub.Hub, tcpPort string) *ControllerManager {
	cm := &ControllerManager{
		hub:         hub,
		controllers: make(map[string]*ControllerConnection),
	}

	// Create the TCP server with the controller manager
	cm.tcpServer = NewWallControllerTCPServer(":"+tcpPort, cm)

	return cm
}

// Start initializes the ControllerManager
func (cm *ControllerManager) Start() error {
	logger := logging.GetLogger()

	// Start the TCP server
	err := cm.tcpServer.Start()
	if err != nil {
		logger.Error("Failed to start TCP server: %v", err)
		return fmt.Errorf("failed to start TCP server: %v", err)
	}

	return nil
}

// Stop gracefully shuts down the ControllerManager
func (cm *ControllerManager) Stop() error {
	logger := logging.GetLogger()
	logger.Debug("Stopping ControllerManager...")

	// Stop TCP server
	if cm.tcpServer != nil {
		cm.tcpServer.Stop()
		cm.tcpServer = nil
	}
	return nil
}

// =================== TCP Event Handlers ===================

// OnControllerConnected handles new TCP connections
func (cm *ControllerManager) OnControllerConnected(connectionID string, conn net.Conn) {
	logger := logging.GetLogger()
	logger.Info("New controller connected: %s (Remote: %s)", connectionID, conn.RemoteAddr())

	// Create controller entry
	cm.mutex.Lock()
	cm.controllers[connectionID] = &ControllerConnection{
		Connection:   conn,
		ConnectedAt:  time.Now(),
		IsIdentified: false,
	}
	currentCount := len(cm.controllers)
	cm.mutex.Unlock()

	logger.Debug("Active connections: %d", currentCount)

	// Send identification request
	identifyMessage := api.ControllerTCPMessage{
		Action:  "identify",
		Payload: json.RawMessage(`{}`),
	}

	messageBytes, err := json.Marshal(identifyMessage)
	if err != nil {
		logger.Error("Failed to marshal identify message: %v", err)
		return
	}

	_, err = conn.Write(append(messageBytes, '\n'))
	if err != nil {
		logger.Error("Failed to send identify message to %s: %v", connectionID, err)
		cm.OnControllerDisconnected(connectionID)
		return
	}

	logger.Debug("Sent identify message to controller %s: %s", connectionID, string(messageBytes))
}

// OnControllerDisconnected handles TCP disconnections
func (cm *ControllerManager) OnControllerDisconnected(connectionID string) {
	logger := logging.GetLogger()

	cm.mutex.Lock()
	controller, exists := cm.controllers[connectionID]
	if exists {
		delete(cm.controllers, connectionID)
	}
	currentCount := len(cm.controllers)
	cm.mutex.Unlock()

	if exists && controller.IsIdentified {
		logger.Info("Controller disconnected: %s (ID: %s)", connectionID, controller.Info.ID)

		// TODO: Broadcast controller disconnection event here if/when needed.
	} else {
		logger.Info("Unidentified controller disconnected: %s", connectionID)
	}

	logger.Debug("Active connections: %d", currentCount)
}

// OnControllerMessage handles incoming TCP messages
func (cm *ControllerManager) OnControllerMessage(connectionID string, message []byte) {
	logger := logging.GetLogger()
	logger.Debug("Received message from %s: %s", connectionID, string(message))

	// Parse JSON message
	var msg api.ControllerTCPMessage
	err := json.Unmarshal(message, &msg)
	if err != nil {
		logger.Error("Invalid JSON from controller %s: %v", connectionID, err)
		logger.Error("Raw message: %s", string(message))
		return
	}

	action := msg.Action

	logger.Debug("Processing action '%s' from controller %s", action, connectionID)

	switch action {
	case "identity":
		cm.handleIdentityResponse(connectionID, msg)
	case "winkResponse":
		cm.handleWinkResponse(connectionID, msg)
	default:
		logger.Warn("Unknown action '%s' from controller %s", action, connectionID)
	}
}

// =================== Message Handlers ===================

// handleIdentityResponse processes controller identification
func (cm *ControllerManager) handleIdentityResponse(connectionID string, message api.ControllerTCPMessage) {
	logger := logging.GetLogger()
	logger.Debug("Processing identity response from %s", connectionID)

	var payload api.ControllerIdentifyResponse
	if err := json.Unmarshal(message.Payload, &payload); err != nil {
		logger.Error("Invalid identity payload from controller %s: %v", connectionID, err)
		logger.Error("Message structure: %+v", message)
		return
	}

	logger.Debug("Identity details - ID: %s, Type: %s, Version: %s", payload.ID, payload.DeviceType, payload.FirmwareVersion)

	if payload.ID == "" {
		logger.Error("Missing controller ID in identity from %s", connectionID)
		logger.Error("Payload content: %+v", payload)
		return
	}

	cm.mutex.Lock()
	controller, exists := cm.controllers[connectionID]
	if exists {
		controller.Info = &api.ControllerInfo{
			ID:      payload.ID,
			Name:    payload.DeviceType,
			Version: payload.FirmwareVersion,
			Address: controller.Connection.RemoteAddr().String(),
		}
		controller.IsIdentified = true
		controller.LastActivity = time.Now()
		logger.Debug("Controller %s identified successfully (Connection: %s)", payload.ID, connectionID)
	}
	cm.mutex.Unlock()

	// if exists {
	// 	// Broadcast identification event
	// 	event := &api.NotifyMessage{
	// 		Operation: api.NotifyOpControllerAdd,
	// 		ConfigUpdate: &api.ConfigUpdate{
	// 			Data: map[string]interface{}{
	// 				"action":          "controller_connected",
	// 				"controllerID":    controllerID,
	// 				"deviceType":      deviceType,
	// 				"firmwareVersion": firmwareVersion,
	// 				"timestamp":       time.Now(),
	// 			},
	// 		},
	// 	}
	// 	cm.hub.Broadcast(event)
	// 	logger.Debug("📡 Broadcasted controller identification event for %s", controllerID)
	// }
}

// handleWinkResponse processes wink command responses
func (cm *ControllerManager) handleWinkResponse(connectionID string, message api.ControllerTCPMessage) {
	logger := logging.GetLogger()

	var payload api.ControllerWinkResponse
	if err := json.Unmarshal(message.Payload, &payload); err != nil {
		logger.Error("Invalid winkResponse payload from controller %s", connectionID)
		logger.Error("Message structure: %+v", message)
		return
	}

	cm.mutex.RLock()
	controller, exists := cm.controllers[connectionID]
	cm.mutex.RUnlock()

	if !exists || !controller.IsIdentified {
		logger.Error("Wink response from unidentified controller %s", connectionID)
		return
	}

	logger.Debug("Wink response from controller %s: %s", controller.Info.ID, payload.Status)

	// // Broadcast wink event
	// eventType := "controller_winking"
	// if status == "done" {
	// 	eventType = "controller_wink_complete"
	// }

	// event := map[string]interface{}{
	// 	"type": eventType,
	// 	"controller": map[string]interface{}{
	// 		"id":           controller.Info.ID,
	// 		"connectionId": connectionID,
	// 		"status":       status,
	// 		"timestamp":    time.Now(),
	// 	},
	// }
	// cm.broadcastEvent(event)
}

// =================== HTTP API Implementation ===================

// GetActiveControllers returns all identified controllers
func (cm *ControllerManager) GetActiveControllers() []*api.ControllerInfo {
	logger := logging.GetLogger()
	cm.mutex.RLock()
	defer cm.mutex.RUnlock()

	logger.Debug("GetControllers called - checking %d total connections", len(cm.controllers))

	var controllers []*api.ControllerInfo
	for connectionID, conn := range cm.controllers {
		logger.Debug("Connection %s: IsIdentified=%t, Info=%v", connectionID, conn.IsIdentified, conn.Info != nil)
		if conn.IsIdentified && conn.Info != nil {
			logger.Debug("    Adding controller: %s", conn.Info.ID)
			controllers = append(controllers, conn.Info)
		}
	}

	logger.Debug("Returning %d identified controllers", len(controllers))
	return controllers
}

// GetControllerByID returns a specific controller by ID
func (cm *ControllerManager) GetControllerByID(id string) (*api.ControllerInfo, error) {
	cm.mutex.RLock()
	defer cm.mutex.RUnlock()

	for _, conn := range cm.controllers {
		if conn.IsIdentified && conn.Info != nil && conn.Info.ID == id {
			return conn.Info, nil
		}
	}

	return nil, fmt.Errorf("controller with ID %s not found", id)
}

// StartWinkCommand initiates a wink command for a controller
func (cm *ControllerManager) StartWinkCommand(controllerID string) error {
	type winkPayload struct {
		Duration  int64 `json:"duration"`
		Timestamp int64 `json:"timestamp"`
	}
	type winkMessage struct {
		Action  string      `json:"action"`
		Payload winkPayload `json:"payload"`
	}

	logger := logging.GetLogger()
	logger.Debug("💡 Starting wink command for controller %s", controllerID)

	// Find the controller connection
	cm.mutex.RLock()
	var targetConn *ControllerConnection
	for _, conn := range cm.controllers {
		if conn.IsIdentified && conn.Info != nil && conn.Info.ID == controllerID {
			targetConn = conn
			break
		}
	}
	cm.mutex.RUnlock()

	if targetConn == nil {
		logger.Error("❌ Controller %s not found or not connected", controllerID)
		return fmt.Errorf("controller with ID %s not found or not connected", controllerID)
	}

	logger.Debug("✅ Found controller %s, sending wink command", controllerID)

	// Send wink command
	winkMsg := winkMessage{
		Action: "performWink",
		Payload: winkPayload{
			Duration:  5000, // 5 seconds
			Timestamp: time.Now().Unix(),
		},
	}

	messageBytes, err := json.Marshal(winkMsg)
	if err != nil {
		logger.Error("❌ Failed to marshal wink message: %v", err)
		return fmt.Errorf("failed to marshal wink message: %v", err)
	}

	_, err = targetConn.Connection.Write(append(messageBytes, '\n'))
	if err != nil {
		logger.Error("❌ Failed to send wink command to controller %s: %v", controllerID, err)
		return fmt.Errorf("failed to send wink command: %v", err)
	}

	logger.Debug("📤 Sent wink command to controller %s: %s", controllerID, string(messageBytes))
	return nil
}

// =================== Utility Methods ===================

// broadcastEvent sends events to WebSocket clients
// func (cm *ControllerManager) broadcastEvent(event map[string]interface{}) {
// 	// Determine the operation type based on event type
// 	var operation api.NotifyOp
// 	if eventType, exists := event["type"].(string); exists {
// 		switch eventType {
// 		case "controller_connected":
// 			operation = api.NotifyOpControllerAdd
// 		case "controller_disconnected":
// 			operation = api.NotifyOpControllerRemove
// 		default:
// 			operation = api.NotifyOpConfigUpdate // Default for other events like winking
// 		}
// 	} else {
// 		operation = api.NotifyOpConfigUpdate
// 	}

// 	// Create a NotifyMessage to send the event
// 	notifyMsg := &api.NotifyMessage{
// 		ID:        fmt.Sprintf("controller-event-%d", time.Now().UnixNano()),
// 		Operation: operation,
// 		Node:      "controller-manager",
// 		SentAt:    time.Now(),
// 		ConfigUpdate: &api.ConfigUpdate{
// 			Data: event,
// 		},
// 	}

// 	cm.hub.Broadcast(notifyMsg)
// }
