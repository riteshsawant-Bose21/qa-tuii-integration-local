//go:build linux
// +build linux

package cluster

import (
	"fusion/internal/logging"

	"github.com/vishvananda/netlink"
)

func (c *Cluster) watchLocalVIP() {
	logger := logging.GetLogger()

	addrs, err := netlink.AddrList(nil, netlink.FAMILY_ALL)
	if err == nil {
		for _, a := range addrs {
			if a.IP.String() == c.vip {
				logger.Info("Detected VIP present at startup: %s", c.vip)
				c.listenerUpdated(c.vip, c.bindAddr)
				break
			}
		}
	} else {
		logger.Error("AddrList in startup scan failed: %v", err)
	}

	updates := make(chan netlink.AddrUpdate, 16)
	done := make(chan struct{})

	if err := netlink.AddrSubscribeWithOptions(updates, done, netlink.AddrSubscribeOptions{
		ErrorCallback: func(e error) {
			logger.Error("netlink subscription callback error: %v", e)
		},
	}); err != nil {
		logger.Error("AddrSubscribeWithOptions failed: %v", err)
		return
	}

	for {
		for {
			update, ok := <-updates
			if !ok {
				logger.Error("netlink updates channel closed")
				return
			}
			ip := update.LinkAddress.IP.String()
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
}
