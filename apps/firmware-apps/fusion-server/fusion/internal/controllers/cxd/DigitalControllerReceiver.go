package cxd

import (
	"fmt"
	"fusion/internal/logging"
	"fusion/internal/server/handler"
	"strconv"
	"strings"
)

type DigitalControllerReceiver struct {
	manager *Manager
	logger  *logging.Logger
}

func NewDigitalControllerReceiver(handler *handler.Handler, listenAddr string) (*DigitalControllerReceiver, error) {
	logger := logging.GetLogger()
	logger.Debug("Creating new DigitalControllerReceiver with listenAddr: %s", listenAddr)

	manager, err := NewManager()
	if err != nil {
		logger.Error("Failed to create manager: %v", err)
		return nil, err
	}

	port, err := getPortFromAddress(listenAddr)
	if err != nil {
		logger.Error("Failed to parse port from address: %v", err)
		manager.Close()
		return nil, err
	}

	// Create a default device and add it to the manager
	defaultDevice := NewDevice()
	defaultDevice.ModelID = "DEFAULT"
	defaultDevice.Name = "Default Device"
	defaultDevice.Port = uint16(port)
	deviceID := fmt.Sprintf("%x", defaultDevice.HardwareID) // Use proper hardware ID format

	logger.Debug("Creating default device with ID: %s", deviceID)
	if err := manager.AddDevice(defaultDevice); err != nil {
		logger.Error("Failed to add default device: %v", err)
		manager.Close()
		return nil, err
	}

	logger.Debug("Setting up TCP listener for device %s on port %d", deviceID, port)
	if err := manager.Listen(deviceID, port); err != nil {
		logger.Error("Failed to set up TCP listener: %v", err)
		// Log error but continue
		logger.Warn("Digital controller listener not available")
	}

	receiver := &DigitalControllerReceiver{
		manager: manager,
		logger:  logger,
	}

	logger.Debug("DigitalControllerReceiver initialized successfully")
	return receiver, nil
}

func (r *DigitalControllerReceiver) Close() {
	r.logger.Debug("Closing DigitalControllerReceiver")
	if r.manager != nil {
		r.manager.Close()
	}
}

// Helper function to extract port number from address string
func getPortFromAddress(addr string) (int, error) {
	parts := strings.Split(addr, ":")
	if len(parts) != 2 {
		return 0, fmt.Errorf("invalid address format: %s", addr)
	}

	return strconv.Atoi(parts[1])
}
