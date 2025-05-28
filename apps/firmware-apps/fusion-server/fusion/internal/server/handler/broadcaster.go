package handler

import "fusion/internal/api"

// Broadcaster defines an interface for components that can broadcast updates
type Broadcaster interface {
	BroadcastUpdate(message *api.NotifyMessage) error
}
