package vipmonitor

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"

	"fusion-services-core/logging"
	coreNetwork "fusion-services-core/network"
	"fusion-services-core/vip"
	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/routes"
	"fusion/internal/utils"

	json "github.com/goccy/go-json"
)

const (
	configPath   = "/etc/keepalived/" + vip.DefaultConfFile
	baseBackoff  = 500 * time.Millisecond
	maxBackoff   = 30 * time.Second
	serverPrefix = "fusion"
)

// VIPEventType represents the type of VIP state change
type VIPEventType string

const (
	EventGained         VIPEventType = "gained"          // VIP gained locally
	EventLost           VIPEventType = "lost"            // VIP lost locally
	EventMoved          VIPEventType = "moved"           // VIP moved to different remote node
	EventAddressChanged VIPEventType = "address_changed" // VIP address changed
	EventHolderChanged  VIPEventType = "holder_changed"  // VIP holder changed (but same address)
)

// VIPEvent represents a VIP state change event
type VIPEvent struct {
	VIP          string       // Current VIP address (canonicalized)
	Holder       string       // Current holder IP address
	EventType    VIPEventType // Type of event
	IsLocalOwner bool         // True if this node owns the VIP
	OldVIP       string       // Previous VIP address (for address changes)
	OldHolder    string       // Previous holder (for holder changes)
}

// VIPMonitor is the single source of truth for VIP state and monitoring
type VIPMonitor struct {
	netIface string
	isLocal  bool // True for local dev mode (no VRRP/keepalived)
	cluster  *cluster.Cluster

	// VIP state (protected by stateMu)
	stateMu       sync.RWMutex
	currentVIP    string    // Canonicalized current VIP
	currentHolder string    // IP address of current holder
	expectedVIP   net.IPNet // Expected VIP from config (for watcher)

	configPath string

	// Monitoring infrastructure
	vipWatcher       *coreNetwork.VIPWatcher
	vrrpListenerDone chan struct{}
	monitoringActive bool

	// Callback for state changes
	onStateChange func(VIPEvent)

	// Lifecycle management
	stopMu sync.Mutex
	stopCh chan struct{}
	stopWg sync.WaitGroup
}

// NewVIPMonitor creates a new VIP monitor instance
func NewVIPMonitor(netIface string, isLocal bool, cluster *cluster.Cluster) *VIPMonitor {
	return &VIPMonitor{
		netIface:   netIface,
		isLocal:    isLocal,
		cluster:    cluster,
		configPath: configPath,
		vipWatcher: coreNetwork.NewVIPWatcher(logging.GetLogger(), netIface),
		stopCh:     make(chan struct{}),
	}
}

// SetCallback sets the callback function for VIP state changes
func (m *VIPMonitor) SetCallback(callback func(VIPEvent)) {
	m.stateMu.Lock()
	defer m.stateMu.Unlock()
	m.onStateChange = callback
}

// GetCurrentVIP returns the current VIP address
func (m *VIPMonitor) GetCurrentVIP() string {
	m.stateMu.RLock()
	defer m.stateMu.RUnlock()
	return m.currentVIP
}

// GetVIPHolder returns the current VIP holder IP address
func (m *VIPMonitor) GetVIPHolder() string {
	m.stateMu.RLock()
	defer m.stateMu.RUnlock()
	return m.currentHolder
}

// IsLocalVIPHolder returns true if this node currently owns the VIP
func (m *VIPMonitor) IsLocalVIPHolder() bool {
	m.stateMu.RLock()
	currentVIP := m.currentVIP
	m.stateMu.RUnlock()

	if currentVIP == "" {
		return false
	}

	isLocal, err := vip.IsIPPresentOnLocalInterface(currentVIP)
	if err != nil {
		logging.GetLogger().Error("Error checking if currentVIP %s is local: %v", currentVIP, err)
		return false
	}
	return isLocal
}

// SetClusterInstance updates the cluster instance reference (used for cluster operations)
func (m *VIPMonitor) SetClusterInstance(cluster *cluster.Cluster) {
	m.stateMu.Lock()
	defer m.stateMu.Unlock()
	m.cluster = cluster
}

