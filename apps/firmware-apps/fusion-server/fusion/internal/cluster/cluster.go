package cluster

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/network"
	"net"
	"net/http"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/hashicorp/memberlist"
)

const (
	monitorInterval = 10 * time.Second
)

// ClusterInfo provides information about the cluster
type ClusterInfo struct {
	MemberCount    int             `json:"member_count"`
	AliveCount     int             `json:"alive_count"`
	LocalNode      string          `json:"local_node"`
	Members        []ClusterMember `json:"members"`
	LastUpdateTime time.Time       `json:"last_update_time"`

	// Additional cluster metrics
	SuspectNodes   int     `json:"suspect_nodes"`
	DeadNodes      int     `json:"dead_nodes"`
	ClusterHealth  float64 `json:"cluster_health"` // Percentage of healthy nodes
	AvgPingLatency float64 `json:"avg_ping_latency_ms"`
}

// ClusterMember represents a member in the cluster
type ClusterMember struct {
	Name    string `json:"name"`
	Address string `json:"address"`
	Port    uint16 `json:"port"`
	State   string `json:"state"`
}

type Cluster struct {
	nodeName         string
	bindAddr         string
	bindPort         int
	delegate         *ClusterDelegate
	config           *api.AppConfig
	Memberlist       *memberlist.Memberlist
	vip              string
	vipLock          sync.RWMutex
	configPath       string
	Metrics          *MetricsCollector
	networkLatencies *NetworkLatencyStore
}

func NewCluster(appConfig *api.AppConfig, delegate *ClusterDelegate, memberlist *memberlist.Memberlist) *Cluster {

	cluster := &Cluster{
		nodeName:         appConfig.NodeName,
		bindAddr:         appConfig.BindAddr,
		bindPort:         appConfig.BindPort,
		delegate:         delegate,
		config:           appConfig,
		Memberlist:       memberlist,
		configPath:       "/etc/keepalived/keepalived.conf",
		Metrics:          NewMetricsCollector(memberlist, delegate.stateManager),
		networkLatencies: NewNetworkLatencyStore(maxLatencyCount, latencyPruneTime),
	}

	if !cluster.config.Local {
		logger := logging.GetLogger()

		if err := cluster.startVRRPListener(); err != nil {
			logger.Fatal("Failed to start VRRP listener: %v", err)
		}

		vips, err := cluster.getVIPFromConfig()
		if err != nil {
			logger.Fatal("Failed to get VIP: %v", err)
		}

		for _, vip := range vips {
			if isVip := cluster.isLocalVIP(vip); isVip {
				if err := cluster.delegate.taskManager.Start(); err != nil {
					logger.Fatal("Failed to start TaskManger: %v", err)
				} else {
					logger.Info("TaskManager running on %s", appConfig.NodeName)
				}
				break
			}
		}
	}

	cluster.updateDeviceInfo()

	go cluster.startStateMonitor()
	go cluster.startNetworkLatencyProbes()

	return cluster
}

// GetInfo returns detailed information about the cluster
func (c *Cluster) GetInfo() ClusterInfo {
	members := c.Memberlist.Members()
	clusterMembers := c.getMembers()

	aliveCount := 0
	for _, member := range members {
		if member.State == memberlist.StateAlive {
			aliveCount++
		}
	}

	return ClusterInfo{
		MemberCount:    len(members),
		AliveCount:     aliveCount,
		LocalNode:      c.Memberlist.LocalNode().Name,
		Members:        clusterMembers,
		LastUpdateTime: time.Now().UTC(),
	}
}

// getClusterIPs retrieves the list of IP addresses of all nodes in the cluster
func (c *Cluster) getClusterIPs() []string {
	var ips []string
	for _, member := range c.Memberlist.Members() {
		// Extract IP address of each member
		ips = append(ips, member.Addr.String())
	}
	return ips
}

func (c *Cluster) listenerUpdated(vip string) {

	logger := logging.GetLogger()
	logger.Debug("New VIP detected: %s", vip)

	c.vipLock.Lock()
	c.vip = vip
	c.vipLock.Unlock()

	member, err := c.isMember()
	if err != nil {
		logger.Error("Unable to determine membership: %v", err)
	}

	if member {
		logger.Debug("%s already a member", c.nodeName)
	} else {
		if err = c.JoinMemberlist(); err != nil {
			logger.Error("Unable to join memberlist: %v", err)
		} else {
			logger.Info("%s [%s] joined memberlist with VIP: %s", c.nodeName, c.bindAddr, c.vip)
		}
	}
}

