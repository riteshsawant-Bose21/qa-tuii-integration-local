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
	snapshotsBucketName = "snapshots"
	defaultSnapshotKey  = "default"
	fusionBucketName    = "fusion"
	metadataKey         = "metadata"
	tasksBucketName     = "tasks"
)

// PersistentState represents the saved state structure.
type PersistentState struct {
	Version   int64                      `json:"version"`
	Timestamp time.Time                  `json:"timestamp"`
	Checksum  string                     `json:"checksum"`
	State     map[string]*api.StateEntry `json:"state"`
}

// Persistence handles state persistence and metadata management.
type Persistence struct {
	dbPath       string
	stateManager *StateManager
	db           *bbolt.DB
	verbose      bool
	mutex        sync.RWMutex
	lastSave     time.Time
	saveDebounce time.Duration
}

// NewPersistence opens the database and returns a new persistence instance.
func NewPersistence(dbPath string, stateManager *StateManager, verbose bool) (*Persistence, error) {
	db, err := bbolt.Open(dbPath, 0600, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}
	persistance := &Persistence{
		dbPath:       dbPath,
		stateManager: stateManager,
		db:           db,
		verbose:      verbose,
		saveDebounce: 100 * time.Millisecond,
	}

	if err := persistance.createDefaultBuckets(); err != nil {
		return nil, err
	}

	return persistance, nil
}

// Close safely closes the database.
func (p *Persistence) Close() {
	p.db.Close()
}

// saveMetadata saves the api.DatabaseMetadata into the metadata bucket.
func (p *Persistence) saveMetadata(meta api.DatabaseMetadata) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	return p.db.Update(func(tx *bbolt.Tx) error {
		metaBucket := tx.Bucket([]byte(fusionBucketName))
		if metaBucket == nil {
			return fmt.Errorf("metadata bucket not found")
		}
		return metaBucket.Put([]byte(metadataKey), data)
	})
}

// loadMetadata retrieves and unmarshals the api.DatabaseMetadata from the database.
func (p *Persistence) loadMetadata() (api.DatabaseMetadata, error) {
	var meta api.DatabaseMetadata
	err := p.db.View(func(tx *bbolt.Tx) error {
		metaBucket := tx.Bucket([]byte(fusionBucketName))
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
		return api.DatabaseMetadata{}, err
	}
	return meta, nil
}

// SaveState persists the current state using the active snapshot key.
func (p *Persistence) SaveState() error {
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

	meta, err := p.loadMetadata()
	if err != nil {
		meta = api.DatabaseMetadata{}
	}
	meta.Timestamp = ps.Timestamp
	meta.Valid = len(ps.State) > 0

	if err := p.saveMetadata(meta); err != nil {
		return fmt.Errorf("failed to update metadata: %w", err)
	}

	if p.verbose {
		logging.GetLogger().Debug("State saved (version: %d, checksum: %s) under snapshot '%s'",
			ps.Version, ps.Checksum, snapshotKey)
	}

	return nil
}

// MarkDirty triggers a state save with debounce logic.
func (p *Persistence) MarkDirty() {
	if time.Since(p.getLastSave()) < p.saveDebounce {
		time.Sleep(p.saveDebounce)
	}

	if err := p.SaveState(); err != nil {
		logging.GetLogger().Error("Failed to persist state: %v", err)
	}
}

// ValidateState checks that the persistant state exists has a valid checksum.
func (p *Persistence) ValidateState() error {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	state := p.stateManager.GetFullState()
	calculatedChecksum, err := CalculateChecksum(state.State)
	if err != nil {
		return fmt.Errorf("failed to calculate checksum: %w", err)
	}
	if calculatedChecksum != state.Checksum {
		return fmt.Errorf("checksum mismatch: state: %s calculated %s", state.Checksum, calculatedChecksum)
	}
	return nil
}

// Export retrieves the entire bbolt database in JSON.
func (p *Persistence) ExportData() (any, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	// dbExport will hold the entire database content.
	dbExport := make(map[string]map[string]any)

	// Start a read-only transaction.
	err := p.db.View(func(tx *bbolt.Tx) error {
		// Iterate over every bucket in the database.
		return tx.ForEach(func(bucketName []byte, b *bbolt.Bucket) error {
			bucket := string(bucketName)
			dbExport[bucket] = make(map[string]any)

			// Iterate over each key/value pair in the bucket.
			err := b.ForEach(func(k, v []byte) error {
				var value any
				// Try to unmarshal the JSON value.
				if err := json.Unmarshal(v, &value); err != nil {
					// If unmarshaling fails, store the raw string.
					dbExport[bucket][string(k)] = string(v)
				} else {
					dbExport[bucket][string(k)] = value
				}
				return nil
			})
			return err
		})
	})
	if err != nil {
		return nil, fmt.Errorf("failed to export snapshots: %w", err)
	}
	return dbExport, nil
}

// Import imports data into the database
func (p *Persistence) ImportData(importData map[string]any) error {

	update := false

	// Get the snapshots from the import
	snapshotsData, ok := importData[snapshotsBucketName]
	if ok {
		// Assert snapshotsData is a map[string]any.
		snapshots, ok := snapshotsData.(map[string]any)
		if !ok {
			return fmt.Errorf("snapshots data is not in the expected format")
		}

		if err := p.replaceBucketData(snapshotsBucketName, snapshots); err != nil {
			return err
		}

		update = true
	}

	// Get the tasks from the import
	tasksData, ok := importData[tasksBucketName]
	if ok {
		// Assert tasksData is a map[string]any.
		tasks, ok := tasksData.(map[string]any)
		if !ok {
			return fmt.Errorf("tasks data is not in the expected format")
		}

		if err := p.replaceBucketData(tasksBucketName, tasks); err != nil {
			return err
		}

		update = true
	}

	if !update {
		return nil
	}

	// Update the overall database hash.
	if err := p.updateHash(); err != nil {
		return fmt.Errorf("failed to update DB hash after import: %w", err)
	}

	return nil
}

// getLastSave returns the last save time.
func (p *Persistence) getLastSave() time.Time {
	p.mutex.RLock()
	defer p.mutex.RUnlock()
	return p.lastSave
}

// updateHash recalculates the overall database hash and updates it in metadata.
func (p *Persistence) updateHash() error {
	newHash, err := p.computeHash()
	if err != nil {
		return fmt.Errorf("failed to compute DB hash: %w", err)
	}
	meta, err := p.loadMetadata()
	if err != nil {
		meta = api.DatabaseMetadata{}
	}
	meta.Hash = newHash
	return p.saveMetadata(meta)
}

// computeHash computes a SHA-256 hash over all buckets and their key/value pairs.
func (p *Persistence) computeHash() (string, error) {
	hash := sha256.New()
	if err := p.db.View(func(tx *bbolt.Tx) error {
		return tx.ForEach(func(name []byte, b *bbolt.Bucket) error {
			hash.Write(name)
			cursor := b.Cursor()
			for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
				hash.Write(k)
				hash.Write(v)
			}
			return nil
		})
	}); err != nil {
		return "", err
	}

	return hex.EncodeToString(hash.Sum(nil)), nil
}

