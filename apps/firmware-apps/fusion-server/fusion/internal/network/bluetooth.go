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
)

const (
	advertiserName   = "Fusion Mini"
	backoffAttempts  = 10
	backoffDelay     = 50 * time.Millisecond
	backoffIncrement = 2
	bleRetryTime     = 5 * time.Second
	bleTimeout       = 15 * time.Second
	channelSize      = 10
	deviceName       = "Fusion Mini"
	maxChunkSize     = 100
	restTimeout      = 10 * time.Second
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
	client := &http.Client{Timeout: restTimeout}

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
	logger.Debug("Processing request: %s", string(data))
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

	logger.Debug("Response: %s", string(respBytes))
	return respBytes, nil
}

// enqueueResponseChunks splits the response into chunks and sends each chunk
// (wrapped in a ResponseChunk JSON object) to the notification channel.
func enqueueResponseChunks(response []byte, ch chan []byte, logger *logging.Logger) {
	totalChunks := (len(response) + maxChunkSize - 1) / maxChunkSize
	logger.Debug("Sending response in %d chunks", totalChunks)

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
		logger.Debug("Enqueued chunk %d/%d: %s", i+1, totalChunks, string(chunkBytes))
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

	d, err := newBLEDevice(deviceName)
	if err != nil {
		return nil, err
	}
	ble.SetDefaultDevice(d)

	// Create cancelable context
	ctx, cancel := context.WithCancel(context.Background())
	server := &BLEServer{ctx: ctx, cancel: cancel, device: d}

	// Shared channels and mutexes
	var (
		notificationChan chan []byte
		notificationMu   sync.Mutex
		requestMu        sync.Mutex
		idleMu           sync.Mutex
		idleResetChan    chan struct{}
	)

	svcUUID := ble.MustParse(serviceUUID)
	svc := ble.NewService(svcUUID)

	charUUID := ble.MustParse(characterUUID)
	char := ble.NewCharacteristic(charUUID)
	char.Property = ble.CharRead | ble.CharWrite | ble.CharNotify

	// Write handler. Reset idle timer and queue request
	char.HandleWrite(ble.WriteHandlerFunc(func(req ble.Request, rsp ble.ResponseWriter) {
		// Reset idle timer
		idleMu.Lock()
		if idleResetChan != nil {
			select {
			case idleResetChan <- struct{}{}:
			default:
			}
		}
		idleMu.Unlock()

		incoming := append([]byte(nil), req.Data()...)
		rsp.SetStatus(ble.ErrSuccess)

		go func() {
			requestMu.Lock()
			server.globalRequestBuffer.Write(incoming)
			data := server.globalRequestBuffer.Bytes()
			requestMu.Unlock()

			var dummy map[string]any
			if err := json.Unmarshal(data, &dummy); err != nil {
				if strings.Contains(err.Error(), "unexpected end") {
					return
				}
				logger.Error("Invalid JSON: %v", err)
				requestMu.Lock()
				server.globalRequestBuffer.Reset()
				requestMu.Unlock()
				return
			}

			requestMu.Lock()
			complete := make([]byte, len(data))
			copy(complete, data)
			server.globalRequestBuffer.Reset()
			requestMu.Unlock()

			respBytes, err := handleRequest(complete, logger)
			if err != nil {
				logger.Error("Error handling request: %v", err)
				return
			}

			notificationMu.Lock()
			ch := notificationChan
			notificationMu.Unlock()
			if ch == nil {
				logger.Error("No subscriber; response dropped")
				return
			}
			enqueueResponseChunks(respBytes, ch, logger)
		}()
	}))

	char.HandleNotify(ble.NotifyHandlerFunc(func(req ble.Request, n ble.Notifier) {
		conn := req.Conn()

		// Initialize idle reset channel
		idleMu.Lock()
		idleResetChan = make(chan struct{}, 1)
		idleMu.Unlock()

		// Spawn idle monitor
		go func() {
			timer := time.NewTimer(bleTimeout)
			defer timer.Stop()
			for {
				select {
				case <-timer.C:
					logger.Warn("Closing stale BLE connection.")
					conn.Close()
					return
				case <-idleResetChan:
					if !timer.Stop() {
						<-timer.C
					}
					timer.Reset(bleTimeout)
				case <-n.Context().Done():
					// Clean up idle monitor
					idleMu.Lock()
					close(idleResetChan)
					idleResetChan = nil
					idleMu.Unlock()
					return
				}
			}
		}()

		// Notification loop
		notificationMu.Lock()
		notificationChan = make(chan []byte, channelSize)
		notificationMu.Unlock()

		for {
			select {
			case data := <-notificationChan:
				delay := backoffDelay
				maxAttempts := backoffAttempts
				sent := false
				for attempt := 1; attempt <= maxAttempts; attempt++ {
					if _, err := n.Write(data); err != nil {
						logger.Debug("Failed to send notification (attempt %d/%d): %v", attempt, maxAttempts, err)
						time.Sleep(delay)
						delay *= backoffIncrement
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

	// Advertising loop
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
					if errors.Is(err, context.Canceled) {
						logger.Info("Shutting down BLE advertiser...")
						return
					}
					logger.Error("BLE advertising failed: %v. Retrying in %d seconds", err, bleRetryTime)
					time.Sleep(bleRetryTime * time.Second)
					continue
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
