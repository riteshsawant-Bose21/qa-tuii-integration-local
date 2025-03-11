package main

import (
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
)

// TestMarkDirtyConcurrent checks for potential race conditions by calling MarkDirty concurrently.
// (Run this test with `go test -race`.)
func TestMarkDirtyConcurrent(t *testing.T) {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "PersistenceTest",
		LogDir:      "/tmp/persistence_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	// Create a temporary directory and file for our test state.
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.db")

	sm := server.NewStateManager("test_manager")
	if err := sm.Set("testKey", "testValue"); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	// Create the persistence object.
	cp, err := server.NewConfigPersistence(configPath, sm, true)
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

	// Optionally, check that the state file exists.
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		t.Errorf("Expected state file %s to exist", configPath)
	}
}

// TestLoadStateNonExistent verifies that when the state file does not exist,
// LoadState logs an info message and returns nil (allowing the service to start with an empty state).
func TestLoadStateNonExistent(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TestLoadStateNonExistent",
		LogDir:      "/tmp/persistence_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "nonexistent.db")

	sm := server.NewStateManager("testnode")
	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Call LoadState. Since the file doesn't exist, it should return nil.
	if err := cp.LoadState(); err != nil {
		t.Fatalf("LoadState failed on non-existent file: %v", err)
	}
}

// TestSaveAndLoadState tests that saving and then loading the state using the latest key works as expected.
func TestSaveAndLoadState(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.db")

	sm := server.NewStateManager("testnode")
	testKey, testValue := "testKey", "testValue"
	if err := sm.Set(testKey, testValue); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	// Create the persistence object.
	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Save the state.
	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Close the first persistence instance before simulating a restart.
	cp.Close()

	// Simulate restart by creating a new persistence object.
	newSM := server.NewStateManager("testnode")
	newCP, err := server.NewConfigPersistence(configPath, newSM, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}
	defer newCP.Close()

	// Load the saved state.
	if err := newCP.LoadState(); err != nil {
		t.Fatalf("LoadState failed: %v", err)
	}

	// Check that the state was applied.
	fullState := newSM.GetFullState()
	entry, exists := fullState[testKey]
	if !exists {
		t.Fatalf("Key %s not found after load", testKey)
	}
	if entry.Data != testValue {
		t.Fatalf("Expected value %v for key %s, got %v", testValue, testKey, entry.Data)
	}
}

// TestValidateStateFile verifies that after a proper save the ValidateState returns nil.
func TestValidateStateFile(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.db")

	sm := server.NewStateManager("testnode")
	if err := sm.Set("key", "value"); err != nil {
		t.Fatalf("Failed to set state: %v", err)
	}
	cp, err := server.NewConfigPersistence(configPath, sm, false)
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
	sm := server.NewStateManager("testnode")

	// Set a known state.
	state := map[string]*api.StateEntry{
		"key1": {Data: "value1"},
		"key2": {Data: 42},
	}

	sm.SetState(state)

	cp, err := server.NewConfigPersistence("dummy", sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Get the full state.
	fullState := sm.GetFullState()
	checksum1, err := cp.CalculateChecksum(fullState)
	if err != nil {
		t.Fatalf("CalculateChecksum returned error: %v", err)
	}

	// Serialize the same state and calculate again.
	checksum2, err := cp.CalculateChecksum(fullState)
	if err != nil {
		t.Fatalf("CalculateChecksum returned error: %v", err)
	}

	if checksum1 != checksum2 {
		t.Errorf("Expected same checksum for identical state, got %s and %s", checksum1, checksum2)
	}
}

// TestActiveSnapshot tests the snapshot functionality.
// It verifies that saving a snapshot and activating it via the active snapshot pointer
// causes LoadState() to load the snapshot's state.
func TestActiveSnapshot(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.db")

	// Initialize state manager and persistence.
	sm := server.NewStateManager("testnode")
	if err := sm.Set("key", "value_latest"); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Save the initial state
	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Modify state to simulate a snapshot.
	if err := sm.Set("key", "value_snapshot"); err != nil {
		t.Fatalf("Failed to update state: %v", err)
	}

	// Save the new state as a snapshot with key "snapshot1".
	if err := cp.SaveSnapshot("snapshot1"); err != nil {
		t.Fatalf("SaveSnapshot failed: %v", err)
	}

	// Change the state again to simulate a difference.
	if err := sm.Set("key", "value_modified"); err != nil {
		t.Fatalf("Failed to modify state: %v", err)
	}

	// Activate the snapshot "snapshot1".
	if err := cp.ActivateSnapshot("snapshot1"); err != nil {
		t.Fatalf("ActivateSnapshot failed: %v", err)
	}

	// Verify that the state manager now holds the snapshot's state.
	fullState := sm.GetFullState()
	entry, exists := fullState["key"]
	if !exists {
		t.Fatalf("Key 'key' not found after activating snapshot")
	}
	if entry.Data != "value_snapshot" {
		t.Errorf("Expected active snapshot state 'value_snapshot', got %v", entry.Data)
	}
	cp.Close()

	// Simulate a new instance loading state to verify the active pointer.
	newSM := server.NewStateManager("testnode")
	newCP, err := server.NewConfigPersistence(configPath, newSM, false)
	if err != nil {
		t.Fatalf("Failed to reinitialize persistence: %v", err)
	}
	defer newCP.Close()

	if err := newCP.LoadState(); err != nil {
		t.Fatalf("LoadState failed: %v", err)
	}

	newState := newSM.GetFullState()
	newEntry, exists := newState["key"]
	if !exists {
		t.Fatalf("Key 'key' not found after reloading state")
	}
	if newEntry.Data != "value_snapshot" {
		t.Errorf("Expected reloaded state to be 'value_snapshot', got %v", newEntry.Data)
	}
}
