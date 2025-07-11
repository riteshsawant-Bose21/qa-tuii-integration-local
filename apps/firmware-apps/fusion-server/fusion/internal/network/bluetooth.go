package network

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/go-ble/ble"
	"github.com/go-ble/ble/examples/lib/dev"
)

const (
	advertiserName = "Fusion Mini"
	bleRetryTime   = 5
	maxChunkSize   = 100
	errUnexpected  = 0x80
)

// BluetoothHTTPRequest represents the structure of incoming HTTP-like messages.
type BluetoothHTTPRequest struct {
	Method string         `json:"method"` // "GET" or "POST"
	URL    string         `json:"url"`    // The API endpoint
	Body   map[string]any `json:"body"`   // Optional body for POST requests
}

// BluetoothHTTPResponse represents the structure of outgoing HTTP responses.
type BluetoothHTTPResponse struct {
	Type    string         `json:"type"` // "response" or "error"
	Payload map[string]any `json:"payload"`
}

// ResponseChunk defines the structure of each chunk notification.
type ResponseChunk struct {
	Data string `json:"data"`
	Last bool   `json:"last"`
}

// performHTTPRequest processes the incoming request and calls the actual REST API.
func performHTTPRequest(req BluetoothHTTPRequest) (BluetoothHTTPResponse, error) {
	var response BluetoothHTTPResponse
	client := &http.Client{Timeout: 10 * time.Second}

	var httpResp *http.Response
	var err error

	switch req.Method {
	case "GET":
		httpResp, err = client.Get(req.URL)
	case "POST":
		bodyBytes, _ := json.Marshal(req.Body)
		httpResp, err = client.Post(req.URL, api.JsonMIMEType, bytes.NewBuffer(bodyBytes))
	default:
		return BluetoothHTTPResponse{
			Type: "error",
			Payload: map[string]any{
				"error": "Unsupported HTTP method",
			},
		}, fmt.Errorf("unsupported HTTP method: %s", req.Method)
	}

	if err != nil {
		return BluetoothHTTPResponse{
			Type: "error",
			Payload: map[string]any{
				"error": err.Error(),
			},
		}, err
	}
	defer httpResp.Body.Close()

	body, _ := io.ReadAll(httpResp.Body)
	response = BluetoothHTTPResponse{
		Type: "response",
		Payload: map[string]any{
			"status": httpResp.StatusCode,
			"body":   string(body),
		},
	}

	return response, nil
}

func handleRequest(data []byte, logger *logging.Logger) ([]byte, error) {
	//logger.Debug("Processing request: %s", string(data))
	var wrapper struct {
		Type    string               `json:"type"`
		Payload BluetoothHTTPRequest `json:"payload"`
	}

	if err := json.Unmarshal(data, &wrapper); err != nil {
		logger.Error("Invalid JSON format: %v", err)
		return nil, errors.New("invalid JSON format")
	}

	response, err := performHTTPRequest(wrapper.Payload)
	if err != nil {
		logger.Error("Error performing HTTP request: %v", err)
		return nil, err
	}

	respBytes, err := json.Marshal(response)
	if err != nil {
		logger.Error("Error serializing response: %v", err)
		return nil, err
	}

	//logger.Debug("Response: %s", string(respBytes))
	return respBytes, nil
}

// enqueueResponseChunks splits the response into chunks and sends each chunk
// (wrapped in a ResponseChunk JSON object) to the notification channel.
func enqueueResponseChunks(response []byte, ch chan []byte, logger *logging.Logger) {
	totalChunks := (len(response) + maxChunkSize - 1) / maxChunkSize
	//logger.Debug("Sending response in %d chunks", totalChunks)

	for i := range totalChunks {
		start := i * maxChunkSize
		end := min(start+maxChunkSize, len(response))
		chunkData := response[start:end]

		rc := ResponseChunk{
			Data: string(chunkData),
			Last: (i == totalChunks-1),
		}
		chunkBytes, err := json.Marshal(rc)
		if err != nil {
			logger.Error("Error marshaling chunk %d: %v", i, err)
			continue
		}

		// This send is blocking if the channel is full.
		ch <- chunkBytes
		//logger.Debug("Enqueued chunk %d/%d: %s", i+1, totalChunks, string(chunkBytes))
	}
}

// BLEServer encapsulates the BLE server's context, cancel function, device, and WaitGroup.
type BLEServer struct {
	ctx                 context.Context
	cancel              context.CancelFunc
	device              ble.Device
	wg                  sync.WaitGroup
	globalRequestBuffer bytes.Buffer
}

