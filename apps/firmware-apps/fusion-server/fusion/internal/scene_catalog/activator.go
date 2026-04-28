package scene_catalog

import (
	"fmt"

	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
)

// Activator applies persisted snapshot and scene definitions to live state
// and broadcasts the resulting updates to the cluster.
type Activator struct {
	appConfig    *api.AppConfig
	persistence  *persistence.Persistence
	stateManager *persistence.StateManager
	hub          *pubsub.Hub
}

func NewActivator(
	appConfig *api.AppConfig,
	persistence *persistence.Persistence,
	stateManager *persistence.StateManager,
	hub *pubsub.Hub,
) *Activator {
	return &Activator{
		appConfig:    appConfig,
		persistence:  persistence,
		stateManager: stateManager,
		hub:          hub,
	}
}

func (a *Activator) ActivateSnapshotByID(id string) error {
	def, err := a.persistence.GetSnapshotDefinition(id)
	if err != nil {
		return err
	}

	result, err := a.stateManager.Patch(def.Data)
	if err != nil {
		return err
	}

	if result != nil {
		message := api.NewNotifyMessage(
			api.NotifyOpConfigUpdate,
			a.appConfig.NodeName,
			api.WithConfigUpdate(result.ConfigUpdate),
		)
		if err := a.hub.BroadcastToNodes(message); err != nil {
			return fmt.Errorf("failed to broadcast config update: %w", err)
		}
	}

	msg := api.NewNotifyMessage(
		api.NotifyOpSnapshotV2Activate,
		a.appConfig.NodeName,
		api.WithSnapshotActivation(&api.ActivateSnapshotRequest{ID: id}),
	)
	if err := a.hub.BroadcastToNodes(msg); err != nil {
		return fmt.Errorf("failed to broadcast snapshot activation: %w", err)
	}

	return nil
}

func (a *Activator) ActivateScene(setID, sceneID string) error {
	scene, err := a.persistence.GetSceneInSet(setID, sceneID)
	if err != nil {
		return err
	}

	result, err := a.stateManager.Patch(scene.Data)
	if err != nil {
		return err
	}

	if err := a.persistence.SetCurrentScene(setID, sceneID); err != nil {
		return err
	}

	if result != nil {
		message := api.NewNotifyMessage(
			api.NotifyOpConfigUpdate,
			a.appConfig.NodeName,
			api.WithConfigUpdate(result.ConfigUpdate),
		)
		if err := a.hub.BroadcastToNodes(message); err != nil {
			return fmt.Errorf("failed to broadcast config update: %w", err)
		}
	}

	msg := api.NewNotifyMessage(
		api.NotifyOpSceneActivate,
		a.appConfig.NodeName,
		api.WithSceneActivation(&api.ActivateSceneSetRequest{SetID: setID, SceneID: sceneID}),
	)
	if err := a.hub.BroadcastToNodes(msg); err != nil {
		return fmt.Errorf("failed to broadcast scene activation: %w", err)
	}

	return nil
}
