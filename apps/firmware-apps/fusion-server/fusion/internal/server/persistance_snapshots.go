package server

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"time"

	"go.etcd.io/bbolt"
)

// CreateSnapshot saves the current state under a custom snapshot key.
func (p *Persistence) CreateSnapshot(snapshotKey string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	ps, err := p.persistState(snapshotKey)
	if err != nil {
		return err
	}

	logging.GetLogger().Debug("Snapshot '%s' saved (version: %d, checksum: %s)",
		snapshotKey, ps.Version, ps.Checksum[:8])

	return nil
}

// ActivateSnapshot restores the state from the given snapshot key and updates metadata.
func (p *Persistence) ActivateSnapshot(snapshotKey string) error {
	ps, err := p.readSnapshot(snapshotKey)
	if err != nil {
		return err
	}
	if ps == nil {
		return fmt.Errorf("snapshot %s does not exist", snapshotKey)
	}

	meta, err := p.loadMetadata()
	if err != nil {
		meta = api.DatabaseMetadata{}
	}
	meta.ActiveSnapshot = snapshotKey
	if err := p.saveMetadata(meta); err != nil {
		return fmt.Errorf("failed to update active snapshot metadata: %w", err)
	}

	// Restore state into the state manager.
	for key, entry := range ps.State {
		if err := p.stateManager.Set(key, entry.Data); err != nil {
			logging.GetLogger().Warn("Error restoring key '%s': %v", key, err)
		}
	}

	logging.GetLogger().Debug("Activated snapshot '%s' (version: %d)", snapshotKey, ps.Version)

	p.mutex.Lock()
	p.lastSave = time.Now().UTC()
	p.mutex.Unlock()
	return nil
}

// DeleteSnapshot removes the snapshot and clears the active pointer if it was active.
func (p *Persistence) DeleteSnapshot(snapshotKey string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	// Perform deletion in a single atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(snapshotsBucketName))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", snapshotsBucketName)
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
		return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotKey, err)
	}

	// If the deleted snapshot was active, clear it from metadata.
	meta, err := p.loadMetadata()
	if err == nil && meta.ActiveSnapshot == snapshotKey {
		meta.ActiveSnapshot = ""
		if err := p.saveMetadata(meta); err != nil {
			return fmt.Errorf("failed to update metadata after deleting active snapshot: %w", err)
		}
	}

	// Update the overall DB hash
	if err := p.updateHash(); err != nil {
		return fmt.Errorf("to update DB hash after deleting snapshot '%s': %v", snapshotKey, err)
	}

	return nil
}

// ListSnapshots returns a list of all snapshot keys.
func (p *Persistence) ListSnapshots() ([]string, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	var snapshots []string
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(snapshotsBucketName))
		if b == nil {
			return nil
		}
		return b.ForEach(func(k, _ []byte) error {
			snapshots = append(snapshots, string(k))
			return nil
		})
	})
	return snapshots, err
}

// SnapshotExists checks if a snapshot with the given name exists.
func (p *Persistence) SnapshotExists(snapshotKey string) (bool, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	ps, err := p.readSnapshot(snapshotKey)
	if err != nil {
		return false, err
	}

	if ps == nil {
		return false, nil
	}

	return true, err
}

// GetDatabaseMetadata retrieves the database metadata.
func (p *Persistence) GetDatabaseMetadata() (api.DatabaseMetadata, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	meta, err := p.loadMetadata()
	if err != nil {
		return api.DatabaseMetadata{}, fmt.Errorf("failed to get database metadata: %w", err)
	}
	return meta, nil
}

// GetSnapshot retrieves the snapshot data.
func (p *Persistence) GetSnapshot(snapshotKey string) (any, error) {

	p.mutex.RLock()
	defer p.mutex.RUnlock()

	ps, err := p.readSnapshot(snapshotKey)
	if err != nil {
		return nil, err
	}

	if ps == nil {
		return nil, fmt.Errorf("snapshot %s does not exist", snapshotKey)
	}

	return ps, nil
}

// LoadActiveSnapshot ensures default buckets exist, loads the active snapshot, and activates it.
func (p *Persistence) LoadActiveSnapshot() error {

	snapshotName, err := p.getActiveSnapshotKey()
	if err != nil {
		return fmt.Errorf("failed to load active snapshot key: %w", err)
	}

	if err := p.ActivateSnapshot(snapshotName); err != nil {
		return fmt.Errorf("failed to activate snapshot %s: %w", snapshotName, err)
	}

	logging.GetLogger().Debug("Activated initial snapshot: %s", snapshotName)
	return nil
}

// getActiveSnapshotKey retrieves the active snapshot key from metadata.
func (p *Persistence) getActiveSnapshotKey() (string, error) {
	meta, err := p.loadMetadata()
	if err != nil || meta.ActiveSnapshot == "" {
		return defaultSnapshotKey, nil
	}
	return meta.ActiveSnapshot, nil
}

// readSnapshot reads the snapshots from the database.
func (p *Persistence) readSnapshot(snapshotKey string) (*PersistentState, error) {

	var ps PersistentState
	exists := true

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(snapshotsBucketName))
		if b == nil {
			return fmt.Errorf("bucket '%s' not found", snapshotsBucketName)
		}
		data := b.Get([]byte(snapshotKey))
		if data == nil {
			exists = false
			return nil
		}
		return json.Unmarshal(data, &ps)
	})

	if err != nil {
		return nil, err
	}

	if !exists {
		return nil, nil
	}

	return &ps, nil
}
