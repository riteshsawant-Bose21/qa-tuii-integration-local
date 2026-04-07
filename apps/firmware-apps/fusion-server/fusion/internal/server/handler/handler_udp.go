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
		Key     string          `json:"key,omitempty"`
		Value   json.RawMessage `json:"value,omitempty"`
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
		response, err := h.HandleHTTPGet(msg.Key)
		if err != nil {
			logger.Error("HandleUDPMessage NotifyOpValueGet error: %v", err)
			return nil, fmt.Errorf("failed to get value: %w", err)
		}
		payload, err := attachUDPVersionMetadata(response, h.StateManager.GetVersion())
		if err != nil {
			logger.Error("HandleUDPMessage NotifyOpValueGet metadata error: %v", err)
			return nil, fmt.Errorf("failed to encode response: %w", err)
		}
		return udpResponse{
			FusionOp: msg.Action,
			Status:   "success",
			Payload:  payload,
		}, nil

	case api.NotifyOpValuePut, api.NotifyOpValueSet:
		update, err := udpPayloadMap(data, msg)
		if err != nil {
			logger.Error("HandleUDPMessage NotifyOpValuePut error: %v", err)
			return nil, fmt.Errorf("invalid payload: %w", err)
		}
		response, err := h.HandleHTTPSet(update)
		if err != nil {
			logger.Error("HandleUDPMessage NotifyOpValuePut apply error: %v", err)
			return nil, fmt.Errorf("failed to handle put: %w", err)
		}
		return udpResponse{
			FusionOp: api.NotifyOpValuePut,
			Status:   "success",
			Payload:  response,
		}, nil

	case api.NotifyOpValuePatch:
		patch, err := udpPatchMap(msg)
		if err != nil {
			logger.Error("HandleUDPMessage NotifyOpValuePatch error: %v", err)
			return nil, fmt.Errorf("invalid patch: %w", err)
		}
		diff, err := h.HandleHTTPPatch(patch)
		if err != nil {
			logger.Error("HandleUDPMessage NotifyOpValuePatch apply error: %v", err)
			return nil, fmt.Errorf("failed to handle patch: %w", err)
		}
		return udpResponse{
			FusionOp: api.NotifyOpValuePatch,
			Status:   "success",
			Payload:  diff,
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

func udpPayloadMap(data []byte, msg struct {
	Action  api.NotifyOp    `json:"action"`
	Key     string          `json:"key,omitempty"`
	Value   json.RawMessage `json:"value,omitempty"`
	Payload json.RawMessage `json:"payload,omitempty"`
}) (map[string]any, error) {
	if len(msg.Payload) > 0 {
		var update map[string]any
		if err := json.Unmarshal(msg.Payload, &update); err != nil {
			return nil, err
		}
		return update, nil
	}

	var legacy map[string]any
	if err := json.Unmarshal(data, &legacy); err != nil {
		return nil, err
	}
	delete(legacy, "action")
	delete(legacy, "key")
	delete(legacy, "value")
	delete(legacy, "payload")
	return legacy, nil
}

func udpPatchMap(msg struct {
	Action  api.NotifyOp    `json:"action"`
	Key     string          `json:"key,omitempty"`
	Value   json.RawMessage `json:"value,omitempty"`
	Payload json.RawMessage `json:"payload,omitempty"`
}) (map[string]any, error) {
	if msg.Key != "" {
		if len(msg.Value) == 0 {
			return nil, fmt.Errorf("missing value for key %q", msg.Key)
		}
		var value any
		if err := json.Unmarshal(msg.Value, &value); err != nil {
			return nil, err
		}
		return map[string]any{msg.Key: value}, nil
	}
	if len(msg.Payload) == 0 {
		return nil, fmt.Errorf("missing payload")
	}
	var patch map[string]any
	if err := json.Unmarshal(msg.Payload, &patch); err != nil {
		return nil, err
	}
	return patch, nil
}

func attachUDPVersionMetadata(response any, version api.Version) (any, error) {
	payloadMap, ok := response.(map[string]any)
	if !ok {
		data, err := json.Marshal(response)
		if err != nil {
			return nil, err
		}
		if err := json.Unmarshal(data, &payloadMap); err != nil {
			return nil, err
		}
	}
	payloadMap[api.FusionVersion] = version.Counter
	payloadMap[api.FusionEpoch] = version.Epoch
	return payloadMap, nil
}
