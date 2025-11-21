package handler

import (
	"fmt"

	json "github.com/goccy/go-json"
)

// WebSocketMessage represents an incoming websocket message
type WebSocketMessage struct {
	Type string          `json:"type"`
	Data json.RawMessage `json:"data,omitempty"`
}

// WebSocketResponse represents a websocket response
type WebSocketResponse struct {
	Type    string `json:"type"`
	Status  string `json:"status,omitempty"`
	Message string `json:"message,omitempty"`
	Data    any    `json:"data,omitempty"`
}

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
		if err := h.handleConfigUpdate(updateData, false); err != nil {
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
