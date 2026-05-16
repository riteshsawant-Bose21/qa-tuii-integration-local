package tasks

import (
	"fmt"
	"net/http"
	"strings"
	"time"

	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"

	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"
)

var (
	protoJSONMarshalOptions = protojson.MarshalOptions{
		UseProtoNames:   true,
		EmitUnpopulated: false,
	}
	protoJSONUnmarshalOptions = protojson.UnmarshalOptions{
		DiscardUnknown: false,
	}
)

func recurringWindowFromProto(window *model.RecurringWindow) *api.RecurringWindow {
	return window
}

func timeFromProto(ts *timestamppb.Timestamp) time.Time {
	if ts == nil {
		return time.Time{}
	}
	return ts.AsTime()
}

func writeProtoJSON(w http.ResponseWriter, msg proto.Message) error {
	data, err := protoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}

	_, err = w.Write(data)
	return err
}

func snapshotCreateRequestToTask(req *model.SnapshotTaskCreateRequest) *api.Task {
	task := &api.Task{}
	task.Id = req.Id
	task.Description = req.Description
	task.Type = api.TaskTypeSnapshot
	task.CronExpr = req.CronExpr
	task.StartAt = req.StartAt
	task.EndAt = req.EndAt
	task.Recurrence = req.Recurrence
	task.Enabled = true
	_ = task.SetParam(api.SnapshotIDKey, req.SnapshotId)
	return task
}

func messageCreateRequestToTask(req *model.MessageTaskCreateRequest) *api.Task {
	task := &api.Task{}
	task.Id = req.Id
	task.Description = req.Description
	task.Type = api.TaskTypeMessage
	task.CronExpr = req.CronExpr
	task.StartAt = req.StartAt
	task.EndAt = req.EndAt
	task.Recurrence = req.Recurrence
	task.Enabled = true
	_ = task.SetParam(api.MessageIDKey, req.MessageId)
	_ = task.SetParam(api.MessagePriorityKey, req.Priority)
	_ = task.SetParam(api.MessageZonesKey, messageZonesFromProto(req.Zones))
	return task
}

func sceneSnapshotCreateRequestToTask(req *model.SceneSnapshotTaskCreateRequest) *api.Task {
	task := &api.Task{}
	task.Id = req.Id
	task.Description = req.Description
	task.Type = api.TaskTypeSceneSnapshot
	task.CronExpr = req.CronExpr
	task.StartAt = req.StartAt
	task.EndAt = req.EndAt
	task.Recurrence = req.Recurrence
	task.Enabled = true
	_ = task.SetParam(api.SnapshotDefinitionIDKey, req.SnapshotDefinitionId)
	return task
}

func sceneActivateCreateRequestToTask(req *model.SceneActivateTaskCreateRequest) *api.Task {
	task := &api.Task{}
	task.Id = req.Id
	task.Description = req.Description
	task.Type = api.TaskTypeSceneActivate
	task.CronExpr = req.CronExpr
	task.StartAt = req.StartAt
	task.EndAt = req.EndAt
	task.Recurrence = req.Recurrence
	task.Enabled = true
	_ = task.SetParam(api.SceneSetIDKey, req.SetId)
	_ = task.SetParam(api.SceneIDKey, req.SceneId)
	return task
}

func messageZonesFromProto(zones string) []string {
	zones = strings.TrimSpace(zones)
	if zones == "" {
		return []string{}
	}

	if strings.HasPrefix(zones, "[") && strings.HasSuffix(zones, "]") {
		trimmed := strings.TrimSpace(strings.TrimSuffix(strings.TrimPrefix(zones, "["), "]"))
		if trimmed == "" {
			return []string{}
		}
		return strings.Fields(trimmed)
	}

	if strings.Contains(zones, ",") {
		parts := strings.Split(zones, ",")
		out := make([]string, 0, len(parts))
		for _, part := range parts {
			part = strings.TrimSpace(part)
			if part != "" {
				out = append(out, part)
			}
		}
		return out
	}

	return []string{zones}
}

func messageZonesToProto(value any) string {
	var zones []string
	switch v := value.(type) {
	case []string:
		zones = v
	case []interface{}:
		zones = make([]string, 0, len(v))
		for _, item := range v {
			s, ok := item.(string)
			if ok && strings.TrimSpace(s) != "" {
				zones = append(zones, strings.TrimSpace(s))
			}
		}
	default:
		zones = messageZonesFromProto(fmt.Sprintf("%v", value))
	}

	return strings.Join(zones, ",")
}