// createDefaultBuckets ensures that the metadata and default state buckets exist.
// If a default snapshot is not present, it is created.
func (p *Persistence) createDefaultBuckets() error {
	if err := p.db.Update(func(tx *bbolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(fusionBucketName))
		return err
	}); err != nil {
		return fmt.Errorf("failed to create metadata bucket: %w", err)
	}

	return p.db.Update(func(tx *bbolt.Tx) error {

		_, err := tx.CreateBucketIfNotExists([]byte(tasksBucketName))
		if err != nil {
			return fmt.Errorf("failed to create bucket '%s': %w", tasksBucketName, err)
		}

		fusionBucket, err := tx.CreateBucketIfNotExists([]byte(snapshotsBucketName))
		if err != nil {
			return fmt.Errorf("failed to create bucket '%s': %w", snapshotsBucketName, err)
		}

		if fusionBucket.Get([]byte(defaultSnapshotKey)) == nil {
			state := p.stateManager.GetFullState()
			ps := PersistentState{
				Version:   p.stateManager.GetVersion(),
				Timestamp: time.Now().UTC(),
				Checksum:  state.Checksum,
				State:     state.State,
			}
			data, err := json.Marshal(ps)
			if err != nil {
				return fmt.Errorf("failed to marshal default snapshot: %w", err)
			}
			if err := fusionBucket.Put([]byte(defaultSnapshotKey), data); err != nil {
				return fmt.Errorf("failed to save default snapshot: %w", err)
			}
		}
		return nil
	})
}

// persistState saves the current state under the given snapshot key.
// Note that it does not update lastSave; the caller should update lastSave as needed.
func (p *Persistence) persistState(snapshotKey string) (*PersistentState, error) {
	state := p.stateManager.GetFullState()

	ps := &PersistentState{
		Version:   p.stateManager.GetVersion(),
		Timestamp: time.Now().UTC(),
		Checksum:  state.Checksum,
		State:     state.State,
	}

	data, err := json.Marshal(ps)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal state: %w", err)
	}

	err = p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(snapshotsBucketName))
		if bucket == nil {
			return fmt.Errorf("snapshots bucket not found")
		}
		return bucket.Put([]byte(snapshotKey), data)
	})
	if err != nil {
		return nil, fmt.Errorf("failed to save state: %w", err)
	}

	if err := p.updateHash(); err != nil {
		return nil, err
	}

	return ps, nil
}

func (p *Persistence) replaceBucketData(bucketName string, data map[string]any) error {

	// Replace the entire bucket in an atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {

		bucket := tx.Bucket([]byte(tasksBucketName))
		if bucket == nil {
			return fmt.Errorf("%s bucket not found", bucketName)
		}

		// Clear existing keys.
		var keysToDelete []string
		err := bucket.ForEach(func(k, v []byte) error {
			keysToDelete = append(keysToDelete, string(k))
			return nil
		})
		if err != nil {
			return err
		}
		for _, k := range keysToDelete {
			if err := bucket.Delete([]byte(k)); err != nil {
				return fmt.Errorf("failed to delete key %s: %w", k, err)
			}
		}

		// Insert new keys
		for key, value := range data {
			// Marshal each value into JSON bytes.
			marshaledValue, err := json.Marshal(value)
			if err != nil {
				return fmt.Errorf("failed to marshal value for key %s: %w", key, err)
			}
			if err := bucket.Put([]byte(key), marshaledValue); err != nil {
				return fmt.Errorf("failed to put key %s: %w", key, err)
			}
		}
		return nil
	})

	return err
}
