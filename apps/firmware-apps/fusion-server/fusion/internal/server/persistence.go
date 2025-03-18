package server

import (
	"crypto/sha256"
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
	metadataKey            = "metadata"
	defaultBucketName      = "state"
	defaultSnapshotKey     = "default"
)

// PersistentState represents the saved state structure.
type PersistentState struct {
	Version   int64                      `json:"version"`
	Timestamp time.Time                  `json:"timestamp"`
	Checksum  string                     `json:"checksum"`
	State     map[string]*api.StateEntry `json:"state"`
}

// ConfigPersistence handles state persistence and metadata management.
type ConfigPersistence struct {
	dbPath       string
	stateManager *StateManager
	db           *bbolt.DB
	verbose      bool

	mutex        sync.RWMutex
	lastSave     time.Time
	saveDebounce time.Duration
}

// NewConfigPersistence opens the database and returns a new persistence instance.
func NewConfigPersistence(dbPath string, stateManager *StateManager, verbose bool) (*ConfigPersistence, error) {
	db, err := bbolt.Open(dbPath, 0600, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}
	return &ConfigPersistence{
		dbPath:       dbPath,
		stateManager: stateManager,
		db:           db,
		verbose:      verbose,
		saveDebounce: 100 * time.Millisecond,
	}, nil
}

// Close safely closes the database.
func (p *ConfigPersistence) Close() {
	p.db.Close()
}

// CalculateChecksum returns a SHA-256 hash of the provided state.
func (p *ConfigPersistence) CalculateChecksum(state map[string]*api.StateEntry) (string, error) {
	data, err := json.Marshal(state)
	if err != nil {
		return "", fmt.Errorf("failed to marshal state for checksum: %w", err)
	}
	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash), nil
}

// SaveMetadata saves the api.SnapshotMetadata into the metadata bucket.
func (p *ConfigPersistence) SaveMetadata(meta api.SnapshotMetadata) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	return p.db.Update(func(tx *bbolt.Tx) error {
		metaBucket, err := tx.CreateBucketIfNotExists([]byte(snapshotMetadataBucket))
		if err != nil {
			return fmt.Errorf("failed to create metadata bucket: %w", err)
		}
		return metaBucket.Put([]byte(metadataKey), data)
	})
}

// LoadMetadata retrieves and unmarshals the api.SnapshotMetadata from the database.
func (p *ConfigPersistence) LoadMetadata() (api.SnapshotMetadata, error) {
	var meta api.SnapshotMetadata
	err := p.db.View(func(tx *bbolt.Tx) error {
		metaBucket := tx.Bucket([]byte(snapshotMetadataBucket))
		if metaBucket == nil {
			return fmt.Errorf("metadata bucket not found")
		}
		data := metaBucket.Get([]byte(metadataKey))
		if data == nil {
			return fmt.Errorf("metadata not found")
		}
		return json.Unmarshal(data, &meta)
	})
	if err != nil {
		return api.SnapshotMetadata{}, err
	}
	return meta, nil
}

// getActiveSnapshotKey retrieves the active snapshot key from metadata.
func (p *ConfigPersistence) getActiveSnapshotKey() (string, error) {
	meta, err := p.LoadMetadata()
	if err != nil || meta.ActiveSnapshot == "" {
		return defaultSnapshotKey, nil
	}
	return meta.ActiveSnapshot, nil
}

// persistState saves the current state under the given snapshot key.
// Note that it does not update lastSave; the caller should update lastSave as needed.
func (p *ConfigPersistence) persistState(snapshotKey string) (*PersistentState, error) {
	state := p.stateManager.GetFullState()
	checksum, err := p.CalculateChecksum(state)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate checksum: %w", err)
	}

	ps := &PersistentState{
		Version:   p.stateManager.GetVersion(),
		Timestamp: time.Now().UTC(),
		Checksum:  checksum,
		State:     state,
	}

	data, err := json.Marshal(ps)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal state: %w", err)
	}

	err = p.db.Update(func(tx *bbolt.Tx) error {
		bucket, err := tx.CreateBucketIfNotExists([]byte(defaultBucketName))
		if err != nil {
			return fmt.Errorf("failed to create bucket '%s': %w", defaultBucketName, err)
		}
		return bucket.Put([]byte(snapshotKey), data)
	})
	if err != nil {
		return nil, fmt.Errorf("failed to save state: %w", err)
	}

	if err := p.updateDBHash(); err != nil {
		return nil, err
	}

	return ps, nil
}

