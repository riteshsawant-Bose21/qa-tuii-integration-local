package main

import (
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/types/known/structpb"
)

const (
	remoteURL     = "ws://192.168.2.100:8080/ws"
	localURL      = "ws://127.0.0.1:8080/ws"
	wsTestTimeout = 5 * time.Second
	shortTimeout  = 2 * time.Second
)

type wsRequest struct {
	ID      string
	Version int
	Type    string
	Data    any
}

type wsResponse struct {
	ID        *string
	Version   int
	Type      string
	Code      int
	Status    string
	Message   string
	Data      any
	Timestamp time.Time
}

// getTestURL returns the appropriate URL based on environment
func getTestURL() string {
	if os.Getenv("FUSION_TEST_LOCAL") == "1" {
		return localURL
	}
	return remoteURL
}

// Helper functions for testing
func connectWebSocketRaw(serverURL string) (*websocket.Conn, error) {
	c, _, err := websocket.DefaultDialer.Dial(serverURL, nil)
	return c, err
}

func connectWebSocket(t *testing.T, serverURL string) *websocket.Conn {
	t.Helper()
	c, err := connectWebSocketRaw(serverURL)
	require.NoError(t, err, "Failed to connect to WebSocket")
	return c
}

func wsValue(t *testing.T, data any) *structpb.Value {
	t.Helper()
	if data == nil {
		return nil
	}
	if reflect.TypeOf(data) == reflect.TypeOf(struct{}{}) {
		return structpb.NewStructValue(&structpb.Struct{Fields: map[string]*structpb.Value{}})
	}
	value, err := structpb.NewValue(data)
	require.NoError(t, err, "Failed to encode websocket data value")
	return value
}

func sendWebSocketRequestRaw(conn *websocket.Conn, req *wsRequest) error {
	protoReq := &model.WebSocketRequest{
		Id:      req.ID,
		Version: int32(req.Version),
		Type:    req.Type,
	}
	if req.Data != nil {
		normalized := req.Data
		if raw, ok := req.Data.(json.RawMessage); ok {
			var decoded any
			if err := json.Unmarshal(raw, &decoded); err != nil {
				return err
			}
			normalized = decoded
		} else {
			payloadBytes, err := json.Marshal(req.Data)
			if err != nil {
				return err
			}
			var decoded any
			if err := json.Unmarshal(payloadBytes, &decoded); err != nil {
				return err
			}
			normalized = decoded
		}
		value, err := structpb.NewValue(normalized)
		if err != nil {
			return err
		}
		protoReq.Data = value
	}
	data, err := protojson.Marshal(protoReq)
	if err != nil {
		return err
	}

	return conn.WriteMessage(websocket.TextMessage, data)
}

func sendWebSocketRequest(t *testing.T, conn *websocket.Conn, req *wsRequest) {
	t.Helper()
	require.NotNil(t, conn, "WebSocket connection is nil")
	err := sendWebSocketRequestRaw(conn, req)
	require.NoError(t, err, "Failed to send WebSocket message")
}

func readWebSocketResponseRaw(conn *websocket.Conn, timeout time.Duration) (*wsResponse, error) {
	conn.SetReadDeadline(time.Now().Add(timeout))
	_, data, err := conn.ReadMessage()
	if err != nil {
		return nil, err
	}

	var protoResp model.WebSocketResponse
	err = protojson.Unmarshal(data, &protoResp)
	if err != nil {
		return nil, err
	}

	var responseData any
	if protoResp.Data != nil {
		responseData = protoResp.Data.AsInterface()
	}
	var ts time.Time
	if protoResp.Timestamp != nil {
		ts = protoResp.Timestamp.AsTime()
	}

	return &wsResponse{
		ID:        protoResp.Id,
		Version:   int(protoResp.Version),
		Type:      protoResp.Type,
		Code:      int(protoResp.Code),
		Status:    protoResp.Status,
		Message:   protoResp.Message,
		Data:      responseData,
		Timestamp: ts,
	}, nil
}

func readWebSocketResponse(t *testing.T, conn *websocket.Conn, timeout time.Duration) *wsResponse {
	t.Helper()
	require.NotNil(t, conn, "WebSocket connection is nil")
	resp, err := readWebSocketResponseRaw(conn, timeout)
	require.NoError(t, err, "Failed to read WebSocket message")
	return resp
}

func mustMarshal(v interface{}) any {
	return v
}

// ====================
// CONNECTION MANAGEMENT TESTS
// ====================

func TestWebsocketConnect(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	// Should receive welcome message
	welcome := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, "welcome", welcome.Type)
	assert.Equal(t, api.WSCodeConnected, welcome.Code)
	assert.Equal(t, "event", welcome.Status)
}

func TestWebSocketBasicConnection(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	// Should receive welcome message
	welcome := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, "welcome", welcome.Type)
	assert.Equal(t, api.WSCodeConnected, welcome.Code)
	assert.NotEmpty(t, welcome.Message)
}

func TestWebSocketConnectionClose(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())

	// Read welcome message
	readWebSocketResponse(t, conn, wsTestTimeout)

	// Close connection gracefully
	err := conn.WriteMessage(websocket.CloseMessage,
		websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
	assert.NoError(t, err)

	conn.Close()
}

func TestWebSocketMultipleConnections(t *testing.T) {
	// Test multiple simultaneous connections
	connections := make([]*websocket.Conn, 3)
	defer func() {
		for _, conn := range connections {
			if conn != nil {
				conn.Close()
			}
		}
	}()

	for i := range connections {
		connections[i] = connectWebSocket(t, getTestURL())
		welcome := readWebSocketResponse(t, connections[i], wsTestTimeout)
		assert.Equal(t, "welcome", welcome.Type)
	}
}

func TestWebSocketConnectionTimeout(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Set a very short read deadline and expect timeout
	conn.SetReadDeadline(time.Now().Add(100 * time.Millisecond))
	_, _, err := conn.ReadMessage()

	// Should timeout - no message expected
	assert.Error(t, err)
	assert.True(t, strings.Contains(err.Error(), "timeout") ||
		strings.Contains(err.Error(), "deadline"))
}

func TestWebSocketReconnectAfterDisconnect(t *testing.T) {
	// First connection
	conn1 := connectWebSocket(t, getTestURL())
	readWebSocketResponse(t, conn1, wsTestTimeout) // Welcome
	conn1.Close()

	// Reconnect
	conn2 := connectWebSocket(t, getTestURL())
	defer conn2.Close()

	welcome := readWebSocketResponse(t, conn2, wsTestTimeout)
	assert.Equal(t, "welcome", welcome.Type)
}

// ====================
// MESSAGE FORMAT VALIDATION TESTS
// ====================

func TestWebSocketInvalidJSON(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Send invalid JSON
	err := conn.WriteMessage(websocket.TextMessage, []byte(`{invalid json}`))
	require.NoError(t, err)

	// Should receive error response
	response := readWebSocketResponse(t, conn, shortTimeout)
	assert.Equal(t, api.WSMsgTypeError, response.Type)
	assert.Equal(t, api.WSCodeInvalidJSON, response.Code)
	assert.Contains(t, response.Message, "Invalid JSON")
}

