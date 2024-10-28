package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// PersistentState represents the structure of our saved state
type PersistentState struct {
	Version int64                  `json:"version"`
	State   map[string]*StateEntry `json:"state"`
}

// ConfigPersistence handles saving and loading state
type ConfigPersistence struct {
	sync.RWMutex
	filePath     string
	saveTimeout  time.Duration
	dirty        bool
	stopChan     chan struct{}
	stateManager *StateManager
	logger       *log.Logger
}

func NewConfigPersistence(filePath string, stateManager *StateManager) *ConfigPersistence {
	return &ConfigPersistence{
		filePath:     filePath,
		saveTimeout:  5 * time.Second,
		stopChan:     make(chan struct{}),
		stateManager: stateManager,
		logger:       log.New(os.Stdout, "[PERSIST] ", log.LstdFlags),
	}
}

func (cp *ConfigPersistence) Start() {
	cp.logger.Printf("Starting persistence system with path: %s", cp.filePath)
	go cp.periodicSave()
}

func (cp *ConfigPersistence) Stop() {
	cp.logger.Printf("Stopping persistence system")
	close(cp.stopChan)
	cp.SaveState() // Final save
}

// SaveState persists the current state to disk
func (cp *ConfigPersistence) SaveState() error {
	cp.Lock()
	defer cp.Unlock()

	// Create state directory if it doesn't exist
	dir := filepath.Dir(cp.filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %v", err)
	}

	// Get current state from StateManager
	state := PersistentState{
		Version: cp.stateManager.version,
		State:   cp.stateManager.GetFullState(),
	}

	// Marshal with indentation for readability
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal state: %v", err)
	}

	// Write to temporary file first
	tempFile := cp.filePath + ".tmp"
	if err := os.WriteFile(tempFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write temporary file: %v", err)
	}

	// Rename temporary file to actual file (atomic operation)
	if err := os.Rename(tempFile, cp.filePath); err != nil {
		os.Remove(tempFile) // Clean up temp file if rename fails
		return fmt.Errorf("failed to rename temporary file: %v", err)
	}

	cp.dirty = false
	cp.logger.Printf("State saved successfully (version %d)", state.Version)
	return nil
}

// LoadState loads the state from disk
func (cp *ConfigPersistence) LoadState() error {
	cp.Lock()
	defer cp.Unlock()

	data, err := os.ReadFile(cp.filePath)
	if err != nil {
		if os.IsNotExist(err) {
			cp.logger.Printf("No existing state file found at %s", cp.filePath)
			return nil // Not an error if file doesn't exist yet
		}
		return fmt.Errorf("failed to read state file: %v", err)
	}

	var persistedState PersistentState
	if err := json.Unmarshal(data, &persistedState); err != nil {
		return fmt.Errorf("failed to unmarshal state: %v", err)
	}

	// Apply loaded state to StateManager
	cp.stateManager.Lock()
	defer cp.stateManager.Unlock()

	if persistedState.Version > cp.stateManager.version {
		// Update state entries
		for key, entry := range persistedState.State {
			cp.stateManager.state[key] = entry
		}

		// Update version
		cp.stateManager.version = persistedState.Version

		// Notify listeners about restored state
		for key, entry := range persistedState.State {
			cp.stateManager.notifyListeners(StateUpdate{
				Key:     key,
				Value:   entry.Value,
				Version: entry.Version,
				NodeID:  entry.NodeID,
			})
		}

		cp.logger.Printf("Loaded state from disk (version %d, %d entries)",
			persistedState.Version, len(persistedState.State))
	} else {
		cp.logger.Printf("Skipped loading outdated state from disk (disk version %d < current version %d)",
			persistedState.Version, cp.stateManager.version)
	}

	return nil
}

func (cp *ConfigPersistence) MarkDirty() {
	cp.Lock()
	cp.dirty = true
	cp.Unlock()
}

func (cp *ConfigPersistence) periodicSave() {
	ticker := time.NewTicker(cp.saveTimeout)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			cp.Lock()
			if cp.dirty {
				if err := cp.SaveState(); err != nil {
					cp.logger.Printf("Error saving state: %v", err)
				}
			}
			cp.Unlock()

		case <-cp.stopChan:
			cp.logger.Printf("Periodic save routine stopped")
			return
		}
	}
}

// Helper function to verify persistence
func (cp *ConfigPersistence) VerifyPersistence() error {
	// Read the current state file
	data, err := os.ReadFile(cp.filePath)
	if err != nil {
		return fmt.Errorf("failed to read state file for verification: %v", err)
	}

	var persistedState PersistentState
	if err := json.Unmarshal(data, &persistedState); err != nil {
		return fmt.Errorf("failed to unmarshal state for verification: %v", err)
	}

	// Get current state
	currentState := cp.stateManager.GetFullState()
	currentVersion := cp.stateManager.version

	// Compare versions
	if persistedState.Version != currentVersion {
		return fmt.Errorf("version mismatch: persisted=%d, current=%d",
			persistedState.Version, currentVersion)
	}

	// Compare entries
	for key, entry := range currentState {
		persistedEntry, exists := persistedState.State[key]
		if !exists {
			return fmt.Errorf("key %s exists in memory but not in persistent storage", key)
		}
		if entry.Version != persistedEntry.Version {
			return fmt.Errorf("version mismatch for key %s: persisted=%d, current=%d",
				key, persistedEntry.Version, entry.Version)
		}
	}

	cp.logger.Printf("Persistence verification successful")
	return nil
}
