package persistence_test

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"sync"
	"testing"
	"time"
	"unsafe"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/utils"

	json "github.com/goccy/go-json"
	"github.com/stretchr/testify/require"
	"go.etcd.io/bbolt"
)

const databaseName = "fusion_test.db"

var persistConfig = api.AppConfig{
	NodeName: "test_manager",
	Verbose:  false,
}

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "persistence_unit_test",
		LogDir:      "/tmp/persistence_unit_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.ERROR,
	})

	api.AudioFilesLocation = filepath.Join(os.TempDir(), "fusion_persistence_test_audio")
}

// TestMarkDirtyConcurrent checks for potential race conditions by calling MarkDirty concurrently.
// (Run this test with `go test -race`.)
func TestMarkDirtyConcurrent(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := persistence.NewStateManager(&persistConfig)
	if err := sm.Set("testKey", "testValue"); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	cp, err := persistence.NewPersistence(configPath, sm)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	const numGoroutines = 50
	const iterations = 20
	var wg sync.WaitGroup

	for i := range numGoroutines {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for range iterations {
				cp.MarkDirty()
				time.Sleep(5 * time.Millisecond)
			}
		}(i)
	}
	wg.Wait()

	if err := cp.ValidateState(); err != nil {
		t.Errorf("ValidateState failed: %v", err)
	}

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		t.Errorf("Expected state file %s to exist", configPath)
	}
}

// TestValidateStateFile verifies that after a proper save ValidateState returns without error.
func TestValidateStateFile(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := persistence.NewStateManager(&persistConfig)
	if err := sm.Set("key", "value"); err != nil {
		t.Fatalf("Failed to set state: %v", err)
	}
	cp, err := persistence.NewPersistence(configPath, sm)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	if err := cp.ValidateState(); err != nil {
		t.Fatalf("ValidateState failed: %v", err)
	}
}

// TestChecksumCalculation verifies that the checksum calculated on the state
// remains consistent when the same state is used.
func TestChecksumCalculation(t *testing.T) {
	sm := persistence.NewStateManager(&persistConfig)

	state := map[string]*api.StateEntry{
		"key1": {Data: "value1"},
		"key2": {Data: 42},
	}

	sm.SetState(state)

	filename := "dummy"

	_, err := persistence.NewPersistence(filename, sm)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}
	defer os.Remove(filename)

	fullState := sm.GetFullState()

	checksum, err := utils.JSONChecksum(sm.GetStateMap())
	if err != nil {
		t.Fatalf("JSONChecksum returned error: %v", err)
	}

	if fullState.Checksum != checksum {
		t.Errorf("Expected same checksum for identical state, got %s and %s", fullState.Checksum, checksum)
	}
}

func TestSaveTasksPersistsFullAndDeletesMissing(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "tasks_test.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)

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

func TestSaveStateStoresMetadataHashMatchingCurrentDatabaseContents(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "metadata_hash_test.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test-node"})
	err := sm.Set("test.key", "value")
	require.NoError(t, err)

	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)

	err = p.SaveState()
	require.NoError(t, err)

	p.Close()

	metadata, err := readDatabaseMetadata(dbPath)
	require.NoError(t, err)

	actualHash, err := computeDatabaseHashForTest(dbPath)
	require.NoError(t, err)

	require.Equal(t, actualHash, metadata.Hash)
}

func TestNewPersistenceInitializesMetadataHashMatchingCurrentDatabaseContents(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "metadata_hash_init_test.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test-node"})
	require.NoError(t, sm.Set("test.key", "value"))

	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	metadata, err := readDatabaseMetadataFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	actualHash, err := computeDatabaseHashFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	require.Equal(t, actualHash, metadata.Hash)
}

