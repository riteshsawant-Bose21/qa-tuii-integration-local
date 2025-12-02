package controllers

import (
	"fusion/internal/api"
	"fusion/internal/pubsub"
	"net"
	"sync"
	"time"
)

type ControllerManager struct {
	// Core components
	tcpServer *WallControllerTCPServer
	hub       *pubsub.Hub

	// Controller tracking
	controllers map[string]*ControllerConnection // key: connectionID
	mutex       sync.RWMutex
}

type ControllerConnection struct {
	Info         *api.ControllerInfo
	Connection   net.Conn
	ConnectedAt  time.Time
	LastActivity time.Time
	IsIdentified bool
}