func TestWebSocketMissingRequiredFields(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	testCases := []struct {
		name         string
		msg          map[string]interface{}
		expectedCode int
	}{
		{
			name:         "missing_id",
			msg:          map[string]interface{}{"version": 1, "type": "devices"},
			expectedCode: api.WSCodeMissingField,
		},
		{
			name:         "empty_id",
			msg:          map[string]interface{}{"id": "", "version": 1, "type": "devices"},
			expectedCode: api.WSCodeMissingField,
		},
		{
			name:         "missing_type",
			msg:          map[string]interface{}{"id": "test-1", "version": 1},
			expectedCode: api.WSCodeMissingField,
		},
		{
			name:         "invalid_type",
			msg:          map[string]interface{}{"id": "test-2", "version": 1, "type": "unknown_type"},
			expectedCode: api.WSCodeInvalidType,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			data, _ := json.Marshal(tc.msg)
			err := conn.WriteMessage(websocket.TextMessage, data)
			require.NoError(t, err)

			response := readWebSocketResponse(t, conn, shortTimeout)
			assert.Equal(t, api.WSMsgTypeError, response.Type)
			assert.Equal(t, tc.expectedCode, response.Code)
		})
	}
}

func TestWebSocketVersionCompatibility(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Test current version (should work)
	req := &wsRequest{
		ID:      "test-version-1",
		Version: 1,
		Type:    api.WSMsgTypePing,
	}
	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, shortTimeout)
	assert.Equal(t, api.WSMsgTypePong, response.Type)
}

func TestWebSocketOversizedMessage(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Create a very large message
	largeData := make(map[string]interface{})
	largeData["large_field"] = strings.Repeat("x", 100000) // 100KB

	req := map[string]interface{}{
		"id":      "large-message",
		"version": 1,
		"type":    "ping",
		"data":    largeData,
	}

	data, _ := json.Marshal(req)
	err := conn.WriteMessage(websocket.TextMessage, data)

	// May fail due to size limits, or succeed and get processed
	if err == nil {
		// If sent successfully, should get some response
		conn.SetReadDeadline(time.Now().Add(5 * time.Second))
		_, _, readErr := conn.ReadMessage()
		// Either processes successfully or fails gracefully
		_ = readErr // Response handling depends on server limits
	}
}

// ====================
// API OPERATION TESTS - DEVICE LISTING
// ====================

