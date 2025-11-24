package controllers

import (
	"fusion/internal/api"
)

// For Handler to use
type ControllerManagerInterface interface {
	// HTTP API support
	GetActiveControllers() []*api.ControllerInfo
	GetControllerByID(id string) (*api.ControllerInfo, error)

	// Wink command execution - TODO
	StartWinkCommand(controllerID string) error

	// Lifecycle
	Start() error
	Stop() error
}
