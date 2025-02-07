package cluster

import (
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
)

type ClusterDelegate struct {
	nodeID       string
	stateManager *server.StateManager
	persistence  *server.ConfigPersistence
	updater      *server.Updater
	verbose      bool
}

func NewClusterDelegate(nodeID string, stateManager *server.StateManager, persistence *server.ConfigPersistence, updater *server.Updater, verbose bool) *ClusterDelegate {
	return &ClusterDelegate{
		nodeID:       nodeID,
		stateManager: stateManager,
		persistence:  persistence,
		updater:      updater,
		verbose:      verbose,
	}
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

	// Try to decode as binary message first
	var binaryMsg server.VersionMessage
	if err := json.Unmarshal(msg, &binaryMsg); err == nil {
		if err = d.updater.PerformRemoteUpdate(binaryMsg); err != nil {
			logger.Error("PerformRemoteUpdate error: %v", err)
			return
		}
		// Ignore error at this level so we can check for api.ConfigUpdate
	}

	// Handle the config update next
	var update api.ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		logger.Error("Error unmarshaling update: %v", err)
		return
	}

	if err := d.stateManager.ApplyUpdate(update); err != nil {
		logger.Error("Error applying update: %v", err)
		return
	}

	// Get the single key from the update map
	var updateKey string
	for k := range update.Data {
		updateKey = k
		break
	}

	if d.verbose {
		logger.Debug("Applied update for key %s from node %s (version: %d)",
			updateKey, update.NodeID, update.Version)
	}
}

func (d *ClusterDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *ClusterDelegate) LocalState(join bool) []byte {

	logger := logging.GetLogger()

	if d.verbose {
		logger.Debug("LocalState requested (join=%v)", join)
	}

	state := d.stateManager.GetFullState()
	snapshot := struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}{
		Version: d.stateManager.GetVersion(),
		NodeID:  d.nodeID,
		State:   state,
	}

	data, err := json.Marshal(snapshot)
	if err != nil {
		logger.Error("Error marshaling local state: %v", err)
		return nil
	}

	if d.verbose {
		logger.Debug("Providing local state with %d entries (version: %d)",
			len(state), snapshot.Version)
	}
	return data
}

func (d *ClusterDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	logger := logging.GetLogger()

	if d.verbose {
		logger.Debug("MergeRemoteState called (join=%v, size=%d)", join, len(buf))
	}

	var snapshot struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}

	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logger.Error("Error unmarshaling remote state: %v", err)
		return
	}

	if d.verbose {
		logger.Debug("Merging remote state from node %s with %d entries (version: %d)",
			snapshot.NodeID, len(snapshot.State), snapshot.Version)
	}
	d.stateManager.MergeRemoteState(snapshot.State, snapshot.NodeID)

	// Persist after merging remote state
	d.persistence.MarkDirty()
}