// NewBLEServer initializes the BLE server and starts advertising in a separate goroutine.
func NewBLEServer(serviceUUID string, characterUUID string) (*BLEServer, error) {
	logger := logging.GetLogger()

	// Initialize the default BLE device.
	d, err := dev.DefaultDevice()
	if err != nil {
		return nil, err
	}
	ble.SetDefaultDevice(d)

	ctx, cancel := context.WithCancel(context.Background())
	server := &BLEServer{
		ctx:    ctx,
		cancel: cancel,
		device: d,
	}

	svcUUID := ble.MustParse(serviceUUID)
	svc := ble.NewService(svcUUID)

	charUUID := ble.MustParse(characterUUID)
	char := ble.NewCharacteristic(charUUID)
	char.Property = ble.CharRead | ble.CharWrite | ble.CharNotify

	// Use a channel to queue responses for the notifier.
	var notificationChan chan []byte
	var notificationMu sync.Mutex

	// Write handler: Process the incoming request and send the response
	// to the notification channel if a subscriber exists.
	char.HandleWrite(ble.WriteHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		incoming := req.Data()

		// Append the incoming fragment to the global buffer.
		server.globalRequestBuffer.Write(incoming)

		// Try to unmarshal the entire accumulated data.
		accumulated := server.globalRequestBuffer.Bytes()
		var dummy map[string]any
		err := json.Unmarshal(accumulated, &dummy)
		if err != nil {
			// If error indicates incomplete JSON, just acknowledge and wait for more.
			if strings.Contains(err.Error(), "unexpected end") {
				rsp.SetStatus(ble.ErrSuccess)
				return
			}
			// If it’s a genuine error, reset the buffer.
			logging.GetLogger().Error("Invalid JSON format: %v", err)
			server.globalRequestBuffer.Reset()
			rsp.SetStatus(errUnexpected)
			return
		}

		// If we reach here, the accumulated data forms valid JSON.
		completeData := server.globalRequestBuffer.Bytes()
		// Reset the buffer for the next message.
		server.globalRequestBuffer.Reset()

		// Process the complete request.
		response, err := handleRequest(completeData, logging.GetLogger())
		if err != nil {
			logging.GetLogger().Error("Error handling request: %v", err)
			rsp.SetStatus(0x80)
			return
		}
		rsp.SetStatus(ble.ErrSuccess)

		notificationMu.Lock()
		ch := notificationChan
		notificationMu.Unlock()
		if ch != nil {
			// Launch a goroutine to enqueue the response in chunks.
			go enqueueResponseChunks(response, ch, logging.GetLogger())
		} else {
			logging.GetLogger().Error("No subscriber for notifications; response not sent")
		}
	}))

	char.HandleRead(ble.ReadHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		rsp.Write([]byte("Ready"))
	}))

	// Notify handler called when a central subscribes.
	char.HandleNotify(ble.NotifyHandlerFunc(func(req ble.Request, n ble.Notifier) {
		// Create a channel with increased buffer size.
		ch := make(chan []byte, 10)
		notificationMu.Lock()
		notificationChan = ch
		notificationMu.Unlock()

		// Loop until the central unsubscribes.
		for {
			select {
			case data := <-ch:
				// Use exponential backoff when the TX queue is full.
				delay := 50 * time.Millisecond
				maxAttempts := 10
				sent := false
				for range maxAttempts {
					if _, err := n.Write(data); err != nil {
						//logger.Debug("Failed to send notification: %v", err)
						time.Sleep(delay)
						delay *= 2
					} else {
						sent = true
						break
					}
				}
				if !sent {
					logger.Error("Dropping notification chunk after %d attempts", maxAttempts)
				}
			case <-n.Context().Done():
				notificationMu.Lock()
				notificationChan = nil
				notificationMu.Unlock()
				return
			}
		}
	}))

	svc.AddCharacteristic(char)
	ble.AddService(svc)

	server.wg.Add(1)
	go func() {
		defer server.wg.Done()
		for {
			select {
			case <-ctx.Done():
				return
			default:
				err := ble.AdvertiseNameAndServices(ctx, advertiserName, svc.UUID)
				if err != nil {
					logger.Error("BLE advertising failed: %v. Retrying in %d seconds", err, bleRetryTime)
					time.Sleep(bleRetryTime * time.Second)
				}
			}
		}
	}()

	logger.Info("BLE server initialized: %s %s", serviceUUID, characterUUID)

	return server, nil
}

// Stop terminates the BLE server by canceling its context,
// stopping the device, and waiting for the advertisement to finish.
func (s *BLEServer) Stop() {
	s.cancel()
	s.device.Stop()
	s.wg.Wait()
}
