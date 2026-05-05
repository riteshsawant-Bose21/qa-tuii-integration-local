package controllers

import (
	model "fusion/internal/gen/proto/fusion"
)

// For Handler to use
type ControllerManagerInterface interface {
	// HTTP API support
	GetActiveControllers() []*model.ControllerInfo
	GetControllerByID(id string) (*model.ControllerInfo, error)

	// Wink command execution - TODO
	StartWinkCommand(controllerID string) error

	// Lifecycle
	Start() error
	Stop() error
}
