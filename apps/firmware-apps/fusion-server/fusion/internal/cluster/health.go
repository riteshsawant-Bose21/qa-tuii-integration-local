package cluster

import (
	"log"
	"time"

	"fusion/internal/config"

	"github.com/hashicorp/memberlist"
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
					log.Printf("Node %s is not alive: state=%d",
						member.Name, member.State)
				}
			}

			log.Printf("[HEALTH] Cluster health: %d/%d nodes alive",
				numAlive, numMembers)

			time.Sleep(10 * time.Second)
		}
	}()
}

// StartStateVerification starts periodic state verification
func StartStateVerification(list *memberlist.Memberlist, stateManager *config.StateManager) {
	go func() {
		for {
			hash := stateManager.VerifyState()
			log.Printf("[STATE] Local state hash: %s", hash)

			// TODO: Implement cross-node state verification
			// This could involve making HTTP requests to other nodes
			// to compare state hashes

			time.Sleep(30 * time.Second)
		}
	}()
}
