package persistence

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/gibson042/canonicaljson-go"
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

	miB = 1024 * 1024

	boltOpenTimeout     = 1 * time.Second
	compactMinFreeBytes = 1 * miB
	compactMinFreeRatio = 0.25
	compactTxMaxSize    = 4 * miB
	minSaveInterval     = 2 * time.Second
)

var antiEntropyBuckets = []string{
	bucketSnapshots,
	bucketTasks,
	bucketSnapshotDefs,
	bucketSceneSets,
	bucketAudio,
	bucketDevice,
}

type saveState struct {
	lastRun   time.Time
	debounce  time.Duration
	triggerCh chan struct{}
}

// ErrNotFound is returned when a record or bucket doesn't exist.
var ErrNotFound = errors.New("not found")

// ErrNotMember is returned when a scene is not a member of the given scene set.
var ErrNotMember = errors.New("not a member of scene set")

// Persistence handles state persistence and metadata management.
type Persistence struct {
	dbPath           string
	stateManager     *StateManager
	db               *bbolt.DB
	dbOptions        *bbolt.Options
	mutex            sync.RWMutex
	notifierMu       sync.RWMutex
	metadataNotifier func(*model.DatabaseMetadata)
	lastSave         time.Time
	saveDebounce     time.Duration
	minSaveGap       time.Duration
	saveCh           chan struct{}
	shutdownCh       chan struct{}
	workerDone       chan struct{}
	closeOnce        sync.Once
}

// NewPersistence opens the database and returns a new persistence instance.
func NewPersistence(dbPath string, stateManager *StateManager) (*Persistence, error) {

	logger := logging.GetLogger()
	dbOptions := defaultBoltOptions()

	db, err := bbolt.Open(dbPath, permPrivate, dbOptions)
	if err != nil {
		logger.Warn("Failed to open database at %s: %v. Attempting to recreate.", dbPath, err)
		_ = os.Remove(dbPath)
		db, err = bbolt.Open(dbPath, permPrivate, dbOptions)
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
		dbOptions:    dbOptions,
		saveDebounce: debounceTime,
		minSaveGap:   minSaveInterval,
		saveCh:       make(chan struct{}, 1),
		shutdownCh:   make(chan struct{}),
		workerDone:   make(chan struct{}),
	}

	if err := persistence.initializeDatabase(); err != nil {
		return nil, err
	}
	if err := persistence.maybeCompactOnOpen(); err != nil {
		return nil, err
	}

	go persistence.saveWorker()

	logger.Debug(
		"Persistence opened: path=%s freelist_type=%s no_freelist_sync=%t",
		dbPath, dbOptions.FreelistType, dbOptions.NoFreelistSync,
	)

	return persistence, nil
}

func defaultBoltOptions() *bbolt.Options {
	return &bbolt.Options{
		Timeout:        boltOpenTimeout,
		NoFreelistSync: true,
		FreelistType:   bbolt.FreelistMapType,
	}
}

// Close safely closes the database.
func (p *Persistence) Close() {
	p.closeOnce.Do(func() {
		if err := p.SaveState(); err != nil {
			if errors.Is(err, ErrNotFound) {
				logging.GetLogger().Debug("Skipping close-time state save: %v", err)
			} else {
				logging.GetLogger().Error("Error saving state during close: %v", err)
			}
		}
		close(p.shutdownCh)
		<-p.workerDone
		if err := p.db.Close(); err != nil {
			logging.GetLogger().Error("Error closing persistence DB: %v", err)
		}
	})
}

