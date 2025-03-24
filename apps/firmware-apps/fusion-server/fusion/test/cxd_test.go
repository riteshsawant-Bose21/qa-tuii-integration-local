//go:build controllers

package main

import (
	"context"
	"fmt"
	"fusion/internal/controllers/cxd"
	"fusion/internal/logging"
	"net"
	"testing"
	"time"
)

func mockDevice() *cxd.Device {
	device := cxd.NewDevice()
	device.ModelID = "TEST-1"
	device.Name = "Test Device"
	device.IP = net.ParseIP("192.168.1.100")
	device.MAC = []byte{0x00, 0x11, 0x22, 0x33, 0x44, 0x55}
	device.DHCPEnabled = true
	device.StaticIP = net.ParseIP("192.168.1.100")
	device.SubnetMask = net.IPMask{255, 255, 255, 0}
	device.Gateway = net.ParseIP("192.168.1.1")
	device.FirmwareVersion = "1.0.0"
	device.HardwareID = [4]uint32{1, 2, 3, 4}
	device.OperationMode = cxd.OpModeCSP
	device.Port = 8003
	return device
}

type TestDevice struct {
	*cxd.Device
	t *testing.T
}

func NewTestDevice(t *testing.T) *TestDevice {
	return &TestDevice{
		Device: mockDevice(),
		t:      t,
	}
}

func MockManager(t *testing.T) (*cxd.Manager, string, error) {
	manager, err := cxd.NewManager()
	if err != nil {
		return nil, "", err
	}

	device := mockDevice()
	deviceID := fmt.Sprintf("%x", device.HardwareID)

	err = manager.AddDevice(device)
	if err != nil {
		manager.Close()
		return nil, "", err
	}

	return manager, deviceID, nil
}

func TestFullSystemIntegration(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test in short mode")
	}

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TestFullSystemIntegration",
		LogDir:      "/tmp/cxd_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	manager, err := cxd.NewManager()
	if err != nil {
		t.Fatalf("Failed to create manager: %v", err)
	}

	device := mockDevice()
	deviceID := fmt.Sprintf("%x", device.HardwareID)

	if err := manager.AddDevice(device); err != nil {
		t.Fatalf("Failed to add device: %v", err)
	}

	errChan := make(chan error, 1)
	done := make(chan struct{})

	go func() {
		defer close(done)

		t.Run("Connection and Control", func(t *testing.T) {
			listenDone := make(chan error, 1)

			go func() {
				listenDone <- manager.Listen(deviceID, int(device.Port))
			}()

			time.Sleep(100 * time.Millisecond)

			conn, err := net.Dial("tcp", fmt.Sprintf("localhost:%d", device.Port))
			if err != nil {
				t.Fatalf("Failed to connect: %v", err)
			}

			if err := manager.WaitForConnection(deviceID, 2*time.Second); err != nil {
				t.Fatalf("Connection wait error: %v", err)
			}

			// Clean shutdown sequence
			conn.Close()
			<-listenDone
			manager.Close()
		})
	}()

	select {
	case <-ctx.Done():
		t.Fatal("Test timed out")
	case err := <-errChan:
		if err != nil {
			t.Fatal(err)
		}
	case <-done:
	}
}

func TestDeviceValues(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TestFullSystemIntegration",
		LogDir:      "/tmp/cxd_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})

	tests := []struct {
		name      string
		param     string
		value     string
		index     string
		checkFunc func(device *cxd.Device, t *testing.T) error
	}{
		{
			name:  "Level Test",
			param: "gain",
			value: "50",
			index: "1",
			checkFunc: func(device *cxd.Device, t *testing.T) error {
				value, err := device.GetValue("gain")
				if err != nil {
					return err
				}
				if value != "50" {
					t.Errorf("Level mismatch, got %s, want 50", value)
				}
				return nil
			},
		},
		{
			name:  "Mute Test",
			param: "mute",
			value: "O",
			index: "2",
			checkFunc: func(device *cxd.Device, t *testing.T) error {
				value, err := device.GetValue("mute")
				if err != nil {
					return err
				}
				if value != "O" {
					t.Errorf("Mute state mismatch, got %s, want O", value)
				}
				return nil
			},
		},
		{
			name:  "Source Test",
			param: "source",
			value: "2",
			index: "1",
			checkFunc: func(device *cxd.Device, t *testing.T) error {
				value, err := device.GetValue("source")
				if err != nil {
					return err
				}
				if value != "2" {
					t.Errorf("Source mismatch, got %s, want 2", value)
				}
				return nil
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			manager, deviceID, err := MockManager(t)
			if err != nil {
				t.Fatalf("Failed to create mock manager: %v", err)
			}
			defer manager.Close()

			errChan := make(chan error, 1)
			go func() {
				errChan <- manager.Listen(deviceID, 8003)
			}()

			time.Sleep(100 * time.Millisecond)

			conn, err := net.Dial("tcp", "localhost:8003")
			if err != nil {
				t.Fatalf("Failed to connect client: %v", err)
			}
			defer conn.Close()

			err = manager.WaitForConnection(deviceID, 2*time.Second)
			if err != nil {
				t.Fatalf("Connection timeout: %v", err)
			}

			err = manager.SetParam(deviceID, tt.param, tt.index, tt.value)
			if err != nil {
				t.Fatalf("Failed to set parameter: %v", err)
			}

			device, err := manager.Device(deviceID)
			if err != nil {
				t.Fatalf("Failed to get device: %v", err)
			}

			if err := tt.checkFunc(device, t); err != nil {
				t.Error(err)
			}
		})
	}
}

func TestManagerControl(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TestFullSystemIntegration",
		LogDir:      "/tmp/cxd_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})

	manager, deviceID, err := MockManager(t)
	if err != nil {
		t.Fatalf("Failed to create mock manager: %v", err)
	}
	defer manager.Close()

	errChan := make(chan error, 1)
	go func() {
		errChan <- manager.Listen(deviceID, 8003)
	}()

	time.Sleep(100 * time.Millisecond)
	conn, err := net.Dial("tcp", "localhost:8003")
	if err != nil {
		t.Fatalf("Failed to connect: %v", err)
	}
	defer conn.Close()

	// Wait for connection to establish
	if err := manager.WaitForConnection(deviceID, 2*time.Second); err != nil {
		t.Fatalf("Connection timeout: %v", err)
	}

	tests := []struct {
		name string
		test func(t *testing.T)
	}{
		{
			name: "Level Control",
			test: func(t *testing.T) {
				if err := manager.SetLevel(deviceID, "50"); err != nil {
					t.Errorf("SetLevel failed: %v", err)
				}
				level, err := manager.GetLevel(deviceID)
				if err != nil || level != "50" {
					t.Errorf("GetLevel got %s, want 50", level)
				}
			},
		},
		{
			name: "Mute Control",
			test: func(t *testing.T) {
				if err := manager.Mute(deviceID); err != nil {
					t.Errorf("Mute failed: %v", err)
				}
				muted, err := manager.IsMuted(deviceID)
				if err != nil || !muted {
					t.Errorf("IsMuted got %v, want true", muted)
				}
			},
		},
		{
			name: "Source Selection",
			test: func(t *testing.T) {
				if err := manager.Select(deviceID, "2"); err != nil {
					t.Errorf("Select failed: %v", err)
				}
				source, err := manager.GetSource(deviceID)
				if err != nil || source != "2" {
					t.Errorf("GetSource got %s, want 2", source)
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tt.test(t)
		})
	}
}
