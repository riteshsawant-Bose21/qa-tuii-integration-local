//go:build linux
// +build linux

package cluster

import (
	"fusion-services-core/vip"
	"fusion/internal/logging"

	"github.com/vishvananda/netlink"
)

const updateChannels = 16

func (c *Cluster) watchLocalVIP(iface string) {
	logger := logging.GetLogger()

	logger.Debug("[VIP watcher] Starting VIP on Linux watcher on interface: %s", iface)
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
		logger.Error("[VIP watcher] interface %s not found: %v", iface, err)
		return
	}

	// Initial scan to detect VIP at startup.
	addrs, err := netlink.AddrList(link, netlink.FAMILY_V4)
	if err != nil {
		logger.Error("[VIP watcher] failed to list addresses: %v", err)
		return
	}
	for _, a := range addrs {

		if vip.Canonicalize(a.IP.String()) == expectedVIP {
			logger.Info("[VIP watcher] VIP present at startup: %s", expectedVIP)
			c.listenerUpdated(expectedVIP, c.appConfig.BindAddr)
			break
		}
	}

	go func() {
		updates := make(chan netlink.AddrUpdate, updateChannels)
		done := make(chan struct{})

		defer func() {
			close(done)
			logger.Debug("[VIP watcher] watcher goroutine exited")
		}()

		if err := netlink.AddrSubscribeWithOptions(
			updates, done,
			netlink.AddrSubscribeOptions{
				ErrorCallback: func(e error) {
					logger.Error("[VIP watcher] netlink error: %v", e)
				},
				ListExisting: false, //first scan done above
			},
		); err != nil {
			logger.Error("[VIP watcher] AddrSubscribe failed: %v", err)
			return
		}

		for {
			select {
			case <-done:
				return
			case update, ok := <-updates:
				if !ok {
					logger.Warn("[VIP watcher] netlink updates channel closed")
					return
				}

				//Since there was an update, check for new expected VIP
				expectedVIP, multiple, err := vip.ReadFromKeepalivedConfig(c.configPath)
				if err != nil {
					logger.Error("[VIP watcher] Failed to get VIP from config: %v", err)
					return
				}
				if multiple {
					logger.Warn("More than one VIP found.")
				}
				expectedVIP = vip.Canonicalize(expectedVIP)

				ip := update.LinkAddress.IP
				if ip == nil || ip.To4() == nil {
					continue
				}
				theIP := vip.Canonicalize(ip.String())
				logger.Debug("[VIP watcher] received update for IP: %s", theIP)
				logger.Debug("[VIP watcher] expected VIP: %s", expectedVIP)
				logger.Debug("[VIP watcher] theIP: %s", theIP)
				logger.Debug("[VIP watcher] NewAddr: %v", update.NewAddr)

				if theIP != expectedVIP {
					continue
				}

				if update.NewAddr {
					logger.Info("[VIP watcher] Local VIP appeared: %s", theIP)
					c.listenerUpdated(theIP, c.appConfig.BindAddr)
				} else {
					logger.Info("[VIP watcher] Local VIP removed: %s", theIP)
					c.listenerUpdated("", c.appConfig.BindAddr)
				}
			}
		}
	}()
}
