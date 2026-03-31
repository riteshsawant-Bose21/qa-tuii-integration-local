package handler

import (
	"fmt"

	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/api"
)

// HandleUDPMessage handles and decodes UDP messages
func (h *Handler) HandleUDPMessage(data []byte) (any, error) {
	type udpResponse struct {
		FusionOp api.NotifyOp `json:"_fusion_op"`
		Status   string       `json:"status"`
		Payload  any          `json:"payload,omitempty"`
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
		return udpResponse{FusionOp: msg.Action, Status: "ok"}, nil

	case api.NotifyOpValueGet:
		state := h.StateManager.GetStateMap()
		state[api.FusionVersion] = h.StateManager.GetVersion().Counter
		state[api.FusionEpoch] = h.StateManager.GetVersion().Epoch
		return udpResponse{
			FusionOp: msg.Action,
			Status:   "success",
			Payload:  state,
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
		return udpResponse{
			FusionOp: msg.Action,
			Status:   "success",
		}, nil

	case api.NotifyOpGetLocalDeviceInformation:
		info := h.HandleGetDeviceInfo()

		return udpResponse{
			FusionOp: msg.Action,
			Status:   "success",
			Payload:  info,
		}, nil

	default:
		logger.Warn("HandleUDPMessage unknown action: %s", msg.Action)
		return nil, fmt.Errorf("unknown action: %s", msg.Action)
	}
}
