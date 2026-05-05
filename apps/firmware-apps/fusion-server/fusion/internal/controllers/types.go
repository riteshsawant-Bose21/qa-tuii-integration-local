package controllers

import (
	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/pubsub"
	"net"
	"sync"
	"time"

	json "github.com/goccy/go-json"
)

// ControllerConnection tracks a connected controller and its identity state.
type ControllerConnection struct {
	Connection   net.Conn
	ConnectedAt  time.Time
	LastActivity time.Time
	IsIdentified bool
	Info         *fusionpb.ControllerInfo
}

// ControllerManager manages connected wall controllers over TCP.
type ControllerManager struct {
	hub         *pubsub.Hub
	tcpServer   *WallControllerTCPServer
	controllers map[string]*ControllerConnection
	mutex       sync.RWMutex
}

// TCPMessage is the internal controller TCP protocol envelope.
type TCPMessage struct {
	Action  string          `json:"action"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

// IdentifyResponse is the controller TCP identify payload.
type IdentifyResponse struct {
	ID              string `json:"id"`
	DeviceType      string `json:"deviceType"`
	SoftwareVersion string `json:"softwareVersion"`
}
