package server

import (
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"sync"
	"time"

	"go.etcd.io/bbolt"
)

const (
	snapshotMetadataBucket = "snapshot_metadata"
	activeSnapshotKey      = "active_snapshot"
	timestampKey           = "timestamp"
	hashKey                = "hash"
	defaultBucketName      = "state"
	defaultStateKey        = "default"
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

// LoadState retrieves the active state from the database.
// It first checks the snapshotMetadataBucket for an active snapshot pointer.
// If found, it loads that snapshot; otherwise, it loads the "latest" state.
func (p *ConfigPersistence) LoadState() error {
	logger := logging.GetLogger()
	var persistentState PersistentState

	err := p.db.View(func(tx *bbolt.Tx) error {
		var key []byte
		// Check for an active snapshot pointer
		metaBucket := tx.Bucket([]byte(snapshotMetadataBucket))
		if metaBucket != nil {
			active := metaBucket.Get([]byte(activeSnapshotKey))
			if active != nil {
				key = active
				logger.Info("Loading active snapshot from pointer: %s", string(active))
			}
		}
		// If no active snapshot, fall back to defaultStateKey
		if key == nil {
			key = []byte(defaultStateKey)
			logger.Info("No active snapshot pointer found, loading defaultStateKey")
		}

		// Retrieve the state from the default bucket
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			logger.Info("No state bucket found in database")
			// Allow service to start with an empty state
			return nil
		}
		val := b.Get(key)
		if val == nil {
			logger.Info("No saved state found for key: %s", string(key))
			return nil
		}
		return json.Unmarshal(val, &persistentState)
	})
	if err != nil {
		logger.Error("Failed to load state from database: %v", err)
		return err
	}

	// Restore state using the state manager
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
		b, err := tx.CreateBucketIfNotExists([]byte(defaultBucketName))
		if err != nil {
			return err
		}
		data, err := json.Marshal(persistentState)
		if err != nil {
			return err
		}
		if err := b.Put([]byte(defaultStateKey), data); err != nil {
			return err
		}

		// Store timestamp
		metaBucket, err := tx.CreateBucketIfNotExists([]byte(snapshotMetadataBucket))
		if err != nil {
			return err
		}
		timestampBytes := make([]byte, 8)
		binary.BigEndian.PutUint64(timestampBytes, uint64(persistentState.Timestamp.Unix()))
		if err := metaBucket.Put([]byte(timestampKey), timestampBytes); err != nil {
			return err
		}

		return nil
	})

	if err != nil {
		return fmt.Errorf("failed to save state: %v", err)
	}

	// Update hash value
	err = p.db.Update(func(tx *bbolt.Tx) error {

		hash, err := p.computeDBHash()
		if err != nil {
			return fmt.Errorf("failed to compute hash: %v", err)
		}

		metaBucket, err := tx.CreateBucketIfNotExists([]byte(snapshotMetadataBucket))
		if err != nil {
			return err
		}

		return metaBucket.Put([]byte(activeSnapshotKey), []byte(hash))
	})

	if err != nil {
		return fmt.Errorf("failed to update database hash: %v", err)
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
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			return fmt.Errorf("default bucket not found")
		}
		val := b.Get([]byte(defaultStateKey))
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

// SaveSnapshot persists the current state to the database using a custom key.
func (p *ConfigPersistence) SaveSnapshot(snapshotKey string) error {
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

	// Store snapshot in database using the provided key
	err = p.db.Update(func(tx *bbolt.Tx) error {
		b, err := tx.CreateBucketIfNotExists([]byte(defaultBucketName))
		if err != nil {
			return err
		}
		data, err := json.Marshal(persistentState)
		if err != nil {
			return err
		}
		return b.Put([]byte(snapshotKey), data)
	})
	if err != nil {
		return fmt.Errorf("failed to save snapshot: %v", err)
	}

	if p.verbose {
		logger.Debug("Snapshot '%s' saved successfully (version: %d, checksum: %s)", snapshotKey, persistentState.Version, checksum[:8])
	}

	p.lastSave = time.Now()
	return nil
}