func (c *Cluster) startVRRPListener() error {
	if err := network.StartVRRPListener(c.listenerUpdated); err != nil {
		return fmt.Errorf("unable to start keepalived listener: %v", err)
	}
	return nil
}

// isLocalVIP compares the VIP (which might be in CIDR format) to the IPs on local interfaces.
func (c *Cluster) isLocalVIP(vip string) bool {
	expectedIP := net.ParseIP(vip)
	if expectedIP == nil {
		// Try to parse as CIDR and extract the IP
		ip, _, err := net.ParseCIDR(vip)
		if err != nil {
			return false
		}
		expectedIP = ip
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return false
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.Equal(expectedIP) {
				return true
			}
		}
	}

	return false
}

// getLocalAndVIP checks whether `vip` (CIDR or plain IP) is assigned on any local interface.
// If so, it returns two things:
//   - internalAddr: the first non-loopback IPv4 address that is NOT equal to the VIP
//   - vipAddr: the exact Addr where vip was found
//   - ok = true
//
// If vip isn’t present on any interface, it returns (nil, nil, false).
func (c *Cluster) getLocalForVIP(vip string) (net.Addr, net.Addr, bool) {
	expectedIP := net.ParseIP(vip)
	if expectedIP == nil {
		ip, _, err := net.ParseCIDR(vip)
		if err != nil {
			return nil, nil, false
		}
		expectedIP = ip
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return nil, nil, false
	}

	var vipAddr net.Addr
	var internalAddr net.Addr

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok {
			if ipnet.IP.IsLoopback() {
				continue
			}

			if ip4 := ipnet.IP.To4(); ip4 != nil {
				if ip4.Equal(expectedIP) {
					vipAddr = &net.IPAddr{IP: ip4}
					continue
				}
				if internalAddr == nil {
					internalAddr = &net.IPAddr{IP: ip4}
				}
			}
		}
	}

	if vipAddr == nil {
		return nil, nil, false
	}

	return internalAddr, vipAddr, true
}

func (c *Cluster) getVIPFromConfig() ([]string, error) {

	data, err := os.ReadFile(c.configPath)
	if err != nil {
		return nil, fmt.Errorf("unable to read config file: %v", err)
	}
	configText := string(data)

	// This regex looks for a block starting with "virtual_ipaddress" and
	// captures everything until the closing brace.
	re := regexp.MustCompile(`virtual_ipaddress\s*{([^}]+)}`)
	matches := re.FindStringSubmatch(configText)
	if len(matches) < 2 {
		return nil, fmt.Errorf("no virtual_ipaddress block found")
	}

	// Extract the content between braces and split by newline or whitespace
	vipBlock := matches[1]

	// Split lines and remove extra spaces
	lines := strings.Split(vipBlock, "\n")
	var vips []string
	for _, line := range lines {
		v := strings.TrimSpace(line)
		if v != "" {
			vips = append(vips, v)
		}
	}
	return vips, nil
}

// restartKeepalived reloads the keepalived process
func (c *Cluster) restartKeepalived() error {
	return exec.Command("systemctl", "reload", "keepalived").Run()
}

// monitorState continuously monitors the cluster membership state
func (c *Cluster) startStateMonitor() {
	go func() {
		for {
			members := c.Memberlist.Members()
			logger := logging.GetLogger()

			logger.Debug("[CLUSTER] Current cluster state:")
			logger.Debug("[CLUSTER] Total members: %d", len(members))

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

				logger.Debug("[CLUSTER] Node: %s, Address: %s:%d, Status: %s",
					member.Name,
					member.Addr.String(),
					member.Port,
					status,
				)
			}

			time.Sleep(monitorInterval)
		}
	}()
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