func TestSyncAudioFileRepairsMissingMetadataWhenFinalFileAlreadyExists(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "audio_sync_test.db")
	audioDir := t.TempDir()

	previousAudioFilesLocation := api.AudioFilesLocation
	api.AudioFilesLocation = audioDir
	t.Cleanup(func() {
		api.AudioFilesLocation = previousAudioFilesLocation
	})

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test-node"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	meta := api.AudioMetadata{
		Id:          "audio-1",
		DisplayName: "Test Audio",
		Filename:    "sync-audio-existing.bin",
		MimeType:    "audio/mpeg",
	}

	finalPath := filepath.Join(api.AudioFilesLocation, meta.Filename)
	partPath := finalPath + ".part"

	t.Cleanup(func() {
		_ = os.Remove(finalPath)
		_ = os.Remove(partPath)
	})

	err = os.MkdirAll(api.AudioFilesLocation, 0755)
	require.NoError(t, err)

	err = os.WriteFile(finalPath, []byte("already-downloaded"), 0644)
	require.NoError(t, err)

	err = os.WriteFile(partPath, []byte("stale-temp-file"), 0644)
	require.NoError(t, err)

	err = p.SyncAudioFile(&api.AudioSyncUpdate{
		Metadata: meta,
		URL:      "http://127.0.0.1:1",
	})
	require.NoError(t, err)

	stored, err := p.GetAudioMetadata(meta.Id)
	require.NoError(t, err)
	require.Equal(t, meta.Id, stored.Id)
	require.Equal(t, meta.Filename, stored.Filename)
}

func TestCloseWhileMarkDirtyIsActiveDoesNotPanic(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "close_race_test.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test-node"})
	require.NoError(t, sm.Set("race.key", "value"))

	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)

	var wg sync.WaitGroup
	stop := make(chan struct{})

	for range 8 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case <-stop:
					return
				default:
					p.MarkDirty()
				}
			}
		}()
	}

	time.Sleep(20 * time.Millisecond)
	p.Close()
	close(stop)
	wg.Wait()
}

func TestActivateSnapshotSurvivesRestartWithoutExplicitSaveState(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "activate_snapshot_restart.db")

	sm1 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	require.NoError(t, sm1.Set("mode", "old"))

	p1, err := persistence.NewPersistence(dbPath, sm1)
	require.NoError(t, err)

	require.NoError(t, p1.SaveState())
	require.NoError(t, p1.CreateSnapshot("old"))

	require.NoError(t, sm1.Set("mode", "new"))
	require.NoError(t, p1.CreateSnapshot("new"))
	require.NoError(t, p1.ActivateSnapshot("new"))

	rawDB := rawBoltDBForTest(t, p1)
	require.NoError(t, rawDB.Close())

	sm2 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p2, err := persistence.NewPersistence(dbPath, sm2)
	require.NoError(t, err)
	defer p2.Close()

	require.NoError(t, p2.LoadActiveSnapshot())

	value, ok := sm2.Get("mode")
	require.True(t, ok)
	require.Equal(t, "new", value)
}

func TestDeleteSnapshotRejectsDefaultSnapshot(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "delete_default_snapshot.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.DeleteSnapshot("default")
	require.Error(t, err)

	exists, err := p.SnapshotExists("default")
	require.NoError(t, err)
	require.True(t, exists)
}

func TestImportDataRejectsSnapshotsWithoutDefault(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_without_default.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	require.NoError(t, sm.Set("mode", "other"))
	require.NoError(t, p.CreateSnapshot("other"))

	exported, err := p.ExportData()
	require.NoError(t, err)

	importData, ok := exported.(map[string]map[string]any)
	require.True(t, ok)

	snapshots := importData["snapshots"]
	require.NotNil(t, snapshots)
	delete(snapshots, "default")

	err = p.ImportData(map[string]any{
		"snapshots": snapshots,
	})
	require.Error(t, err)

	exists, err := p.SnapshotExists("default")
	require.NoError(t, err)
	require.True(t, exists)
}

func TestSaveAudioMetaUpdatesDatabaseHash(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "audio_hash_test.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	meta := &api.AudioMetadata{
		Id:          "audio-1",
		DisplayName: "Audio One",
		Filename:    "audio-one.mp3",
		MimeType:    "audio/mpeg",
	}
	require.NoError(t, p.SaveAudioMeta(meta))

	metadata, err := readDatabaseMetadataFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	actualHash, err := computeDatabaseHashFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	require.Equal(t, actualHash, metadata.Hash)
}

