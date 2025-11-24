package main

import (
	"reflect"
	"strconv"
	"testing"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
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

	// first make config.param1 & param2
	u1 := api.ConfigUpdate{
		Data: map[string]any{"config": map[string]any{
			"param1": "value1", "param2": "value2",
		}},
		Version: api.Version{Counter: 100, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u1); err != nil {
		t.Fatalf("ApplyUpdate u1 failed: %v", err)
	}

	// then only overwrite param2
	u2 := api.ConfigUpdate{
		Data: map[string]any{"config": map[string]any{
			"param2": "updated",
		}},
		Version: api.Version{Counter: 200, NodeID: stateConfig.NodeName},
	}
	if _, err := sm.ApplyUpdate(u2); err != nil {
		t.Fatalf("ApplyUpdate u2 failed: %v", err)
	}

	v, _ := sm.Get("config.param1")
	if v != "value1" {
		t.Errorf("Expected config.param1='value1', got %v", v)
	}
	v, _ = sm.Get("config.param2")
	if v != "updated" {
		t.Errorf("Expected config.param2='updated', got %v", v)
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
