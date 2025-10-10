//go:build linux
// +build linux

package cluster

import (
	"fusion/internal/logging"

	"github.com/vishvananda/netlink"
)

func (c *Cluster) watchLocalVIP() {
	logger := logging.GetLogger()

	updates := make(chan netlink.AddrUpdate)
	done := make(chan struct{})

	if err := netlink.AddrSubscribe(updates, done); err != nil {
		logger.Error("netlink.AddrSubscribe failed: %v", err)
		return
	}

	logger.Info("Started watching local VIP changes via netlink")
	logger.Info("About to enter updates loop")

	for {
		update, ok := <-updates
		if !ok {
			logger.Error("netlink updates channel closed unexpectedly")
			return
		}

		// Debug: print everything
		logger.Debug("Received netlink update: %+v", update)

		ip := update.LinkAddress.IP.String()
		// Skip events for other IPs
		if ip == c.vip {
			if update.NewAddr {
				logger.Info("Local VIP appeared: %s", ip)
				c.listenerUpdated(ip, c.bindAddr)
			} else {
				logger.Info("Local VIP removed: %s", ip)
				c.listenerUpdated("", c.bindAddr)
			}
		}
	}
}
