package tasks

import (
	"context"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
<<<<<<< HEAD
=======
	model "fusion/internal/gen/proto/fusion"
>>>>>>> gene/value
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
	"google.golang.org/protobuf/encoding/protojson"
)

const (
	defaultMinPriority = 1
	defaultMaxPriority = 100
)

type scheduledMessage struct {
	ID          string               `json:"id"`
	Description string               `json:"description"`
	CronExpr    string               `json:"cron_expr"`
	StartAt     time.Time            `json:"start_at"`
	EndAt       time.Time            `json:"end_at"`
	Recurrence  *api.RecurringWindow `json:"recurrence,omitempty"`
	MessageID   string               `json:"message_id"`
	Priority    int64                `json:"priority"`
	Zones       []string             `json:"zones"`
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

	var req model.TriggerMessageRequest
	if r.Body != nil {
		body, readErr := io.ReadAll(r.Body)
		if readErr != nil {
			http.Error(w, fmt.Sprintf("Invalid JSON format: %v", readErr), http.StatusBadRequest)
			return
		}
		if len(body) > 0 {
			err = protojson.UnmarshalOptions{DiscardUnknown: false}.Unmarshal(body, &req)
		}
		if err != nil {
			http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
			return
		}
		defer r.Body.Close()
	}

	params, err := tm.buildMessageTaskParams(id, int(req.GetPriority()), req.GetZones())
	if err != nil {
		switch {
		case errors.Is(err, persistence.ErrNotFound):
			logger.Error("Error getting audio metadata for id %q: %v", id, err)
			http.Error(w, "Not found", http.StatusNotFound)
		default:
			logger.Error("Error building immediate message task params for id %q: %v", id, err)
			http.Error(w, "Server error", http.StatusInternalServerError)
		}
		return
	}

	// Trigger a task immediately
	task := api.Task{
		ID:          "message_trigger_immediate",
		Description: "Immediate/manual audio message trigger",
		Type:        api.TaskTypeMessage,
		Enabled:     true,
		Params:      params,
	}

	if err = tm.taskTriggerMessageFunc(&task)(r.Context()); err != nil {
		tm.RecordExecution(&task, "failed")
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	tm.RecordExecution(&task, "success")

	w.WriteHeader(http.StatusNoContent)
}

// messageID handles HTTP GET requests to list scheduled messages
func (tm *TaskManager) ListScheduledMessages(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	logger := logging.GetLogger()

	tasks := tm.ListTasks()
	messages := make([]scheduledMessage, 0, len(tasks))

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
			v, hasKey := t.Params[key]
			if !hasKey {
				return "", false
			}
			s, isString := v.(string)
			return s, isString
		}

		getInt64 := func(key string) (int64, bool) {
			v, hasKey := t.Params[key]
			if !hasKey {
				return 0, false
			}
			i, isInt64 := v.(int64)
			if isInt64 {
				return i, true
			}
			// handle JSON numbers unmarshaled as float64
			if f, isFloat64 := v.(float64); isFloat64 {
				return int64(f), true
			}
			return 0, false
		}

		getStringSliceLocal := func(key string) []string {
			v, hasKey := t.Params[key]
			if !hasKey {
				return []string{}
			}
			return utils.CoerceStringSlice(v)
		}

		msgID, hasMessageID := getString(api.MessageIDKey)
		zones := getStringSliceLocal(api.MessageZonesKey)
		priority, hasPriority := getInt64(api.MessagePriorityKey)

		// Skip or log incomplete tasks
		if !hasMessageID || !hasPriority {
			logger.Warn("Skipping message task due to invalid params")
			continue
		}

		m := scheduledMessage{
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
	defer r.Body.Close()

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusInternalServerError)
		return
	}

	var request model.MessageTaskCreateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	taskMessage := scheduledMessage{
		ID:          request.Id,
		Description: request.Description,
		CronExpr:    request.CronExpr,
		StartAt:     timeFromProto(request.StartAt),
		EndAt:       timeFromProto(request.EndAt),
		Recurrence:  recurringWindowFromProto(request.Recurrence),
		MessageID:   request.MessageId,
		Priority:    request.Priority,
		Zones:       messageZonesFromProto(request.Zones),
	}

	if taskMessage.ID == "" || taskMessage.MessageID == "" || taskMessage.CronExpr == "" || taskMessage.Description == "" {
		http.Error(w, "Task ID, message, cron expression and description are required", http.StatusBadRequest)
		return
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
	params, err := tm.buildMessageTaskParams(taskMessage.MessageID, int(taskMessage.Priority), taskMessage.Zones)
	if err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, "not found", http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Failed to build task params: %v", err), http.StatusInternalServerError)
		return
	}

	task := &api.Task{
		ID:          taskMessage.ID,
		Description: taskMessage.Description,
		Type:        api.TaskTypeMessage,
		CronExpr:    taskMessage.CronExpr,
		StartAt:     taskMessage.StartAt,
		EndAt:       taskMessage.EndAt,
		Recurrence:  taskMessage.Recurrence,
		Enabled:     true,
		Params:      params,
	}

	if err := tm.AddTask(task); err != nil {
		http.Error(w, fmt.Sprintf("Failed to add task: %v", err), http.StatusBadRequest)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusCreated)
	_ = writeProtoJSON(w, &model.CreateTaskResponse{Id: task.ID})
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

	var patch model.MessageTaskUpdateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	// At least one must be present
	hasMessageId := patch.MessageId != nil && strings.TrimSpace(*patch.MessageId) != ""
	hasCron := patch.CronExpr != nil && strings.TrimSpace(*patch.CronExpr) != ""
	hasDesc := patch.Description != nil && strings.TrimSpace(*patch.Description) != ""
	hasZones := patch.Zones != nil
	hasPriority := patch.Priority != nil
	hasStart := patch.StartAt != nil
	hasEnd := patch.EndAt != nil

	if !(hasMessageId || hasCron || hasDesc || hasZones || hasPriority) {
		http.Error(w, "At least one field (message_id, cron_expr, description, zones, priority) must be provided", http.StatusBadRequest)
		return
	}

	if hasDesc {
		task.Description = patch.GetDescription()
	}

	if hasCron {
		task.CronExpr = patch.GetCronExpr()
	}

	if hasPriority {
		task.Params[api.MessagePriorityKey] = patch.GetPriority()
	}

	if hasZones {
		task.Params[api.MessageZonesKey] = messageZonesFromProto(patch.GetZones())
	}

	if hasStart {
		task.StartAt = patch.StartAt.AsTime()
	}

	if hasEnd {
		task.EndAt = patch.EndAt.AsTime()
	}

	logger := logging.GetLogger()

	// Update message id
	if hasMessageId {

		messageID := patch.GetMessageId()

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

		task.Params[api.MessageIDKey] = messageID
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
		if v, hasKey := task.Params[key]; hasKey && v != nil {
			switch val := v.(type) {
			case string:
				return val
			default:
				return fmt.Sprintf("%v", val)
			}
		}
		return ""
	}

	// Helper to coerce any value to []string
	getStringSlice := func(key string) []string {
		v, hasKey := task.Params[key]
		if !hasKey {
			return []string{}
		}
		return utils.CoerceStringSlice(v)
	}

	// Helper to coerce any value to int
	getInt := func(key string) int {
		if v, hasKey := task.Params[key]; hasKey && v != nil {
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
	zones := getStringSlice(api.MessageZonesKey)

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
	msg := api.MessageTrigger{
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

func (tm *TaskManager) buildMessageTaskParams(messageID string, priority int, zones []string) (map[string]any, error) {
	meta, err := tm.persistence.GetAudioMetadata(messageID)
	if err != nil {
		return nil, err
	}

	filePath := filepath.Join(api.AudioFilesLocation, meta.Filename)
	f, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	exists, err := utils.FileExists(filePath)
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, os.ErrNotExist
	}

	if priority == 0 {
		priority = defaultMaxPriority
	}
	if priority < defaultMinPriority {
		priority = defaultMinPriority
	}
	if priority > defaultMaxPriority {
		priority = defaultMaxPriority
	}

	trigger := api.MessageTrigger{
		ID:        meta.Id,
		Path:      filePath,
		Priority:  priority,
		Zones:     utils.CoerceStringSlice(zones),
		Timestamp: time.Now().Unix(),
	}

	params, err := utils.ToMap(trigger)
	if err != nil {
		return nil, err
	}

	// Empty zones means "all zones", but keep it explicit in task params so the
	// scheduler API can round-trip the user's intent.
	params[api.MessageZonesKey] = utils.CoerceStringSlice(zones)

	return params, nil
}