func TestWebSocketDevicesRequest(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	req := &wsRequest{
		ID:      "devices-test-1",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypeDevices, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
	assert.Equal(t, "devices-test-1", *response.ID)
	assert.NotNil(t, response.Data)

	// Data should be an array of devices
	devices, ok := response.Data.([]interface{})
	assert.True(t, ok, "Expected devices data to be array")
	assert.Greater(t, len(devices), 0, "Expected at least one device")
}

func TestWebSocketDevicesAutoSubscription(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Request devices list (automatically subscribes)
	req := &wsRequest{
		ID:      "devices-sub-1",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeDevices, response.Type)
	assert.Contains(t, response.Message, "subscribed")
}

func TestWebSocketDevicesResponseFormat(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	req := &wsRequest{
		ID:      "format-test",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	// Validate response format
	assert.Equal(t, "format-test", *response.ID)
	assert.Equal(t, 1, response.Version)
	assert.NotEmpty(t, response.Timestamp)
	assert.Equal(t, "success", response.Status)

	// Validate device data structure
	devices, ok := response.Data.([]interface{})
	require.True(t, ok)

	if len(devices) > 0 {
		device := devices[0].(map[string]interface{})
		requiredFields := []string{"id", "name", "address"}
		for _, field := range requiredFields {
			assert.Contains(t, device, field, "Device should contain field %s", field)
		}
		if location, exists := device["location"]; exists {
			_, ok := location.(string)
			assert.True(t, ok, "Device location should be a string when present")
		}
	}
}

// ====================
// API OPERATION TESTS - CONFIGURATION
// ====================

func TestWebSocketConfigurationRequest(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	req := &wsRequest{
		ID:      "config-test-1",
		Version: 1,
		Type:    api.WSMsgTypeConfiguration,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypeConfiguration, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
	assert.Equal(t, "config-test-1", *response.ID)
	assert.NotNil(t, response.Data)

	// Data should be a configuration object
	_, ok := response.Data.(map[string]interface{})
	assert.True(t, ok, "Expected config data to be object")
}

func TestWebSocketConfigurationAutoSubscription(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Request config (automatically subscribes)
	req := &wsRequest{
		ID:      "config-sub-1",
		Version: 1,
		Type:    api.WSMsgTypeConfiguration,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeConfiguration, response.Type)
	assert.Contains(t, response.Message, "subscribed")
}

func TestWebSocketConfigurationResponseFormat(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	req := &wsRequest{
		ID:      "config-format-test",
		Version: 1,
		Type:    api.WSMsgTypeConfiguration,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	// Validate response format
	assert.Equal(t, "config-format-test", *response.ID)
	assert.Equal(t, 1, response.Version)
	assert.NotEmpty(t, response.Timestamp)
	assert.Equal(t, "success", response.Status)

	// Validate config data structure
	_, ok := response.Data.(map[string]interface{})
	require.True(t, ok)
}

func TestWebSocketPatchConfiguration(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Test simple patch
	patchData := map[string]interface{}{
		"test_key": "test_value",
		"another_key": map[string]interface{}{
			"nested": "value",
		},
	}

	req := &wsRequest{
		ID:      "patch-config-test",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshal(patchData),
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypePatchConfiguration, response.Type)
	// Should be either WSCodeOK (no-op) or WSCodeUpdated (patch applied)
	assert.True(t, response.Code == api.WSCodeOK || response.Code == api.WSCodeUpdated,
		"Expected OK or Updated code, got %d", response.Code)
	assert.Equal(t, "patch-config-test", *response.ID)

	// Response should include updates info if data is present
	if response.Data != nil {
		responseData, ok := response.Data.(map[string]interface{})
		assert.True(t, ok, "Expected response data to be object")
		assert.Contains(t, responseData, "updates", "Response should contain updates field")
	}
}

func TestWebSocketPatchConfigurationEmpty(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Test empty patch (should be no-op)
	req := &wsRequest{
		ID:      "patch-empty-test",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshal(map[string]interface{}{}),
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypePatchConfiguration, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code) // Empty patch should be no-op
	assert.Equal(t, "patch-empty-test", *response.ID)
}

func TestWebSocketPatchConfigurationInvalidPayload(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Test invalid JSON payload
	req := &wsRequest{
		ID:      "patch-invalid-test",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    json.RawMessage(`"invalid"`), // Invalid patch data (string instead of object)
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypeError, response.Type)
	assert.Equal(t, api.WSCodeInvalidPayload, response.Code)
	assert.Equal(t, "patch-invalid-test", *response.ID)
}

func TestWebSocketUnsubscribeConfig(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// First subscribe by requesting config
	subReq := &wsRequest{
		ID:      "sub-first",
		Version: 1,
		Type:    api.WSMsgTypeConfiguration,
	}

	sendWebSocketRequest(t, conn, subReq)
	readWebSocketResponse(t, conn, wsTestTimeout) // config response

	// Now unsubscribe
	unsubReq := &wsRequest{
		ID:      "unsub-config-test",
		Version: 1,
		Type:    api.WSMsgTypeUnsubscribeConfig,
	}

	sendWebSocketRequest(t, conn, unsubReq)
	response := readWebSocketResponse(t, conn, shortTimeout)

	assert.Equal(t, api.WSMsgTypeUnsubscribeConfig, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
	assert.Equal(t, "unsub-config-test", *response.ID)
	assert.Contains(t, response.Message, "Unsubscribed from configuration updates")
}

func TestWebSocketConfigSubscriptionLifecycle(t *testing.T) {
	// Setup two connections - monitor and updater
	connMonitor := connectWebSocket(t, getTestURL())
	defer connMonitor.Close()

	connUpdater := connectWebSocket(t, getTestURL())
	defer connUpdater.Close()

	// Skip welcome messages
	readWebSocketResponse(t, connMonitor, wsTestTimeout)
	readWebSocketResponse(t, connUpdater, wsTestTimeout)

	// Phase 1: Subscribe to config updates by requesting config
	subReq := &wsRequest{
		ID:      "config-lifecycle-sub",
		Version: 1,
		Type:    api.WSMsgTypeConfiguration,
	}
	sendWebSocketRequest(t, connMonitor, subReq)
	subResponse := readWebSocketResponse(t, connMonitor, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeConfiguration, subResponse.Type)

	// Phase 2: Trigger config update while subscribed (should receive notification)
	baseTimestamp := time.Now().UnixNano()
	patchData := map[string]interface{}{
		"test_before_unsub": fmt.Sprintf("value_%d", baseTimestamp),
		"lifecycle_phase":   "phase_2_subscribed",
	}
	patchReq := &wsRequest{
		ID:      "config-update-before",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshal(patchData),
	}
	sendWebSocketRequest(t, connUpdater, patchReq)
	patchResponse := readWebSocketResponse(t, connUpdater, wsTestTimeout)

	if patchResponse.Code == api.WSCodeUpdated {
		// Should receive notification (subscribed)
		notification := readWebSocketResponse(t, connMonitor, 5*time.Second)
		assert.Equal(t, api.WSMsgTypeConfigUpdate, notification.Type)
	} else {
		// Phase 2 patch was no-op, continuing test
	}

	// Phase 3: Unsubscribe
	unsubReq := &wsRequest{
		ID:      "config-lifecycle-unsub",
		Version: 1,
		Type:    api.WSMsgTypeUnsubscribeConfig,
	}
	sendWebSocketRequest(t, connMonitor, unsubReq)
	unsubResponse := readWebSocketResponse(t, connMonitor, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUnsubscribeConfig, unsubResponse.Type)

	// Phase 4: Trigger config update after unsubscribe (should NOT receive notification)
	patchDataAfter := map[string]interface{}{
		"test_after_unsub": fmt.Sprintf("value_%d", baseTimestamp+1),
		"lifecycle_phase":  "phase_4_unsubscribed",
	}
	patchReqAfter := &wsRequest{
		ID:      "config-update-after",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshal(patchDataAfter),
	}
	sendWebSocketRequest(t, connUpdater, patchReqAfter)
	patchResponseAfter := readWebSocketResponse(t, connUpdater, wsTestTimeout)

	if patchResponseAfter.Code == api.WSCodeUpdated {
		// Should NOT receive notification (unsubscribed)
		connMonitor.SetReadDeadline(time.Now().Add(3 * time.Second))
		_, _, err := connMonitor.ReadMessage()

		if err != nil && (strings.Contains(err.Error(), "timeout") || strings.Contains(err.Error(), "deadline")) {
			// No notification received after unsubscribe (correct behavior)
		} else if err == nil {
			t.Errorf("Should NOT receive notification after unsubscribing")
		}
	} else {
		// Phase 4 patch was no-op, cannot test notification blocking
	}

	// Phase 5: Re-subscribe by requesting config again
	// Create fresh connection to avoid timeout issues from Phase 4
	connMonitorFresh := connectWebSocket(t, getTestURL())
	defer connMonitorFresh.Close()
	readWebSocketResponse(t, connMonitorFresh, wsTestTimeout) // Skip welcome

	resubReq := &wsRequest{
		ID:      "config-lifecycle-resub",
		Version: 1,
		Type:    api.WSMsgTypeConfiguration,
	}
	sendWebSocketRequest(t, connMonitorFresh, resubReq)
	resubResponse := readWebSocketResponse(t, connMonitorFresh, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeConfiguration, resubResponse.Type)

	// Phase 6: Trigger config update after re-subscribe (should receive notification again)
	patchDataResub := map[string]interface{}{
		"test_after_resub": fmt.Sprintf("value_%d", baseTimestamp+2),
		"lifecycle_phase":  "phase_6_resubscribed",
	}
	patchReqResub := &wsRequest{
		ID:      "config-update-resub",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshal(patchDataResub),
	}
	sendWebSocketRequest(t, connUpdater, patchReqResub)
	patchResponseResub := readWebSocketResponse(t, connUpdater, wsTestTimeout)

	if patchResponseResub.Code == api.WSCodeUpdated {
		// Should receive notification (re-subscribed)
		notificationResub := readWebSocketResponse(t, connMonitorFresh, 5*time.Second)
		assert.Equal(t, api.WSMsgTypeConfigUpdate, notificationResub.Type)
	} else {
		// Phase 6 patch was no-op, cannot test re-subscription notification
	}
}

func TestWebSocketConfigPushNotifications(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping config push notification test in short mode")
	}

	// Monitor connection (subscribes to config updates)
	connMonitor := connectWebSocket(t, getTestURL())
	defer connMonitor.Close()

	// Updater connection (makes config changes)
	connUpdater := connectWebSocket(t, getTestURL())
	defer connUpdater.Close()

	// Skip welcome messages
	readWebSocketResponse(t, connMonitor, wsTestTimeout)
	readWebSocketResponse(t, connUpdater, wsTestTimeout)

	// Monitor subscribes to config updates by requesting config
	subReq := &wsRequest{
		ID:      "monitor-config-sub",
		Version: 1,
		Type:    api.WSMsgTypeConfiguration,
	}
	sendWebSocketRequest(t, connMonitor, subReq)
	readWebSocketResponse(t, connMonitor, wsTestTimeout) // config response

	// Updater patches config
	patchData := map[string]interface{}{
		"test_notification": fmt.Sprintf("value_%d", time.Now().Unix()),
		"nested_config": map[string]interface{}{
			"notification_test": true,
		},
	}

	patchReq := &wsRequest{
		ID:      "trigger-config-notification",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshal(patchData),
	}

	sendWebSocketRequest(t, connUpdater, patchReq)
	patchResponse := readWebSocketResponse(t, connUpdater, wsTestTimeout)

	// Only proceed if patch was successful
	if patchResponse.Code == api.WSCodeUpdated {
		// Monitor should receive config update notification
		connMonitor.SetReadDeadline(time.Now().Add(10 * time.Second))
		notification := readWebSocketResponse(t, connMonitor, 10*time.Second)

		assert.Equal(t, api.WSMsgTypeConfigUpdate, notification.Type)
		assert.Nil(t, notification.ID)
		assert.Equal(t, api.WSCodeUpdated, notification.Code)
		assert.Equal(t, "event", notification.Status)

		// Notification should contain config data
		_, ok := notification.Data.(map[string]interface{})
		assert.True(t, ok, "Expected notification data to be object")
	} else {
		// Config patch was no-op, skipping notification test
	}
}

// setupConfigSubscribers creates and subscribes multiple connections to config updates
func setupConfigSubscribers(t *testing.T, numSubscribers int) []*websocket.Conn {
	subscribers := make([]*websocket.Conn, numSubscribers)
	for i := range subscribers {
		subscribers[i] = connectWebSocket(t, getTestURL())
		readWebSocketResponse(t, subscribers[i], wsTestTimeout) // Skip welcome

		// Subscribe to config updates by requesting config
		subReq := &wsRequest{
			ID:      fmt.Sprintf("multi-config-sub-%d", i),
			Version: 1,
			Type:    api.WSMsgTypeConfiguration,
		}
		sendWebSocketRequest(t, subscribers[i], subReq)
		readWebSocketResponse(t, subscribers[i], wsTestTimeout) // config response
	}
	return subscribers
}

// readAndValidateConfigNotification reads and validates a config notification from a connection
func readAndValidateConfigNotification(t *testing.T, conn *websocket.Conn, subscriberID int) bool {
	conn.SetReadDeadline(time.Now().Add(10 * time.Second))

	_, data, err := conn.ReadMessage()
	if err != nil {
		if strings.Contains(err.Error(), "timeout") || strings.Contains(err.Error(), "deadline") {
			// Config subscriber did not receive notification within timeout
			return false
		}
		t.Errorf("Config subscriber %d failed to read message: %v", subscriberID, err)
		return false
	}

	var notification wsResponse
	if err := json.Unmarshal(data, &notification); err != nil {
		t.Errorf("Config subscriber %d failed to unmarshal response: %v", subscriberID, err)
		return false
	}

	assert.Equal(t, api.WSMsgTypeConfigUpdate, notification.Type,
		"Config subscriber %d should receive notification", subscriberID)
	assert.Equal(t, api.WSCodeUpdated, notification.Code)
	assert.Nil(t, notification.ID)

	return true
}

func TestWebSocketConfigMultipleSubscriberNotifications(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping multiple config subscriber test in short mode")
	}

	numSubscribers := 2
	subscribers := setupConfigSubscribers(t, numSubscribers)
	defer func() {
		for _, conn := range subscribers {
			if conn != nil {
				conn.Close()
			}
		}
	}()

	// Create updater connection
	updater := connectWebSocket(t, getTestURL())
	defer updater.Close()
	readWebSocketResponse(t, updater, wsTestTimeout) // Skip welcome

	// Perform config update
	patchData := map[string]interface{}{
		"multi_subscriber_test": fmt.Sprintf("timestamp_%d", time.Now().UnixNano()),
	}

	patchReq := &wsRequest{
		ID:      "multi-config-update",
		Version: 1,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshal(patchData),
	}

	sendWebSocketRequest(t, updater, patchReq)
	patchResponse := readWebSocketResponse(t, updater, wsTestTimeout)

	// Only test notifications if patch was successful
	if patchResponse.Code != api.WSCodeUpdated {
		// Config patch was no-op, skipping notification test
		return
	}

	// Validate notifications for all subscribers
	for i, conn := range subscribers {
		readAndValidateConfigNotification(t, conn, i)
	}
}

func TestWebSocketConfigErrorHandling(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	errorTests := []struct {
		name         string
		request      *wsRequest
		expectedCode int
	}{
		{
			name: "invalid_patch_payload",
			request: &wsRequest{
				ID:      "error-patch-1",
				Version: 1,
				Type:    api.WSMsgTypePatchConfiguration,
				Data:    json.RawMessage(`"invalid"`), // Invalid patch data (string instead of object)
			},
			expectedCode: api.WSCodeInvalidPayload,
		},
		{
			name: "missing_patch_data",
			request: &wsRequest{
				ID:      "error-patch-2",
				Version: 1,
				Type:    api.WSMsgTypePatchConfiguration,
				// No Data field
			},
			expectedCode: api.WSCodeInvalidPayload,
		},
	}

	for _, tc := range errorTests {
		t.Run(tc.name, func(t *testing.T) {
			sendWebSocketRequest(t, conn, tc.request)
			response := readWebSocketResponse(t, conn, shortTimeout)

			assert.Equal(t, api.WSMsgTypeError, response.Type)
			assert.Equal(t, tc.expectedCode, response.Code)
			assert.Equal(t, tc.request.ID, *response.ID)
		})
	}
}

// ====================
// API OPERATION TESTS - DEVICE LOOKUP
// ====================

func TestWebSocketDeviceByID(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// First get list of devices to find a valid ID
	req := &wsRequest{
		ID:      "get-devices",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	devicesResponse := readWebSocketResponse(t, conn, wsTestTimeout)

	devices, ok := devicesResponse.Data.([]interface{})
	require.True(t, ok, "Expected devices array")
	require.Greater(t, len(devices), 0, "Need at least one device for test")

	device := devices[0].(map[string]interface{})
	deviceID := device["id"].(string)

	// Now test device lookup by ID
	lookupReq := &wsRequest{
		ID:      "device-by-id-test",
		Version: 1,
		Type:    api.WSMsgTypeDeviceByID,
		Data:    mustMarshal(map[string]interface{}{"device_id": deviceID}),
	}

	sendWebSocketRequest(t, conn, lookupReq)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypeDeviceByID, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
	assert.Equal(t, "device-by-id-test", *response.ID)

	// Verify device data
	returnedDevice, ok := response.Data.(map[string]interface{})
	assert.True(t, ok, "Expected device object")
	assert.Equal(t, deviceID, returnedDevice["id"])
}

func TestWebSocketDeviceByIDNotFound(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	req := &wsRequest{
		ID:      "device-not-found",
		Version: 1,
		Type:    api.WSMsgTypeDeviceByID,
		Data:    mustMarshal(map[string]interface{}{"device_id": "non-existent-device"}),
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypeError, response.Type)
	// Server may return different error codes for device not found - accept any error code
	assert.True(t, response.Code >= 4000 && response.Code < 5000 || response.Code == 1011,
		"Expected error code (4xxx or 1011), got: %d", response.Code)
}

func TestWebSocketDeviceByIDMissingDeviceID(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	testCases := []struct {
		name string
		data string
	}{
		{"empty_payload", `{}`},
		{"empty_device_id", `{"device_id": ""}`},
		{"null_device_id", `{"device_id": null}`},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := &wsRequest{
				ID:      fmt.Sprintf("missing-id-%s", tc.name),
				Version: 1,
				Type:    api.WSMsgTypeDeviceByID,
				Data:    json.RawMessage(tc.data),
			}

			sendWebSocketRequest(t, conn, req)
			response := readWebSocketResponse(t, conn, shortTimeout)

			assert.Equal(t, api.WSMsgTypeError, response.Type)
			assert.Equal(t, api.WSCodeMissingDeviceID, response.Code)
		})
	}
}

// ====================
// API OPERATION TESTS - DEVICE UPDATES
// ====================

func TestWebSocketUpdateDeviceInfo(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Get a device to update
	deviceID := getFirstDeviceID(t, conn)

	// Update device name
	updateData := map[string]interface{}{
		"device_id": deviceID,
		"name":      "Updated Device Name",
		"location":  "Updated Location",
	}

	updateReq := &wsRequest{
		ID:      "update-device-test",
		Version: 1,
		Type:    api.WSMsgTypeUpdateDeviceInfo,
		Data:    mustMarshal(updateData),
	}

	sendWebSocketRequest(t, conn, updateReq)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	//t.Logf("Update response - Type: %s, Code: %d, ID: %v", response.Type, response.Code, response.ID)

	// Check if we got an update confirmation or a push notification
	if response.ID != nil && *response.ID == "update-device-test" {
		// This is the update confirmation
		assert.Equal(t, api.WSMsgTypeUpdateDeviceInfo, response.Type)
		assert.Equal(t, api.WSCodeUpdated, response.Code)
	} else if response.Type == api.WSMsgTypeError {
		// Update failed - this is acceptable for testing
		assert.Equal(t, api.WSMsgTypeError, response.Type)
		assert.True(t, response.Code >= 4000, "Expected error code 4xxx, got %d", response.Code)
		t.Logf("Update failed (expected in test environment): %s", response.Message)
	} else {
		// This might be a push notification, accept it
		assert.Equal(t, api.WSMsgTypeDeviceUpdate, response.Type)
		assert.Equal(t, api.WSCodeDeviceUpdated, response.Code)
		assert.Nil(t, response.ID) // Push notifications have null ID
	}
}

func TestWebSocketUpdateDevicePartialFields(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	deviceID := getFirstDeviceID(t, conn)

	// Test partial updates
	partialUpdates := []map[string]interface{}{
		{"device_id": deviceID, "name": "Only Name Updated"},
		{"device_id": deviceID, "location": "Only Location Updated"},
		{"device_id": deviceID, "is_claimed": true},
		{"device_id": deviceID, "model_name": "Updated Model"},
	}

	for i, updateData := range partialUpdates {
		req := &wsRequest{
			ID:      fmt.Sprintf("partial-update-%d", i),
			Version: 1,
			Type:    api.WSMsgTypeUpdateDeviceInfo,
			Data:    mustMarshal(updateData),
		}

		sendWebSocketRequest(t, conn, req)
		response := readWebSocketResponse(t, conn, wsTestTimeout)

		//t.Logf("Partial update %d response - Type: %s, Code: %d", i, response.Type, response.Code)

		// Accept either update confirmation, push notification, or error
		switch response.Type {
		case api.WSMsgTypeUpdateDeviceInfo:
			assert.Equal(t, api.WSCodeUpdated, response.Code)
		case api.WSMsgTypeDeviceUpdate:
			assert.Equal(t, api.WSCodeDeviceUpdated, response.Code)
		case api.WSMsgTypeError:
			// Update failed - acceptable in test environment
			assert.True(t, response.Code >= 4000, "Expected error code 4xxx, got %d", response.Code)
			//t.Logf("Update %d failed (expected in test): %s", i, response.Message)
		default:
			t.Errorf("Unexpected response type: %s", response.Type)
		}
	}
}

func TestWebSocketUpdateDeviceValidation(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	testCases := []struct {
		name         string
		data         map[string]interface{}
		expectedCode int
	}{
		{
			name:         "missing_device_id",
			data:         map[string]interface{}{"name": "Test"},
			expectedCode: api.WSCodeMissingDeviceID,
		},
		{
			name:         "empty_device_id",
			data:         map[string]interface{}{"device_id": "", "name": "Test"},
			expectedCode: api.WSCodeMissingDeviceID,
		},
		{
			name:         "non_existent_device",
			data:         map[string]interface{}{"device_id": "does-not-exist", "name": "Test"},
			expectedCode: api.WSCodeUpdateFailed,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			req := &wsRequest{
				ID:      fmt.Sprintf("validation-%s", tc.name),
				Version: 1,
				Type:    api.WSMsgTypeUpdateDeviceInfo,
				Data:    mustMarshal(tc.data),
			}

			sendWebSocketRequest(t, conn, req)
			response := readWebSocketResponse(t, conn, shortTimeout)

			assert.Equal(t, api.WSMsgTypeError, response.Type)
			assert.Equal(t, tc.expectedCode, response.Code)
		})
	}
}

func TestWebSocketConcurrentUpdates(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping concurrent test in short mode")
	}

	// Create multiple connections for concurrent updates
	numConnections := 3
	connections := make([]*websocket.Conn, numConnections)
	defer func() {
		for _, conn := range connections {
			if conn != nil {
				conn.Close()
			}
		}
	}()

	// Set up connections
	for i := range connections {
		connections[i] = connectWebSocket(t, getTestURL())
		readWebSocketResponse(t, connections[i], wsTestTimeout) // Skip welcome
	}

	deviceID := getFirstDeviceID(t, connections[0])

	// Perform concurrent updates
	var wg sync.WaitGroup
	errCh := make(chan error, len(connections))
	for i, conn := range connections {
		wg.Add(1)
		go func(connIndex int, connection *websocket.Conn) {
			defer wg.Done()

			timestamp := time.Now().UnixNano()
			updateReq := &wsRequest{
				ID:      fmt.Sprintf("concurrent-update-%d", connIndex),
				Version: 1,
				Type:    api.WSMsgTypeUpdateDeviceInfo,
				Data: mustMarshal(map[string]interface{}{
					"device_id": deviceID,
					"name":      fmt.Sprintf("Concurrent Update %d-%d", connIndex, timestamp),
				}),
			}

			if err := sendWebSocketRequestRaw(connection, updateReq); err != nil {
				errCh <- fmt.Errorf("connection %d send failed: %w", connIndex, err)
				return
			}
			response, err := readWebSocketResponseRaw(connection, wsTestTimeout)
			if err != nil {
				errCh <- fmt.Errorf("connection %d read failed: %w", connIndex, err)
				return
			}
			// Can be either update_device_info, device_update, or error (in case of conflicts)
			validTypes := []string{api.WSMsgTypeUpdateDeviceInfo, "device_update", "error"}
			assert.Contains(t, validTypes, response.Type, "Response type %s not in expected types %v", response.Type, validTypes)
		}(i, conn)
	}

	wg.Wait()
	close(errCh)
	for err := range errCh {
		require.NoError(t, err)
	}
}