func TestDatabaseHashIgnoresPersistentStateTimestampOnlyDifferences(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "persistent_state_timestamp_hash_test.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	require.NoError(t, sm.Set("mode", "baseline"))

	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	require.NoError(t, p.SaveState())
	require.NoError(t, p.CreateSnapshot("baseline"))

	beforeHash, err := computeDatabaseHashFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	err = rawBoltDBForTest(t, p).Update(func(tx *bbolt.Tx) error {
		for _, bucketName := range []string{"active", "snapshots"} {
			bucket := tx.Bucket([]byte(bucketName))
			if bucket == nil {
				return errors.New("expected bucket to exist")
			}

			if err := bucket.ForEach(func(k, v []byte) error {
				var state persistence.PersistentState
				if err := json.Unmarshal(v, &state); err != nil {
					return err
				}
				state.Timestamp = time.Date(2030, time.January, 2, 3, 4, 5, 0, time.UTC)
				updated, err := json.Marshal(state)
				if err != nil {
					return err
				}
				return bucket.Put(k, updated)
			}); err != nil {
				return err
			}
		}
		return nil
	})
	require.NoError(t, err)

	afterHash, err := computeDatabaseHashFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	require.Equal(t, beforeHash, afterHash)
}

func TestImportDataRejectsSnapshotTaskWithMissingSnapshot(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_bad_snapshot_task.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.ImportData(map[string]any{
		"tasks": map[string]any{
			"bad-task": map[string]any{
				"id":          "bad-task",
				"description": "apply missing snapshot",
				"type":        "snapshot",
				"cron_expr":   "* * * * *",
				"enabled":     true,
				"params": map[string]any{
					api.SnapshotIDKey: "does-not-exist",
				},
			},
		},
	})
	require.Error(t, err)

	_, err = p.GetTask("bad-task")
	require.Error(t, err)
}

func TestDeleteSnapshotRejectsMissingSnapshot(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "delete_missing_snapshot.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.DeleteSnapshot("does-not-exist")
	require.Error(t, err)
}

func TestImportDataRejectsSnapshotsThatWouldOrphanExistingSnapshotTasks(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_orphan_snapshot_tasks.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	require.NoError(t, sm.Set("mode", "other"))
	require.NoError(t, p.CreateSnapshot("other"))
	require.NoError(t, p.SaveTasks(map[string]*api.Task{
		"task-1": {
			ID:          "task-1",
			Description: "apply other snapshot",
			Type:        api.TaskTypeSnapshot,
			CronExpr:    "* * * * *",
			Enabled:     true,
			Params: map[string]any{
				api.SnapshotIDKey: "other",
			},
		},
	}))

	err = p.ImportData(map[string]any{
		"snapshots": map[string]any{
			"default": map[string]any{
				"version":   map[string]any{"epoch": 0, "counter": 0, "node_id": "node-a"},
				"timestamp": time.Now().UTC(),
				"checksum":  "",
				"state":     map[string]any{},
			},
		},
	})
	require.Error(t, err)

	exists, err := p.SnapshotExists("other")
	require.NoError(t, err)
	require.True(t, exists)
}

func TestImportDataAcceptsSelfContainedSnapshotsAndTasksBundle(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_self_contained_bundle.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.ImportData(map[string]any{
		"snapshots": map[string]any{
			"default": map[string]any{
				"version":   map[string]any{"epoch": 0, "counter": 0, "node_id": "node-a"},
				"timestamp": time.Now().UTC(),
				"checksum":  "",
				"state":     map[string]any{},
			},
			"other": map[string]any{
				"version":   map[string]any{"epoch": 0, "counter": 1, "node_id": "node-a"},
				"timestamp": time.Now().UTC(),
				"checksum":  "",
				"state":     map[string]any{},
			},
		},
		"tasks": map[string]any{
			"task-1": map[string]any{
				"id":          "task-1",
				"description": "apply other snapshot",
				"type":        "snapshot",
				"cron_expr":   "* * * * *",
				"enabled":     true,
				"params": map[string]any{
					api.SnapshotIDKey: "other",
				},
			},
		},
	})
	require.NoError(t, err)

	exists, err := p.SnapshotExists("other")
	require.NoError(t, err)
	require.True(t, exists)

	task, err := p.GetTask("task-1")
	require.NoError(t, err)
	require.Equal(t, "other", task.Params[api.SnapshotIDKey])
}