func (p *Persistence) SetMetadataNotifier(notifier func(*model.DatabaseMetadata)) {
	p.notifierMu.Lock()
	defer p.notifierMu.Unlock()
	p.metadataNotifier = notifier
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
		logging.GetLogger().Debug("Active state flush queued")
	default:
		logging.GetLogger().Debug("Active state flush skipped: save already pending")
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
	metadata.Version = versionInfoFromAPI(ps.Version)
	metadata.Valid = len(ps.State) > 0

	if err := p.saveMetadataWithNotify(metadata, false); err != nil {
		return fmt.Errorf("failed to update metadata: %w", err)
	}

	if err := p.updateHash(true); err != nil {
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
			// Device identity is node-local and must not be exported to peers.
			if bucket == bucketDevice {
				return nil
			}
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
		update       bool
		active       map[string]any
		snapshots    map[string]any
		snapshotDefs map[string]any
		sceneSets    map[string]any
		tasks        map[string]any
		audio        map[string]any
		ok           bool
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

	if activeData, exists := importData[bucketActive]; exists {
		active, ok = activeData.(map[string]any)
		if !ok {
			return fmt.Errorf("active data is not in the expected format")
		}
		if err := validateImportedActive(active); err != nil {
			return err
		}
		update = true
	}

	if snapshotDefsData, exists := importData[bucketSnapshotDefs]; exists {
		snapshotDefs, ok = snapshotDefsData.(map[string]any)
		if !ok {
			return fmt.Errorf("snapshot definitions data is not in the expected format")
		}
		update = true
	}

	if sceneSetsData, exists := importData[bucketSceneSets]; exists {
		sceneSets, ok = sceneSetsData.(map[string]any)
		if !ok {
			return fmt.Errorf("scene sets data is not in the expected format")
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

	// Device identity is node-local; ignore any device data in the import payload.
	// This prevents anti-entropy sync from overwriting per-node identity.

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

			if active == nil {
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
		}

		if active != nil {
			if err := replaceBucketDataTx(tx, bucketActive, active); err != nil {
				return fmt.Errorf("failed to replace active state during import: %w", err)
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

		if snapshotDefs != nil {
			if err := replaceBucketDataTx(tx, bucketSnapshotDefs, snapshotDefs); err != nil {
				return err
			}
		}

		if sceneSets != nil {
			if err := replaceBucketDataTx(tx, bucketSceneSets, sceneSets); err != nil {
				return err
			}
		}

		if audio != nil {
			if err := replaceBucketDataTx(tx, bucketAudio, audio); err != nil {
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

func validateImportedActive(active map[string]any) error {
	stateData, exists := active[keyActiveState]
	if !exists {
		return fmt.Errorf("active import must include key %q", keyActiveState)
	}

	data, err := json.Marshal(stateData)
	if err != nil {
		return fmt.Errorf("failed to marshal imported active state %q: %w", keyActiveState, err)
	}

	var ps PersistentState
	if err := json.Unmarshal(data, &ps); err != nil {
		return fmt.Errorf("failed to unmarshal imported active state %q: %w", keyActiveState, err)
	}

	return nil
}

func validateImportedAudio(audio map[string]any) error {
	for key, value := range audio {
		data, err := json.Marshal(value)
		if err != nil {
			return fmt.Errorf("failed to marshal imported audio metadata %q: %w", key, err)
		}

		var meta model.AudioMetadata
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
			var info model.DevicePatch
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
func (p *Persistence) persistStateToBucket(bucketName, key string, bumpMetadataVersion bool) (*PersistentState, error) {
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

	var changed bool
	err = p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketName))
		if bucket == nil {
			return fmt.Errorf("%w: %s bucket not found", ErrNotFound, bucketName)
		}
		var err error
		changed, err = putIfChanged(bucket, []byte(key), data)
		return err
	})
	if err != nil {
		return nil, fmt.Errorf("failed to save state to %s/%s: %w", bucketName, key, err)
	}

	if changed {
		if bumpMetadataVersion {
			if err := p.updateHash(true); err != nil {
				return nil, err
			}
		} else {
			if err := p.updateHash(false); err != nil {
				return nil, err
			}
		}
	} else {
		logging.GetLogger().Debug("Persistence write skipped: bucket=%s key=%s unchanged", bucketName, key)
	}

	return ps, nil
}

func putIfChanged(bucket *bbolt.Bucket, key, value []byte) (bool, error) {
	existing := bucket.Get(key)
	if bytes.Equal(existing, value) {
		return false, nil
	}
	if err := bucket.Put(key, value); err != nil {
		return false, err
	}
	return true, nil
}

func (p *Persistence) getValue(bucketName, key string) ([]byte, error) {
	var dataCopy []byte
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketName))
		if bucket == nil {
			return ErrNotFound
		}
		value := bucket.Get([]byte(key))
		if value == nil {
			return nil
		}
		dataCopy = append([]byte(nil), value...)
		return nil
	})
	if err != nil {
		return nil, err
	}
	return dataCopy, nil
}

func (p *Persistence) keyExists(bucketName, key string) (bool, error) {
	var exists bool
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketName))
		if bucket == nil {
			return ErrNotFound
		}
		exists = bucket.Get([]byte(key)) != nil
		return nil
	})
	return exists, err
}

