package handler

import (
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"path/filepath"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
)

// WebSocket error message constants to avoid hardcoding
const (
	ErrInvalidPayload = "Invalid data payload"
)

// WebSocketServer interface for server operations required by the handler
type WebSocketServer interface {
	// Topic-based subscription methods
	SubscribeToTopic(conn *websocket.Conn, topic string)
	UnsubscribeFromTopic(conn *websocket.Conn, topic string)
	BroadcastToTopic(topic string, message *model.WebSocketResponse) error
}

// HandleWebSocketMessageWithConn processes incoming WebSocket messages and enables pull-then-push pattern
func (h *Handler) HandleWebSocketMessageWithConn(data []byte, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	logger := logging.GetLogger()

	// Parse WebSocket request
	var request model.WebSocketRequest
	if err := protojson.Unmarshal(data, &request); err != nil {
		return createErrorResponse(nil, api.WSCodeInvalidJSON, "Invalid JSON format"), nil
	}

	// Validate required fields
	if request.Id == "" {
		return createErrorResponse(nil, api.WSCodeMissingField, "Missing required field: id"), nil
	}

	if request.Version != int32(api.WSCurrentVersion) {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, "Unsupported protocol version"), nil
	}

	if request.Type == "" {
		return createErrorResponse(&request.Id, api.WSCodeMissingField, "Missing required field: type"), nil
	}

	logger.Debug("Processing WebSocket message: %s (ID: %s)", request.Type, request.Id)

	// Route to appropriate handler based on message type
	response, err := h.routeWebSocketMessageWithConn(&request, conn, server)
	if err != nil {
		logger.Error("WebSocket message routing error: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, err.Error()), nil
	}

	return response, nil
}

// routeWebSocketMessageWithConn routes messages to appropriate handlers with connection context for subscriptions
func (h *Handler) routeWebSocketMessageWithConn(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	switch request.Type {
	case api.WSMsgTypeDevices:
		return h.handleDevicesWithSubscription(request, conn, server)
	case api.WSMsgTypeDeviceByID:
		return h.handleDeviceByIDWithSubscription(request, conn, server)
	case api.WSMsgTypeUpdateDeviceInfo:
		return h.handleUpdateDeviceInfoWithNotification(request, server)
	case api.WSMsgTypeConfiguration:
		return h.handleConfigurationWithSubscription(request, conn, server)
	case api.WSMsgTypePatchConfiguration:
		return h.handlePatchConfigurationWithNotification(request)
	case api.WSMsgTypeUnsubscribeConfig:
		return h.handleUnsubscribeConfig(request, conn, server)
	case api.WSMsgTypeUnsubscribeDevices:
		return h.handleUnsubscribeDevices(request, conn, server)
	case api.WSMsgTypePing:
		return h.handlePing(request)
	case api.WSMsgTypeStartUpdate:
		return h.handleStartUpdate(request)
	case api.WSMsgTypeSwUpdateInfo:
		return h.handleSwUpdateInfo(request)
	case api.WSMsgTypeListSoftwareUpdates:
		return h.handleListSoftwareUpdates(request)
	default:
		return createErrorResponse(&request.Id, api.WSCodeInvalidType, fmt.Sprintf("Unknown message type: %s", request.Type)), nil
	}
}

// handleConfigurationWithSubscription returns current config and subscribes client to config updates (Pull-then-Push)
func (h *Handler) handleConfigurationWithSubscription(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	state, err := h.GetInitialState()
	if err != nil {
		logging.GetLogger().Error("Failed to get configuration state: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to retrieve configuration: %v", err)), nil
	}

	server.SubscribeToTopic(conn, api.WSTopicConfigUpdates)
	logging.GetLogger().Info("Client subscribed to configuration updates for request %s", request.Id)

	return createSuccessResponse(&request.Id, api.WSMsgTypeConfiguration, api.WSCodeOK, "OK - subscribed to configuration updates", state), nil
}

// handleDevicesWithSubscription handles device listing requests and subscribes client to updates (Pull-then-Push)
func (h *Handler) handleDevicesWithSubscription(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	// Subscribe client to device updates for push notifications
	server.SubscribeToTopic(conn, api.WSTopicDeviceUpdates)
	logging.GetLogger().Info("Client subscribed to device updates for request %s", request.Id)

	// Get actual device information from persistence
	devices, err := h.getDevicesList()
	if err != nil {
		logging.GetLogger().Error("Failed to get devices list: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to retrieve devices: %v", err)), nil
	}

	return createSuccessResponse(&request.Id, api.WSMsgTypeDevices, api.WSCodeOK, "OK - subscribed to device updates", devices), nil
}

