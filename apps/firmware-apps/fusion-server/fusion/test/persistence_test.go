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
		t.Fatalf("Failed to initialize persistance: %v", err)
	}

	// Run many goroutines calling MarkDirty concurrently.
	const numGoroutines = 50
	const iterations = 20
	var wg sync.WaitGroup

	for i := 0; i < numGoroutines; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			for j := 0; j < iterations; j++ {
				cp.MarkDirty()
				// Optionally sleep a bit to simulate work.
				time.Sleep(5 * time.Millisecond)
			}
		}(i)
	}
	wg.Wait()

	// After all MarkDirty calls, we can try validating the state file.
	if err := cp.ValidateState(); err != nil {
		t.Errorf("ValidateStateFile error: %v", err)
	}

	// Optionally, check that the state file exists.
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		t.Errorf("Expected state file %s to exist", configPath)
	}
}

// TestLoadStateNonExistent verifies that when the state file does not exist,
// LoadState logs an info message and returns nil (allowing the service to start with an empty state).
func TestLoadStateNonExistent(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "nonexistent.db")

	sm := server.NewStateManager("testnode")
	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistance: %v", err)
	}

	// Call LoadState. Since the file doesn't exist, it should return nil.
	if err := cp.LoadState(); err != nil {
		t.Fatalf("LoadState failed on non-existent file: %v", err)
	}
}

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
	defer cp.Close() // CLOSE THE DB AFTER USE

	// Save the state.
	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}
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

// TestValidateStateFile verifies that after a proper save the ValidateStateFile returns nil.
func TestValidateStateFile(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.db")

	sm := server.NewStateManager("testnode")
	if err := sm.Set("key", "value"); err != nil {
		t.Fatalf("Failed to set state: %v", err)
	}
	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistance: %v", err)
	}

	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Validate the state file.
	if err := cp.ValidateState(); err != nil {
		t.Fatalf("ValidateStateFile failed: %v", err)
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
		t.Fatalf("Failed to initialize persistance: %v", err)
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
		t.Fatalf("calculateChecksum returned error: %v", err)
	}

	if checksum1 != checksum2 {
		t.Errorf("Expected same checksum for identical state, got %s and %s", checksum1, checksum2)
	}
}
