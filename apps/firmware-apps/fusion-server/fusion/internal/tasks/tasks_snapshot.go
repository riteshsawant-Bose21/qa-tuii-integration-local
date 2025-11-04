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

	json "github.com/goccy/go-json"
)

// CreateApplySnapshotTask handles HTTP POST requests to add a new snapshot task.
func (tm *TaskManager) CreateApplySnapshotTask(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	// Decode directly into api.Task
	var task api.Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Basic required fields
	if task.ID == "" || task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Task ID, cron expression and description are required", http.StatusBadRequest)
		return
	}

	// Must be a snapshot-type task
	if task.Type != api.TaskTypeSnapshot {
		http.Error(w, "Task type must be 'snapshot'", http.StatusBadRequest)
		return
	}

	// Must have params[api.SnapshotIDKey]
	snapID, ok := task.Params[api.SnapshotIDKey]
	if !ok || snapID == "" {
		http.Error(w, "params.snapshot_id is required for snapshot tasks", http.StatusBadRequest)
		return
	}

	// Check persistence for conflicts
	exists, err := tm.persistence.TaskExists(&task)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking task existence: %v", err), http.StatusInternalServerError)
		return
	}
	if exists {
		http.Error(w, "Task already exists", http.StatusConflict)
		return
	}

	// Schedule it via the new AddTask(task) signature
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

// UpdateApplySnapshotTask handles HTTP POST requests to update an existing task.
func (tm *TaskManager) UpdateApplySnapshotTask(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePost(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var task api.Task
	if err := json.Unmarshal(body, &task); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}
	task.ID = id

	if task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Cron expression and description are required", http.StatusBadRequest)
		return
	}

	// Must be a snapshot-type task
	if task.Type != api.TaskTypeSnapshot {
		http.Error(w, "Task type must be 'snapshot'", http.StatusBadRequest)
		return
	}

	if err = tm.UpdateTask(&task, tm.taskActivateSnapshotFunc(&task)); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
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
