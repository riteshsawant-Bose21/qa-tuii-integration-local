//go:build linux
// +build linux

package cluster

import (
	"fusion/internal/logging"

	"github.com/vishvananda/netlink"
)

const updateChannels = 16

func (c *Cluster) watchLocalVIP() {
	logger := logging.GetLogger()

	expectedVIP, err := c.getVIPFromConfig()
	if err != nil {
		logger.Error("Failed to get VIP from config: %v", err)
		return
	}

	addrs, err := netlink.AddrList(nil, netlink.FAMILY_ALL)
	if err == nil {
		for _, a := range addrs {
			if a.IP.String() == expectedVIP {
				logger.Info("VIP present at startup: %s", expectedVIP)
				c.listenerUpdated(expectedVIP, c.bindAddr)
				c.notifyLocalVIPChange(true)
				break
			}
		}
	} else {
		logger.Error("AddrList in startup scan failed: %v", err)
	}

	updates := make(chan netlink.AddrUpdate, updateChannels)
	done := make(chan struct{})

	if err := netlink.AddrSubscribeWithOptions(updates, done, netlink.AddrSubscribeOptions{
		ErrorCallback: func(e error) {
			logger.Error("netlink subscription callback error: %v", e)
		},
	}); err != nil {
		logger.Error("AddrSubscribeWithOptions failed: %v", err)
		return
	}

	for update := range updates {
		ip := update.LinkAddress.IP
		if ip == nil || ip.To4() == nil {
			continue
		}
		theIP := ip.String()

		if update.NewAddr {
			logger.Debug("Local VIP appeared: %s", theIP)
			c.listenerUpdated(theIP, c.bindAddr)
		} else {
			logger.Debug("Local VIP removed: %s", theIP)
			if c.isLocalVIP(theIP) {
				c.listenerUpdated("", c.bindAddr)
			}
		}
	}

	logger.Warn("netlink updates channel closed")
}
