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
	bucketActive       = "active"
	bucketAudio        = "audio"
	bucketDevice       = "device"
	bucketFusion       = "fusion"
	bucketSceneSets    = "scene_sets"
	bucketSnapshotDefs = "snapshot_definitions"
	bucketSnapshots    = "snapshots"
	bucketTasks        = "tasks"

	keyActiveState     = "state"
	keyDefaultSnapshot = "default"
	keyDeviceInfo      = "info"
	keyMetadata        = "metadata"

	debounceTime = 100 * time.Millisecond
	permPrivate  = 0600
)

// ErrNotFound is returned when a record or bucket doesn't exist.
var ErrNotFound = errors.New("not found")

// ErrNotMember is returned when a scene is not a member of the given scene set.
var ErrNotMember = errors.New("not a member of scene set")

// Persistence handles state persistence and metadata management.
type Persistence struct {
	dbPath       string
	stateManager *StateManager
	db           *bbolt.DB
	mutex        sync.RWMutex
	lastSave     time.Time
	saveDebounce time.Duration
	saveCh       chan struct{}
	shutdownCh   chan struct{}
	workerDone   chan struct{}
	closeOnce    sync.Once
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
		shutdownCh:   make(chan struct{}),
		workerDone:   make(chan struct{}),
	}

	if err := persistence.initializeDatabase(); err != nil {
		return nil, err
	}

	go persistence.saveWorker()

	return persistence, nil
}

// Close safely closes the database.
func (p *Persistence) Close() {
	p.closeOnce.Do(func() {
		if err := p.SaveState(); err != nil {
			logging.GetLogger().Error("Error saving state during close: %v", err)
		}
		close(p.shutdownCh)
		<-p.workerDone
		if err := p.db.Close(); err != nil {
			logging.GetLogger().Error("Error closing persistence DB: %v", err)
		}
	})
}