// getClusterMembers returns the current list of cluster members
func (c *Cluster) getMembers() []ClusterMember {
	members := c.Memberlist.Members()
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

// fetchGenericFromAdmin is a helper; every node produces a []T, local or remote.
func fetchGenericFromAdmin[T any](
	c *Cluster,
	endpoint string,
	localFetch func() []T,
	remoteFetch func(addr, endpoint string) ([]T, error),
) []T {
	var all []T
	logger := logging.GetLogger()

	for _, addr := range c.getNodeAdminAddresses() {
		if c.hostIsLocal(addr) {
			all = append(all, localFetch()...)
			continue
		}

		remoteSlice, err := remoteFetch(addr, endpoint)
		if err != nil {
			url := getLocalURL(addr, endpoint)
			logger.Error("GET %s failed: %v", url, err)
			continue
		}
		all = append(all, remoteSlice...)
	}

	return all
}

// fetchFromAdminSingle is the single‐object version: wraps T into []T.
func fetchFromAdminSingle[T any](
	c *Cluster,
	localFn func() T, // returns one T for the local node
	endpoint string,
) []T {
	// localFetch: wrap the single‐T into a slice
	localFetch := func() []T {
		single := localFn()
		return []T{single}
	}

	// remoteFetch: decode one T, then wrap into []T
	remoteFetch := func(addr, endpoint string) ([]T, error) {
		var tmp T
		if err := fetchAndDecode(addr, endpoint, &tmp); err != nil {
			return nil, err
		}
		return []T{tmp}, nil
	}

	return fetchGenericFromAdmin(c, endpoint, localFetch, remoteFetch)
}

// fetchFromAdminSlice returns []T for local and remote.
func fetchFromAdminSlice[T any](
	c *Cluster,
	localFn func() []T, // returns a slice for the local node
	endpoint string,
) []T {
	localFetch := func() []T {
		return localFn()
	}

	remoteFetch := func(addr, endpoint string) ([]T, error) {
		var remoteSlice []T
		if err := fetchAndDecode(addr, endpoint, &remoteSlice); err != nil {
			return nil, err
		}
		return remoteSlice, nil
	}

	return fetchGenericFromAdmin(c, endpoint, localFetch, remoteFetch)
}

// fetchFromAdmin return a single value
func fetchFromAdmin[T any](
	c *Cluster,
	localFn func() T,
	endpoint string,
) []T {
	return fetchFromAdminSingle(c, localFn, endpoint)
}

// fetchAllFromAdmin return a slice
func fetchAllFromAdmin[T any](
	c *Cluster,
	localFn func() []T,
	endpoint string,
) []T {
	return fetchFromAdminSlice(c, localFn, endpoint)
}

// fetchAndDecode calls an endpoint and decodes the value
func fetchAndDecode[T any](
	addr, endpoint string,
	dest *T,
) error {
	resp, err := getLocalEndpointResponse(addr, endpoint)
	if err != nil {
		return err
	}
	return decodeSlice(resp.Body, dest)
}

// postGenericToAdmin POSTs to an admin route on all nodes
func postGenericToAdmin(
	c *Cluster,
	endpoint string,
	localFn func() error,
) error {

	for _, addr := range c.getNodeAdminAddresses() {
		if c.hostIsLocal(addr) {
			// If this is the local address, invoke localFn() directly:
			if err := localFn(); err != nil {
				return fmt.Errorf("local update failed: %w", err)
			}
			continue
		}

		// POST to the remote node’s admin endpoint
		urlStr := getLocalURL(addr, endpoint)
		resp, err := http.Post(urlStr, "", nil)
		if err != nil {
			return err
		}
		resp.Body.Close()
	}

	return nil
}

// getLocalEndpointResponse calls a endpoint
func getLocalEndpointResponse(addr, endpoint string) (response *http.Response, err error) {

	url := getLocalURL(addr, endpoint)
	resp, err := httpClient.Get(url)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, fmt.Errorf("unexpected status %d", resp.StatusCode)
	}

	return resp, nil
}

// hostIsLocal checks if the address is the local memberlist node
func (c *Cluster) hostIsLocal(addr string) bool {
	host, _, err := net.SplitHostPort(addr)
	if err != nil {
		logging.GetLogger().Error("Error splitting host port: %v", err)

		return false
	}
	return host == c.Memberlist.LocalNode().Addr.String()
}

// getLocalURL builds a full API URL to the endpoint
func getLocalURL(addr, endpoint string) string {
	return fmt.Sprintf("%s%s%s", api.Protocol, addr, endpoint)
}
