package tasks

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/utils"

	json "github.com/goccy/go-json"
)

func (tm *TaskManager) CreateTask(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	var task api.Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	task.ID = strings.TrimSpace(task.ID)
	task.CronExpr = strings.TrimSpace(task.CronExpr)
	task.Description = strings.TrimSpace(task.Description)

	if task.ID == "" || task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Task ID, cron expression and description are required", http.StatusBadRequest)
		return
	}

	if task.Params == nil {
		task.Params = map[string]any{}
	}

	if err := validateTaskParams(task.Type, task.Params); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
	}

	if status, err := tm.validateTaskReferences(&task); err != nil {
		http.Error(w, err.Error(), status)
		return
	}

	exists, err := tm.persistence.TaskExists(&task)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking task existence: %v", err), http.StatusInternalServerError)
		return
	}
	if exists {
		http.Error(w, "Task already exists", http.StatusConflict)
		return
	}

	if err := tm.AddTask(&task); err != nil {
		http.Error(w, fmt.Sprintf("Failed to add task: %v", err), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"id": task.ID})
}

func (tm *TaskManager) UpdateTaskHandler(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePatch(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.GetTask(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()

	var patch api.TaskPatchRequest
	if err := json.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	hasDesc := patch.Description != nil
	hasCron := patch.CronExpr != nil
	hasStart := patch.StartAt != nil
	hasEnd := patch.EndAt != nil
	hasRecurrence := patch.Recurrence != nil
	hasParams := patch.Params != nil
	hasSnapshot := patch.Snapshot != nil

	if !(hasDesc || hasCron || hasStart || hasEnd || hasRecurrence || hasParams || hasSnapshot) {
		http.Error(w, "At least one field must be provided", http.StatusBadRequest)
		return
	}

	if hasDesc {
		description := strings.TrimSpace(*patch.Description)
		if description == "" {
			http.Error(w, "description cannot be empty", http.StatusBadRequest)
			return
		}
		task.Description = description
	}

	if hasCron {
		cronExpr := strings.TrimSpace(*patch.CronExpr)
		if cronExpr == "" {
			http.Error(w, "cron_expr cannot be empty", http.StatusBadRequest)
			return
		}
		task.CronExpr = cronExpr
	}

	if hasStart {
		task.StartAt = *patch.StartAt
	}

	if hasEnd {
		task.EndAt = *patch.EndAt
	}

	if hasRecurrence {
		if err := validateRecurringWindow(patch.Recurrence); err != nil {
			http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
			return
		}
		task.Recurrence = patch.Recurrence
	}

	if task.Params == nil {
		task.Params = map[string]any{}
	}

	if hasParams {
		for key, value := range patch.Params {
			task.Params[key] = value
		}
	}

	if hasSnapshot {
		snapshot := strings.TrimSpace(*patch.Snapshot)
		if snapshot == "" {
			http.Error(w, "snapshot cannot be empty", http.StatusBadRequest)
			return
		}
		task.Params[api.SnapshotIDKey] = snapshot
	}

	if err := validateTaskParams(task.Type, task.Params); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if status, err := tm.validateTaskReferences(task); err != nil {
		http.Error(w, err.Error(), status)
		return
	}

	taskFunc, err := tm.makeTaskFunc(task)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err = tm.UpdateTask(task, taskFunc)
	if err != nil {
		if errors.Is(err, ErrTaskNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}

		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func validateTaskParams(taskType api.TaskType, params map[string]any) error {
	if params == nil {
		params = map[string]any{}
	}

	requiredString := func(key string) error {
		value, ok := params[key]
		if !ok {
			return fmt.Errorf("params.%s is required", key)
		}
		stringValue, ok := value.(string)
		if !ok || strings.TrimSpace(stringValue) == "" {
			return fmt.Errorf("params.%s is required", key)
		}
		return nil
	}

	switch taskType {
	case api.TaskTypeSnapshot:
		return requiredString(api.SnapshotIDKey)
	case api.TaskTypeMessage:
		return requiredString(api.MessageIDKey)
	case api.TaskTypeSceneSnapshot:
		return requiredString(api.SnapshotDefinitionIDKey)
	case api.TaskTypeSceneActivate:
		if err := requiredString(api.SceneSetIDKey); err != nil {
			return err
		}
		return requiredString(api.SceneIDKey)
	default:
		return fmt.Errorf("unsupported task type: %s", taskType)
	}
}

func (tm *TaskManager) validateTaskReferences(task *api.Task) (int, error) {
	switch task.Type {
	case api.TaskTypeSnapshot:
		snapshotID, _ := task.Params[api.SnapshotIDKey].(string)
		exists, err := tm.persistence.SnapshotExists(snapshotID)
		if err != nil {
			return http.StatusInternalServerError, err
		}
		if !exists {
			return http.StatusNotFound, fmt.Errorf("snapshot %s not found", snapshotID)
		}

	case api.TaskTypeMessage:
		messageID, _ := task.Params[api.MessageIDKey].(string)
		if _, err := tm.persistence.GetAudioMetadata(messageID); err != nil {
			if errors.Is(err, persistence.ErrNotFound) {
				return http.StatusNotFound, fmt.Errorf("message %s not found", messageID)
			}
			return http.StatusInternalServerError, err
		}

	case api.TaskTypeSceneSnapshot:
		snapshotDefinitionID, _ := task.Params[api.SnapshotDefinitionIDKey].(string)
		exists, err := tm.persistence.SnapshotDefinitionExists(snapshotDefinitionID)
		if err != nil {
			return http.StatusInternalServerError, err
		}
		if !exists {
			return http.StatusNotFound, fmt.Errorf("snapshot definition %s not found", snapshotDefinitionID)
		}

	case api.TaskTypeSceneActivate:
		setID, _ := task.Params[api.SceneSetIDKey].(string)
		sceneID, _ := task.Params[api.SceneIDKey].(string)

		exists, err := tm.persistence.SceneSetExists(setID)
		if err != nil {
			return http.StatusInternalServerError, err
		}
		if !exists {
			return http.StatusNotFound, fmt.Errorf("scene set %s not found", setID)
		}

		if _, err := tm.persistence.GetSceneInSet(setID, sceneID); err != nil {
			if errors.Is(err, persistence.ErrNotMember) {
				return http.StatusConflict, fmt.Errorf("scene %s is not part of scene set %s", sceneID, setID)
			}
			if errors.Is(err, persistence.ErrNotFound) {
				return http.StatusNotFound, fmt.Errorf("scene set %s not found", setID)
			}
			return http.StatusInternalServerError, err
		}
	}

	return http.StatusOK, nil
}
