package handler

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
)

// UDP Server methods
func (h *Handler) HandleUDPMessage(data []byte) (any, error) {
	var msg struct {
		Action api.NotifyOp    `json:"action"`
		Raw    json.RawMessage `json:",omitempty"`
	}

	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid JSON: %w", err)
	}

	switch msg.Action {
	case api.NotifyOpValueGet:
		data := h.StateManager.GetStateMap()
		return map[string]any{
			"status": "success",
			"data":   data,
		}, nil

	case api.NotifyOpValueSet:
		var update map[string]any
		if err := json.Unmarshal(data, &update); err != nil {
			return nil, fmt.Errorf("invalid JSON: %w", err)
		}
		delete(update, "action")
		if err := h.handleConfigUpdate(update, false); err != nil {
			return nil, fmt.Errorf("failed to handle update: %w", err)
		}
		return map[string]any{
			"status":  "success",
			"message": "Update applied successfully",
		}, nil

	case api.NotifyOpControllerAdd:
		var ctrl api.ControllerInfo
		if err := json.Unmarshal(msg.Raw, &ctrl); err != nil {
			return nil, fmt.Errorf("invalid controller data: %w", err)
		}
		if err := h.RegisterController(&ctrl); err != nil {
			return nil, err
		}
		return map[string]any{"status": "success", "message": "controller registered"}, nil

	case api.NotifyOpControllerRemove:
		var payload struct {
			ID string `json:"id"`
		}
		if err := json.Unmarshal(msg.Raw, &payload); err != nil {
			return nil, fmt.Errorf("invalid controller delete request: %w", err)
		}
		if err := h.UnregisterController(payload.ID); err != nil {
			return nil, err
		}
		return map[string]any{"status": "success", "message": "controller unregistered"}, nil

	default:
		return nil, fmt.Errorf("unknown action: %s", msg.Action)
	}
}