// Start begins VIP monitoring (VRRP listener + netlink watcher)
func (m *VIPMonitor) Start() error {
	m.stopMu.Lock()
	defer m.stopMu.Unlock()

	logger := logging.GetLogger()

	if m.monitoringActive {
		return fmt.Errorf("VIP monitoring already active")
	}

	// Read expected VIP from config
	var expectedVIPStr string
	var err error

	if m.isLocal {
		expectedVIPStr, err = vip.ReadFromLocalConfig(serverPrefix, vip.DefaultConfFile)
		if err != nil {
			logger.Warn("No VIP configured in local mode: %v", err)
			// In local mode, it's okay if VIP isn't configured yet
			return nil
		}
	} else {
		var multiple bool
		expectedVIPStr, multiple, err = vip.ReadFromKeepalivedConfig(m.configPath)
		if err != nil {
			logger.Error("Failed to get VIP from config: %v", err)
			return err
		}
		if multiple {
			logger.Warn("More than one VIP found in keepalived config")
		}
	}

	// Parse expected VIP
	_, expectedVIPNet, err := net.ParseCIDR(expectedVIPStr)
	if err != nil {
		logger.Error("Invalid VIP CIDR %s: %v", expectedVIPStr, err)
		return fmt.Errorf("invalid VIP CIDR: %s", expectedVIPStr)
	}

	m.stateMu.Lock()
	m.expectedVIP = *expectedVIPNet
	// Initialize current VIP from config
	m.currentVIP = vip.Canonicalize(expectedVIPStr)
	m.stateMu.Unlock()

	// Start VRRP listener (non-local mode only)
	if !m.isLocal {
		m.stopWg.Add(1)
		go m.startVRRPListener()
	}

	// Start VIP watcher (netlink monitoring)
	if err := m.vipWatcher.Start(*expectedVIPNet, m.handleVIPWatcherUpdate); err != nil {
		logger.Error("Failed to start VIP watcher: %v", err)
		return err
	}

	m.monitoringActive = true
	logger.Info("VIP monitoring started for %s on interface %s", expectedVIPStr, m.netIface)

	return nil
}

// Stop stops VIP monitoring
func (m *VIPMonitor) Stop() {
	m.stopMu.Lock()
	defer m.stopMu.Unlock()

	if !m.monitoringActive {
		return
	}

	// Signal goroutines to stop
	close(m.stopCh)

	// Stop VIP watcher
	m.vipWatcher.Stop()

	// Wait for VRRP listener to exit
	m.stopWg.Wait()

	m.monitoringActive = false
	logging.GetLogger().Info("VIP monitoring stopped")
}

func (m *VIPMonitor) startVRRPListener() {
	defer m.stopWg.Done()

	logger := logging.GetLogger()
	logger.Debug("Starting VRRP listener")

	err := coreNetwork.StartVRRPListener(logger, m.handleVRRPUpdate)

	// Check if we were stopped
	select {
	case <-m.stopCh:
		logger.Debug("VRRP listener stopped")
		return
	default:
		if err != nil {
			logger.Error("VRRP listener exited with error: %v", err)
		} else {
			logger.Info("VRRP listener exited")
		}
	}
}

// handleVIPWatcherUpdate is called when the VIP is added/removed from the local interface
func (m *VIPMonitor) handleVIPWatcherUpdate(gained bool) {
	logger := logging.GetLogger()
	logger.Debug("VIP watcher update: gained=%v", gained)

	// Get current state
	m.stateMu.RLock()
	currentVIP := m.currentVIP
	currentHolder := m.currentHolder
	callback := m.onStateChange
	m.stateMu.RUnlock()

	if callback == nil {
		logger.Warn("VIP watcher update received but no callback registered")
		return
	}

	// Determine our local IP (for holder updates)
	localIP, err := utils.GetLocalIPByInterface(m.netIface)
	if err != nil {
		logger.Error("Failed to determine local IP for interface %s: %v", m.netIface, err)
	}

	if gained {
		logger.Info("VIP gained on local interface")

		// Update state
		m.stateMu.Lock()
		m.currentHolder = localIP
		m.stateMu.Unlock()

		// Notify
		callback(VIPEvent{
			VIP:          currentVIP,
			Holder:       localIP,
			EventType:    EventGained,
			IsLocalOwner: true,
			OldVIP:       currentVIP,
			OldHolder:    currentHolder,
		})
	} else {
		logger.Info("VIP lost from local interface")

		// We not sure of new holder - wait for VRRP update to tell us who has it
		callback(VIPEvent{
			VIP:          currentVIP,
			Holder:       "", // Unknown until VRRP tells us
			EventType:    EventLost,
			IsLocalOwner: false,
			OldVIP:       currentVIP,
			OldHolder:    currentHolder,
		})
	}
}

