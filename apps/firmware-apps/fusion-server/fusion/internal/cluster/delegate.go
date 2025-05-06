package cluster

import (
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
	"math"
	"sync"
	"time"
)

const (
	latencyPruneTime  = 5 * time.Minute
	maxLatencyCount   = 1000
	skewPruneInterval = 1 * time.Minute
	skewPruneAge      = 10 * time.Minute
	skewTime          = 500 * time.Millisecond
)

type SkewEntry struct {
	Skew     time.Duration
	Detected time.Time
}

// SkewEntry holds time skew values
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
	nodeID           string
	persistence      *server.Persistence
	stateManager     *server.StateManager
	taskManager      *server.TaskManager
	updater          *server.Updater
	networkLatencies *NetworkLatencyStore
	syncLatencies    *SyncLatencyStore
	skewStore        *SkewStore
}

func NewClusterDelegate(nodeID string, persistence *server.Persistence, stateManager *server.StateManager, taskManager *server.TaskManager, updater *server.Updater) *ClusterDelegate {
	delegate := &ClusterDelegate{
		nodeID:           nodeID,
		persistence:      persistence,
		stateManager:     stateManager,
		taskManager:      taskManager,
		updater:          updater,
		networkLatencies: NewNetworkLatencyStore(maxLatencyCount, latencyPruneTime),
		syncLatencies:    NewSyncLatencyStore(maxLatencyCount, latencyPruneTime),
		skewStore:        NewSkewStore(),
	}

	delegate.startSkewPruner()

	return delegate
}

func (d *ClusterDelegate) NodeMeta(limit int) []byte {
	meta := struct {
		NodeID  string `json:"node_id"`
		Version int64  `json:"version"`
	}{
		NodeID:  d.nodeID,
		Version: d.stateManager.GetVersion(),
	}
	data, err := json.Marshal(meta)
	if err != nil {
		logging.GetLogger().Error("Error marshaling metadata: %v", err)
		return []byte{}
	}
	if len(data) > limit {
		return data[:limit]
	}
	return data
}

func (d *ClusterDelegate) NotifyMsg(msg []byte) {
	if len(msg) == 0 {
		return
	}

	logger := logging.GetLogger()

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
		if err := d.taskManager.AddTask(message.Task, func() {}); err != nil {
			logger.Error("Error creating task: %v", err)
		}

	case api.NotifyOpTaskDelete:
		if err := d.taskManager.RemoveTask(message.Task.ID); err != nil {
			logger.Error("Error deleting task: %v", err)
		}

	case api.NotifyOpTaskUpdate:
		if err := d.taskManager.RemoveTask(message.Task.ID); err != nil {
			logger.Error("Error deleting task: %v", err)
		}

	case api.NotifyOpVersionUpdate:
		if err := d.updater.PerformRemoteUpdate(*message.VersionMessage); err != nil {
			logger.Error("PerformRemoteUpdate error: %v", err)
		}

	default:
		logger.Error("Unknown message type")
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
		Version int64                      `json:"version"`
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

	logger.Debug("Providing local state with %d entries (version: %d)",
		len(state.State), snapshot.Version)

	return data
}

func (d *ClusterDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	logger := logging.GetLogger()
	logger.Debug("MergeRemoteState called (join=%v, size=%d)", join, len(buf))

	var snapshot struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}

	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logger.Error("Error unmarshaling remote state: %v", err)
		return
	}

	logger.Debug("Merging remote state from node %s with %d entries (version: %d)",
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
