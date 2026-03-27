package handler

import (
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"time"
)

// HandleListSnapshotDefinitions returns all stored snapshot definitions.
func (h *Handler) HandleListSnapshotDefinitions() ([]api.SnapshotDefinition, error) {
	return h.persistence.ListSnapshotDefinitions()
}

// HandleListSceneSets returns all stored scene sets.
func (h *Handler) HandleListSceneSets() ([]api.SceneSet, error) {
	return h.persistence.ListSceneSets()
}

// HandleGetSceneSet returns a single scene set by set_id.
func (h *Handler) HandleGetSceneSet(setID string) (*api.SceneSet, error) {
	return h.persistence.GetSceneSet(setID)
}

// HandleActivateSnapshotByID patches the snapshot data onto DB State.
// Full implementation in Step 6.
func (h *Handler) HandleActivateSnapshotByID(id string) error {
	return fmt.Errorf("not implemented")
}

// HandleActivateScene activates a scene within a scene set and patches its data onto DB State.
// Full implementation in Step 6.
func (h *Handler) HandleActivateScene(setID, sceneID string) error {
	return fmt.Errorf("not implemented")
}

// HandleListSnapshots returns a list of all available snapshot names.
func (h *Handler) HandleListSnapshots() ([]string, error) {
	return h.persistence.ListSnapshots()
}

// HandleActivateSnapshot activates the specified snapshot and broadcasts the change to the cluster.
func (h *Handler) HandleActivateSnapshot(snapshot string) error {
	if err := h.handleSnapshotOperation(snapshot, api.NotifyOpSnapActivate); err != nil {
		return fmt.Errorf("failed to handle snapshot activate: %w", err)
	}

	return nil
}

// HandleCreateSnapshot creates a new snapshot and broadcasts it to the cluster with the current system state.
func (h *Handler) HandleCreateSnapshot(snapshot string) error {
	if err := h.handleSnapshotOperation(snapshot, api.NotifyOpSnapCreate); err != nil {
		return fmt.Errorf("failed to handle snapshot create: %w", err)
	}
	return nil
}

// HandleDeleteSnapshot removes the specified snapshot and notifies the cluster.
func (h *Handler) HandleDeleteSnapshot(snapshot string) error {

	// First, broadcast delete operation (this removes snapshot everywhere)
	if err := h.handleSnapshotOperation(snapshot, api.NotifyOpSnapDelete); err != nil {
		return fmt.Errorf("failed to handle snapshot delete: %w", err)
	}

	return nil
}

// HandleSaveSnapshot updates a snapshot and broadcasts it to the cluster with the current system state.
func (h *Handler) HandleSaveSnapshot(snapshot string) error {
	if err := h.handleSnapshotOperation(snapshot, api.NotifyOpSnapSave); err != nil {
		return fmt.Errorf("failed to handle snapshot save: %w", err)
	}
	return nil
}

// HandleSnapshotExists checks if a snapshot with the given name exists.
func (h *Handler) HandleSnapshotExists(snapshot string) (bool, error) {
	return h.persistence.SnapshotExists(snapshot)
}

// HandleGetDatabaseMetadata retrieves metadata for the fusion database.
func (h *Handler) HandleGetDatabaseMetadata() (*api.DatabaseMetadata, error) {
	return h.persistence.GetDatabaseMetadata()
}

// HandleGetSnapshot returns the full snapshot data for the specified name.
func (h *Handler) HandleGetSnapshot(snapshot string) (any, error) {
	return h.persistence.GetSnapshot(snapshot)
}

// HandleGetActiveSnapshotName returns the name of the active snapshot
func (h *Handler) HandleGetActiveSnapshotName() string {
	return h.persistence.GetActiveSnapshotName()
}

// HandleIsDefaultSnapshot returns true is the name is the default snapshot
func (h *Handler) IsDefaultSnapshot(snapshot string) bool {
	return h.persistence.IsDefaultSnapshot(snapshot)
}

// handleSnapshotOperation constructs a snapshot update message and broadcasts it to the cluster.
func (h *Handler) handleSnapshotOperation(snapshot string, operation api.NotifyOp) error {

	logging.GetLogger().Debug("Handler::handleSnapshotOperation: %s Node: %s", operation, h.appConfig.NodeName)

	msg := api.NewNotifyMessage(operation,
		h.appConfig.NodeName,
		api.WithSnapshotOperation(
			&api.SnapshotOperation{
				Name:      snapshot,
				Timestamp: time.Now().UTC(),
			}),
	)
	return h.hub.BroadcastToNodes(msg)
}
