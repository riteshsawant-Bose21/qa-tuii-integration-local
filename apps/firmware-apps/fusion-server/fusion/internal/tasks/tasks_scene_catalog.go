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

		value, ok := task.GetParam(api.SnapshotDefinitionIDKey)
		snapshotDefinitionID, ok := value.(string)
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

		setValue, ok := task.GetParam(api.SceneSetIDKey)
		setID, ok := setValue.(string)
		if !ok || setID == "" {
			return fmt.Errorf("%s required for scene_activate tasks", api.SceneSetIDKey)
		}

		sceneValue, ok := task.GetParam(api.SceneIDKey)
		sceneID, ok := sceneValue.(string)
		if !ok || sceneID == "" {
			return fmt.Errorf("%s required for scene_activate tasks", api.SceneIDKey)
		}

		return tm.sceneCatalog.ActivateScene(setID, sceneID)
	}
}