// persistState saves the current state under the given snapshot key
// in the snapshots bucket. This is ONLY for explicit snapshot creation.
func (p *Persistence) persistState(snapshotKey string) (*PersistentState, error) {
	return p.persistStateToBucket(bucketSnapshots, snapshotKey, true)
}

// persistActiveState saves the current state as the live "active" state.
// This is what SaveState() uses instead of mutating snapshots.
func (p *Persistence) persistActiveState() (*PersistentState, error) {
	return p.persistStateToBucket(bucketActive, keyActiveState, false)
}

// loadMetadata retrieves and unmarshals the model.DatabaseMetadata from the database.
func (p *Persistence) loadMetadata() (*model.DatabaseMetadata, error) {
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

// saveMetadata saves the model.DatabaseMetadata into the metadata bucket.
func (p *Persistence) saveMetadata(meta *model.DatabaseMetadata) error {
	return p.saveMetadataWithNotify(meta, true)
}

func (p *Persistence) saveMetadataWithNotify(meta *model.DatabaseMetadata, notify bool) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	if err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketFusion))
		if bucket == nil {
			return fmt.Errorf("%w: metadata bucket not found", ErrNotFound)
		}
		_, err := putIfChanged(bucket, []byte(keyMetadata), data)
		return err
	}); err != nil {
		return err
	}

	if notify {
		p.notifierMu.RLock()
		notifier := p.metadataNotifier
		p.notifierMu.RUnlock()
		if notifier != nil {
			metaCopy := *meta
			go notifier(&metaCopy)
		}
	}

	return nil
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

func decodeMetadataBytes(data []byte) (*model.DatabaseMetadata, error) {
	var metadata model.DatabaseMetadata
	if err := json.Unmarshal(data, &metadata); err != nil {
		return nil, err
	}
	metadata.ActiveSnapshot = strings.Clone(metadata.ActiveSnapshot)
	metadata.Hash = strings.Clone(metadata.Hash)
	if metadata.Version != nil {
		metadata.Version.NodeId = strings.Clone(metadata.Version.NodeId)
	}
	return &metadata, nil
}

func versionInfoFromAPI(v api.Version) *model.VersionInfo {
	return &model.VersionInfo{
		Epoch:   v.Epoch,
		Counter: v.Counter,
		NodeId:  v.NodeID,
	}
}

func apiVersionFromProto(v *model.VersionInfo) api.Version {
	if v == nil {
		return api.Version{}
	}
	return api.Version{
		Epoch:   v.Epoch,
		Counter: v.Counter,
		NodeID:  v.NodeId,
	}
}

func loadMetadataFromTx(tx *bbolt.Tx) (*model.DatabaseMetadata, error) {
	data, err := metadataBytesFromTx(tx)
	if err != nil {
		return nil, err
	}
	return decodeMetadataBytes(data)
}

func saveMetadataToTx(tx *bbolt.Tx, meta *model.DatabaseMetadata) error {
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
func (p *Persistence) updateHash(notify bool) error {
	newHash, err := p.computeHash()
	if err != nil {
		return fmt.Errorf("failed to compute DB hash: %w", err)
	}
	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}
	if metadata.Version == nil {
		metadata.Version = versionInfoFromAPI(p.stateManager.GetVersion())
	} else if metadata.Version.NodeId == "" {
		metadata.Version.NodeId = p.stateManager.GetVersion().NodeID
	}
	metadata.Hash = newHash
	return p.saveMetadataWithNotify(metadata, notify)
}

func (p *Persistence) updateHashWithVersionBump(notify bool) error {
	newHash, err := p.computeHash()
	if err != nil {
		return fmt.Errorf("failed to compute DB hash: %w", err)
	}

	metadata, err := p.loadMetadata()
	if err != nil {
		return fmt.Errorf("failed to load metadata: %w", err)
	}

	metadata.Version = versionInfoFromAPI(p.stateManager.NextVersionAfter(apiVersionFromProto(metadata.Version)))
	metadata.Hash = newHash
	metadata.Valid = true

	return p.saveMetadataWithNotify(metadata, notify)
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
	for _, bucketName := range antiEntropyBuckets {

		// Device identity is node-local and must not influence the cluster hash.
		if bucketName == bucketDevice {
			continue
		}

		b := tx.Bucket([]byte(bucketName))

		if b == nil {
			continue
		}

		hash.Write([]byte(bucketName))

		cursor := b.Cursor()
		for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
			hash.Write(k)

			sanitized, err := normalizeBucketValueForHash(bucketName, string(k), v)
			if err != nil {
				return "", err
			}
			hash.Write(sanitized)
		}
	}
	return hex.EncodeToString(hash.Sum(nil)), nil
}

