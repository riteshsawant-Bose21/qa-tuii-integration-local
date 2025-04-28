package cluster

import (
	"encoding/json"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"log"
	"net/http"
	"os"
	"syscall"
	"time"

	"slices"

	"github.com/hashicorp/memberlist"
)

const (
	probeInterval    = 5
	probeTimeout     = 2
	pushPullInterval = 30
	retryInterval    = 2
	retryTimes       = 5
	suspicionMult    = 3
	tcpTimeout       = 10
)

// CreateMemberlist creates and configures a new memberlist instance
func CreateMemberlist(appConfig *api.AppConfig, delegate *ClusterDelegate) *memberlist.Memberlist {
	config := memberlist.DefaultLANConfig()
	config.Name = appConfig.NodeName
	config.BindAddr = appConfig.BindAddr
	config.BindPort = appConfig.BindPort

	if appConfig.Verbose {
		config.Logger = log.New(os.Stdout, fmt.Sprintf("[MEMBERLIST-%s] ", appConfig.NodeName), log.LstdFlags)
	} else {
		config.Logger = log.New(io.Discard, "", 0)
	}

	config.Delegate = delegate
	config.TCPTimeout = tcpTimeout * time.Second
	config.DisableTcpPings = false
	config.ProbeInterval = probeInterval * time.Second
	config.ProbeTimeout = probeTimeout * time.Second
	config.SuspicionMult = suspicionMult
	config.PushPullInterval = pushPullInterval * time.Second

	list, err := memberlist.Create(config)
	if err != nil {
		logging.GetLogger().Fatal("Failed to create memberlist: %v", err)
	}

	if appConfig.Verbose {
		MonitorClusterState(list)
		StartHealthCheck(list)
	}

	return list
}

// JoinMemberlist adds the node to the memberlist
func (c *Cluster) JoinMemberlist() error {

	joinAddrs, err := c.getJoinAddresses(c.bindAddr)
	if err != nil {
		return err
	}

	if len(joinAddrs) == 0 {
		return nil
	}

	logger := logging.GetLogger()

	for retries := range retryTimes {

		n, err := c.Memberlist.Join(joinAddrs)
		if err == nil {
			logger.Info("[MEMBERLIST-%s] Successfully joined cluster with %d nodes", c.nodeName, n)
			return nil
		}

		logger.Warn("[MEMBERLIST-%s] Join attempt %d failed: %v", c.nodeName, retries+1, err)

		time.Sleep(retryInterval * time.Second)
	}

	return fmt.Errorf("failed to join cluster after retries: %v", err)
}

// IsMember returns true if the address is part of the memberlist
func (c *Cluster) IsMember() (bool, error) {

	liveAddrs, err := c.GetLiveNodeAddresses()
	if err != nil {
		return false, err
	}

	if slices.Contains(liveAddrs, c.bindAddr) {
		return true, nil
	}

	return false, nil
}

// GetLiveNodeAddresses a list of live node addresses
func (c *Cluster) GetLiveNodeAddresses() ([]string, error) {

	url := fmt.Sprintf("http://%s%s/members", c.vip, api.HTTPPort)
	resp, err := http.Get(url)
	if err != nil {
		if errors.Is(err, syscall.ECONNREFUSED) {
			// Handle connection refused specifically.
			// The assumption is the the VIP server in not running yet, as the
			// caller is the first server to come up.
			return []string{}, nil
		} else {
			return nil, fmt.Errorf("unable to get members from VIP %s: %w", url, err)
		}
	}

	defer resp.Body.Close()

	var members []*memberlist.Node
	if err := json.NewDecoder(resp.Body).Decode(&members); err != nil {
		return nil, fmt.Errorf("failed to decode members: %w", err)
	}

	// Only append nodes that are alive
	var liveAddrs []string
	for _, m := range members {
		if m.State == memberlist.StateAlive {
			liveAddrs = append(liveAddrs, m.Addr.String())
		}
	}

	return liveAddrs, nil
}

// getJoinAddresses returns a list of memberlist member addresses
func (c *Cluster) getJoinAddresses(bindAddr string) ([]string, error) {

	joinAddrs, err := c.GetLiveNodeAddresses()
	if err != nil {
		return nil, err
	}

	// Remove self from nodes
	var filteredAddrs []string
	for _, addr := range joinAddrs {
		if addr != bindAddr {
			filteredAddrs = append(filteredAddrs, addr)
		}
	}

	return filteredAddrs, nil
}
