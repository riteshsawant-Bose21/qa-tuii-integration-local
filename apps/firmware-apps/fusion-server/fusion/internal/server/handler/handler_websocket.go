package handler

import (
	"fmt"
	"path/filepath"

	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/encoding/protojson"
)

const (
	ErrInvalidPayload = "Invalid data payload"
)

type WebSocketServer interface {
	SubscribeToTopic(conn *websocket.Conn, topic string)
	UnsubscribeFromTopic(conn *websocket.Conn, topic string)
	BroadcastToTopic(topic string, message *model.WebSocketResponse) error
	SetMeterFilter(conn *websocket.Conn, ids []string)
	RemoveMeterFilter(conn *websocket.Conn)
}

func (h *Handler) HandleWebSocketMessageWithConn(data []byte, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	logger := logging.GetLogger()

	var request model.WebSocketRequest
	if err := protojson.Unmarshal(data, &request); err != nil {
		return createErrorResponse(nil, api.WSCodeInvalidJSON, "Invalid JSON format"), nil
	}

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

	response, err := h.routeWebSocketMessageWithConn(&request, conn, server)
	if err != nil {
		logger.Error("WebSocket message routing error: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, err.Error()), nil
	}

	return response, nil
}

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
	case api.WSMsgTypeSubscribeMeterData:
		return h.handleMeterDataWithSubscription(request, conn, server)
	case api.WSMsgTypeUpdateMeterDataFilter:
		return h.handlePatchMeterDataFilter(request, conn, server)
	case api.WSMsgTypeUnsubscribeMeterData:
		return h.handleUnsubscribeMeterData(request, conn, server)
	default:
		return createErrorResponse(&request.Id, api.WSCodeInvalidType, fmt.Sprintf("Unknown message type: %s", request.Type)), nil
	}
}

func (h *Handler) handleConfigurationWithSubscription(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	state, err := h.GetInitialState()
	if err != nil {
		logging.GetLogger().Error("Failed to get configuration state: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to retrieve configuration: %v", err)), nil
	}

	server.SubscribeToTopic(conn, api.WSTopicConfigUpdates)
	logging.GetLogger().Debug("Client subscribed to configuration updates for request %s", request.Id)

	return createSuccessResponse(&request.Id, api.WSMsgTypeConfiguration, api.WSCodeOK, "OK - subscribed to configuration updates", state), nil
}

func (h *Handler) handleDevicesWithSubscription(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	server.SubscribeToTopic(conn, api.WSTopicDeviceUpdates)
	logging.GetLogger().Debug("Client subscribed to device updates for request %s", request.Id)

	devices, err := h.getDevicesList()
	if err != nil {
		logging.GetLogger().Error("Failed to get devices list: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to retrieve devices: %v", err)), nil
	}

	return createSuccessResponse(&request.Id, api.WSMsgTypeDevices, api.WSCodeOK, "OK - subscribed to device updates", devices), nil
}

func (h *Handler) handleDeviceByIDWithSubscription(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	var payload model.WebSocketDeviceLookupRequest
	if err := websocketRequestDataToProto(request.Data, &payload); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

	if payload.DeviceId == "" {
		return createErrorResponse(&request.Id, api.WSCodeMissingDeviceID, "Missing device_id in payload"), nil
	}

	server.SubscribeToTopic(conn, api.WSTopicDeviceUpdates)
	logging.GetLogger().Debug("Client subscribed to device updates for device %s", payload.DeviceId)

	device, err := h.getDeviceByID(payload.DeviceId)
	if err != nil {
		return createErrorResponse(&request.Id, api.WSCodeDeviceNotFound, fmt.Sprintf("Device not found: %s", payload.DeviceId)), nil
	}

	return createSuccessResponse(&request.Id, api.WSMsgTypeDeviceByID, api.WSCodeOK, "OK - subscribed to device updates", device), nil
}

func (h *Handler) handleUpdateDeviceInfoWithNotification(request *model.WebSocketRequest, server WebSocketServer) (*model.WebSocketResponse, error) {
	var payload model.WebSocketUpdateDeviceInfoRequest
	if err := websocketRequestDataToProto(request.Data, &payload); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

	if payload.DeviceId == "" {
		return createErrorResponse(&request.Id, api.WSCodeMissingDeviceID, "Missing device_id in payload"), nil
	}

	patch := model.DevicePatch{
		Id:       payload.Id,
		Location: payload.Location,
		Name:     payload.Name,
	}

	if err := h.updateDeviceInfo(payload.DeviceId, &patch); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeUpdateFailed, fmt.Sprintf("Failed to update device: %v", err)), nil
	}

	logging.GetLogger().Debug("Device %s updated successfully, push notification will be sent when cluster sync completes", payload.DeviceId)
	return createSuccessResponse(&request.Id, api.WSMsgTypeUpdateDeviceInfo, api.WSCodeUpdated, "Device updated successfully", map[string]interface{}{
		"device_id": payload.DeviceId,
		"message":   "Device updated successfully. Updated device info will be sent via push notification.",
	}), nil
}

func (h *Handler) handlePatchConfigurationWithNotification(request *model.WebSocketRequest) (*model.WebSocketResponse, error) {
	var patchData map[string]any
	if err := websocketRequestDataToAny(request.Data, &patchData); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

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

	return createSuccessResponse(&request.Id, api.WSMsgTypePatchConfiguration, api.WSCodeUpdated, "Configuration patched successfully", map[string]any{
		"updates": diff,
	}), nil
}