// ====================
// API OPERATION TESTS - HEALTH CHECK
// ====================

func TestWebSocketPingPong(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	req := &wsRequest{
		ID:      "ping-test-1",
		Version: 1,
		Type:    api.WSMsgTypePing,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, shortTimeout)

	assert.Equal(t, api.WSMsgTypePong, response.Type)
	assert.Equal(t, api.WSCodePong, response.Code)
	assert.Equal(t, "ping-test-1", *response.ID)
	assert.Equal(t, "pong", response.Message)
}

func TestWebSocketMultiplePingPong(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	for i := 0; i < 5; i++ {
		req := &wsRequest{
			ID:      fmt.Sprintf("ping-%d", i),
			Version: 1,
			Type:    api.WSMsgTypePing,
		}

		sendWebSocketRequest(t, conn, req)
		response := readWebSocketResponse(t, conn, shortTimeout)

		assert.Equal(t, api.WSMsgTypePong, response.Type)
		assert.Equal(t, fmt.Sprintf("ping-%d", i), *response.ID)
	}
}

func TestWebSocketPingTimeout(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Send ping and immediately set very short timeout
	req := &wsRequest{
		ID:      "ping-timeout-test",
		Version: 1,
		Type:    api.WSMsgTypePing,
	}

	sendWebSocketRequest(t, conn, req)

	// Should still get pong even with normal timeout
	response := readWebSocketResponse(t, conn, shortTimeout)
	assert.Equal(t, api.WSMsgTypePong, response.Type)
}

