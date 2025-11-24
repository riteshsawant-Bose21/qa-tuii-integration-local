package tasks

import (
	"context"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/utils"
	"io"
	"net/http"
	"strings"

	json "github.com/goccy/go-json"
)

// CreateApplySnapshotTask handles HTTP POST requests to add a new snapshot task.
func (tm *TaskManager) CreateApplySnapshotTask(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	var task api.Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	if task.ID == "" || task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Task ID, cron expression and description are required", http.StatusBadRequest)
		return
	}

	if task.Type != api.TaskTypeSnapshot {
		http.Error(w, "Task type must be 'snapshot'", http.StatusBadRequest)
		return
	}

	snapID, ok := task.Params[api.SnapshotIDKey]
	if !ok || snapID == "" {
		http.Error(w, "params.snapshot_id is required for snapshot tasks", http.StatusBadRequest)
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
	json.NewEncoder(w).Encode(map[string]string{
		"status": "created",
		"id":     task.ID,
	})
}

// UpdateApplySnapshotTask handles HTTP PATCH requests to update an existing task.
func (tm *TaskManager) UpdateApplySnapshotTask(w http.ResponseWriter, r *http.Request) {

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

	var patch api.TaskSnapshopPatch
	if err := json.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	// At least one must be present
	hasSnapshot := patch.Snapshot != nil
	hasCron := patch.CronExpr != nil && strings.TrimSpace(*patch.CronExpr) != ""
	hasDesc := patch.Description != nil && strings.TrimSpace(*patch.Description) != ""

	if !(hasSnapshot || hasCron || hasDesc) {
		http.Error(w, "At least one field (snapshot, cron_expr, description) must be provided", http.StatusBadRequest)
		return
	}

	// Update description
	if patch.Description != nil && strings.TrimSpace(*patch.Description) != "" {
		task.Description = *patch.Description
	}

	// Update cron expression
	if patch.CronExpr != nil && strings.TrimSpace(*patch.CronExpr) != "" {
		task.CronExpr = *patch.CronExpr
	}

	// Update snapshot
	if patch.Snapshot != nil {
		exists, err := tm.persistence.SnapshotExists(*patch.Snapshot)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if !exists {
			http.Error(w, fmt.Sprintf("Snapshot %s not found", *patch.Snapshot), http.StatusNotFound)
			return
		}

		task.Params[api.SnapshotIDKey] = *patch.Snapshot
	}

	// Run update
	err = tm.UpdateTask(task, tm.taskActivateSnapshotFunc(task))
	if err != nil {
		if errors.Is(err, ErrTaskNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}

		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// taskActivateSnapshotFunc creates a task function that applies a snapshot.
func (tm *TaskManager) taskActivateSnapshotFunc(t *api.Task) TaskFunc {
	return func(ctx context.Context) error {
		logger := logging.GetLogger()

		// Safely extract snapID as a string
		var snapID string
		if v, ok := t.Params[api.SnapshotIDKey]; ok && v != nil {
			switch val := v.(type) {
			case string:
				snapID = val
			default:
				snapID = fmt.Sprintf("%v", val)
			}
		}

		if snapID == "" {
			return errors.New("snapshot_id required for snapshot tasks")
		}

		logger.Debug("Activating snapshot %s on %s", snapID, tm.node)

		// Activate the snapshot only on the instance.
		if err := tm.persistence.ActivateSnapshot(snapID); err != nil {
			logger.Error("Snapshot apply task for '%s' failed: %v", snapID, err)
			return err
		}

		logger.Debug("Snapshot '%s' activated successfully via task", snapID)
		return nil
	}
}
