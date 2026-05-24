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
	"strings"
	"syscall"
	"time"

	json "github.com/goccy/go-json"
	hashicorpMemberlist "github.com/hashicorp/memberlist"

	"github.com/hashicorp/memberlist"
)

const firstNodeWhileVIPExistsLog = "[MEMBERLIST] No remote join seeds resolved while a VIP was already known; treating node as first member"
const zeroSeedsJoinLog = "[MEMBERLIST] No remote join seeds resolved"
const retryingZeroSeedsJoinLog = "[MEMBERLIST] No remote join seeds resolved during startup; retrying join"
const standaloneBootstrapAssumedLog = "[MEMBERLIST] Join retry stopping after startup grace; allowing standalone bootstrap"

const (
	gossipInterval      = 20 * time.Millisecond
	gossipToTheDeadTime = 30 * time.Second
	probeInterval       = 100 * time.Millisecond
	probeTimeout        = 50 * time.Millisecond
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
	bootstrapJoinGrace       = 15 * time.Second
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
		currentVIP := c.getCurrentVIP()
		localMembers := c.memberlist.Members()
		logger.Warn("%s vip=%q self=%s:%d local_members=%s",
			zeroSeedsJoinLog,
			currentVIP,
			c.appConfig.BindAddr,
			c.appConfig.BindPort,
			formatMemberlistMembers(localMembers),
		)
		if c.shouldRetryZeroSeedJoin(currentVIP, localMembers) {
			logger.Warn("%s vip=%q local_vip_holder=%t self=%s:%d",
				retryingZeroSeedsJoinLog,
				currentVIP,
				c.isLocalVIPHolder(),
				c.appConfig.BindAddr,
				c.appConfig.BindPort,
			)
			c.ensureJoinRetryLoop()
			return fmt.Errorf("join unresolved: zero remote seeds for %s while cluster state is not a confirmed bootstrap", c.appConfig.BindAddr)
		}

		if currentVIP != "" {
			logger.Warn("%s vip=%s self=%s:%d local_members=%s",
				firstNodeWhileVIPExistsLog,
				currentVIP,
				c.appConfig.BindAddr,
				c.appConfig.BindPort,
				formatMemberlistMembers(localMembers),
			)
		}
		logger.Warn("[MEMBERLIST] First member of cluster: %s", c.appConfig.BindAddr)
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
		if attempt < retryTimes-1 {
			time.Sleep(retryInterval)
		}
	}

	return fmt.Errorf("failed to join cluster after %d attempts: %w", retryTimes, lastErr)
}

func (c *Cluster) shouldRetryZeroSeedJoin(currentVIP string, localMembers []*memberlist.Node) bool {
	if len(localMembers) > 1 {
		return false
	}
	if currentVIP != "" {
		return true
	}
	if c.isLocalVIPHolder() {
		return true
	}
	return time.Since(c.createdAt) < bootstrapJoinGrace
}

func (c *Cluster) isLocalVIPHolder() bool {
	if c.vipMonitor == nil {
		return false
	}
	return c.vipMonitor.IsLocalVIPHolder()
}

func (c *Cluster) ensureJoinRetryLoop() {
	c.joinRetryMu.Lock()
	if c.joinRetryActive {
		c.joinRetryMu.Unlock()
		return
	}
	c.joinRetryActive = true
	c.joinRetryMu.Unlock()

	go c.retryJoinUntilSuccessOrTimeout()
}

func (c *Cluster) retryJoinUntilSuccessOrTimeout() {
	logger := logging.GetLogger()
	deadline := time.Now().Add(vipMembersMaxDuration)

	defer func() {
		c.joinRetryMu.Lock()
		c.joinRetryActive = false
		c.joinRetryMu.Unlock()
	}()

	for time.Now().Before(deadline) {
		if len(c.memberlist.Members()) > 1 {
			logger.Info("[MEMBERLIST] Join retry loop stopping: local memberlist already has %d members", len(c.memberlist.Members()))
			return
		}

		joinAddrs, err := c.getJoinAddresses(c.appConfig.BindAddr)
		if err != nil {
			logger.Warn("[MEMBERLIST] Join retry: failed to resolve join addresses: %v", err)
			time.Sleep(retryInterval)
			continue
		}

		if len(joinAddrs) == 0 {
			currentVIP := c.getCurrentVIP()
			localMembers := c.memberlist.Members()
			if !c.shouldRetryZeroSeedJoin(currentVIP, localMembers) {
				logger.Warn("%s vip=%q self=%s elapsed=%v local_members=%s",
					standaloneBootstrapAssumedLog,
					currentVIP,
					c.appConfig.BindAddr,
					time.Since(c.createdAt).Round(time.Second),
					formatMemberlistMembers(localMembers),
				)
				return
			}

			logger.Warn("[MEMBERLIST] Join retry: still no remote seeds for %s", c.appConfig.BindAddr)
			time.Sleep(retryInterval)
			continue
		}

		if _, err := c.memberlist.Join(joinAddrs); err != nil {
			logger.Warn("[MEMBERLIST] Join retry with seeds=%v failed: %v", joinAddrs, err)
			time.Sleep(retryInterval)
			continue
		}

		logger.Info("[MEMBERLIST] Join retry succeeded with seeds=%v", joinAddrs)
		return
	}

	logger.Error("[MEMBERLIST] Join retry loop timed out after %v for %s", vipMembersMaxDuration, c.appConfig.BindAddr)
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

	backoff := vipMembersInitialBackoff
	startTime := time.Now()
	attempt := 0
	currentVIP := vip
	for {
		attempt++

		// On retries, re-resolve the VIP so that a failover during the retry
		// window is picked up rather than retrying against a stale address.
		if attempt > 1 {
			if resolved := c.getCurrentVIP(); resolved != "" {
				currentVIP = resolved
			}
		}
		url := utils.BuildInternalURL(currentVIP, api.HTTPPort, routes.ClusterMembersEndpoint)

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

	if len(filteredAddrs) == 0 && c.getCurrentVIP() != "" {
		logging.GetLogger().Warn("[MEMBERLIST] getJoinAddresses filtered all VIP-derived seeds as self vip=%s self=%s live_addrs=%v",
			c.getCurrentVIP(),
			bindAddr,
			joinAddrs,
		)
	}

	return filteredAddrs, nil
}

func formatMemberlistMembers(members []*memberlist.Node) string {
	if len(members) == 0 {
		return "[]"
	}

	formatted := make([]string, 0, len(members))
	for _, member := range members {
		if member == nil {
			formatted = append(formatted, "<nil>")
			continue
		}
		formatted = append(formatted, fmt.Sprintf("%s(%s:%d,%s)",
			member.Name,
			member.Addr.String(),
			member.Port,
			GetStateString(member.State),
		))
	}

	return fmt.Sprintf("[%s]", strings.Join(formatted, ", "))
}
