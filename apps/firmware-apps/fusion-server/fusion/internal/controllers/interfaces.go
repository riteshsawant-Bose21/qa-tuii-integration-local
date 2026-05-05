package controllers

import (
	fusionpb "fusion/internal/gen/proto/fusion"
)

// For Handler to use
type ControllerManagerInterface interface {
	// HTTP API support
	GetActiveControllers() []*fusionpb.ControllerInfo
	GetControllerByID(id string) (*fusionpb.ControllerInfo, error)

	// Wink command execution - TODO
	StartWinkCommand(controllerID string) error

	// Lifecycle
	Start() error
	Stop() error
}
