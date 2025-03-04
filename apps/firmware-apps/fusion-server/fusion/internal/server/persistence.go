package server

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"sync"
	"time"

	"go.etcd.io/bbolt"
)

// PersistentState represents the structure saved in database
type PersistentState struct {
	Version   int64                      `json:"version"`
	Timestamp time.Time                  `json:"timestamp"`
	Checksum  string                     `json:"checksum"`
	State     map[string]*api.StateEntry `json:"state"`
}

type ConfigPersistence struct {
	dbPath       string
	stateManager *StateManager
	mutex        sync.RWMutex
	db           *bbolt.DB
	verbose      bool
	lastSave     time.Time
	saveDebounce time.Duration
}

func NewConfigPersistence(dbPath string, stateManager *StateManager, verbose bool) (*ConfigPersistence, error) {
	db, err := bbolt.Open(dbPath, 0600, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %v", err)
	}

	return &ConfigPersistence{
		dbPath:       dbPath,
		stateManager: stateManager,
		db:           db,
		verbose:      verbose,
		saveDebounce: 100 * time.Millisecond,
	}, nil
}

// Close closes the database instance safely.
func (p *ConfigPersistence) Close() {
	p.db.Close()
}

// CalculateChecksum generates a SHA-256 hash of the state
func (p *ConfigPersistence) CalculateChecksum(state map[string]*api.StateEntry) (string, error) {
	data, err := json.Marshal(state)
	if err != nil {
		return "", err
	}
	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash), nil
}

// LoadState retrieves the latest state from the database
func (p *ConfigPersistence) LoadState() error {
	logger := logging.GetLogger()

	var persistentState PersistentState
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte("state"))
		if b == nil {
			logger.Info("No existing state found in database")
			return nil // Allow service to start with empty state
		}
		val := b.Get([]byte("latest"))
		if val == nil {
			logger.Info("No saved state in database")
			return nil
		}
		return json.Unmarshal(val, &persistentState)
	})
	if err != nil {
		logger.Error("Failed to load state from database: %v", err)
		return nil
	}

	// Restore state
	for key, entry := range persistentState.State {
		if err := p.stateManager.Set(key, entry.Data); err != nil {
			logger.Warn("Error restoring key %s: %v", key, err)
		}
	}

	if p.verbose {
		logger.Info("Loaded state version %d from database", persistentState.Version)
	}
	return nil
}

// SaveState persists the state to database
func (p *ConfigPersistence) SaveState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	logger := logging.GetLogger()

	// Get current state
	state := p.stateManager.GetFullState()
	checksum, err := p.CalculateChecksum(state)
	if err != nil {
		return fmt.Errorf("failed to calculate checksum: %v", err)
	}

	persistentState := PersistentState{
		Version:   p.stateManager.GetVersion(),
		Timestamp: time.Now().UTC(),
		Checksum:  checksum,
		State:     state,
	}

	// Store in database
	err = p.db.Update(func(tx *bbolt.Tx) error {
		b, err := tx.CreateBucketIfNotExists([]byte("state"))
		if err != nil {
			return err
		}
		data, err := json.Marshal(persistentState)
		if err != nil {
			return err
		}
		return b.Put([]byte("latest"), data)
	})
	if err != nil {
		return fmt.Errorf("failed to save state: %v", err)
	}

	if p.verbose {
		logger.Debug("State saved successfully (version: %d, checksum: %s)", persistentState.Version, checksum[:8])
	}

	p.lastSave = time.Now()
	return nil
}

// MarkDirty triggers a state save with debounce logic
func (p *ConfigPersistence) MarkDirty() {
	if time.Since(p.getLastSave()) < p.saveDebounce {
		time.Sleep(p.saveDebounce)
	}

	if err := p.SaveState(); err != nil {
		logging.GetLogger().Error("Failed to persist state: %v", err)
	}
}

// ValidateState verifies if the state in database is valid
func (p *ConfigPersistence) ValidateState() error {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	logger := logging.GetLogger()

	var persistentState PersistentState
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte("state"))
		if b == nil {
			return fmt.Errorf("state bucket not found")
		}
		val := b.Get([]byte("latest"))
		if val == nil {
			return fmt.Errorf("no saved state in database")
		}
		return json.Unmarshal(val, &persistentState)
	})
	if err != nil {
		logger.Error("Failed to validate state: %v", err)
		return err
	}

	// Verify checksum
	calculatedChecksum, err := p.CalculateChecksum(persistentState.State)
	if err != nil {
		return fmt.Errorf("failed to calculate checksum: %v", err)
	}

	if calculatedChecksum != persistentState.Checksum {
		return fmt.Errorf("state corruption detected: checksum mismatch")
	}

	return nil
}

// getLastSave returns the last save time safely
func (p *ConfigPersistence) getLastSave() time.Time {
	p.mutex.RLock()
	defer p.mutex.RUnlock()
	return p.lastSave
}
