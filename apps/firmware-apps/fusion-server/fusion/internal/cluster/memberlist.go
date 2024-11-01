package cluster

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/hashicorp/memberlist"
)

// CreateMemberlist creates and configures a new memberlist instance
func CreateMemberlist(nodeName, bindAddr string, bindPort int, joinAddrs []string) (*memberlist.Memberlist, error) {
	config := memberlist.DefaultLANConfig() // Use LAN config instead of Local
	config.Name = nodeName
	config.BindAddr = bindAddr
	config.BindPort = bindPort

	// Disable TCP pings
	config.TCPTimeout = 0
	config.DisableTcpPings = true

	// Use minimal protocol
	config.ProbeInterval = 5 * time.Second
	config.ProbeTimeout = 2 * time.Second
	config.SuspicionMult = 3

	delegate := &GossipDelegate{
		logger: log.New(os.Stdout, fmt.Sprintf("[GOSSIP-%s] ", nodeName), log.LstdFlags),
		nodeID: nodeName,
	}
	config.Delegate = delegate

	config.Logger = log.New(os.Stdout, fmt.Sprintf("[MEMBERLIST-%s] ", nodeName), log.LstdFlags)

	list, err := memberlist.Create(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create memberlist: %v", err)
	}

	// Join the cluster with retries if we have addresses
	if len(joinAddrs) > 0 {
		log.Printf("[DEBUG-%s] Attempting to join cluster at: %v", nodeName, joinAddrs)

		// Retry join up to 5 times
		var n int
		for retries := 0; retries < 5; retries++ {
			n, err = list.Join(joinAddrs)
			if err == nil {
				log.Printf("[DEBUG-%s] Successfully joined cluster with %d nodes", nodeName, n)
				break
			}
			log.Printf("[DEBUG-%s] Join attempt %d failed: %v", nodeName, retries+1, err)
			time.Sleep(2 * time.Second)
		}
		if err != nil {
			return nil, fmt.Errorf("failed to join cluster after retries: %v", err)
		}
	}

	return list, nil
}
