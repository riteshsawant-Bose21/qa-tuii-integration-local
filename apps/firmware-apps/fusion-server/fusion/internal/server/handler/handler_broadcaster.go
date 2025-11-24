package handler

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"

	json "github.com/goccy/go-json"
)

// broadcastMessage processes an incoming NotifyMessage by applying configuration or snapshot updates,
// performing version changes, and then broadcasting the message to other nodes and local clients if needed.
func (h *Handler) broadcastMessage(message *api.NotifyMessage) error {

	switch message.Operation {

	case api.NotifyOpAudioRemove:
		if message.AudioRemove == nil {
			return fmt.Errorf("AudioRemove required for operation")
		}

	case api.NotifyOpAudioSync:
		if message.AudioSync == nil {
			return fmt.Errorf("AudioSync required for operation")
		}

		err := h.handleAudioSync(message.AudioSync)
		if err != nil {
			return fmt.Errorf("audio sync failed: %w", err)
		}

	case api.NotifyOpConfigUpdate:

		var dirty bool
		var err error

		localNode := h.memberlist.LocalNode().Name

		if message.Node != localNode {
			// Handle remote update
			dirty, err = h.StateManager.ApplyUpdate(*message.ConfigUpdate)
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
		updated.Version = h.StateManager.GetVersion()
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
	if message.Node == h.memberlist.LocalNode().Name {
		data, err := json.Marshal(message)
		if err != nil {
			return fmt.Errorf("failed to marshal update: %w", err)
		}
		h.broadcastToNodes(data)
	}

	h.hub.Broadcast(message)

	return nil
}

// broadcastToNodes sends the given message to all cluster members except the local node.
func (h *Handler) broadcastToNodes(message []byte) {
	logger := logging.GetLogger()
	for _, node := range h.memberlist.Members() {
		if node.Name == h.memberlist.LocalNode().Name {
			continue
		}
		if err := h.memberlist.SendReliable(node, message); err != nil {
			logger.Error("Failed to send message to node %s: %v", node.Name, err)
		}
	}
}
