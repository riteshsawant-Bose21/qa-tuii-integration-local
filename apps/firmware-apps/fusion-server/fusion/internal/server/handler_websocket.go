package server

import (
	"encoding/json"
	"fmt"
)

func (h *Handler) HandleWebSocketMessage(data []byte) (*WebSocketResponse, error) {
	var msg WebSocketMessage
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, fmt.Errorf("invalid WebSocket message: %w", err)
	}

	switch msg.Type {
	case "update":
		var updateData map[string]any
		if err := json.Unmarshal(msg.Data, &updateData); err != nil {
			return nil, fmt.Errorf("invalid update in WebSocket message: %w", err)
		}
		if err := h.handleConfigUpdate(updateData); err != nil {
			return nil, fmt.Errorf("failed to handle update: %w", err)
		}
		return &WebSocketResponse{
			Type:    "update_success",
			Status:  "success",
			Message: "Update applied successfully",
		}, nil

	default:
		return nil, fmt.Errorf("unknown WebSocket message type: %s", msg.Type)
	}
}
