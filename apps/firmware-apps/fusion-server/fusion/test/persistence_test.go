package main

import (
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/utils"
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
	checksum, err := utils.CalculateChecksum(sm.GetStateMap())
	if err != nil {
		t.Fatalf("CalculateChecksum returned error: %v", err)
	}

	if fullState.Checksum != checksum {
		t.Errorf("Expected same checksum for identical state, got %s and %s", fullState.Checksum, checksum)
	}
}
