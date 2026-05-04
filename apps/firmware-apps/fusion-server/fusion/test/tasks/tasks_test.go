package tasks_test

import (
	"path/filepath"
	"testing"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/tasks"

	"github.com/stretchr/testify/require"
)

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "tasks_unit_test",
		LogDir:      "/tmp/tasks_unit_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.ERROR,
	})
}

func TestAddTaskRejectsSnapshotTaskWithMissingSnapshot(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "tasks_validation.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	tm := tasks.NewTaskManager(&api.AppConfig{NodeName: "node-a"}, p, nil)

	err = tm.AddTask(&api.Task{
		ID:          "snap-task-1",
		CronExpr:    "* * * * *",
		Description: "apply missing snapshot",
		Type:        api.TaskTypeSnapshot,
		Params: map[string]any{
			api.SnapshotIDKey: "does-not-exist",
		},
	})
	require.Error(t, err)
	require.ErrorContains(t, err, `snapshot "does-not-exist" not found`)
}

func TestLoadTasksDisablesInvalidPersistedSnapshotTask(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "tasks_load_validation.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	require.NoError(t, p.SaveTasks(map[string]*api.Task{
		"bad-task": {
			ID:          "bad-task",
			CronExpr:    "* * * * *",
			Description: "apply missing snapshot",
			Type:        api.TaskTypeSnapshot,
			Enabled:     true,
			Params: map[string]any{
				api.SnapshotIDKey: "does-not-exist",
			},
		},
	}))

	tm := tasks.NewTaskManager(&api.AppConfig{NodeName: "node-a"}, p, nil)

	require.NoError(t, tm.LoadTasks())

	task, err := tm.GetTask("bad-task")
	require.NoError(t, err)
	require.False(t, task.Enabled)
}
