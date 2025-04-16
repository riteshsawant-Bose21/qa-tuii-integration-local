package cluster

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/utils"
	"net"
	"net/http"
	"os"
	"regexp"
	"strings"
	"sync"

	"github.com/hashicorp/memberlist"
)

type Cluster struct {
	nodeName   string
	bindAddr   string
	bindPort   int
	delegate   *ClusterDelegate
	Memberlist *memberlist.Memberlist
	vip        string
	vipLock    sync.RWMutex
	configPath string
}

func NewCluster(appConfig *api.AppConfig, delegate *ClusterDelegate, memberlist *memberlist.Memberlist) *Cluster {

	logger := logging.GetLogger()

	cluster := &Cluster{
		nodeName:   appConfig.NodeName,
		bindAddr:   appConfig.BindAddr,
		bindPort:   appConfig.BindPort,
		delegate:   delegate,
		Memberlist: memberlist,
		configPath: "/etc/keepalived/keepalived.conf",
	}

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

	return cluster
}

func (c *Cluster) GetEndpoints(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	clusterAddresses := c.getClusterIPs()
	var addressesWithPort []string
	for _, addr := range clusterAddresses {
		addressesWithPort = append(addressesWithPort, addr+api.ZMQPort)
	}

	endpoints := api.Endpoints{
		API:       c.vip + api.HTTPPort,
		Telemetry: addressesWithPort,
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(endpoints)
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

		// Start the task manager if we are the holder of the VIP
		if addr, isVip := c.isLocalVIP(vip); isVip {
			if err := c.delegate.taskManager.Start(); err != nil {
				logging.GetLogger().Fatal("Error starting TaskManager: %v", err)
			}
			logger.Info("TaskManager running on: %s", addr.String())
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
