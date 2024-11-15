package config

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sync"
)

type ConfigPersistence struct {
	filePath     string
	stateManager *StateManager
	mutex        sync.Mutex
}

func NewConfigPersistence(filePath string, stateManager *StateManager) *ConfigPersistence {
	return &ConfigPersistence{
		filePath:     filePath,
		stateManager: stateManager,
	}
}

func (p *ConfigPersistence) LoadState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	dir := filepath.Dir(p.filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("[ERROR] Failed to create directory: %v", err)
	}

	file, err := os.Open(p.filePath)
	if os.IsNotExist(err) {
		log.Printf("[INFO] No existing state file found at %s", p.filePath)
		return nil
	} else if err != nil {
		return fmt.Errorf("[ERROR] Failed to open state file: %v", err)
	}
	defer file.Close()

	var state map[string]interface{}
	if err := json.NewDecoder(file).Decode(&state); err != nil {
		return fmt.Errorf("[ERROR] Failed to decode state: %v", err)
	}

	for key, value := range state {
		if err := p.stateManager.Set(key, value); err != nil {
			log.Printf("[WARN] Error restoring key %s: %v", key, err)
		}
	}
	return nil
}

func (p *ConfigPersistence) SaveState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	tmpFile := p.filePath + ".tmp"
	file, err := os.Create(tmpFile)
	if err != nil {
		return fmt.Errorf("[ERROR] Failed to create temp file: %v", err)
	}
	defer file.Close()

	state := p.stateManager.GetFullState()
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")

	if err := encoder.Encode(state); err != nil {
		os.Remove(tmpFile)
		return fmt.Errorf("[ERROR] Failed to encode state: %v", err)
	}

	if err := file.Sync(); err != nil {
		os.Remove(tmpFile)
		return fmt.Errorf("[ERROR] Failed to sync temp file: %v", err)
	}

	if err := os.Rename(tmpFile, p.filePath); err != nil {
		return fmt.Errorf("[ERROR] Failed to save state file: %v", err)
	}

	log.Printf("[PERSISTENCE] State saved successfully")
	return nil
}

func (p *ConfigPersistence) MarkDirty() {
	go func() {
		if err := p.SaveState(); err != nil {
			log.Printf("[ERROR] Failed to persist state: %v", err)
		}
	}()
}