// LoadActiveSnapshot ensures default buckets exist, loads the active snapshot, and activates it.
func (p *ConfigPersistence) LoadActiveSnapshot() error {
	if err := p.createDefaultBuckets(); err != nil {
		return err
	}

	snapshotName, err := p.getActiveSnapshotKey()
	if err != nil {
		return fmt.Errorf("failed to load active snapshot key: %w", err)
	}

	if err := p.ActivateSnapshot(snapshotName); err != nil {
		return fmt.Errorf("failed to activate snapshot: %w", err)
	}

	logging.GetLogger().Info("Activated initial snapshot: %s", snapshotName)
	return nil
}

// SaveState persists the current state using the active snapshot key.
func (p *ConfigPersistence) SaveState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	snapshotKey, err := p.getActiveSnapshotKey()
	if err != nil || snapshotKey == "" {
		snapshotKey = defaultSnapshotKey
	}

	ps, err := p.persistState(snapshotKey)
	if err != nil {
		return err
	}

	// Update lastSave after persistState returns.
	p.lastSave = time.Now().UTC()

	meta, err := p.LoadMetadata()
	if err != nil {
		meta = api.SnapshotMetadata{}
	}
	meta.Timestamp = ps.Timestamp
	if err := p.SaveMetadata(meta); err != nil {
		return fmt.Errorf("failed to update metadata: %w", err)
	}

	if p.verbose {
		logging.GetLogger().Debug("State saved (version: %d, checksum: %s) under snapshot '%s'",
			ps.Version, ps.Checksum[:8], snapshotKey)
	}
	return nil
}

// createDefaultBuckets ensures that the metadata and default state buckets exist.
// If a default snapshot is not present, it is created.
func (p *ConfigPersistence) createDefaultBuckets() error {
	if err := p.db.Update(func(tx *bbolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(snapshotMetadataBucket))
		return err
	}); err != nil {
		return fmt.Errorf("failed to create metadata bucket: %w", err)
	}

	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket, err := tx.CreateBucketIfNotExists([]byte(defaultBucketName))
		if err != nil {
			return fmt.Errorf("failed to create bucket '%s': %w", defaultBucketName, err)
		}
		if bucket.Get([]byte(defaultSnapshotKey)) == nil {
			state := p.stateManager.GetFullState()
			checksum, err := p.CalculateChecksum(state)
			if err != nil {
				return fmt.Errorf("failed to calculate checksum for default snapshot: %w", err)
			}
			ps := PersistentState{
				Version:   p.stateManager.GetVersion(),
				Timestamp: time.Now().UTC(),
				Checksum:  checksum,
				State:     state,
			}
			data, err := json.Marshal(ps)
			if err != nil {
				return fmt.Errorf("failed to marshal default snapshot: %w", err)
			}
			if err := bucket.Put([]byte(defaultSnapshotKey), data); err != nil {
				return fmt.Errorf("failed to save default snapshot: %w", err)
			}
		}
		return nil
	})
}

// MarkDirty triggers a state save with debounce logic.
func (p *ConfigPersistence) MarkDirty() {
	if time.Since(p.getLastSave()) < p.saveDebounce {
		time.Sleep(p.saveDebounce)
	}

	if err := p.SaveState(); err != nil {
		logging.GetLogger().Error("Failed to persist state: %v", err)
	}
}

// ValidateState checks that the persisted state exists and its checksum is valid.
func (p *ConfigPersistence) ValidateState() error {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	var ps PersistentState
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			return fmt.Errorf("default bucket not found")
		}
		data := b.Get([]byte(defaultSnapshotKey))
		if data == nil {
			return fmt.Errorf("no saved state in database")
		}
		return json.Unmarshal(data, &ps)
	})
	if err != nil {
		logging.GetLogger().Error("Failed to validate state: %v", err)
		return err
	}

	calculatedChecksum, err := p.CalculateChecksum(ps.State)
	if err != nil {
		return fmt.Errorf("failed to calculate checksum: %w", err)
	}
	if calculatedChecksum != ps.Checksum {
		return fmt.Errorf("state corruption detected: checksum mismatch")
	}
	return nil
}

// SaveSnapshot saves the current state under a custom snapshot key.
func (p *ConfigPersistence) SaveSnapshot(snapshotKey string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	ps, err := p.persistState(snapshotKey)
	if err != nil {
		return err
	}

	if p.verbose {
		logging.GetLogger().Debug("Snapshot '%s' saved (version: %d, checksum: %s)",
			snapshotKey, ps.Version, ps.Checksum[:8])
	}
	return nil
}

