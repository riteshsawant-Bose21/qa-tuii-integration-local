package cluster

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"

	"github.com/hashicorp/memberlist"
)

const (
	checkInterval = 10
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
			localHash := stateManager.VerifyState()
			logging.GetLogger().Info("[STATE] Local state hash: %s", localHash)

			members := list.Members()
			stateHashes := make(map[string]int)
			stateHashes[localHash] = 1

			// Query other nodes for their state hashes
			for _, member := range members {
				if member.State != memberlist.StateAlive || member.Name == list.LocalNode().Name {
					continue
				}

				url := fmt.Sprintf("http://%s%s/getValue", member.Addr.String(), api.HTTPPort)
				resp, err := http.Get(url)
				if err != nil {
					logging.GetLogger().Warn("Failed to get state from %s: %v", member.Name, err)
					continue
				}

				var remoteState map[string]*api.StateEntry
				if err := json.NewDecoder(resp.Body).Decode(&remoteState); err != nil {
					resp.Body.Close()
					logging.GetLogger().Warn("Failed to decode state from %s %s: %v", member.Name, url, err)
					body, _ := io.ReadAll(resp.Body)
					logging.GetLogger().Warn("     Response Body: %s", string(body))
					continue
				}
				resp.Body.Close()

				// Calculate remote state hash
				data, err := json.Marshal(remoteState)
				if err != nil {
					continue
				}
				remoteHash := fmt.Sprintf("%x", sha256.Sum256(data))
				stateHashes[remoteHash]++
			}

			// Log state consistency status
			if len(stateHashes) > 1 {
				logging.GetLogger().Warn("[STATE] Inconsistent state detected across cluster")
				for hash, count := range stateHashes {
					logging.GetLogger().Info("[STATE] Hash %s: %d nodes", hash[:8], count)
				}
			} else {
				logging.GetLogger().Info("[STATE] State consistent across cluster")
			}

			time.Sleep(30 * time.Second)
		}
	}()
}
