package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/routes"
	"fusion/internal/utils"

	"github.com/stretchr/testify/require"
)

const (
	databaseName = "fusion_test.db"
)

var persistConfig = api.AppConfig{
	NodeName: "test_manager",
	Verbose:  false,
}

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "persistence_test",
		LogDir:      "/tmp/persistence_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.ERROR,
	})
}

// TestMarkDirtyConcurrent checks for potential race conditions by calling MarkDirty concurrently.
// (Run this test with `go test -race`.)
func TestMarkDirtyConcurrent(t *testing.T) {

	// Create a temporary directory and file for our test state.
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := persistence.NewStateManager(&persistConfig)
	if err := sm.Set("testKey", "testValue"); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	// Create the persistence object.
	cp, err := persistence.NewPersistence(configPath, sm)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Run many goroutines calling MarkDirty concurrently.
	const numGoroutines = 50
	const iterations = 20
	var wg sync.WaitGroup

	for i := range numGoroutines {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for range iterations {
				cp.MarkDirty()
				// Optionally sleep a bit to simulate work.
				time.Sleep(5 * time.Millisecond)
			}
		}(i)
	}
	wg.Wait()

	// After all MarkDirty calls, validate the state file.
	if err := cp.ValidateState(); err != nil {
		t.Errorf("ValidateState failed: %v", err)
	}

	// Check that the state file exists.
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

	// Validate the state file.
	if err := cp.ValidateState(); err != nil {
		t.Fatalf("ValidateState failed: %v", err)
	}
}

// TestChecksumCalculation verifies that the checksum calculated on the state
// remains consistent when the same state is used.
func TestChecksumCalculation(t *testing.T) {

	sm := persistence.NewStateManager(&persistConfig)

	// Set a known state.
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

	// Get the full state.
	fullState := sm.GetFullState()

	// Serialize the same state and calculate again.
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

	// 1. Save two tasks
	original := map[string]*api.Task{
		"one": {ID: "one", CronExpr: "* * * * *", Description: "t1", Type: api.TaskTypeSnapshot},
		"two": {ID: "two", CronExpr: "* * * * *", Description: "t2", Type: api.TaskTypeSnapshot},
	}
	require.NoError(t, p.SaveTasks(original))

	// Load tasks
	loaded, err := p.LoadTasks()
	require.NoError(t, err)
	require.Len(t, loaded, 2)

	// 2. Remove one task and save again
	delete(original, "one")
	require.NoError(t, p.SaveTasks(original))

	// Load again
	loaded2, err := p.LoadTasks()
	require.NoError(t, err)

	// Verify only "two" remains
	require.Len(t, loaded2, 1)
	require.NotNil(t, loaded2["two"])
	require.Nil(t, loaded2["one"])
}

func TestSaveStateMetadataNotifierFiresOnceWithFinalMetadata(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := persistence.NewStateManager(&persistConfig)
	require.NoError(t, sm.Set("notify_key", "notify_value"))

	cp, err := persistence.NewPersistence(configPath, sm)
	require.NoError(t, err)
	defer cp.Close()

	ch := make(chan *api.DatabaseMetadata, 4)
	cp.SetMetadataNotifier(func(meta *api.DatabaseMetadata) {
		ch <- meta
	})

	require.NoError(t, cp.SaveState())

	var got *api.DatabaseMetadata
	select {
	case got = <-ch:
	case <-time.After(300 * time.Millisecond):
		t.Fatal("timed out waiting for metadata notifier payload")
	}

	require.NotNil(t, got)
	require.NotEmpty(t, got.Hash)
	require.True(t, got.Valid)
	require.Equal(t, sm.GetVersion(), got.Version)

	select {
	case extra := <-ch:
		t.Fatalf("expected exactly one notifier call, got extra %+v", extra)
	case <-time.After(50 * time.Millisecond):
	}
}

