package tasks

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"

	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
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

	task.Id = strings.TrimSpace(task.Id)
	task.CronExpr = strings.TrimSpace(task.CronExpr)
	task.Description = strings.TrimSpace(task.Description)

	if task.Id == "" || task.CronExpr == "" || task.Description == "" {
		http.Error(w, "Task ID, cron expression and description are required", http.StatusBadRequest)
		return
	}

	if err := normalizeTaskParams(task); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := validateTaskParams(task); err != nil {
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
	_ = writeProtoJSON(w, &model.CreateTaskResponse{Id: task.Id})
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
	case api.TaskTypeSceneSnapshot:
		tm.updateSceneSnapshotTaskFromProto(w, task, body)
		return
	case api.TaskTypeSceneActivate:
		tm.updateSceneActivateTaskFromProto(w, task, body)
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
		var request model.SnapshotTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		return snapshotCreateRequestToTask(&request), nil
	}
	if _, ok := raw["message_id"]; ok {
		var request model.MessageTaskCreateRequest
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
		var request model.MessageTaskCreateRequest
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
		var request model.MessageTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		task := messageCreateRequestToTask(&request)
		if err := normalizeTaskParams(task); err != nil {
			return nil, err
		}
		return task, nil
	}
	if _, ok := raw["snapshot_definition_id"]; ok {
		var request model.SceneSnapshotTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		return sceneSnapshotCreateRequestToTask(&request), nil
	}
	if _, ok := raw["set_id"]; ok {
		var request model.SceneActivateTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		return sceneActivateCreateRequestToTask(&request), nil
	}
	if _, ok := raw["scene_id"]; ok {
		var request model.SceneActivateTaskCreateRequest
		if err := protoJSONUnmarshalOptions.Unmarshal(body, &request); err != nil {
			return nil, err
		}
		return sceneActivateCreateRequestToTask(&request), nil
	}

	return nil, fmt.Errorf("task requests must use protobuf JSON and include snapshot_id, message_id, snapshot_definition_id, or set_id/scene_id")
}

func normalizeTaskParams(task *api.Task) error {
	if task == nil {
		return fmt.Errorf("task is nil")
	}

	switch task.Type {
	case api.TaskTypeMessage:
		value, _ := task.GetParam(api.MessageIDKey)
		messageID, _ := value.(string)
		if strings.TrimSpace(messageID) == "" {
			return fmt.Errorf("params.%s is required", api.MessageIDKey)
		}
		zonesValue, _ := task.GetParam(api.MessageZonesKey)
		if err := task.SetParam(api.MessageZonesKey, messageZonesFromProto(fmt.Sprintf("%v", zonesValue))); err != nil {
			return err
		}

		priorityValue, _ := task.GetParam(api.MessagePriorityKey)
		priority, err := int64Param(priorityValue)
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
		if err := task.SetParam(api.MessagePriorityKey, priority); err != nil {
			return err
		}
	}

	return nil
}