// handleDeviceByIDWithSubscription handles device lookup by ID and subscribes client to that device's updates
func (h *Handler) handleDeviceByIDWithSubscription(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	var payload model.WebSocketDeviceLookupRequest
	if err := websocketRequestDataToProto(request.Data, &payload); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

	if payload.DeviceId == "" {
		return createErrorResponse(&request.Id, api.WSCodeMissingDeviceID, "Missing device_id in payload"), nil
	}

	// Subscribe client to device updates for push notifications
	server.SubscribeToTopic(conn, api.WSTopicDeviceUpdates)
	logging.GetLogger().Info("Client subscribed to device updates for device %s", payload.DeviceId)

	// Get actual device by ID from persistence
	device, err := h.getDeviceByID(payload.DeviceId)
	if err != nil {
		return createErrorResponse(&request.Id, api.WSCodeDeviceNotFound, fmt.Sprintf("Device not found: %s", payload.DeviceId)), nil
	}

	return createSuccessResponse(&request.Id, api.WSMsgTypeDeviceByID, api.WSCodeOK, "OK - subscribed to device updates", device), nil
}

// handleUpdateDeviceInfoWithNotification handles device updates and broadcasts changes to subscribed clients
func (h *Handler) handleUpdateDeviceInfoWithNotification(request *model.WebSocketRequest, server WebSocketServer) (*model.WebSocketResponse, error) {
	var payload model.WebSocketUpdateDeviceInfoRequest
	if err := websocketRequestDataToProto(request.Data, &payload); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

	if payload.DeviceId == "" {
		return createErrorResponse(&request.Id, api.WSCodeMissingDeviceID, "Missing device_id in payload"), nil
	}

	patch := api.DevicePatch{
		Id:       payload.Id,
		Location: payload.Location,
		Name:     payload.Name,
	}

	// Update device using cluster-aware device provider
	err := h.updateDeviceInfo(payload.DeviceId, &patch)
	if err != nil {
		return createErrorResponse(&request.Id, api.WSCodeUpdateFailed, fmt.Sprintf("Failed to update device: %v", err)), nil
	}

	// Return success immediately - updated device info will be sent via push notification
	// when gossip protocol propagates the change across cluster nodes
	logging.GetLogger().Info("Device %s updated successfully, push notification will be sent when cluster sync completes", payload.DeviceId)
	return createSuccessResponse(&request.Id, api.WSMsgTypeUpdateDeviceInfo, api.WSCodeUpdated, "Device updated successfully", map[string]interface{}{
		"device_id": payload.DeviceId,
		"message":   "Device updated successfully. Updated device info will be sent via push notification.",
	}), nil
}

// handlePatchConfigurationWithNotification applies a partial state patch and notifies config subscribers
func (h *Handler) handlePatchConfigurationWithNotification(request *model.WebSocketRequest) (*model.WebSocketResponse, error) {
	var patchData map[string]any
	if err := websocketRequestDataToAny(request.Data, &patchData); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

	// Explicitly reject nil patch data (JSON null) since patch_config expects an object
	if patchData == nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, "Patch data cannot be null - expected object"), nil
	}

	diff, err := h.HandleHTTPPatch(patchData)
	if err != nil {
		return createErrorResponse(&request.Id, api.WSCodeUpdateFailed, fmt.Sprintf("Failed to patch configuration: %v", err)), nil
	}

	if diff == nil {
		return createSuccessResponse(&request.Id, api.WSMsgTypePatchConfiguration, api.WSCodeOK, "No configuration changes applied", nil), nil
	}

	// Wrap diff in updates field to match REST API pattern
	responseData := map[string]any{
		"updates": diff,
	}

	return createSuccessResponse(&request.Id, api.WSMsgTypePatchConfiguration, api.WSCodeUpdated, "Configuration patched successfully", responseData), nil
}

// handleUnsubscribeConfig unsubscribes client from config update events
func (h *Handler) handleUnsubscribeConfig(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	server.UnsubscribeFromTopic(conn, api.WSTopicConfigUpdates)
	return createSuccessResponse(&request.Id, api.WSMsgTypeUnsubscribeConfig, api.WSCodeOK, "Unsubscribed from configuration updates", nil), nil
}

