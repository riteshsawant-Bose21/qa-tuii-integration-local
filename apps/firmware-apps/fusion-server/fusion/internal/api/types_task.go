package api

import (
	"fmt"
	model "fusion/internal/gen/proto/fusion"
	"strings"
	"time"

	json "github.com/goccy/go-json"
	"github.com/robfig/cron/v3"
	"google.golang.org/protobuf/types/known/timestamppb"
)

// Snapshot, scene, and task types.

// SnapshotOperation represents a snapshot operation broadcast across the cluster.
type SnapshotOperation struct {
	Name      string    `json:"name"`
	Timestamp time.Time `json:"timestamp"`
}

// SceneSetOperation represents a scene-set operation broadcast across the cluster.
type SceneSetOperation struct {
	SetID     string    `json:"set_id"`
	Timestamp time.Time `json:"timestamp"`
}

// SceneOperation represents a scene operation broadcast across the cluster.
type SceneOperation struct {
	SceneID   string    `json:"scene_id"`
	Timestamp time.Time `json:"timestamp"`
}

// ActivateSnapshotRequest is the request body for snapshot activation.
type ActivateSnapshotRequest struct {
	ID string `json:"id"`
}

// ActivateSceneSetRequest is the request body for scene activation in a set.
type ActivateSceneSetRequest struct {
	SetID   string `json:"set_id"`
	SceneID string `json:"scene_id"`
}

// RecurringWindow contains info to manage recurring tasks.
type RecurringWindow = model.RecurringWindow

const (
	TaskTypeMessage       = model.TaskType_TASK_TYPE_MESSAGE
	TaskTypeSnapshot      = model.TaskType_TASK_TYPE_SNAPSHOT
	TaskTypeSceneSnapshot = model.TaskType_TASK_TYPE_SCENE_SNAPSHOT
	TaskTypeSceneActivate = model.TaskType_TASK_TYPE_SCENE_ACTIVATE
)

type taskJSON struct {
	ID          string           `json:"id"`
	Description string           `json:"description"`
	Type        string           `json:"type"`
	CronExpr    string           `json:"cron_expr"`
	StartAt     time.Time        `json:"start_at"`
	EndAt       time.Time        `json:"end_at"`
	Recurrence  *RecurringWindow `json:"recurrence,omitempty"`
	Params      map[string]any   `json:"params"`
	Enabled     bool             `json:"enabled"`
	Scheduled   bool             `json:"scheduled,omitempty"`
}

// Task wraps the protobuf task with runtime-only scheduler state.
type Task struct {
	model.Task  `json:"-"`
	CronEntryID cron.EntryID `json:"-"`
}

func (t *Task) StartAtTime() time.Time {
	if t == nil || t.StartAt == nil {
		return time.Time{}
	}
	return t.StartAt.AsTime()
}

func (t *Task) EndAtTime() time.Time {
	if t == nil || t.EndAt == nil {
		return time.Time{}
	}
	return t.EndAt.AsTime()
}

func (t *Task) SetStartAtTime(ts time.Time) {
	if ts.IsZero() {
		t.StartAt = nil
		return
	}
	t.StartAt = timestamppb.New(ts)
}

func (t *Task) SetEndAtTime(ts time.Time) {
	if ts.IsZero() {
		t.EndAt = nil
		return
	}
	t.EndAt = timestamppb.New(ts)
}

func (t *Task) GetParam(key string) (any, bool) {
	if t == nil {
		return nil, false
	}

	switch key {
	case SnapshotIDKey:
		if d := t.GetSnapshot(); d != nil && d.SnapshotId != "" {
			return d.SnapshotId, true
		}
	case MessageIDKey:
		if d := t.GetMessage(); d != nil && d.MessageId != "" {
			return d.MessageId, true
		}
	case MessagePriorityKey:
		if d := t.GetMessage(); d != nil {
			return d.Priority, true
		}
	case MessageZonesKey:
		if d := t.GetMessage(); d != nil {
			return parseZones(d.Zones), true
		}
	case SnapshotDefinitionIDKey:
		if d := t.GetSceneSnapshot(); d != nil && d.SnapshotDefinitionId != "" {
			return d.SnapshotDefinitionId, true
		}
	case SceneSetIDKey:
		if d := t.GetSceneActivate(); d != nil && d.SetId != "" {
			return d.SetId, true
		}
	case SceneIDKey:
		if d := t.GetSceneActivate(); d != nil && d.SceneId != "" {
			return d.SceneId, true
		}
	}

	return nil, false
}

func (t *Task) SetParam(key string, value any) error {
	switch key {
	case SnapshotIDKey:
		d, err := t.ensureSnapshotDetails()
		if err != nil {
			return err
		}
		d.SnapshotId = fmt.Sprintf("%v", value)
	case MessageIDKey:
		d, err := t.ensureMessageDetails()
		if err != nil {
			return err
		}
		d.MessageId = fmt.Sprintf("%v", value)
	case MessagePriorityKey:
		d, err := t.ensureMessageDetails()
		if err != nil {
			return err
		}
		switch v := value.(type) {
		case int64:
			d.Priority = v
		case int:
			d.Priority = int64(v)
		case float64:
			d.Priority = int64(v)
		case float32:
			d.Priority = int64(v)
		default:
			return fmt.Errorf("invalid priority type %T", value)
		}
	case MessageZonesKey:
		d, err := t.ensureMessageDetails()
		if err != nil {
			return err
		}
		d.Zones = stringifyZones(value)
	case SnapshotDefinitionIDKey:
		d, err := t.ensureSceneSnapshotDetails()
		if err != nil {
			return err
		}
		d.SnapshotDefinitionId = fmt.Sprintf("%v", value)
	case SceneSetIDKey:
		d, err := t.ensureSceneActivateDetails()
		if err != nil {
			return err
		}
		d.SetId = fmt.Sprintf("%v", value)
	case SceneIDKey:
		d, err := t.ensureSceneActivateDetails()
		if err != nil {
			return err
		}
		d.SceneId = fmt.Sprintf("%v", value)
	default:
		return fmt.Errorf("unsupported task param %q", key)
	}

	return nil
}

