package persistence

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"go.etcd.io/bbolt"
)

const (
	bucketActive          = "active"
	bucketAudio           = "audio"
	bucketDevice          = "device"
	bucketFusion          = "fusion"
	bucketPendingCommands = "pending_commands"
	bucketSnapshots       = "snapshots"
	bucketTasks           = "tasks"

	keyActiveState     = "state"
	keyDefaultSnapshot = "default"
	keyDeviceInfo      = "info"
	keyMetadata        = "metadata"

	debounceTime = 100 * time.Millisecond
	permPrivate  = 0600
)

// ErrNotFound is returned when a record or bucket doesn't exist.
var ErrNotFound = errors.New("not found")

// Persistence handles state persistence and metadata management.
type Persistence struct {
	dbPath       string
	stateManager *StateManager
	db           *bbolt.DB
	mutex        sync.RWMutex
	lastSave     time.Time
	saveDebounce time.Duration
	saveCh       chan struct{}
}

// NewPersistence opens the database and returns a new persistence instance.
func NewPersistence(dbPath string, stateManager *StateManager) (*Persistence, error) {

	logger := logging.GetLogger()

	db, err := bbolt.Open(dbPath, permPrivate, nil)
	if err != nil {
		logger.Warn("Failed to open database at %s: %v. Attempting to recreate.", dbPath, err)
		_ = os.Remove(dbPath)
		db, err = bbolt.Open(dbPath, permPrivate, nil)
		if err != nil {
			return nil, fmt.Errorf("failed to open or recreate database: %w", err)
		}
		logger.Debug("Successfully recreated new database at %s", dbPath)
	}

	// Ensure audio directory exists
	if err := os.MkdirAll(api.AudioFilesLocation, 0755); err != nil {
		return nil, fmt.Errorf("mkdir %s: %w", api.AudioFilesLocation, err)
	}

	persistence := &Persistence{
		dbPath:       dbPath,
		stateManager: stateManager,
		db:           db,
		saveDebounce: debounceTime,
		saveCh:       make(chan struct{}, 1),
	}

	if err := persistence.initializeDatabase(); err != nil {
		return nil, err
	}

	go persistence.saveWorker()

	return persistence, nil
}

// Close safely closes the database.
func (p *Persistence) Close() {
	p.SaveState()
	close(p.saveCh)
	p.db.Close()
}

// MarkDirty triggers a state save with debounce
func (p *Persistence) MarkDirty() {
	select {
	case p.saveCh <- struct{}{}:
	default:
		// channel already has a pending signal — ignore
	}
}

// SaveState persists the current state as the live "active" state.
func (p *Persistence) SaveState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	ps, err := p.persistActiveState()
	if err != nil {
		return err
	}

	p.lastSave = time.Now().UTC()

	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}
	metadata.Version = ps.Version
	metadata.Valid = len(ps.State) > 0

	if err := p.saveMetadata(metadata); err != nil {
		return fmt.Errorf("failed to update metadata: %w", err)
	}

	logging.GetLogger().Debug("State saved (version: %v, checksum: %s) to active state",
		ps.Version, ps.Checksum)

	return nil
}

// ValidateState checks that the persistant state has a valid checksum.
func (p *Persistence) ValidateState() error {

	// Grab an immutable snapshot of the data only
	payload := p.stateManager.GetStateMap()

	// Recompute checksum over that payload
	calculated, err := utils.JSONChecksum(payload)
	if err != nil {
		return fmt.Errorf("failed to calculate checksum: %w", err)
	}

	// Now grab the expected checksum from the VersionedState
	expected := p.stateManager.GetFullState().Checksum

	if calculated != expected {
		return fmt.Errorf(
			"checksum mismatch: expected %s, calculated %s",
			expected, calculated,
		)
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

	p.mutex.Lock()
	defer p.mutex.Unlock()

	update := false

	// Get the snapshots from the import
	snapshotsData, ok := importData[bucketSnapshots]
	if ok {
		// Assert snapshotsData is a map[string]any.
		snapshots, ok := snapshotsData.(map[string]any)
		if !ok {
			return fmt.Errorf("snapshots data is not in the expected format")
		}

		if err := p.replaceBucketData(bucketSnapshots, snapshots); err != nil {
			return err
		}

		update = true
	}

	// Get the tasks from the import
	tasksData, ok := importData[bucketTasks]
	if ok {
		// Assert tasksData is a map[string]any.
		tasks, ok := tasksData.(map[string]any)
		if !ok {
			return fmt.Errorf("tasks data is not in the expected format")
		}

		if err := p.replaceBucketData(bucketTasks, tasks); err != nil {
			return err
		}

		update = true
	}

	if !update {
		return nil
	}

	// Update the overall database hash
	if err := p.updateHash(); err != nil {
		return fmt.Errorf("failed to update DB hash after import: %w", err)
	}

	return nil
}

// persistStateToBucket saves the current state into the given bucket/key.
// Used by both snapshot persistence and active state persistence.
func (p *Persistence) persistStateToBucket(bucketName, key string) (*PersistentState, error) {
	state := p.stateManager.GetFullState()

	// Ensure we always have a checksum
	chk := state.Checksum
	if chk == "" {
		// Compute over the state payload only
		payload := state.State
		if c, err := utils.JSONChecksum(payload); err == nil {
			chk = c
		}
	}

	ps := &PersistentState{
		Version:   p.stateManager.GetVersion(),
		Timestamp: time.Now().UTC(),
		Checksum:  chk,
		State:     deepCopyState(state.State),
	}

	data, err := json.Marshal(ps)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal state: %w", err)
	}

	err = p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketName))
		if bucket == nil {
			return fmt.Errorf("%s bucket not found", bucketName)
		}
		return bucket.Put([]byte(key), data)
	})
	if err != nil {
		return nil, fmt.Errorf("failed to save state to %s/%s: %w", bucketName, key, err)
	}

	if err := p.updateHash(); err != nil {
		return nil, err
	}

	return ps, nil
}

