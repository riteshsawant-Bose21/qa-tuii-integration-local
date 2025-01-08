package network

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"fusion/internal/logging"
	"io"
	"net/http"
	"time"

	"github.com/go-ble/ble"
	"github.com/go-ble/ble/examples/lib/dev"
)

const (
	jsonContentType = "application/json"
	serviceUUID     = "12345678-90EF-1234-5678-90ABCDEFABCD"
	characterUUID   = "ABCD5678-90EF-1234-5678-90ABCDEF1234"
)

// BluetoothHTTPRequest represents the structure of incoming HTTP-like messages
type BluetoothHTTPRequest struct {
	Method string                 `json:"method"` // "GET" or "POST"
	URL    string                 `json:"url"`    // The API endpoint
	Body   map[string]interface{} `json:"body"`   // Optional body for POST requests
}

// BluetoothHTTPResponse represents the structure of outgoing HTTP responses
type BluetoothHTTPResponse struct {
	Type    string                 `json:"type"` // "response" or "error"
	Payload map[string]interface{} `json:"payload"`
}

// performHTTPRequest processes the incoming request and calls the actual REST API
func performHTTPRequest(req BluetoothHTTPRequest) (BluetoothHTTPResponse, error) {
	var response BluetoothHTTPResponse
	client := &http.Client{Timeout: 10 * time.Second}

	var httpResp *http.Response
	var err error

	// Prepare the request
	switch req.Method {
	case "GET":
		httpResp, err = client.Get(req.URL)
	case "POST":
		bodyBytes, _ := json.Marshal(req.Body)
		httpResp, err = client.Post(req.URL, jsonContentType, bytes.NewBuffer(bodyBytes))
	default:
		return BluetoothHTTPResponse{
			Type: "error",
			Payload: map[string]interface{}{
				"error": "Unsupported HTTP method",
			},
		}, fmt.Errorf("unsupported HTTP method: %s", req.Method)
	}

	if err != nil {
		return BluetoothHTTPResponse{
			Type: "error",
			Payload: map[string]interface{}{
				"error": err.Error(),
			},
		}, err
	}
	defer httpResp.Body.Close()

	// Read response body
	body, _ := io.ReadAll(httpResp.Body)

	// Construct response
	response = BluetoothHTTPResponse{
		Type: "response",
		Payload: map[string]interface{}{
			"status": httpResp.StatusCode,
			"body":   string(body),
		},
	}

	return response, nil
}

func handleRequest(data []byte, logger *logging.Logger) ([]byte, error) {
	logger.Info("Processing request: %s", string(data))

	// Define a wrapper for the JSON structure
	var wrapper struct {
		Type    string               `json:"type"`
		Payload BluetoothHTTPRequest `json:"payload"`
	}

	// Parse the JSON into the wrapper struct
	if err := json.Unmarshal(data, &wrapper); err != nil {
		logger.Error("Invalid JSON format: %v", err)
		return nil, errors.New("invalid JSON format")
	}

	// Perform the HTTP request
	response, err := performHTTPRequest(wrapper.Payload)
	if err != nil {
		logger.Error("Error performing HTTP request: %v", err)
		return nil, err
	}

	// Serialize the response to JSON
	respBytes, err := json.Marshal(response)
	if err != nil {
		logger.Error("Error serializing response: %v", err)
		return nil, err
	}

	logger.Info("Response: %s", string(respBytes))
	return respBytes, nil
}

func StartBLEServer() {
	logger := logging.GetLogger()

	// Default device (using OS-specific USB device)
	d, err := dev.DefaultDevice()
	if err != nil {
		logger.Fatal("Failed to create device: %v", err)
	}
	ble.SetDefaultDevice(d)

	// Define service and characteristic UUIDs
	svcUUID := ble.MustParse(serviceUUID)
	charUUID := ble.MustParse(characterUUID)

	// Create a new service
	svc := ble.NewService(svcUUID)

	// Create characteristic
	char := ble.NewCharacteristic(charUUID)
	char.HandleWrite(ble.WriteHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		logger.Info("Received data: %s", string(req.Data()))

		response, err := handleRequest(req.Data(), logger)
		if err != nil {
			logger.Error("Error handling request: %v", err)
			return
		}

		// Send response
		_, err = rsp.Write(response)
		if err != nil {
			logger.Error("Failed to send response: %v", err)
		}
	}))
	char.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		// Handle read requests if needed
		rsp.Write([]byte("Ready"))
	}))

	// Add characteristic to service
	svc.AddCharacteristic(char)

	// Start advertising
	ctx := ble.WithSigHandler(context.WithTimeout(context.Background(), 24*time.Hour))
	err = ble.AdvertiseNameAndServices(ctx, "FusionServer", svc.UUID)
	if err != nil {
		logger.Fatal("Failed to advertise: %v", err)
	}

	logger.Info("BLE server started successfully!")

	// Keep server running
	<-ctx.Done()
	logger.Info("Server stopped")
}