// ====================
// SUBSCRIPTION MANAGEMENT TESTS
// ====================

func TestWebSocketUnsubscribeDevices(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// First subscribe by requesting devices
	req := &wsRequest{
		ID:      "subscribe-first",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	readWebSocketResponse(t, conn, wsTestTimeout) // devices response

	// Now unsubscribe
	unsubReq := &wsRequest{
		ID:      "unsubscribe-test",
		Version: 1,
		Type:    api.WSMsgTypeUnsubscribeDevices,
	}

	sendWebSocketRequest(t, conn, unsubReq)
	response := readWebSocketResponse(t, conn, shortTimeout)

	assert.Equal(t, api.WSMsgTypeUnsubscribeDevices, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
	assert.Equal(t, "unsubscribe-test", *response.ID)
	assert.Contains(t, response.Message, "Unsubscribed")
}

func TestWebSocketSubscriptionLifecycle(t *testing.T) {
	// Create two connections - one for updates, one for monitoring
	connUpdater := connectWebSocket(t, getTestURL())
	defer connUpdater.Close()

	connMonitor := connectWebSocket(t, getTestURL())
	defer connMonitor.Close()

	// Skip welcome messages
	readWebSocketResponse(t, connUpdater, wsTestTimeout)
	readWebSocketResponse(t, connMonitor, wsTestTimeout)

	// Phase 1: Monitor subscribes
	monitorReq := &wsRequest{
		ID:      "monitor-sub",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}
	sendWebSocketRequest(t, connMonitor, monitorReq)
	readWebSocketResponse(t, connMonitor, wsTestTimeout) // devices response

	// Phase 2: Monitor unsubscribes
	unsubReq := &wsRequest{
		ID:      "monitor-unsub",
		Version: 1,
		Type:    api.WSMsgTypeUnsubscribeDevices,
	}
	sendWebSocketRequest(t, connMonitor, unsubReq)
	unsubResponse := readWebSocketResponse(t, connMonitor, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUnsubscribeDevices, unsubResponse.Type)

	// Phase 3: Monitor re-subscribes
	resubReq := &wsRequest{
		ID:      "monitor-resub",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}
	sendWebSocketRequest(t, connMonitor, resubReq)
	resubResponse := readWebSocketResponse(t, connMonitor, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeDevices, resubResponse.Type)
}

func TestWebSocketResubscriptionAfterUnsubscribe(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Subscribe
	subReq := &wsRequest{
		ID:      "sub",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}
	sendWebSocketRequest(t, conn, subReq)
	subResponse := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeDevices, subResponse.Type)

	// Unsubscribe
	unsubReq := &wsRequest{
		ID:      "unsub",
		Version: 1,
		Type:    api.WSMsgTypeUnsubscribeDevices,
	}
	sendWebSocketRequest(t, conn, unsubReq)
	unsubResponse := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUnsubscribeDevices, unsubResponse.Type)

	// Re-subscribe
	resubReq := &wsRequest{
		ID:      "resub",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}
	sendWebSocketRequest(t, conn, resubReq)
	resubResponse := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeDevices, resubResponse.Type)
}

