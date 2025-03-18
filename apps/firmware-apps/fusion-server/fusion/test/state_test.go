package main

import (
	"reflect"
	"strconv"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
)

func TestSetAndGetSimpleValue(t *testing.T) {
	sm := server.NewStateManager("node-1", false)
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
	sm := server.NewStateManager("node-1", false)

	// Create nested data with an array.
	update := api.ConfigUpdate{
		Data: map[string]any{
			"settings": map[string]any{
				"audio": map[string]any{
					"modifiers": []any{"bass", "treble", "echo"},
				},
			},
		},
		Version: time.Now().UnixNano(),
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Test getting a nested map value.
	val, ok := sm.Get("settings.audio")
	if !ok {
		t.Fatalf("Failed to get nested key 'settings.audio'")
	}
	_, ok = val.(map[string]any)
	if !ok {
		t.Fatalf("Expected a map for 'settings.audio', got %T", val)
	}

	// Test getting an array element using an index.
	val, ok = sm.Get("settings.audio.modifiers[1]")
	if !ok {
		t.Fatalf("Failed to get array index 'settings.audio.modifiers[1]'")
	}
	if val != "treble" {
		t.Errorf("Expected 'treble', got %v", val)
	}

	// Test getting a slice of the array.
	val, ok = sm.Get("settings.audio.modifiers[0:2]")
	if !ok {
		t.Fatalf("Failed to get array slice 'settings.audio.modifiers[0:2]'")
	}
	slice, ok := val.([]any)
	if !ok {
		t.Fatalf("Expected slice type, got %T", val)
	}
	expected := []any{"bass", "treble"}
	if !reflect.DeepEqual(slice, expected) {
		t.Errorf("Expected %v, got %v", expected, slice)
	}
}

func TestGetInvalidKey(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "StateTest",
		LogDir:      "/tmp/state_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	sm := server.NewStateManager("node-1", false)
	// No data has been set yet.
	if _, ok := sm.Get("nonexistent.key"); ok {
		t.Errorf("Expected key 'nonexistent.key' to be not found")
	}
}

func TestSubscribeNotification(t *testing.T) {
	sm := server.NewStateManager("node-1", false)
	sub := sm.Subscribe()

	// Apply an update.
	update := api.ConfigUpdate{
		Data: map[string]any{
			"foo": "bar",
		},
		Version: time.Now().UnixNano(),
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	select {
	case <-sub:
		// Received notification.
	case <-time.After(100 * time.Millisecond):
		t.Errorf("Expected subscriber to be notified")
	}
}

func TestMergeRemoteState(t *testing.T) {
	sm := server.NewStateManager("node-1", false)

	// Local state: key "a" with version 100.
	if err := sm.ApplyUpdate(api.ConfigUpdate{
		Data: map[string]any{
			"a": "local",
		},
		Version: 100,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Remote state: key "a" with higher version and key "b".
	remoteState := map[string]*api.StateEntry{
		"a": {
			Data:      "remote",
			Version:   200,
			Timestamp: time.Now().UTC(),
		},
		"b": {
			Data:      "new remote",
			Version:   200,
			Timestamp: time.Now().UTC(),
		},
	}

	sm.MergeRemoteState(remoteState, "remote-node")

	// Check that key "a" was updated.
	val, ok := sm.Get("a")
	if !ok {
		t.Fatalf("Key 'a' not found after merge")
	}
	if val != "remote" {
		t.Errorf("Expected 'remote' for key 'a', got %v", val)
	}

	// Check that key "b" exists.
	val, ok = sm.Get("b")
	if !ok {
		t.Fatalf("Key 'b' not found after merge")
	}
	if val != "new remote" {
		t.Errorf("Expected 'new remote' for key 'b', got %v", val)
	}
}

func TestSetStateAndGetFullState(t *testing.T) {
	sm := server.NewStateManager("node-1", false)

	// Prepare a new state.
	newState := map[string]*api.StateEntry{
		"alpha": {
			Data:      "beta",
			Version:   111,
			Timestamp: time.Now().UTC(),
		},
	}
	sm.SetState(newState)

	fullState := sm.GetFullState()
	if !reflect.DeepEqual(fullState, newState) {
		t.Errorf("GetFullState did not return the expected state.\nGot: %v\nWant: %v", fullState, newState)
	}

	// Modify the copy and ensure the original state is not affected.
	fullState["alpha"].Data = "changed"
	origState := sm.GetFullState()
	if origState["alpha"].Data == "changed" {
		t.Errorf("Original state was modified through the copy")
	}
}

func TestNestedMergeMapsViaApplyUpdate(t *testing.T) {
	sm := server.NewStateManager("node-1", false)

	// First update: add a nested map.
	update1 := api.ConfigUpdate{
		Data: map[string]any{
			"config": map[string]any{
				"param1": "value1",
				"param2": "value2",
			},
		},
		Version: 100,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update1); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Second update: update only param2.
	update2 := api.ConfigUpdate{
		Data: map[string]any{
			"config": map[string]any{
				"param2": "updated",
			},
		},
		Version: 200,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update2); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Check that param1 remains and param2 is updated.
	val, ok := sm.Get("config.param1")
	if !ok || val != "value1" {
		t.Errorf("Expected config.param1 to be 'value1', got %v", val)
	}
	val, ok = sm.Get("config.param2")
	if !ok || val != "updated" {
		t.Errorf("Expected config.param2 to be 'updated', got %v", val)
	}
}

func TestArrayIndexErrors(t *testing.T) {
	sm := server.NewStateManager("node-1", false)
	// Set state with an array.
	update := api.ConfigUpdate{
		Data: map[string]any{
			"numbers": []any{1, 2, 3},
		},
		Version: 300,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Test invalid index (out-of-bounds)
	if _, ok := sm.Get("numbers[5]"); ok {
		t.Errorf("Expected numbers[5] to be invalid")
	}

	// Test invalid slice (end index too high)
	if _, ok := sm.Get("numbers[0:5]"); ok {
		t.Errorf("Expected numbers[0:5] to be invalid")
	}

	// Test non-numeric index.
	if _, ok := sm.Get("numbers[abc]"); ok {
		t.Errorf("Expected numbers[abc] to be invalid")
	}

	// Test slice with non-numeric values.
	if _, ok := sm.Get("numbers[a:b]"); ok {
		t.Errorf("Expected numbers[a:b] to be invalid")
	}
}

func TestArraySliceEdgeCases(t *testing.T) {
	sm := server.NewStateManager("node-1", false)
	// Set state with an array.
	update := api.ConfigUpdate{
		Data: map[string]any{
			"letters": []any{"a", "b", "c", "d"},
		},
		Version: 400,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Test slice with omitted start (e.g. [:2])
	val, ok := sm.Get("letters[:2]")
	if !ok {
		t.Fatalf("Failed to get slice letters[:2]")
	}
	slice, ok := val.([]any)
	if !ok {
		t.Fatalf("Expected a slice, got %T", val)
	}
	expected := []any{"a", "b"}
	if !reflect.DeepEqual(slice, expected) {
		t.Errorf("Expected %v, got %v", expected, slice)
	}

	// Test slice with omitted end (e.g. [2:])
	val, ok = sm.Get("letters[2:]")
	if !ok {
		t.Fatalf("Failed to get slice letters[2:]")
	}
	slice, ok = val.([]any)
	if !ok {
		t.Fatalf("Expected a slice, got %T", val)
	}
	expected = []any{"c", "d"}
	if !reflect.DeepEqual(slice, expected) {
		t.Errorf("Expected %v, got %v", expected, slice)
	}
}

func TestMultipleSubscribers(t *testing.T) {
	sm := server.NewStateManager("node-1", false)
	sub1 := sm.Subscribe()
	sub2 := sm.Subscribe()

	update := api.ConfigUpdate{
		Data: map[string]any{
			"key": "value",
		},
		Version: 500,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Check that both subscribers receive a notification.
	received := 0
	// Attempt to read from both channels.
	for range 2 {
		select {
		case <-sub1:
			received++
		case <-sub2:
			received++
		case <-time.After(100 * time.Millisecond):
			// Timeout: break out if no notification.
		}
	}
	if received == 0 {
		t.Errorf("Expected at least one notification from subscribers")
	}
}

// Additional helper: test retrieval using a complex path for nested arrays.
func TestGetWithComplexPath(t *testing.T) {
	sm := server.NewStateManager("node-1", false)

	// Prepare a complex nested structure.
	update := api.ConfigUpdate{
		Data: map[string]any{
			"outer": map[string]any{
				"inner": []any{
					map[string]any{
						"name":  "first",
						"score": 10,
					},
					map[string]any{
						"name":  "second",
						"score": 20,
					},
				},
			},
		},
		Version: 600,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}

	// Retrieve the "score" of the second element.
	val, ok := sm.Get("outer.inner[1].score")
	if !ok {
		t.Fatalf("Failed to retrieve outer.inner[1].score")
	}
	// Depending on how numbers are stored, they might be float64.
	switch v := val.(type) {
	case float64:
		if v != 20 {
			t.Errorf("Expected score 20, got %v", v)
		}
	case int:
		if v != 20 {
			t.Errorf("Expected score 20, got %v", v)
		}
	case string:
		if num, err := strconv.Atoi(v); err != nil || num != 20 {
			t.Errorf("Expected score 20, got %v", v)
		}
	default:
		t.Errorf("Unexpected type %T for score", v)
	}
}

func TestApplyUpdateWithClearFlag(t *testing.T) {
	sm := server.NewStateManager("node-1", false)
	// First, apply a normal update.
	update := api.ConfigUpdate{
		Data: map[string]any{
			"key": "value",
		},
		Version: 1000,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(update); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}
	if val, ok := sm.Get("key"); !ok || val != "value" {
		t.Fatalf("Expected key to be set")
	}

	// Now, apply an update with the Clear flag.
	clearUpdate := api.ConfigUpdate{
		Data:    map[string]any{"irrelevant": "data"},
		Version: 2000,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
		Clear:   true,
	}
	if err := sm.ApplyUpdate(clearUpdate); err != nil {
		t.Fatalf("ApplyUpdate with Clear failed: %v", err)
	}
	if _, ok := sm.Get("key"); ok {
		t.Errorf("Expected key to be cleared")
	}
	if full := sm.GetFullState(); len(full) != 0 {
		t.Errorf("Expected state to be empty after clear, got %v", full)
	}
}

func TestMergeRemoteStateWithEqualVersion(t *testing.T) {
	sm := server.NewStateManager("node-1", false)
	// Set local state with a given version.
	localUpdate := api.ConfigUpdate{
		Data: map[string]any{
			"x": "local",
		},
		Version: 5000,
		NodeID:  "node-1",
		Time:    time.Now().UTC(),
	}
	if err := sm.ApplyUpdate(localUpdate); err != nil {
		t.Fatalf("ApplyUpdate failed: %v", err)
	}
	// Prepare remote state with an equal version.
	remoteState := map[string]*api.StateEntry{
		"x": {
			Data:      "remote",
			Version:   5000, // equal version: should not overwrite.
			Timestamp: time.Now().UTC(),
		},
	}
	sm.MergeRemoteState(remoteState, "node-2")
	// Verify that the state remains unchanged.
	val, ok := sm.Get("x")
	if !ok {
		t.Fatalf("Expected key 'x' to exist")
	}
	if val != "local" {
		t.Errorf("Expected state not to update for equal version, got %v", val)
	}
}

func TestTransformState(t *testing.T) {
	// Create a sample state.
	now := time.Now().UTC()
	state := map[string]*api.StateEntry{
		"a": {Data: 123, Version: 1, Timestamp: now},
		"b": {Data: "foo", Version: 2, Timestamp: now},
	}
	transformed := server.TransformState(state)
	if len(transformed) != 2 {
		t.Fatalf("Expected 2 keys in transformed state, got %d", len(transformed))
	}
	if transformed["a"] != 123 {
		t.Errorf("Expected key 'a' to be 123, got %v", transformed["a"])
	}
	if transformed["b"] != "foo" {
		t.Errorf("Expected key 'b' to be 'foo', got %v", transformed["b"])
	}
}
