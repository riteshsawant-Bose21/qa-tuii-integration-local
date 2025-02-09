package main

import (
	"io/ioutil"
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
	configPath := filepath.Join(tmpDir, "config.json")

	sm := server.NewStateManager("test_manager")
	if err := sm.Set("testKey", "testValue"); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	// Create the persistence object.
	cp := server.NewConfigPersistence(configPath, sm, true)

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
	if err := cp.ValidateStateFile(); err != nil {
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
	configPath := filepath.Join(tmpDir, "nonexistent.json")

	sm := server.NewStateManager("testnode")
	cp := server.NewConfigPersistence(configPath, sm, false)

	// Call LoadState. Since the file doesn't exist, it should return nil.
	if err := cp.LoadState(); err != nil {
		t.Fatalf("LoadState failed on non-existent file: %v", err)
	}
}

// TestSaveAndLoadState verifies that after saving state to disk, the same state can be loaded back.
func TestSaveAndLoadState(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.json")

	sm := server.NewStateManager("testnode")
	testKey, testValue := "testKey", "testValue"
	if err := sm.Set(testKey, testValue); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	// Create the persistence object.
	cp := server.NewConfigPersistence(configPath, sm, false)

	// Save the state.
	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Create a new StateManager instance and persistence object to load the saved state.
	// (This simulates restarting the service.)
	newSM := server.NewStateManager("testnode")
	newCP := server.NewConfigPersistence(configPath, newSM, false)
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
	configPath := filepath.Join(tmpDir, "config.json")

	sm := server.NewStateManager("testnode")
	if err := sm.Set("key", "value"); err != nil {
		t.Fatalf("Failed to set state: %v", err)
	}
	cp := server.NewConfigPersistence(configPath, sm, false)
	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Validate the state file.
	if err := cp.ValidateStateFile(); err != nil {
		t.Fatalf("ValidateStateFile failed: %v", err)
	}
}

// TestCorruptedStateFile verifies that if the state file is corrupted (e.g. invalid JSON),
// LoadState renames it with a ".corrupted" suffix.
func TestCorruptedStateFile(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.json")

	// Write a corrupted JSON file.
	corruptContent := []byte("{ this is not valid json }")
	if err := ioutil.WriteFile(configPath, corruptContent, 0644); err != nil {
		t.Fatalf("Failed to write corrupted file: %v", err)
	}

	sm := server.NewStateManager("testnode")
	cp := server.NewConfigPersistence(configPath, sm, false)

	// LoadState should log an error, backup the corrupted file, and return nil.
	if err := cp.LoadState(); err != nil {
		t.Errorf("LoadState should not fail outright on corrupted file, but got: %v", err)
	}

	// The original file should be renamed to have a ".corrupted" suffix.
	corruptedBackup := configPath + ".corrupted"
	if _, err := os.Stat(corruptedBackup); os.IsNotExist(err) {
		t.Errorf("Expected corrupted file backup %s to exist", corruptedBackup)
	}

	// Optionally, check that the original file no longer exists.
	if _, err := os.Stat(configPath); err == nil {
		t.Errorf("Expected original file %s to have been renamed", configPath)
	}
}

// TestBackupRemoval tests that the backup file is removed after a successful save.
// This test saves state, then changes the file so that a backup would be created, then saves again,
// and verifies that the backup file no longer exists.
func TestBackupRemoval(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "config.json")
	backupPath := configPath + ".bak"

	sm := server.NewStateManager("testnode")
	if err := sm.Set("key", "initial"); err != nil {
		t.Fatalf("Failed to set state: %v", err)
	}
	cp := server.NewConfigPersistence(configPath, sm, false)

	// First save.
	if err := cp.SaveState(); err != nil {
		t.Fatalf("First SaveState failed: %v", err)
	}

	// Simulate an update by writing an extra backup file manually.
	if err := os.WriteFile(backupPath, []byte("backup content"), 0644); err != nil {
		t.Fatalf("Failed to write backup file: %v", err)
	}

	// Change state.
	if err := sm.Set("key", "updated"); err != nil {
		t.Fatalf("Failed to update state: %v", err)
	}

	// Save again. This should remove the backup file on success.
	if err := cp.SaveState(); err != nil {
		t.Fatalf("Second SaveState failed: %v", err)
	}

	// Check that backup file is removed.
	if _, err := os.Stat(backupPath); err == nil {
		t.Errorf("Expected backup file %s to be removed after successful save", backupPath)
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

	cp := server.NewConfigPersistence("dummy", sm, false)

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