func (t *Task) ParamsMap() map[string]any {
	params := map[string]any{}
	for _, key := range []string{
		SnapshotIDKey,
		MessageIDKey,
		MessagePriorityKey,
		MessageZonesKey,
		SnapshotDefinitionIDKey,
		SceneSetIDKey,
		SceneIDKey,
	} {
		if v, ok := t.GetParam(key); ok {
			params[key] = v
		}
	}
	return params
}

func (t *Task) MarshalJSON() ([]byte, error) {
	return json.Marshal(taskJSON{
		ID:          t.Id,
		Description: t.Description,
		Type:        taskTypeString(t.Type),
		CronExpr:    t.CronExpr,
		StartAt:     t.StartAtTime(),
		EndAt:       t.EndAtTime(),
		Recurrence:  t.Recurrence,
		Params:      t.ParamsMap(),
		Enabled:     t.Enabled,
		Scheduled:   t.Scheduled,
	})
}

func (t *Task) UnmarshalJSON(data []byte) error {
	var raw taskJSON
	if err := json.Unmarshal(data, &raw); err != nil {
		return err
	}

	t.Task = model.Task{
		Id:          raw.ID,
		Description: raw.Description,
		Type:        parseTaskType(raw.Type),
		CronExpr:    raw.CronExpr,
		Recurrence:  raw.Recurrence,
		Enabled:     raw.Enabled,
		Scheduled:   raw.Scheduled,
	}
	t.SetStartAtTime(raw.StartAt)
	t.SetEndAtTime(raw.EndAt)

	for key, value := range raw.Params {
		if err := t.SetParam(key, value); err != nil {
			return err
		}
	}

	return nil
}

func (t *Task) ensureSnapshotDetails() (*model.SnapshotTaskDetails, error) {
	if t.Type != TaskTypeSnapshot {
		return nil, fmt.Errorf("task type %v does not support snapshot params", t.Type)
	}
	if d := t.GetSnapshot(); d != nil {
		return d, nil
	}
	d := &model.SnapshotTaskDetails{}
	t.Details = &model.Task_Snapshot{Snapshot: d}
	return d, nil
}

func (t *Task) ensureMessageDetails() (*model.MessageTaskDetails, error) {
	if t.Type != TaskTypeMessage {
		return nil, fmt.Errorf("task type %v does not support message params", t.Type)
	}
	if d := t.GetMessage(); d != nil {
		return d, nil
	}
	d := &model.MessageTaskDetails{}
	t.Details = &model.Task_Message{Message: d}
	return d, nil
}

func (t *Task) ensureSceneSnapshotDetails() (*model.SceneSnapshotTaskDetails, error) {
	if t.Type != TaskTypeSceneSnapshot {
		return nil, fmt.Errorf("task type %v does not support scene snapshot params", t.Type)
	}
	if d := t.GetSceneSnapshot(); d != nil {
		return d, nil
	}
	d := &model.SceneSnapshotTaskDetails{}
	t.Details = &model.Task_SceneSnapshot{SceneSnapshot: d}
	return d, nil
}

func (t *Task) ensureSceneActivateDetails() (*model.SceneActivateTaskDetails, error) {
	if t.Type != TaskTypeSceneActivate {
		return nil, fmt.Errorf("task type %v does not support scene activate params", t.Type)
	}
	if d := t.GetSceneActivate(); d != nil {
		return d, nil
	}
	d := &model.SceneActivateTaskDetails{}
	t.Details = &model.Task_SceneActivate{SceneActivate: d}
	return d, nil
}

func taskTypeString(taskType model.TaskType) string {
	switch taskType {
	case TaskTypeSnapshot:
		return "snapshot"
	case TaskTypeMessage:
		return "message"
	case TaskTypeSceneSnapshot:
		return "scene_snapshot"
	case TaskTypeSceneActivate:
		return "scene_activate"
	default:
		return ""
	}
}

func parseTaskType(value string) model.TaskType {
	switch value {
	case "snapshot":
		return TaskTypeSnapshot
	case "message":
		return TaskTypeMessage
	case "scene_snapshot":
		return TaskTypeSceneSnapshot
	case "scene_activate":
		return TaskTypeSceneActivate
	default:
		return model.TaskType_TASK_TYPE_UNSPECIFIED
	}
}

func parseZones(value string) []string {
	if value == "" {
		return []string{}
	}
	out := []string{}
	for _, part := range strings.Split(value, ",") {
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	return out
}

func stringifyZones(value any) string {
	switch v := value.(type) {
	case []string:
		return strings.Join(v, ",")
	case []any:
		out := make([]string, 0, len(v))
		for _, item := range v {
			s := strings.TrimSpace(fmt.Sprintf("%v", item))
			if s != "" {
				out = append(out, s)
			}
		}
		return strings.Join(out, ",")
	default:
		return strings.TrimSpace(fmt.Sprintf("%v", value))
	}
}
