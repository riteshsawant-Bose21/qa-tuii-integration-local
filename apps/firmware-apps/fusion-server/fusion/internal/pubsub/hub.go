package pubsub

import (
	"fusion/internal/api"
	"fusion/internal/logging"
)

type Broadcaster interface {
	BroadcastMessage(msg *api.NotifyMessage) error
}

type LocalBroadcaster func(*api.NotifyMessage)

type Hub struct {
	broadcasters []Broadcaster
}

func NewHub(bs ...Broadcaster) *Hub {
	return &Hub{broadcasters: bs}
}

func (h *Hub) Register(b Broadcaster) {
	h.broadcasters = append(h.broadcasters, b)
}

func (h *Hub) Broadcast(msg *api.NotifyMessage) {

	for _, bc := range h.broadcasters {
		if err := bc.BroadcastMessage(msg); err != nil {
			logging.GetLogger().Error("local broadcast failed: %v", err)
		}
	}
}
