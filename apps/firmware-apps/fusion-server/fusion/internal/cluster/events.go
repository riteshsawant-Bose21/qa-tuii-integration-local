package cluster

import (
	"fusion/internal/logging"

	"github.com/hashicorp/memberlist"
)

// ClusterEventDelegate implements memberlist.EventDelegate to log gossip membership changes.
type ClusterEventDelegate struct {
}

// NotifyJoin is invoked when a node joins the cluster.
func (e *ClusterEventDelegate) NotifyJoin(n *memberlist.Node) {
	logger := logging.GetLogger()
	logger.Info("[GOSSIP] NotifyJoin: addr=%s:%d",
		n.Addr.String(), n.Port)
}

// NotifyLeave is invoked when a node leaves the cluster.
func (e *ClusterEventDelegate) NotifyLeave(n *memberlist.Node) {
	logger := logging.GetLogger()
	logger.Info("[GOSSIP] NotifyLeave: addr=%s:%d",
		n.Addr.String(), n.Port)
}

// NotifyAlive is invoked when a node is detected as alive (heartbeat/suspect cleared).
func (e *ClusterEventDelegate) NotifyAlive(n *memberlist.Node) error {
	logger := logging.GetLogger()
	logger.Info("[GOSSIP] NotifyAlive: addr=%s:%d",
		n.Addr.String(), n.Port)
	return nil
}

// NotifyUpdate is invoked when a node is updated (e.g., metadata changes).
func (e *ClusterEventDelegate) NotifyUpdate(n *memberlist.Node) {
	logger := logging.GetLogger()
	logger.Info("[GOSSIP] NotifyUpdate: addr=%s:%d",
		n.Addr.String(), n.Port)
}
