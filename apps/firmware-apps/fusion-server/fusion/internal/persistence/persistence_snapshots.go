package persistence

import (
	"fmt"
	"fusion/internal/api"
	"fusion-services-core/logging"
	"fusion/internal/utils"
	"time"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

// CreateSnapshot saves the current state under a custom snapshot key.
func (p *Persistence) CreateSnapshot(snapshotName string) error {

	p.stateManager.BumpEpoch()

	p.mutex.Lock()
	defer p.mutex.Unlock()

	ps, err := p.persistState(snapshotName)
	if err != nil {
		return err
	}

	checksum := ps.Checksum
	if len(checksum) > 8 {
		checksum = checksum[:8]
	}

	logging.GetLogger().Debug("Snapshot '%s' created (version: %v, checksum: %s)",
		snapshotName, ps.Version, checksum)

	return nil
}

// ActivateSnapshot restores the state from the given snapshot key and updates metadata.
func (p *Persistence) ActivateSnapshot(snapshotName string) error {

	ps, err := p.readSnapshot(snapshotName)
	if err != nil {
		return err
	}
	if ps == nil {
		return fmt.Errorf("snapshot %s does not exist", snapshotName)
	}

	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}

	// Replace state and bump epoch atomically
	p.stateManager.Lock()

	// New global epoch boundary
	newVersion := p.stateManager.BumpEpochLocked()

	// Restore snapshot state, but force each entry to use the new epoch version
	restored := deepCopyState(ps.State)
	for _, entry := range restored {
		if entry != nil {
			entry.Version = newVersion
		}
	}

	p.stateManager.state.State = restored
	p.stateManager.updateChecksumUnsafe()
	p.stateManager.Unlock()

	// Update metadata snapshot
	metadata.ActiveSnapshot = snapshotName
	if err := p.saveMetadata(metadata); err != nil {
		return fmt.Errorf("failed to update metadata: %w", err)
	}

	logging.GetLogger().Debug(
		"Activated snapshot '%s': Epoch=%d Version=%d",
		snapshotName, newVersion.Epoch, newVersion.Counter,
	)

	// Mark last save time
	p.mutex.Lock()
	p.lastSave = time.Now().UTC()
	p.mutex.Unlock()

	return nil
}

// DeleteSnapshot removes the snapshot and restores the default if it was active.
func (p *Persistence) DeleteSnapshot(snapshotName string) error {

	// Perform deletion in a single atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketSnapshots))
		if bucket == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshots)
		}
		if err := bucket.Delete([]byte(snapshotName)); err != nil {
			return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotName, err)
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotName, err)
	}

	// Remove tasks associated with the snapshot
	tasks, err := p.GetTaskIDsBySnapshot(snapshotName)
	if err != nil {
		return err
	}
	for _, taskID := range tasks {
		if err := p.DeleteTask(taskID); err != nil {
			return fmt.Errorf("failed to delete task %s: %w", taskID, err)
		}
	}

	// If the deleted snapshot was active, restore the default snapshot.
	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata when deleting snapshot %q: %w", snapshotName, err)
	}

	if metadata.ActiveSnapshot == snapshotName {
		// Ensure default snapshot exists before activation
		exists, err := p.SnapshotExists(keyDefaultSnapshot)
		if err != nil {
			return fmt.Errorf("failed to check default snapshot existence: %w", err)
		}
		if !exists {
			return fmt.Errorf("default snapshot %q does not exist", keyDefaultSnapshot)
		}

		if err := p.ActivateSnapshot(keyDefaultSnapshot); err != nil {
			return fmt.Errorf("failed to activate default snapshot %q: %w", keyDefaultSnapshot, err)
		}
	}

	// Update the database hash
	if err := p.updateHash(); err != nil {
		return fmt.Errorf("to update DB hash after deleting snapshot '%s': %v", snapshotName, err)
	}

	return nil
}

