package main

import (
	"reflect"
	"strconv"
	"testing"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/utils"
)

var stateConfig = api.AppConfig{
	NodeName: "test_manager",
	Verbose:  false,
}

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "state_test",
		LogDir:      "/tmp/state_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.ERROR,
	})
}

func TestSetAndGetSimpleValue(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)
	value := "hello world"
	if err := sm.Set("greeting", value); err != nil {
		t.Fatalf("Set failed: %v", err)
	}

	got, ok := sm.Get("greeting")
	if !ok {
		t.Fatalf("Get returned not found for key 'greeting'")
	}
	if got != value {
		t.Errorf("Expected %v, got %v", value, got)
	}
}

func TestApplyUpdateAndGetNestedValues(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	update := api.ConfigUpdate{
		Data: map[string]any{
			"settings": map[string]any{
				"audio": map[string]any{
					"modifiers": []any{"bass", "treble", "echo"},
				},
			},
		},
		Version: api.Version{Counter: 1, NodeID: stateConfig.NodeName},
	}

	if _, err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// nested map
	val, ok := sm.Get("settings.audio")
	if !ok {
		t.Fatalf("Failed to get 'settings.audio'")
	}
	if _, ok := val.(map[string]any); !ok {
		t.Fatalf("Expected map at 'settings.audio', got %T", val)
	}

	// array index
	val, ok = sm.Get("settings.audio.modifiers[1]")
	if !ok {
		t.Fatalf("Failed to get 'modifiers[1]'")
	}
	if val != "treble" {
		t.Errorf("Expected 'treble', got %v", val)
	}

	// array slice
	val, ok = sm.Get("settings.audio.modifiers[0:2]")
	if !ok {
		t.Fatalf("Failed to get 'modifiers[0:2]'")
	}
	slice, ok := val.([]any)
	if !ok {
		t.Fatalf("Expected []any, got %T", val)
	}
	expected := []any{"bass", "treble"}
	if !reflect.DeepEqual(slice, expected) {
		t.Errorf("Expected %v, got %v", expected, slice)
	}
}

func TestGetInvalidKey(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)
	if _, ok := sm.Get("nonexistent.key"); ok {
		t.Errorf("Expected 'nonexistent.key' to be missing")
	}
}

func TestMergeRemoteState(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	// use Set() for a simple local value
	if err := sm.Set("a", "local"); err != nil {
		t.Fatalf("Set failed: %v", err)
	}

	// remote has higher version → should overwrite
	remoteState := map[string]*api.StateEntry{
		"a": {
			Data:    "remote",
			Version: api.Version{Counter: 200, NodeID: "other"},
		},
		"b": {
			Data:    "new remote",
			Version: api.Version{Counter: 200, NodeID: "other"},
		},
	}

	sm.MergeRemoteState(remoteState)

	v, ok := sm.Get("a")
	if !ok || v != "remote" {
		t.Errorf("Expected 'a'→'remote', got %v (exists=%v)", v, ok)
	}
	v, ok = sm.Get("b")
	if !ok || v != "new remote" {
		t.Errorf("Expected 'b'→'new remote', got %v (exists=%v)", v, ok)
	}
}

