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
			ctrlType: CC1, // TODO: Determine the correct controller type
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
