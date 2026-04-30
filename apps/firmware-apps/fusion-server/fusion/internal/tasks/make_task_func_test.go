package tasks

import (
	"testing"

	"fusion/internal/api"
)

func TestMakeTaskFunc_RejectsInvalidSceneSnapshotParams(t *testing.T) {
	tm := &TaskManager{}

	tests := []struct {
		name   string
		params map[string]any
	}{
		{name: "missing key", params: map[string]any{}},
		{name: "nil params", params: nil},
		{name: "non-string value", params: map[string]any{api.SnapshotDefinitionIDKey: 42}},
		{name: "whitespace value", params: map[string]any{api.SnapshotDefinitionIDKey: "   "}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			task := &api.Task{Type: api.TaskTypeSceneSnapshot, Params: tt.params}
			_, err := tm.makeTaskFunc(task)
			if err == nil {
				t.Fatalf("expected error for %s", tt.name)
			}
		})
	}
}

func TestMakeTaskFunc_AcceptsValidRequiredParams(t *testing.T) {
	tm := &TaskManager{}

	tests := []struct {
		name string
		task *api.Task
	}{
		{
			name: "message",
			task: &api.Task{Type: api.TaskTypeMessage, Params: map[string]any{api.MessageIDKey: "message-1"}},
		},
		{
			name: "snapshot",
			task: &api.Task{Type: api.TaskTypeSnapshot, Params: map[string]any{api.SnapshotIDKey: "snapshot-1"}},
		},
		{
			name: "scene snapshot",
			task: &api.Task{Type: api.TaskTypeSceneSnapshot, Params: map[string]any{api.SnapshotDefinitionIDKey: "definition-1"}},
		},
		{
			name: "scene activate",
			task: &api.Task{Type: api.TaskTypeSceneActivate, Params: map[string]any{api.SceneSetIDKey: "set-1", api.SceneIDKey: "scene-1"}},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := tm.makeTaskFunc(tt.task)
			if err != nil {
				t.Fatalf("expected no error, got %v", err)
			}
		})
	}
}
