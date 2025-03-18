package cluster

import (
	"encoding/json"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/server"
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
func CreateMemberlist(nodeName, bindAddr string, bindPort int,
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

	delegate := NewClusterDelegate(nodeName, stateManager, persistence, updater)
	config.Delegate = delegate

	config.TCPTimeout = tcpTimeout * time.Second
	config.DisableTcpPings = false
	config.ProbeInterval = probeInterval * time.Second
	config.ProbeTimeout = probeTimeout * time.Second
	config.SuspicionMult = suspicionMult
	config.PushPullInterval = pushPullInterval * time.Second

	list, err := memberlist.Create(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create memberlist: %v", err)
	}

	err = JoinMemberlist(nodeName, list, bindAddr)
	if err != nil {
		return nil, fmt.Errorf("failed to join cluster after retries: %v", err)
	}

	RejoinClusterMonitor(nodeName, bindAddr, list)

	if verbose {
		MonitorClusterState(list)
		StartHealthCheck(list)
	}
	StartStateVerification(list, stateManager)

	return list, nil
}

// GetClusterIPs retrieves the list of IP addresses of all nodes in the memberlist cluster.
func GetClusterIPs(mList *memberlist.Memberlist) []string {
	var ips []string
	for _, member := range mList.Members() {
		// Extract IP address of each member
		ips = append(ips, member.Addr.String())
	}
	return ips
}

// JoinMemberlist adds the node to the memberlist
func JoinMemberlist(nodeName string, list *memberlist.Memberlist, bindAddr string) error {

	joinAddrs, err := getJoinAddresses(bindAddr)
	if err != nil {
		return err
	}

	if len(joinAddrs) == 0 {
		return nil
	}

	logger := logging.GetLogger()

	for retries := range retryTimes {

		n, err := list.Join(joinAddrs)
		if err == nil {
			logger.Info("[MEMBERLIST-%s] Successfully joined cluster with %d nodes", nodeName, n)
			return nil
		}

		logger.Warn("[MEMBERLIST-%s] Join attempt %d failed: %v", nodeName, retries+1, err)

		time.Sleep(retryInterval * time.Second)
	}

	return fmt.Errorf("failed to join cluster after retries: %v", err)
}

// IsMember returns true if the address is part of the memberlist
func IsMember(address string, list *memberlist.Memberlist) (bool, error) {

	liveAddrs, err := GetLiveNodeAddresses()
	if err != nil {
		return false, err
	}

	if slices.Contains(liveAddrs, address) {
		return true, nil
	}

	return false, nil
}

// GetLiveNodeAddresses a list of live node addresses
func GetLiveNodeAddresses() ([]string, error) {

	vip, err := server.GetVIPAddress()
	if err != nil {
		return nil, fmt.Errorf("unable to retrieve VIP: %w", err)
	}

	url := fmt.Sprintf("http://%s%s/members", vip, api.HTTPPort)
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
func getJoinAddresses(bindAddr string) ([]string, error) {

	joinAddrs, err := GetLiveNodeAddresses()
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
