package handler

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
)

// HandleRegisterController registers a new controller from JSON payload.
func (h *Handler) HandleRegisterController(data map[string]any) (*api.ControllerInfo, error) {
	var ctrl api.ControllerInfo
	if err := mapToStruct(data, &ctrl); err != nil {
		return nil, fmt.Errorf("invalid controller data: %w", err)
	}

	if ctrl.ID == "" {
		return nil, fmt.Errorf("controller ID is required")
	}

	if err := h.RegisterController(&ctrl); err != nil {
		return nil, err
	}

	return &ctrl, nil
}

// HandleDeleteController unregisters a controller by ID.
func (h *Handler) HandleDeleteController(id string) error {
	return h.UnregisterController(id)
}

// HandleGetControllerByID retrieves a single controller by ID.
func (h *Handler) HandleGetControllerByID(id string) (*api.ControllerInfo, error) {
	h.controllersLock.RLock()
	defer h.controllersLock.RUnlock()

	ctrl, ok := h.controllers[id]
	if !ok {
		return nil, fmt.Errorf("controller %s not found", id)
	}
	return ctrl, nil
}

// HandleGetControllers returns a list of all registered controllers.
func (h *Handler) HandleGetControllers() []*api.ControllerInfo {
	return h.ListControllers()
}

// RegisterController adds a controller to the registry.
func (h *Handler) RegisterController(c *api.ControllerInfo) error {
	h.controllersLock.Lock()
	defer h.controllersLock.Unlock()
	if _, exists := h.controllers[c.ID]; exists {
		return fmt.Errorf("controller %s already registered", c.ID)
	}
	h.controllers[c.ID] = c
	return nil
}

// UnregisterController removes a controller from the registry.
func (h *Handler) UnregisterController(id string) error {
	h.controllersLock.Lock()
	defer h.controllersLock.Unlock()
	if _, exists := h.controllers[id]; !exists {
		return fmt.Errorf("controller %s not found", id)
	}
	delete(h.controllers, id)
	return nil
}

// ListControllers returns a slice of all registered controllers.
func (h *Handler) ListControllers() []*api.ControllerInfo {
	h.controllersLock.RLock()
	defer h.controllersLock.RUnlock()
	out := make([]*api.ControllerInfo, 0, len(h.controllers))
	for _, c := range h.controllers {
		out = append(out, c)
	}
	return out
}

// mapToStruct converts a generic map to a struct.
func mapToStruct(m map[string]any, v any) error {
	b, err := json.Marshal(m)
	if err != nil {
		return err
	}
	return json.Unmarshal(b, v)
}
