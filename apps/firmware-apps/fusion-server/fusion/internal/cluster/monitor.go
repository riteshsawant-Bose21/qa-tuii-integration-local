package cluster

import (
	"log"
	"time"

	"github.com/hashicorp/memberlist"
)

// MonitorClusterState continuously monitors the cluster membership state
func MonitorClusterState(list *memberlist.Memberlist) {
	go func() {
		for {
			members := list.Members()
			log.Printf("[CLUSTER] Current cluster state:")
			log.Printf("[CLUSTER] Total members: %d", len(members))

			for _, member := range members {
				status := "ALIVE"
				switch member.State {
				case memberlist.StateAlive:
					status = "ALIVE"
				case memberlist.StateSuspect:
					status = "SUSPECT"
				case memberlist.StateDead:
					status = "DEAD"
				default:
					status = "UNKNOWN"
				}

				log.Printf("[CLUSTER] - Node: %s, Address: %s:%d, Status: %s",
					member.Name,
					member.Addr.String(),
					member.Port,
					status,
				)
			}

			time.Sleep(10 * time.Second)
		}
	}()
}

// GetClusterMembers returns the current list of cluster members
func GetClusterMembers(list *memberlist.Memberlist) []ClusterMember {
	members := list.Members()
	result := make([]ClusterMember, len(members))

	for i, member := range members {
		result[i] = ClusterMember{
			Name:    member.Name,
			Address: member.Addr.String(),
			Port:    member.Port,
			State:   getStateString(member.State),
		}
	}

	return result
}

// ClusterMember represents a member in the cluster
type ClusterMember struct {
	Name    string `json:"name"`
	Address string `json:"address"`
	Port    uint16 `json:"port"`
	State   string `json:"state"`
}

// getStateString converts memberlist state to human-readable string
func getStateString(state memberlist.NodeStateType) string {
	switch state {
	case memberlist.StateAlive:
		return "ALIVE"
	case memberlist.StateSuspect:
		return "SUSPECT"
	case memberlist.StateDead:
		return "DEAD"
	default:
		return "UNKNOWN"
	}
}

// ClusterInfo provides information about the cluster
type ClusterInfo struct {
	MemberCount    int             `json:"member_count"`
	AliveCount     int             `json:"alive_count"`
	LocalNode      string          `json:"local_node"`
	Members        []ClusterMember `json:"members"`
	LastUpdateTime time.Time       `json:"last_update_time"`
}

// GetClusterInfo returns detailed information about the cluster
func GetClusterInfo(list *memberlist.Memberlist) ClusterInfo {
	members := list.Members()
	clusterMembers := GetClusterMembers(list)

	aliveCount := 0
	for _, member := range members {
		if member.State == memberlist.StateAlive {
			aliveCount++
		}
	}

	return ClusterInfo{
		MemberCount:    len(members),
		AliveCount:     aliveCount,
		LocalNode:      list.LocalNode().Name,
		Members:        clusterMembers,
		LastUpdateTime: time.Now().UTC(),
	}
}