// handleVRRPUpdate is called when a VRRP advertisement is received
func (m *VIPMonitor) handleVRRPUpdate(vipAddr string, srcIP string) {
	logger := logging.GetLogger()
	logger.Debug("VRRP update received: vipAddr=%s srcIP=%s", vipAddr, srcIP)

	// Validate input
	if vipAddr == "" && srcIP == "" {
		logger.Warn("VRRP update with empty vipAddr and srcIP")
		return
	}

	newVIP := vip.Canonicalize(vipAddr)

	// Get current state
	m.stateMu.RLock()
	oldVIP := m.currentVIP
	oldHolder := m.currentHolder
	callback := m.onStateChange
	m.stateMu.RUnlock()

	if callback == nil {
		logger.Warn("VRRP update received but no callback registered")
		return
	}

	// VIP removed entirely
	if newVIP == "" {
		if oldVIP == "" {
			logger.Warn("Both oldVIP and newVIP are empty - no change")
			return
		}

		logger.Debug("VIP removed: oldVIP=%s", oldVIP)

		// Update state
		m.stateMu.Lock()
		m.currentVIP = ""
		m.currentHolder = ""
		m.stateMu.Unlock()

		// Notify
		callback(VIPEvent{
			VIP:          "",
			Holder:       "",
			EventType:    EventLost,
			IsLocalOwner: false,
			OldVIP:       oldVIP,
			OldHolder:    oldHolder,
		})
		return
	}

	// No change
	if newVIP == oldVIP && srcIP == oldHolder {
		logger.Debug("VRRP update with no state change")
		return
	}

	// Check ownership
	oldLocal, err := vip.IsIPPresentOnLocalInterface(oldHolder)
	if err != nil {
		logger.Error("Error checking if oldHolder is local: %v", err)
		oldLocal = false
	}

	newLocal, err := vip.IsIPPresentOnLocalInterface(srcIP)
	if err != nil {
		logger.Error("Error checking if srcIP is local: %v", err)
		newLocal = false
	}

	logger.Debug("VIP state: oldVIP=%s newVIP=%s oldHolder=%s newHolder=%s oldLocal=%v newLocal=%v",
		oldVIP, newVIP, oldHolder, srcIP, oldLocal, newLocal)

	// Update state
	m.stateMu.Lock()
	m.currentVIP = newVIP
	m.currentHolder = srcIP
	m.stateMu.Unlock()

	// Determine event type and notify
	vipChanged := (newVIP != oldVIP)
	holderChanged := (srcIP != oldHolder)

	switch {
	case oldLocal && newLocal:
		// Still have VIP locally (maybe just address changed)
		if vipChanged {
			callback(VIPEvent{
				VIP:          newVIP,
				Holder:       srcIP,
				EventType:    EventAddressChanged,
				IsLocalOwner: true,
				OldVIP:       oldVIP,
				OldHolder:    oldHolder,
			})
		} else if holderChanged {
			logger.Warn("Holder changed but still local: old=%s new=%s", oldHolder, srcIP)
		}

	case oldLocal && !newLocal:
		// Lost VIP locally
		logger.Info("VIP lost: was local, now at %s", srcIP)
		callback(VIPEvent{
			VIP:          newVIP,
			Holder:       srcIP,
			EventType:    EventLost,
			IsLocalOwner: false,
			OldVIP:       oldVIP,
			OldHolder:    oldHolder,
		})

	case !oldLocal && newLocal:
		// Gained VIP locally
		logger.Info("VIP gained: now local at %s", srcIP)
		callback(VIPEvent{
			VIP:          newVIP,
			Holder:       srcIP,
			EventType:    EventGained,
			IsLocalOwner: true,
			OldVIP:       oldVIP,
			OldHolder:    oldHolder,
		})

	case !oldLocal && !newLocal:
		// VIP moved between remote nodes
		logger.Info("VIP moved: from %s to %s", oldHolder, srcIP)
		callback(VIPEvent{
			VIP:          newVIP,
			Holder:       srcIP,
			EventType:    EventMoved,
			IsLocalOwner: false,
			OldVIP:       oldVIP,
			OldHolder:    oldHolder,
		})
	}
}

