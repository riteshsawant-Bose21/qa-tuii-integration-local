//go:build controllers

package main

import (
	"encoding/binary"
	"fmt"
	"fusion/internal/controllers/cxa"
	"net"
	"sync"
	"testing"
	"time"
)

type testServer struct {
	listener net.Listener
	conn     net.Conn
	data     []byte
	wg       sync.WaitGroup
}

func newTestServer(t *testing.T) *testServer {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("failed to create test server: %v", err)
	}
	return &testServer{listener: l}
}

func (s *testServer) accept() {
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		var err error
		s.conn, err = s.listener.Accept()
		if err != nil {
			return
		}
	}()
}

func (s *testServer) close() {
	if s.conn != nil {
		s.conn.Close()
	}
	if s.listener != nil {
		s.listener.Close()
	}
}

func (s *testServer) read() {
	if s.conn == nil {
		s.data = nil
		return
	}

	s.data = make([]byte, 20)
	_, err := s.conn.Read(s.data)
	if err != nil {
		s.data = nil
		return
	}
}

func (s *testServer) waitForConnection(timeout time.Duration) error {
	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return nil
	case <-time.After(timeout):
		return fmt.Errorf("timeout waiting for connection")
	}
}

func setupTestServer(t *testing.T, ctrlType cxa.ControllerType) (*cxa.Device, *testServer) {
	server := newTestServer(t)
	server.accept()

	// Create device using server's address
	device, err := cxa.NewDevice(ctrlType, 1, server.listener.Addr().String())
	if err != nil {
		server.close()
		t.Fatalf("failed to create device: %v", err)
	}

	// Wait for connection to be established
	if err := server.waitForConnection(time.Second); err != nil {
		server.close()
		t.Fatal(err)
	}

	return device, server
}

func TestNewDevice(t *testing.T) {
	// Test successful creation
	device, server := setupTestServer(t, cxa.CC1)
	defer server.close()

	if device == nil {
		t.Error("NewDevice() returned nil device")
	}

	// Test with invalid address
	_, err := cxa.NewDevice(cxa.CC1, 1, "invalid:address")
	if err == nil {
		t.Error("Expected error with invalid address, got nil")
	}
}

func TestDeviceClose(t *testing.T) {
	device, server := setupTestServer(t, cxa.CC1)
	defer server.close()

	// Write some data first to ensure connection is established
	err := device.SetVolume(0.5)
	if err != nil {
		t.Fatalf("Failed to write test data: %v", err)
	}

	// Read the initial data
	server.read()
	if server.data == nil {
		t.Fatal("Failed to read initial test data")
	}

	// Close the device
	device.Close()

	// Try to read from connection - should fail
	server.read()
	if server.data != nil {
		t.Error("Connection was not closed properly")
	}
}

func TestSetVolume(t *testing.T) {
	tests := []struct {
		name      string
		volume    float64
		wantError bool
	}{
		{"valid volume", 0.5, false},
		{"zero volume", 0.0, false},
		{"max volume", 1.0, false},
		{"negative volume", -0.1, true},
		{"excessive volume", 1.1, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			device, server := setupTestServer(t, cxa.CC1)
			defer server.close()

			err := device.SetVolume(tt.volume)
			if (err != nil) != tt.wantError {
				t.Errorf("SetVolume() error = %v, wantError %v", err, tt.wantError)
			}

			if !tt.wantError {
				server.read()
				if server.data == nil {
					t.Error("Failed to read data from connection")
				} else if len(server.data) != 20 { // 5 uint32 values
					t.Errorf("Unexpected data length, got %d, want 20", len(server.data))
				}
			}
		})
	}
}

func TestSetInput(t *testing.T) {
	tests := []struct {
		name      string
		ctrlType  cxa.ControllerType
		input     int
		wantError bool
		maxInputs int
	}{
		{"CC1 invalid input", cxa.CC1, 2, true, 1},
		{"CC2 valid input 1", cxa.CC2, 1, false, 2},
		{"CC2 valid input 2", cxa.CC2, 2, false, 2},
		{"CC2 invalid input", cxa.CC2, 3, true, 2},
		{"CC3 valid input 1", cxa.CC3, 1, false, 4},
		{"CC3 valid input 4", cxa.CC3, 4, false, 4},
		{"CC3 invalid input", cxa.CC3, 5, true, 4},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			device, server := setupTestServer(t, tt.ctrlType)
			defer server.close()

			err := device.SetInput(tt.input)
			if (err != nil) != tt.wantError {
				t.Errorf("SetInput() error = %v, wantError %v", err, tt.wantError)
			}

			if !tt.wantError {
				server.read()
				if server.data == nil {
					t.Error("Failed to read data from connection")
				} else if len(server.data) != 20 { // 5 uint32 values
					t.Errorf("Unexpected data length, got %d, want 20", len(server.data))
				}
			}
		})
	}
}

func TestAnalogValues(t *testing.T) {
	tests := []struct {
		name      string
		ctrlType  cxa.ControllerType
		position  int
		volume    float64
		input     int
		checkFunc func([]byte) error
	}{
		{
			name:     "CC1 Volume Test",
			ctrlType: cxa.CC1,
			position: 1,
			volume:   0.5,
			checkFunc: func(data []byte) error {
				value := binary.BigEndian.Uint32(data[0:4])
				expectedMin := uint32(cxa.REMOTE_CC1_MIN_VOLUME)
				expectedMax := uint32(cxa.REMOTE_CC1_MAX_VOLUME)
				if value < expectedMin || value > expectedMax {
					t.Errorf("CC1 volume out of range, got %d, want between %d and %d", value, expectedMin, expectedMax)
				}
				return nil
			},
		},
		{
			name:     "CC2 Volume Test Position 1",
			ctrlType: cxa.CC2,
			position: 1,
			volume:   0.5,
			input:    1,
			checkFunc: func(data []byte) error {
				value := binary.BigEndian.Uint32(data[0:4])
				expectedMin := uint32(cxa.REMOTE_CC2_MIN_VOLUME)
				expectedMax := uint32(cxa.REMOTE_CC2_MAX_VOLUME_A)
				if value < expectedMin || value > expectedMax {
					t.Errorf("CC2 volume out of range, got %d, want between %d and %d", value, expectedMin, expectedMax)
				}
				return nil
			},
		},
		{
			name:     "CC3 Volume Test",
			ctrlType: cxa.CC3,
			position: 1,
			volume:   0.5,
			input:    1,
			checkFunc: func(data []byte) error {
				value := binary.BigEndian.Uint32(data[0:4])
				expectedMin := uint32(cxa.REMOTE_CC3_MAX_VOLUME)
				expectedMax := uint32(cxa.REMOTE_CC3_MIN_VOLUME)
				if value < expectedMin || value > expectedMax {
					t.Errorf("CC3 volume out of range, got %d, want between %d and %d", value, expectedMin, expectedMax)
				}
				return nil
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			device, server := setupTestServer(t, tt.ctrlType)
			defer server.close()

			// Set initial volume and input
			device.SetVolume(tt.volume)
			if tt.input > 0 {
				device.SetInput(tt.input)
			}

			server.read()
			if server.data == nil {
				t.Error("Failed to read data from connection")
				return
			}
			if len(server.data) != 20 {
				t.Errorf("Unexpected data length, got %d, want 20", len(server.data))
				return
			}

			if err := tt.checkFunc(server.data); err != nil {
				t.Error(err)
			}
		})
	}
}