// handleUnsubscribeDevices allows clients to unsubscribe from device updates
func (h *Handler) handleUnsubscribeDevices(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	server.UnsubscribeFromTopic(conn, api.WSTopicDeviceUpdates)
	return createSuccessResponse(&request.Id, api.WSMsgTypeUnsubscribeDevices, api.WSCodeOK, "Unsubscribed from device updates", nil), nil
}

// handlePing handles ping requests
func (h *Handler) handlePing(request *model.WebSocketRequest) (*model.WebSocketResponse, error) {
	return createSuccessResponse(&request.Id, api.WSMsgTypePong, api.WSCodePong, "pong", nil), nil
}

// handleStartUpdate handles software update trigger requests
func (h *Handler) handleStartUpdate(request *model.WebSocketRequest) (*model.WebSocketResponse, error) {
	logger := logging.GetLogger()

	logger.Info("Received software update start request - broadcasting to cluster")

	// Check that at least one .swu file is present in the OTA directory before triggering an update
	swuFiles, err := filepath.Glob(filepath.Join(api.SoftwareUpdateOTAPath, "*.swu"))
	if err != nil {
		logger.Error("Failed to check OTA directory for .swu files: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to check OTA directory: %v", err)), nil
	}
	if len(swuFiles) == 0 {
		logger.Warn("Software update requested but no .swu files found in %s", api.SoftwareUpdateOTAPath)
		return createErrorResponse(&request.Id, api.WSCodeUpdateFailed, fmt.Sprintf("No .swu bundle found in %s — upload a bundle before triggering an update", api.SoftwareUpdateOTAPath)), nil
	}
	logger.Info("Found %d .swu file(s) in %s, proceeding with update", len(swuFiles), api.SoftwareUpdateOTAPath)

	// Count followers and ensure every .swu file is present on all followers
	// before triggering the update. And gossip + HTTP-pull sync as the upload API.
	// Followers that already have the file with a matching checksum ack immediately (no re-download).
	followerCount, syncErr := h.ensureSWUFilesOnFollowers(swuFiles)
	if syncErr != nil {
		logger.Error("[StartUpdate] SWU file sync to followers failed: %v", syncErr)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError,
			fmt.Sprintf("Failed to sync SWU files to cluster before triggering update: %v", syncErr)), nil
	}
	logger.Info("[StartUpdate] %d follower(s) confirmed — all SWU files present on all nodes, proceeding with trigger", followerCount)

	// All nodes have the files — broadcast the update trigger
	// Create a cluster message to broadcast the software update trigger to all nodes
	// This will call the delegate's handleSoftwareUpdate method on each node
	msg := api.NewNotifyMessage(
		api.NotifyOpSoftwareUpdate,
		h.clusterTransport.LocalNode().Name,
		func(m *api.NotifyMessage) {
			// No additional data needed for software update trigger
		},
	)

	// Broadcast to all nodes in the cluster (this calls delegate.handleSoftwareUpdate)
	if err := h.hub.BroadcastToNodes(msg); err != nil {
		logger.Error("Failed to broadcast software update to cluster: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to broadcast software update: %v", err)), nil
	}

	logger.Info("Successfully broadcasted software update trigger to cluster")
	return createSuccessResponse(&request.Id, api.WSMsgTypeStartUpdate, api.WSCodeUpdateStarted, "Software update broadcasted to all cluster nodes", map[string]interface{}{
		"action": "broadcast_cluster",
		"nodes":  h.clusterTransport.MemberListMembers(),
	}), nil
}

// getDevicesList retrieves all devices
func (h *Handler) getDevicesList() ([]api.DeviceInfo, error) {

	devicesInfo := h.clusterTransport.GetAllDevicesInfo()

	return devicesInfo, nil

}

// getDeviceByID retrieves a specific device by ID
func (h *Handler) getDeviceByID(deviceID string) (*api.DeviceInfo, error) {

	// Search all cluster devices
	allDevices := h.clusterTransport.GetAllDevicesInfo()

	// Find device with matching ID
	for i, deviceInfo := range allDevices {
		if deviceInfo.Id == deviceID {
			return &allDevices[i], nil
		}
	}

	// Device not found in any cluster node
	return nil, fmt.Errorf("device not found")
}

// updateDeviceInfo updates device information
func (h *Handler) updateDeviceInfo(deviceID string, patch *api.DevicePatch) error {
	return h.clusterTransport.UpdateDeviceInfo(deviceID, patch)
}
