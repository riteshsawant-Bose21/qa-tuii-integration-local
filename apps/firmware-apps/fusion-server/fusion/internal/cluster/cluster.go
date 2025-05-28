package cluster

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/network"
	"net"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/hashicorp/memberlist"
)

const (
	checkInterval   = 30 * time.Second
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
		Memberlist:       memberlist,
		configPath:       "/etc/keepalived/keepalived.conf",
		Metrics:          NewMetricsCollector(memberlist, delegate.stateManager),
		networkLatencies: NewNetworkLatencyStore(maxLatencyCount, latencyPruneTime),
	}

	if !appConfig.Local {
		logger := logging.GetLogger()

		if err := cluster.startVRRPListener(); err != nil {
			logger.Fatal("Failed to start VRRP listener: %v", err)
		}

		vips, err := cluster.getVIPFromConfig()
		if err != nil {
			logger.Fatal("Failed to get VIP: %v", err)
		}

		for _, vip := range vips {
			if _, isVip := cluster.isLocalVIP(vip); isVip {
				if err := cluster.delegate.taskManager.Start(); err != nil {
					logger.Fatal("Failed to start TaskManger: %v", err)
				} else {
					logger.Info("TaskManager running on: %s", appConfig.NodeName)
				}
				break
			}
		}
	}

	go cluster.startStateMonitor()
	go cluster.startNetworkLatencyProbes()

	return cluster
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

func (c *Cluster) startVRRPListener() error {
	err := network.StartVRRPListener(func(vip string) {

		logger := logging.GetLogger()
		logger.Info("New VIP detected: %s", vip)

		c.vipLock.Lock()
		c.vip = vip
		c.vipLock.Unlock()

		member, err := c.IsMember()
		if err != nil {
			logger.Error("IsMember error: %v", err)
		}

		if member {
			logger.Info("%s already a member", c.nodeName)
		} else {
			err = c.JoinMemberlist()
			if err != nil {
				logger.Error("Unable to rejoin memberlist: %v", err)
			} else {
				logger.Info("%s[%s] joined memberlist with VIP: %s", c.nodeName, c.bindAddr, c.vip)
			}
		}
	})

	if err != nil {
		return fmt.Errorf("unable to start keepalived listener: %v", err)
	}

	return nil
}

// isLocalVIP compares the expected VIP (which might be in CIDR format) to the IPs on local interfaces.
func (c *Cluster) isLocalVIP(vip string) (net.Addr, bool) {

	// Try to parse the vip as CIDR and use just the IP portion.
	expectedIP, _, err := net.ParseCIDR(vip)
	if err != nil {
		// If not in CIDR, assume vip is a plain IP address.
		expectedIP = net.ParseIP(vip)
		if expectedIP == nil {
			return nil, false
		}
	}

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return nil, false
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.Equal(expectedIP) {
				return addr, true
			}
		}
	}

	return nil, false
}

func (c *Cluster) getVIPFromConfig() ([]string, error) {
	// Read the file
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

// monitorState continuously monitors the cluster membership state
func (c *Cluster) startStateMonitor() {
	go func() {
		for {
			members := c.Memberlist.Members()
			logger := logging.GetLogger()

			logger.Info("[CLUSTER] Current cluster state:")
			logger.Info("[CLUSTER] Total members: %d", len(members))

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

				logger.Info("[CLUSTER] Node: %s, Address: %s:%d, Status: %s",
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
