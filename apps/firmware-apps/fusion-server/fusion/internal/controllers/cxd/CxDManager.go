package cxd

import (
	"encoding/json"
	"fmt"
	"fusion/internal/logging"
	"os"
	"sync"
	"time"
)

// Manager coordinates UDP and TCP communication with devices
type Manager struct {
	devices map[string]*Device
	comms   map[string]*TCPController
	udpComm *Controller
	mutex   sync.RWMutex
}

// NewManager creates a new device manager
func NewManager() (*Manager, error) {
	udpComm, err := NewController()
	if err != nil {
		return nil, fmt.Errorf("failed to create UDP controller: %w", err)
	}

	return &Manager{
		devices: make(map[string]*Device),
		comms:   make(map[string]*TCPController),
		udpComm: udpComm,
	}, nil
}

// Close closes all connections
func (m *Manager) Close() error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	for _, comm := range m.comms {
		comm.Close()
	}
	return m.udpComm.Close()
}

// Devices returns all known devices
func (m *Manager) Devices() map[string]*Device {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	devices := make(map[string]*Device)
	for id, device := range m.devices {
		devices[id] = device
	}
	return devices
}

// Device returns a specific device
func (m *Manager) Device(deviceID string) (*Device, error) {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	device, exists := m.devices[deviceID]
	if !exists {
		return nil, &DeviceError{
			Code:    ErrInvalidDevice,
			Message: fmt.Sprintf("device %s not found", deviceID),
		}
	}
	return device, nil
}

// AddDevice adds or updates a device
func (m *Manager) AddDevice(device *Device) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	deviceID := fmt.Sprintf("%x", device.HardwareID)
	m.devices[deviceID] = device
	return nil
}

// Discover initiates device discovery
func (m *Manager) Discover() error {
	devices, err := m.udpComm.Discover()
	if err != nil {
		return err
	}

	m.mutex.Lock()
	defer m.mutex.Unlock()

	for _, device := range devices {
		deviceID := fmt.Sprintf("%x", device.HardwareID)
		m.devices[deviceID] = device
	}

	return nil
}

// Listen starts TCP communication
func (m *Manager) Listen(deviceID string, port int) error {
	logger := logging.GetLogger()
	logger.Debug("Manager.Listen called for device %s on port %d", deviceID, port)

	m.mutex.Lock()
	defer m.mutex.Unlock()

	device, exists := m.devices[deviceID]
	if !exists {
		logger.Error("Device %s not found in devices map", deviceID)
		return &DeviceError{
			Code:    ErrInvalidDevice,
			Message: fmt.Sprintf("device %s not found", deviceID),
		}
	}
	logger.Debug("Found device: %+v", device)

	if _, exists := m.comms[deviceID]; exists {
		logger.Error("Device %s already has a TCP controller", deviceID)
		return &DeviceError{
			Code:    ErrAlreadyConnected,
			Message: fmt.Sprintf("device %s already connected", deviceID),
		}
	}

	logger.Debug("Creating new TCP controller for device %s", deviceID)
	comm, err := NewTCPController(deviceID, port)
	if err != nil {
		logger.Error("Failed to create TCP controller: %v", err)
		return fmt.Errorf("failed to create TCP controller: %w", err)
	}

	logger.Debug("TCP controller created successfully, storing in comms map")
	m.comms[deviceID] = comm
	return nil
}

// Disconnect stops TCP communication
func (m *Manager) Disconnect(deviceID string) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	comm, exists := m.comms[deviceID]
	if !exists {
		return nil
	}

	delete(m.comms, deviceID)
	return comm.Close()
}

// Add these methods to the Manager struct in manager.go:

// SetParam sets a parameter value for a device
func (m *Manager) SetParam(deviceID string, param, index, value string) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()

	device, exists := m.devices[deviceID]
	if !exists {
		return &DeviceError{
			Code:    ErrInvalidDevice,
			Message: fmt.Sprintf("device %s not found", deviceID),
		}
	}

	comm, exists := m.comms[deviceID]
	if !exists {
		return &DeviceError{
			Code:    ErrNotConnected,
			Message: fmt.Sprintf("device %s not connected", deviceID),
		}
	}

	// Update device state
	device.SetValue(param, value)

	// Send to device
	return comm.Send(param, index, value)
}

// GetParam gets a parameter value from a device
func (m *Manager) GetParam(deviceID string, param string) (string, error) {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	device, exists := m.devices[deviceID]
	if !exists {
		return "", &DeviceError{
			Code:    ErrInvalidDevice,
			Message: fmt.Sprintf("device %s not found", deviceID),
		}
	}

	return device.GetValue(param)
}

// SetParamWithoutIndex sets a parameter value without an index
func (m *Manager) SetParamWithoutIndex(deviceID string, param, value string) error {
	return m.SetParam(deviceID, param, "", value)
}

// SubscribeParam subscribes to parameter changes
func (m *Manager) SubscribeParam(deviceID string, param string, callback func(string)) error {
	m.mutex.RLock()
	defer m.mutex.RUnlock()

	comm, exists := m.comms[deviceID]
	if !exists {
		return &DeviceError{
			Code:    ErrNotConnected,
			Message: fmt.Sprintf("device %s not connected", deviceID),
		}
	}

	return comm.Subscribe(param, func(value string) {
		// Update device state when parameter changes
		if device, exists := m.devices[deviceID]; exists {
			device.SetValue(param, value)
		}
		callback(value)
	})
}

// Parameter control methods

func (m *Manager) SetLevel(deviceID string, value string) error {
	return m.SetParam(deviceID, "gain", "1", value)
}

func (m *Manager) Mute(deviceID string) error {
	return m.SetParam(deviceID, "mute", "2", "O")
}

func (m *Manager) Unmute(deviceID string) error {
	return m.SetParam(deviceID, "mute", "2", "F")
}

func (m *Manager) Select(deviceID string, value string) error {
	return m.SetParam(deviceID, "source", "1", value)
}

func (m *Manager) GetLevel(deviceID string) (string, error) {
	return m.GetParam(deviceID, "gain")
}

func (m *Manager) IsMuted(deviceID string) (bool, error) {
	value, err := m.GetParam(deviceID, "mute")
	if err != nil {
		return false, err
	}
	return value == "O", nil
}

func (m *Manager) GetSource(deviceID string) (string, error) {
	return m.GetParam(deviceID, "source")
}

// Configuration methods

func (m *Manager) SetConfig(deviceID string, cfg *Config) error {
	device, err := m.Device(deviceID)
	if err != nil {
		return err
	}

	if err := device.LoadConfig(cfg); err != nil {
		return err
	}

	return m.udpComm.SetStaticIP(device, cfg.IP, cfg.SubnetMask, cfg.Gateway)
}

func (m *Manager) SaveConfig(deviceID string, filename string) error {
	device, err := m.Device(deviceID)
	if err != nil {
		return err
	}

	cfg := device.ToConfig()
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(filename, data, 0644)
}

func (m *Manager) LoadConfig(deviceID string, filename string) error {
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	var cfg Config
	if err := json.Unmarshal(data, &cfg); err != nil {
		return err
	}

	return m.SetConfig(deviceID, &cfg)
}

// Utility methods

func (m *Manager) WaitForConnection(deviceID string, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		m.mutex.RLock()
		comm, exists := m.comms[deviceID]
		m.mutex.RUnlock()

		if exists && comm.IsConnected() {
			return nil
		}
		time.Sleep(100 * time.Millisecond)
	}

	return &DeviceError{
		Code:    ErrTimeout,
		Message: "connection timeout",
	}
}