// MarkDirty triggers a state save with debounce
func (p *Persistence) MarkDirty() {
	select {
	case <-p.shutdownCh:
		return
	default:
	}

	select {
	case p.saveCh <- struct{}{}:
	case <-p.shutdownCh:
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

	if err := p.updateHash(); err != nil {
		return fmt.Errorf("failed to update metadata hash: %w", err)
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

	var (
		update    bool
		snapshots map[string]any
		tasks     map[string]any
		audio     map[string]any
		device    map[string]any
		ok        bool
	)

	if snapshotsData, exists := importData[bucketSnapshots]; exists {
		snapshots, ok = snapshotsData.(map[string]any)
		if !ok {
			return fmt.Errorf("snapshots data is not in the expected format")
		}
		if _, exists := snapshots[keyDefaultSnapshot]; !exists {
			return fmt.Errorf("snapshots import must include default snapshot %q", keyDefaultSnapshot)
		}
		if err := validateImportedSnapshots(snapshots); err != nil {
			return err
		}
		update = true
	}

	if tasksData, exists := importData[bucketTasks]; exists {
		tasks, ok = tasksData.(map[string]any)
		if !ok {
			return fmt.Errorf("tasks data is not in the expected format")
		}
		update = true
	}

	if audioData, exists := importData[bucketAudio]; exists {
		audio, ok = audioData.(map[string]any)
		if !ok {
			return fmt.Errorf("audio data is not in the expected format")
		}
		if err := validateImportedAudio(audio); err != nil {
			return err
		}
		update = true
	}

	if deviceData, exists := importData[bucketDevice]; exists {
		device, ok = deviceData.(map[string]any)
		if !ok {
			return fmt.Errorf("device data is not in the expected format")
		}
		if err := validateImportedDevice(device); err != nil {
			return err
		}
		update = true
	}

	if !update {
		return nil
	}

	return p.db.Update(func(tx *bbolt.Tx) error {
		if snapshots != nil {
			if tasks == nil {
				existingTasks, err := loadTasksFromTx(tx)
				if err != nil {
					return fmt.Errorf("failed to load existing tasks for snapshot import validation: %w", err)
				}
				existingTaskMap := make(map[string]any, len(existingTasks))
				for key, task := range existingTasks {
					existingTaskMap[key] = task
				}
				if err := validateSnapshotTaskRefs(existingTaskMap, func(snapshotID string) (bool, error) {
					_, exists := snapshots[snapshotID]
					return exists, nil
				}); err != nil {
					return err
				}
			}

			if err := replaceBucketDataTx(tx, bucketSnapshots, snapshots); err != nil {
				return err
			}

			metadata, err := loadMetadataFromTx(tx)
			if err != nil {
				return fmt.Errorf("failed to load metadata: %w", err)
			}
			if _, exists := snapshots[metadata.ActiveSnapshot]; !exists {
				metadata.ActiveSnapshot = keyDefaultSnapshot
				if err := saveMetadataToTx(tx, metadata); err != nil {
					return fmt.Errorf("failed to update active snapshot metadata: %w", err)
				}
			}

			activeSnapshot, ok := snapshots[metadata.ActiveSnapshot]
			if !ok {
				return fmt.Errorf("active snapshot %q missing after import", metadata.ActiveSnapshot)
			}
			activeState, ok := activeSnapshot.(map[string]any)
			if !ok {
				return fmt.Errorf("active snapshot %q is not in the expected format", metadata.ActiveSnapshot)
			}
			if err := replaceBucketDataTx(tx, bucketActive, map[string]any{
				keyActiveState: activeState,
			}); err != nil {
				return fmt.Errorf("failed to refresh active state from snapshot import: %w", err)
			}
		}

		if tasks != nil {
			snapshotExists := func(snapshotID string) (bool, error) {
				if snapshots != nil {
					_, exists := snapshots[snapshotID]
					return exists, nil
				}
				b := tx.Bucket([]byte(bucketSnapshots))
				if b == nil {
					return false, nil
				}
				return b.Get([]byte(snapshotID)) != nil, nil
			}
			if err := validateSnapshotTaskRefs(tasks, snapshotExists); err != nil {
				return err
			}
			if err := replaceBucketDataTx(tx, bucketTasks, tasks); err != nil {
				return err
			}
		}

		if audio != nil {
			if err := replaceBucketDataTx(tx, bucketAudio, audio); err != nil {
				return err
			}
		}

		if device != nil {
			if err := replaceBucketDataTx(tx, bucketDevice, device); err != nil {
				return err
			}
		}

		return updateHashTx(tx)
	})
}

func validateImportedSnapshots(snapshots map[string]any) error {
	for key, value := range snapshots {
		data, err := json.Marshal(value)
		if err != nil {
			return fmt.Errorf("failed to marshal imported snapshot %q: %w", key, err)
		}

		var ps PersistentState
		if err := json.Unmarshal(data, &ps); err != nil {
			return fmt.Errorf("failed to unmarshal imported snapshot %q: %w", key, err)
		}
	}

	return nil
}

func validateImportedAudio(audio map[string]any) error {
	for key, value := range audio {
		data, err := json.Marshal(value)
		if err != nil {
			return fmt.Errorf("failed to marshal imported audio metadata %q: %w", key, err)
		}

		var meta api.AudioMetadata
		if err := json.Unmarshal(data, &meta); err != nil {
			return fmt.Errorf("failed to unmarshal imported audio metadata %q: %w", key, err)
		}
	}

	return nil
}

func validateImportedDevice(device map[string]any) error {
	for key, value := range device {
		data, err := json.Marshal(value)
		if err != nil {
			return fmt.Errorf("failed to marshal imported device record %q: %w", key, err)
		}

		if key == keyDeviceInfo {
			var info api.DevicePatch
			if err := json.Unmarshal(data, &info); err != nil {
				return fmt.Errorf("failed to unmarshal imported device record %q: %w", key, err)
			}
			continue
		}

		var fields map[string]json.RawMessage
		if err := json.Unmarshal(data, &fields); err != nil {
			return fmt.Errorf("failed to unmarshal imported device record %q: %w", key, err)
		}
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
			return fmt.Errorf("%w: %s bucket not found", ErrNotFound, bucketName)
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
	var dataCopy []byte
	err := p.db.View(func(tx *bbolt.Tx) error {
		var err error
		dataCopy, err = metadataBytesFromTx(tx)
		return err
	})
	if err != nil {
		return nil, err
	}
	return decodeMetadataBytes(dataCopy)
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
			return fmt.Errorf("%w: metadata bucket not found", ErrNotFound)
		}
		return bucket.Put([]byte(keyMetadata), data)
	})
}

func metadataBytesFromTx(tx *bbolt.Tx) ([]byte, error) {
	bucket := tx.Bucket([]byte(bucketFusion))
	if bucket == nil {
		return nil, fmt.Errorf("%w: metadata bucket not found", ErrNotFound)
	}
	data := bucket.Get([]byte(keyMetadata))
	if data == nil {
		return nil, fmt.Errorf("%w: metadata not found", ErrNotFound)
	}
	return append([]byte(nil), data...), nil
}