func normalizeBucketValueForHash(bucketName, key string, value []byte) ([]byte, error) {
	switch bucketName {
	case bucketFusion:
		if key != keyMetadata {
			return value, nil
		}
		var metadata model.DatabaseMetadata
		if err := json.Unmarshal(value, &metadata); err != nil {
			return nil, fmt.Errorf("failed to unmarshal metadata for hashing: %w", err)
		}
		metadata.Hash = ""
		metadata.Version = nil
		normalized, err := canonicaljson.Marshal(metadata)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal normalized metadata for hashing: %w", err)
		}
		return normalized, nil

	case bucketSnapshots, bucketActive:
		// Strip the Timestamp field so that nodes with logically identical
		// state but different local wrapper metadata produce the same hash. This must
		// match the normalization applied in normalizeAntiEntropyValue;
		// without it, the hash and the diff diverge, causing perpetual
		// anti-entropy repair loops.
		var state PersistentState
		if err := json.Unmarshal(value, &state); err != nil {
			return nil, fmt.Errorf("failed to unmarshal persistent state for hashing (bucket=%s key=%s): %w", bucketName, key, err)
		}
		state.Version = api.Version{}
		state.Timestamp = time.Time{}
		normalized, err := canonicaljson.Marshal(state)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal normalized persistent state for hashing (bucket=%s key=%s): %w", bucketName, key, err)
		}
		return normalized, nil

	case bucketTasks, bucketSnapshotDefs, bucketSceneSets, bucketAudio, bucketDevice:
		normalized, err := canonicalizeHashJSONValue(value)
		if err != nil {
			return nil, fmt.Errorf("failed to canonicalize JSON for hashing (bucket=%s key=%s): %w", bucketName, key, err)
		}
		return normalized, nil

	default:
		return value, nil
	}
}

func canonicalizeHashJSONValue(value []byte) ([]byte, error) {
	var decoded any
	if err := json.Unmarshal(value, &decoded); err != nil {
		return nil, err
	}
	return canonicaljson.Marshal(decoded)
}

func antiEntropyValueChecksum(bucketName string, value any) (string, error) {
	raw, err := json.Marshal(value)
	if err != nil {
		return "", fmt.Errorf("failed to marshal value for anti-entropy checksum (bucket=%s): %w", bucketName, err)
	}
	normalized, err := normalizeBucketValueForHash(bucketName, "", raw)
	if err != nil {
		return "", err
	}
	sum := sha256.Sum256(normalized)
	return hex.EncodeToString(sum[:]), nil
}

func mapStringAny(value any) map[string]any {
	if value == nil {
		return nil
	}
	if m, ok := value.(map[string]any); ok {
		return m
	}
	return nil
}

