package persistence

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/utils"
	"time"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

// CreateSnapshot saves the current state under a custom snapshot key.
func (p *Persistence) CreateSnapshot(snapshotKey string) error {

	logging.GetLogger().Info("--------------->>> CreateSnapshot")
	p.stateManager.BumpEpoch()

	p.mutex.Lock()
	defer p.mutex.Unlock()

	ps, err := p.persistState(snapshotKey)
	if err != nil {
		return err
	}

	checksum := ps.Checksum
	if len(checksum) > 8 {
		checksum = checksum[:8]
	}

	logging.GetLogger().Debug("Snapshot '%s' saved (version: %v, checksum: %s)",
		snapshotKey, ps.Version, checksum)

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
		return fmt.Errorf("failed to load metadata: %w", err)
	}

	logger := logging.GetLogger()

	// Update active snapshot name in metadata
	metadata.ActiveSnapshot = snapshotKey
	if err := p.saveMetadata(metadata); err != nil {
		return fmt.Errorf("failed to update metadata: %w", err)
	}

	// Replace state and bump epoch atomically
	p.stateManager.Lock()
	newVersion := p.stateManager.BumpEpochLocked()
	p.stateManager.state.State = deepCopyState(ps.State)
	p.stateManager.updateChecksumUnsafe()
	p.stateManager.Unlock()

	logger.Info(
		"Activated snapshot '%s' → new epoch=%d counter=%d",
		snapshotKey, newVersion.Epoch, newVersion.Counter,
	)

	// Mark last save time
	p.mutex.Lock()
	p.lastSave = time.Now().UTC()
	p.mutex.Unlock()

	return nil
}

// DeleteSnapshot removes the snapshot and clears the active pointer if it was active.
func (p *Persistence) DeleteSnapshot(snapshotKey string) error {

	p.stateManager.BumpEpoch()

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

	// If the deleted snapshot was active, clear it from metadata.
	metadata, err := p.loadMetadata()
	if err == nil && metadata.ActiveSnapshot == snapshotKey {
		if err := p.ActivateSnapshot(keyDefaultSnapshot); err != nil {
			return fmt.Errorf("failed to restore active snapshot %q: %w", keyDefaultSnapshot, err)
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

	return utils.FlattenState(ps.State), nil
}

// GetActiveSnapshotName returns the name of the active snapshot
func (p *Persistence) GetActiveSnapshotName() string {
	return p.getActiveSnapshotKey()
}

// LoadActiveSnapshot loads the active snapshot from metadata,
// restores its full state into the state manager, and persists it.
func (p *Persistence) LoadActiveSnapshot() error {

	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}

	snapshotName := metadata.ActiveSnapshot
	logger := logging.GetLogger()

	if snapshotName == "" {
		logger.Warn("No active snapshot on startup")
		snapshotName = keyDefaultSnapshot
	}

	if err := p.ActivateSnapshot(snapshotName); err != nil {
		return fmt.Errorf("failed to restore active snapshot %q: %w", snapshotName, err)
	}

	logger.Debug("Restored active snapshot on startup: %s", snapshotName)

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