func decodeMetadataBytes(data []byte) (*api.DatabaseMetadata, error) {
	var metadata api.DatabaseMetadata
	if err := json.Unmarshal(data, &metadata); err != nil {
		return nil, err
	}
	metadata.ActiveSnapshot = strings.Clone(metadata.ActiveSnapshot)
	metadata.Hash = strings.Clone(metadata.Hash)
	metadata.Version.NodeID = strings.Clone(metadata.Version.NodeID)
	return &metadata, nil
}

func loadMetadataFromTx(tx *bbolt.Tx) (*api.DatabaseMetadata, error) {
	data, err := metadataBytesFromTx(tx)
	if err != nil {
		return nil, err
	}
	return decodeMetadataBytes(data)
}

func saveMetadataToTx(tx *bbolt.Tx, meta *api.DatabaseMetadata) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	bucket := tx.Bucket([]byte(bucketFusion))
	if bucket == nil {
		return fmt.Errorf("%w: metadata bucket not found", ErrNotFound)
	}
	return bucket.Put([]byte(keyMetadata), data)
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

func updateHashTx(tx *bbolt.Tx) error {
	newHash, err := computeHashTx(tx)
	if err != nil {
		return fmt.Errorf("failed to compute DB hash: %w", err)
	}
	metadata, err := loadMetadataFromTx(tx)
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}
	metadata.Hash = newHash
	return saveMetadataToTx(tx, metadata)
}

// computeHash computes a SHA-256 hash over all buckets and their key/value pairs.
func (p *Persistence) computeHash() (string, error) {
	var sum string
	if err := p.db.View(func(tx *bbolt.Tx) error {
		var err error
		sum, err = computeHashTx(tx)
		return err
	}); err != nil {
		return "", err
	}
	return sum, nil
}

func computeHashTx(tx *bbolt.Tx) (string, error) {
	hash := sha256.New()
	if err := tx.ForEach(func(name []byte, b *bbolt.Bucket) error {
		hash.Write(name)
		cursor := b.Cursor()
		for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
			hash.Write(k)
			normalizedValue, err := normalizeHashValue(string(name), string(k), v)
			if err != nil {
				return err
			}
			hash.Write(normalizedValue)
		}
		return nil
	}); err != nil {
		return "", err
	}

	return hex.EncodeToString(hash.Sum(nil)), nil
}

func normalizeHashValue(bucketName, key string, value []byte) ([]byte, error) {
	if bucketName != bucketFusion || key != keyMetadata {
		return value, nil
	}

	var metadata api.DatabaseMetadata
	if err := json.Unmarshal(value, &metadata); err != nil {
		return nil, fmt.Errorf("failed to unmarshal metadata for hashing: %w", err)
	}

	// Exclude the stored DB hash from the hash input so the value is stable.
	metadata.Hash = ""

	normalized, err := json.Marshal(metadata)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal normalized metadata for hashing: %w", err)
	}

	return normalized, nil
}

func createBucketIfNotExists(tx *bbolt.Tx, bucket string) error {
	_, err := tx.CreateBucketIfNotExists([]byte(bucket))
	if err != nil {
		return fmt.Errorf("failed to create bucket '%s': %w", bucket, err)
	}
	return nil
}

func (p *Persistence) initializeDatabase() error {
	var initialized bool

	err := p.db.Update(func(tx *bbolt.Tx) error {
		for _, bucket := range []string{
			bucketActive,
			bucketAudio,
			bucketDevice,
			bucketFusion,
			bucketSceneSets,
			bucketSnapshotDefs,
			bucketTasks,
			bucketSnapshots,
		} {
			if err := createBucketIfNotExists(tx, bucket); err != nil {
				return err
			}
		}

		snapshotsBucket := tx.Bucket([]byte(bucketSnapshots))
		changed, err := p.initializeDefaultSnapshot(snapshotsBucket)
		if err != nil {
			return err
		}
		initialized = initialized || changed

		activeBucket := tx.Bucket([]byte(bucketActive))
		changed, err = p.initializeActiveState(activeBucket)
		if err != nil {
			return err
		}
		initialized = initialized || changed

		fusionBucket := tx.Bucket([]byte(bucketFusion))
		changed, err = p.initializeMetadata(fusionBucket)
		if err != nil {
			return err
		}
		initialized = initialized || changed

		return nil
	})
	if err != nil {
		return err
	}

	if initialized {
		if err := p.updateHash(); err != nil {
			return fmt.Errorf("failed to update DB hash after initialization: %w", err)
		}
	}

	return nil
}

