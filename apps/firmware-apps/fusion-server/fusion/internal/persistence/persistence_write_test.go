package persistence

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion-services-core/logging"

	"github.com/stretchr/testify/require"
)

var initTestLogger sync.Once

func newTestPersistence(t *testing.T, dbPath string) *Persistence {
	t.Helper()

	initTestLogger.Do(func() {
		logging.InitLogger(logging.LogConfig{
			NodeName:    "persistence-test",
			LogDir:      t.TempDir(),
			MaxFileSize: 10,
			MaxFiles:    2,
			LogLevel:    logging.ERROR,
		})
	})

	sm := NewStateManager(&api.AppConfig{NodeName: "test-node"})
	p, err := NewPersistence(dbPath, sm)
	require.NoError(t, err)
	return p
}

func readDBBytes(t *testing.T, dbPath string) []byte {
	t.Helper()

	data, err := os.ReadFile(dbPath)
	require.NoError(t, err)
	return data
}

func stableDBSnapshot(t *testing.T, p *Persistence, dbPath string) []byte {
	t.Helper()
	require.NoError(t, p.db.Sync())
	return readDBBytes(t, dbPath)
}

func TestSaveTasksPersistsFullAndDeletesMissing(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "tasks_test.db")

	p := newTestPersistence(t, dbPath)
	defer p.Close()

	original := map[string]*api.Task{
		"one": {ID: "one", CronExpr: "* * * * *", Description: "t1", Type: api.TaskTypeSnapshot},
		"two": {ID: "two", CronExpr: "* * * * *", Description: "t2", Type: api.TaskTypeSnapshot},
	}
	require.NoError(t, p.SaveTasks(original))

	loaded, err := p.LoadTasks()
	require.NoError(t, err)
	require.Len(t, loaded, 2)

	delete(original, "one")
	require.NoError(t, p.SaveTasks(original))

	loaded2, err := p.LoadTasks()
	require.NoError(t, err)
	require.Len(t, loaded2, 1)
	require.NotNil(t, loaded2["two"])
	require.Nil(t, loaded2["one"])
}

func TestPersistenceCompactsDatabaseOnReopen(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "compact_test.db")

	p := newTestPersistence(t, dbPath)

	largeTasks := make(map[string]*api.Task)
	for i := 0; i < 48; i++ {
		id := fmt.Sprintf("task-%03d", i)
		largeTasks[id] = &api.Task{
			ID:          id,
			CronExpr:    "* * * * *",
			Description: strings.Repeat("payload-", 4096),
			Type:        api.TaskTypeSnapshot,
		}
	}
	require.NoError(t, p.SaveTasks(largeTasks))

	trimmed := map[string]*api.Task{}
	for id, task := range largeTasks {
		trimmed[id] = task
		break
	}
	require.NoError(t, p.SaveTasks(trimmed))

	freeBytes, ratio, err := p.compactionEstimate()
	require.NoError(t, err)
	require.GreaterOrEqual(t, freeBytes, int64(compactMinFreeBytes))
	require.GreaterOrEqual(t, ratio, compactMinFreeRatio)

	beforeInfo, err := os.Stat(dbPath)
	require.NoError(t, err)

	p.Close()

	reopened := newTestPersistence(t, dbPath)
	defer reopened.Close()

	afterInfo, err := os.Stat(dbPath)
	require.NoError(t, err)

	require.Less(t, afterInfo.Size(), beforeInfo.Size())

	loaded, err := reopened.LoadTasks()
	require.NoError(t, err)
	require.Len(t, loaded, 1)
}

func TestSaveTasksNoOpDoesNotRewriteDatabase(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "tasks_noop.db")

	p := newTestPersistence(t, dbPath)
	defer p.Close()

	tasks := map[string]*api.Task{
		"one": {ID: "one", CronExpr: "* * * * *", Description: "t1", Type: api.TaskTypeSnapshot},
	}
	require.NoError(t, p.SaveTasks(tasks))
	before := stableDBSnapshot(t, p, dbPath)

	time.Sleep(10 * time.Millisecond)
	require.NoError(t, p.SaveTasks(tasks))
	after := stableDBSnapshot(t, p, dbPath)

	require.True(t, bytes.Equal(before, after))
}

func TestSaveAudioMetaNoOpDoesNotRewriteDatabase(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "audio_noop.db")

	p := newTestPersistence(t, dbPath)
	defer p.Close()

	meta := &api.AudioMetadata{
		Id:          "audio-1",
		DisplayName: "Audio 1",
		Filename:    "audio-1.wav",
		MimeType:    "audio/wav",
		Uploaded:    time.Unix(1700000000, 0).UTC(),
		SizeBytes:   1234,
		Checksum:    "abc",
	}
	require.NoError(t, p.SaveAudioMeta(meta))
	before := stableDBSnapshot(t, p, dbPath)

	time.Sleep(10 * time.Millisecond)
	require.NoError(t, p.SaveAudioMeta(meta))
	after := stableDBSnapshot(t, p, dbPath)

	require.True(t, bytes.Equal(before, after))
}

func TestSetDeviceInfoNoOpDoesNotRewriteDatabase(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "device_noop.db")

	p := newTestPersistence(t, dbPath)
	defer p.Close()

	name := "Fusion"
	info := &api.DevicePatch{Name: &name}
	require.NoError(t, p.SetDeviceInfo(info))
	before := stableDBSnapshot(t, p, dbPath)

	time.Sleep(10 * time.Millisecond)
	require.NoError(t, p.SetDeviceInfo(info))
	after := stableDBSnapshot(t, p, dbPath)

	require.True(t, bytes.Equal(before, after))
}

func TestDeleteMissingRecordsAreNoOps(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "delete_noop.db")

	p := newTestPersistence(t, dbPath)
	defer p.Close()

	before := stableDBSnapshot(t, p, dbPath)

	require.NoError(t, p.DeleteTask("missing-task"))
	require.NoError(t, p.DeleteAudioMetadata("missing-audio"))
	require.NoError(t, p.DeleteSnapshot("missing-snapshot"))

	after := stableDBSnapshot(t, p, dbPath)
	require.True(t, bytes.Equal(before, after))
}

func TestMaybeCompactOnOpenSkipsWhenBelowThreshold(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "compact_skip.db")

	p := newTestPersistence(t, dbPath)
	defer p.Close()

	tasks := map[string]*api.Task{
		"one": {ID: "one", CronExpr: "* * * * *", Description: "small", Type: api.TaskTypeSnapshot},
	}
	require.NoError(t, p.SaveTasks(tasks))

	freeBytes, ratio, err := p.compactionEstimate()
	require.NoError(t, err)
	require.True(t, freeBytes < compactMinFreeBytes || ratio < compactMinFreeRatio)

	before := stableDBSnapshot(t, p, dbPath)
	require.NoError(t, p.maybeCompactOnOpen())
	after := stableDBSnapshot(t, p, dbPath)

	require.True(t, bytes.Equal(before, after))
}

func TestNextSaveDelayRespectsMinimumInterval(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "save_delay.db")

	p := newTestPersistence(t, dbPath)
	defer p.Close()

	p.saveDebounce = 20 * time.Millisecond
	p.minSaveGap = 200 * time.Millisecond
	p.lastSave = time.Now()

	delay := p.nextSaveDelay()
	require.GreaterOrEqual(t, delay, 150*time.Millisecond)
	require.LessOrEqual(t, delay, 200*time.Millisecond)

	p.lastSave = time.Now().Add(-p.minSaveGap - 50*time.Millisecond)
	delay = p.nextSaveDelay()
	require.Equal(t, p.saveDebounce, delay)
}