// AntiEntropyDiffSummary returns a human-readable summary of how the convergent
// persisted buckets differ from the provided remote export payload.
func (p *Persistence) AntiEntropyDiffSummary(remoteData map[string]any) string {
	localExportAny, err := p.ExportData()
	if err != nil {
		return fmt.Sprintf("failed to export local data: %v", err)
	}

	localExport, ok := localExportAny.(map[string]map[string]any)
	if !ok {
		return "failed to interpret local export data"
	}

	parts := make([]string, 0, len(antiEntropyBuckets))
	for _, bucketName := range antiEntropyBuckets {
		localBucket := localExport[bucketName]
		remoteBucket := mapStringAny(remoteData[bucketName])

		keySet := make(map[string]struct{}, len(localBucket)+len(remoteBucket))
		for key := range localBucket {
			keySet[key] = struct{}{}
		}
		for key := range remoteBucket {
			keySet[key] = struct{}{}
		}

		if len(keySet) == 0 {
			continue
		}

		keys := make([]string, 0, len(keySet))
		for key := range keySet {
			keys = append(keys, key)
		}
		sort.Strings(keys)

		changed := make([]string, 0, 3)
		localOnly := make([]string, 0, 3)
		remoteOnly := make([]string, 0, 3)

		changedCount := 0
		localOnlyCount := 0
		remoteOnlyCount := 0

		for _, key := range keys {
			localValue, hasLocal := localBucket[key]
			remoteValue, hasRemote := remoteBucket[key]

			switch {
			case hasLocal && !hasRemote:
				localOnlyCount++
				if len(localOnly) < 3 {
					localOnly = append(localOnly, key)
				}
			case !hasLocal && hasRemote:
				remoteOnlyCount++
				if len(remoteOnly) < 3 {
					remoteOnly = append(remoteOnly, key)
				}
			default:
				localChecksum, err := antiEntropyValueChecksum(bucketName, localValue)
				if err != nil {
					return fmt.Sprintf("failed to checksum local %s/%s: %v", bucketName, key, err)
				}
				remoteChecksum, err := antiEntropyValueChecksum(bucketName, remoteValue)
				if err != nil {
					return fmt.Sprintf("failed to checksum remote %s/%s: %v", bucketName, key, err)
				}
				if localChecksum != remoteChecksum {
					changedCount++
					if len(changed) < 3 {
						changed = append(changed, key)
					}
				}
			}
		}

		if changedCount == 0 && localOnlyCount == 0 && remoteOnlyCount == 0 {
			continue
		}

		summary := fmt.Sprintf("%s changed=%d local_only=%d remote_only=%d", bucketName, changedCount, localOnlyCount, remoteOnlyCount)
		if len(changed) > 0 {
			summary += fmt.Sprintf(" sample_changed=%v", changed)
		}
		if len(localOnly) > 0 {
			summary += fmt.Sprintf(" sample_local_only=%v", localOnly)
		}
		if len(remoteOnly) > 0 {
			summary += fmt.Sprintf(" sample_remote_only=%v", remoteOnly)
		}
		parts = append(parts, summary)
	}

	if len(parts) == 0 {
		return "no bucket-level differences found"
	}

	return strings.Join(parts, "; ")
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

	if err := p.updateHash(false); err != nil {
		return fmt.Errorf("failed to update DB hash after initialization: %w", err)
	}

	return nil
}