// ActivateSnapshot restores the state from the given snapshot key and updates metadata.
func (p *ConfigPersistence) ActivateSnapshot(snapshotKey string) error {
	var ps PersistentState
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			return fmt.Errorf("state bucket not found")
		}
		data := b.Get([]byte(snapshotKey))
		if data == nil {
			return fmt.Errorf("snapshot '%s' not found", snapshotKey)
		}
		return json.Unmarshal(data, &ps)
	})
	if err != nil {
		return err
	}

	meta, err := p.LoadMetadata()
	if err != nil {
		meta = api.SnapshotMetadata{}
	}
	meta.ActiveSnapshot = snapshotKey
	if err := p.SaveMetadata(meta); err != nil {
		return fmt.Errorf("failed to update active snapshot metadata: %w", err)
	}

	// Restore state into the state manager.
	for key, entry := range ps.State {
		if err := p.stateManager.Set(key, entry.Data); err != nil {
			logging.GetLogger().Warn("Error restoring key '%s': %v", key, err)
		}
	}

	if p.verbose {
		logging.GetLogger().Info("Activated snapshot '%s' (version: %d)", snapshotKey, ps.Version)
	}

	p.mutex.Lock()
	p.lastSave = time.Now().UTC()
	p.mutex.Unlock()
	return nil
}

// DeleteSnapshot removes the snapshot and clears the active pointer if it was active.
func (p *ConfigPersistence) DeleteSnapshot(snapshotKey string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	// Perform deletion in a single atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(defaultBucketName))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", defaultBucketName)
		}
		if err := bucket.Delete([]byte(snapshotKey)); err != nil {
			return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotKey, err)
		}
		// Verify deletion in the same transaction.
		if bucket.Get([]byte(snapshotKey)) != nil {
			return fmt.Errorf("snapshot '%s' still exists after deletion", snapshotKey)
		}
		return nil
	})
	if err != nil {
		logging.GetLogger().Error("Deletion error for snapshot '%s': %v", snapshotKey, err)
		return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotKey, err)
	}

	// If the deleted snapshot was active, clear it from metadata.
	meta, err := p.LoadMetadata()
	if err == nil && meta.ActiveSnapshot == snapshotKey {
		meta.ActiveSnapshot = ""
		if err := p.SaveMetadata(meta); err != nil {
			logging.GetLogger().Error("Failed to update metadata after deleting snapshot '%s': %v", snapshotKey, err)
			return fmt.Errorf("failed to update metadata after deleting active snapshot: %w", err)
		}
	}

	// Update the overall DB hash
	if err := p.updateDBHash(); err != nil {
		logging.GetLogger().Error("Failed to update DB hash after deleting snapshot '%s': %v", snapshotKey, err)
		return err
	}

	return nil
}

// ListSnapshots returns a list of all snapshot keys.
func (p *ConfigPersistence) ListSnapshots() ([]string, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	var snapshots []string
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			return nil // No snapshots if bucket doesn't exist.
		}
		return b.ForEach(func(k, _ []byte) error {
			snapshots = append(snapshots, string(k))
			return nil
		})
	})
	return snapshots, err
}

// SnapshotExists checks if a snapshot with the given name exists.
func (p *ConfigPersistence) SnapshotExists(name string) (bool, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	var exists bool
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			exists = false
			return nil
		}
		exists = b.Get([]byte(name)) != nil
		return nil
	})
	return exists, err
}

// GetSnapshotMetadata retrieves the snapshot metadata.
func (p *ConfigPersistence) GetSnapshotMetadata() (api.SnapshotMetadata, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	meta, err := p.LoadMetadata()
	if err != nil {
		return api.SnapshotMetadata{}, fmt.Errorf("failed to get snapshot metadata: %w", err)
	}
	return meta, nil
}

// getLastSave returns the last save time.
func (p *ConfigPersistence) getLastSave() time.Time {
	p.mutex.RLock()
	defer p.mutex.RUnlock()
	return p.lastSave
}

// updateDBHash recalculates the overall database hash and updates it in metadata.
func (p *ConfigPersistence) updateDBHash() error {
	newHash, err := p.computeDBHash()
	if err != nil {
		return fmt.Errorf("failed to compute DB hash: %w", err)
	}
	meta, err := p.LoadMetadata()
	if err != nil {
		meta = api.SnapshotMetadata{}
	}
	meta.DBHash = newHash
	return p.SaveMetadata(meta)
}

// computeDBHash computes a SHA-256 hash over all buckets and their key/value pairs.
func (p *ConfigPersistence) computeDBHash() (string, error) {
	hash := sha256.New()
	err := p.db.View(func(tx *bbolt.Tx) error {
		return tx.ForEach(func(name []byte, b *bbolt.Bucket) error {
			hash.Write(name)
			cursor := b.Cursor()
			for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
				hash.Write(k)
				hash.Write(v)
			}
			return nil
		})
	})
	if err != nil {
		return "", err
	}
	return hex.EncodeToString(hash.Sum(nil)), nil
}
