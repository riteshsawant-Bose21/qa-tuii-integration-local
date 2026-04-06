package app

import (
	"fmt"
	"net"
	"sync"
	"time"
)

type DiscoveryReconciler struct {
	app *App

	mu               sync.Mutex
	reconcileCh      chan string
	stopCh           chan struct{}
	wg               sync.WaitGroup
	lastMode         string
	lastVIP          string
	lastAddressVIP   string
	lastAddressUntil time.Time
}

type DiscoverySnapshot struct {
	Mode             string
	VIP              string
	LastAddressVIP   string
	LastAddressUntil time.Time
}

func NewDiscoveryReconciler(app *App) *DiscoveryReconciler {
	return &DiscoveryReconciler{
		app:         app,
		reconcileCh: make(chan string, 1),
		stopCh:      make(chan struct{}),
	}
}

func (r *DiscoveryReconciler) Start() {
	r.wg.Add(1)
	go func() {
		defer r.wg.Done()

		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-r.stopCh:
				return
			case reason := <-r.reconcileCh:
				if err := r.reconcile(reason); err != nil {
					r.app.Logger.Error("[Discovery] reconcile failed: %v", err)
				}
			case <-ticker.C:
				if err := r.reconcile("periodic"); err != nil {
					r.app.Logger.Error("[Discovery] periodic reconcile failed: %v", err)
				}
			}
		}
	}()
}

func (r *DiscoveryReconciler) Stop() {
	select {
	case <-r.stopCh:
	default:
		close(r.stopCh)
	}
	r.wg.Wait()
}

func (r *DiscoveryReconciler) RequestReconcile(reason string) {
	select {
	case r.reconcileCh <- reason:
	default:
	}
}

func (r *DiscoveryReconciler) RecordLocalAddressChange(vip string) {
	r.mu.Lock()
	defer r.mu.Unlock()

	r.lastAddressVIP = vip
	r.lastAddressUntil = time.Now().Add(3 * time.Second)
}

func (r *DiscoveryReconciler) ShouldSuppressLocalGainMDNS(vip string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()

	if r.lastAddressVIP != vip {
		return false
	}
	if time.Now().After(r.lastAddressUntil) {
		r.lastAddressVIP = ""
		r.lastAddressUntil = time.Time{}
		return false
	}

	r.lastAddressVIP = ""
	r.lastAddressUntil = time.Time{}
	return true
}

func (r *DiscoveryReconciler) Snapshot() DiscoverySnapshot {
	r.mu.Lock()
	defer r.mu.Unlock()

	return DiscoverySnapshot{
		Mode:             r.lastMode,
		VIP:              r.lastVIP,
		LastAddressVIP:   r.lastAddressVIP,
		LastAddressUntil: r.lastAddressUntil,
	}
}

func (r *DiscoveryReconciler) reconcile(reason string) error {
	// snapshot short-lived state under lock, release for long operations
	r.mu.Lock()
	currentMode := r.lastMode
	currentVIPState := r.lastVIP
	r.mu.Unlock()

	currentVIP := r.app.VIPMonitor.GetCurrentVIP()
	isLocalOwner := r.app.VIPMonitor.IsLocalVIPHolder()
	bindAddr := r.app.config.BindAddr

	mode := "remote"
	targetVIP := currentVIP
	if currentVIP == "" {
		mode = "bind"
		targetVIP = bindAddr
	} else if isLocalOwner {
		mode = "vip"
	}

	changed := currentMode != mode || currentVIPState != targetVIP
	logger := r.app.Logger

	switch {
	case currentVIP == "":
		if err := r.app.MDNSManager.Close(); err != nil {
			return fmt.Errorf("stop mDNS with no VIP configured: %w", err)
		}

		ip := net.ParseIP(bindAddr)
		if ip == nil {
			return fmt.Errorf("invalid bind addr for fusion-only mDNS: %s", bindAddr)
		}
		if err := r.app.MDNSManager.StartFusionAdvertismentOnly(ip); err != nil {
			return fmt.Errorf("start fusion-only mDNS for bind addr %s: %w", bindAddr, err)
		}
		if changed {
			logger.Debug("[Discovery] Reconciled mDNS to local bind address %s (%s)", bindAddr, reason)
		} else {
			logger.Debug("[Discovery] mDNS already reconciled to local bind address %s (%s)", bindAddr, reason)
		}
		r.mu.Lock()
		r.lastMode = mode
		r.lastVIP = targetVIP
		r.mu.Unlock()
		return nil

	case isLocalOwner:
		// suppress immediate start if local address just changed
		if r.ShouldSuppressLocalGainMDNS(currentVIP) {
			if changed {
				logger.Debug("[Discovery] Suppressed mDNS start for local VIP %s (%s)", currentVIP, reason)
			} else {
				logger.Debug("[Discovery] mDNS start suppressed for local VIP %s (%s)", currentVIP, reason)
			}
			r.mu.Lock()
			r.lastMode = mode
			r.lastVIP = targetVIP
			r.mu.Unlock()
			return nil
		}

		ip := net.ParseIP(currentVIP)
		if ip == nil {
			return fmt.Errorf("invalid VIP for mDNS reconcile: %s", currentVIP)
		}
		if err := r.app.MDNSManager.StartFusionAndOcaAdvertisment(ip); err != nil {
			return fmt.Errorf("start mDNS for local VIP %s: %w", currentVIP, err)
		}
		if changed {
			logger.Debug("[Discovery] Reconciled mDNS to local VIP %s (%s)", currentVIP, reason)
		} else {
			logger.Debug("[Discovery] mDNS already reconciled to local VIP %s (%s)", currentVIP, reason)
		}
		r.mu.Lock()
		r.lastMode = mode
		r.lastVIP = targetVIP
		r.mu.Unlock()
		return nil

	default:
		if err := r.app.MDNSManager.Close(); err != nil {
			return fmt.Errorf("stop mDNS for non-owner VIP %s: %w", currentVIP, err)
		}
		if changed {
			logger.Debug("[Discovery] Reconciled mDNS off for remote-owned VIP %s (%s)", currentVIP, reason)
		} else {
			logger.Debug("[Discovery] mDNS already off for remote-owned VIP %s (%s)", currentVIP, reason)
		}
		r.mu.Lock()
		r.lastMode = mode
		r.lastVIP = targetVIP
		r.mu.Unlock()
		return nil
	}
}
