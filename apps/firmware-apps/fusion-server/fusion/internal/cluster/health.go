package cluster

import (
	"time"

	"fusion/internal/config"
	"fusion/internal/logging"

	"github.com/hashicorp/memberlist"
)

// StartHealthCheck starts monitoring cluster health
func StartHealthCheck(list *memberlist.Memberlist, nodeName string) {
	go func() {
		for {
			members := list.Members()
			numMembers := len(members)
			numAlive := 0

			for _, member := range members {
				if member.State == memberlist.StateAlive {
					numAlive++
				} else {
					logging.GetLogger(nodeName).Info("Node %s is not alive: state=%d",
						member.Name, member.State)
				}
			}

			logging.GetLogger(nodeName).Info("[HEALTH] Cluster health: %d/%d nodes alive",
				numAlive, numMembers)

			time.Sleep(10 * time.Second)
		}
	}()
}

// StartStateVerification starts periodic state verification
func StartStateVerification(list *memberlist.Memberlist, stateManager *config.StateManager, nodeName string) {
	go func() {
		for {
			hash := stateManager.VerifyState()
			logging.GetLogger(nodeName).Info("[STATE] Local state hash: %s", hash)

			// TODO: Implement cross-node state verification
			// This could involve making requests to other nodes
			// to compare state hashes

			time.Sleep(30 * time.Second)
		}
	}()
}
