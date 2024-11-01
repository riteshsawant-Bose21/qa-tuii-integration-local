package cluster

import (
	"encoding/json"
	"log"
	"os"

	"fusion/internal/api"
)

// GossipDelegate implements the memberlist.Delegate interface
type GossipDelegate struct {
	logger  *log.Logger
	nodeID  string
	updates chan<- api.ConfigUpdate
}

// NewGossipDelegate creates a new delegate instance
func NewGossipDelegate(nodeID string) *GossipDelegate {
	return &GossipDelegate{
		logger: log.New(os.Stdout, "[GOSSIP-"+nodeID+"] ", log.LstdFlags),
		nodeID: nodeID,
	}
}

// NodeMeta returns metadata about the current node
func (d *GossipDelegate) NodeMeta(limit int) []byte {
	return []byte{}
}

// NotifyMsg handles incoming messages from other nodes
func (d *GossipDelegate) NotifyMsg(msg []byte) {
	var update api.ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		d.logger.Printf("Error unmarshaling update: %v", err)
		return
	}

	if d.updates != nil {
		d.updates <- update
	}
}

// GetBroadcasts is called when asked for broadcast messages
func (d *GossipDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

// LocalState is called when asked for the local state
func (d *GossipDelegate) LocalState(join bool) []byte {
	d.logger.Printf("LocalState requested (join=%v)", join)
	return nil
}

// MergeRemoteState is called when a remote state is received
func (d *GossipDelegate) MergeRemoteState(buf []byte, join bool) {
	d.logger.Printf("MergeRemoteState called (join=%v, size=%d)", join, len(buf))
}