// UpdateVIP updates the VIP in the configuration file (does NOT reload keepalived)
func (m *VIPMonitor) UpdateVIP(vipValue string) error {
	logger := logging.GetLogger()

	if err := vip.Validate(vipValue); err != nil {
		return err
	}

	if m.isLocal {
		return vip.WriteToLocalConfig(serverPrefix, vip.DefaultConfFile, vipValue)
	}

	canonicalVIP := vip.Canonicalize(vipValue)
	logger.Debug("Updating virtual_ipaddress in %s → %s", m.configPath, canonicalVIP)

	if err := vip.WriteToKeepalivedConfig(m.configPath, canonicalVIP); err != nil {
		return err
	}

	logger.Debug("VIP updated successfully in config: %s", canonicalVIP)
	return nil
}

// ReloadKeepalived reloads the keepalived service
func (m *VIPMonitor) ReloadKeepalived() error {
	logger := logging.GetLogger()

	if m.isLocal {
		logger.Debug("Skipping keepalived reload in local mode")
		return nil
	}

	logger.Info("Reloading keepalived service")
	return exec.Command("systemctl", "reload", "keepalived").Run()
}

// UpdateVIPAndReload updates the VIP configuration and reloads keepalived
func (m *VIPMonitor) UpdateVIPAndReload(vipValue string) error {
	if err := m.UpdateVIP(vipValue); err != nil {
		return err
	}
	if err := m.ReloadKeepalived(); err != nil {
		return err
	}
	return nil
}

// HandleGetVIP handles GET /devices/vip
func (m *VIPMonitor) HandleGetVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	if m.isLocal {
		m.getVIPInLocalConfig(w)
		return
	}

	vipValue, multiple, err := vip.ReadFromKeepalivedConfig(m.configPath)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if multiple {
		logging.GetLogger().Warn("More than one VIP found.")
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)

	isVip, err := vip.IsIPPresentOnLocalInterface(vipValue)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if isVip {
		local, vipAddr, ok := vip.LocalForVIP(vipValue)
		if !ok {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		json.NewEncoder(w).Encode(map[string]string{
			"local": local.String(),
			"vip":   vipAddr.String(),
		})
		return
	}

	w.WriteHeader(http.StatusNotFound)
}

// HandleSetVIP handles POST /devices/vip/{vip}
func (m *VIPMonitor) HandleSetVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	vipValue, err := utils.ExtractValue(r, "vip")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := vip.Validate(vipValue); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	endpoint := routes.DevicesSetVIPEndpoint
	endpoint = strings.Replace(endpoint, "{vip}", url.QueryEscape(vipValue), 1)

	// Update VIP on all nodes in cluster
	localFn := func() error {
		return m.UpdateVIP(vipValue)
	}

	if err := cluster.PostGenericToAdmin(m.cluster, endpoint, localFn); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Reload keepalived on all nodes (async)
	if !m.isLocal {
		go func() {
			if err := cluster.PostGenericToAdmin(m.cluster, routes.DeviceReloadVIPEndpoint, m.ReloadKeepalived); err != nil {
				logging.GetLogger().Error("Failed to reload VIP: %v", err)
			}
		}()
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleUpdateVIPLocal handles POST /devices/vip/{vip} on admin port (local update only)
func (m *VIPMonitor) HandleUpdateVIPLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	vipValue, err := utils.ExtractValue(r, "vip")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := m.UpdateVIP(vipValue); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleReloadVIP handles POST /device/reload/vip (reloads on all nodes)
func (m *VIPMonitor) HandleReloadVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	go func() {
		if err := cluster.PostGenericToAdmin(m.cluster, routes.DeviceReloadVIPEndpoint, m.ReloadKeepalived); err != nil {
			logging.GetLogger().Error("Failed to reload VIP: %v", err)
		}
	}()

	w.WriteHeader(http.StatusNoContent)
}

// HandleReloadVIPLocal handles POST /device/reload/vip on admin port (local reload only)
func (m *VIPMonitor) HandleReloadVIPLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	if err := m.ReloadKeepalived(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// getVIPInLocalConfig is for use in "local" development mode only
func (m *VIPMonitor) getVIPInLocalConfig(w http.ResponseWriter) {
	vipValue, err := vip.ReadFromLocalConfig(serverPrefix, vip.DefaultConfFile)
	if err != nil {
		if os.IsNotExist(err) || err == vip.ErrLocalConfigEmpty {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("error reading local config: %v", err),
			http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]string{
		"local": vipValue,
		"vip":   vipValue,
	})
}
