package cluster

import (
	"fmt"
	"fusion/internal/logging"
	"fusion/internal/server"
	"io"
	"log"
	"os"
	"time"

	"github.com/hashicorp/memberlist"
)

const (
	probeInterval = 5
	probeTimeout  = 2
	retryInterval = 2
	retryTimes    = 5
	suspicionMult = 3
	tcpTimeout    = 10
)

// CreateMemberlist creates and configures a new memberlist instance
func CreateMemberlist(nodeName, bindAddr string, bindPort int, joinAddrs []string,
	stateManager *server.StateManager, persistence *server.ConfigPersistence, updater *server.Updater, verbose bool) (*memberlist.Memberlist, error) {
	config := memberlist.DefaultLANConfig()
	config.Name = nodeName
	config.BindAddr = bindAddr
	config.BindPort = bindPort

	if verbose {
		config.Logger = log.New(os.Stdout, fmt.Sprintf("[MEMBERLIST-%s] ", nodeName), log.LstdFlags)
	} else {
		config.Logger = log.New(io.Discard, "", 0)
	}

	delegate := NewClusterDelegate(nodeName, stateManager, persistence, updater, verbose)
	config.Delegate = delegate

	config.TCPTimeout = tcpTimeout * time.Second
	config.DisableTcpPings = false
	config.ProbeInterval = probeInterval * time.Second
	config.ProbeTimeout = probeTimeout * time.Second
	config.SuspicionMult = suspicionMult

	list, err := memberlist.Create(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create memberlist: %v", err)
	}

	if len(joinAddrs) > 0 {
		var n int
		for retries := 0; retries < retryTimes; retries++ {
			n, err = list.Join(joinAddrs)
			if err == nil {
				if verbose {
					logger := logging.GetLogger()
					logger.Info("[MEMBERLIST-%s] Successfully joined cluster with %d nodes", nodeName, n)
				}
				break
			}
			if verbose {
				logger := logging.GetLogger()
				logger.Info("[MEMBERLIST-%s] Join attempt %d failed: %v", nodeName, retries+1, err)
			}
			time.Sleep(retryInterval * time.Second)
		}
		if err != nil {
			return nil, fmt.Errorf("failed to join cluster after retries: %v", err)
		}
	}

	return list, nil
}
