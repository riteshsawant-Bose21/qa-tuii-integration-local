package cluster

import (
	"fmt"
	coreNetwork "fusion-services-core/network"
	"fusion-services-core/vip"

	"fusion/internal/api"
	"fusion-services-core/logging"
	"fusion/internal/routes"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	json "github.com/goccy/go-json"
	"github.com/hashicorp/memberlist"
)

const (
	configPath           = "/etc/keepalived/" + vip.DefaultConfFile
	statusUpdateInterval = 30 * time.Second
	monitorInterval      = 10 * time.Second
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
	Memberlist       *memberlist.Memberlist
	vip              string
	vipHolder        string
	vipLock          sync.RWMutex
	configPath       string
	Metrics          *MetricsCollector
	networkLatencies *NetworkLatencyStore
	vipMu            sync.Mutex
	mdnsManager      *network.MDNSManager
}

func NewCluster(appConfig *api.AppConfig, delegate *ClusterDelegate, memberlist *memberlist.Memberlist, mdnsManager *network.MDNSManager) *Cluster {

	cluster := &Cluster{
		appConfig:        appConfig,
		delegate:         delegate,
		httpClient:       &http.Client{Timeout: api.HTTPTimeout},
		Memberlist:       memberlist,
		configPath:       configPath,
		Metrics:          NewMetricsCollector(memberlist, delegate.stateManager),
		networkLatencies: NewNetworkLatencyStore(maxLatencyCount, latencyPruneTime),
		mdnsManager:      mdnsManager,
	}

	logger := logging.GetLogger()

	if !cluster.appConfig.Local {

		if err := cluster.startVRRPListener(appConfig.NetIface); err != nil {
			logger.Fatal("startVRRPListener: %v", err)
		}

		vipValue, multiple, err := vip.ReadFromKeepalivedConfig(cluster.configPath)
		if err != nil {
			logger.Fatal("read keepalived config: %v", err)
		}
		if multiple {
			logger.Warn("More than one VIP found.")
		}

		canonical := vip.Canonicalize(vipValue)
		cluster.vip = canonical
	}

	if err := cluster.JoinMemberlist(); err != nil {
		logger.Error("initial JoinMemberlist: %v", err)
	}

	cluster.updateDeviceInfo()

	go cluster.initialAudioSync()
	go cluster.startStateMonitor()
	go cluster.startNetworkLatencyProbes()

	return cluster
}

