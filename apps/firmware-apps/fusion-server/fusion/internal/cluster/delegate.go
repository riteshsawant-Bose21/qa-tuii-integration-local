package cluster

import (
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
	"fusion/internal/tasks"
	"math"
	"sync"
	"time"

	json "github.com/goccy/go-json"
)

const (
	maxLatencyCount   = 1000
	skewPruneInterval = 1 * time.Minute
	skewPruneAge      = 10 * time.Minute
	skewTime          = 500 * time.Millisecond
)

type SkewEntry struct {
	Skew     time.Duration
	Detected time.Time
}

// SkewStore holds time skew values detected from incoming messages
type SkewStore struct {
	mu        sync.RWMutex
	timeSkews map[string]*SkewEntry
}

func NewSkewStore() *SkewStore {
	return &SkewStore{
		timeSkews: make(map[string]*SkewEntry),
	}
}

// Add inserts a new record and updates rolling stats.
func (s *SkewStore) Add(node string, skew time.Duration, detected time.Time) {
	s.mu.Lock()
	s.timeSkews[node] = &SkewEntry{
		Skew:     skew,
		Detected: detected,
	}
	s.mu.Unlock()
}

// Prune removes stale records from the store.
func (s *SkewStore) Prune(ticker *time.Ticker, maxAge time.Duration) {
	for range ticker.C {
		now := time.Now()
		s.mu.Lock()
		for node, entry := range s.timeSkews {
			if now.Sub(entry.Detected) > maxAge {
				delete(s.timeSkews, node)
			}
		}
		s.mu.Unlock()
	}
}

type ClusterDelegate struct {
	appConfig     *api.AppConfig
	persistence   *persistence.Persistence
	stateManager  *persistence.StateManager
	taskManager   *tasks.TaskManager
	syncLatencies *SyncLatencyStore
	skewStore     *SkewStore
	hub           *pubsub.Hub
}

func NewClusterDelegate(
	config *api.AppConfig,
	persistence *persistence.Persistence,
	stateManager *persistence.StateManager,
	taskManager *tasks.TaskManager,
	hub *pubsub.Hub) *ClusterDelegate {
	delegate := &ClusterDelegate{
		appConfig:     config,
		persistence:   persistence,
		stateManager:  stateManager,
		taskManager:   taskManager,
		hub:           hub,
		syncLatencies: NewSyncLatencyStore(maxLatencyCount, latencyPruneTime),
		skewStore:     NewSkewStore(),
	}

	delegate.startSkewPruner()

	return delegate
}

func (d *ClusterDelegate) NodeMeta(limit int) []byte {

	version := d.stateManager.GetVersion()

	meta := struct {
		NodeID  string      `json:"node_id"`
		Version api.Version `json:"version"`
	}{
		NodeID:  d.appConfig.NodeName,
		Version: version,
	}

	data, err := json.Marshal(meta)
	if err != nil {
		logging.GetLogger().Error("Error marshaling metadata: %v", err)
		return nil
	}

	if len(data) > limit {
		logging.GetLogger().Warn("NodeMeta (%d bytes) exceeds limit (%d), dropping metadata", len(data), limit)
		return nil
	}

	return data
}

func (d *ClusterDelegate) NotifyMsg(msg []byte) {

	logger := logging.GetLogger()

	if len(msg) == 0 {
		logger.Warn("Received empty message")
		return
	}

	var message api.NotifyMessage
	if err := json.Unmarshal(msg, &message); err != nil {
		logger.Error("Error unmarshaling message: %v", err)
		return
	}

	now := time.Now().UTC()

	if !message.SentAt.IsZero() {

		// Detect clock skew
		if message.SentAt.After(now.Add(skewTime)) {
			skew := message.SentAt.Sub(now)
			d.skewStore.Add(message.Node, skew, now)
			logger.Warn("Clock skew detected: message from %s is %v ahead", message.Node, skew)
		}

		// Calculate latency, clamped to zero
		latency := max(now.Sub(message.SentAt), 0)
		latencyMs := float64(latency.Nanoseconds()) / 1e6
		latencyMs = math.Round(latencyMs*100) / 100

		d.syncLatencies.Add(SyncLatency{
			Sender:    message.Node,
			Receiver:  d.appConfig.NodeName,
			Operation: string(message.Operation),
			Latency:   latencyMs,
			Timestamp: time.Now(),
		})
	}

	switch message.Operation {

	case api.NotifyOpAudioRemove:
		if message.AudioRemove == nil {
			logger.Error("AudioRemove message with nil payload from %s", message.Node)
			return
		}
		if err := d.handleAudioRemove(message.AudioRemove); err != nil {
			logger.Error("Error handling audio remove from %s: %v", message.Node, err)
		}

	case api.NotifyOpAudioSync:
		if message.AudioSync == nil {
			logger.Error("AudioSync message with nil payload from %s", message.Node)
			return
		}
		if err := d.handleAudioSync(message.AudioSync); err != nil {
			logger.Error("Error handling audio sync from %s: %v", message.Node, err)
		}

	case api.NotifyOpConfigUpdate:
		dirty, err := d.stateManager.ApplyUpdate(*message.ConfigUpdate)
		if err != nil {
			logger.Error("Error applying update: %v", err)
			return
		}

		if !dirty {
			logger.Debug("[Delegate] Skipping stale ConfigUpdate version=%v from %s",
				message.ConfigUpdate.Version, message.Node)
			return
		}

		// Overwrite with effective local Lamport version
		updated := *message.ConfigUpdate
		updated.Version = d.stateManager.GetVersion()
		logger.Debug("[Delegate] NotifyOpConfigUpdate setting Version: %d", updated.Version.Counter)
		message.ConfigUpdate = &updated

		d.persistence.MarkDirty()
		d.hub.BroadcastToObservers(&message)

	case api.NotifyOpSnapActivate:
		if message.SnapshotOperation == nil {
			logger.Error("SnapActivate message with nil payload from %s", message.Node)
			return
		}

		logger.Info("[Delegate] SnapActivate on %s for %s (from=%s)",
			d.appConfig.NodeName,
			message.SnapshotOperation.Name,
			message.Node,
		)

		if err := d.persistence.ActivateSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error activating snapshot: %v", err)
		}

	case api.NotifyOpSnapCreate:
		if err := d.persistence.CreateSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error creating snapshot: %v", err)
		}

	case api.NotifyOpSnapDelete:
		if err := d.persistence.DeleteSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error deleting snapshot: %v", err)
		}

	case api.NotifyOpSnapSave:
		if err := d.persistence.SaveSnapshot(message.SnapshotOperation.Name); err != nil {
			logger.Error("Error saving snapshot: %v", err)
		}

	case api.NotifyOpTaskCreate:
		if err := d.taskManager.AddTask(message.Task); err != nil {
			logger.Error("Error creating task: %v", err)
		}

	case api.NotifyOpTaskDelete:
		if err := d.taskManager.RemoveTask(message.Task.ID); err != nil {
			logger.Error("Error deleting task: %v", err)
		}

	case api.NotifyOpTaskUpdate:
		if err := d.taskManager.UpdateTaskFromCluster(message.Task); err != nil {
			logger.Error("Error updating task: %v", err)
		}

	case api.NotifyOpDeviceUpdate:
		d.handleDeviceUpdate(&message)

	default:
		logger.Error("Unknown message type: %q", message.Operation)
	}
}