// SaveSnapshot overwrites an existing snapshot with the current in-memory state.
func (p *Persistence) SaveSnapshot(snapshotName string) error {

	p.mutex.Lock()
	defer p.mutex.Unlock()

	ps, err := p.persistState(snapshotName)
	if err != nil {
		return err
	}

	checksum := ps.Checksum
	if len(checksum) > 8 {
		checksum = checksum[:8]
	}

	logging.GetLogger().Debug(
		"Snapshot '%s' updated (version: %v, checksum: %s)",
		snapshotName, ps.Version, checksum,
	)

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
func (p *Persistence) SnapshotExists(snapshotName string) (bool, error) {
	var exists bool

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketSnapshots))
		if b == nil {
			// No snapshots bucket means no snapshots at all
			exists = false
			return nil
		}
		// If Get returns non-nil, the key exists
		exists = b.Get([]byte(snapshotName)) != nil
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
func (p *Persistence) GetSnapshot(snapshotName string) (any, error) {

	ps, err := p.readSnapshot(snapshotName)
	if err != nil {
		return nil, err
	}

	if ps == nil {
		return nil, fmt.Errorf("snapshot %s does not exist", snapshotName)
	}

	return utils.FlattenState(ps.State), nil
}

// GetActiveSnapshotName returns the name of the active snapshot
func (p *Persistence) GetActiveSnapshotName() string {
	return p.getActiveSnapshotName()
}

// LoadActiveSnapshot loads the last persisted active state if present,
// otherwise falls back to the active snapshot and then seeds the active state.
func (p *Persistence) LoadActiveSnapshot() error {

	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}

	logger := logging.GetLogger()

	// Restore from active state bucket
	if ps, err := p.readActiveState(); err != nil {
		return fmt.Errorf("failed to read active state: %w", err)
	} else if ps != nil && len(ps.State) > 0 {
		p.stateManager.Lock()
		p.stateManager.state.State = deepCopyState(ps.State)
		p.stateManager.updateChecksumUnsafe()
		p.stateManager.Unlock()

		// Use the version stored with the active state
		p.stateManager.SetVersion(ps.Version)

		logger.Debug("Restored active state on startup: Epoch=%d Counter=%d", ps.Version.Epoch, ps.Version.Counter)
		return nil
	}

	// Restore from the active snapshot
	snapshotName := metadata.ActiveSnapshot
	if snapshotName == "" {
		logger.Warn("No active snapshot on startup; using default")
		snapshotName = keyDefaultSnapshot
	}

	if err := p.ActivateSnapshot(snapshotName); err != nil {
		return fmt.Errorf("failed to restore active snapshot %q: %w", snapshotName, err)
	}

	// Save version from metadata as authoritative (existing semantics)
	p.stateManager.SetVersion(metadata.Version)

	logger.Debug("Restored snapshot on startup: %s %d %d",
		snapshotName, metadata.Version.Epoch, metadata.Version.Counter)

	// Seed the active bucket so future restarts bypass snapshots
	if err := p.SaveState(); err != nil {
		logger.Warn("Failed to persist initial active state after restoring snapshot %q: %v", snapshotName, err)
	}

	return nil
}

// IsDefaultSnapshot returns true is the name is the default snapshot
func (p *Persistence) IsDefaultSnapshot(snapshot string) bool {
	return snapshot == keyDefaultSnapshot
}

// getActiveSnapshotName retrieves the active snapshot key from metadata.
// If none is present, the default key is returned.
func (p *Persistence) getActiveSnapshotName() string {
	metadata, err := p.loadMetadata()
	if err != nil || metadata.ActiveSnapshot == "" {
		return keyDefaultSnapshot
	}
	return metadata.ActiveSnapshot
}

// readSnapshot reads the snapshot from the database.
func (p *Persistence) readSnapshot(snapshotName string) (*PersistentState, error) {

	var ps PersistentState
	exists := true

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketSnapshots))
		if b == nil {
			return fmt.Errorf("bucket '%s' not found", bucketSnapshots)
		}
		data := b.Get([]byte(snapshotName))
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

func (p *Persistence) readActiveState() (*PersistentState, error) {

	var ps PersistentState
	exists := true

	err := p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(bucketActive))
		if b == nil {
			return fmt.Errorf("bucket '%s' not found", bucketActive)
		}
		data := b.Get([]byte(keyActiveState))
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
