package network

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	json "github.com/goccy/go-json"
)

const (
	bluetoothDeviceName = "Fusion Mini"

	backoffAttempts  = 10
	backoffDelay     = 50 * time.Millisecond
	backoffIncrement = 2
	bleRetryTime     = 5 * time.Second
	bleTimeout       = 15 * time.Second
	channelSize      = 10
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
	Type    string               `json:"type"` // "response" or "error"
	Payload BluetoothHTTPPayload `json:"payload"`
}

type BluetoothHTTPPayload struct {
	Error  string `json:"error,omitempty"`
	Status int    `json:"status,omitempty"`
	Body   string `json:"body,omitempty"`
}

// ResponseChunk defines the structure of each chunk notification.
type ResponseChunk struct {
	Data string `json:"data"`
	Last bool   `json:"last"`
}

type bluetoothTransport interface {
	serve(context.Context) error
	stop()
}

type notificationSession interface {
	Context() context.Context
	Close() error
	Write([]byte) error
}

// BLEServer currently hosts the BLE transport, but its internals are transport-agnostic so
// a BlueZ D-Bus BLE backend and a classic Bluetooth backend can share the same protocol logic.
type BLEServer struct {
	cancel  context.CancelFunc
	wg      sync.WaitGroup
	backend bluetoothTransport
}

type bluetoothBridge struct {
	logger              *logging.Logger
	globalRequestBuffer bytes.Buffer

	notificationMu   sync.Mutex
	notificationChan chan []byte

	requestMu sync.Mutex

	idleMu        sync.Mutex
	idleResetChan chan struct{}
}

func newBluetoothBridge(logger *logging.Logger) *bluetoothBridge {
	return &bluetoothBridge{logger: logger}
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
			Payload: BluetoothHTTPPayload{
				Error: "Unsupported HTTP method",
			},
		}, fmt.Errorf("unsupported HTTP method: %s", req.Method)
	}

	if err != nil {
		return BluetoothHTTPResponse{
			Type: "error",
			Payload: BluetoothHTTPPayload{
				Error: err.Error(),
			},
		}, err
	}
	defer httpResp.Body.Close()

	body, _ := io.ReadAll(httpResp.Body)
	response = BluetoothHTTPResponse{
		Type: "response",
		Payload: BluetoothHTTPPayload{
			Status: httpResp.StatusCode,
			Body:   string(body),
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

func (b *bluetoothBridge) resetIdleTimer() {
	b.idleMu.Lock()
	defer b.idleMu.Unlock()
	if b.idleResetChan == nil {
		return
	}
	select {
	case b.idleResetChan <- struct{}{}:
	default:
	}
}

func (b *bluetoothBridge) handleWrite(incoming []byte) {
	b.resetIdleTimer()

	go func() {
		b.requestMu.Lock()
		b.globalRequestBuffer.Write(incoming)
		data := b.globalRequestBuffer.Bytes()
		b.requestMu.Unlock()

		var dummy map[string]any
		if err := json.Unmarshal(data, &dummy); err != nil {
			if strings.Contains(err.Error(), "unexpected end") {
				return
			}
			b.logger.Error("Invalid JSON: %v", err)
			b.requestMu.Lock()
			b.globalRequestBuffer.Reset()
			b.requestMu.Unlock()
			return
		}

		b.requestMu.Lock()
		complete := make([]byte, len(data))
		copy(complete, data)
		b.globalRequestBuffer.Reset()
		b.requestMu.Unlock()

		respBytes, err := handleRequest(complete, b.logger)
		if err != nil {
			b.logger.Error("Error handling request: %v", err)
			return
		}

		b.notificationMu.Lock()
		ch := b.notificationChan
		b.notificationMu.Unlock()
		if ch == nil {
			b.logger.Error("No subscriber; response dropped")
			return
		}
		enqueueResponseChunks(respBytes, ch, b.logger)
	}()
}

func (b *bluetoothBridge) runNotificationSession(session notificationSession) {
	b.idleMu.Lock()
	b.idleResetChan = make(chan struct{}, 1)
	b.idleMu.Unlock()

	go func() {
		timer := time.NewTimer(bleTimeout)
		defer timer.Stop()
		for {
			select {
			case <-timer.C:
				b.logger.Warn("Closing stale BLE connection.")
				_ = session.Close()
				return
			case <-b.idleResetChan:
				if !timer.Stop() {
					<-timer.C
				}
				timer.Reset(bleTimeout)
			case <-session.Context().Done():
				b.idleMu.Lock()
				close(b.idleResetChan)
				b.idleResetChan = nil
				b.idleMu.Unlock()
				return
			}
		}
	}()

	b.notificationMu.Lock()
	b.notificationChan = make(chan []byte, channelSize)
	b.notificationMu.Unlock()

	for {
		select {
		case data := <-b.notificationChan:
			delay := backoffDelay
			sent := false
			for attempt := 1; attempt <= backoffAttempts; attempt++ {
				if err := session.Write(data); err != nil {
					b.logger.Debug("Failed to send notification (attempt %d/%d): %v", attempt, backoffAttempts, err)
					time.Sleep(delay)
					delay *= backoffIncrement
				} else {
					sent = true
					break
				}
			}
			if !sent {
				b.logger.Error("Dropping notification chunk after %d attempts", backoffAttempts)
			}
		case <-session.Context().Done():
			b.notificationMu.Lock()
			b.notificationChan = nil
			b.notificationMu.Unlock()
			return
		}
	}
}

// NewBLEServer initializes the BLE server and starts advertising in a separate goroutine.
func NewBLEServer(serviceUUID string, characterUUID string) (*BLEServer, error) {
	logger := logging.GetLogger()
	ctx, cancel := context.WithCancel(context.Background())

	bridge := newBluetoothBridge(logger)
	backend, err := newPlatformBLETransport(bluetoothDeviceName, serviceUUID, characterUUID, bridge)
	if err != nil {
		cancel()
		return nil, err
	}

	server := &BLEServer{
		cancel:  cancel,
		backend: backend,
	}

	server.wg.Add(1)
	go func() {
		defer server.wg.Done()
		if err := backend.serve(ctx); err != nil && !errors.Is(err, context.Canceled) {
			logger.Error("BLE transport stopped: %v", err)
		}
	}()

	logger.Info("BLE server initialized: %s %s", serviceUUID, characterUUID)
	return server, nil
}

// Stop terminates the BLE server by canceling its context,
// stopping the device, and waiting for the advertisement to finish.
func (s *BLEServer) Stop() {
	s.cancel()
	if s.backend != nil {
		s.backend.stop()
	}
	s.wg.Wait()
}