func TestImportDataIsAtomicWhenLaterSectionFails(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_atomicity.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	require.NoError(t, sm.Set("mode", "old"))

	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	require.NoError(t, p.SaveState())

	err = p.ImportData(map[string]any{
		"snapshots": map[string]any{
			"default": map[string]any{
				"version":   map[string]any{"epoch": 0, "counter": 1, "node_id": "node-a"},
				"timestamp": time.Now().UTC(),
				"checksum":  "",
				"state": map[string]any{
					"mode": map[string]any{
						"data":    "new",
						"version": map[string]any{"epoch": 0, "counter": 1, "node_id": "node-a"},
					},
				},
			},
		},
		"tasks": "not-a-task-map",
	})
	require.Error(t, err)

	snapshot, err := p.GetSnapshot("default")
	require.NoError(t, err)

	stateMap, ok := snapshot.(map[string]any)
	require.True(t, ok)
	require.Equal(t, "old", stateMap["mode"])
}

func TestImportDataRefreshesActiveStateForRestartRecovery(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_refreshes_active_state.db")

	sm1 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	require.NoError(t, sm1.Set("mode", "old"))

	p1, err := persistence.NewPersistence(dbPath, sm1)
	require.NoError(t, err)

	require.NoError(t, p1.SaveState())

	err = p1.ImportData(map[string]any{
		"snapshots": map[string]any{
			"default": map[string]any{
				"version":   map[string]any{"epoch": 0, "counter": 0, "node_id": "node-a"},
				"timestamp": time.Now().UTC(),
				"checksum":  "",
				"state": map[string]any{
					"mode": map[string]any{
						"data":    "new",
						"version": map[string]any{"epoch": 0, "counter": 1, "node_id": "node-a"},
					},
				},
			},
		},
	})
	require.NoError(t, err)

	rawDB := rawBoltDBForTest(t, p1)
	require.NoError(t, rawDB.Close())

	sm2 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p2, err := persistence.NewPersistence(dbPath, sm2)
	require.NoError(t, err)
	defer p2.Close()

	require.NoError(t, p2.LoadActiveSnapshot())

	value, ok := sm2.Get("mode")
	require.True(t, ok)
	require.Equal(t, "new", value)
}

func TestImportDataRejectsMalformedSnapshotPayload(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_malformed_snapshot.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.ImportData(map[string]any{
		"snapshots": map[string]any{
			"default": map[string]any{
				"version":   map[string]any{"epoch": 0, "counter": 0, "node_id": "node-a"},
				"timestamp": time.Now().UTC(),
				"checksum":  "",
				"state":     map[string]any{},
			},
			"broken": "not-a-persistent-state",
		},
	})
	require.Error(t, err)

	exists, err := p.SnapshotExists("default")
	require.NoError(t, err)
	require.True(t, exists)

	exists, err = p.SnapshotExists("broken")
	require.NoError(t, err)
	require.False(t, exists)
}