func (p *Persistence) replaceBucketData(bucketName string, data map[string]any) error {

	// Replace the entire bucket in an atomic transaction.
	err := p.db.Update(func(tx *bbolt.Tx) error {
		return replaceBucketDataTx(tx, bucketName, data)
	})

	return err
}

func replaceBucketDataTx(tx *bbolt.Tx, bucketName string, data map[string]any) error {
	bucket := tx.Bucket([]byte(bucketName))
	if bucket == nil {
		return fmt.Errorf("%w: %s bucket not found", ErrNotFound, bucketName)
	}

	var keysToDelete []string
	err := bucket.ForEach(func(k, _ []byte) error {
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

	for key, value := range data {
		marshaledValue, err := json.Marshal(value)
		if err != nil {
			return fmt.Errorf("failed to marshal value for key %s: %w", key, err)
		}
		if err := bucket.Put([]byte(key), marshaledValue); err != nil {
			return fmt.Errorf("failed to put key %s: %w", key, err)
		}
	}

	return nil
}

func loadTasksFromTx(tx *bbolt.Tx) (map[string]*api.Task, error) {
	tasks := make(map[string]*api.Task)
	b := tx.Bucket([]byte(bucketTasks))
	if b == nil {
		return tasks, nil
	}

	if err := b.ForEach(func(key, value []byte) error {
		var task api.Task
		if err := json.Unmarshal(value, &task); err != nil {
			return fmt.Errorf("failed to unmarshal task data: %w", err)
		}
		tasks[string(key)] = &task
		return nil
	}); err != nil {
		return nil, err
	}

	return tasks, nil
}

func (p *Persistence) initializeActiveState(bucket *bbolt.Bucket) (bool, error) {

	if existing := bucket.Get([]byte(keyActiveState)); existing != nil {
		return false, nil
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
		return false, fmt.Errorf("failed to marshal initial active state: %w", err)
	}
	if err := bucket.Put([]byte(keyActiveState), data); err != nil {
		return false, fmt.Errorf("failed to save initial active state: %w", err)
	}
	return true, nil
}

func (p *Persistence) initializeDefaultSnapshot(bucket *bbolt.Bucket) (bool, error) {

	if existing := bucket.Get([]byte(keyDefaultSnapshot)); existing != nil {
		return false, nil
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
		return false, fmt.Errorf("failed to marshal default snapshot: %w", err)
	}
	if err := bucket.Put([]byte(keyDefaultSnapshot), data); err != nil {
		return false, fmt.Errorf("failed to save default snapshot: %w", err)
	}
	return true, nil
}

func (p *Persistence) initializeMetadata(bucket *bbolt.Bucket) (bool, error) {

	// If metadata already exists, do not overwrite.
	if existing := bucket.Get([]byte(keyMetadata)); existing != nil {
		return false, nil
	}

	meta := &api.DatabaseMetadata{
		ActiveSnapshot: keyDefaultSnapshot,
		Hash:           "",
		Valid:          true,
	}

	data, err := json.Marshal(meta)
	if err != nil {
		return false, fmt.Errorf("failed to marshal metadata: %w", err)
	}

	if err := bucket.Put([]byte(keyMetadata), data); err != nil {
		return false, err
	}

	return true, nil
}

// saveWorker saves state with debounce
func (p *Persistence) saveWorker() {
	defer close(p.workerDone)

	var (
		timer   *time.Timer
		timerCh <-chan time.Time
	)

	stopTimer := func() {
		if timer == nil {
			return
		}
		if !timer.Stop() {
			select {
			case <-timer.C:
			default:
			}
		}
		timer = nil
		timerCh = nil
	}

	for {
		select {
		case <-p.saveCh:
			if timer == nil {
				timer = time.NewTimer(p.saveDebounce)
				timerCh = timer.C
				continue
			}
			if !timer.Stop() {
				select {
				case <-timer.C:
				default:
				}
			}
			timer.Reset(p.saveDebounce)
		case <-timerCh:
			stopTimer()
			if err := p.SaveState(); err != nil {
				logging.GetLogger().Error("Error saving state: %v", err)
			}
		case <-p.shutdownCh:
			stopTimer()
			return
		}
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
				// The file is already present; ensure metadata is present as well.
				return p.SaveAudioMeta(&update.Metadata)
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
