package server

// Broadcaster defines an interface for components that can broadcast updates
type Broadcaster interface {
	BroadcastUpdate(map[string]any) error
}
