package cluster

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"reflect"
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

		logger := logging.GetLogger()

		for {
			localState := stateManager.GetState()
			consistent := true
			members := list.Members()

			// Query other nodes for their state objects
			for _, member := range members {
				if member.State != memberlist.StateAlive || member.Name == list.LocalNode().Name {
					continue
				}

				url := fmt.Sprintf("http://%s%s/dump", member.Addr.String(), api.HTTPPort)
				resp, err := http.Get(url)
				if err != nil {
					logger.Warn("Failed to get state from %s: %v", member.Name, err)
					continue
				}

				body, err := io.ReadAll(resp.Body)
				resp.Body.Close()
				if err != nil {
					logger.Warn("Error reading response body from %s: %v", member.Name, err)
					continue
				}

				var remoteState api.RawState
				if err := json.Unmarshal(body, &remoteState); err != nil {
					logger.Warn("Failed to unmarshal JSON from %s: %v. Raw JSON: %s", member.Name, err, string(body))
					continue
				}

				// Compare the local state object with the remote state object.
				if !reflect.DeepEqual(localState, remoteState.State) {
					logger.Warn("[STATE] Inconsistent state detected with node %s", member.Name)

					consistent = false
				}
			}

			if consistent {
				logger.Info("[STATE] State consistent across cluster")
			}

			time.Sleep(30 * time.Second)
		}
	}()
}