func TestSaveStateMetadataNotifierNotCalledOnFailure(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := persistence.NewStateManager(&persistConfig)
	require.NoError(t, sm.Set("notify_key", "notify_value"))

	cp, err := persistence.NewPersistence(configPath, sm)
	require.NoError(t, err)

	ch := make(chan *api.DatabaseMetadata, 1)
	cp.SetMetadataNotifier(func(meta *api.DatabaseMetadata) {
		ch <- meta
	})

	require.NoError(t, cp.SaveState())
	select {
	case <-ch:
	case <-time.After(300 * time.Millisecond):
		t.Fatal("timed out waiting for initial metadata notifier")
	}

	cp.Close()
drain:
	for {
		select {
		case <-ch:
		case <-time.After(50 * time.Millisecond):
			break drain
		}
	}

	err = cp.SaveState()
	require.Error(t, err)

	select {
	case got := <-ch:
		t.Fatalf("expected notifier not to fire on failed save, got %+v", got)
	case <-time.After(50 * time.Millisecond):
	}
}

func TestSaveStateDoesNotChangeAntiEntropyHashWithoutDataChange(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := persistence.NewStateManager(&persistConfig)
	require.NoError(t, sm.Set("stable_key", "stable_value"))

	cp, err := persistence.NewPersistence(configPath, sm)
	require.NoError(t, err)
	defer cp.Close()

	require.NoError(t, cp.SaveState())
	meta1, err := cp.GetDatabaseMetadata()
	require.NoError(t, err)
	require.NotEmpty(t, meta1.Hash)

	time.Sleep(20 * time.Millisecond)
	require.NoError(t, cp.SaveState())
	meta2, err := cp.GetDatabaseMetadata()
	require.NoError(t, err)

	require.Equal(t, meta1.Version, meta2.Version)
	require.Equal(t, meta1.Hash, meta2.Hash)
}

func TestAntiEntropyHashCanonicalizesSceneSetData(t *testing.T) {
	dir := t.TempDir()

	smA := persistence.NewStateManager(&api.AppConfig{NodeName: "hash-node"})
	pA, err := persistence.NewPersistence(filepath.Join(dir, "a.db"), smA)
	require.NoError(t, err)
	defer pA.Close()

	smB := persistence.NewStateManager(&api.AppConfig{NodeName: "hash-node"})
	pB, err := persistence.NewPersistence(filepath.Join(dir, "b.db"), smB)
	require.NoError(t, err)
	defer pB.Close()

	sceneSetA := map[string]any{
		"set-1": map[string]any{
			"set_id": "set-1",
			"scenes": []any{
				map[string]any{
					"id": "scene-1",
					"data": map[string]any{
						"alpha": 1,
						"beta":  2,
					},
				},
			},
		},
	}

	sceneSetB := map[string]any{
		"set-1": map[string]any{
			"set_id": "set-1",
			"scenes": []any{
				map[string]any{
					"id": "scene-1",
					"data": map[string]any{
						"beta":  2,
						"alpha": 1,
					},
				},
			},
		},
	}

	require.NoError(t, pA.ImportData(map[string]any{"scene_sets": sceneSetA}))
	require.NoError(t, pB.ImportData(map[string]any{"scene_sets": sceneSetB}))

	metaA, err := pA.GetDatabaseMetadata()
	require.NoError(t, err)
	metaB, err := pB.GetDatabaseMetadata()
	require.NoError(t, err)

	require.Equal(t, metaA.Hash, metaB.Hash)
}

func TestUpsertSceneSetsAdvancesDatabaseMetadataVersion(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "scene_set_version.db")

	sm := persistence.NewStateManager(&api.AppConfig{NodeName: "test-node"})
	p, err := persistence.NewPersistence(dbPath, sm)
	require.NoError(t, err)
	defer p.Close()

	before, err := p.GetDatabaseMetadata()
	require.NoError(t, err)

	require.NoError(t, p.UpsertSceneSets([]api.SceneSet{{
		SetID: "anti-entropy-version-test",
		Name:  "Version bump",
		Scenes: []api.Scene{
			{ID: "anti-entropy-version-test-scene", Name: "Scene"},
		},
	}}))

	after, err := p.GetDatabaseMetadata()
	require.NoError(t, err)

	require.True(t, before.Version.Less(after.Version), "expected scene-set persistence to advance database metadata version")
}

func stopFusionOnNode(t *testing.T, nodeName string) {
	t.Helper()
	_, err := runMultipassCommandOnInstance(t, nodeName, "sudo systemctl stop fusion-server")
	require.NoError(t, err)
}

