package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"sync"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion/internal/routes"
)

const controllersServerAddr = "http://192.168.2.100:8080"
const mockControllersTCPAddr = "192.168.2.100:7950"

// MockTCPController represents a mocked wall controller
type MockTCPController struct {
	ID              string
	DeviceType      string
	FirmwareVersion string
	conn            net.Conn
	connected       bool
	mu              sync.Mutex
}

func TestControllerLifecycle(t *testing.T) {
	base := fmt.Sprintf("%s%s", controllersServerAddr, routes.ControllersEndpoint)

	t.Run("Single Controller Connection", func(t *testing.T) {
		controller := NewMockTCPController("ctrl1", "WallController", "1.0.0")

		err := controller.StartMockController()
		if err != nil {
			t.Fatalf("Failed to start mock controller: %v", err)
		}
		defer controller.Disconnect()

		time.Sleep(500 * time.Millisecond)

		resp, err := http.Get(base)
		if err != nil {
			t.Fatalf("GET controllers failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
		}

		var controllers []api.ControllerInfo
		if err := json.NewDecoder(resp.Body).Decode(&controllers); err != nil {
			t.Fatalf("decode controllers response: %v", err)
		}

		found := false
		for _, c := range controllers {
			if c.ID == "ctrl1" {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("TCP controller ctrl1 not found in controllers list")
		}
	})

	t.Run("Multiple Controllers Simultaneously", func(t *testing.T) {
		controllers := []*MockTCPController{
			NewMockTCPController("ctrl2", "WallController", "1.0.1"),
			NewMockTCPController("ctrl3", "WallController", "1.0.2"),
			NewMockTCPController("ctrl4", "WallController", "1.0.3"),
		}

		for _, ctrl := range controllers {
			err := ctrl.StartMockController()
			if err != nil {
				t.Fatalf("Failed to start controller %s: %v", ctrl.ID, err)
			}
		}

		// Cleanup all controllers
		defer func() {
			for _, ctrl := range controllers {
				ctrl.Disconnect()
			}
		}()

		time.Sleep(500 * time.Millisecond)

		resp, err := http.Get(base)
		if err != nil {
			t.Fatalf("GET controllers failed: %v", err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected 200 OK, got %d", resp.StatusCode)
		}

		var apiControllers []api.ControllerInfo
		if err := json.NewDecoder(resp.Body).Decode(&apiControllers); err != nil {
			t.Fatalf("decode controllers response: %v", err)
		}

		expectedIDs := []string{"ctrl2", "ctrl3", "ctrl4"}
		for _, expectedID := range expectedIDs {
			found := false
			for _, c := range apiControllers {
				if c.ID == expectedID {
					found = true
					break
				}
			}
			if !found {
				t.Errorf("TCP controller %s not found in controllers list", expectedID)
			}
		}
	})

	t.Run("Controller Disconnection", func(t *testing.T) {
		controller := NewMockTCPController("ctrl5", "WallController", "1.0.4")

		err := controller.StartMockController()
		if err != nil {
			t.Fatalf("Failed to start mock controller: %v", err)
		}

		time.Sleep(500 * time.Millisecond)

		resp, err := http.Get(base)
		if err != nil {
			t.Fatalf("GET controllers failed: %v", err)
		}
		defer resp.Body.Close()

		var controllers []api.ControllerInfo
		json.NewDecoder(resp.Body).Decode(&controllers)

		found := false
		for _, c := range controllers {
			if c.ID == "ctrl5" {
				found = true
				break
			} else {
				t.Logf("Found controller: %s", c.ID)
			}
		}
		if !found {
			t.Error("Controller ctrl5 was not found before disconnection")
		}

		err = controller.Disconnect()
		if err != nil {
			t.Fatalf("Failed to disconnect controller: %v", err)
		}

		time.Sleep(500 * time.Millisecond)

		resp, err = http.Get(base)
		if err != nil {
			t.Fatalf("GET controllers failed: %v", err)
		}
		defer resp.Body.Close()

		controllers = nil
		json.NewDecoder(resp.Body).Decode(&controllers)

		found = false
		for _, c := range controllers {
			if c.ID == "ctrl5" {
				found = true
				break
			}
		}
		if found {
			t.Error("Controller ctrl5 should be removed after disconnection")
		}
	})

}

// NewMockTCPController creates a new mock controller
func NewMockTCPController(id, deviceType, firmwareVersion string) *MockTCPController {
	return &MockTCPController{
		ID:              id,
		DeviceType:      deviceType,
		FirmwareVersion: firmwareVersion,
	}
}

// Connect establishes TCP connection to the server
func (m *MockTCPController) Connect() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	conn, err := net.Dial("tcp", mockControllersTCPAddr)
	if err != nil {
		return fmt.Errorf("failed to connect to %s: %v", mockControllersTCPAddr, err)
	}

	m.conn = conn
	m.connected = true
	return nil
}

// Disconnect closes the TCP connection
func (m *MockTCPController) Disconnect() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.conn != nil {
		err := m.conn.Close()
		m.conn = nil
		m.connected = false
		return err
	}
	return nil
}

// HandleMessages processes messages from the server
func (m *MockTCPController) HandleMessages() error {
	decoder := json.NewDecoder(m.conn)
	encoder := json.NewEncoder(m.conn)

	for {
		var msg api.ControllerTCPMessage
		if err := decoder.Decode(&msg); err != nil {
			return fmt.Errorf("failed to decode message: %v", err)
		}

		switch msg.Action {
		case "identify":

			identifyResponsePayload := api.ControllerIdentifyResponse{
				ID:              m.ID,
				DeviceType:      m.DeviceType,
				FirmwareVersion: m.FirmwareVersion,
			}

			payloadBytes, err := json.Marshal(identifyResponsePayload)
			if err != nil {
				return fmt.Errorf("failed to marshal identity response: %v", err)
			}

			response := api.ControllerTCPMessage{
				Action:  "identity",
				Payload: payloadBytes,
			}

			if err := encoder.Encode(response); err != nil {
				return fmt.Errorf("failed to send identity response: %v", err)
			}
		default:
			// Need to extend to wink and reverse wink
		}
	}
}

// StartMockController starts a mock controller
func (m *MockTCPController) StartMockController() error {
	if err := m.Connect(); err != nil {
		return err
	}

	go func() {
		if err := m.HandleMessages(); err != nil {
			m.mu.Lock()
			m.connected = false
			m.mu.Unlock()
		}
	}()

	return nil
}