func TestImportDataRejectsMalformedAudioPayload(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_malformed_audio.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.ImportData(map[string]any{
		"audio": map[string]any{
			"audio-1": "not-audio-metadata",
		},
	})
	require.Error(t, err)

	_, err = p.GetAudioMetadata("audio-1")
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestImportDataIgnoresDevicePayload(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_ignored_device.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	// Device data in import payload should be silently ignored (no error, no write).
	err = p.ImportData(map[string]any{
		"device": map[string]any{
			"info": "not-a-device-patch",
		},
	})
	require.NoError(t, err)

	_, err = p.GetStoredDeviceInfo()
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestExportImportRoundTripPreservesAudioButExcludesDeviceData(t *testing.T) {
	tmpDir := t.TempDir()
	srcDBPath := filepath.Join(tmpDir, "export_import_src.db")
	dstDBPath := filepath.Join(tmpDir, "export_import_dst.db")

	sm1 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p1, err := persistence.NewPersistence(srcDBPath, sm1)
	require.NoError(t, err)
	defer p1.Close()

	audioMeta := &api.AudioMetadata{
		Id:          "audio-1",
		DisplayName: "Audio One",
		Filename:    "audio-one.mp3",
		MimeType:    "audio/mpeg",
	}
	require.NoError(t, p1.SaveAudioMeta(audioMeta))

	deviceInfo := &api.DevicePatch{
		Id:   stringPtr("dev-1"),
		Name: stringPtr("Kitchen"),
	}
	require.NoError(t, p1.SetDeviceInfo(deviceInfo))

	exported, err := p1.ExportData()
	require.NoError(t, err)

	importData, ok := exported.(map[string]map[string]any)
	require.True(t, ok)

	// Device bucket must not appear in export.
	_, hasDevice := importData["device"]
	require.False(t, hasDevice, "device bucket should not be exported")

	sm2 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-b"})
	p2, err := persistence.NewPersistence(dstDBPath, sm2)
	require.NoError(t, err)
	defer p2.Close()

	importPayload := make(map[string]any, len(importData))
	for key, value := range importData {
		importPayload[key] = value
	}
	require.NoError(t, p2.ImportData(importPayload))

	// Audio should be preserved via import.
	storedAudio, err := p2.GetAudioMetadata(audioMeta.Id)
	require.NoError(t, err)
	require.Equal(t, audioMeta.DisplayName, storedAudio.DisplayName)
	require.Equal(t, audioMeta.Filename, storedAudio.Filename)

	// Device info on destination should remain unset (not synced from source).
	_, err = p2.GetStoredDeviceInfo()
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestGetStoredDeviceInfoReturnsErrNotFoundWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_device_info.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	_, err = p.GetStoredDeviceInfo()
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestGetAudioByDisplayNameReturnsErrNotFoundWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_audio_display_name.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	meta, err := p.GetAudioByDisplayName("does-not-exist")
	require.Nil(t, meta)
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestDeleteAudioMetadataReturnsErrNotFoundWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_audio_delete.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.DeleteAudioMetadata("does-not-exist")
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestSaveTasksReturnsErrNotFoundWhenTasksBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_tasks_bucket_save.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("tasks"))
	})
	require.NoError(t, err)

	err = p.SaveTasks(map[string]*api.Task{})
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestSetDeviceInfoReturnsErrNotFoundWhenDeviceBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_device_bucket_set.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("device"))
	})
	require.NoError(t, err)

	err = p.SetDeviceInfo(&api.DevicePatch{Name: stringPtr("Kitchen")})
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestSaveStateReturnsErrNotFoundWhenActiveBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_active_bucket_save_state.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	require.NoError(t, sm.Set("mode", "value"))
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("active"))
	})
	require.NoError(t, err)

	err = p.SaveState()
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestDeleteTaskReturnsErrNotFoundWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_task_delete.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	err = p.DeleteTask("does-not-exist")
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestGetTaskReturnsErrNotFoundWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_task_get.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	task, err := p.GetTask("does-not-exist")
	require.Nil(t, task)
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestGetSnapshotReturnsErrNotFoundWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_snapshot_get.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	snapshot, err := p.GetSnapshot("does-not-exist")
	require.Nil(t, snapshot)
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestGetDatabaseMetadataReturnsErrNotFoundWhenMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_metadata_get.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte("fusion"))
		require.NotNil(t, bucket)
		return bucket.Delete([]byte("metadata"))
	})
	require.NoError(t, err)

	metadata, err := p.GetDatabaseMetadata()
	require.Nil(t, metadata)
	require.Error(t, err)
	require.True(t, errors.Is(err, persistence.ErrNotFound))
}

