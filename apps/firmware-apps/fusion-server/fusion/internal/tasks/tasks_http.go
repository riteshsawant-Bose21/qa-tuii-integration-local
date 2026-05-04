package tasks

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"fusion/internal/api"
	fusionpb "fusion/internal/gen/proto/fusion"
	"fusion/internal/persistence"
	"fusion/internal/utils"

	json "github.com/goccy/go-json"
)

func (tm *TaskManager) CreateTask(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()

	task, err := tm.decodeCreateTaskBody(body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

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

	if err := normalizeTaskParams(task); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := validateTaskParams(task.Type, task.Params); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
	}

	if status, err := tm.validateTaskReferences(task); err != nil {
		http.Error(w, err.Error(), status)
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

	if err := tm.broadcastTaskOperation(api.NotifyOpTaskCreate, task); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusCreated)
	_ = writeProtoJSON(w, &fusionpb.CreateTaskResponse{Id: task.ID})
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

	if len(body) == 0 {
		http.Error(w, "Invalid JSON format: empty body", http.StatusBadRequest)
		return
	}

	switch task.Type {
	case api.TaskTypeSnapshot:
		tm.updateSnapshotTaskFromProto(w, task, body)
		return
	case api.TaskTypeMessage:
		tm.updateMessageTaskFromProto(w, task, body)
		return
	default:
		http.Error(w, fmt.Sprintf("Unsupported task type: %s", task.Type), http.StatusBadRequest)
		return
	}
}

func (tm *TaskManager) decodeCreateTaskBody(body []byte) (*api.Task, error) {
	var raw map[string]json.RawMessage
	if err := json.Unmarshal(body, &raw); err != nil {
		return nil, err
	}

	if _, ok := raw["snapshot_id"]; ok {
		var request fusionpb.SnapshotTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		return snapshotCreateRequestToTask(&request), nil
	}
	if _, ok := raw["message_id"]; ok {
		var request fusionpb.MessageTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		task := messageCreateRequestToTask(&request)
		if err := normalizeTaskParams(task); err != nil {
			return nil, err
		}
		return task, nil
	}
	if _, ok := raw["priority"]; ok {
		var request fusionpb.MessageTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		task := messageCreateRequestToTask(&request)
		if err := normalizeTaskParams(task); err != nil {
			return nil, err
		}
		return task, nil
	}
	if _, ok := raw["zones"]; ok {
		var request fusionpb.MessageTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		task := messageCreateRequestToTask(&request)
		if err := normalizeTaskParams(task); err != nil {
			return nil, err
		}
		return task, nil
	}

	return nil, fmt.Errorf("task requests must use protobuf JSON and include snapshot_id or message_id")
}

func normalizeTaskParams(task *api.Task) error {
	if task == nil {
		return fmt.Errorf("task is nil")
	}

	if task.Params == nil {
		task.Params = map[string]any{}
	}

	switch task.Type {
	case api.TaskTypeMessage:
		messageID, _ := task.Params[api.MessageIDKey].(string)
		if strings.TrimSpace(messageID) == "" {
			return fmt.Errorf("params.%s is required", api.MessageIDKey)
		}

		task.Params[api.MessageZonesKey] = messageZonesFromProto(fmt.Sprintf("%v", task.Params[api.MessageZonesKey]))

		priority, err := int64Param(task.Params[api.MessagePriorityKey])
		if err != nil {
			priority = 0
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
		task.Params[api.MessagePriorityKey] = priority
	}

	return nil
}

func (tm *TaskManager) updateSnapshotTaskFromProto(w http.ResponseWriter, task *api.Task, body []byte) {
	var patch fusionpb.SnapshotTaskUpdateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

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
		task.Params[api.SnapshotIDKey] = patch.GetSnapshotId()
	}
	if hasStart {
		task.StartAt = patch.StartAt.AsTime()
	}
	if hasEnd {
		task.EndAt = patch.EndAt.AsTime()
	}
	if hasRecurrence {
		task.Recurrence = recurringWindowFromProto(patch.Recurrence)
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
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
	if err := tm.UpdateTask(task, taskFunc); err != nil {
		if errors.Is(err, ErrTaskNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := tm.broadcastTaskOperation(api.NotifyOpTaskUpdate, task); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func (tm *TaskManager) updateMessageTaskFromProto(w http.ResponseWriter, task *api.Task, body []byte) {
	var patch fusionpb.MessageTaskUpdateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	hasMessageID := patch.MessageId != nil && strings.TrimSpace(patch.GetMessageId()) != ""
	hasCron := patch.CronExpr != nil && strings.TrimSpace(patch.GetCronExpr()) != ""
	hasDesc := patch.Description != nil && strings.TrimSpace(patch.GetDescription()) != ""
	hasZones := patch.Zones != nil
	hasPriority := patch.Priority != nil
	hasStart := patch.StartAt != nil
	hasEnd := patch.EndAt != nil
	hasRecurrence := patch.Recurrence != nil

	if !(hasMessageID || hasCron || hasDesc || hasZones || hasPriority || hasStart || hasEnd || hasRecurrence) {
		http.Error(w, "At least one field must be provided", http.StatusBadRequest)
		return
	}

	if hasDesc {
		task.Description = patch.GetDescription()
	}
	if hasCron {
		task.CronExpr = patch.GetCronExpr()
	}
	if hasMessageID {
		task.Params[api.MessageIDKey] = patch.GetMessageId()
	}
	if hasZones {
		task.Params[api.MessageZonesKey] = messageZonesFromProto(patch.GetZones())
	}
	if hasPriority {
		task.Params[api.MessagePriorityKey] = patch.GetPriority()
	}
	if hasStart {
		task.StartAt = patch.StartAt.AsTime()
	}
	if hasEnd {
		task.EndAt = patch.EndAt.AsTime()
	}
	if hasRecurrence {
		task.Recurrence = recurringWindowFromProto(patch.Recurrence)
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
	}
	if err := normalizeTaskParams(task); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
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
	if err := tm.UpdateTask(task, taskFunc); err != nil {
		if errors.Is(err, ErrTaskNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := tm.broadcastTaskOperation(api.NotifyOpTaskUpdate, task); err != nil {
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
