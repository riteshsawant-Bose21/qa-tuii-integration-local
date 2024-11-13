package cluster

import (
	"encoding/json"
	"fusion/internal/api"
	"fusion/internal/config"
	"log"
	"os"
)

// GossipDelegate implements the memberlist.Delegate interface
type GossipDelegate struct {
	logger       *log.Logger
	nodeID       string
	stateManager *config.StateManager
}

// NewGossipDelegate creates a new delegate instance
func NewGossipDelegate(nodeID string, stateManager *config.StateManager) *GossipDelegate {
	return &GossipDelegate{
		logger:       log.New(os.Stdout, "[GOSSIP-"+nodeID+"] ", log.LstdFlags),
		nodeID:       nodeID,
		stateManager: stateManager,
	}
}

// NodeMeta returns metadata about the current node
func (d *GossipDelegate) NodeMeta(limit int) []byte {
	// Include version in metadata to help detect out-of-sync nodes
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

// NotifyMsg handles incoming messages from other nodes
func (d *GossipDelegate) NotifyMsg(msg []byte) {
	if len(msg) == 0 {
		return
	}

	var update api.ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		d.logger.Printf("Error unmarshaling update: %v", err)
		return
	}

	// Apply the update to local state
	if err := d.stateManager.ApplyUpdate(update); err != nil {
		d.logger.Printf("Error applying update: %v", err)
		return
	}

	d.logger.Printf("Applied update for key %s from node %s (version: %d)",
		update.Key, update.NodeID, update.Version)
}

// GetBroadcasts is called when asked for broadcast messages
func (d *GossipDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	// We're using SendReliable for updates instead of broadcasts
	return nil
}

// LocalState is called when asked for the local state
func (d *GossipDelegate) LocalState(join bool) []byte {
	d.logger.Printf("LocalState requested (join=%v)", join)

	// Get the full state
	state := d.stateManager.GetFullState()

	// Create a state snapshot
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

	d.logger.Printf("Providing local state with %d entries (version: %d)",
		len(state), snapshot.Version)
	return data
}

// MergeRemoteState is called when a remote state is received
func (d *GossipDelegate) MergeRemoteState(buf []byte, join bool) {
	if len(buf) == 0 {
		return
	}

	d.logger.Printf("MergeRemoteState called (join=%v, size=%d)", join, len(buf))

	var snapshot struct {
		Version int64                      `json:"version"`
		NodeID  string                     `json:"node_id"`
		State   map[string]*api.StateEntry `json:"state"`
	}

	if err := json.Unmarshal(buf, &snapshot); err != nil {
		d.logger.Printf("Error unmarshaling remote state: %v", err)
		return
	}

	d.logger.Printf("Merging remote state from node %s with %d entries (version: %d)",
		snapshot.NodeID, len(snapshot.State), snapshot.Version)

	// Merge the remote state
	d.stateManager.MergeRemoteState(snapshot.State, snapshot.NodeID)
}
