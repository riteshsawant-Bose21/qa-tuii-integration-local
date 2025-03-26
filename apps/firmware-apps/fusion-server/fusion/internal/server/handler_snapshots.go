package server

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
	if err := h.persistence.ActivateSnapshot(name); err != nil {
		return fmt.Errorf("failed to activate snapshot: %w", err)
	}
	if err := h.handleSnapshotOperation(h.stateManager.node, name, api.NotifyOpSnapActivate, nil); err != nil {
		return fmt.Errorf("failed to handle snapshot activate: %w", err)
	}
	return nil
}

// HandleCreateSnapshot creates a new snapshot and broadcasts it to the cluster with the current system state.
func (h *Handler) HandleCreateSnapshot(name string) error {
	if err := h.persistence.CreateSnapshot(name); err != nil {
		return fmt.Errorf("failed to create snapshot: %w", err)
	}

	data := TransformState(h.stateManager.GetFullState())
	if err := h.handleSnapshotOperation(h.stateManager.node, name, api.NotifyOpSnapCreate, data); err != nil {
		return fmt.Errorf("failed to handle snapshot create: %w", err)
	}
	return nil
}

// HandleDeleteSnapshot removes the specified snapshot and notifies the cluster.
func (h *Handler) HandleDeleteSnapshot(name string) error {
	if err := h.persistence.DeleteSnapshot(name); err != nil {
		return fmt.Errorf("failed to delete snapshot: %w", err)
	}
	if err := h.handleSnapshotOperation(h.stateManager.node, name, api.NotifyOpSnapDelete, nil); err != nil {
		return fmt.Errorf("failed to handle snapshot delete: %w", err)
	}
	return nil
}

// HandleImportSnapshots imports a batch of snapshots and broadcasts the import operation to the cluster.
func (h *Handler) HandleImportSnapshots(data map[string]any) error {
	if err := h.persistence.ImportSnapshots(data); err != nil {
		return fmt.Errorf("failed to import snapshot: %w", err)
	}

	if err := h.handleSnapshotOperation(h.stateManager.node, defaultBucketName, api.NotifyOpSnapImport, data); err != nil {
		return fmt.Errorf("failed to handle snapshot import: %w", err)
	}

	return nil
}

// HandleSnapshotExists checks if a snapshot with the given name exists.
func (h *Handler) HandleSnapshotExists(name string) (bool, error) {
	return h.persistence.SnapshotExists(name)
}

// HandleGetSnapshotMetadata retrieves metadata for all stored snapshots.
func (h *Handler) HandleGetSnapshotMetadata() (api.SnapshotMetadata, error) {
	return h.persistence.GetSnapshotMetadata()
}

// HandleGetSnapshot returns the full snapshot data for the specified name.
func (h *Handler) HandleGetSnapshot(name string) (any, error) {
	return h.persistence.GetSnapshot(name)
}

// HandleExportSnapshots exports all current snapshots.
func (h *Handler) HandleExportSnapshots() (any, error) {
	return h.persistence.ExportSnapshots()
}

// handleSnapshotOperation constructs a snapshot update message and broadcasts it to the cluster.
func (h *Handler) handleSnapshotOperation(node string, name string, update api.NotifyOp, data map[string]any) error {
	message := api.NotifyMessage{
		Operation:      update,
		Node:           node,
		SnapshotUpdate: &api.SnapshotUpdate{Name: name, Data: data, Timestamp: time.Now().UTC()},
	}
	return h.broadcastUpdate(message)
}