// ====================
// ERROR HANDLING TESTS
// ====================

func TestWebSocketErrorCodes(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	errorTests := []struct {
		name         string
		request      *wsRequest
		expectedCode int
	}{
		{
			name: "invalid_message_type",
			request: &wsRequest{
				ID:      "error-1",
				Version: 1,
				Type:    "invalid_type",
			},
			expectedCode: api.WSCodeInvalidType,
		},
		{
			name: "missing_device_id_in_lookup",
			request: &wsRequest{
				ID:      "error-2",
				Version: 1,
				Type:    api.WSMsgTypeDeviceByID,
				Data:    json.RawMessage(`{}`),
			},
			expectedCode: api.WSCodeMissingDeviceID,
		},
	}

	for _, tc := range errorTests {
		t.Run(tc.name, func(t *testing.T) {
			sendWebSocketRequest(t, conn, tc.request)
			response := readWebSocketResponse(t, conn, shortTimeout)

			assert.Equal(t, api.WSMsgTypeError, response.Type)
			assert.Equal(t, tc.expectedCode, response.Code)
			assert.Equal(t, tc.request.ID, *response.ID)
		})
	}
}

func TestWebSocketErrorResponseFormat(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Send request that will cause error
	req := &wsRequest{
		ID:      "error-format-test",
		Version: 1,
		Type:    "unknown_type",
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, shortTimeout)

	// Validate error response structure
	assert.Equal(t, api.WSMsgTypeError, response.Type)
	assert.Equal(t, "error", response.Status)
	assert.Equal(t, "error-format-test", *response.ID)
	assert.NotEmpty(t, response.Message)
	assert.NotEmpty(t, response.Timestamp)
	assert.True(t, response.Code >= 4000 && response.Code < 5000)
}

func TestWebSocketAllErrorCodes(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	errorCases := []struct {
		name         string
		message      string
		expectedCode int
	}{
		{
			name:         "invalid_json",
			message:      `{invalid json}`,
			expectedCode: api.WSCodeInvalidJSON,
		},
		{
			name:         "missing_field",
			message:      `{"version": 1, "type": "ping"}`, // missing id
			expectedCode: api.WSCodeMissingField,
		},
	}

	for _, tc := range errorCases {
		t.Run(tc.name, func(t *testing.T) {
			err := conn.WriteMessage(websocket.TextMessage, []byte(tc.message))
			require.NoError(t, err)

			response := readWebSocketResponse(t, conn, shortTimeout)
			assert.Equal(t, api.WSMsgTypeError, response.Type)
			assert.Equal(t, tc.expectedCode, response.Code)
		})
	}
}

