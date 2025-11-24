package tasks

import (
	"context"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/utils"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	json "github.com/goccy/go-json"
)

type MessageTrigger struct {
	ID        string `json:"id"`
	Path      string `json:"path"`
	Priority  int    `json:"priority,omitempty"`
	Zones     string `json:"zones,omitempty"`
	Timestamp int64  `json:"timestamp"`
}

// HandleTriggerMessage handles triggering the playback of an audio message
func (tm *TaskManager) TriggerMessage(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePut(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	logger := logging.GetLogger()

	meta, err := tm.persistence.GetAudioMetadata(id)
	if err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			logger.Error("error getting audio metadata for id %q: %v", id, err)
			http.Error(w, "Not found", http.StatusNotFound)
			return
		}
		logger.Error("Error reading audio metadata for id %q: %v", id, err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	filePath := filepath.Join(api.AudioFilesLocation, meta.Filename)
	f, err := os.Open(filePath)
	if err != nil {
		logger.Error("error opening audio file: %v", err)
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}
	defer f.Close()

	exists, err := utils.FileExists(filePath)
	if err != nil {
		logger.Error("audio file does not exist for id %q: %v", id, err)
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	if !exists {
		http.Error(w, "File not found", http.StatusNotFound)
		return
	}

	trigger := MessageTrigger{
		ID:        meta.Id,
		Path:      filePath,
		Priority:  100,
		Zones:     "all",
		Timestamp: time.Now().Unix(),
	}

	params, err := paramsFromTrigger(trigger)
	if err != nil {
		logger.Error("paramsFromTrigger error: %v", err)
		http.Error(w, "Server error", http.StatusInternalServerError)
		return
	}

	// Trigger a task immediately
	task := api.Task{
		ID:          "message_trigger",
		Description: "Trigger audio message",
		Type:        api.TaskTypeSnapshot,
		Params:      params,
	}

	if err = tm.notifyMessageTrigger(&task); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// CreateScheduleMessageTask handles HTTP POST requests to add a message trigger task.
func (tm *TaskManager) CreateScheduleMessageTask(w http.ResponseWriter, r *http.Request) {
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
	if task.Type != api.TaskTypeMessage {
		http.Error(w, "Task type must be 'message'", http.StatusBadRequest)
		return
	}

	// Must have params[api.MessageIDKey]
	messageId, ok := task.Params[api.MessageIDKey]
	if !ok || messageId == "" {
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

// taskTriggerMessageFunc returns a func that triggers playback of the given file
func (tm *TaskManager) taskTriggerMessageFunc(task *api.Task) TaskFunc {

	return func(ctx context.Context) error {

		err := tm.notifyMessageTrigger(task)
		if err != nil {
			logging.GetLogger().Error("message trigger failed: %v", err)
			tm.RecordExecution(&api.Task{}, "failed")
			return err
		}

		tm.RecordExecution(task, "success")
		return nil
	}
}

func (tm *TaskManager) notifyMessageTrigger(task *api.Task) error {
	logger := logging.GetLogger()

	// Helper to coerce any value to string
	getString := func(key string) string {
		if v, ok := task.Params[key]; ok && v != nil {
			switch val := v.(type) {
			case string:
				return val
			default:
				return fmt.Sprintf("%v", val)
			}
		}
		return ""
	}

	// Helper to coerce any value to int
	getInt := func(key string) int {
		if v, ok := task.Params[key]; ok && v != nil {
			switch val := v.(type) {
			case int:
				return val
			case int32:
				return int(val)
			case int64:
				return int(val)
			case float64:
				return int(val)
			case float32:
				return int(val)
			case string:
				if n, err := strconv.Atoi(val); err == nil {
					return n
				}
			}
		}
		return 0
	}

	messageID := getString(api.MessageIDKey)
	path := getString(api.MessagePathKey)
	zones := getString(api.MessageZonesKey)
	priority := getInt(api.MessagePriorityKey)

	// Required params
	switch {
	case messageID == "":
		return errors.New("missing required param: message_id")
	case path == "":
		return errors.New("missing required param: message_path")
	}

	// Verify audio file exists
	if _, err := os.Stat(path); err != nil {
		return fmt.Errorf("audio file not found at %q: %w", path, err)
	}

	// Construct message payload
	msg := MessageTrigger{
		ID:        messageID,
		Path:      path,
		Priority:  priority,
		Zones:     zones,
		Timestamp: time.Now().Unix(),
	}

	addr := &net.UDPAddr{IP: net.IPv4(127, 0, 0, 1), Port: api.MessageTriggerPort}
	if err := utils.SendUDPMessage(addr, msg); err != nil {
		return fmt.Errorf("failed to send UDP message: %w", err)
	}

	logger.Info("Triggered message %q at path %q (priority %d)", messageID, path, priority)
	return nil
}

// paramsFromTrigger converts a MessageTrigger struct to a map
func paramsFromTrigger(mt MessageTrigger) (map[string]any, error) {
	data, err := json.Marshal(mt)
	if err != nil {
		return nil, err
	}
	params := make(map[string]any)
	if err := json.Unmarshal(data, &params); err != nil {
		return nil, err
	}
	return params, nil
}