func (tm *TaskManager) updateSnapshotTaskFromProto(w http.ResponseWriter, task *api.Task, body []byte) {
	var patch model.SnapshotTaskUpdateRequest
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
		if err := task.SetParam(api.SnapshotIDKey, patch.GetSnapshotId()); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}
	if hasStart {
		task.SetStartAtTime(patch.StartAt.AsTime())
	}
	if hasEnd {
		task.SetEndAtTime(patch.EndAt.AsTime())
	}
	if hasRecurrence {
		task.Recurrence = recurringWindowFromProto(patch.Recurrence)
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
	}
	if err := validateTaskParams(task); err != nil {
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
	var patch model.MessageTaskUpdateRequest
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
		if err := task.SetParam(api.MessageIDKey, patch.GetMessageId()); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}
	if hasZones {
		if err := task.SetParam(api.MessageZonesKey, messageZonesFromProto(patch.GetZones())); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}
	if hasPriority {
		if err := task.SetParam(api.MessagePriorityKey, patch.GetPriority()); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}
	if hasStart {
		task.SetStartAtTime(patch.StartAt.AsTime())
	}
	if hasEnd {
		task.SetEndAtTime(patch.EndAt.AsTime())
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
	if err := validateTaskParams(task); err != nil {
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

func (tm *TaskManager) updateSceneSnapshotTaskFromProto(w http.ResponseWriter, task *api.Task, body []byte) {
	var patch model.SceneSnapshotTaskUpdateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	hasSnapshotDefinition := patch.SnapshotDefinitionId != nil && strings.TrimSpace(patch.GetSnapshotDefinitionId()) != ""
	hasCron := patch.CronExpr != nil && strings.TrimSpace(patch.GetCronExpr()) != ""
	hasDesc := patch.Description != nil && strings.TrimSpace(patch.GetDescription()) != ""
	hasStart := patch.StartAt != nil
	hasEnd := patch.EndAt != nil
	hasRecurrence := patch.Recurrence != nil

	if !(hasSnapshotDefinition || hasCron || hasDesc || hasStart || hasEnd || hasRecurrence) {
		http.Error(w, "At least one field must be provided", http.StatusBadRequest)
		return
	}

	if hasDesc {
		task.Description = patch.GetDescription()
	}
	if hasCron {
		task.CronExpr = patch.GetCronExpr()
	}
	if hasSnapshotDefinition {
		if err := task.SetParam(api.SnapshotDefinitionIDKey, patch.GetSnapshotDefinitionId()); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}
	if hasStart {
		task.SetStartAtTime(patch.StartAt.AsTime())
	}
	if hasEnd {
		task.SetEndAtTime(patch.EndAt.AsTime())
	}
	if hasRecurrence {
		task.Recurrence = recurringWindowFromProto(patch.Recurrence)
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
	}
	if err := validateTaskParams(task); err != nil {
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

func (tm *TaskManager) updateSceneActivateTaskFromProto(w http.ResponseWriter, task *api.Task, body []byte) {
	var patch model.SceneActivateTaskUpdateRequest
	if err := protoJSONUnmarshalOptions.Unmarshal(body, &patch); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	hasSetID := patch.SetId != nil && strings.TrimSpace(patch.GetSetId()) != ""
	hasSceneID := patch.SceneId != nil && strings.TrimSpace(patch.GetSceneId()) != ""
	hasCron := patch.CronExpr != nil && strings.TrimSpace(patch.GetCronExpr()) != ""
	hasDesc := patch.Description != nil && strings.TrimSpace(patch.GetDescription()) != ""
	hasStart := patch.StartAt != nil
	hasEnd := patch.EndAt != nil
	hasRecurrence := patch.Recurrence != nil

	if !(hasSetID || hasSceneID || hasCron || hasDesc || hasStart || hasEnd || hasRecurrence) {
		http.Error(w, "At least one field must be provided", http.StatusBadRequest)
		return
	}

	if hasDesc {
		task.Description = patch.GetDescription()
	}
	if hasCron {
		task.CronExpr = patch.GetCronExpr()
	}
	if hasSetID {
		if err := task.SetParam(api.SceneSetIDKey, patch.GetSetId()); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}
	if hasSceneID {
		if err := task.SetParam(api.SceneIDKey, patch.GetSceneId()); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}
	if hasStart {
		task.SetStartAtTime(patch.StartAt.AsTime())
	}
	if hasEnd {
		task.SetEndAtTime(patch.EndAt.AsTime())
	}
	if hasRecurrence {
		task.Recurrence = recurringWindowFromProto(patch.Recurrence)
	}

	if err := validateRecurringWindow(task.Recurrence); err != nil {
		http.Error(w, fmt.Sprintf("Invalid recurrence: %v", err), http.StatusBadRequest)
		return
	}
	if err := validateTaskParams(task); err != nil {
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

func validateTaskParams(task *api.Task) error {
	requiredString := func(key string) error {
		value, ok := task.GetParam(key)
		if !ok {
			return fmt.Errorf("params.%s is required", key)
		}
		stringValue, ok := value.(string)
		if !ok || strings.TrimSpace(stringValue) == "" {
			return fmt.Errorf("params.%s is required", key)
		}
		return nil
	}

	switch task.Type {
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
		return fmt.Errorf("unsupported task type: %s", task.Type)
	}
}

func (tm *TaskManager) validateTaskReferences(task *api.Task) (int, error) {
	switch task.Type {
	case api.TaskTypeSnapshot:
		value, _ := task.GetParam(api.SnapshotIDKey)
		snapshotID, _ := value.(string)
		exists, err := tm.persistence.SnapshotExists(snapshotID)
		if err != nil {
			return http.StatusInternalServerError, err
		}
		if !exists {
			return http.StatusNotFound, fmt.Errorf("snapshot %s not found", snapshotID)
		}

	case api.TaskTypeMessage:
		value, _ := task.GetParam(api.MessageIDKey)
		messageID, _ := value.(string)
		if _, err := tm.persistence.GetAudioMetadata(messageID); err != nil {
			if errors.Is(err, persistence.ErrNotFound) {
				return http.StatusNotFound, fmt.Errorf("message %s not found", messageID)
			}
			return http.StatusInternalServerError, err
		}

	case api.TaskTypeSceneSnapshot:
		value, _ := task.GetParam(api.SnapshotDefinitionIDKey)
		snapshotDefinitionID, _ := value.(string)
		exists, err := tm.persistence.SnapshotDefinitionExists(snapshotDefinitionID)
		if err != nil {
			return http.StatusInternalServerError, err
		}
		if !exists {
			return http.StatusNotFound, fmt.Errorf("snapshot definition %s not found", snapshotDefinitionID)
		}

	case api.TaskTypeSceneActivate:
		setValue, _ := task.GetParam(api.SceneSetIDKey)
		setID, _ := setValue.(string)
		sceneValue, _ := task.GetParam(api.SceneIDKey)
		sceneID, _ := sceneValue.(string)

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
