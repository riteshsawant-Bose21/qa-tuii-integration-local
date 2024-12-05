package server

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// PersistentState represents the structure we'll save to disk
type PersistentState struct {
	Version   int64                      `json:"version"`
	Timestamp time.Time                  `json:"timestamp"`
	Checksum  string                     `json:"checksum"`
	State     map[string]*api.StateEntry `json:"state"`
}

type ConfigPersistence struct {
	filePath     string
	stateManager *StateManager
	mutex        sync.RWMutex
	verbose      bool
	lastSave     time.Time
	saveDebounce time.Duration
}

func NewConfigPersistence(filePath string, stateManager *StateManager, verbose bool) *ConfigPersistence {
	return &ConfigPersistence{
		filePath:     filePath,
		stateManager: stateManager,
		verbose:      verbose,
		saveDebounce: 100 * time.Millisecond,
	}
}

// calculateChecksum generates a SHA-256 hash of the state
func (p *ConfigPersistence) calculateChecksum(state map[string]*api.StateEntry) (string, error) {
	data, err := json.Marshal(state)
	if err != nil {
		return "", err
	}
	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash), nil
}

func (p *ConfigPersistence) LoadState() error {
	logger := logging.GetLogger()

	// Ensure directory exists
	p.mutex.Lock()
	dir := filepath.Dir(p.filePath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		p.mutex.Unlock()
		return fmt.Errorf("failed to create directory: %v", err)
	}

	file, err := os.Open(p.filePath)
	p.mutex.Unlock()

	if os.IsNotExist(err) {
		logger.Info("No existing state file found at %s", p.filePath)
		return nil
	} else if err != nil {
		logger.Error("Failed to open state file: %v", err)
		return nil // Allow service to start with empty state
	}
	defer file.Close()

	data, err := io.ReadAll(file)
	if err != nil {
		logger.Error("Failed to read state file: %v", err)
		return nil // Allow service to start with empty state
	}

	var persistentState PersistentState
	if err := json.Unmarshal(data, &persistentState); err != nil {
		logger.Error("Failed to decode state file: %v", err)
		// Try to rename corrupted file for investigation
		backupPath := p.filePath + ".corrupted"
		if renameErr := os.Rename(p.filePath, backupPath); renameErr != nil {
			logger.Error("Failed to backup corrupted state file: %v", renameErr)
		} else {
			logger.Info("Corrupted state file backed up to: %s", backupPath)
		}
		return nil // Allow service to start with empty state
	}

	// Verify checksum without holding any locks
	calculatedChecksum, err := p.calculateChecksum(persistentState.State)
	if err != nil {
		logger.Error("Failed to calculate checksum: %v", err)
		return nil // Allow service to start with empty state
	}

	if calculatedChecksum != persistentState.Checksum {
		logger.Error("State file corruption detected: checksum mismatch")
		// Backup the corrupted file for investigation
		backupPath := p.filePath + ".corrupted"
		if err := os.Rename(p.filePath, backupPath); err != nil {
			logger.Error("Failed to backup corrupted state file: %v", err)
		} else {
			logger.Info("Corrupted state file backed up to: %s", backupPath)
		}
		return nil // Allow service to start with empty state
	}

	// Apply state entries
	for key, entry := range persistentState.State {
		if err := p.stateManager.Set(key, entry.Data); err != nil {
			logger.Warn("Error restoring key %s: %v", key, err)
		}
	}

	if p.verbose {
		logger.Info("Loaded state version %d from %s", persistentState.Version, p.filePath)
	}

	return nil
}

func (p *ConfigPersistence) SaveState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	logger := logging.GetLogger()

	// Get current state
	state := p.stateManager.GetFullState()
	checksum, err := p.calculateChecksum(state)
	if err != nil {
		return fmt.Errorf("failed to calculate checksum: %v", err)
	}

	persistentState := PersistentState{
		Version:   p.stateManager.GetVersion(),
		Timestamp: time.Now().UTC(),
		Checksum:  checksum,
		State:     state,
	}

	// Create temporary file
	tmpFile := p.filePath + ".tmp"
	file, err := os.OpenFile(tmpFile, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return fmt.Errorf("failed to create temp file: %v", err)
	}
	defer func() {
		file.Close()
		if err != nil {
			os.Remove(tmpFile)
		}
	}()

	// Write to temporary file
	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(persistentState); err != nil {
		return fmt.Errorf("failed to encode state: %v", err)
	}

	// Ensure all data is written to disk
	if err := file.Sync(); err != nil {
		return fmt.Errorf("failed to sync temp file: %v", err)
	}

	// Close file before rename
	if err := file.Close(); err != nil {
		return fmt.Errorf("failed to close temp file: %v", err)
	}

	// Atomic rename
	backupFile := p.filePath + ".bak"
	if _, err := os.Stat(p.filePath); err == nil {
		if err := os.Rename(p.filePath, backupFile); err != nil {
			return fmt.Errorf("failed to create backup: %v", err)
		}
	}

	if err := os.Rename(tmpFile, p.filePath); err != nil {
		// Try to restore backup if rename fails
		if _, err := os.Stat(backupFile); err == nil {
			os.Rename(backupFile, p.filePath)
		}
		return fmt.Errorf("failed to save state file: %v", err)
	}

	// Remove backup file after successful save
	os.Remove(backupFile)

	if p.verbose {
		logger.Debug("State saved successfully (version: %d, checksum: %s)",
			persistentState.Version, checksum[:8])
	}

	p.lastSave = time.Now()
	return nil
}

func (p *ConfigPersistence) MarkDirty() {

	if time.Since(p.lastSave) < p.saveDebounce {
		time.Sleep(p.saveDebounce)
	}

	if err := p.SaveState(); err != nil {
		logging.GetLogger().Error("Failed to persist state: %v", err)
	}
}

// ValidateStateFile verifies if a state file is valid
func (p *ConfigPersistence) ValidateStateFile() error {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	file, err := os.Open(p.filePath)
	if err != nil {
		return fmt.Errorf("failed to open state file: %v", err)
	}
	defer file.Close()

	var persistentState PersistentState
	if err := json.NewDecoder(file).Decode(&persistentState); err != nil {
		return fmt.Errorf("failed to decode state file: %v", err)
	}

	calculatedChecksum, err := p.calculateChecksum(persistentState.State)
	if err != nil {
		return fmt.Errorf("failed to calculate checksum: %v", err)
	}

	if calculatedChecksum != persistentState.Checksum {
		return fmt.Errorf("state file corruption detected: checksum mismatch")
	}

	return nil
}