func TestNewPersistenceReseedsMissingDefaultSnapshotMetadataAndActiveState(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "reseed_missing_records.db")

	sm1 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	require.NoError(t, sm1.Set("mode", "expected"))

	p1, err := persistence.NewPersistence(dbPath, sm1)
	require.NoError(t, err)
	require.NoError(t, p1.SaveState())
	p1.Close()

	db, err := bbolt.Open(dbPath, 0600, nil)
	require.NoError(t, err)
	err = db.Update(func(tx *bbolt.Tx) error {
		require.NotNil(t, tx.Bucket([]byte("snapshots")))
		require.NotNil(t, tx.Bucket([]byte("fusion")))
		require.NotNil(t, tx.Bucket([]byte("active")))
		require.NoError(t, tx.Bucket([]byte("snapshots")).Delete([]byte("default")))
		require.NoError(t, tx.Bucket([]byte("fusion")).Delete([]byte("metadata")))
		require.NoError(t, tx.Bucket([]byte("active")).Delete([]byte("state")))
		return nil
	})
	require.NoError(t, err)
	require.NoError(t, db.Close())

	sm2 := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	require.NoError(t, sm2.Set("mode", "expected"))

	p2, err := persistence.NewPersistence(dbPath, sm2)
	require.NoError(t, err)
	defer p2.Close()

	exists, err := p2.SnapshotExists("default")
	require.NoError(t, err)
	require.True(t, exists)

	metadata, err := p2.GetDatabaseMetadata()
	require.NoError(t, err)
	require.Equal(t, "default", metadata.ActiveSnapshot)

	require.NoError(t, p2.LoadActiveSnapshot())
	value, ok := sm2.Get("mode")
	require.True(t, ok)
	require.Equal(t, "expected", value)

	actualHash, err := computeDatabaseHashFromDB(rawBoltDBForTest(t, p2))
	require.NoError(t, err)
	require.Equal(t, actualHash, metadata.Hash)
}

func TestTaskExistsReturnsFalseWithoutErrorWhenTasksBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_tasks_bucket_exists.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("tasks"))
	})
	require.NoError(t, err)

	exists, err := p.TaskExists(&api.Task{ID: "does-not-exist"})
	require.NoError(t, err)
	require.False(t, exists)
}

func TestGetTaskIDsBySnapshotReturnsEmptyWithoutErrorWhenTasksBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_tasks_bucket_snapshot_ids.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("tasks"))
	})
	require.NoError(t, err)

	taskIDs, err := p.GetTaskIDsBySnapshot("snapshot-a")
	require.NoError(t, err)
	require.Empty(t, taskIDs)
}

func TestLoadTasksReturnsEmptyWithoutErrorWhenTasksBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_tasks_bucket_load.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("tasks"))
	})
	require.NoError(t, err)

	tasks, err := p.LoadTasks()
	require.NoError(t, err)
	require.Empty(t, tasks)
}

func TestListAudioMetadataReturnsEmptyWithoutErrorWhenAudioBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_audio_bucket_list.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("audio"))
	})
	require.NoError(t, err)

	metadata, err := p.ListAudioMetadata()
	require.NoError(t, err)
	require.Empty(t, metadata)
}

func TestListAllTagsReturnsEmptyWithoutErrorWhenAudioBucketMissing(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "missing_audio_bucket_tags.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	rawDB := rawBoltDBForTest(t, p)
	err = rawDB.Update(func(tx *bbolt.Tx) error {
		return tx.DeleteBucket([]byte("audio"))
	})
	require.NoError(t, err)

	tags, err := p.ListAllTags(context.Background())
	require.NoError(t, err)
	require.Empty(t, tags)
}