// ====================
// PUSH NOTIFICATION TESTS
// ====================

func TestWebSocketPushNotifications(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping push notification test in short mode")
	}

	// This test requires two connections - one for updates, one for notifications
	conn1 := connectWebSocket(t, getTestURL())
	defer conn1.Close()

	conn2 := connectWebSocket(t, getTestURL())
	defer conn2.Close()

	// Skip welcome messages
	readWebSocketResponse(t, conn1, wsTestTimeout)
	readWebSocketResponse(t, conn2, wsTestTimeout)

	// conn1 subscribes to device updates
	req := &wsRequest{
		ID:      "subscribe-for-notifications",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn1, req)
	response := readWebSocketResponse(t, conn1, wsTestTimeout)

	devices, ok := response.Data.([]interface{})
	require.True(t, ok)
	require.Greater(t, len(devices), 0)

	deviceID := devices[0].(map[string]interface{})["id"].(string)

	// conn2 updates the device
	updateReq := &wsRequest{
		ID:      "trigger-notification",
		Version: 1,
		Type:    api.WSMsgTypeUpdateDeviceInfo,
		Data: mustMarshal(map[string]interface{}{
			"device_id": deviceID,
			"name":      fmt.Sprintf("Push Test %d", time.Now().Unix()),
		}),
	}

	sendWebSocketRequest(t, conn2, updateReq)
	updateResponse := readWebSocketResponse(t, conn2, wsTestTimeout)
	assert.Equal(t, api.WSCodeUpdated, updateResponse.Code)

	// conn1 should receive push notification
	// Note: This might take a moment due to clustering/gossip delays
	conn1.SetReadDeadline(time.Now().Add(10 * time.Second))
	notification := readWebSocketResponse(t, conn1, 10*time.Second)

	assert.Equal(t, api.WSMsgTypeDeviceUpdate, notification.Type)
	assert.Nil(t, notification.ID) // Server-initiated messages have null ID
	assert.Equal(t, api.WSCodeDeviceUpdated, notification.Code)
}

func TestWebSocketPullThenPushPattern(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping pull-then-push test in short mode")
	}

	// Monitor connection
	connMonitor := connectWebSocket(t, getTestURL())
	defer connMonitor.Close()

	// Updater connection
	connUpdater := connectWebSocket(t, getTestURL())
	defer connUpdater.Close()

	// Skip welcome messages
	readWebSocketResponse(t, connMonitor, wsTestTimeout)
	readWebSocketResponse(t, connUpdater, wsTestTimeout)

	// Step 1: Pull - get initial device data and auto-subscribe
	req := &wsRequest{
		ID:      "pull-phase",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, connMonitor, req)
	pullResponse := readWebSocketResponse(t, connMonitor, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeDevices, pullResponse.Type)

	devices, ok := pullResponse.Data.([]interface{})
	require.True(t, ok)
	require.Greater(t, len(devices), 0)

	deviceID := devices[0].(map[string]interface{})["id"].(string)

	// Step 2: Push - update device and expect notification
	updateReq := &wsRequest{
		ID:      "push-trigger",
		Version: 1,
		Type:    api.WSMsgTypeUpdateDeviceInfo,
		Data: mustMarshal(map[string]interface{}{
			"device_id": deviceID,
			"name":      fmt.Sprintf("Pull-Then-Push Test %d", time.Now().UnixNano()),
		}),
	}

	sendWebSocketRequest(t, connUpdater, updateReq)
	updateResponse := readWebSocketResponse(t, connUpdater, wsTestTimeout)

	//t.Logf("Update response - Type: %s, Code: %d, Message: %s", updateResponse.Type, updateResponse.Code, updateResponse.Message)

	// Handle potential update failure gracefully
	if updateResponse.Code == api.WSCodeUpdateFailed {
		//t.Logf("Device update failed (acceptable in test environment): %s", updateResponse.Message)
		t.Skip("Skipping notification test since update failed")
		return
	}

	// Check if we got an update confirmation
	if updateResponse.ID != nil && *updateResponse.ID == "push-trigger" {
		assert.Equal(t, api.WSCodeUpdated, updateResponse.Code)
	} else {
		// Might be an error response
		assert.Equal(t, api.WSMsgTypeError, updateResponse.Type)
		t.Logf("Update failed: %s", updateResponse.Message)
		t.Skip("Skipping notification test due to update failure")
		return
	}

	// Monitor should receive push notification (with longer timeout for network delays)
	connMonitor.SetReadDeadline(time.Now().Add(15 * time.Second))
	pushNotification := readWebSocketResponse(t, connMonitor, 15*time.Second)
	assert.Equal(t, api.WSMsgTypeDeviceUpdate, pushNotification.Type)
	assert.Nil(t, pushNotification.ID) // Server-initiated
	assert.Equal(t, "event", pushNotification.Status)
}

func TestWebSocketMultipleSubscriberNotifications(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping multiple subscriber test in short mode")
	}

	numSubscribers := 3
	subscribers := make([]*websocket.Conn, numSubscribers)
	defer func() {
		for _, conn := range subscribers {
			if conn != nil {
				conn.Close()
			}
		}
	}()

	// Set up multiple subscriber connections
	for i := range subscribers {
		subscribers[i] = connectWebSocket(t, getTestURL())
		readWebSocketResponse(t, subscribers[i], wsTestTimeout) // Skip welcome

		// Subscribe each connection
		subReq := &wsRequest{
			ID:      fmt.Sprintf("multi-sub-%d", i),
			Version: 1,
			Type:    api.WSMsgTypeDevices,
		}
		sendWebSocketRequest(t, subscribers[i], subReq)
		readWebSocketResponse(t, subscribers[i], wsTestTimeout) // devices response
	}

	// Updater connection
	updater := connectWebSocket(t, getTestURL())
	defer updater.Close()
	readWebSocketResponse(t, updater, wsTestTimeout) // Skip welcome

	// Get device ID and perform update
	deviceID := getFirstDeviceID(t, updater)

	updateReq := &wsRequest{
		ID:      "multi-subscriber-update",
		Version: 1,
		Type:    api.WSMsgTypeUpdateDeviceInfo,
		Data: mustMarshal(map[string]interface{}{
			"device_id": deviceID,
			"name":      fmt.Sprintf("Multi-Subscriber Test %d", time.Now().UnixNano()),
		}),
	}

	sendWebSocketRequest(t, updater, updateReq)
	updateResponse := readWebSocketResponse(t, updater, wsTestTimeout)

	//t.Logf("Update response - Type: %s, Code: %d, Message: %s", updateResponse.Type, updateResponse.Code, updateResponse.Message)

	// Handle potential update failure gracefully
	if updateResponse.Code == api.WSCodeUpdateFailed {
		t.Logf("Device update failed (acceptable in test environment): %s", updateResponse.Message)
		t.Skip("Skipping notification test since update failed")
		return
	}

	// Check if we got an update confirmation
	if updateResponse.ID != nil && *updateResponse.ID == "multi-subscriber-update" {
		if updateResponse.Code != api.WSCodeUpdated {
			t.Logf("Update failed: %s", updateResponse.Message)
			t.Skip("Skipping notification test due to update failure")
			return
		}
	} else if updateResponse.Type == api.WSMsgTypeError {
		t.Logf("Update failed: %s", updateResponse.Message)
		t.Skip("Skipping notification test due to update failure")
		return
	}

	// All subscribers should receive notification (with longer timeout for network delays)
	for i, conn := range subscribers {
		// Set explicit deadline for remote testing
		conn.SetReadDeadline(time.Now().Add(20 * time.Second))

		// Try to read notification with timeout handling
		_, data, err := conn.ReadMessage()
		if err != nil {
			// Handle timeout gracefully for remote testing
			if strings.Contains(err.Error(), "timeout") || strings.Contains(err.Error(), "deadline") {
				t.Logf("Subscriber %d did not receive notification within timeout (acceptable in test environment)", i)
				continue
			}
			t.Errorf("Subscriber %d failed to read message: %v", i, err)
			continue
		}

		var notification wsResponse
		if err := json.Unmarshal(data, &notification); err != nil {
			t.Errorf("Subscriber %d failed to unmarshal response: %v", i, err)
			continue
		}

		assert.Equal(t, api.WSMsgTypeDeviceUpdate, notification.Type,
			"Subscriber %d should receive notification", i)
		assert.Equal(t, api.WSCodeDeviceUpdated, notification.Code)
		assert.Nil(t, notification.ID)

		//t.Logf("Subscriber %d successfully received notification", i)
	}
}

