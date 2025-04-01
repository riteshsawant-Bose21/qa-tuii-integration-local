package server

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"net/http"
	"sync"
	"time"

	"github.com/hashicorp/memberlist"
	"go.etcd.io/bbolt"
)

const (
	defaultBucketName      = "fusion"
	defaultSnapshotKey     = "default"
	metadataKey            = "metadata"
	snapshotMetadataBucket = "snapshot_metadata"
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
	return &Persistence{
		dbPath:       dbPath,
		stateManager: stateManager,
		db:           db,
		verbose:      verbose,
		saveDebounce: 100 * time.Millisecond,
	}, nil
}

// Close safely closes the database.
func (p *Persistence) Close() {
	p.db.Close()
}

// CalculateChecksum returns a SHA-256 hash of the provided state.
func (p *Persistence) CalculateChecksum(state map[string]*api.StateEntry) (string, error) {
	data, err := json.Marshal(state)
	if err != nil {
		return "", fmt.Errorf("failed to marshal state for checksum: %w", err)
	}
	hash := sha256.Sum256(data)
	return fmt.Sprintf("%x", hash), nil
}

// saveMetadata saves the api.SnapshotMetadata into the metadata bucket.
func (p *Persistence) saveMetadata(meta api.SnapshotMetadata) error {
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
func (p *Persistence) LoadMetadata() (api.SnapshotMetadata, error) {
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

// LoadActiveSnapshot ensures default buckets exist, loads the active snapshot, and activates it.
func (p *Persistence) LoadActiveSnapshot() error {
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

	logging.GetLogger().Debug("Activated initial snapshot: %s", snapshotName)
	return nil
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

	meta, err := p.LoadMetadata()
	if err != nil {
		meta = api.SnapshotMetadata{}
	}
	meta.Timestamp = ps.Timestamp
	meta.Valid = len(ps.State) > 0

	if err := p.saveMetadata(meta); err != nil {
		return fmt.Errorf("failed to update metadata: %w", err)
	}

	if p.verbose {
		logging.GetLogger().Debug("State saved (version: %d, checksum: %s) under snapshot '%s'",
			ps.Version, ps.Checksum[:8], snapshotKey)
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

// ValidateState checks that the persisted state exists and its checksum is valid.
func (p *Persistence) ValidateState() error {
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

// CreateSnapshot saves the current state under a custom snapshot key.
func (p *Persistence) CreateSnapshot(snapshotKey string) error {
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
func (p *Persistence) ActivateSnapshot(snapshotKey string) error {
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
	if err := p.saveMetadata(meta); err != nil {
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
func (p *Persistence) DeleteSnapshot(snapshotKey string) error {
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
		return fmt.Errorf("failed to delete snapshot '%s': %w", snapshotKey, err)
	}

	// If the deleted snapshot was active, clear it from metadata.
	meta, err := p.LoadMetadata()
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
func (p *Persistence) SnapshotExists(name string) (bool, error) {
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
func (p *Persistence) GetSnapshotMetadata() (api.SnapshotMetadata, error) {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	meta, err := p.LoadMetadata()
	if err != nil {
		return api.SnapshotMetadata{}, fmt.Errorf("failed to get snapshot metadata: %w", err)
	}
	return meta, nil
}

// GetSnapshot retrieves the snapshot data.
func (p *Persistence) GetSnapshot(name string) (any, error) {
	exists, err := p.SnapshotExists(name)
	if err != nil {
		return nil, fmt.Errorf("error checking snapshot existence: %w", err)
	}
	if !exists {
		return nil, fmt.Errorf("snapshot does not exist")
	}

	p.mutex.RLock()
	defer p.mutex.RUnlock()

	var data []byte
	err = p.db.View(func(tx *bbolt.Tx) error {
		b := tx.Bucket([]byte(defaultBucketName))
		if b == nil {
			return fmt.Errorf("state bucket not found")
		}
		data = b.Get([]byte(name))
		if data == nil {
			return fmt.Errorf("snapshot '%s' not found", name)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	// Unmarshal the raw JSON data into an any
	var result any
	if err := json.Unmarshal(data, &result); err != nil {
		return nil, fmt.Errorf("failed to unmarshal snapshot data: %w", err)
	}
	return result, nil
}

// ExportSnapshots retrieves the entire bbolt database in JSON.
func (p *Persistence) ExportSnapshots() (any, error) {
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

// ImportSnapshots imports the snapshot data into the database
func (p *Persistence) ImportSnapshots(importData map[string]any) error {

	// Get the snapshots from the import (fusion bucket).
	snapshotsData, ok := importData[defaultBucketName]
	if !ok {
		return fmt.Errorf("export does not contain fusion bucket")
	}

	// Assert snapshotsData is a map[string]any.
	snapshots, ok := snapshotsData.(map[string]any)
	if !ok {
		return fmt.Errorf("snapshots data is not in the expected format")
	}

	// Replace the entire state bucket in an atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket, err := tx.CreateBucketIfNotExists([]byte(defaultBucketName))
		if err != nil {
			return fmt.Errorf("failed to create state bucket: %w", err)
		}

		// Clear existing keys.
		var keysToDelete []string
		err = bucket.ForEach(func(k, v []byte) error {
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

		// Insert new keys from the export.
		for key, value := range snapshots {
			// Marshal each snapshot value into JSON bytes.
			marshaledValue, err := json.Marshal(value)
			if err != nil {
				return fmt.Errorf("failed to marshal snapshot value for key %s: %w", key, err)
			}
			if err := bucket.Put([]byte(key), marshaledValue); err != nil {
				return fmt.Errorf("failed to put key %s: %w", key, err)
			}
		}
		return nil
	})
	if err != nil {
		return err
	}

	// Update the overall database hash.
	if err := p.updateHash(); err != nil {
		return fmt.Errorf("failed to update DB hash after import: %w", err)
	}
	return nil
}

func (p *Persistence) SyncFullStateFromCluster(list *memberlist.Memberlist) error {
	logger := logging.GetLogger()

	// NodeSnapshot holds a member and its snapshot metadata.
	type NodeSnapshot struct {
		Member   *memberlist.Node
		Metadata api.SnapshotMetadata
	}

	var snapshots []NodeSnapshot

	// Query all live cluster members for their snapshot metadata.
	members := list.Members()
	for _, member := range members {
		if member.State != memberlist.StateAlive {
			continue
		}
		// Each node must expose its metadata at /snapshots/metadata.
		url := fmt.Sprintf("http://%s%s/snapshots/metadata", member.Addr.String(), api.HTTPPort)
		resp, err := http.Get(url)
		if err != nil {
			logger.Warn("Failed to get metadata from %s: %v", member.Name, err)
			continue
		}
		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			logger.Warn("Error reading response body from %s: %v", member.Name, err)
			continue
		}
		var metadata api.SnapshotMetadata
		if err := json.Unmarshal(body, &metadata); err != nil {
			logger.Warn("Failed to unmarshal JSON from %s: %v", member.Name, err)
			continue
		}
		snapshots = append(snapshots, NodeSnapshot{Member: member, Metadata: metadata})
	}

	if len(snapshots) == 0 {
		return fmt.Errorf("no snapshots available from cluster peers")
	}

	// Identify the node with the most recent full state (based on metadata timestamp).
	leader := snapshots[0]
	for _, s := range snapshots[1:] {
		if s.Metadata.Timestamp.After(leader.Metadata.Timestamp) {
			leader = s
		}
	}
	logger.Info("Syncing full state from node %s with snapshot timestamp %v", leader.Member.Name, leader.Metadata.Timestamp)

	// Fetch the full export from the leader node.
	exportURL := fmt.Sprintf("http://%s%s/snapshots/export", leader.Member.Addr.String(), api.HTTPPort)
	resp, err := http.Get(exportURL)
	if err != nil {
		return fmt.Errorf("failed to fetch full export from node %s: %w", leader.Member.Name, err)
	}
	exportData, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		return fmt.Errorf("failed to read full export data: %w", err)
	}

	var exportMap map[string]any
	if err := json.Unmarshal(exportData, &exportMap); err != nil {
		return fmt.Errorf("failed to unmarshal exportData: %w", err)
	}

	// Import the full export into the local database.
	if err := p.ImportSnapshots(exportMap); err != nil {
		return fmt.Errorf("failed to import full export: %w", err)
	}
	logger.Info("Local instance successfully synced with the leader's full state.")

	// Propagate the full export to nodes that are out-of-sync.
	// For each node with an older snapshot timestamp, POST the export to /snapshots/import.
	for _, nodeSnap := range snapshots {
		if nodeSnap.Metadata.Timestamp.Before(leader.Metadata.Timestamp) {
			importURL := fmt.Sprintf("http://%s%s/snapshots/import", nodeSnap.Member.Addr.String(), api.HTTPPort)
			resp, err := http.Post(importURL, "application/json", bytes.NewReader(exportData))
			if err != nil {
				logger.Warn("Failed to push full export to node %s: %v", nodeSnap.Member.Name, err)
				continue
			}
			resp.Body.Close()
			if resp.StatusCode != http.StatusOK {
				logger.Warn("Node %s responded with status %d during sync", nodeSnap.Member.Name, resp.StatusCode)
			} else {
				logger.Info("Successfully pushed full export to node %s", nodeSnap.Member.Name)
			}
		}
	}

	logger.Info("Full cluster state synchronization complete.")
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
	meta, err := p.LoadMetadata()
	if err != nil {
		meta = api.SnapshotMetadata{}
	}
	meta.Hash = newHash
	return p.saveMetadata(meta)
}

// computeHash computes a SHA-256 hash over all buckets and their key/value pairs.
func (p *Persistence) computeHash() (string, error) {
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

// createDefaultBuckets ensures that the metadata and default state buckets exist.
// If a default snapshot is not present, it is created.
func (p *Persistence) createDefaultBuckets() error {
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

// getActiveSnapshotKey retrieves the active snapshot key from metadata.
func (p *Persistence) getActiveSnapshotKey() (string, error) {
	meta, err := p.LoadMetadata()
	if err != nil || meta.ActiveSnapshot == "" {
		return defaultSnapshotKey, nil
	}
	return meta.ActiveSnapshot, nil
}

// persistState saves the current state under the given snapshot key.
// Note that it does not update lastSave; the caller should update lastSave as needed.
func (p *Persistence) persistState(snapshotKey string) (*PersistentState, error) {
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

	if err := p.updateHash(); err != nil {
		return nil, err
	}

	return ps, nil
}
