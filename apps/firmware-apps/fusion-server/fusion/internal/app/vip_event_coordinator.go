package app

import (
	"fusion-services-core/logging"
	"fusion-services-core/vip"
	vipmonitor "fusion/internal/vip_monitor"
	"sync"
)

type VIPEventCoordinator struct {
	app *App
	mu  sync.Mutex
}

func NewVIPEventCoordinator(app *App) *VIPEventCoordinator {
	return &VIPEventCoordinator{app: app}
}

func (c *VIPEventCoordinator) Handle(event vipmonitor.VIPEvent) {
	c.mu.Lock()
	defer c.mu.Unlock()

	logger := logging.GetLogger()

	logger.Debug("[VIP] State change: type=%s vip=%s holder=%s isLocal=%v",
		event.EventType, event.VIP, event.Holder, event.IsLocalOwner)

	if event.VIP == "" {
		logger.Fatal("VIP event has VIP empty")
		return
	}

	if member, err := c.app.Cluster.IsMember(); err != nil {
		logger.Error("isMember: %v", err)
	} else if !member {
		if err := c.app.Cluster.JoinMemberlist(); err != nil {
			logger.Error("JoinMemberlist: %v", err)
		} else {
			logger.Info("Joined memberlist with VIP %s", event.VIP)
		}
	}

	switch event.EventType {
	case vipmonitor.EventGainedOnLocalInterface:
		if c.isStaleLocalVIPEvent(event) {
			logger.Debug("[VIP] Ignoring stale local gain event for vip=%s holder=%s", event.VIP, event.Holder)
			return
		}
		logger.Debug("VIP %s gained locally", event.VIP)
		if err := vip.SendLocalStatus(event.VIP, c.app.config.BindAddr, true); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}
		if c.app.discoveryReconciler.ShouldSuppressLocalGainMDNS(event.VIP) {
			logger.Debug("[Discovery] Skipping duplicate local gain mDNS start for VIP %s after address change", event.VIP)
			return
		}
		c.app.discoveryReconciler.RequestReconcile("event_gained_on_local_interface")

	case vipmonitor.EventLostOnLocalInterface:
		if c.isStaleLocalVIPEvent(event) {
			logger.Debug("[VIP] Ignoring stale local loss event for vip=%s oldHolder=%s", event.VIP, event.OldHolder)
			return
		}
		logger.Info("VIP %s lost", event.VIP)
		if err := vip.SendLocalStatus(event.VIP, event.Holder, false); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}
		c.app.discoveryReconciler.RequestReconcile("event_lost_on_local_interface")

	case vipmonitor.EventGainedOnVRRPUpdate:
		logger.Info("VIP %s gained (VRRP update), holder=%s", event.VIP, event.Holder)
		if err := vip.SendLocalStatus(event.VIP, c.app.config.BindAddr, true); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}
		c.app.discoveryReconciler.RequestReconcile("event_gained_on_vrrp_update")

	case vipmonitor.EventLostOnVRRPUpdate:
		if c.shouldIgnoreRemoteVIPEvent(event) {
			logger.Debug("[VIP] Ignoring stale remote VRRP loss event for vip=%s holder=%s", event.VIP, event.Holder)
			return
		}
		logger.Debug("VIP %s lost (VRRP update), holder=%s", event.VIP, event.Holder)
		if err := vip.SendLocalStatus(event.VIP, event.Holder, false); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}
		c.app.discoveryReconciler.RequestReconcile("event_lost_on_vrrp_update")

	case vipmonitor.EventMovedOnVRRPUpdate:
		if c.shouldIgnoreRemoteVIPEvent(event) {
			logger.Debug("[VIP] Ignoring stale remote VRRP move event for vip=%s holder=%s", event.VIP, event.Holder)
			return
		}
		logger.Debug("VIP %s moved from %s to %s", event.VIP, event.OldHolder, event.Holder)
		if err := vip.SendLocalStatus(event.VIP, event.Holder, false); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}
		c.app.discoveryReconciler.RequestReconcile("event_moved_on_vrrp_update")

	case vipmonitor.EventAddressChanged:
		logger.Info("VIP address changed from %s to %s (localOwner=%v holder=%s oldHolder=%s)",
			event.OldVIP, event.VIP, event.IsLocalOwner, event.Holder, event.OldHolder)
		if event.IsLocalOwner {
			c.app.discoveryReconciler.RecordLocalAddressChange(event.VIP)
			if err := vip.SendLocalStatus(event.VIP, c.app.config.BindAddr, true); err != nil {
				logger.Error("Failed to send UDP status: %v", err)
			}
			c.app.discoveryReconciler.RequestReconcile("event_address_changed_local")
			return
		}
		logger.Debug("[VIP] Ignoring remote VIP address change event for discovery authority: oldVIP=%s newVIP=%s holder=%s",
			event.OldVIP, event.VIP, event.Holder)
		if c.shouldIgnoreRemoteVIPEvent(event) {
			logger.Debug("[VIP] Ignoring stale remote VIP address change for vip=%s holder=%s", event.VIP, event.Holder)
			return
		}
		if err := vip.SendLocalStatus(event.VIP, event.Holder, false); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}
		c.app.discoveryReconciler.RequestReconcile("event_address_changed_remote")

	case vipmonitor.EventVIPHolderChanged:
		logger.Debug("VIP %s holder changed from %s to %s", event.VIP, event.OldHolder, event.Holder)
		c.app.discoveryReconciler.RequestReconcile("event_vip_holder_changed")
	}
}

func (c *VIPEventCoordinator) isStaleLocalVIPEvent(event vipmonitor.VIPEvent) bool {
	currentVIP := c.app.VIPMonitor.GetCurrentVIP()
	currentHolder := c.app.VIPMonitor.GetVIPHolder()
	isLocalOwner := c.app.VIPMonitor.IsLocalVIPHolder()

	switch event.EventType {
	case vipmonitor.EventGainedOnLocalInterface:
		if currentVIP != event.VIP {
			return true
		}
		if !isLocalOwner {
			return true
		}
		if event.Holder != "" && currentHolder != "" && currentHolder != event.Holder {
			return true
		}
	case vipmonitor.EventLostOnLocalInterface:
		if currentVIP != event.VIP {
			return true
		}
		if isLocalOwner {
			return true
		}
	}

	return false
}

func (c *VIPEventCoordinator) shouldIgnoreRemoteVIPEvent(event vipmonitor.VIPEvent) bool {
	if event.IsLocalOwner {
		return false
	}
	return c.app.VIPMonitor.IsLocalVIPHolder()
}
