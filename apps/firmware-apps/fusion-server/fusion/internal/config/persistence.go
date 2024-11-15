package config

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// ConfigPersistence handles persistent storage of configuration state
type ConfigPersistence struct {
	filePath     string
	stateManager *StateManager
	stopChan     chan struct{}
	dirty        bool
	mutex        sync.Mutex
}

// NewConfigPersistence creates a new persistence manager
func NewConfigPersistence(filePath string, stateManager *StateManager) *ConfigPersistence {
	return &ConfigPersistence{
		filePath:     filePath,
		stateManager: stateManager,
		stopChan:     make(chan struct{}),
	}
}

// Start begins the persistence routine
func (p *ConfigPersistence) Start() {
	go p.persistenceLoop()
}

// Stop halts the persistence routine
func (p *ConfigPersistence) Stop() {
	close(p.stopChan)
}

// LoadState loads the persisted state from disk
func (p *ConfigPersistence) LoadState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	// Ensure directory exists
	dir := filepath.Dir(p.filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create directory: %v", err)
	}

	file, err := os.Open(p.filePath)
	if os.IsNotExist(err) {
		log.Printf("[ERROR] No existing state file found at %s", p.filePath)
		return nil
	} else if err != nil {
		return fmt.Errorf("failed to open state file: %v", err)
	}
	defer file.Close()

	var state map[string]interface{}
	if err := json.NewDecoder(file).Decode(&state); err != nil {
		return fmt.Errorf("failed to decode state: %v", err)
	}

	// Apply loaded state
	for key, value := range state {
		if err := p.stateManager.Set(key, value); err != nil {
			log.Printf("Error restoring key %s: %v", key, err)
		}
	}

	return nil
}

// SaveState persists the current state to disk
func (p *ConfigPersistence) SaveState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	// Create temporary file
	tmpFile := p.filePath + ".tmp"
	file, err := os.Create(tmpFile)
	if err != nil {
		return fmt.Errorf("failed to create temp file: %v", err)
	}

	// Get current state
	state := p.stateManager.GetFullState()

	// Write state to temp file
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(state); err != nil {
		file.Close()
		os.Remove(tmpFile)
		return fmt.Errorf("failed to encode state: %v", err)
	}

	if err := file.Close(); err != nil {
		return fmt.Errorf("failed to close temp file: %v", err)
	}

	// Rename temp file to actual file
	if err := os.Rename(tmpFile, p.filePath); err != nil {
		return fmt.Errorf("failed to save state file: %v", err)
	}

	p.dirty = false
	return nil
}

// MarkDirty marks the state as needing persistence
func (p *ConfigPersistence) MarkDirty() {
	p.mutex.Lock()
	p.dirty = true
	p.mutex.Unlock()
}

func (p *ConfigPersistence) persistenceLoop() {
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopChan:
			return
		case <-ticker.C:
			p.mutex.Lock()
			if p.dirty {
				if err := p.SaveState(); err != nil {
					log.Printf("[ERROR] Failed to persist state: %v", err)
				}
			}
			p.mutex.Unlock()
		}
	}
}