func taskToProto(task *api.Task) (*model.Task, error) {
	if task == nil {
		return nil, fmt.Errorf("task is nil")
	}

	enabled := task.Enabled
	scheduled := task.CronEntryID != 0
	if startAt := task.StartAtTime(); !startAt.IsZero() && nowFunction().Before(startAt) {
		scheduled = false
	}
	if endAt := task.EndAtTime(); enabled && !endAt.IsZero() && nowFunction().After(endAt) {
		enabled = false
		scheduled = false
	}

	out := proto.Clone(&task.Task).(*model.Task)
	out.Enabled = enabled
	out.Scheduled = scheduled

	switch task.Type {
	case api.TaskTypeSnapshot:
		snapshotID, ok := task.GetParam(api.SnapshotIDKey)
		if !ok {
			return nil, fmt.Errorf("task %q missing snapshot_id", task.Id)
		}
		out.Details = &model.Task_Snapshot{
			Snapshot: &model.SnapshotTaskDetails{
				SnapshotId: fmt.Sprintf("%v", snapshotID),
			},
		}
	case api.TaskTypeMessage:
		messageID, ok := task.GetParam(api.MessageIDKey)
		if !ok {
			return nil, fmt.Errorf("task %q missing message_id", task.Id)
		}

		priorityValue, ok := task.GetParam(api.MessagePriorityKey)
		if !ok {
			return nil, fmt.Errorf("task %q missing priority", task.Id)
		}
		priority, err := int64Param(priorityValue)
		if err != nil {
			return nil, fmt.Errorf("task %q invalid priority: %w", task.Id, err)
		}

		zones, ok := task.GetParam(api.MessageZonesKey)
		if !ok {
			return nil, fmt.Errorf("task %q missing zones", task.Id)
		}

		out.Details = &model.Task_Message{
			Message: &model.MessageTaskDetails{
				MessageId: fmt.Sprintf("%v", messageID),
				Priority:  priority,
				Zones:     messageZonesToProto(zones),
			},
		}
	case api.TaskTypeSceneSnapshot:
		snapshotDefinitionID, ok := task.GetParam(api.SnapshotDefinitionIDKey)
		if !ok {
			return nil, fmt.Errorf("task %q missing snapshot_definition_id", task.Id)
		}
		out.Details = &model.Task_SceneSnapshot{
			SceneSnapshot: &model.SceneSnapshotTaskDetails{
				SnapshotDefinitionId: fmt.Sprintf("%v", snapshotDefinitionID),
			},
		}
	case api.TaskTypeSceneActivate:
		setID, ok := task.GetParam(api.SceneSetIDKey)
		if !ok {
			return nil, fmt.Errorf("task %q missing set_id", task.Id)
		}

		sceneID, ok := task.GetParam(api.SceneIDKey)
		if !ok {
			return nil, fmt.Errorf("task %q missing scene_id", task.Id)
		}

		out.Details = &model.Task_SceneActivate{
			SceneActivate: &model.SceneActivateTaskDetails{
				SetId:   fmt.Sprintf("%v", setID),
				SceneId: fmt.Sprintf("%v", sceneID),
			},
		}
	default:
		return nil, fmt.Errorf("unsupported task type %q", task.Type)
	}

	return out, nil
}

func tasksToProto(tasks []*api.Task) (*model.TaskListResponse, error) {
	resp := &model.TaskListResponse{
		Tasks: make([]*model.Task, 0, len(tasks)),
	}

	for _, task := range tasks {
		taskMsg, err := taskToProto(task)
		if err != nil {
			return nil, err
		}
		resp.Tasks = append(resp.Tasks, taskMsg)
	}

	return resp, nil
}

func historyToProto(history []ExecutionRecord) *model.TaskHistoryResponse {
	resp := &model.TaskHistoryResponse{
		History: make([]*model.TaskExecutionRecord, 0, len(history)),
	}

	for _, entry := range history {
		resp.History = append(resp.History, &model.TaskExecutionRecord{
			Description: entry.Description,
			Status:      entry.Status,
			TaskId:      entry.TaskID,
			Timestamp:   timestamppb.New(entry.Timestamp),
		})
	}

	return resp
}

func int64Param(value any) (int64, error) {
	switch v := value.(type) {
	case int64:
		return v, nil
	case int:
		return int64(v), nil
	case float64:
		return int64(v), nil
	case float32:
		return int64(v), nil
	default:
		return 0, fmt.Errorf("unsupported numeric type %T", value)
	}
}
