package handler

import (
	"fmt"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
)

// HandleUDPMessage handles and decodes UDP messages
func (h *Handler) HandleUDPMessage(data []byte) (any, error) {
	var msg struct {
		Action  api.NotifyOp    `json:"action"`
		Payload json.RawMessage `json:"settings,omitempty"`
	}

	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid JSON: %w", err)
	}

	switch msg.Action {
	case api.NotifyOpValueGet:
		state := h.StateManager.GetStateMap()
		return map[string]any{
			"status": "success",
			"data":   state,
		}, nil

	case api.NotifyOpValueSet:
		var update map[string]any
		if err := json.Unmarshal(msg.Payload, &update); err != nil {
			return nil, fmt.Errorf("invalid payload: %w", err)
		}
		delete(update, "action")
		if err := h.handleConfigUpdate(update, false); err != nil {
			return nil, fmt.Errorf("failed to handle update: %w", err)
		}
		return map[string]any{
			"status":  "success",
			"message": "Update applied successfully",
		}, nil

	default:
		return nil, fmt.Errorf("unknown action: %s", msg.Action)
	}
}
