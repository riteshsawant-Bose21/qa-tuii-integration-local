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
)

var antiEntropyBuckets = []string{
	bucketSnapshots,
	bucketTasks,
	bucketSnapshotDefs,
	bucketSceneSets,
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
	mutex            sync.RWMutex
	notifierMu       sync.RWMutex
	save             saveState
	metadataNotifier func(*api.DatabaseMetadata)
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
		save: saveState{
			debounce:  debounceTime,
			triggerCh: make(chan struct{}, 1),
		},
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
	close(p.save.triggerCh)
	p.db.Close()
}

func (p *Persistence) SetMetadataNotifier(notifier func(*api.DatabaseMetadata)) {
	p.notifierMu.Lock()
	defer p.notifierMu.Unlock()
	p.metadataNotifier = notifier
}

// MarkDirty triggers a state save with debounce
func (p *Persistence) MarkDirty() {
	select {
	case p.save.triggerCh <- struct{}{}:
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

	p.save.lastRun = time.Now().UTC()

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

	snapshotDefsData, ok := importData[bucketSnapshotDefs]
	if ok {
		snapshotDefs, ok := snapshotDefsData.(map[string]any)
		if !ok {
			return fmt.Errorf("snapshot definitions data is not in the expected format")
		}

		if err := p.replaceBucketData(bucketSnapshotDefs, snapshotDefs); err != nil {
			return err
		}

		update = true
	}

	sceneSetsData, ok := importData[bucketSceneSets]
	if ok {
		sceneSets, ok := sceneSetsData.(map[string]any)
		if !ok {
			return fmt.Errorf("scene sets data is not in the expected format")
		}

		if err := p.replaceBucketData(bucketSceneSets, sceneSets); err != nil {
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
	if err := p.updateHash(false); err != nil {
		return fmt.Errorf("failed to update DB hash after import: %w", err)
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

	if bumpMetadataVersion {
		if err := p.updateHash(true); err != nil {
			return nil, err
		}
	} else {
		if err := p.updateHash(false); err != nil {
			return nil, err
		}
	}

	return ps, nil
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

// loadMetadata retrieves and unmarshals the api.DatabaseMetadata from the database.
func (p *Persistence) loadMetadata() (*api.DatabaseMetadata, error) {
	var dataCopy []byte
	err := p.db.View(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketFusion))
		if bucket == nil {
			return fmt.Errorf("metadata bucket not found")
		}
		data := bucket.Get([]byte(keyMetadata))
		if data == nil {
			return fmt.Errorf("metadata not found")
		}
		dataCopy = append([]byte(nil), data...)
		return nil
	})
	if err != nil {
		return nil, err
	}

	var metadata api.DatabaseMetadata
	if err := json.Unmarshal(dataCopy, &metadata); err != nil {
		return nil, err
	}
	// Ensure no string field aliases a temporary decode buffer.
	metadata.ActiveSnapshot = strings.Clone(metadata.ActiveSnapshot)
	metadata.Hash = strings.Clone(metadata.Hash)
	metadata.Version.NodeID = strings.Clone(metadata.Version.NodeID)

	return &metadata, nil
}

// saveMetadata saves the api.DatabaseMetadata into the metadata bucket.
func (p *Persistence) saveMetadata(meta *api.DatabaseMetadata) error {
	return p.saveMetadataWithNotify(meta, true)
}

func (p *Persistence) saveMetadataWithNotify(meta *api.DatabaseMetadata, notify bool) error {
	data, err := json.Marshal(meta)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	if err := p.db.Update(func(tx *bbolt.Tx) error {
		bucket := tx.Bucket([]byte(bucketFusion))
		if bucket == nil {
			return fmt.Errorf("metadata bucket not found")
		}
		return bucket.Put([]byte(keyMetadata), data)
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
	if metadata.Version.NodeID == "" {
		metadata.Version.NodeID = p.stateManager.GetVersion().NodeID
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

	metadata.Version = p.stateManager.NextVersionAfter(metadata.Version)
	metadata.Hash = newHash
	metadata.Valid = true

	return p.saveMetadataWithNotify(metadata, notify)
}

// computeHash computes a SHA-256 hash over all buckets and their key/value pairs.
func (p *Persistence) computeHash() (string, error) {
	hash := sha256.New()
	if err := p.db.View(func(tx *bbolt.Tx) error {
		for _, bucketName := range antiEntropyBuckets {
			b := tx.Bucket([]byte(bucketName))
			if b == nil {
				continue
			}

			hash.Write([]byte(bucketName))
			cursor := b.Cursor()
			for k, v := cursor.First(); k != nil; k, v = cursor.Next() {
				hash.Write(k)

				sanitized, err := sanitizeHashValue(bucketName, v)
				if err != nil {
					return err
				}
				hash.Write(sanitized)
			}
		}
		return nil
	}); err != nil {
		return "", err
	}

	return hex.EncodeToString(hash.Sum(nil)), nil
}

func sanitizeHashValue(bucketName string, value []byte) ([]byte, error) {
	switch bucketName {
	case bucketSnapshots:
		var state PersistentState
		if err := json.Unmarshal(value, &state); err != nil {
			return nil, fmt.Errorf("failed to unmarshal snapshot for hashing: %w", err)
		}
		state.Timestamp = time.Time{}
		sanitized, err := canonicaljson.Marshal(state)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal sanitized snapshot for hashing: %w", err)
		}
		return sanitized, nil
	case bucketTasks, bucketSnapshotDefs, bucketSceneSets:
		var normalized any
		if err := json.Unmarshal(value, &normalized); err != nil {
			return nil, fmt.Errorf("failed to unmarshal %s entry for hashing: %w", bucketName, err)
		}
		sanitized, err := canonicaljson.Marshal(normalized)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal canonical %s entry for hashing: %w", bucketName, err)
		}
		return sanitized, nil
	default:
		return value, nil
	}
}

func normalizeAntiEntropyValue(bucketName string, value any) (any, error) {
	switch bucketName {
	case bucketSnapshots:
		raw, err := json.Marshal(value)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal snapshot for normalization: %w", err)
		}
		var state PersistentState
		if err := json.Unmarshal(raw, &state); err != nil {
			return nil, fmt.Errorf("failed to unmarshal snapshot for normalization: %w", err)
		}
		state.Timestamp = time.Time{}
		return state, nil
	default:
		return value, nil
	}
}

func antiEntropyValueChecksum(bucketName string, value any) (string, error) {
	normalized, err := normalizeAntiEntropyValue(bucketName, value)
	if err != nil {
		return "", err
	}
	return utils.JSONChecksum(normalized)
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

	return p.db.Update(func(tx *bbolt.Tx) error {

		// Bail out if buckets exist
		if tx.Bucket([]byte(bucketActive)) != nil &&
			tx.Bucket([]byte(bucketAudio)) != nil &&
			tx.Bucket([]byte(bucketFusion)) != nil &&
			tx.Bucket([]byte(bucketDevice)) != nil &&
			tx.Bucket([]byte(bucketSceneSets)) != nil &&
			tx.Bucket([]byte(bucketSnapshotDefs)) != nil &&
			tx.Bucket([]byte(bucketTasks)) != nil &&
			tx.Bucket([]byte(bucketSnapshots)) != nil {
			return nil
		}

		// Otherwise create any missing buckets
		for _, bucket := range []string{
			bucketActive,
			bucketAudio,
			bucketDevice,
			bucketFusion,
			bucketSceneSets,
			bucketSnapshotDefs,
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
	if existing := bucket.Get([]byte(keyDefaultSnapshot)); existing != nil {
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
		Version:        p.stateManager.GetVersion(),
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

	for range p.save.triggerCh {
		mu.Lock()
		if timer != nil {
			timer.Reset(p.save.debounce)
			mu.Unlock()
			continue
		}

		timer = time.AfterFunc(p.save.debounce, func() {
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
