package tasks

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/persistence"

	"github.com/stretchr/testify/require"
)

func TestRecordExecutionDebouncesHistoryFlush(t *testing.T) {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "tasks-history-test",
		LogDir:      t.TempDir(),
		MaxFileSize: 10,
		MaxFiles:    2,
		LogLevel:    logging.ERROR,
	})

	dir := t.TempDir()
	historyPath := filepath.Join(dir, "history.json")
	prevAudioDir := api.AudioFilesLocation
	api.AudioFilesLocation = filepath.Join(dir, "audio")
	require.NoError(t, os.MkdirAll(api.AudioFilesLocation, 0755))
	t.Cleanup(func() {
		api.AudioFilesLocation = prevAudioDir
	})

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test-node"})
	p, err := persistence.NewPersistence(filepath.Join(dir, "tasks.db"), sm)
	require.NoError(t, err)
	defer p.Close()

	tm := NewTaskManager(&api.AppConfig{NodeName: "test-node"}, p, nil, nil)
	tm.historyFilePath = historyPath

	task := &api.Task{Task: model.Task{Id: "task-1", Description: "test"}}

	tm.RecordExecution(task, "success")
	_, err = os.Stat(historyPath)
	require.Error(t, err)
	require.True(t, os.IsNotExist(err))

	time.Sleep(historyFlushDebounce / 2)
	tm.RecordExecution(task, "failed")
	_, err = os.Stat(historyPath)
	require.Error(t, err)
	require.True(t, os.IsNotExist(err))

	time.Sleep(historyFlushDebounce + 300*time.Millisecond)

	require.Len(t, tm.GetExecutionHistory(), 2)

	data, err := os.ReadFile(historyPath)
	require.NoError(t, err)
	content := string(data)
	require.Contains(t, content, `"task_id": "task-1"`)
	require.Equal(t, 1, strings.Count(content, `"task_id": "task-1"`))
	require.Contains(t, content, `"status": "failed"`)
	require.NotContains(t, content, `"status": "success"`)
}