// persistState saves the current state under the given snapshot key
// in the snapshots bucket. This is ONLY for explicit snapshot creation.
func (p *Persistence) persistState(snapshotKey string) (*PersistentState, error) {
	return p.persistStateToBucket(bucketSnapshots, snapshotKey)
}

// persistActiveState saves the current state as the live "active" state.
// This is what SaveState() uses instead of mutating snapshots.
func (p *Persistence) persistActiveState() (*PersistentState, error) {
	return p.persistStateToBucket(bucketActive, keyActiveState)
}

// loadMetadata retrieves and unmarshals the api.DatabaseMetadata from the database.
func (p *Persistence) loadMetadata() (*api.DatabaseMetadata, error) {
	var metadata api.DatabaseMetadata
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketFusion))
		if bucket == nil {
			return fmt.Errorf("metadata bucket not found")
		}
		data := bucket.Get([]byte(keyMetadata))
		if data == nil {
			return fmt.Errorf("metadata not found")
		}
		return json.Unmarshal(data, &metadata)
	})
	if err != nil {
		return nil, err
	}
	return &metadata, nil
}

// saveMetadata saves the api.DatabaseMetadata into the metadata bucket.
func (p *Persistence) saveMetadata(meta *api.DatabaseMetadata) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	return p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketFusion))
		if bucket == nil {
			return fmt.Errorf("metadata bucket not found")
		}
		return bucket.Put([]byte(keyMetadata), data)
	})
}

// updateHash recalculates the overall database hash and updates it in metadata.
func (p *Persistence) updateHash() error {
	newHash, err := p.computeHash()
	if err != nil {
		return fmt.Errorf("failed to compute DB hash: %w", err)
	}
	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}
	metadata.Hash = newHash
	return p.saveMetadata(metadata)
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

func createBucketIfNotExists(tx *bbolt.Tx, bucket string) error {
	_, err := tx.CreateBucketIfNotExists([]byte(bucket))
	if err != nil {
		return fmt.Errorf("failed to create bucket '%s': %w", bucket, err)
	}
	return nil
}

func (p *Persistence) initializeDatabase() error {

	return p.db.Update(func(tx *bbolt.Tx) error {

		// Bail out if buckets exist
		if tx.Bucket([]byte(bucketActive)) != nil &&
			tx.Bucket([]byte(bucketAudio)) != nil &&
			tx.Bucket([]byte(bucketFusion)) != nil &&
			tx.Bucket([]byte(bucketDevice)) != nil &&
			tx.Bucket([]byte(bucketTasks)) != nil &&
			tx.Bucket([]byte(bucketPendingCommands)) != nil &&
			tx.Bucket([]byte(bucketSnapshots)) != nil {
			return nil
		}

		// Otherwise create any missing buckets
		for _, bucket := range []string{
			bucketActive,
			bucketAudio,
			bucketDevice,
			bucketFusion,
			bucketPendingCommands,
			bucketTasks,
			bucketSnapshots} {
			if err := createBucketIfNotExists(tx, bucket); err != nil {
				return err
			}
		}

		// We have a new database. Set up the default data.
		snapshotsBucket := tx.Bucket([]byte(bucketSnapshots))
		if err := p.initializeDefaultSnapshot(snapshotsBucket); err != nil {
			return err
		}

		fusionBucket := tx.Bucket([]byte(bucketFusion))
		if err := p.initializeMetadata(fusionBucket); err != nil {
			return err
		}

		// Seed the active state with whatever is in the default snapshot
		activeBucket := tx.Bucket([]byte(bucketActive))
		if err := p.initializeActiveState(activeBucket); err != nil {
			return err
		}

		return nil
	})
}

