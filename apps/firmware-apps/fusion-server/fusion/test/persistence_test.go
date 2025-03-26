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

const (
	databaseName = "fusion_test.db"
)

// TestMarkDirtyConcurrent checks for potential race conditions by calling MarkDirty concurrently.
// (Run this test with `go test -race`.)
func TestMarkDirtyConcurrent(t *testing.T) {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "PersistenceTest",
		LogDir:      "/tmp/persistence_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})

	// Create a temporary directory and file for our test state.
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := server.NewStateManager("test_manager")
	if err := sm.Set("testKey", "testValue"); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	// Create the persistence object.
	cp, err := server.NewPersistence(configPath, sm, true)
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

// TestValidateStateFile verifies that after a proper save ValidateState returns without error.
func TestValidateStateFile(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, databaseName)

	sm := server.NewStateManager("testnode")
	if err := sm.Set("key", "value"); err != nil {
		t.Fatalf("Failed to set state: %v", err)
	}
	cp, err := server.NewPersistence(configPath, sm, false)
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

	cp, err := server.NewPersistence("dummy", sm, false)
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
