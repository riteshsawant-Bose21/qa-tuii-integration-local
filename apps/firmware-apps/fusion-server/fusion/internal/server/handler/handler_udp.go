package handler

import (
	"fmt"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
	"fusion/internal/logging"
)

// HandleUDPMessage handles and decodes UDP messages
func (h *Handler) HandleUDPMessage(data []byte) (any, error) {
	var msg struct {
		Action  api.NotifyOp    `json:"action"`
		Payload json.RawMessage `json:"payload,omitempty"`
	}

	logger := logging.GetLogger()

	if err := json.Unmarshal(data, &msg); err != nil {
		logger.Error("HandleUDPMessage error: %v", err)
		return nil, fmt.Errorf("invalid JSON: %w", err)
	}

	switch msg.Action {
	case api.NotifyOpNoop:
		// For profiling: no state change, no broadcast, no gossip.
		return map[string]any{
			"status": "ok",
		}, nil

	case api.NotifyOpValueGet:
		state := h.StateManager.GetStateMap()
		state[api.FusionVersion] = h.StateManager.GetVersion().Counter
		return map[string]any{
			"status": "success",
			"data":   state,
		}, nil

	case api.NotifyOpValueSet:
		var update map[string]any
		if err := json.Unmarshal(msg.Payload, &update); err != nil {
			logger.Error("HandleUDPMessage NotifyOpValueSet error: %v", err)
			return nil, fmt.Errorf("invalid payload: %w", err)
		}
		delete(update, "action")
		if err := h.handleConfigUpdate(update, false); err != nil {
			logger.Error("HandleUDPMessage handleConfigUpdate error: %v", err)
			return nil, fmt.Errorf("failed to handle update: %w", err)
		}
		return map[string]any{
			"status":  "success",
			"message": "Update applied successfully",
		}, nil

	default:
		logger.Warn("HandleUDPMessage unknown action: %s", msg.Action)
		return nil, fmt.Errorf("unknown action: %s", msg.Action)
	}
}
