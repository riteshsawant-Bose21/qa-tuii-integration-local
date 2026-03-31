package tasks

import (
	"context"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/utils"
	"io"
	"net/http"
	"strings"
	"time"
)

// CreateApplySnapshotTask handles HTTP POST requests to add a new snapshot task.
func (tm *TaskManager) CreateApplySnapshotTask(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusInternalServerError)
		return
	}

	var request fusionpb.SnapshotTaskCreateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	task := snapshotCreateRequestToTask(&request)

	if task.ID == "" || task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Task ID, cron expression and description are required", http.StatusBadRequest)
		return
	}

	snapID, ok := task.Params[api.SnapshotIDKey]
	if !ok || snapID == "" {
		http.Error(w, "params.snapshot_id is required for snapshot tasks", http.StatusBadRequest)
		return
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
	}

	exists, err := tm.persistence.TaskExists(task)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking task existence: %v", err), http.StatusInternalServerError)
		return
	}
	if exists {
		http.Error(w, "Task already exists", http.StatusConflict)
		return
	}

	if err := tm.AddTask(task); err != nil {
		http.Error(w, fmt.Sprintf("Failed to add task: %v", err), http.StatusBadRequest)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusCreated)
	_ = writeProtoJSON(w, &fusionpb.CreateTaskResponse{Id: task.ID})
}

// UpdateApplySnapshotTask handles HTTP PATCH requests to update an existing snapshot task.
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

	var patch fusionpb.SnapshotTaskUpdateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	// At least one must be present
	hasSnapshot := patch.SnapshotId != nil && strings.TrimSpace(patch.GetSnapshotId()) != ""
	hasCron := patch.CronExpr != nil && strings.TrimSpace(patch.GetCronExpr()) != ""
	hasDesc := patch.Description != nil && strings.TrimSpace(patch.GetDescription()) != ""
	hasStart := patch.StartAt != nil
	hasEnd := patch.EndAt != nil
	hasRecurrence := patch.Recurrence != nil

	if !(hasSnapshot || hasCron || hasDesc || hasStart || hasEnd || hasRecurrence) {
		http.Error(w, "At least one field must be provided", http.StatusBadRequest)
		return
	}

	if hasDesc {
		task.Description = patch.GetDescription()
	}

	if hasCron {
		task.CronExpr = patch.GetCronExpr()
	}

	if hasSnapshot {
		snapshotID := patch.GetSnapshotId()
		exists, err := tm.persistence.SnapshotExists(snapshotID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if !exists {
			http.Error(w, fmt.Sprintf("Snapshot %s not found", snapshotID), http.StatusNotFound)
			return
		}

		task.Params[api.SnapshotIDKey] = snapshotID
	}

	if hasStart {
		task.StartAt = patch.StartAt.AsTime()
	}

	if hasEnd {
		task.EndAt = patch.EndAt.AsTime()
	}

	if hasRecurrence {
		recurrence := recurringWindowFromProto(patch.Recurrence)
		if err := validateRecurringWindow(recurrence); err != nil {
			http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
			return
		}
		task.Recurrence = recurrence
	}

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

		// Activate the snapshot only on the instance.
		err := tm.persistence.ActivateSnapshot(snapID)
		if err != nil {
			return err
		}

		// Broadcast snapshot-activation (cluster-sync)
		if err := tm.handleSnapshotOperation(
			tm.node,
			snapID,
			api.NotifyOpSnapActivate); err != nil {
			return err
		}

		logging.GetLogger().Info("Snapshot '%s' activated successfully via task", snapID)

		return nil
	}
}

// handleSnapshotOperation constructs a snapshot update message and broadcasts it to the cluster.
func (tm *TaskManager) handleSnapshotOperation(node string, name string, update api.NotifyOp) error {

	msg := api.NewNotifyMessage(update,
		node,
		api.WithSnapshotOperation(&api.SnapshotOperation{
			Name:      name,
			Timestamp: time.Now().UTC(),
		}),
	)
	return tm.hub.BroadcastToNodes(msg)
}