func TestNestedMergeMapsViaApplyUpdate(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	// First snapshot
	u1 := api.ConfigUpdate{
		Data: map[string]any{"config": map[string]any{
			"param1": "value1", "param2": "value2",
		}},
		Version: api.Version{Counter: 100, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u1); err != nil {
		t.Fatalf("ApplyUpdate u1 failed: %v", err)
	}

	// Second snapshot (authoritative replacement for "config")
	u2 := api.ConfigUpdate{
		Data: map[string]any{"config": map[string]any{
			"param2": "updated",
		}},
		Version: api.Version{Counter: 200, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u2); err != nil {
		t.Fatalf("ApplyUpdate u2 failed: %v", err)
	}

	// Under snapshot semantics, param1 is intentionally dropped.
	v1, _ := sm.Get("config.param1")
	if v1 != nil {
		t.Errorf("Expected config.param1 to be removed, got %v", v1)
	}

	v2, _ := sm.Get("config.param2")
	if v2 != "updated" {
		t.Errorf("Expected config.param2='updated', got %v", v2)
	}
}

func TestArrayIndexErrors(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	u := api.ConfigUpdate{
		Data:    map[string]any{"numbers": []any{1, 2, 3}},
		Version: api.Version{Counter: 300, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	if _, ok := sm.Get("numbers[5]"); ok {
		t.Error("Expected out-of-bounds index to be invalid")
	}
	if _, ok := sm.Get("numbers[0:5]"); ok {
		t.Error("Expected slice end>len to be invalid")
	}
	if _, ok := sm.Get("numbers[abc]"); ok {
		t.Error("Expected non-numeric index to be invalid")
	}
	if _, ok := sm.Get("numbers[a:b]"); ok {
		t.Error("Expected non-numeric slice to be invalid")
	}
}

func TestArraySliceEdgeCases(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	u := api.ConfigUpdate{
		Data:    map[string]any{"letters": []any{"a", "b", "c", "d"}},
		Version: api.Version{Counter: 400, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	v, ok := sm.Get("letters[:2]")
	if !ok {
		t.Fatal("Expected letters[:2] to succeed")
	}
	s1, _ := v.([]any)
	if !reflect.DeepEqual(s1, []any{"a", "b"}) {
		t.Errorf("letters[:2] → %v", s1)
	}

	v, ok = sm.Get("letters[2:]")
	if !ok {
		t.Fatal("Expected letters[2:] to succeed")
	}
	s2, _ := v.([]any)
	if !reflect.DeepEqual(s2, []any{"c", "d"}) {
		t.Errorf("letters[2:] → %v", s2)
	}
}

func TestGetWithComplexPath(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	u := api.ConfigUpdate{
		Data: map[string]any{"outer": map[string]any{"inner": []any{
			map[string]any{"name": "first", "score": 10},
			map[string]any{"name": "second", "score": 20},
		}}},
		Version: api.Version{Counter: 600, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	val, ok := sm.Get("outer.inner[1].score")
	if !ok {
		t.Fatal("Failed to retrieve outer.inner[1].score")
	}
	switch v := val.(type) {
	case float64:
		if v != 20 {
			t.Errorf("Expected 20, got %v", v)
		}
	case int:
		if v != 20 {
			t.Errorf("Expected 20, got %v", v)
		}
	case string:
		i, err := strconv.Atoi(v)
		if err != nil || i != 20 {
			t.Errorf("Expected 20, got %v", v)
		}
	default:
		t.Errorf("Unexpected type %T for score", v)
	}
}

func TestApplyUpdateWithClearFlag(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	// use Set() for the initial data
	if err := sm.Set("key", "value"); err != nil {
		t.Fatalf("Set failed: %v", err)
	}
	if v, ok := sm.Get("key"); !ok || v != "value" {
		t.Fatal("Expected key to be set")
	}

	clear := api.ConfigUpdate{
		Data:    map[string]any{"irrelevant": "data"},
		Version: api.Version{Counter: 2000, NodeID: stateConfig.NodeName},
		Clear:   true,
	}
	if _, err := sm.ApplyUpdate(clear); err != nil {
		t.Fatalf("ApplyUpdate(Clear) failed: %v", err)
	}

	// After the atomic clear and apply, "key" should be gone
	if _, ok := sm.Get("key"); ok {
		t.Error("Expected original key to be cleared")
	}

	// Only "irrelevant":"data" should remain
	v, ok := sm.Get("irrelevant")
	if !ok || v != "data" {
		t.Errorf("Expected only irrelevant:data, got %v", sm.GetFullState().State)
	}
}

func TestMergeRemoteStateWithEqualVersion(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	u := api.ConfigUpdate{
		Data:    map[string]any{"x": "local"},
		Version: api.Version{Counter: 5000, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	remote := map[string]*api.StateEntry{
		"x": {
			Data:    "remote",
			Version: api.Version{Counter: 5000, NodeID: stateConfig.NodeName}, // same counter & NodeID
		},
	}
	sm.MergeRemoteState(remote)

	v, _ := sm.Get("x")
	if v != "local" {
		t.Errorf("Expected equal‐version merge to skip, got %v", v)
	}
}

func TestApplyStaleUpdatePropagation(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	fresh := api.ConfigUpdate{
		Data:    map[string]any{"y": "freshValue"},
		Version: api.Version{Counter: 1000, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(fresh); err != nil {
		t.Fatalf("ApplyUpdate(fresh) failed: %v", err)
	}

	stale := api.ConfigUpdate{
		Data:    map[string]any{"y": "staleValue"},
		Version: api.Version{Counter: 500, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(stale); err != nil {
		t.Fatalf("ApplyUpdate(stale) failed: %v", err)
	}

	v, _ := sm.Get("y")
	if v != "freshValue" {
		t.Errorf("Expected stale update to be ignored, got %v", v)
	}
}

func TestMergeRemoteStateWithLowerVersion(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	u := api.ConfigUpdate{
		Data:    map[string]any{"x": "local"},
		Version: api.Version{Counter: 5000, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	remote := map[string]*api.StateEntry{
		"x": {
			Data:    "stale",
			Version: api.Version{Counter: 4000, NodeID: "other"},
		},
	}
	sm.MergeRemoteState(remote)

	v, _ := sm.Get("x")
	if v != "local" {
		t.Errorf("Expected lower‐version remote to be ignored, got %v", v)
	}
}

func TestApplyUpdateRejectsOldEpoch(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	// Local epoch = 0
	fresh := api.ConfigUpdate{
		Data:    map[string]any{"k": "fresh"},
		Version: api.Version{Epoch: 0, Counter: 100},
	}
	if _, err := sm.ApplyUpdate(fresh); err != nil {
		t.Fatalf("ApplyUpdate(fresh) failed: %v", err)
	}

	// Stale epoch
	stale := api.ConfigUpdate{
		Data:    map[string]any{"k": "stale"},
		Version: api.Version{Epoch: 0, Counter: 50},
	}

	if _, err := sm.ApplyUpdate(stale); err != nil {
		t.Fatalf("ApplyUpdate(stale) failed: %v", err)
	}

	v, _ := sm.Get("k")
	if v != "fresh" {
		t.Fatalf("Expected stale update to be ignored, got %v", v)
	}
}

func TestApplyUpdateAdoptsNewEpoch(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	// Local epoch = 0
	sm.Set("a", "old")

	// Update with higher epoch
	newer := api.ConfigUpdate{
		Data:    map[string]any{"a": "new"},
		Version: api.Version{Epoch: 1, Counter: 1},
	}

	if _, err := sm.ApplyUpdate(newer); err != nil {
		t.Fatalf("ApplyUpdate(newer) failed: %v", err)
	}

	// Should overwrite & adopt epoch
	v, _ := sm.Get("a")
	if v != "new" {
		t.Fatalf("Expected 'new', got %v", v)
	}

	version := sm.GetVersion()
	if version.Epoch != 1 {
		t.Fatalf("Expected epoch=1 after adoption, got %d", version.Epoch)
	}
}

func TestMergeRemoteStateAdoptsNewEpoch(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	sm.Set("foo", "old")

	remoteState := map[string]*api.StateEntry{
		"foo": {Data: "new", Version: api.Version{Epoch: 1, Counter: 5}},
		"bar": {Data: "added", Version: api.Version{Epoch: 1, Counter: 5}},
	}

	sm.MergeRemoteState(remoteState)

	v, _ := sm.Get("foo")
	if v != "new" {
		t.Fatalf("Expected foo='new', got %v", v)
	}
	v, _ = sm.Get("bar")
	if v != "added" {
		t.Fatalf("Expected bar='added', got %v", v)
	}

	if sm.GetVersion().Epoch != 1 {
		t.Fatalf("Expected epoch adoption=1, got %d", sm.GetVersion().Epoch)
	}
}

func TestReplaceFullStateExactness(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	sm.Set("a", 1)
	sm.Set("b", 2)

	newState := map[string]*api.StateEntry{
		"x": {Data: 9, Version: api.Version{Epoch: 10, Counter: 1}},
	}
	newVersion := api.Version{Epoch: 10, Counter: 1}

	sm.ReplaceFullState(newState, newVersion)

	if _, ok := sm.Get("a"); ok {
		t.Fatal("Expected old key 'a' to be removed after ReplaceFullState")
	}
	if _, ok := sm.Get("b"); ok {
		t.Fatal("Expected old key 'b' to be removed after ReplaceFullState")
	}

	v, _ := sm.Get("x")
	if v != 9 {
		t.Fatalf("Expected x=9, got %v", v)
	}

	if sm.GetVersion().Epoch != 10 {
		t.Fatalf("Expected epoch=10 after ReplaceFullState")
	}
}

func TestDeepCopySafety(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	original := map[string]any{
		"nested": []any{1, 2, 3},
	}

	sm.Set("config", original)

	// Modify original after Set()
	original["nested"].([]any)[0] = 999

	// The stored value must NOT change
	val, _ := sm.Get("config.nested[0]")
	if stateToInt(val) != 1 {
		t.Fatalf("Deep-copy violation: expected stored value 1, got %v", val)
	}
}

func TestVersionChecksumConsistency(t *testing.T) {
	sm := persistence.NewStateManager(&stateConfig)

	sm.Set("a", 1)
	sm.Set("b", "text")

	full := sm.GetFullState()
	computed, err := utils.JSONChecksum(sm.GetStateMap())
	if err != nil {
		t.Fatalf("Checksum calculation failed: %v", err)
	}

	if full.Checksum != computed {
		t.Fatalf("Checksum mismatch: expected %s, computed %s",
			full.Checksum, computed)
	}
}

func stateToInt(v any) int {
	switch n := v.(type) {
	case float64:
		return int(n)
	case int:
		return n
	default:
		return 0
	}
}

func TestRejoinAdoptsSnapshotEpoch(t *testing.T) {
	smA := persistence.NewStateManager(&stateConfig)
	smB := persistence.NewStateManager(&stateConfig)

	// Node A: foo=42, then “activate snapshot” by bumping epoch.
	if err := smA.Set("foo", 42); err != nil {
		t.Fatalf("Set(A) failed: %v", err)
	}

	// Simulate snapshot activation → Replace and bump epoch to 1.
	smA.ReplaceFullState(
		smA.GetFullState().State,
		api.Version{Epoch: 1, Counter: 0},
	)

	// Node B is stale (epoch=0)
	if err := smB.Set("foo", "stale_value"); err != nil {
		t.Fatalf("Set(B) failed: %v", err)
	}

	// Node B rejoins:
	remoteState := smA.GetFullState().State
	remoteVer := smA.GetVersion()
	localVer := smB.GetVersion()

	// Delegate-level epoch logic:
	if remoteVer.Epoch > localVer.Epoch {
		smB.ReplaceFullState(remoteState, remoteVer)
	} else if remoteVer.Epoch == localVer.Epoch {
		smB.MergeRemoteState(remoteState)
	}

	if smB.GetVersion().Epoch != 1 {
		t.Fatalf("Expected rejoin to adopt epoch=1, got %d", smB.GetVersion().Epoch)
	}

	v, _ := smB.Get("foo")
	if v != 42 {
		t.Fatalf("Expected foo=42 after rejoin, got %v", v)
	}
}

func TestDelegateEpochRejectsOlderState(t *testing.T) {
	smLocal := persistence.NewStateManager(&stateConfig)
	smRemote := persistence.NewStateManager(&stateConfig)

	// Local at epoch 1, value is "new"
	smLocal.Set("x", "new")
	smLocal.ReplaceFullState(smLocal.GetFullState().State,
		api.Version{Epoch: 1, Counter: 0})

	// Remote at epoch 0 (stale), value is "old"
	smRemote.Set("x", "old")
	smRemote.ReplaceFullState(smRemote.GetFullState().State,
		api.Version{Epoch: 0, Counter: 0})

	// Simulate delegate-level merge
	remoteFull := smRemote.GetFullState()
	remoteVer := smRemote.GetVersion()
	localVer := smLocal.GetVersion()

	if remoteVer.Epoch > localVer.Epoch {
		smLocal.ReplaceFullState(remoteFull.State, remoteVer)
	} else if remoteVer.Epoch == localVer.Epoch {
		smLocal.MergeRemoteState(remoteFull.State)
	}

	// x should remain "new"
	v, _ := smLocal.Get("x")
	if v != "new" {
		t.Fatalf("Expected 'new', got %v", v)
	}
}

func TestRejoinDoesNotOverwriteNewerEpoch(t *testing.T) {
	smA := persistence.NewStateManager(&stateConfig)
	smB := persistence.NewStateManager(&stateConfig)

	// Node A is new epoch (3)
	smA.Set("key", "new")
	smA.ReplaceFullState(
		smA.GetFullState().State,
		api.Version{Epoch: 3, Counter: 0},
	)

	// Node B is old epoch (1)
	smB.Set("key", "old")
	smB.ReplaceFullState(
		smB.GetFullState().State,
		api.Version{Epoch: 1, Counter: 0},
	)

	// B rejoins → but A should NOT adopt older epoch
	smA.MergeRemoteState(smB.GetFullState().State)

	v, _ := smA.Get("key")
	if v != "new" {
		t.Fatalf("Expected x='new' (newer epoch prevails), got %v", v)
	}

	if smA.GetVersion().Epoch != 3 {
		t.Fatalf("Expected epoch=3, got %d", smA.GetVersion().Epoch)
	}
}