// LoadSnapshot retrieves the snapshot stored under snapshotKey and restores the state.
func (p *ConfigPersistence) LoadSnapshot(snapshotKey string) error {
	logger := logging.GetLogger()

	var persistentState PersistentState
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			logger.Info("No existing state bucket found in database")
			return nil // Allow service to start with an empty state
		}
		val := b.Get([]byte(snapshotKey))
		if val == nil {
			logger.Info("No snapshot found in database for key '%s'", snapshotKey)
			return nil
		}
		return json.Unmarshal(val, &persistentState)
	})
	if err != nil {
		logger.Error("Failed to load snapshot '%s' from database: %v", snapshotKey, err)
		return err
	}

	// Restore state from snapshot
	for key, entry := range persistentState.State {
		if err := p.stateManager.Set(key, entry.Data); err != nil {
			logger.Warn("Error restoring key '%s': %v", key, err)
		}
	}

	if p.verbose {
		logger.Info("Loaded snapshot '%s' (version: %d) from database", snapshotKey, persistentState.Version)
	}
	return nil
}

// ActivateSnapshot sets the given snapshot key as the active snapshot.
// It reads the snapshot data from the default bucket and updates the snapshotMetadataBucket.
func (p *ConfigPersistence) ActivateSnapshot(snapshotKey string) error {
	logger := logging.GetLogger()
	var persistentState PersistentState

	// Retrieve the snapshot state from the default bucket.
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			return fmt.Errorf("state bucket not found")
		}
		val := b.Get([]byte(snapshotKey))
		if val == nil {
			return fmt.Errorf("snapshot '%s' not found", snapshotKey)
		}
		return json.Unmarshal(val, &persistentState)
	})
	if err != nil {
		logger.Error("Failed to load snapshot '%s': %v", snapshotKey, err)
		return err
	}

	// Update the active snapshot pointer in the snapshotMetadataBucket.
	err = p.db.Update(func(tx *bbolt.Tx) error {
		metaBucket, err := tx.CreateBucketIfNotExists([]byte(snapshotMetadataBucket))
		if err != nil {
			return err
		}
		return metaBucket.Put([]byte(activeSnapshotKey), []byte(snapshotKey))
	})
	if err != nil {
		logger.Error("Failed to update active snapshot pointer: %v", err)
		return err
	}

	// Restore the snapshot state into the state manager.
	for key, entry := range persistentState.State {
		if err := p.stateManager.Set(key, entry.Data); err != nil {
			logger.Warn("Error restoring key '%s': %v", key, err)
		}
	}

	if p.verbose {
		logger.Info("Activated snapshot '%s' (version: %d)", snapshotKey, persistentState.Version)
	}
	p.lastSave = time.Now()
	return nil
}

// DeleteSnapshot removes the snapshot stored under snapshotKey from the database.
func (p *ConfigPersistence) DeleteSnapshot(snapshotKey string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	logger := logging.GetLogger()

	err := p.db.Update(func(tx *bbolt.Tx) error {
		// Open the bucket that stores snapshots.
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			return fmt.Errorf("bucket %s not found", defaultBucketName)
		}

		// Check if the snapshot being deleted is currently active.
		metaBucket := tx.Bucket([]byte(snapshotMetadataBucket))
		if metaBucket != nil {
			active := metaBucket.Get([]byte(activeSnapshotKey))
			if active != nil && string(active) == snapshotKey {
				if err := metaBucket.Delete([]byte(activeSnapshotKey)); err != nil {
					return fmt.Errorf("failed to delete active snapshot pointer: %v", err)
				}
			}
		}

		// Delete the snapshot key.
		return b.Delete([]byte(snapshotKey))
	})
	if err != nil {
		logger.Error("Failed to delete snapshot '%s': %v", snapshotKey, err)
		return fmt.Errorf("failed to delete snapshot '%s': %v", snapshotKey, err)
	}

	if p.verbose {
		logger.Info("Deleted snapshot '%s'", snapshotKey)
	}
	return nil
}

// getLastSave returns the last save time safely
func (p *ConfigPersistence) getLastSave() time.Time {
	p.mutex.RLock()
	defer p.mutex.RUnlock()
	return p.lastSave
}

// computeDBHash computes a hash of all bucket key/values
func (p *ConfigPersistence) computeDBHash() (string, error) {
	hash := sha256.New()

	err := p.db.View(func(tx *bbolt.Tx) error {
		tx.ForEach(func(name []byte, b *bbolt.Bucket) error {
			hash.Write(name)
			c := b.Cursor()
			for k, v := c.First(); k != nil; k, v = c.Next() {
				hash.Write(k)
				hash.Write(v)
			}
			return nil
		})
		return nil
	})

	if err != nil {
		return "", err
	}

	return hex.EncodeToString(hash.Sum(nil)), nil
}
