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
			validateMemberState(list, stateManager)
			validateSnapshotState(list)
			time.Sleep(checkInterval * time.Second)
		}

	}()
}

func validateMemberState(list *memberlist.Memberlist, stateManager *server.StateManager) {

	logger := logging.GetLogger()

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
}

func validateSnapshotState(list *memberlist.Memberlist) {

	logger := logging.GetLogger()

	members := list.Members()

	var hashes []string

	for _, member := range members {
		if member.State != memberlist.StateAlive {
			continue
		}

		url := fmt.Sprintf("http://%s%s/snapshots/metadata", member.Addr.String(), api.HTTPPort)
		resp, err := http.Get(url)
		if err != nil {
			logger.Warn("Failed to get metadata from %s: %v", member.Name, err)
			continue
		}

		body, err := io.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			logger.Warn("Error reading response body from %s: %v", member.Name, err)
			continue
		}

		var metadata api.SnapshotMetadata
		if err := json.Unmarshal(body, &metadata); err != nil {
			logger.Warn("Failed to unmarshal JSON from %s: %v. Raw JSON: %s", member.Name, err, string(body))
			continue
		}

		hashes = append(hashes, metadata.DBHash)
	}

	consistent := true

	if len(hashes) > 0 {
		first := hashes[0]
		for _, s := range hashes[1:] {
			if s != first {
				consistent = false
				continue
			}
		}
	}

	if consistent {
		logger.Info("[SNAPSHOTS] Snapshots consistent across cluster")
	} else {
		logger.Warn("[SNAPSHOTS] Inconsistent Snapshot detected ")
	}
}
