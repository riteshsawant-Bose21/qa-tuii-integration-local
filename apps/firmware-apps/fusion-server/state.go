package main

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// PersistentState represents the structure of our saved state
type PersistentState struct {
	Version int64                  `json:"version"`
	Config  map[string]interface{} `json:"config"`
}

// ConfigPersistence handles saving and loading state
type ConfigPersistence struct {
	sync.RWMutex
	filePath    string
	saveTimeout time.Duration
	dirty       bool
	stopChan    chan struct{}
}

func NewConfigPersistence(filePath string) *ConfigPersistence {
	return &ConfigPersistence{
		filePath:    filePath,
		saveTimeout: 5 * time.Second,
		stopChan:    make(chan struct{}),
	}
}

func (cp *ConfigPersistence) Start() {
	go cp.periodicSave()
}

func (cp *ConfigPersistence) Stop() {
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
		return err
	}

	// Get current state
	state := PersistentState{
		Version: configVersion,
		Config:  make(map[string]interface{}),
	}

	config.Range(func(key, value interface{}) bool {
		state.Config[key.(string)] = value
		return true
	})

	// Marshal with indentation for readability
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}

	// Write to temporary file first
	tempFile := cp.filePath + ".tmp"
	if err := os.WriteFile(tempFile, data, 0644); err != nil {
		return err
	}

	// Rename temporary file to actual file (atomic operation)
	if err := os.Rename(tempFile, cp.filePath); err != nil {
		os.Remove(tempFile) // Clean up temp file if rename fails
		return err
	}

	cp.dirty = false
	return nil
}

// LoadState loads the state from disk
func (cp *ConfigPersistence) LoadState() error {
	cp.Lock()
	defer cp.Unlock()

	data, err := os.ReadFile(cp.filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil // Not an error if file doesn't exist yet
		}
		return err
	}

	var state PersistentState
	if err := json.Unmarshal(data, &state); err != nil {
		return err
	}

	// Apply loaded state
	configMutex.Lock()
	defer configMutex.Unlock()

	if state.Version > configVersion {
		configVersion = state.Version
		for k, v := range state.Config {
			config.Store(k, v)
		}
		log.Printf("Loaded state from disk, version: %d", configVersion)
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
					log.Printf("Error saving state: %v", err)
				}
			}
			cp.Unlock()
		case <-cp.stopChan:
			return
		}
	}
}
