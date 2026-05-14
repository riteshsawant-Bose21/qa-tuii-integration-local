package main

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"fusion/internal/api"
)

// ====================
// METER DATA SUBSCRIPTION TESTS
// ====================

func TestWebSocketSubscribeMeterData(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	request := &wsRequest{
		ID:      "meter-sub-1",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeSubscribeMeterData,
	}
	sendWebSocketRequest(t, conn, request)

	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeSubscribeMeterData, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
	assert.Equal(t, api.WSStatusSuccess, response.Status)
	assert.NotNil(t, response.ID)
	assert.Equal(t, "meter-sub-1", *response.ID)
}

func TestWebSocketSubscribeMeterDataIdempotent(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Subscribe twice — both should succeed
	for i := 0; i < 2; i++ {
		request := &wsRequest{
			ID:      "meter-sub-idem",
			Version: api.WSCurrentVersion,
			Type:    api.WSMsgTypeSubscribeMeterData,
		}
		sendWebSocketRequest(t, conn, request)

		response := readWebSocketResponse(t, conn, wsTestTimeout)
		assert.Equal(t, api.WSMsgTypeSubscribeMeterData, response.Type)
		assert.Equal(t, api.WSCodeOK, response.Code)
	}
}

// ====================
// METER DATA FILTER TESTS
// ====================

func TestWebSocketUpdateMeterDataFilter(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Set a filter
	payload := map[string]interface{}{
		"filter": []string{"block_a", "block_b"},
	}
	request := &wsRequest{
		ID:      "meter-filter-1",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(payload),
	}
	sendWebSocketRequest(t, conn, request)

	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUpdateMeterDataFilter, response.Type)
	assert.Equal(t, api.WSCodeUpdated, response.Code)
	assert.Equal(t, api.WSStatusSuccess, response.Status)
	assert.NotNil(t, response.ID)
	assert.Equal(t, "meter-filter-1", *response.ID)

	// Validate response data includes filter_count
	if response.Data != nil {
		dataMap, ok := response.Data.(map[string]interface{})
		if ok {
			assert.Equal(t, float64(2), dataMap["filter_count"])
		}
	}
}

func TestWebSocketUpdateMeterDataFilterEmpty(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Set an empty filter
	payload := map[string]interface{}{
		"filter": []string{},
	}
	request := &wsRequest{
		ID:      "meter-filter-empty",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(payload),
	}
	sendWebSocketRequest(t, conn, request)

	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUpdateMeterDataFilter, response.Type)
	assert.Equal(t, api.WSCodeUpdated, response.Code)

	if response.Data != nil {
		dataMap, ok := response.Data.(map[string]interface{})
		if ok {
			assert.Equal(t, float64(0), dataMap["filter_count"])
		}
	}
}

func TestWebSocketUpdateMeterDataFilterInvalidPayload(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	request := &wsRequest{
		ID:      "meter-filter-bad",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    json.RawMessage(`"not an object"`),
	}
	sendWebSocketRequest(t, conn, request)

	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeError, response.Type)
	assert.Equal(t, api.WSCodeInvalidPayload, response.Code)
	assert.Equal(t, api.WSStatusError, response.Status)
}

func TestWebSocketUpdateMeterDataFilterAutoSubscribes(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Setting a filter without explicit subscribe should still succeed
	// (auto-subscribes under the hood)
	payload := map[string]interface{}{
		"filter": []string{"block_x"},
	}
	request := &wsRequest{
		ID:      "meter-filter-autosub",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(payload),
	}
	sendWebSocketRequest(t, conn, request)

	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUpdateMeterDataFilter, response.Type)
	assert.Equal(t, api.WSCodeUpdated, response.Code)
}

func TestWebSocketUpdateMeterDataFilterReplace(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Set initial filter
	payload1 := map[string]interface{}{
		"filter": []string{"block_a", "block_b"},
	}
	request := &wsRequest{
		ID:      "meter-filter-r1",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(payload1),
	}
	sendWebSocketRequest(t, conn, request)
	resp1 := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSCodeUpdated, resp1.Code)

	// Replace with different filter
	payload2 := map[string]interface{}{
		"filter": []string{"block_c", "block_d", "block_e"},
	}
	request2 := &wsRequest{
		ID:      "meter-filter-r2",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(payload2),
	}
	sendWebSocketRequest(t, conn, request2)
	resp2 := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSCodeUpdated, resp2.Code)

	if resp2.Data != nil {
		dataMap, ok := resp2.Data.(map[string]interface{})
		if ok {
			assert.Equal(t, float64(3), dataMap["filter_count"])
		}
	}
}

// ====================
// METER DATA UNSUBSCRIBE TESTS
// ====================

