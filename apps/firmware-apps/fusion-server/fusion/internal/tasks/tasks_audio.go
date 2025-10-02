package tasks

import (
	"context"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/utils"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
)

const audioPlayerName = "fusion-announce"

// HandleTriggerMessage handles triggering the playback of an audio message
func (tm *TaskManager) TriggerMessage(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePut(w, r) {
		return
	}

	name, err := utils.ExtractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	filePath := filepath.Join(api.AudioFilesLocation, name)
	exists, err := utils.FileExists(filePath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if !exists {
		http.Error(w, "File not found", http.StatusNotFound)
		return
	}

	// TODO: Do what is needed to play the file

	w.WriteHeader(http.StatusNoContent)
}

// CreateApplySnapshotTask handles HTTP POST requests to add a new snapshot task.
func (tm *TaskManager) CreatePlayAudioTask(w http.ResponseWriter, r *http.Request) {
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

	// Must be a audio task
	if task.Type != api.TaskTypeAudioPlayback {
		http.Error(w, "Task type must be 'audio_playback'", http.StatusBadRequest)
		return
	}

	// Must have params[api.MessageIDKey]
	snapID, ok := task.Params[api.MessageIDKey]
	if !ok || snapID == "" {
		http.Error(w, "params.message_id is required for audio playback tasks", http.StatusBadRequest)
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

// taskPlayAudioFunc returns a func that plays the given file
func (tm *TaskManager) taskPlayAudioFunc(t *api.Task, path string) TaskFunc {

	return func(ctx context.Context) error {
		_, err := os.Stat(path)
		if err != nil {
			logging.GetLogger().Error("Failed to stat audio file: %v", err)
			return err
		}

		output, err := exec.CommandContext(ctx, audioPlayerName, path).CombinedOutput()
		if err != nil {
			logging.GetLogger().Error("playback failed: %v, output: %s", err, string(output))
			tm.RecordExecution(&api.Task{}, "failed")
			return err
		}

		tm.RecordExecution(t, "success")
		return nil
	}
}
