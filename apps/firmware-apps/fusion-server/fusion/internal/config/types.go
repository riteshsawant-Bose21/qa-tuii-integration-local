package config

import (
	"encoding/json"
)

// Response represents a UDP server response
type UDPResponse struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
}

// WebSocketMessage represents an incoming websocket message
type WebSocketMessage struct {
	Type string          `json:"type"`
	Data json.RawMessage `json:"data,omitempty"`
}

// WebSocketResponse represents a websocket response
type WebSocketResponse struct {
	Type    string      `json:"type"`
	Status  string      `json:"status,omitempty"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}