func (d *ClusterDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

// handleDeviceUpdate processes device update notifications
func (d *ClusterDelegate) handleDeviceUpdate(message *api.NotifyMessage) {
	logger := logging.GetLogger()

	if message.DeviceUpdate == nil {
		logger.Error("DeviceUpdate message with nil payload from %s", message.Node)
		return
	}

	logger.Info("[DeviceUpdate] Received device update from %s for device %s",
		message.Node, message.DeviceUpdate.DeviceID)

	d.hub.BroadcastToObservers(message)
}

func (d *ClusterDelegate) LocalState(join bool) []byte {

	logger := logging.GetLogger()
	logger.Debug("[DELEGATE] LocalState requested (join=%v)", join)

	state := d.stateManager.GetFullState()
	snapshot := struct {
		Version api.Version                `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}{
		Version: d.stateManager.GetVersion(),
		NodeID:  d.appConfig.NodeName,
		State:   state.State,
	}

	data, err := json.Marshal(snapshot)
	if err != nil {
		logger.Error("Error marshaling local state: %v", err)
		return nil
	}

	logger.Debug("Providing local state with %d entries (version: %v)",
		len(state.State), snapshot.Version)

	if join {
		logger.Debug("[DELEGATE] LocalState provided with join true, size=%d", len(data))
	}
	return data
}

// MergeRemoteState merges remote state data
func (d *ClusterDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	logger := logging.GetLogger()
	logger.Debug("[DELEGATE] MergeRemoteState called (join=%v, size=%d)", join, len(buf))

	var snapshot api.RemoteStateSnapshot
	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logger.Error("[DELEGATE] Error unmarshaling remote state: %v", err)
		return
	}

	logger.Debug("[DELEGATE] Merging remote state from node %s with %d entries (version: %v)",
		snapshot.NodeID, len(snapshot.State), snapshot.Version)

	localVersion := d.stateManager.GetVersion()
	remoteVersion := snapshot.Version

	// Reject older epoch outright
	if remoteVersion.Epoch < localVersion.Epoch {
		logger.Debug("[DELEGATE] Ignoring remote state from older epoch %d (local=%d)", remoteVersion.Epoch, localVersion.Epoch)
		return
	}

	// Adopt newer epoch as authoritative
	if remoteVersion.Epoch > localVersion.Epoch {
		logger.Debug("[DELEGATE] Adopting newer epoch %d (local=%d)", remoteVersion.Epoch, localVersion.Epoch)
		d.stateManager.ReplaceFullState(snapshot.State, remoteVersion)
		d.persistence.MarkDirty()
		return
	}

	// Same epoch, do normal merge
	d.stateManager.MergeRemoteState(snapshot.State)

	d.persistence.MarkDirty()

	if join {
		logger.Debug("[DELEGATE] MergeRemoteState completed during join")
	}
}

func (d *ClusterDelegate) handleAudioRemove(update *api.AudioRemoveUpdate) error {
	return d.persistence.RemoveAudioFile(update.ID)
}

func (d *ClusterDelegate) handleAudioSync(update *api.AudioSyncUpdate) error {
	return d.persistence.SyncAudioFile(update)
}

func (d *ClusterDelegate) startSkewPruner() {

	go func() {
		ticker := time.NewTicker(skewPruneInterval)
		defer ticker.Stop()
		d.skewStore.Prune(ticker, skewPruneAge)
	}()
}
