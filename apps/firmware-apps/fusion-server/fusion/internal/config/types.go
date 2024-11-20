package config

import (
	"encoding/json"
)

// Message represents an incoming UDP message
type Message struct {
	Action string          `json:"action"`
	Update json.RawMessage `json:"update,omitempty"`
	Data   json.RawMessage `json:"data,omitempty"`
}

// Response represents a UDP server response
type Response struct {
	Status  string      `json:"status"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

// WebSocketMessage represents an incoming websocket message
type WebSocketMessage struct {
	Type    string          `json:"type"`
	Update  json.RawMessage `json:"update,omitempty"`
	Channel int             `json:"channel,omitempty"`
	Volume  float64         `json:"volume,omitempty"`
}

// WebSocketResponse represents a websocket response
type WebSocketResponse struct {
	Type    string      `json:"type"`
	Status  string      `json:"status,omitempty"`
	Message string      `json:"message,omitempty"`
	Data    interface{} `json:"data,omitempty"`
	Update  interface{} `json:"update,omitempty"`
	Version int64       `json:"version,omitempty"`
	State   interface{} `json:"state,omitempty"`
}
