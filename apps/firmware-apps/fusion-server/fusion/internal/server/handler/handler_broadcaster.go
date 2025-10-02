package handler

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
)

// broadcastUpdate processes an incoming NotifyMessage by applying configuration or snapshot updates,
// performing version changes, and then broadcasting the message to other nodes and local clients if needed.
func (h *Handler) broadcastUpdate(message *api.NotifyMessage) error {

	switch message.Operation {

	case api.NotifyOpConfigUpdate:
		// Apply the configuration update and mark state as dirty for persistence.
		if err := h.StateManager.ApplyUpdate(*message.ConfigUpdate); err != nil {
			return fmt.Errorf("failed to apply update: %w", err)
		}
		h.persistence.MarkDirty()

	case api.NotifyOpSnapActivate:
		// Activate the specified snapshot.
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

	case api.NotifyOpVersionUpdate:
		// Perform a version update triggered remotely.
		if err := h.updater.PerformRemoteUpdate(*message.VersionMessage); err != nil {
			return fmt.Errorf("performRemoteUpdate error: %v", err)
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