func TestSetDeviceInfoDoesNotChangeMetadataHash(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "device_no_hash_change.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	hashBefore, err := readDatabaseMetadataFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	require.NoError(t, p.SetDeviceInfo(&api.DevicePatch{
		Id:   stringPtr("dev-1"),
		Name: stringPtr("Kitchen"),
	}))

	hashAfter, err := readDatabaseMetadataFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	require.Equal(t, hashBefore.Hash, hashAfter.Hash,
		"device write must not alter the metadata hash")
}

func TestExportDataExcludesDeviceBucket(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "export_excludes_device.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	require.NoError(t, p.SetDeviceInfo(&api.DevicePatch{
		Id:   stringPtr("dev-1"),
		Name: stringPtr("Living Room"),
	}))

	exported, err := p.ExportData()
	require.NoError(t, err)

	exportMap, ok := exported.(map[string]map[string]any)
	require.True(t, ok)

	_, hasDevice := exportMap["device"]
	require.False(t, hasDevice, "export must not include device bucket")
}

func TestImportDoesNotOverwriteExistingDeviceIdentity(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_preserves_local_device.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	// Set local device identity.
	require.NoError(t, p.SetDeviceInfo(&api.DevicePatch{
		Id:   stringPtr("local-id"),
		Name: stringPtr("Local Node"),
	}))

	// Import a payload that includes a different device identity.
	err = p.ImportData(map[string]any{
		"device": map[string]any{
			"info": map[string]any{
				"id":   "remote-id",
				"name": "Remote Node",
			},
		},
	})
	require.NoError(t, err)

	// Local identity must be preserved.
	stored, err := p.GetStoredDeviceInfo()
	require.NoError(t, err)
	require.Equal(t, "local-id", *stored.Id)
	require.Equal(t, "Local Node", *stored.Name)
}

func TestImportWithDeviceKeyDoesNotAffectHash(t *testing.T) {
	tmpDir := t.TempDir()
	dbPath := filepath.Join(tmpDir, "import_device_no_hash.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	hashBefore, err := readDatabaseMetadataFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	// Import containing only device data — should be a no-op.
	err = p.ImportData(map[string]any{
		"device": map[string]any{
			"info": map[string]any{
				"id":   "injected-id",
				"name": "Injected",
			},
		},
	})
	require.NoError(t, err)

	hashAfter, err := readDatabaseMetadataFromDB(rawBoltDBForTest(t, p))
	require.NoError(t, err)

	require.Equal(t, hashBefore.Hash, hashAfter.Hash,
		"importing device-only payload must not change hash")
}

func TestTwoNodesPersistDistinctIdentitiesAfterExportImport(t *testing.T) {
	tmpDir := t.TempDir()
	dbPathA := filepath.Join(tmpDir, "node_a.db")
	dbPathB := filepath.Join(tmpDir, "node_b.db")

	// Node A
	smA := persistence.NewStateManager(&api.AppConfig{NodeName: "node-a"})
	pA, err := persistence.NewPersistence(dbPathA, smA)
	require.NoError(t, err)
	defer pA.Close()

	require.NoError(t, pA.SetDeviceInfo(&api.DevicePatch{
		Id:   stringPtr("id-a"),
		Name: stringPtr("Node A"),
	}))

	// Node B
	smB := persistence.NewStateManager(&api.AppConfig{NodeName: "node-b"})
	pB, err := persistence.NewPersistence(dbPathB, smB)
	require.NoError(t, err)
	defer pB.Close()

	require.NoError(t, pB.SetDeviceInfo(&api.DevicePatch{
		Id:   stringPtr("id-b"),
		Name: stringPtr("Node B"),
	}))

	// Export from A and import into B (simulating anti-entropy sync).
	exported, err := pA.ExportData()
	require.NoError(t, err)

	exportMap, ok := exported.(map[string]map[string]any)
	require.True(t, ok)

	importPayload := make(map[string]any, len(exportMap))
	for key, value := range exportMap {
		importPayload[key] = value
	}
	require.NoError(t, pB.ImportData(importPayload))

	// Node B must retain its own identity.
	storedB, err := pB.GetStoredDeviceInfo()
	require.NoError(t, err)
	require.Equal(t, "id-b", *storedB.Id)
	require.Equal(t, "Node B", *storedB.Name)

	// Node A identity also untouched.
	storedA, err := pA.GetStoredDeviceInfo()
	require.NoError(t, err)
	require.Equal(t, "id-a", *storedA.Id)
	require.Equal(t, "Node A", *storedA.Name)
}

func readDatabaseMetadata(dbPath string) (*api.DatabaseMetadata, error) {
	db, err := bbolt.Open(dbPath, 0600, &bbolt.Options{ReadOnly: true})
	if err != nil {
		return nil, err
	}
	defer db.Close()

	var metadata api.DatabaseMetadata
	err = db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte("fusion"))
		if bucket == nil {
			return os.ErrNotExist
		}
		value := bucket.Get([]byte("metadata"))
		if value == nil {
			return os.ErrNotExist
		}
		return json.Unmarshal(value, &metadata)
	})
	if err != nil {
		return nil, err
	}

	return &metadata, nil
}