func (p *Persistence) replaceBucketData(bucketName string, data map[string]any) error {

	// Replace the entire bucket in an atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {

		bucket := tx.Bucket([]byte(bucketName))
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

func (p *Persistence) initializeActiveState(bucket *bbolt.Bucket) error {

	if existing := bucket.Get([]byte(keyActiveState)); existing != nil {
		return nil
	}

	state := p.stateManager.GetFullState()

	ps := PersistentState{
		Version:   p.stateManager.GetVersion(),
		Timestamp: time.Now().UTC(),
		Checksum:  state.Checksum,
		State:     deepCopyState(state.State),
	}
	data, err := json.Marshal(ps)
	if err != nil {
		return fmt.Errorf("failed to marshal initial active state: %w", err)
	}
	if err := bucket.Put([]byte(keyActiveState), data); err != nil {
		return fmt.Errorf("failed to save initial active state: %w", err)
	}
	return nil
}

func (p *Persistence) initializeDefaultSnapshot(bucket *bbolt.Bucket) error {

	state := p.stateManager.GetFullState()

	ps := PersistentState{
		Version:   p.stateManager.GetVersion(),
		Timestamp: time.Now().UTC(),
		Checksum:  state.Checksum,
		State:     deepCopyState(state.State),
	}
	data, err := json.Marshal(ps)
	if err != nil {
		return fmt.Errorf("failed to marshal default snapshot: %w", err)
	}
	if err := bucket.Put([]byte(keyDefaultSnapshot), data); err != nil {
		return fmt.Errorf("failed to save default snapshot: %w", err)
	}
	return nil
}

func (p *Persistence) initializeMetadata(bucket *bbolt.Bucket) error {

	// If metadata already exists, do not overwrite.
	if existing := bucket.Get([]byte(keyMetadata)); existing != nil {
		return nil
	}

	newHash, err := p.computeHash()
	if err != nil {
		return fmt.Errorf("failed to compute DB hash: %w", err)
	}

	meta := &api.DatabaseMetadata{
		ActiveSnapshot: keyDefaultSnapshot,
		Hash:           newHash,
		Valid:          true,
	}

	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	return bucket.Put([]byte(keyMetadata), data)
}

// saveWorker saves state with debounce
func (p *Persistence) saveWorker() {
	var (
		timer *time.Timer
		mu    sync.Mutex
	)

	for range p.saveCh {
		mu.Lock()
		if timer != nil {
			timer.Reset(p.saveDebounce)
			mu.Unlock()
			continue
		}

		timer = time.AfterFunc(p.saveDebounce, func() {
			if err := p.SaveState(); err != nil {
				logging.GetLogger().Error("Error saving state: %v", err)
			}

			mu.Lock()
			timer = nil
			mu.Unlock()
		})
		mu.Unlock()
	}
}

// RemoveAudioFile removes an audio file from a node
func (p *Persistence) RemoveAudioFile(id string) error {
	meta, err := p.GetAudioMetadata(id)
	if err != nil {
		return err
	}
	if meta == nil {
		return nil
	}

	path := filepath.Join(api.AudioFilesLocation, meta.Filename)
	if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("remove %s: %w", path, err)
	}

	return p.DeleteAudioMetadata(id)
}

// SyncAudioFile retrieves an audio file from another node and stores metadata.
func (p *Persistence) SyncAudioFile(update *api.AudioSyncUpdate) error {
	finalPath := filepath.Join(api.AudioFilesLocation, update.Metadata.Filename)

	// Attempt to open a temp file with O_CREATE|O_EXCL
	// If the final file already exists, return early.
	tmpPath := finalPath + ".part"

	tmp, err := os.OpenFile(tmpPath, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0644)
	if err != nil {
		// If temp file or final file already exists, another goroutine/node is handling it
		if os.IsExist(err) {
			if _, statErr := os.Stat(finalPath); statErr == nil {
				// File already exists — we're done
				return nil
			}
			// If .part exists but final doesn't, someone else is writing it — treat as in progress
			return nil
		}
		return fmt.Errorf("create %s: %w", tmpPath, err)
	}

	// Make sure cleanup happens if anything fails after this point
	cleanup := func(err error) error {
		tmp.Close()
		os.Remove(tmpPath)
		return err
	}

	// Fetch source data
	streamEndpoint := strings.Replace(routes.PAVAMessageStreamEndpoint, "{id}", update.Metadata.Id, 1)
	streamURL := fmt.Sprintf("%s%s", update.URL, streamEndpoint)

	resp, err := http.Get(streamURL)
	if err != nil {
		return cleanup(fmt.Errorf("GET %s: %w", streamURL, err))
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return cleanup(fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(body)))
	}

	// Copy file body to temp
	if _, err := io.Copy(tmp, resp.Body); err != nil {
		return cleanup(fmt.Errorf("copy: %w", err))
	}

	if err := tmp.Sync(); err != nil {
		return cleanup(fmt.Errorf("sync: %w", err))
	}

	if err := tmp.Close(); err != nil {
		return cleanup(fmt.Errorf("close: %w", err))
	}

	// Rename atomically
	if err := os.Rename(tmpPath, finalPath); err != nil {
		// Attempt cleanup but return rename error
		os.Remove(tmpPath)
		return fmt.Errorf("rename %s → %s: %w", tmpPath, finalPath, err)
	}

	if err := p.SaveAudioMeta(&update.Metadata); err != nil {
		return fmt.Errorf("SaveAudioMeta: %w", err)
	}

	return nil
}

func (p *Persistence) GetVersion() api.Version {
	return p.stateManager.GetVersion()
}
