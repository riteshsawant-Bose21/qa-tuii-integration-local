package cluster

import (
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/server"
	"fusion/internal/utils"
	"net/http"
	"sync"

	"github.com/hashicorp/memberlist"
)

type Cluster struct {
	nodeName     string
	bindAddr     string
	bindPort     int
	StateManager *server.StateManager
	Persistence  *server.Persistence
	Updater      *server.Updater
	Memberlist   *memberlist.Memberlist
	vip          string
	vipLock      sync.RWMutex
}

func NewCluster(nodeName string, bindAddr string, bindPort int, stateManager *server.StateManager, persistence *server.Persistence, updater *server.Updater, verbose bool) *Cluster {

	logger := logging.GetLogger()

	memberlist, err := CreateMemberlist(nodeName, bindAddr, bindPort, stateManager, persistence, updater, verbose)
	if err != nil {
		logger.Fatal("Failed to create memberlist: %v", err)
	}

	cluster := &Cluster{
		nodeName:     nodeName,
		bindAddr:     bindAddr,
		bindPort:     bindPort,
		StateManager: stateManager,
		Persistence:  persistence,
		Updater:      updater,
		Memberlist:   memberlist,
	}

	err = cluster.startVRRPListener()
	if err != nil {
		logger.Fatal("Failed to start VRRP listener: %v", err)
	}

	return cluster
}

func (c *Cluster) GetEndpoints(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(w, r) {
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
		Metrics:   c.vip + api.MetricsPort,
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
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
	})

	if err != nil {
		return fmt.Errorf("unable to start keepalived listener: %v", err)
	}

	return nil
}
