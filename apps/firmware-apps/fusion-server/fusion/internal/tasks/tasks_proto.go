package tasks

import (
	"fmt"
	"net/http"
	"time"

	"fusion/internal/api"
	fusionpb "fusion/internal/gen/proto/fusion"

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

func writeProtoJSON(w http.ResponseWriter, msg proto.Message) error {
	data, err := protoJSONMarshalOptions.Marshal(msg)
	if err != nil {
		return err
	}

	_, err = w.Write(data)
	return err
}

func recurringWindowToProto(window *api.RecurringWindow) *fusionpb.RecurringWindow {
	if window == nil {
		return nil
	}

	days := make([]int32, len(window.Days))
	for i, day := range window.Days {
		days[i] = int32(day)
	}

	return &fusionpb.RecurringWindow{
		StartTime: window.StartTime,
		EndTime:   window.EndTime,
		Days:      days,
	}
}

func recurringWindowFromProto(window *fusionpb.RecurringWindow) *api.RecurringWindow {
	if window == nil {
		return nil
	}

	days := make([]int, len(window.Days))
	for i, day := range window.Days {
		days[i] = int(day)
	}

	return &api.RecurringWindow{
		StartTime: window.StartTime,
		EndTime:   window.EndTime,
		Days:      days,
	}
}

func timeToProto(ts time.Time) *timestamppb.Timestamp {
	if ts.IsZero() {
		return nil
	}
	return timestamppb.New(ts)
}

func timeFromProto(ts *timestamppb.Timestamp) time.Time {
	if ts == nil {
		return time.Time{}
	}
	return ts.AsTime()
}

func snapshotCreateRequestToTask(req *fusionpb.SnapshotTaskCreateRequest) *api.Task {
	return &api.Task{
		ID:          req.Id,
		Description: req.Description,
		Type:        api.TaskTypeSnapshot,
		CronExpr:    req.CronExpr,
		StartAt:     timeFromProto(req.StartAt),
		EndAt:       timeFromProto(req.EndAt),
		Recurrence:  recurringWindowFromProto(req.Recurrence),
		Enabled:     true,
		Params: map[string]any{
			api.SnapshotIDKey: req.SnapshotId,
		},
	}
}

func messageCreateRequestToTask(req *fusionpb.MessageTaskCreateRequest) *api.Task {
	return &api.Task{
		ID:          req.Id,
		Description: req.Description,
		Type:        api.TaskTypeMessage,
		CronExpr:    req.CronExpr,
		StartAt:     timeFromProto(req.StartAt),
		EndAt:       timeFromProto(req.EndAt),
		Recurrence:  recurringWindowFromProto(req.Recurrence),
		Enabled:     true,
		Params: map[string]any{
			api.MessageIDKey:       req.MessageId,
			api.MessagePriorityKey: req.Priority,
			api.MessageZonesKey:    req.Zones,
		},
	}
}

func taskToProto(task *api.Task) (*fusionpb.Task, error) {
	if task == nil {
		return nil, fmt.Errorf("task is nil")
	}

	out := &fusionpb.Task{
		Id:          task.ID,
		Description: task.Description,
		CronExpr:    task.CronExpr,
		StartAt:     timeToProto(task.StartAt),
		EndAt:       timeToProto(task.EndAt),
		Recurrence:  recurringWindowToProto(task.Recurrence),
		Enabled:     task.Enabled,
		Scheduled:   task.CronEntryID != 0,
	}

	switch task.Type {
	case api.TaskTypeSnapshot:
		out.Type = fusionpb.TaskType_TASK_TYPE_SNAPSHOT
		snapshotID, ok := task.Params[api.SnapshotIDKey]
		if !ok {
			return nil, fmt.Errorf("task %q missing snapshot_id", task.ID)
		}
		out.Details = &fusionpb.Task_Snapshot{
			Snapshot: &fusionpb.SnapshotTaskDetails{
				SnapshotId: fmt.Sprintf("%v", snapshotID),
			},
		}
	case api.TaskTypeMessage:
		out.Type = fusionpb.TaskType_TASK_TYPE_MESSAGE

		messageID, ok := task.Params[api.MessageIDKey]
		if !ok {
			return nil, fmt.Errorf("task %q missing message_id", task.ID)
		}

		priority, err := int64Param(task.Params[api.MessagePriorityKey])
		if err != nil {
			return nil, fmt.Errorf("task %q invalid priority: %w", task.ID, err)
		}

		zones, ok := task.Params[api.MessageZonesKey]
		if !ok {
			return nil, fmt.Errorf("task %q missing zones", task.ID)
		}

		out.Details = &fusionpb.Task_Message{
			Message: &fusionpb.MessageTaskDetails{
				MessageId: fmt.Sprintf("%v", messageID),
				Priority:  priority,
				Zones:     fmt.Sprintf("%v", zones),
			},
		}
	default:
		return nil, fmt.Errorf("unsupported task type %q", task.Type)
	}

	return out, nil
}

func tasksToProto(tasks []api.Task) (*fusionpb.TaskListResponse, error) {
	resp := &fusionpb.TaskListResponse{
		Tasks: make([]*fusionpb.Task, 0, len(tasks)),
	}

	for i := range tasks {
		taskMsg, err := taskToProto(&tasks[i])
		if err != nil {
			return nil, err
		}
		resp.Tasks = append(resp.Tasks, taskMsg)
	}

	return resp, nil
}

func historyToProto(history []ExecutionRecord) *fusionpb.TaskHistoryResponse {
	resp := &fusionpb.TaskHistoryResponse{
		History: make([]*fusionpb.TaskExecutionRecord, 0, len(history)),
	}

	for _, entry := range history {
		resp.History = append(resp.History, &fusionpb.TaskExecutionRecord{
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