func startFusionOnNode(t *testing.T, nodeName string) {
	t.Helper()
	_, err := runMultipassCommandOnInstance(t, nodeName, "sudo systemctl start fusion-server")
	require.NoError(t, err)
}

func waitForNodeReachable(t *testing.T, node clusterNode, timeout time.Duration) {
	t.Helper()
	require.Eventually(t, func() bool {
		resp, err := http.Get(node.address + routes.MetadataEndpoint)
		if err != nil {
			return false
		}
		resp.Body.Close()
		return resp.StatusCode == http.StatusOK
	}, timeout, 250*time.Millisecond, "node %s did not become reachable", node.name)
}

func upsertSceneSetsOnNode(t *testing.T, node clusterNode, sets []api.SceneSet) {
	t.Helper()

	payload, err := json.Marshal(map[string]any{"scene_sets": sets})
	require.NoError(t, err)

	resp, err := http.Post(node.address+routes.ValueEndpoint, api.JsonMIMEType, bytes.NewBuffer(payload))
	require.NoError(t, err)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s returned %d: %s", node.address+routes.ValueEndpoint, resp.StatusCode, string(body))
	}
}

func sceneSetIDsOnNode(t *testing.T, node clusterNode) []string {
	t.Helper()

	resp, err := http.Get(node.address + routes.ScenesSetsEndpoint)
	require.NoError(t, err)
	defer resp.Body.Close()
	require.Equal(t, http.StatusOK, resp.StatusCode)

	var out api.SceneSetListResponse
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&out))

	ids := make([]string, 0, len(out.SceneSets))
	for _, set := range out.SceneSets {
		ids = append(ids, set.SetID)
	}
	return ids
}

func sceneSetExistsOnNode(t *testing.T, node clusterNode, setID string) bool {
	t.Helper()
	for _, existing := range sceneSetIDsOnNode(t, node) {
		if existing == setID {
			return true
		}
	}
	return false
}

func TestSceneSetAntiEntropyRepairsMissedWriteAfterNodeRejoin(t *testing.T) {
	requireClusterNodes(t, 2)

	nodeA := clusterConfig.nodes[0]
	nodeB := clusterConfig.nodes[1]

	t.Cleanup(func() {
		startFusionOnNode(t, nodeB.name)
		waitForNodeReachable(t, nodeB, 15*time.Second)
	})

	stopFusionOnNode(t, nodeB.name)

	set1ID := fmt.Sprintf("anti-entropy-missed-%d", time.Now().UnixNano())
	set2ID := fmt.Sprintf("anti-entropy-trigger-%d", time.Now().UnixNano())

	set1 := api.SceneSet{
		SetID: set1ID,
		Name:  "Missed while offline",
		Scenes: []api.Scene{
			{ID: set1ID + "-scene", Name: "Missed scene", Data: map[string]any{set1ID + "_gain": -3.0}},
		},
	}
	set2 := api.SceneSet{
		SetID: set2ID,
		Name:  "Trigger repair after rejoin",
		Scenes: []api.Scene{
			{ID: set2ID + "-scene", Name: "Trigger scene", Data: map[string]any{set2ID + "_gain": -6.0}},
		},
	}

	upsertSceneSetsOnNode(t, nodeA, []api.SceneSet{set1})
	require.Eventually(t, func() bool {
		return sceneSetExistsOnNode(t, nodeA, set1ID)
	}, 5*time.Second, 200*time.Millisecond)

	startFusionOnNode(t, nodeB.name)
	waitForNodeReachable(t, nodeB, 15*time.Second)

	// Confirm the restarted node did not already have the missed write before we trigger a fresh metadata update.
	require.Eventually(t, func() bool {
		return !sceneSetExistsOnNode(t, nodeB, set1ID)
	}, 2*time.Second, 200*time.Millisecond)

	upsertSceneSetsOnNode(t, nodeA, []api.SceneSet{set2})

	require.Eventually(t, func() bool {
		return sceneSetExistsOnNode(t, nodeA, set1ID) &&
			sceneSetExistsOnNode(t, nodeA, set2ID) &&
			sceneSetExistsOnNode(t, nodeB, set1ID) &&
			sceneSetExistsOnNode(t, nodeB, set2ID)
	}, 15*time.Second, 250*time.Millisecond, "expected rejoined node to recover missed scene set via anti-entropy")
}
