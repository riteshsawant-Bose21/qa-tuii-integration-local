package cluster

import (
	"time"

	"fusion/internal/logging"
	"fusion/internal/server"

	"github.com/hashicorp/memberlist"
)

const (
	checkInterval = 30
)

// StartHealthCheck starts monitoring cluster health
func StartHealthCheck(list *memberlist.Memberlist) {
	go func() {
		for {
			members := list.Members()
			numMembers := len(members)
			numAlive := 0

			for _, member := range members {
				if member.State == memberlist.StateAlive {
					numAlive++
				} else {
					logging.GetLogger().Info("Node %s is not alive: state=%d",
						member.Name, member.State)
				}
			}

			logging.GetLogger().Info("[HEALTH] Cluster health: %d/%d nodes alive",
				numAlive, numMembers)

			time.Sleep(checkInterval * time.Second)
		}
	}()
}

// StartStateVerification starts periodic state verification
func StartStateVerification(list *memberlist.Memberlist, stateManager *server.StateManager) {
	go func() {

		for {
			stateManager.ValidateMemberState(list)
			server.ValidateSnapshots(list)
			time.Sleep(checkInterval * time.Second)
		}

	}()
}
