package cluster

import (
	"bytes"
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
	"slices"
	"syscall"
	"time"

	json "github.com/goccy/go-json"

	"github.com/hashicorp/memberlist"
)

const (
	gossipInterval      = 20 * time.Millisecond
	gossipToTheDeadTime = 30 * time.Second
	probeInterval       = 100 * time.Millisecond
	probeTimeout        = 100 * time.Millisecond
	pushPullInterval    = 1 * time.Second
	retryInterval       = 2 * time.Second
	retryTimes          = 5
	serialPath          = "/sys/firmware/devicetree/base/serial-number"
	serialUnknown       = "Unknown"
	suspicionMult       = 3
	tcpTimeout          = 10 * time.Second
)

type MemberlistTransport struct {
	ml *memberlist.Memberlist
}

func (t *MemberlistTransport) LocalNode() *memberlist.Node {
	return t.ml.LocalNode()
}

func (t *MemberlistTransport) Members() []*memberlist.Node {
	return t.ml.Members()
}

func (t *MemberlistTransport) SendReliable(n *memberlist.Node, msg []byte) error {
	return t.ml.SendReliable(n, msg)
}

// CreateMemberlist creates and configures a new memberlist instance
func CreateMemberlist(appConfig *api.AppConfig, delegate *ClusterDelegate) *memberlist.Memberlist {
	config := memberlist.DefaultLANConfig()
	config.GossipInterval = gossipInterval
	config.GossipToTheDeadTime = gossipToTheDeadTime
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
	config.ProbeTimeout = probeTimeout
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

	// Determine other members to join
	joinAddrs, err := c.getJoinAddresses(c.appConfig.BindAddr)
	if err != nil {
		return fmt.Errorf("getJoinAddresses: %w", err)
	}

	logger := logging.GetLogger()

	if len(joinAddrs) == 0 {
		// This is the first node in the cluster
		logger.Debug("[MEMBERLIST] First member of cluster: %s", c.appConfig.BindAddr)
		return nil
	}

	var lastErr error

	for attempt := range retryTimes {
		// Try to join the cluster
		_, err := c.Memberlist.Join(joinAddrs)
		if err == nil {
			members := c.Memberlist.Members()
			logger.Debug("[MEMBERLIST] Successfully joined cluster of size %d", len(members))

			c.updateDeviceInfo()

			if c.appConfig.Verbose {
				for _, member := range members {
					logger.Debug("[MEMBERLIST] %s (%s)\n", member.Name, member.Addr)
				}
			}
			return nil
		}

		lastErr = err
		logger.Warn("[MEMBERLIST] Join attempt %d/%d failed: %v",
			attempt+1, retryTimes, err)
		time.Sleep(retryInterval)
	}

	return fmt.Errorf("failed to join cluster after %d attempts: %w", retryTimes, lastErr)
}

// isMember returns true if the address is a member of the memberlist
func (c *Cluster) isMember() (bool, error) {

	liveAddrs, err := c.GetLiveNodeAddresses()
	if err != nil {
		return false, err
	}

	return slices.Contains(liveAddrs, c.appConfig.BindAddr), nil
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

	logger := logging.GetLogger()

	if resp.StatusCode != http.StatusOK {
		// Assume the admin API isn't ready yet.
		logger.Warn("GetLiveNodeAddresses: Admin API unavailable")
		return []string{}, nil
	}

	var members []*memberlist.Node
	if err := json.NewDecoder(resp.Body).Decode(&members); err != nil {
		logger.Warn("GetLiveNodeAddresses: invalid JSON from %s: %v", url, err)
		return []string{}, nil
	}

	if c.appConfig.Verbose {
		for _, m := range members {
			logger.Debug("[MEMBERLIST] Found node: %s (%s), state=%v", m.Name, m.Addr.String(), m.State)
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

	info.Address = c.appConfig.BindAddr
	if info.Id == "" {
		info.Id = c.appConfig.NodeName + "_instance"
	}

	if info.Name == "" {
		info.Name = c.appConfig.NodeName
	}

	if info.SerialNumber == "" {
		data, err := os.ReadFile(serialPath)
		if err != nil {
			logging.GetLogger().Warn("%s not found.", serialPath)
			info.SerialNumber = serialUnknown
		} else {
			info.SerialNumber = string(bytes.TrimRight(data, "\x00\n"))
		}
	}

	if err := c.delegate.persistence.SetDeviceInfo(&info); err != nil {
		logging.GetLogger().Error("Unable to update device info: %v", err)
		return
	}
}
