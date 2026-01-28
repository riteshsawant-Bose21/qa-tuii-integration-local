package cluster

import (
	"fusion/internal/logging"
	"net"
)

// MDNS watcher for local VIP changes
// handleMDNSLifecycleWithVIP manages mDNS service creation/destruction with a provided VIP
// this is used for Frontend VIP discovery and not the cluster inter discovery. For that please see VRRP.
func (c *Cluster) handleMDNSLifecycleWithVIP(start bool, currentVIP net.IP) {
	logger := logging.GetLogger()

	logger.Debug("[Cluster Discovery] starting = %v, on VIP=%s", start, currentVIP)
	if currentVIP == nil || currentVIP.IsUnspecified() {
		logger.Error("[Cluster Discovery] Cannot start mDNS service - VIP is empty")
		return
	}

	if c.mdnsManager == nil {
		logger.Warn("[Cluster Discovery] No mDNS manager configured - skipping mDNS lifecycle")
		return
	}

	if c.mdnsManager.IsRunning() {
		logger.Warn("[Cluster Discovery] services already running, skipping duplicate registration")
		return
	}

	if start {
		if err := c.mdnsManager.StartWithVIP(currentVIP); err != nil {
			logger.Error("[Cluster Discovery] Failed to start mDNS service: %v", err)
		}
	} else {
		if err := c.mdnsManager.Stop(); err != nil {
			logger.Error("[Cluster Discovery] Failed to stop mDNS service: %v", err)
		} else {
			logger.Debug("[Cluster Discovery] mDNS service stopped successfully via manager")
		}
	}
}
