package pubsub

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"

	"github.com/hashicorp/memberlist"
)

type Broadcaster interface {
	BroadcastMessage(msg *api.NotifyMessage) error
}

type LocalBroadcaster func(*api.NotifyMessage)

type Hub struct {
	broadcasters []Broadcaster
	stateManager *persistence.StateManager
	persistence  *persistence.Persistence
	Memberlist   *memberlist.Memberlist
}

func NewHub(stateManager *persistence.StateManager, persistence *persistence.Persistence) *Hub {
	return &Hub{
		stateManager: stateManager,
		persistence:  persistence,
	}
}

func (h *Hub) Register(b Broadcaster) {
	h.broadcasters = append(h.broadcasters, b)
}

func (h *Hub) BroadcastToObservers(msg *api.NotifyMessage) {

	for _, bc := range h.broadcasters {
		if err := bc.BroadcastMessage(msg); err != nil {
			logging.GetLogger().Error("local broadcast failed: %v", err)
		}
	}
}

// broadcastMessage processes an incoming NotifyMessage by applying configuration or snapshot updates,
// performing version changes, and then broadcasting the message to other nodes and local clients if needed.
func (h *Hub) BroadcastToNodes(message *api.NotifyMessage) error {

	switch message.Operation {

	case api.NotifyOpAudioRemove:
		if message.AudioRemove == nil {
			return fmt.Errorf("AudioRemove required for operation")
		}

	case api.NotifyOpAudioSync:
		if message.AudioSync == nil {
			return fmt.Errorf("AudioSync required for operation")
		}

		err := h.persistence.SyncAudioFile(message.AudioSync)
		if err != nil {
			return fmt.Errorf("audio sync failed: %w", err)
		}

	case api.NotifyOpConfigUpdate:

		var dirty bool
		var err error

		localNode := h.Memberlist.LocalNode().Name

		if message.Node != localNode {
			// Handle remote update
			dirty, err = h.stateManager.ApplyUpdate(*message.ConfigUpdate)
			if err != nil {
				return fmt.Errorf("failed to apply remote update: %w", err)
			}
			if !dirty {
				logging.GetLogger().Debug(
					"broadcastMessage: skipping stale ConfigUpdate version=%v from node=%s",
					message.ConfigUpdate.Version,
					message.Node,
				)
				return nil
			}
		} else {
			// Local update: We already applied it before calling broadcastMessage
			dirty = true
		}

		// Overwrite with effective local Lamport version
		updated := *message.ConfigUpdate
		updated.Version = h.stateManager.GetVersion()
		message.ConfigUpdate = &updated

		h.persistence.MarkDirty()

	case api.NotifyOpSnapActivate:
		// For snapshot activation:
		// - The origin node has already called ActivateSnapshotAndReturnState
		//   in Handler.HandleActivateSnapshot.
		// - Remote nodes will activate the snapshot in ClusterDelegate.NotifyMsg.
		//
		// Just validate the payload; no local activation.
		if message.SnapshotUpdate == nil || message.SnapshotUpdate.Name == "" {
			return fmt.Errorf("SnapshotUpdate with valid name required for snap activate")
		}

		if err := h.persistence.ActivateSnapshot(message.SnapshotUpdate.Name); err != nil {
			return fmt.Errorf("error activating snapshot: %v", err)
		}

	case api.NotifyOpSnapCreate:
		// Create a snapshot with the given name.
		if err := h.persistence.CreateSnapshot(message.SnapshotUpdate.Name); err != nil {
			return fmt.Errorf("error creating snapshot: %v", err)
		}

	case api.NotifyOpSnapDelete:
		// Delete the specified snapshot.
		if err := h.persistence.DeleteSnapshot(message.SnapshotUpdate.Name); err != nil {
			return fmt.Errorf("error deleting snapshot: %v", err)
		}

	default:
		return fmt.Errorf("unknown operation type: %s", message.Operation)
	}

	// Broadcast the message to other nodes if this is the origin node.
	if message.Node == h.Memberlist.LocalNode().Name {
		data, err := json.Marshal(message)
		if err != nil {
			return fmt.Errorf("failed to marshal update: %w", err)
		}
		h.broadcastToNodes(data)
	}

	h.BroadcastToObservers(message)

	return nil
}

func (h *Hub) broadcastToNodes(message []byte) {
	logger := logging.GetLogger()
	for _, node := range h.Memberlist.Members() {
		if node.Name == h.Memberlist.LocalNode().Name {
			continue
		}
		if err := h.Memberlist.SendReliable(node, message); err != nil {
			logger.Error("Failed to send message to node %s: %v", node.Name, err)
		}
	}
}
