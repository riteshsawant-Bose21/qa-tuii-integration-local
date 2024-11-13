package cluster

import (
	"fmt"
	"fusion/internal/config"
	"log"
	"os"
	"time"

	"github.com/hashicorp/memberlist"
)

// CreateMemberlist creates and configures a new memberlist instance
func CreateMemberlist(nodeName, bindAddr string, bindPort int, joinAddrs []string, stateManager *config.StateManager) (*memberlist.Memberlist, error) {
	config := memberlist.DefaultLANConfig()
	config.Name = nodeName
	config.BindAddr = bindAddr
	config.BindPort = bindPort
	config.Logger = log.New(os.Stdout, fmt.Sprintf("[MEMBERLIST-%s] ", nodeName), log.LstdFlags)

	// Create delegate with state manager
	delegate := NewGossipDelegate(nodeName, stateManager)
	config.Delegate = delegate

	// Enable TCP for join operations
	config.TCPTimeout = 10 * time.Second // Give enough time for join
	config.DisableTcpPings = false       // Enable TCP pings for initial join

	// After successful join, we can use minimal UDP protocol
	config.ProbeInterval = 5 * time.Second
	config.ProbeTimeout = 2 * time.Second
	config.SuspicionMult = 3

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
