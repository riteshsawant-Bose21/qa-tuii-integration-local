package cluster

import (
	"encoding/json"
	"errors"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/routes"
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
	gossipInterval   = 100 * time.Millisecond
	probeInterval    = 5 * time.Second
	probeTimeout     = 2 * time.Second
	pushPullInterval = 30 * time.Second
	retryInterval    = 2 * time.Second
	retryTimes       = 5
	suspicionMult    = 3
	tcpTimeout       = 10 * time.Second
)

// CreateMemberlist creates and configures a new memberlist instance
func CreateMemberlist(appConfig *api.AppConfig, delegate *ClusterDelegate) *memberlist.Memberlist {
	config := memberlist.DefaultLANConfig()
	config.GossipInterval = gossipInterval
	config.Name = appConfig.NodeName
	config.BindAddr = appConfig.BindAddr
	config.BindPort = appConfig.BindPort
	config.AdvertiseAddr = appConfig.BindAddr
	config.AdvertisePort = appConfig.BindPort

	if appConfig.Verbose {
		config.Logger = log.New(os.Stdout, fmt.Sprintf("[MEMBERLIST-%s] ", appConfig.NodeName), log.LstdFlags)
	} else {
		config.Logger = log.New(io.Discard, "", 0)
	}

	config.Delegate = delegate
	config.TCPTimeout = tcpTimeout
	config.DisableTcpPings = false
	config.ProbeInterval = probeInterval
	config.ProbeTimeout = probeTimeout * time.Second
	config.SuspicionMult = suspicionMult
	config.PushPullInterval = pushPullInterval

	list, err := memberlist.Create(config)
	if err != nil {
		logging.GetLogger().Fatal("Failed to create memberlist: %v", err)
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

	for attempt := range retryTimes {

		_, err := c.Memberlist.Join(joinAddrs)
		if err == nil {
			members := c.Memberlist.Members()
			logger.Info("[MEMBERLIST] Successfully joined cluster of size %d", len(members))
			c.updateDeviceInfo()

			if c.config.Verbose {
				for _, member := range c.Memberlist.Members() {
					logger.Debug("[MEMBERLIST] %s (%s)\n", member.Name, member.Addr)
				}
			}
			return nil
		}

		logger.Warn("[MEMBERLIST] Join attempt %d failed: %v", attempt+1, err)

		time.Sleep(retryInterval)
	}

	return fmt.Errorf("failed to join cluster after retries: %d: %v", retryTimes, err)
}

// isMember returns true if the address is a member of the memberlist
func (c *Cluster) isMember() (bool, error) {

	liveAddrs, err := c.GetLiveNodeAddresses()
	if err != nil {
		return false, err
	}

	return slices.Contains(liveAddrs, c.bindAddr), nil
}

// GetLiveNodeAddresses returns a list of live node addresses from the VIP
func (c *Cluster) GetLiveNodeAddresses() ([]string, error) {

	url := fmt.Sprintf("%s%s:%s%s", api.Protocol, c.vip, api.HTTPPort, routes.ClusterMembersEndpoint)
	resp, err := http.Get(url)
	if err != nil {
		if errors.Is(err, syscall.ECONNREFUSED) {
			// Connection refused likely means the VIP is not up yet (e.g., this node is first to start).
			return []string{}, nil
		}
		return nil, fmt.Errorf("unable to get members from VIP %s: %w", url, err)
	}

	defer resp.Body.Close()

	var members []*memberlist.Node
	if err := json.NewDecoder(resp.Body).Decode(&members); err != nil {
		return nil, fmt.Errorf("failed to decode members: %w", err)
	}

	if c.config.Verbose {
		for _, m := range members {
			logging.GetLogger().Debug("[MEMBERLIST] Found node: %s (%s), state=%v", m.Name, m.Addr.String(), m.State)
		}
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

// updateDeviceInfo updates the persisted device info
func (c *Cluster) updateDeviceInfo() {

	var info persistence.DeviceInfo
	savedInfo, err := c.delegate.persistence.GetDeviceInfo()
	if err == nil {
		info = *savedInfo
	}

	info.Address = c.bindAddr
	if info.Id == "" {
		info.Id = c.nodeName + "_instance"
	}

	if info.Name == "" {
		info.Name = c.nodeName
	}

	if err := c.delegate.persistence.SetDeviceInfo(&info); err != nil {
		logging.GetLogger().Error("Unable to update device info: %v", err)
		return
	}
}