func (p *Persistence) replaceBucketData(bucketName string, data map[string]any) error {

	// Replace the entire bucket in an atomic transaction.
	var changed bool
	err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketName))
		if bucket == nil {
			return fmt.Errorf("%w: %s bucket not found", ErrNotFound, bucketName)
		}

		existing := make(map[string][]byte)
		err := bucket.ForEach(func(k, v []byte) error {
			existing[string(k)] = append([]byte(nil), v...)
			return nil
		})
		if err != nil {
			return err
		}

		for key, value := range data {
			marshaledValue, err := json.Marshal(value)
			if err != nil {
				return fmt.Errorf("failed to marshal value for key %s: %w", key, err)
			}
			if bytes.Equal(existing[key], marshaledValue) {
				delete(existing, key)
				continue
			}
			if err := bucket.Put([]byte(key), marshaledValue); err != nil {
				return fmt.Errorf("failed to put key %s: %w", key, err)
			}
			changed = true
			delete(existing, key)
		}

		for key := range existing {
			if err := bucket.Delete([]byte(key)); err != nil {
				return fmt.Errorf("failed to delete key %s: %w", key, err)
			}
			changed = true
		}
		return nil
	})

	if err != nil {
		return err
	}
	if !changed {
		return nil
	}
	return p.updateHash(false)
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

	meta := &model.DatabaseMetadata{
		Version:        versionInfoFromAPI(p.stateManager.GetVersion()),
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
			delay := p.nextSaveDelay()
			if timer == nil {
				logging.GetLogger().Debug("Active state flush scheduled in %s", delay)
				timer = time.NewTimer(delay)
				timerCh = timer.C
				continue
			}
			if !timer.Stop() {
				select {
				case <-timer.C:
				default:
				}
			}
			timer.Reset(delay)
			logging.GetLogger().Debug("Active state flush rescheduled in %s", delay)
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

func (p *Persistence) nextSaveDelay() time.Duration {
	p.mutex.RLock()
	defer p.mutex.RUnlock()

	delay := p.saveDebounce
	if p.minSaveGap <= 0 || p.lastSave.IsZero() {
		return delay
	}

	elapsed := time.Since(p.lastSave)
	if elapsed >= p.minSaveGap {
		return delay
	}

	waitForMinGap := p.minSaveGap - elapsed
	if waitForMinGap > delay {
		logging.GetLogger().Debug(
			"Active state save delayed to preserve flash: wait=%s debounce=%s min_gap=%s",
			waitForMinGap, delay, p.minSaveGap,
		)
		return waitForMinGap
	}
	return delay
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
	if update == nil || update.Metadata == nil {
		return fmt.Errorf("audio sync update missing metadata")
	}

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
				return p.SaveAudioMeta(update.Metadata)
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

	if err := p.SaveAudioMeta(update.Metadata); err != nil {
		return fmt.Errorf("SaveAudioMeta: %w", err)
	}

	return nil
}

func (p *Persistence) GetVersion() api.Version {
	return p.stateManager.GetVersion()
}

func (p *Persistence) maybeCompactOnOpen() error {
	freeBytes, ratio, err := p.compactionEstimate()
	if err != nil {
		return err
	}
	logging.GetLogger().Debug(
		"BoltDB compaction check: path=%s reclaimable=%d ratio=%.2f threshold_bytes=%d threshold_ratio=%.2f",
		p.dbPath, freeBytes, ratio, compactMinFreeBytes, compactMinFreeRatio,
	)
	if freeBytes < compactMinFreeBytes || ratio < compactMinFreeRatio {
		logging.GetLogger().Debug("BoltDB compaction skipped: path=%s below threshold", p.dbPath)
		return nil
	}

	logging.GetLogger().Info(
		"Compacting BoltDB on open: reclaimable=%d bytes ratio=%.2f path=%s",
		freeBytes, ratio, p.dbPath,
	)
	return p.compactAndReopen()
}

func (p *Persistence) compactionEstimate() (int64, float64, error) {
	info, err := os.Stat(p.dbPath)
	if err != nil {
		return 0, 0, fmt.Errorf("stat %s: %w", p.dbPath, err)
	}
	size := info.Size()
	if size <= 0 {
		return 0, 0, nil
	}

	stats := p.db.Stats()
	freeBytes := int64(stats.FreeAlloc)
	return freeBytes, float64(freeBytes) / float64(size), nil
}

func (p *Persistence) compactAndReopen() error {
	tmpPath := p.dbPath + ".compact"
	_ = os.Remove(tmpPath)
	beforeInfo, _ := os.Stat(p.dbPath)

	if err := p.db.Close(); err != nil {
		return fmt.Errorf("close db before compact: %w", err)
	}

	src, err := bbolt.Open(p.dbPath, permPrivate, &bbolt.Options{
		Timeout:  boltOpenTimeout,
		ReadOnly: true,
	})
	if err != nil {
		_ = p.reopenPrimaryDB()
		return fmt.Errorf("open source db for compact: %w", err)
	}

	dst, err := bbolt.Open(tmpPath, permPrivate, p.dbOptions)
	if err != nil {
		_ = src.Close()
		_ = p.reopenPrimaryDB()
		return fmt.Errorf("open destination db for compact: %w", err)
	}

	compactErr := bbolt.Compact(dst, src, compactTxMaxSize)
	closeErr := dst.Close()
	srcCloseErr := src.Close()
	if compactErr != nil {
		_ = os.Remove(tmpPath)
		_ = p.reopenPrimaryDB()
		return fmt.Errorf("compact db: %w", compactErr)
	}
	if closeErr != nil {
		_ = os.Remove(tmpPath)
		_ = p.reopenPrimaryDB()
		return fmt.Errorf("close compacted db: %w", closeErr)
	}
	if srcCloseErr != nil {
		_ = os.Remove(tmpPath)
		_ = p.reopenPrimaryDB()
		return fmt.Errorf("close source db: %w", srcCloseErr)
	}

	if err := os.Rename(tmpPath, p.dbPath); err != nil {
		_ = os.Remove(tmpPath)
		_ = p.reopenPrimaryDB()
		return fmt.Errorf("replace compacted db: %w", err)
	}

	if err := p.reopenPrimaryDB(); err != nil {
		return err
	}

	afterInfo, err := os.Stat(p.dbPath)
	if err == nil && beforeInfo != nil {
		logging.GetLogger().Debug(
			"BoltDB compaction complete: path=%s before=%d after=%d reclaimed=%d",
			p.dbPath, beforeInfo.Size(), afterInfo.Size(), beforeInfo.Size()-afterInfo.Size(),
		)
	} else {
		logging.GetLogger().Debug("BoltDB compaction complete: path=%s", p.dbPath)
	}

	return nil
}

func (p *Persistence) reopenPrimaryDB() error {
	db, err := bbolt.Open(p.dbPath, permPrivate, p.dbOptions)
	if err != nil {
		return fmt.Errorf("reopen db after compact: %w", err)
	}
	p.db = db
	return nil
}
