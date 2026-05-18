package tasks

import (
	"path/filepath"
	"testing"

	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/persistence"
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
			task := &api.Task{Task: model.Task{Type: api.TaskTypeSceneSnapshot}}
			for key, value := range tt.params {
				_ = task.SetParam(key, value)
			}
			_, err := tm.makeTaskFunc(task)
			if err == nil {
				t.Fatalf("expected error for %s", tt.name)
			}
		})
	}
}

func TestMakeTaskFunc_AcceptsValidRequiredParams(t *testing.T) {
	tests := []struct {
		name string
		task *api.Task
	}{
		{
			name: "message",
			task: func() *api.Task {
				task := &api.Task{Task: model.Task{Type: api.TaskTypeMessage}}
				_ = task.SetParam(api.MessageIDKey, "message-1")
				return task
			}(),
		},
		{
			name: "snapshot",
			task: func() *api.Task {
				task := &api.Task{Task: model.Task{Type: api.TaskTypeSnapshot}}
				_ = task.SetParam(api.SnapshotIDKey, "snapshot-1")
				return task
			}(),
		},
		{
			name: "scene snapshot",
			task: func() *api.Task {
				task := &api.Task{Task: model.Task{Type: api.TaskTypeSceneSnapshot}}
				_ = task.SetParam(api.SnapshotDefinitionIDKey, "definition-1")
				return task
			}(),
		},
		{
			name: "scene activate",
			task: func() *api.Task {
				task := &api.Task{Task: model.Task{Type: api.TaskTypeSceneActivate}}
				_ = task.SetParam(api.SceneSetIDKey, "set-1")
				_ = task.SetParam(api.SceneIDKey, "scene-1")
				return task
			}(),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tm := &TaskManager{}
			if tt.task.Type == api.TaskTypeSnapshot {
				tmpDir := t.TempDir()
				prevAudioDir := api.AudioFilesLocation
				api.AudioFilesLocation = filepath.Join(tmpDir, "audio")
				t.Cleanup(func() {
					api.AudioFilesLocation = prevAudioDir
				})

				sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test-node"})
				p, err := persistence.NewPersistence(filepath.Join(tmpDir, "tasks.db"), sm)
				if err != nil {
					t.Fatalf("failed to create persistence: %v", err)
				}
				t.Cleanup(func() {
					p.Close()
				})
				if err := p.CreateSnapshot("snapshot-1"); err != nil {
					t.Fatalf("failed to seed snapshot: %v", err)
				}
				tm.persistence = p
			}
			_, err := tm.makeTaskFunc(tt.task)
			if err != nil {
				t.Fatalf("expected no error, got %v", err)
			}
		})
	}
}
