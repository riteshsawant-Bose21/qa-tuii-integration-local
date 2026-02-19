package network

import (
	"net"

	"github.com/vishvananda/netlink"
)

const updateChannels = 16

func StartLocalVIPWatcher(logger Logger, iface string, expectedVIP net.IPNet, onUpdate func(vip string, srcIP string)) error {
	logger.Debug("[VIP watcher] Starting VIP watcher on interface: %s for VIP: %s", iface, expectedVIP)

	// Watch only the correct interface
	link, err := netlink.LinkByName(iface)
	if err != nil {
		logger.Error("[VIP watcher] interface %s not found: %v", iface, err)
		return err
	}
	linkIndex := link.Attrs().Index

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
				ListExisting: true, // Sends existing addresses as NewAddr events
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
					logger.Error("[VIP watcher] netlink updates channel closed")
					return
				}

				// Filter to only our interface
				if update.LinkIndex != linkIndex {
					continue
				}

				ip := update.LinkAddress.IP
				if ip == nil || ip.To4() == nil {
					continue
				}

				logger.Debug("[VIP watcher] received update for IP: %s, NewAddr: %v", ip, update.NewAddr)

				if !expectedVIP.Contains(ip) {
					continue
				}

				if update.NewAddr {
					logger.Info("[VIP watcher] VIP gained: %s", ip)
					onUpdate(ip.String(), getInterfacePrimaryIP(link))
				} else {
					logger.Info("[VIP watcher] VIP lost: %s", ip)
					onUpdate("", "")
				}
			}
		}
	}()

	return nil
}

// getInterfacePrimaryIP returns the first non-VIP IPv4 address on the interface
func getInterfacePrimaryIP(link netlink.Link) string {
	addrs, err := netlink.AddrList(link, netlink.FAMILY_V4)
	if err != nil || len(addrs) == 0 {
		return ""
	}
	// Return first address (typically the primary IP)
	for _, a := range addrs {
		if a.IP != nil && a.IP.To4() != nil {
			return a.IP.String()
		}
	}
	return ""
}
