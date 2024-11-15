package broadcast

import (
	"fusion/internal/api"
)

// Broadcaster defines an interface for components that can broadcast updates
type Broadcaster interface {
	BroadcastUpdate(update api.ConfigUpdate) error
}