func readDatabaseMetadataFromDB(db *bbolt.DB) (*api.DatabaseMetadata, error) {
	var metadata api.DatabaseMetadata
	err := db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte("fusion"))
		if bucket == nil {
			return os.ErrNotExist
		}
		value := bucket.Get([]byte("metadata"))
		if value == nil {
			return os.ErrNotExist
		}
		return json.Unmarshal(value, &metadata)
	})
	if err != nil {
		return nil, err
	}

	return &metadata, nil
}

func computeDatabaseHashForTest(dbPath string) (string, error) {
	db, err := bbolt.Open(dbPath, 0600, &bbolt.Options{ReadOnly: true})
	if err != nil {
		return "", err
	}
	defer db.Close()

	hash := sha256.New()
	err = db.View(func(tx *bbolt.Tx) error {
		return tx.ForEach(func(name []byte, b *bbolt.Bucket) error {
			if string(name) == "device" {
				return nil
			}
			hash.Write(name)
			cursor := b.Cursor()
			for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
				hash.Write(k)
				normalized, err := normalizeHashValueForTest(string(name), string(k), v)
				if err != nil {
					return err
				}
				hash.Write(normalized)
			}
			return nil
		})
	})
	if err != nil {
		return "", err
	}

	return hex.EncodeToString(hash.Sum(nil)), nil
}

func computeDatabaseHashFromDB(db *bbolt.DB) (string, error) {
	hash := sha256.New()
	err := db.View(func(tx *bbolt.Tx) error {
		return tx.ForEach(func(name []byte, b *bbolt.Bucket) error {
			if string(name) == "device" {
				return nil
			}
			hash.Write(name)
			cursor := b.Cursor()
			for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
				hash.Write(k)
				normalized, err := normalizeHashValueForTest(string(name), string(k), v)
				if err != nil {
					return err
				}
				hash.Write(normalized)
			}
			return nil
		})
	})
	if err != nil {
		return "", err
	}

	return hex.EncodeToString(hash.Sum(nil)), nil
}

func normalizeHashValueForTest(bucketName, key string, value []byte) ([]byte, error) {
	switch bucketName {
	case "fusion":
		if key != "metadata" {
			return value, nil
		}

		var metadata api.DatabaseMetadata
		if err := json.Unmarshal(value, &metadata); err != nil {
			return nil, err
		}
		metadata.Hash = ""
		return json.Marshal(metadata)

	case "snapshots", "active":
		var state persistence.PersistentState
		if err := json.Unmarshal(value, &state); err != nil {
			return nil, err
		}
		state.Timestamp = time.Time{}
		return json.Marshal(state)

	default:
		return value, nil
	}
}

func rawBoltDBForTest(t *testing.T, p *persistence.Persistence) *bbolt.DB {
	t.Helper()

	field := reflect.ValueOf(p).Elem().FieldByName("db")
	require.True(t, field.IsValid(), "persistence.db field not found")

	return *(**bbolt.DB)(unsafe.Pointer(field.UnsafeAddr()))
}

func stringPtr(value string) *string {
	return &value
}
