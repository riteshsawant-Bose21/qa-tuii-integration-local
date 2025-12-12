package tasks

import (
	"context"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/utils"
	"io"
	"net"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	json "github.com/goccy/go-json"
)

const (
	defaultMinPriority = 1
	defaultMaxPriority = 100
	defaultZones       = "all"
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
			logger.Error("Error getting audio metadata for id %q: %v", id, err)
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
		Priority:  defaultMaxPriority,
		Zones:     defaultZones,
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
		Type:        api.TaskTypeMessage,
		Enabled:     true,
		Params:      params,
	}

	if err = tm.notifyMessageTrigger(&task); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// messageID handles HTTP GET requests to list scheduled messages
func (tm *TaskManager) ListScheduledMessages(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	logger := logging.GetLogger()

	tasks := tm.ListTasks()
	messages := make([]api.TaskMessage, 0, len(tasks))

	for _, t := range tasks {
		if t.Type != api.TaskTypeMessage {
			continue
		}

		// Params must exist
		if t.Params == nil {
			continue
		}

		// Safe extraction helpers
		getString := func(key string) (string, bool) {
			v, ok := t.Params[key]
			if !ok {
				return "", false
			}
			s, ok := v.(string)
			return s, ok
		}

		getInt64 := func(key string) (int64, bool) {
			v, ok := t.Params[key]
			if !ok {
				return 0, false
			}
			i, ok := v.(int64)
			if ok {
				return i, true
			}
			// handle JSON numbers unmarshaled as float64
			if f, ok := v.(float64); ok {
				return int64(f), true
			}
			return 0, false
		}

		msgID, ok1 := getString(api.MessageIDKey)
		zones, ok2 := getString(api.MessageZonesKey)
		priority, ok3 := getInt64(api.MessagePriorityKey)

		// Skip or log incomplete tasks
		if !ok1 || !ok2 || !ok3 {
			logger.Warn("Skipping message task due to invalid params")
			continue
		}

		m := api.TaskMessage{
			ID:          t.ID,
			MessageID:   msgID,
			Description: t.Description,
			CronExpr:    t.CronExpr,
			Zones:       zones,
			Priority:    priority,
		}

		messages = append(messages, m)
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(messages)
}

// CreateScheduleMessageTask handles HTTP POST requests to add a message trigger task.
func (tm *TaskManager) CreateScheduleMessageTask(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	var taskMessage api.TaskMessage
	if err := json.NewDecoder(r.Body).Decode(&taskMessage); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	if taskMessage.MessageID == "" || taskMessage.CronExpr == "" || taskMessage.Description == "" {
		http.Error(w, "Message, cron expression and description are required", http.StatusBadRequest)
		return
	}

	if taskMessage.Zones == "" {
		taskMessage.Zones = "all"
	}

	// Default (if unset)
	if taskMessage.Priority == 0 {
		taskMessage.Priority = defaultMaxPriority
	}

	// Clamp to [defaultMinPriority, defaultMaxPriority]
	if taskMessage.Priority < defaultMinPriority {
		taskMessage.Priority = defaultMinPriority
	}
	if taskMessage.Priority > defaultMaxPriority {
		taskMessage.Priority = defaultMaxPriority
	}

	// Verify message exists
	_, err := tm.persistence.GetAudioMetadata(taskMessage.MessageID)
	if err != nil {
		http.Error(w, "not found", http.StatusNotFound)
		return
	}

	// Create the scheduled message task
	task := api.Task{
		ID:          taskMessage.ID,
		Description: taskMessage.Description,
		CronExpr:    taskMessage.CronExpr,
		Type:        api.TaskTypeMessage,
		StartAt:     taskMessage.StartAt,
		EndAt:       taskMessage.EndAt,
		Recurrence:  taskMessage.Recurrence,
		Enabled:     true,
		Params: map[string]any{
			api.MessageIDKey:       taskMessage.MessageID,
			api.MessagePriorityKey: taskMessage.Priority,
			api.MessageZonesKey:    taskMessage.Zones,
		},
	}

	if err := tm.AddTask(&task); err != nil {
		http.Error(w, fmt.Sprintf("Failed to add task: %v", err), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{
		"id": task.ID,
	})
}

// UpdateScheduleMessageTask handles HTTP PATCH requests to update an existing message task.
func (tm *TaskManager) UpdateScheduleMessageTask(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePatch(w, r) {
		return
	}

	taskID, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task, err := tm.GetTask(taskID)
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

	var patch api.TaskMessagePatch
	if err := json.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	// At least one must be present
	hasMessageId := patch.MessageID != nil && strings.TrimSpace(*patch.MessageID) != ""
	hasCron := patch.CronExpr != nil && strings.TrimSpace(*patch.CronExpr) != ""
	hasDesc := patch.Description != nil && strings.TrimSpace(*patch.Description) != ""
	hasZones := patch.Zones != nil && strings.TrimSpace(*patch.Zones) != ""
	hasPriority := patch.Priority != nil
	hasStart := patch.StartAt != nil
	hasEnd := patch.EndAt != nil

	if !(hasMessageId || hasCron || hasDesc || hasZones || hasPriority) {
		http.Error(w, "At least one field (message_id, cron_expr, description, zones, priority) must be provided", http.StatusBadRequest)
		return
	}

	if hasDesc {
		task.Description = *patch.Description
	}

	if hasCron {
		task.CronExpr = *patch.CronExpr
	}

	if hasPriority {
		task.Params[api.MessagePriorityKey] = *patch.Priority
	}

	if hasZones {
		task.Params[api.MessageZonesKey] = *patch.Zones
	}

	if hasStart {
		task.StartAt = *patch.StartAt
	}

	if hasEnd {
		task.EndAt = *patch.EndAt
	}

	logger := logging.GetLogger()

	// Update message id
	if patch.MessageID != nil {

		messageID := *patch.MessageID

		meta, err := tm.persistence.GetAudioMetadata(messageID)
		if err != nil {
			if errors.Is(err, persistence.ErrNotFound) {
				logger.Error("Error getting audio metadata for id %q: %v", messageID, err)
				http.Error(w, "Not found", http.StatusNotFound)
				return
			}
			logger.Error("Error reading audio metadata for id %q: %v", messageID, err)
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
			logger.Error("audio file does not exist for id %q: %v", messageID, err)
			http.Error(w, "Not found", http.StatusNotFound)
			return
		}

		if !exists {
			http.Error(w, "File not found", http.StatusNotFound)
			return
		}
	}

	err = tm.UpdateTask(task, tm.taskTriggerMessageFunc(task))
	if err != nil {
		if errors.Is(err, ErrTaskNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}

		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
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

		logging.GetLogger().Info("Message '%s' triggered successfully via task", task.ID)

		return nil
	}
}

func (tm *TaskManager) notifyMessageTrigger(task *api.Task) error {

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
		return defaultMaxPriority
	}

	messageID := getString(api.MessageIDKey)
	priority := getInt(api.MessagePriorityKey)
	zones := getString(api.MessageZonesKey)

	switch messageID {
	case "":
		return errors.New("missing required param: message_id")
	}

	meta, err := tm.persistence.GetAudioMetadata(messageID)
	if err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			return fmt.Errorf("audio file not found: %s", messageID)
		}
		return fmt.Errorf("error reading audio metadata: %s", messageID)
	}

	filePath := filepath.Join(api.AudioFilesLocation, meta.Filename)
	f, err := os.Open(filePath)
	if err != nil {
		return fmt.Errorf("error opening audio file: %s", filePath)
	}
	defer f.Close()

	exists, err := utils.FileExists(filePath)
	if err != nil {
		return fmt.Errorf("audio file does not exist: %s: %v", filePath, err)
	}

	if !exists {
		return fmt.Errorf("audio file not found: %s", filePath)
	}

	// Construct message payload
	msg := MessageTrigger{
		ID:        messageID,
		Path:      filePath,
		Priority:  priority,
		Zones:     zones,
		Timestamp: time.Now().Unix(),
	}

	addr := &net.UDPAddr{IP: net.IPv4(127, 0, 0, 1), Port: api.MessageTriggerPort}
	if err := utils.SendUDPMessage(addr, msg); err != nil {
		return fmt.Errorf("failed to send UDP message: %w", err)
	}

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
