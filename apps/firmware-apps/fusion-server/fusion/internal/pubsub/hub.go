package pubsub

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/cluster/transport"
	"fusion/internal/logging"
	"fusion/internal/persistence"
)

type Broadcaster interface {
	BroadcastMessage(msg *api.NotifyMessage) error
}

type LocalBroadcaster func(*api.NotifyMessage)

type Hub struct {
	broadcasters []Broadcaster
	stateManager *persistence.StateManager
	persistence  *persistence.Persistence
	transport    transport.ClusterTransport
}

func NewHub(stateManager *persistence.StateManager, persistence *persistence.Persistence) *Hub {
	return &Hub{
		stateManager: stateManager,
		persistence:  persistence,
	}
}

// SetClusterTransport injects the cluster transport (backed by memberlist).
// This is called once during app wiring after memberlist is constructed.
func (h *Hub) SetClusterTransport(t transport.ClusterTransport) {
	h.transport = t
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

	logger := logging.GetLogger()

	logger.Debug("Hub::BroadcastToNodes: %v", message)

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

		if h.transport == nil || h.transport.LocalNode() == nil {
			return fmt.Errorf("cluster transport not configured")
		}
		localNode := h.transport.LocalNode().Name

		if message.Node != localNode {
			// Handle remote update
			dirty, err = h.stateManager.ApplyUpdate(*message.ConfigUpdate)
			if err != nil {
				return fmt.Errorf("failed to apply remote update: %w", err)
			}
			if !dirty {
				logger.Debug(
					"broadcastMessage: skipping stale ConfigUpdate version=%v from node=%s",
					message.ConfigUpdate.Version,
					message.Node,
				)
				return nil
			}
		} else {
			// Local update: We already applied it before calling BroadcastToNodes
			dirty = true
		}

		// Overwrite with effective local Lamport version
		updated := *message.ConfigUpdate
		updated.Version = h.stateManager.GetVersion()
		logger.Debug("BroadcastToNodes::NotifyOpConfigUpdate setting Version: %d", updated.Version.Counter)
		message.ConfigUpdate = &updated

		h.persistence.MarkDirty()

	case api.NotifyOpSnapActivate:
		if message.SnapshotOperation == nil || message.SnapshotOperation.Name == "" {
			return fmt.Errorf("SnapshotOperation with valid name required for snap activate")
		}

		logging.GetLogger().Debug("[Hub] SnapActivate on %s for %s (origin=%s)",
			h.transport.LocalNode().Name,
			message.SnapshotOperation.Name,
			message.Node,
		)

		if err := h.persistence.ActivateSnapshot(message.SnapshotOperation.Name); err != nil {
			return fmt.Errorf("error activating snapshot: %v", err)
		}

	case api.NotifyOpSnapCreate:
		if err := h.persistence.CreateSnapshot(message.SnapshotOperation.Name); err != nil {
			return fmt.Errorf("error creating snapshot: %v", err)
		}

	case api.NotifyOpSnapDelete:
		if err := h.persistence.DeleteSnapshot(message.SnapshotOperation.Name); err != nil {
			return fmt.Errorf("error deleting snapshot: %v", err)
		}

	default:
		return fmt.Errorf("unknown operation type: %s", message.Operation)
	}

	// Broadcast the message to other nodes if this is the origin node.
	if h.transport == nil || h.transport.LocalNode() == nil {
		return fmt.Errorf("cluster transport not configured")
	}

	localNode := h.transport.LocalNode().Name
	logger.Debug("Hub::BroadcastToNodes: messageNode (%s) localNode (%s), ", message.Node, localNode)

	if message.Node == localNode {
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

	if h.transport == nil || h.transport.LocalNode() == nil {
		logger.Error("cluster transport not configured; cannot broadcast to nodes")
		return
	}

	localName := h.transport.LocalNode().Name

	for _, node := range h.transport.Members() {
		if node.Name == localName {
			continue
		}
		if err := h.transport.SendReliable(node, message); err != nil {
			logger.Error("Failed to send message to node %s: %v", node.Name, err)
		}
	}
}