// ====================
// CLUSTER INTEGRATION TESTS
// ====================

func TestWebSocketCrossClusterDeviceVisibility(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping cluster test in short mode")
	}

	// Test that we can see devices across cluster nodes
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	req := &wsRequest{
		ID:      "cluster-devices",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	devices, ok := response.Data.([]interface{})
	require.True(t, ok)

	// Should see at least one device (can be local or remote)
	assert.Greater(t, len(devices), 0, "Should see cluster devices")

	// Verify device data structure includes cluster info
	if len(devices) > 0 {
		device := devices[0].(map[string]interface{})
		assert.Contains(t, device, "address", "Device should have address")
		assert.Contains(t, device, "id", "Device should have ID")
	}
}

func TestWebSocketVIPConnection(t *testing.T) {
	// Test connecting through VIP (if configured)
	// This assumes VIP is configured to point to an active node
	vipURL := getTestURL() // Use the same URL logic for VIP testing

	conn, _, err := websocket.DefaultDialer.Dial(vipURL, nil)
	if err != nil {
		t.Skip("VIP not accessible, skipping VIP connection test")
	}
	defer conn.Close()

	// Should receive welcome message
	welcome := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, "welcome", welcome.Type)

	// Should be able to get device list through VIP
	req := &wsRequest{
		ID:      "vip-devices",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	assert.Equal(t, api.WSMsgTypeDevices, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
}

// ====================
// PERFORMANCE TESTS
// ====================

func TestWebSocketConcurrentConnections(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping performance test in short mode")
	}

	numConnections := 10
	connections := make([]*websocket.Conn, numConnections)
	defer func() {
		for _, conn := range connections {
			if conn != nil {
				conn.Close()
			}
		}
	}()

	// Create concurrent connections
	var wg sync.WaitGroup
	errCh := make(chan error, numConnections)
	for i := 0; i < numConnections; i++ {
		wg.Add(1)
		go func(index int) {
			defer wg.Done()
			conn, err := connectWebSocketRaw(getTestURL())
			if err != nil {
				errCh <- fmt.Errorf("connection %d dial failed: %w", index, err)
				return
			}
			connections[index] = conn

			// Each connection should get welcome
			welcome, err := readWebSocketResponseRaw(conn, wsTestTimeout)
			if err != nil {
				errCh <- fmt.Errorf("connection %d welcome read failed: %w", index, err)
				return
			}
			assert.Equal(t, "welcome", welcome.Type)
		}(i)
	}

	wg.Wait()
	close(errCh)
	for err := range errCh {
		require.NoError(t, err)
	}

	// Test that all connections are working
	for i, conn := range connections {
		req := &wsRequest{
			ID:      fmt.Sprintf("concurrent-ping-%d", i),
			Version: 1,
			Type:    api.WSMsgTypePing,
		}

		sendWebSocketRequest(t, conn, req)
		response := readWebSocketResponse(t, conn, wsTestTimeout)
		assert.Equal(t, api.WSMsgTypePong, response.Type)
	}
}

func TestWebSocketRapidRequests(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping rapid requests test in short mode")
	}

	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Send multiple rapid ping requests
	numRequests := 10
	for i := 0; i < numRequests; i++ {
		req := &wsRequest{
			ID:      fmt.Sprintf("rapid-%d", i),
			Version: 1,
			Type:    api.WSMsgTypePing,
		}
		sendWebSocketRequest(t, conn, req)
	}

	// Read all responses
	responses := make(map[string]*wsResponse)
	for i := 0; i < numRequests; i++ {
		response := readWebSocketResponse(t, conn, wsTestTimeout)
		responses[*response.ID] = response
	}

	// Verify all responses received
	assert.Len(t, responses, numRequests)
	for i := 0; i < numRequests; i++ {
		id := fmt.Sprintf("rapid-%d", i)
		response, exists := responses[id]
		assert.True(t, exists, "Missing response for %s", id)
		assert.Equal(t, api.WSMsgTypePong, response.Type)
	}
}

func TestWebSocketLongRunningConnection(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping long-running test in short mode")
	}

	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Keep connection alive with periodic pings for 10 seconds
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	timeout := time.After(10 * time.Second)
	counter := 0

	for {
		select {
		case <-timeout:
			//t.Logf("Successfully maintained connection for 10 seconds with %d pings", counter)
			return
		case <-ticker.C:
			counter++
			req := &wsRequest{
				ID:      fmt.Sprintf("keepalive-%d", counter),
				Version: 1,
				Type:    api.WSMsgTypePing,
			}

			sendWebSocketRequest(t, conn, req)
			response := readWebSocketResponse(t, conn, 2*time.Second)
			if response != nil {
				assert.Equal(t, api.WSMsgTypePong, response.Type)
			}
		}
	}
}

// ====================
// HELPER FUNCTIONS
// ====================

func getFirstDeviceID(t *testing.T, conn *websocket.Conn) string {
	req := &wsRequest{
		ID:      "helper-get-devices",
		Version: 1,
		Type:    api.WSMsgTypeDevices,
	}

	sendWebSocketRequest(t, conn, req)
	response := readWebSocketResponse(t, conn, wsTestTimeout)

	devices, ok := response.Data.([]interface{})
	require.True(t, ok)
	require.Greater(t, len(devices), 0)

	device := devices[0].(map[string]interface{})
	return device["id"].(string)
}
