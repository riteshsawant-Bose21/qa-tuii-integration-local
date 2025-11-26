package handler

import (
	"fmt"
	"fusion/internal/api"
	"time"
)

// HandleListSnapshots returns a list of all available snapshot names.
func (h *Handler) HandleListSnapshots() ([]string, error) {
	return h.persistence.ListSnapshots()
}

// HandleActivateSnapshot activates the specified snapshot and broadcasts the change to the cluster.
func (h *Handler) HandleActivateSnapshot(name string) error {

	err := h.persistence.ActivateSnapshot(name)
	if err != nil {
		return err
	}

	// Broadcast snapshot-activation (cluster-sync)
	if err := h.handleSnapshotOperation(
		h.StateManager.GetNode(),
		name,
		api.NotifyOpSnapActivate); err != nil {
		return err
	}

	return nil
}

// HandleCreateSnapshot creates a new snapshot and broadcasts it to the cluster with the current system state.
func (h *Handler) HandleCreateSnapshot(name string) error {
	if err := h.persistence.CreateSnapshot(name); err != nil {
		return fmt.Errorf("failed to create snapshot: %w", err)
	}

	if err := h.handleSnapshotOperation(h.StateManager.GetNode(), name, api.NotifyOpSnapCreate); err != nil {
		return fmt.Errorf("failed to handle snapshot create: %w", err)
	}
	return nil
}

// HandleDeleteSnapshot removes the specified snapshot and notifies the cluster.
func (h *Handler) HandleDeleteSnapshot(name string) error {
	if err := h.persistence.DeleteSnapshot(name); err != nil {
		return fmt.Errorf("failed to delete snapshot: %w", err)
	}
	if err := h.handleSnapshotOperation(h.StateManager.GetNode(), name, api.NotifyOpSnapDelete); err != nil {
		return fmt.Errorf("failed to handle snapshot delete: %w", err)
	}
	return nil
}

// HandleSnapshotExists checks if a snapshot with the given name exists.
func (h *Handler) HandleSnapshotExists(name string) (bool, error) {
	return h.persistence.SnapshotExists(name)
}

// HandleGetDatabaseMetadata retrieves metadata for the fusion database.
func (h *Handler) HandleGetDatabaseMetadata() (*api.DatabaseMetadata, error) {
	return h.persistence.GetDatabaseMetadata()
}

// HandleGetSnapshot returns the full snapshot data for the specified name.
func (h *Handler) HandleGetSnapshot(name string) (any, error) {
	return h.persistence.GetSnapshot(name)
}

// HandleGetActiveSnapshotName returns the name of the active snapshot
func (h *Handler) HandleGetActiveSnapshotName() string {
	return h.persistence.GetActiveSnapshotName()
}

// HandleIsDefaultSnapshot returns true is the name is the default snapshot
func (h *Handler) IsDefaultSnapshot(name string) bool {
	return h.persistence.IsDefaultSnapshot(name)
}

// handleSnapshotOperation constructs a snapshot update message and broadcasts it to the cluster.
func (h *Handler) handleSnapshotOperation(node string, name string, update api.NotifyOp) error {

	msg := api.NewNotifyMessage(update,
		node,
		api.WithSnapshotUpdate(
			&api.SnapshotUpdate{
				Name:      name,
				Timestamp: time.Now().UTC(),
			}),
	)
	return h.broadcastMessage(msg)
}
