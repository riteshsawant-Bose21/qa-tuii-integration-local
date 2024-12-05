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
	verbose      bool
}

func NewClusterDelegate(nodeID string, stateManager *server.StateManager, persistence *server.ConfigPersistence, verbose bool) *ClusterDelegate {
	return &ClusterDelegate{
		nodeID:       nodeID,
		stateManager: stateManager,
		persistence:  persistence,
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

	var update api.ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		logging.GetLogger().Error("Error unmarshaling update: %v", err)
		return
	}

	if err := d.stateManager.ApplyUpdate(update); err != nil {
		logging.GetLogger().Error("Error applying update: %v", err)
		return
	}

	// Get the single key from the update map
	var updateKey string
	for k := range update.Data {
		updateKey = k
		break
	}

	if d.verbose {
		logging.GetLogger().Debug("Applied update for key %s from node %s (version: %d)",
			updateKey, update.NodeID, update.Version)
	}
}

func (d *ClusterDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *ClusterDelegate) LocalState(join bool) []byte {

	if d.verbose {
		logging.GetLogger().Debug("LocalState requested (join=%v)", join)
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
		logging.GetLogger().Error("Error marshaling local state: %v", err)
		return nil
	}

	if d.verbose {
		logging.GetLogger().Debug("Providing local state with %d entries (version: %d)",
			len(state), snapshot.Version)
	}
	return data
}

func (d *ClusterDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	if d.verbose {
		logging.GetLogger().Debug("MergeRemoteState called (join=%v, size=%d)", join, len(buf))
	}

	var snapshot struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}

	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logging.GetLogger().Error("Error unmarshaling remote state: %v", err)
		return
	}

	if d.verbose {
		logging.GetLogger().Debug("Merging remote state from node %s with %d entries (version: %d)",
			snapshot.NodeID, len(snapshot.State), snapshot.Version)
	}
	d.stateManager.MergeRemoteState(snapshot.State, snapshot.NodeID)

	// Persist after merging remote state
	d.persistence.MarkDirty()
}
