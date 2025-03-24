package server

import (
	"encoding/json"
	"fmt"
)

// UDP Server methods
func (h *Handler) HandleUDPMessage(data []byte) (any, error) {
	var msg struct {
		Action string          `json:"action"`
		Raw    json.RawMessage `json:",omitempty"`
	}

	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid JSON: %w", err)
	}

	switch msg.Action {
	case "get":
		fullState := h.stateManager.GetFullState()
		transformed := TransformState(fullState)
		return map[string]any{
			"status": "success",
			"data":   transformed,
		}, nil

	case "set":
		var update map[string]any
		if err := json.Unmarshal(data, &update); err != nil {
			return nil, fmt.Errorf("invalid JSON: %w", err)
		}
		delete(update, "action")
		if err := h.handleConfigUpdate(update); err != nil {
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
