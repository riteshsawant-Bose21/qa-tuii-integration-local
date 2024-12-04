package cxa

import (
	"encoding/binary"
	"fmt"
	"fusion/internal/config"
	"fusion/internal/logging"
	"net"
	"sync"
	"time"
)

// AnalogControllerConnection represents a connected device and its current state
type AnalogControllerConnection struct {
	deviceID  string
	conn      net.Conn
	values    [5]uint32
	ctrlType  ControllerType
	valueLock sync.RWMutex
}

// AnalogControllerManager handles connections from CxA devices and manages their state
type AnalogControllerManager struct {
	nodeName   string
	handler    *config.ConfigHandler
	devices    map[string]*AnalogControllerConnection
	deviceLock sync.RWMutex
	listener   net.Listener
}

// detectControllerType determines the controller type based on voltage patterns
func detectControllerType(values []uint32) ControllerType {
	if len(values) < 5 {
		return CC1 // Default to CC1 if we don't have enough data
	}

	// Check for CC2 first
	// CC2 must be in position 1 or 2 and uses REMOTE_CC2_SEL_VOLUME_B (3500)
	// on channel 3 (position 1) or channel 4 (position 2)
	if values[3] == REMOTE_CC2_SEL_VOLUME_B || values[4] == REMOTE_CC2_SEL_VOLUME_B {
		return CC2
	}

	// Check for CC3 - must be in position 1
	// Volume on channel 0 between CC3_MAX (5) and CC3_MIN (1937)
	// One input line (1-4) must be below CC3_SEL_INPUT (3650)
	if values[0] <= REMOTE_CC3_MIN_VOLUME {
		for i := 1; i <= 4; i++ {
			if values[i] < REMOTE_CC3_SEL_INPUT {
				return CC3
			}
		}
	}

	// Default to CC1 - simple volume control between 70-2450
	return CC1
}

func NewAnalogControllerManager(nodeName string, handler *config.ConfigHandler, listenAddr string) (*AnalogControllerManager, error) {
	listener, err := net.Listen("tcp", listenAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to start device listener: %v", err)
	}

	dm := &AnalogControllerManager{
		nodeName: nodeName,
		handler:  handler,
		devices:  make(map[string]*AnalogControllerConnection),
		listener: listener,
	}

	go dm.acceptConnections()
	return dm, nil
}

func (dm *AnalogControllerManager) acceptConnections() {
	logger := logging.GetLogger(dm.nodeName)
	for {
		conn, err := dm.listener.Accept()
		if err != nil {
			logger.Error("Failed to accept device connection: %v", err)
			continue
		}

		deviceID := fmt.Sprintf("device.%s", conn.RemoteAddr().String())
		dc := &AnalogControllerConnection{
			deviceID: deviceID,
			conn:     conn,
			ctrlType: CC1, // Initial type, will be updated after first reading
		}

		dm.deviceLock.Lock()
		dm.devices[deviceID] = dc
		dm.deviceLock.Unlock()

		update := map[string]interface{}{
			fmt.Sprintf("%s.connected", deviceID):     true,
			fmt.Sprintf("%s.lastConnected", deviceID): time.Now().UTC(),
		}

		if _, err := dm.handler.HandleHTTPSet(update); err != nil {
			logger.Error("Failed to broadcast device connection: %v", err)
		}

		logger.Debug("AnalogControllerManager acceptConnections: %v", update)

		go dm.handleDeviceConnection(dc)
	}
}

func (dm *AnalogControllerManager) handleDeviceConnection(dc *AnalogControllerConnection) {
	logger := logging.GetLogger(dm.nodeName)
	defer func() {
		dc.conn.Close()
		dm.deviceLock.Lock()
		delete(dm.devices, dc.deviceID)
		dm.deviceLock.Unlock()

		update := map[string]interface{}{
			fmt.Sprintf("%s.connected", dc.deviceID):        false,
			fmt.Sprintf("%s.lastDisconnected", dc.deviceID): time.Now().UTC(),
		}

		logger.Debug("AnalogControllerManager handleDeviceConnection: %v", update)
	}()

	buf := make([]byte, 20) // 5 uint32 values
	firstRead := true
	for {
		_, err := dc.conn.Read(buf)
		if err != nil {
			logger.Error("Error reading from device %s: %v", dc.deviceID, err)
			return
		}

		// Process the received values
		values := make([]uint32, 5)
		for i := 0; i < 5; i++ {
			voltage := binary.BigEndian.Uint32(buf[i*4 : (i+1)*4])
			values[i] = voltage
		}

		dc.valueLock.Lock()
		if firstRead {
			dc.ctrlType = detectControllerType(values)
			logger.Debug("Device %s detected as controller type: %v", dc.deviceID, dc.ctrlType)
			firstRead = false
		}

		changed := false
		for i := 0; i < 5; i++ {
			if dc.values[i] != values[i] {
				changed = true
				dc.values[i] = values[i]
			}
		}
		dc.valueLock.Unlock()

		if changed {
			update := map[string]interface{}{
				fmt.Sprintf("%s.values", dc.deviceID):     values,
				fmt.Sprintf("%s.lastUpdate", dc.deviceID): time.Now().UTC(),
				fmt.Sprintf("%s.type", dc.deviceID):       dc.ctrlType,
			}

			// Add individual values for easier access
			for i := range values {
				update[fmt.Sprintf("%s.values%d", dc.deviceID, i)] = values[i]
			}

			normalizedValues := MapAnalogValues(values, dc.ctrlType)
			logger.Debug("Device %s state: %v", dc.deviceID, normalizedValues)
		}
	}
}

func (dm *AnalogControllerManager) GetDeviceStates() map[string]interface{} {
	dm.deviceLock.RLock()
	defer dm.deviceLock.RUnlock()

	states := make(map[string]interface{})
	for deviceID, dc := range dm.devices {
		dc.valueLock.RLock()
		deviceState := make(map[string]interface{})
		deviceState["type"] = dc.ctrlType
		for i := range dc.values {
			deviceState[fmt.Sprintf("value%d", i)] = dc.values[i]
		}
		dc.valueLock.RUnlock()
		states[deviceID] = deviceState
	}

	return states
}

func (dm *AnalogControllerManager) Close() error {
	if dm.listener != nil {
		dm.listener.Close()
	}

	dm.deviceLock.Lock()
	defer dm.deviceLock.Unlock()

	for _, dc := range dm.devices {
		dc.conn.Close()
	}
	return nil
}

func (dm *AnalogControllerManager) Listener() net.Listener {
	return dm.listener
}
