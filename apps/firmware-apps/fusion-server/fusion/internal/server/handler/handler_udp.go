package handler

import (
	"fmt"

	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/api"
)

// HandleUDPMessage handles and decodes UDP messages
func (h *Handler) HandleUDPMessage(data []byte) (any, error) {
	type statusResponse struct {
		Status string `json:"status"`
	}
	type statusWithMessageResponse struct {
		Status  string `json:"status"`
		Message string `json:"message"`
	}
	type getStateResponse struct {
		Status string         `json:"status"`
		Data   map[string]any `json:"data"`
	}

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
		return statusResponse{Status: "ok"}, nil

	case api.NotifyOpValueGet:
		state := h.StateManager.GetStateMap()
		state[api.FusionVersion] = h.StateManager.GetVersion().Counter
		state[api.FusionEpoch] = h.StateManager.GetVersion().Epoch
		return getStateResponse{
			Status: "success",
			Data:   state,
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
		return statusWithMessageResponse{
			Status:  "success",
			Message: "Update applied successfully",
		}, nil

	// 			return map[string]any{
	// 		"status":            "success",
	// 		"message":           "Update applied successfully",
	// 		api.FusionOperation: api.NotifyOpValueSet,
	// 	}, nil
	// case api.NotifyOpGetDeviceInformation:
	// 	info, err := h.HandleGetDeviceInfo()
	// 	if err != nil {
	// 		logger.Error("HandleUDPMessage GetDeviceInfo error: %v", err)
	// 		return nil, fmt.Errorf("failed to get device info: %w", err)
	// 	}

	// 	return map[string]any{
	// 		"status":            "success",
	// 		"deviceInfo":        info,
	// 		api.FusionOperation: api.NotifyOpGetDeviceInformation,
	default:
		logger.Warn("HandleUDPMessage unknown action: %s", msg.Action)
		return nil, fmt.Errorf("unknown action: %s", msg.Action)
	}
}
