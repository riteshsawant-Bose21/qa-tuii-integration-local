package cluster

import (
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/config"
	"log"
	"os"
)

type GossipDelegate struct {
	logger       *log.Logger
	nodeID       string
	stateManager *config.StateManager
	verbose      bool
}

func NewGossipDelegate(nodeID string, stateManager *config.StateManager, verbose bool) *GossipDelegate {
	return &GossipDelegate{
		logger:       log.New(os.Stdout, "[GOSSIP-"+nodeID+"] ", log.LstdFlags),
		nodeID:       nodeID,
		stateManager: stateManager,
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
		d.logger.Printf("Error marshaling metadata: %v", err)
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
		d.logger.Printf("Error unmarshaling update: %v", err)
		return
	}

	if err := d.stateManager.ApplyUpdate(update); err != nil {
		d.logger.Printf("Error applying update: %v", err)
		return
	}

	// Get the single key from the update map
	var updateKey string
	for k := range update.Update {
		updateKey = k
		break
	}

	if d.verbose {
		d.logger.Printf("Applied update for key %s from node %s (version: %d)",
			updateKey, update.NodeID, update.Version)
	}
}

func (d *GossipDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *GossipDelegate) LocalState(join bool) []byte {

	if d.verbose {
		d.logger.Printf("LocalState requested (join=%v)", join)
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
		d.logger.Printf("Error marshaling local state: %v", err)
		return nil
	}

	if d.verbose {
		d.logger.Printf("Providing local state with %d entries (version: %d)",
			len(state), snapshot.Version)
	}
	return data
}

func (d *GossipDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	if d.verbose {
		d.logger.Printf("MergeRemoteState called (join=%v, size=%d)", join, len(buf))
	}

	var snapshot struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}

	if err := json.Unmarshal(buf, &snapshot); err != nil {
		d.logger.Printf("Error unmarshaling remote state: %v", err)
		return
	}

	if d.verbose {
		d.logger.Printf("Merging remote state from node %s with %d entries (version: %d)",
			snapshot.NodeID, len(snapshot.State), snapshot.Version)
	}
	d.stateManager.MergeRemoteState(snapshot.State, snapshot.NodeID)
}
