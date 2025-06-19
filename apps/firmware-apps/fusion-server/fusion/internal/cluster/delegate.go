package cluster

import (
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/server/handler"
	"fusion/internal/tasks"
	"math"
	"sync"
	"time"
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
	nodeID        string
	persistence   *persistence.Persistence
	stateManager  *persistence.StateManager
	taskManager   *tasks.TaskManager
	updater       *handler.Updater
	syncLatencies *SyncLatencyStore
	skewStore     *SkewStore
}

func NewClusterDelegate(nodeID string, persistence *persistence.Persistence, stateManager *persistence.StateManager, taskManager *tasks.TaskManager, updater *handler.Updater) *ClusterDelegate {
	delegate := &ClusterDelegate{
		nodeID:        nodeID,
		persistence:   persistence,
		stateManager:  stateManager,
		taskManager:   taskManager,
		updater:       updater,
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
		NodeID:  d.nodeID,
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
			Receiver:  d.nodeID,
			Operation: string(message.Operation),
			Latency:   latencyMs,
			Timestamp: time.Now(),
		})
	}

	switch message.Operation {

	case api.NotifyOpConfigUpdate:
		if err := d.stateManager.ApplyUpdate(*message.ConfigUpdate); err != nil {
			logger.Error("Error applying update: %v", err)
			return
		}

	case api.NotifyOpSnapActivate:
		if err := d.persistence.ActivateSnapshot(message.SnapshotUpdate.Name); err != nil {
			logger.Error("Error activating snapshot: %v", err)
		}

	case api.NotifyOpSnapCreate:
		if err := d.persistence.CreateSnapshot(message.SnapshotUpdate.Name); err != nil {
			logger.Error("Error creating snapshot: %v", err)
		}

	case api.NotifyOpSnapDelete:
		if err := d.persistence.DeleteSnapshot(message.SnapshotUpdate.Name); err != nil {
			logger.Error("Error deleting snapshot: %v", err)
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

	case api.NotifyOpVersionUpdate:
		if err := d.updater.PerformRemoteUpdate(*message.VersionMessage); err != nil {
			logger.Error("PerformRemoteUpdate error: %v", err)
		}

	default:
		logger.Error("Unknown message type: %q", message.Operation)
	}
}

func (d *ClusterDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *ClusterDelegate) LocalState(join bool) []byte {

	logger := logging.GetLogger()
	logger.Debug("LocalState requested (join=%v)", join)

	state := d.stateManager.GetFullState()
	snapshot := struct {
		Version api.Version                `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}{
		Version: d.stateManager.GetVersion(),
		NodeID:  d.nodeID,
		State:   state.State,
	}

	data, err := json.Marshal(snapshot)
	if err != nil {
		logger.Error("Error marshaling local state: %v", err)
		return nil
	}

	logger.Debug("Providing local state with %d entries (version: %v)",
		len(state.State), snapshot.Version)

	return data
}

func (d *ClusterDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	logger := logging.GetLogger()
	logger.Debug("MergeRemoteState called (join=%v, size=%d)", join, len(buf))

	var snapshot api.RemoteStateSnapshot
	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logger.Error("Error unmarshaling remote state: %v", err)
		return
	}

	logger.Debug("Merging remote state from node %s with %d entries (version: %v)",
		snapshot.NodeID, len(snapshot.State), snapshot.Version)
	d.stateManager.MergeRemoteState(snapshot.State)

	d.persistence.MarkDirty()
}

func (d *ClusterDelegate) startSkewPruner() {

	go func() {
		ticker := time.NewTicker(skewPruneInterval)
		defer ticker.Stop()
		d.skewStore.Prune(ticker, skewPruneAge)
	}()
}
