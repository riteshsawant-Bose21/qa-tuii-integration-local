package cxa

import (
	"fusion/internal/config"
)

type AnalogControllerReceiver struct {
	manager *AnalogControllerManager
}

func NewAnalogControllerReceiver(nodeName string, handler *config.ConfigHandler, listenAddr string) (*AnalogControllerReceiver, error) {
	manager, err := NewAnalogControllerManager(nodeName, handler, listenAddr)
	if err != nil {
		return nil, err
	}

	return &AnalogControllerReceiver{
		manager: manager,
	}, nil
}

func (r *AnalogControllerReceiver) GetDeviceStates() map[string]interface{} {
	return r.manager.GetDeviceStates()
}

func (r *AnalogControllerReceiver) Close() {
	r.manager.Close()
}
