package cluster

import (
	"fmt"
	"fusion-services-core/vip"
	"os/exec"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/routes"
	"fusion/internal/utils"
	"net"
	"net/http"
	"runtime"
	"strings"
	"time"

	hashicorpMemberlist "github.com/hashicorp/memberlist"
)

const (
	configPath           = "/etc/keepalived/" + vip.DefaultConfFile
	statusUpdateInterval = 30 * time.Second
	monitorInterval      = 10 * time.Second
)

type VIPMonitorInterface interface {
	GetCurrentVIP() string
	IsLocalVIPHolder() bool
}

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

// ClusterStatus holds information of the cluster state
type ClusterStatus struct {
	VIP       string   `json:"vip"`     // Current VIP address (eg. "192.168.2.100")
	Host      string   `json:"host"`    // Local IP address of the node holding VIP
	Cluster   []string `json:"cluster"` // All known cluster node addresses
	Timestamp int64    `json:"ts"`      // Unix timestamp for freshness
}

type Cluster struct {
	appConfig        *api.AppConfig
	delegate         *ClusterDelegate
	httpClient       *http.Client
	memberlist       *hashicorpMemberlist.Memberlist
	vipMonitor       VIPMonitorInterface
	Metrics          *MetricsCollector
	networkLatencies *NetworkLatencyStore
}

func NewCluster(appConfig *api.AppConfig, delegate *ClusterDelegate, memberlist *hashicorpMemberlist.Memberlist) *Cluster {

	cluster := &Cluster{
		appConfig:        appConfig,
		delegate:         delegate,
		httpClient:       &http.Client{Timeout: api.HTTPTimeout},
		memberlist:       memberlist,
		Metrics:          NewMetricsCollector(memberlist, delegate.stateManager),
		networkLatencies: NewNetworkLatencyStore(maxLatencyCount, latencyPruneTime),
	}

	logger := logging.GetLogger()

	if err := cluster.JoinMemberlist(); err != nil {
		logger.Error("initial JoinMemberlist: %v", err)
	}

	cluster.refreshDeviceDefaultsIfRequired()

	go cluster.initialAudioSync()
	go cluster.startStateMonitor()
	go cluster.startNetworkLatencyProbes()

	return cluster
}

func (c *Cluster) Stop() {
}

// GetInfo returns detailed information about the cluster
func (c *Cluster) GetInfo() ClusterInfo {
	members := c.memberlist.Members()
	clusterMembers := c.getMembers()

	aliveCount := 0
	for _, member := range members {
		if member.State == hashicorpMemberlist.StateAlive {
			aliveCount++
		}
	}

	return ClusterInfo{
		MemberCount:    len(members),
		AliveCount:     aliveCount,
		LocalNode:      c.memberlist.LocalNode().Name,
		Members:        clusterMembers,
		LastUpdateTime: time.Now().UTC(),
	}
}

func (c *Cluster) GetMembers() []*hashicorpMemberlist.Node {
	return c.memberlist.Members()
}

func (c *Cluster) SetMemberlist(memberlist *hashicorpMemberlist.Memberlist) {
	c.memberlist = memberlist
	if err := c.JoinMemberlist(); err != nil {
		logging.GetLogger().Error("Unable to join after setting memberlist: %v", err)
	}
	c.Metrics.SetMemberlist(memberlist)
}

// getClusterIPs retrieves the list of IP addresses of all nodes in the cluster
func (c *Cluster) getClusterIPs() []string {
	var ips []string
	for _, member := range c.memberlist.Members() {
		// Extract IP address of each member
		ips = append(ips, member.Addr.String())
	}
	return ips
}

// SetVIPMonitor sets the VIPMonitor reference for this cluster
func (c *Cluster) SetVIPMonitor(vm VIPMonitorInterface) {
	c.vipMonitor = vm
}

