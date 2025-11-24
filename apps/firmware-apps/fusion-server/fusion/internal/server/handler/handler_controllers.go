package handler

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
)

func (h *Handler) HandleGetControllers() []*api.ControllerInfo {
	logger := logging.GetLogger()

	controllers := h.controllerManager.GetActiveControllers()

	for i, controller := range controllers {
		logger.Debug("  Controller %d: ID=%s, Name=%s, Version=%s", i+1, controller.ID, controller.Name, controller.Version)
	}
	return controllers
}

func (h *Handler) HandleGetControllerByID(controllerID string) (*api.ControllerInfo, error) {
	logger := logging.GetLogger()

	if controllerID == "" {
		return nil, fmt.Errorf("controller ID is required")
	}

	controller, err := h.controllerManager.GetControllerByID(controllerID)
	if err != nil {
		logger.Debug("Controller %s not found: %v", controllerID, err)
		return nil, fmt.Errorf("controller not found")
	}

	return controller, nil
}

func (h *Handler) HandleTriggerWink(controllerID string) error {
	logger := logging.GetLogger()

	if controllerID == "" {
		return fmt.Errorf("controller ID is required")
	}

	err := h.controllerManager.StartWinkCommand(controllerID)
	if err != nil {
		logger.Error("Failed to start wink command for controller %s: %v", controllerID, err)
		return fmt.Errorf("controller not found")
	}

	return nil
}
