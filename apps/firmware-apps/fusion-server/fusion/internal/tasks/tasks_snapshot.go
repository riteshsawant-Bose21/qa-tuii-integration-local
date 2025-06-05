package tasks

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/utils"
	"io"
	"net/http"
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

	// Must have params["snapshot_id"]
	snapID, ok := task.Params["snapshot_id"]
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

	id, err := extractTaskID(r)
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

	// Must have params["snapshot_id"]
	snapshotID, ok := task.Params["snapshot_id"]
	if !ok || snapshotID == "" {
		http.Error(w, "params.snapshot_id is required for snapshot tasks", http.StatusBadRequest)
		return
	}

	if err = tm.UpdateTask(&task, tm.taskActivateSnapshotFunc(snapshotID)); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
}

// taskActivateSnapshotFunc creates a task function that applies a snapshot.
func (tm *TaskManager) taskActivateSnapshotFunc(name string) func() {
	return func() {
		logger := logging.GetLogger()
		logger.Debug("Activating snapshot %s on %s", name, name)

		// Activate the snapshot only on the instance. Activation will cause
		// the config data to be propogaged to all instances.
		if err := tm.persistence.ActivateSnapshot(name); err != nil {
			logger.Error("Snapshot apply task for '%s' failed: %v", name, err)

		} else {
			logger.Debug("Snapshot '%s' activated successfully via task", name)
		}
	}
}