// getCurrentVIP returns the current VIP from VIPMonitor
func (c *Cluster) getCurrentVIP() string {
	if c.vipMonitor != nil {
		return c.vipMonitor.GetCurrentVIP()
	}
	return ""
}

func (c *Cluster) RebootSystem(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	go func() {
		// Reboot system outside of request after updating all the nodes
		if err := postGenericToAdminLast(c, routes.ClusterRebootEndpoint, c.rebootSystem); err != nil {
			// Log the error. Don't respond to client because it's async
			logging.GetLogger().Error("Failed to reboot system: %v", err)
		}
	}()

	w.WriteHeader(http.StatusNoContent)

}

func (c *Cluster) RebootSystemLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	if err := c.rebootSystem(); err != nil {
		logging.GetLogger().Error("Failed to reboot local system: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusAccepted)
}

func (c *Cluster) rebootSystem() error {
	if err := c.restartSystem(); err != nil {
		return err
	}

	return nil
}

// reboot the system...
func (c *Cluster) restartSystem() error {
	logger := logging.GetLogger()
	logger.Info("Rebooting Server in 5 seconds")

	// If running in local mode, skip reboot
	if c.appConfig != nil && c.appConfig.Local {
		logger.Info("Local mode enabled (appConfig.Local), skipping reboot.")
		return nil
	}

	if runtime.GOOS == "darwin" {
		// macOS: use goroutine with sleep since systemd-run doesn't exist
		go func() {
			time.Sleep(5 * time.Second)
			if err := exec.Command("reboot").Run(); err != nil {
				logger.Error("Failed to reboot: %v", err)
			}
		}()
		return nil
	}

	// Linux: use systemd-run for non-blocking delayed reboot
	return exec.Command("systemd-run", "--on-active=5s", "/usr/bin/systemctl", "reboot").Run()
}

// monitorState continuously monitors the cluster membership state
func (c *Cluster) startStateMonitor() {
	go func() {
		for {
			members := c.memberlist.Members()
			logger := logging.GetLogger()

			logger.Debug("[CLUSTER] Current cluster state:")
			logger.Debug("[CLUSTER] Total members: %d", len(members))

			for _, member := range members {
				status := "ALIVE"
				switch member.State {
				case hashicorpMemberlist.StateAlive:
					status = "ALIVE"
				case hashicorpMemberlist.StateSuspect:
					status = "SUSPECT"
				case hashicorpMemberlist.StateDead:
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
func getStateString(state hashicorpMemberlist.NodeStateType) string {
	switch state {
	case hashicorpMemberlist.StateAlive:
		return "ALIVE"
	case hashicorpMemberlist.StateSuspect:
		return "SUSPECT"
	case hashicorpMemberlist.StateDead:
		return "DEAD"
	default:
		return "UNKNOWN"
	}
}

// getClusterMembers returns the current list of cluster members
func (c *Cluster) getMembers() []ClusterMember {
	members := c.memberlist.Members()
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
			url := utils.GetLocalURL(addr, endpoint)
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
		if err := fetchAndDecode(c, addr, endpoint, &tmp); err != nil {
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
		if err := fetchAndDecode(c, addr, endpoint, &remoteSlice); err != nil {
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
	c *Cluster,
	addr, endpoint string,
	dest *T,
) error {
	resp, err := getLocalEndpointResponse(c, addr, endpoint)
	if err != nil {
		return err
	}
	return decodeSlice(resp.Body, dest)
}

func (c *Cluster) FetchGenericWithTargetDevice(
	deviceID string,
	endpointTemplate string,
	localFn func() ([]byte, error),
	remoteFn func(url string) ([]byte, error),
) ([]byte, error) {

	deviceInfos := c.GetAllDevicesInfo()

	var targetDevice *api.DeviceInfo
	for i := range deviceInfos {
		if deviceInfos[i].Id == deviceID {
			targetDevice = &deviceInfos[i]
			break
		}
	}
	if targetDevice == nil {
		return nil, fmt.Errorf("device %s not found", deviceID)
	}

	if c.hostIsLocal(targetDevice.Address) {
		return localFn()
	}

	deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
	endpoint := strings.Replace(endpointTemplate, "{id}", deviceID, 1)
	url := utils.GetLocalURL(deviceAddress, endpoint)

	return remoteFn(url)
}

func (c *Cluster) DoGenericToTargetDevice(
	deviceID string,
	endpointTemplate string,
	payload []byte,
	localFn func(payload []byte) error,
	remoteFn func(payload []byte, url string) error,
) error {
	deviceInfos := c.GetAllDevicesInfo()

	var targetDevice *api.DeviceInfo
	for i := range deviceInfos {
		if deviceInfos[i].Id == deviceID {
			targetDevice = &deviceInfos[i]
			break
		}
	}
	if targetDevice == nil {
		return fmt.Errorf("device %s not found", deviceID)
	}

	if c.hostIsLocal(targetDevice.Address) {
		return localFn(payload)
	}

	deviceAddress := net.JoinHostPort(targetDevice.Address, api.AdminPort)
	endpoint := strings.Replace(endpointTemplate, "{id}", deviceID, 1)
	url := utils.GetLocalURL(deviceAddress, endpoint)

	return remoteFn(payload, url)
}

// PostGenericToAdmin POSTs to an admin route on all nodes
func (c *Cluster) PostGenericToAdmin(
	endpoint string,
	localFn func() error,
) error {

	for _, addr := range c.getNodeAdminAddresses() {
		if c.hostIsLocal(addr) {
			// If this is the local address, invoke localFn() directly:
			if err := localFn(); err != nil {
				return fmt.Errorf("local function failed: %w", err)
			}
			continue
		}

		// POST to the remote node’s admin endpoint
		urlStr := utils.GetLocalURL(addr, endpoint)
		resp, err := http.Post(urlStr, "", nil)
		if err != nil {
			return err
		}
		resp.Body.Close()
	}

	return nil
}

func postGenericToAdminLast(
	c *Cluster,
	endpoint string,
	localFn func() error,
) error {
	for _, addr := range c.getNodeAdminAddresses() {
		if c.hostIsLocal(addr) {
			continue
		}

		// POST to the remote node’s admin endpoint
		urlStr := utils.GetLocalURL(addr, endpoint)
		resp, err := http.Post(urlStr, "", nil)
		if err != nil {
			logging.GetLogger().Error("POST to %s failed: %v", urlStr, err)
			return err
		}
		if resp.StatusCode == http.StatusNotFound {
			logging.GetLogger().Warn("POST to %s returned 404 Not Found", urlStr)
		} else {
			logging.GetLogger().Info("POST to %s succeeded with status %d", urlStr, resp.StatusCode)
		}
		resp.Body.Close()
	}

	// Invoke local function only after all remote nodes were posted.
	if err := localFn(); err != nil {
		logging.GetLogger().Error("Local function for endpoint %s failed: %v", endpoint, err)
		return fmt.Errorf("local function failed: %w", err)
	}

	return nil
}

// getLocalEndpointResponse calls a endpoint
func getLocalEndpointResponse(c *Cluster, addr, endpoint string) (response *http.Response, err error) {

	url := utils.GetLocalURL(addr, endpoint)
	resp, err := c.httpClient.Get(url)
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
		if addrErr, ok := err.(*net.AddrError); ok &&
			strings.Contains(addrErr.Err, "missing port in address") {
			host = addr
		} else {
			logging.GetLogger().Error("Error splitting host and port for address %q: %v", addr, err)
			return false
		}
	}
	return host == c.LocalNode().Addr.String()
}

// isLocalNodePrimary checks if this node is the primary (VIP holder)
func (c *Cluster) isLocalNodePrimary() bool {

	if c.vipMonitor != nil {
		return c.vipMonitor.IsLocalVIPHolder()
	}

	return false
}
