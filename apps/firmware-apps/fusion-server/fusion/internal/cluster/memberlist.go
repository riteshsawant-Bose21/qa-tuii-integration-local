package cluster

import (
	"errors"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"io"
	"log"
	"net/http"
	"os"
	"slices"
	"syscall"
	"time"

	json "github.com/goccy/go-json"
	hashicorpMemberlist "github.com/hashicorp/memberlist"

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
	suspicionMult       = 3
	tcpTimeout          = 10 * time.Second

	// Retry constants for VIP queries for getting members
	// I have noticed when there are couple of devices which come up
	// at the same time, there can be a delay in VIP being active on the primary node
	// and at that time we get ERCONNREFUSED errors.
	vipMembersInitialBackoff = 1 * time.Second
	vipMembersMaxBackoff     = 30 * time.Second
	vipMembersMaxDuration    = 5 * time.Minute
)

func (c *Cluster) LocalNode() *hashicorpMemberlist.Node {
	return c.memberlist.LocalNode()
}

func (c *Cluster) MemberListMembers() []*hashicorpMemberlist.Node {
	return c.memberlist.Members()
}

func (c *Cluster) SendReliable(node *hashicorpMemberlist.Node, msg []byte) error {
	return c.memberlist.SendReliable(node, msg)
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

	logger := logging.GetLogger()
	logger.Debug("[GOSSIP] config bind=%s:%d advertise=%s:%d name=%s",
		config.BindAddr, config.BindPort, config.AdvertiseAddr, config.AdvertisePort, config.Name)

	config.Delegate = delegate
	config.Events = &ClusterEventDelegate{}
	config.TCPTimeout = tcpTimeout
	config.DisableTcpPings = false
	config.ProbeInterval = probeInterval
	config.ProbeTimeout = probeTimeout
	config.SuspicionMult = suspicionMult
	config.PushPullInterval = pushPullInterval

	list, err := memberlist.Create(config)
	if err != nil {
		logger.Fatal("Failed to create memberlist: %v", err)
	}
	logger.Debug("gossip config bind=%s:%d advertise=%s:%d ",
		config.BindAddr, config.BindPort, config.AdvertiseAddr, config.AdvertisePort)

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
	logger.Debug("[GOSSIP] seeds=%v self=%s:%d", joinAddrs, c.appConfig.BindAddr, c.appConfig.BindPort)

	if len(joinAddrs) == 0 {
		// This is the first node in the cluster
		logger.Debug("[MEMBERLIST] First member of cluster: %s", c.appConfig.BindAddr)
		return nil
	}

	var lastErr error

	for attempt := range retryTimes {
		// Try to join the cluster
		_, err := c.memberlist.Join(joinAddrs)
		if err == nil {
			members := c.memberlist.Members()
			logger.Debug("[MEMBERLIST] Successfully joined cluster of size %d", len(members))

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

// IsMember returns true if the address is a member of the memberlist
func (c *Cluster) IsMember() (bool, error) {

	liveAddrs, err := c.GetLiveNodeAddresses()
	if err != nil {
		return false, err
	}

	return slices.Contains(liveAddrs, c.appConfig.BindAddr), nil
}

// GetLiveNodeAddresses returns a list of live node addresses from the VIP
func (c *Cluster) GetLiveNodeAddresses() ([]string, error) {

	members, err := c.getClusterMembersFromVip()
	if err != nil {
		return nil, err
	}
	if c.appConfig.Verbose {
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

func (c *Cluster) getClusterMembersFromVip() ([]*memberlist.Node, error) {
	vip := c.getCurrentVIP()
	if vip == "" {
		logging.GetLogger().Debug("getClusterMembersFromVip: VIP not configured yet")
		// it could be the VIP is not configured yet
		// OR
		// the vip monitor is still stabilizing and hasn't detected the VIP

		//if the VIP monitor is still stabilizing,
		// it will check if its a member in the handler
		// for VIP monitor events and trigger a retry to get members
		return nil, nil
	}

	logger := logging.GetLogger()
	url := utils.BuildInternalURL(vip, api.HTTPPort, routes.ClusterMembersEndpoint)

	backoff := vipMembersInitialBackoff
	startTime := time.Now()
	attempt := 0

	for {
		attempt++

		resp, err := c.httpClient.Get(url)
		if err == nil {
			if resp.StatusCode == http.StatusOK {
				var members []*memberlist.Node
				if err := json.NewDecoder(resp.Body).Decode(&members); err != nil {
					logger.Warn("getClusterMembersFromVip: invalid JSON from %s: %v", url, err)
					resp.Body.Close()
				} else {
					resp.Body.Close()
					if attempt > 1 {
						logger.Debug("getClusterMembersFromVip: succeeded after %d attempts", attempt)
					}
					return members, nil
				}
			} else {
				logger.Debug("getClusterMembersFromVip: Admin API returned status %d", resp.StatusCode)
				resp.Body.Close()
			}
		} else {
			if errors.Is(err, syscall.ECONNREFUSED) {
				logger.Debug("getClusterMembersFromVip: connection refused to VIP %s (attempt %d)", vip, attempt)
			} else {
				logger.Debug("getClusterMembersFromVip: request failed: %v (attempt %d)", err, attempt)
			}
		}

		// Check if we've exceeded max duration
		if time.Since(startTime) >= vipMembersMaxDuration {
			return nil, fmt.Errorf("failed to get members from VIP %s after %v (attempts: %d)", vip, vipMembersMaxDuration, attempt)
		}

		// Log retry
		logger.Debug("getClusterMembersFromVip: retrying in %v (attempt %d)", backoff, attempt)

		// Wait with exponential backoff
		time.Sleep(backoff)

		// Increase backoff exponentially
		backoff *= 2
		if backoff > vipMembersMaxBackoff {
			backoff = vipMembersMaxBackoff
		}
	}
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