func (c *Cluster) Stop() {
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

func (c *Cluster) SetMemberlist(memberlist *memberlist.Memberlist) {
	c.Memberlist = memberlist
	if err := c.JoinMemberlist(); err != nil {
		logging.GetLogger().Error("Unable to join after setting memberlist: %v", err)
	}
	c.Metrics.SetMemberlist(memberlist)
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

// listenerUpdated is called when VRRP state changes
func (c *Cluster) listenerUpdated(vipAddr, srcIP string) {

	logger := logging.GetLogger()

	newVIP := vip.Canonicalize(vipAddr)

	c.vipLock.Lock()
	defer c.vipLock.Unlock()

	oldVIP := c.vip
	oldHolder := c.vipHolder
	logger.Debug("[CLUSTER] listenerUpdated called: oldVIP=%s oldHolder=%s vip=%s srcIP=%s",
		oldVIP, oldHolder, c.vip, srcIP,
	)

	// VIP has been removed entirely
	if newVIP == "" {
		if oldVIP == "" {
			// no change
			logger.Warn("[CLUSTER] Both oldVIP and newVIP are empty - no change.")
			return
		}

		logger.Debug("[CLUSTER] VIP %s removed (old holder %s)", oldVIP, oldHolder)

		c.vip = ""
		c.vipHolder = ""

		c.notifyLocalVIPChange(false)
		if err := c.mdnsManager.Close(); err != nil {
			logger.Error("[Discovery] Failed to stop mDNS service: %v", err)
		} else {
			logger.Debug("[Discovery] mDNS service stopped successfully via manager")
		}
		return
	}

	if newVIP == oldVIP && srcIP == oldHolder {
		logger.Warn("listenerUpdated called but VIP state is unchanged.")
		return
	}

	// Determine ownership

	oldLocal, err := vip.IsLocalVIP(oldHolder)
	if err != nil {
		logger.Error("isLocalVIP(oldHolder): %v", err)
	}

	newLocal, err := vip.IsLocalVIP(srcIP)
	if err != nil {
		logger.Error("isLocalVIP(srcIP): %v", err)
	}

	// VIP address changed
	if newVIP != oldVIP {
		logger.Info("VIP changed: oldVIP=%s newVIP=%s", oldVIP, newVIP)
		if err := c.updateVIP(newVIP); err != nil {
			logger.Error("updateVIP(%q): %v", newVIP, err)
			return
		}

		if err := c.reloadVIP(); err != nil {
			logger.Error("reloadVIP: %v", err)
			return
		}

		// Parse the VIP string into net.IP before passing to mDNS manager
		if ip := net.ParseIP(newVIP); ip == nil {
			logger.Error("[Discovery] Invalid VIP %s for mDNS", newVIP)
		} else {
			if err := c.mdnsManager.StartWithVIP(ip); err != nil {
				logger.Error("[Discovery] Failed to start mDNS service: %v", err)
			}
		}
	}

	c.vip = newVIP
	c.vipHolder = srcIP

	logger.Debug("VIP update: oldVIP=%s newVIP=%s oldHolder=%s newHolder=%s oldLocal=%v newLocal=%v",
		oldVIP, newVIP, oldHolder, srcIP, oldLocal, newLocal)

	// Handle ownership transition
	switch {
	case oldLocal && !newLocal:
		logger.Info("VIP %s moved (was %s, now %s)", newVIP, oldHolder, srcIP)
		c.notifyLocalVIPChange(false)

		if err := c.mdnsManager.Close(); err != nil {
			logger.Error("[Discovery] Failed to stop mDNS service: %v", err)
		} else {
			logger.Debug("[Discovery] mDNS service stopped successfully via manager")
		}

	case !oldLocal && newLocal:
		logger.Debug("VIP %s gained locally (holder %s)", newVIP, srcIP)

		// Ensure we’re in the memberlist
		if member, err := c.isMember(); err != nil {
			logger.Error("isMember: %v", err)
		} else if !member {
			if err := c.JoinMemberlist(); err != nil {
				logger.Error("JoinMemberlist: %v", err)
			} else {
				logger.Info("Joined memberlist with VIP %s", newVIP)
			}
		}
		c.notifyLocalVIPChange(true)

		// Parse the VIP string into net.IP before passing to mDNS manager
		if ip := net.ParseIP(newVIP); ip == nil {
			logger.Error("[Discovery] Invalid VIP %s for mDNS", newVIP)
		} else {
			if err := c.mdnsManager.StartWithVIP(ip); err != nil {
				logger.Error("[Discovery] Failed to start mDNS service: %v", err)
			}
		}
	}
}

func (c *Cluster) startVRRPListener(iface string) error {

	if err := coreNetwork.StartVRRPListener(logging.GetLogger(), c.listenerUpdated); err != nil {
		return fmt.Errorf("unable to start keepalived listener: %v", err)
	}

	go c.watchLocalVIP(iface)

	return nil
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
				return fmt.Errorf("local function failed: %w", err)
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
func getLocalEndpointResponse(c *Cluster, addr, endpoint string) (response *http.Response, err error) {

	url := getLocalURL(addr, endpoint)
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
	return host == c.Memberlist.LocalNode().Addr.String()
}

// getLocalURL builds a full API URL to the endpoint
func getLocalURL(addr, endpoint string) string {
	return fmt.Sprintf("%s%s%s", api.Protocol, addr, endpoint)
}

func (c *Cluster) notifyLocalVIPChange(gained bool) {
	logger := logging.GetLogger()
	event := ternary(gained, vip.EventGained, vip.EventLost)

	if err := vip.SendLocalStatus(c.vip, c.appConfig.BindAddr, gained); err != nil {
		logger.Error("SendUDPMessage failed: %v", err)
		return
	}

	logger.Debug("Local VIP changed %s: %s. Notified localhost:%d", event, c.vip, vip.Port)
}

func ternary(cond bool, a, b string) string {
	if cond {
		return a
	}
	return b
}

func (c *Cluster) initialAudioSync() {
	peers := c.Memberlist.Members()
	if len(peers) <= 1 {
		return
	}

	var peer *memberlist.Node
	for _, p := range peers {
		if p.Name != c.Memberlist.LocalNode().Name {
			peer = p
			break
		}
	}

	if peer != nil {
		_ = c.initialAudioSyncFromPeer(peer)
	}

	c.reconcileLocalAudioState()
}

func (c *Cluster) initialAudioSyncFromPeer(peer *memberlist.Node) error {
	logger := logging.GetLogger()

	url := fmt.Sprintf("http://%s:%s%s", peer.Addr, api.HTTPPort, routes.PAVAMessagesEndpoint)

	resp, err := http.Get(url)
	if err != nil {
		return fmt.Errorf("messages fetch: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("metadata list error: %d %s", resp.StatusCode, string(body))
	}

	var metas []api.AudioMetadata
	if err := json.NewDecoder(resp.Body).Decode(&metas); err != nil {
		return fmt.Errorf("decode metadata: %w", err)
	}

	peerURL := fmt.Sprintf("http://%s:%s", peer.Addr, api.HTTPPort)

	for _, meta := range metas {
		update := api.AudioSyncUpdate{
			Metadata: meta,
			URL:      peerURL,
		}
		if err := c.delegate.persistence.SyncAudioFile(&update); err != nil {
			logger.Error("initial sync failed for %s: %v", meta.Filename, err)
		}
	}

	return nil
}

// reconcileLocalAudioState reconciles audio files and metadata
func (c *Cluster) reconcileLocalAudioState() {
	logger := logging.GetLogger()

	metas, err := c.delegate.persistence.ListAudioMetadata()
	if err != nil {
		logger.Error("Audio reconciliation: failed to list metadata: %v", err)
		return
	}

	metaByFilename := make(map[string]*api.AudioMetadata, len(metas))
	for _, m := range metas {
		metaByFilename[m.Filename] = m
	}

	files, err := os.ReadDir(api.AudioFilesLocation)
	if err != nil {
		logger.Error("Audio reconciliation: failed to read audio directory: %v", err)
		return
	}

	fileSet := make(map[string]bool, len(files))
	for _, f := range files {
		if !f.IsDir() {
			fileSet[f.Name()] = true
		}
	}

	// Remove metadata whose files do not exist on disk
	for _, m := range metas {
		if !fileSet[m.Filename] {
			logger.Warn("Audio reconciliation: removing stale metadata for %s", m.Filename)
			if err := c.delegate.persistence.DeleteAudioMetadata(m.Id); err != nil {
				logger.Error("Failed to delete stale metadata %s: %v", m.Id, err)
			}
		}
	}

	// Remove files on disk with no metadata entry
	for file := range fileSet {
		if _, ok := metaByFilename[file]; !ok {
			full := filepath.Join(api.AudioFilesLocation, file)
			logger.Warn("Audio reconciliation: removing orphaned file %s", file)
			if err := os.Remove(full); err != nil && !os.IsNotExist(err) {
				logger.Error("Failed to delete orphaned file %s: %v", file, err)
			}
		}
	}
}