func (h *Handler) handleUnsubscribeConfig(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	server.UnsubscribeFromTopic(conn, api.WSTopicConfigUpdates)
	return createSuccessResponse(&request.Id, api.WSMsgTypeUnsubscribeConfig, api.WSCodeOK, "Unsubscribed from configuration updates", nil), nil
}

func (h *Handler) handleUnsubscribeDevices(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	server.UnsubscribeFromTopic(conn, api.WSTopicDeviceUpdates)
	return createSuccessResponse(&request.Id, api.WSMsgTypeUnsubscribeDevices, api.WSCodeOK, "Unsubscribed from device updates", nil), nil
}

func (h *Handler) handlePing(request *model.WebSocketRequest) (*model.WebSocketResponse, error) {
	return createSuccessResponse(&request.Id, api.WSMsgTypePong, api.WSCodePong, "pong", nil), nil
}

func (h *Handler) handleStartUpdate(request *model.WebSocketRequest) (*model.WebSocketResponse, error) {
	logger := logging.GetLogger()

	logger.Debug("Received software update start request - broadcasting to cluster")

	swuFiles, err := filepath.Glob(filepath.Join(api.SoftwareUpdateOTAPath, "*.swu"))
	if err != nil {
		logger.Error("Failed to check OTA directory for .swu files: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to check OTA directory: %v", err)), nil
	}
	if len(swuFiles) == 0 {
		logger.Warn("Software update requested but no .swu files found in %s", api.SoftwareUpdateOTAPath)
		return createErrorResponse(&request.Id, api.WSCodeUpdateFailed, fmt.Sprintf("No .swu bundle found in %s — upload a bundle before triggering an update", api.SoftwareUpdateOTAPath)), nil
	}
	logger.Debug("Found %d .swu file(s) in %s, proceeding with update", len(swuFiles), api.SoftwareUpdateOTAPath)

	followerCount, syncErr := h.ensureSWUFilesOnFollowers(swuFiles)
	if syncErr != nil {
		logger.Error("[StartUpdate] SWU file sync to followers failed: %v", syncErr)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError,
			fmt.Sprintf("Failed to sync SWU files to cluster before triggering update: %v", syncErr)), nil
	}
	logger.Debug("[StartUpdate] %d follower(s) confirmed — all SWU files present on all nodes, proceeding with trigger", followerCount)

	msg := api.NewNotifyMessage(
		api.NotifyOpSoftwareUpdate,
		h.clusterTransport.LocalNode().Name,
		func(m *api.NotifyMessage) {},
	)

	if err := h.hub.BroadcastToNodes(msg); err != nil {
		logger.Error("Failed to broadcast software update to cluster: %v", err)
		return createErrorResponse(&request.Id, api.WSCodeApplicationError, fmt.Sprintf("Failed to broadcast software update: %v", err)), nil
	}

	logger.Debug("Successfully broadcasted software update trigger to cluster")
	return createSuccessResponse(&request.Id, api.WSMsgTypeStartUpdate, api.WSCodeUpdateStarted, "Software update broadcasted to all cluster nodes", map[string]interface{}{
		"action": "broadcast_cluster",
		"nodes":  h.clusterTransport.MemberListMembers(),
	}), nil
}

func (h *Handler) handleMeterDataWithSubscription(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	logger := logging.GetLogger()

	server.SubscribeToTopic(conn, api.WSTopicMeterData)
	logger.Debug("Client subscribed to meter data")

	return createSuccessResponse(&request.Id, api.WSMsgTypeSubscribeMeterData, api.WSCodeOK, "OK - subscribed to meter data", nil), nil
}

func (h *Handler) handlePatchMeterDataFilter(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	if request.Data == nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

	var payload struct {
		Filter []string `json:"filter"`
	}

	if err := websocketRequestDataToAny(request.Data, &payload); err != nil {
		return createErrorResponse(&request.Id, api.WSCodeInvalidPayload, ErrInvalidPayload), nil
	}

	server.SubscribeToTopic(conn, api.WSTopicMeterData)
	server.SetMeterFilter(conn, payload.Filter)
	logging.GetLogger().Debug("Client updated meter data filter: %d IDs", len(payload.Filter))

	return createSuccessResponse(&request.Id, api.WSMsgTypeUpdateMeterDataFilter, api.WSCodeUpdated, "Meter data filter updated", map[string]interface{}{
		"filter_count": len(payload.Filter),
	}), nil
}

func (h *Handler) handleUnsubscribeMeterData(request *model.WebSocketRequest, conn *websocket.Conn, server WebSocketServer) (*model.WebSocketResponse, error) {
	logger := logging.GetLogger()

	server.UnsubscribeFromTopic(conn, api.WSTopicMeterData)
	server.RemoveMeterFilter(conn)
	logger.Debug("Client unsubscribed from meter data")

	return createSuccessResponse(&request.Id, api.WSMsgTypeUnsubscribeMeterData, api.WSCodeOK, "Unsubscribed from meter data", nil), nil
}

func (h *Handler) getDevicesList() ([]model.DeviceInfo, error) {
	devicesInfo := h.clusterTransport.GetAllDevicesInfo()
	return devicesInfo, nil
}

func (h *Handler) getDeviceByID(deviceID string) (*model.DeviceInfo, error) {
	allDevices := h.clusterTransport.GetAllDevicesInfo()
	for i, deviceInfo := range allDevices {
		if deviceInfo.Id == deviceID {
			return &allDevices[i], nil
		}
	}
	return nil, fmt.Errorf("device not found")
}

func (h *Handler) updateDeviceInfo(deviceID string, patch *model.DevicePatch) error {
	return h.clusterTransport.UpdateDeviceInfo(deviceID, patch)
}
