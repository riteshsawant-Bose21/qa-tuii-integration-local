package cluster

import (
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/config"
	"fusion/internal/logging"
)

type GossipDelegate struct {
	nodeID       string
	stateManager *config.StateManager
	persistence  *config.ConfigPersistence
	verbose      bool
}

func NewGossipDelegate(nodeID string, stateManager *config.StateManager, persistence *config.ConfigPersistence, verbose bool) *GossipDelegate {
	return &GossipDelegate{
		nodeID:       nodeID,
		stateManager: stateManager,
		persistence:  persistence,
		verbose:      verbose,
	}
}

func (d *GossipDelegate) NodeMeta(limit int) []byte {
	meta := struct {
		NodeID  string `json:"node_id"`
		Version int64  `json:"version"`
	}{
		NodeID:  d.nodeID,
		Version: d.stateManager.GetVersion(),
	}
	data, err := json.Marshal(meta)
	if err != nil {
		logging.GetLogger(d.nodeID).Error("Error marshaling metadata: %v", err)
		return []byte{}
	}
	if len(data) > limit {
		return data[:limit]
	}
	return data
}

func (d *GossipDelegate) NotifyMsg(msg []byte) {
	if len(msg) == 0 {
		return
	}

	var update api.ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		logging.GetLogger(d.nodeID).Error("Error unmarshaling update: %v", err)
		return
	}

	if err := d.stateManager.ApplyUpdate(update); err != nil {
		logging.GetLogger(d.nodeID).Error("Error applying update: %v", err)
		return
	}

	// Get the single key from the update map
	var updateKey string
	for k := range update.Data {
		updateKey = k
		break
	}

	if d.verbose {
		logging.GetLogger(d.nodeID).Debug("Applied update for key %s from node %s (version: %d)",
			updateKey, update.NodeID, update.Version)
	}
}

func (d *GossipDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *GossipDelegate) LocalState(join bool) []byte {

	if d.verbose {
		logging.GetLogger(d.nodeID).Debug("LocalState requested (join=%v)", join)
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
		logging.GetLogger(d.nodeID).Error("Error marshaling local state: %v", err)
		return nil
	}

	if d.verbose {
		logging.GetLogger(d.nodeID).Debug("Providing local state with %d entries (version: %d)",
			len(state), snapshot.Version)
	}
	return data
}

func (d *GossipDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	if d.verbose {
		logging.GetLogger(d.nodeID).Debug("MergeRemoteState called (join=%v, size=%d)", join, len(buf))
	}

	var snapshot struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}

	if err := json.Unmarshal(buf, &snapshot); err != nil {
		logging.GetLogger(d.nodeID).Error("Error unmarshaling remote state: %v", err)
		return
	}

	if d.verbose {
		logging.GetLogger(d.nodeID).Debug("Merging remote state from node %s with %d entries (version: %d)",
			snapshot.NodeID, len(snapshot.State), snapshot.Version)
	}
	d.stateManager.MergeRemoteState(snapshot.State, snapshot.NodeID)

	// Persist after merging remote state
	d.persistence.MarkDirty()
}
