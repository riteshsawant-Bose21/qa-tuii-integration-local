package tasks

import (
	"context"
	"errors"
	"fmt"

	"fusion/internal/api"
)

func (tm *TaskManager) taskActivateSceneSnapshotFunc(task *api.Task) TaskFunc {
	return func(ctx context.Context) error {
		if tm.sceneCatalog == nil {
			return errors.New("scene catalog handler is not configured")
		}

		snapshotDefinitionID, ok := task.Params[api.SnapshotDefinitionIDKey].(string)
		if !ok || snapshotDefinitionID == "" {
			return fmt.Errorf("%s required for scene_snapshot tasks", api.SnapshotDefinitionIDKey)
		}

		return tm.sceneCatalog.ActivateSnapshotByID(snapshotDefinitionID)
	}
}

func (tm *TaskManager) taskActivateSceneFunc(task *api.Task) TaskFunc {
	return func(ctx context.Context) error {
		if tm.sceneCatalog == nil {
			return errors.New("scene catalog handler is not configured")
		}

		setID, ok := task.Params[api.SceneSetIDKey].(string)
		if !ok || setID == "" {
			return fmt.Errorf("%s required for scene_activate tasks", api.SceneSetIDKey)
		}

		sceneID, ok := task.Params[api.SceneIDKey].(string)
		if !ok || sceneID == "" {
			return fmt.Errorf("%s required for scene_activate tasks", api.SceneIDKey)
		}

		return tm.sceneCatalog.ActivateScene(setID, sceneID)
	}
}
