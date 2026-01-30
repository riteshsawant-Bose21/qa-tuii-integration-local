//go:build linux
// +build linux

package cluster

import (
	"fusion-services-core/vip"
	"fusion/internal/logging"
	"net"

	"github.com/vishvananda/netlink"
)

const updateChannels = 16

func (c *Cluster) watchLocalVIP(iface string) {
	logger := logging.GetLogger()
	expectedVIP, multiple, err := vip.ReadFromKeepalivedConfig(c.configPath)
	if err != nil {
		logger.Error("Failed to get VIP from config: %v", err)
		return
	}
	if multiple {
		logger.Warn("More than one VIP found.")
	}
	expectedVIP = vip.Canonicalize(expectedVIP)

	// Watch only the correct interface
	link, err := netlink.LinkByName(iface)
	if err != nil {
		logger.Error("VIP watcher: interface %s not found: %v", iface, err)
		return
	}

	// Initial scan
	addrs, _ := netlink.AddrList(link, netlink.FAMILY_V4)
	for _, a := range addrs {
		if vip.Canonicalize(a.IP.String()) == expectedVIP {
			logger.Info("VIP present at startup: %s", expectedVIP)
			c.listenerUpdated(expectedVIP, c.appConfig.BindAddr)
			c.notifyLocalVIPChange(true)
			break
		}
	}

	updates := make(chan netlink.AddrUpdate, updateChannels)
	done := make(chan struct{})

	if err := netlink.AddrSubscribeWithOptions(
		updates, done,
		netlink.AddrSubscribeOptions{ErrorCallback: func(e error) {
			logger.Error("netlink error: %v", e)
		}},
	); err != nil {
		logger.Error("AddrSubscribe failed: %v", err)
		return
	}

	_, vipNet, _ := net.ParseCIDR("192.168.64.0/24")

	for update := range updates {
		ip := update.LinkAddress.IP
		if ip == nil || ip.To4() == nil || !vipNet.Contains(ip) {
			continue
		}
		theIP := vip.Canonicalize(ip.String())

		if theIP != expectedVIP {
			continue
		}

		if update.NewAddr {
			logger.Info("Local VIP appeared: %s", theIP)
			c.listenerUpdated(theIP, c.appConfig.BindAddr)
		} else {
			logger.Info("Local VIP removed: %s", theIP)
			c.listenerUpdated("", c.appConfig.BindAddr)
		}
	}

	logger.Warn("netlink updates channel closed")
}