func TestWebSocketUnsubscribeMeterData(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// First subscribe
	subReq := &wsRequest{
		ID:      "meter-unsub-setup",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeSubscribeMeterData,
	}
	sendWebSocketRequest(t, conn, subReq)
	readWebSocketResponse(t, conn, wsTestTimeout) // consume subscribe response

	// Now unsubscribe
	unsubReq := &wsRequest{
		ID:      "meter-unsub-1",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUnsubscribeMeterData,
	}
	sendWebSocketRequest(t, conn, unsubReq)

	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUnsubscribeMeterData, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
	assert.Equal(t, api.WSStatusSuccess, response.Status)
	assert.NotNil(t, response.ID)
	assert.Equal(t, "meter-unsub-1", *response.ID)
}

func TestWebSocketUnsubscribeMeterDataWithoutSubscribe(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Unsubscribe without subscribing first — should succeed gracefully
	request := &wsRequest{
		ID:      "meter-unsub-noop",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUnsubscribeMeterData,
	}
	sendWebSocketRequest(t, conn, request)

	response := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUnsubscribeMeterData, response.Type)
	assert.Equal(t, api.WSCodeOK, response.Code)
}

// ====================
// METER DATA LIFECYCLE TESTS
// ====================

func TestWebSocketMeterDataFullLifecycle(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Step 1: Subscribe to meter data
	subReq := &wsRequest{
		ID:      "lifecycle-sub",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeSubscribeMeterData,
	}
	sendWebSocketRequest(t, conn, subReq)
	subResp := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeSubscribeMeterData, subResp.Type)
	assert.Equal(t, api.WSCodeOK, subResp.Code)

	// Step 2: Set a filter
	filterPayload := map[string]interface{}{
		"filter": []string{"meter_1", "meter_2"},
	}
	filterReq := &wsRequest{
		ID:      "lifecycle-filter",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(filterPayload),
	}
	sendWebSocketRequest(t, conn, filterReq)
	filterResp := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUpdateMeterDataFilter, filterResp.Type)
	assert.Equal(t, api.WSCodeUpdated, filterResp.Code)

	// Step 3: Update filter to different IDs
	filterPayload2 := map[string]interface{}{
		"filter": []string{"meter_3"},
	}
	filterReq2 := &wsRequest{
		ID:      "lifecycle-filter2",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(filterPayload2),
	}
	sendWebSocketRequest(t, conn, filterReq2)
	filterResp2 := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUpdateMeterDataFilter, filterResp2.Type)
	assert.Equal(t, api.WSCodeUpdated, filterResp2.Code)

	// Step 4: Unsubscribe
	unsubReq := &wsRequest{
		ID:      "lifecycle-unsub",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUnsubscribeMeterData,
	}
	sendWebSocketRequest(t, conn, unsubReq)
	unsubResp := readWebSocketResponse(t, conn, wsTestTimeout)
	assert.Equal(t, api.WSMsgTypeUnsubscribeMeterData, unsubResp.Type)
	assert.Equal(t, api.WSCodeOK, unsubResp.Code)
}

func TestWebSocketMeterDataMultipleConnections(t *testing.T) {
	// Two connections with different filters
	conn1 := connectWebSocket(t, getTestURL())
	defer conn1.Close()
	conn2 := connectWebSocket(t, getTestURL())
	defer conn2.Close()

	readWebSocketResponse(t, conn1, wsTestTimeout) // Skip welcome
	readWebSocketResponse(t, conn2, wsTestTimeout) // Skip welcome

	// conn1 subscribes and sets filter for block_a
	subReq1 := &wsRequest{
		ID:      "multi-sub-1",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeSubscribeMeterData,
	}
	sendWebSocketRequest(t, conn1, subReq1)
	resp1 := readWebSocketResponse(t, conn1, wsTestTimeout)
	assert.Equal(t, api.WSCodeOK, resp1.Code)

	filterReq1 := &wsRequest{
		ID:      "multi-filter-1",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(map[string]interface{}{"filter": []string{"block_a"}}),
	}
	sendWebSocketRequest(t, conn1, filterReq1)
	fResp1 := readWebSocketResponse(t, conn1, wsTestTimeout)
	assert.Equal(t, api.WSCodeUpdated, fResp1.Code)

	// conn2 subscribes and sets filter for block_b
	subReq2 := &wsRequest{
		ID:      "multi-sub-2",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeSubscribeMeterData,
	}
	sendWebSocketRequest(t, conn2, subReq2)
	resp2 := readWebSocketResponse(t, conn2, wsTestTimeout)
	assert.Equal(t, api.WSCodeOK, resp2.Code)

	filterReq2 := &wsRequest{
		ID:      "multi-filter-2",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(map[string]interface{}{"filter": []string{"block_b"}}),
	}
	sendWebSocketRequest(t, conn2, filterReq2)
	fResp2 := readWebSocketResponse(t, conn2, wsTestTimeout)
	assert.Equal(t, api.WSCodeUpdated, fResp2.Code)

	// conn1 unsubscribes — conn2 should still be active
	unsubReq := &wsRequest{
		ID:      "multi-unsub-1",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUnsubscribeMeterData,
	}
	sendWebSocketRequest(t, conn1, unsubReq)
	unsubResp := readWebSocketResponse(t, conn1, wsTestTimeout)
	assert.Equal(t, api.WSCodeOK, unsubResp.Code)

	// conn2 can still update its filter
	filterReq3 := &wsRequest{
		ID:      "multi-filter-3",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(map[string]interface{}{"filter": []string{"block_c", "block_d"}}),
	}
	sendWebSocketRequest(t, conn2, filterReq3)
	fResp3 := readWebSocketResponse(t, conn2, wsTestTimeout)
	assert.Equal(t, api.WSCodeUpdated, fResp3.Code)
}

