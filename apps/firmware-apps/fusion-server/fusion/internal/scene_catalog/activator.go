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

	var patchData map[string]any
	if def.GetData() != nil {
		patchData = def.GetData().AsMap()
	} else {
		patchData = map[string]any{}
	}
	result, err := a.stateManager.Patch(patchData)
	if err != nil {
		return err
	}

	if result != nil {
		if err := a.applyConfigUpdate(result.ConfigUpdate, result.Diff); err != nil {
			return err
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

	var patchData map[string]any
	if scene.GetData() != nil {
		patchData = scene.GetData().AsMap()
	} else {
		patchData = map[string]any{}
	}
	result, err := a.stateManager.Patch(patchData)
	if err != nil {
		return err
	}

	if err := a.persistence.SetCurrentScene(setID, sceneID); err != nil {
		return err
	}

	if result != nil {
		if err := a.applyConfigUpdate(result.ConfigUpdate, result.Diff); err != nil {
			return err
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

func (a *Activator) applyConfigUpdate(configUpdate *api.ConfigUpdate, diff map[string]any) error {
	if configUpdate == nil {
		return nil
	}
	configUpdate.ObserverData = diff

	message := api.NewNotifyMessage(
		api.NotifyOpConfigUpdate,
		a.appConfig.NodeName,
		api.WithConfigUpdate(configUpdate),
	)

	if err := a.hub.BroadcastToNodes(message); err != nil {
		return fmt.Errorf("failed to broadcast config update: %w", err)
	}

	return nil
}
