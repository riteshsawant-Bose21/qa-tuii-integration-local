package cxa

import "fusion/internal/server"

type AnalogControllerReceiver struct {
	manager *AnalogControllerManager
}

func NewAnalogControllerReceiver(handler *server.Handler, listenAddr string) (*AnalogControllerReceiver, error) {
	manager, err := NewAnalogControllerManager(handler, listenAddr)
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