func TestWebSocketMeterDataDisconnectCleansUp(t *testing.T) {
	// First connection subscribes and sets filter
	conn1 := connectWebSocket(t, getTestURL())

	readWebSocketResponse(t, conn1, wsTestTimeout) // Skip welcome

	subReq := &wsRequest{
		ID:      "disconnect-sub",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeSubscribeMeterData,
	}
	sendWebSocketRequest(t, conn1, subReq)
	readWebSocketResponse(t, conn1, wsTestTimeout)

	filterReq := &wsRequest{
		ID:      "disconnect-filter",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeUpdateMeterDataFilter,
		Data:    mustMarshal(map[string]interface{}{"filter": []string{"block_a", "block_b"}}),
	}
	sendWebSocketRequest(t, conn1, filterReq)
	readWebSocketResponse(t, conn1, wsTestTimeout)

	// Close connection abruptly (simulates disconnect)
	conn1.Close()

	// Wait for server to process the disconnect
	time.Sleep(500 * time.Millisecond)

	// Second connection should work fine — server shouldn't be broken
	conn2 := connectWebSocket(t, getTestURL())
	defer conn2.Close()

	welcome := readWebSocketResponse(t, conn2, wsTestTimeout)
	assert.Equal(t, "welcome", welcome.Type)

	// Can subscribe and set filter on new connection
	subReq2 := &wsRequest{
		ID:      "disconnect-sub-2",
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeSubscribeMeterData,
	}
	sendWebSocketRequest(t, conn2, subReq2)
	resp := readWebSocketResponse(t, conn2, wsTestTimeout)
	assert.Equal(t, api.WSCodeOK, resp.Code)
}

// ====================
// METER DATA ERROR HANDLING TESTS
// ====================

func TestWebSocketMeterDataErrorCases(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	tests := []struct {
		name         string
		request      *wsRequest
		expectedCode int
		expectedType string
	}{
		{
			name: "filter with null data",
			request: &wsRequest{
				ID:      "err-null-data",
				Version: api.WSCurrentVersion,
				Type:    api.WSMsgTypeUpdateMeterDataFilter,
				Data:    json.RawMessage(`null`),
			},
			expectedCode: api.WSCodeInvalidPayload,
			expectedType: api.WSMsgTypeError,
		},
		{
			name: "filter with invalid JSON",
			request: &wsRequest{
				ID:      "err-invalid-json",
				Version: api.WSCurrentVersion,
				Type:    api.WSMsgTypeUpdateMeterDataFilter,
				Data:    json.RawMessage(`"not an object"`),
			},
			expectedCode: api.WSCodeInvalidPayload,
			expectedType: api.WSMsgTypeError,
		},
		{
			name: "filter with wrong field type",
			request: &wsRequest{
				ID:      "err-wrong-type",
				Version: api.WSCurrentVersion,
				Type:    api.WSMsgTypeUpdateMeterDataFilter,
				Data:    json.RawMessage(`{"filter": "not an array"}`),
			},
			expectedCode: api.WSCodeInvalidPayload,
			expectedType: api.WSMsgTypeError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			sendWebSocketRequest(t, conn, tt.request)
			response := readWebSocketResponse(t, conn, wsTestTimeout)
			assert.Equal(t, tt.expectedType, response.Type)
			assert.Equal(t, tt.expectedCode, response.Code)
			assert.Equal(t, api.WSStatusError, response.Status)
		})
	}
}

func TestWebSocketMeterDataResponseIDs(t *testing.T) {
	conn := connectWebSocket(t, getTestURL())
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout) // Skip welcome

	// Each response should echo back the request ID
	ids := []string{"id-alpha", "id-beta", "id-gamma"}

	for _, id := range ids {
		request := &wsRequest{
			ID:      id,
			Version: api.WSCurrentVersion,
			Type:    api.WSMsgTypeSubscribeMeterData,
		}
		sendWebSocketRequest(t, conn, request)
		response := readWebSocketResponse(t, conn, wsTestTimeout)
		require.NotNil(t, response.ID)
		assert.Equal(t, id, *response.ID)
	}
}
