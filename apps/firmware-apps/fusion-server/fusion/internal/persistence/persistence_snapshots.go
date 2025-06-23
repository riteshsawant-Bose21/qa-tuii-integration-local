package persistence

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

	ps, err := p.persistState(snapshotKey)
	if err != nil {
		return err
	}

	logging.GetLogger().Debug("Snapshot '%s' saved (version: %v, checksum: %s)",
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

	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load snapshot metadata: %w", err)
	}
	metadata.ActiveSnapshot = snapshotKey
	if err := p.saveMetadata(metadata); err != nil {
		return fmt.Errorf("failed to update active snapshot metadata: %w", err)
	}

	// Restore state into the state manager.
	for key, entry := range ps.State {
		if err := p.stateManager.Set(key, entry.Data); err != nil {
			logging.GetLogger().Warn("Error restoring key '%s': %v", key, err)
		}
	}

	logging.GetLogger().Debug("Activated snapshot '%s' (version: %v)", snapshotKey, ps.Version)

	p.mutex.Lock()
	p.lastSave = time.Now().UTC()
	p.mutex.Unlock()
	return nil
}

// DeleteSnapshot removes the snapshot and clears the active pointer if it was active.
func (p *Persistence) DeleteSnapshot(snapshotKey string) error {

	// Perform deletion in a single atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshots))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshots)
		}
		if err := bucket.Delete([]byte(snapshotKey)); err != nil {
			return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotKey, err)
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotKey, err)
	}

	// If the deleted snapshot was active, clear it from metadata.
	metadata, err := p.loadMetadata()
	if err == nil && metadata.ActiveSnapshot == snapshotKey {
		metadata.ActiveSnapshot = ""
		if err := p.saveMetadata(metadata); err != nil {
			return fmt.Errorf("failed to update metadata after deleting active snapshot: %w", err)
		}
	}

	// Remove tasks associated with the snapshot
	tasks, err := p.GetTaskIDsBySnapshot(snapshotKey)
	if err != nil {
		return err
	}

	for _, taskID := range tasks {
		if err := p.DeleteTask(taskID); err != nil {
			return fmt.Errorf("failed to delete task %s: %w", taskID, err)
		}
	}

	// Update the database hash
	if err := p.updateHash(); err != nil {
		return fmt.Errorf("to update DB hash after deleting snapshot '%s': %v", snapshotKey, err)
	}

	return nil
}

// ListSnapshots returns a list of all snapshot keys.
func (p *Persistence) ListSnapshots() ([]string, error) {

	var snapshots []string
	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketSnapshots))
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
	var exists bool

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketSnapshots))
		if b == nil {
			// No snapshots bucket means no snapshots at all
			exists = false
			return nil
		}
		// If Get returns non-nil, the key exists
		exists = b.Get([]byte(snapshotKey)) != nil
		return nil
	})

	if err != nil {
		return false, err
	}

	return exists, nil
}

// GetDatabaseMetadata retrieves the database metadata.
func (p *Persistence) GetDatabaseMetadata() (*api.DatabaseMetadata, error) {

	metadata, err := p.loadMetadata()
	if err != nil {
		return nil, fmt.Errorf("failed to get database metadata: %w", err)
	}
	return metadata, nil
}

// GetSnapshot retrieves the snapshot data.
func (p *Persistence) GetSnapshot(snapshotKey string) (any, error) {

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

	snapshotName := p.getActiveSnapshotKey()

	if err := p.ActivateSnapshot(snapshotName); err != nil {
		return fmt.Errorf("failed to activate snapshot %s: %w", snapshotName, err)
	}

	logging.GetLogger().Debug("Activated initial snapshot: %s", snapshotName)
	return nil
}

// IsDefaultSnapshot returns true is the name is the default snapshot
func (p *Persistence) IsDefaultSnapshot(snapshot string) bool {
	return snapshot == keyDefaultSnapshot
}

// getActiveSnapshotKey retrieves the active snapshot key from metadata.
// If none is present, the default key is returned.
func (p *Persistence) getActiveSnapshotKey() string {
	metadata, err := p.loadMetadata()
	if err != nil || metadata.ActiveSnapshot == "" {
		return keyDefaultSnapshot
	}
	return metadata.ActiveSnapshot
}

// readSnapshot reads the snapshot from the database.
func (p *Persistence) readSnapshot(snapshotKey string) (*PersistentState, error) {

	var ps PersistentState
	exists := true

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketSnapshots))
		if b == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshots)
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
