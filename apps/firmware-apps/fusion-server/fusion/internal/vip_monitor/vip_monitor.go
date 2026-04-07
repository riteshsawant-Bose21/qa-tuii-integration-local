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
	"fusion/internal/cluster/transport"
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

type VIPOperationPhase string

const (
	VIPOperationPhaseIdle          VIPOperationPhase = "idle"
	VIPOperationPhaseWritingConfig VIPOperationPhase = "writing_config"
	VIPOperationPhaseReloading     VIPOperationPhase = "reloading"
	VIPOperationPhaseConverging    VIPOperationPhase = "converging"
	VIPOperationPhaseComplete      VIPOperationPhase = "complete"
	VIPOperationPhaseFailed        VIPOperationPhase = "failed"
)

type VIPNodeResult struct {
	Node        string     `json:"node"`
	Host        string     `json:"host"`
	Phase       string     `json:"phase"`
	Success     bool       `json:"success"`
	StatusCode  int        `json:"status_code,omitempty"`
	Error       string     `json:"error,omitempty"`
	StartedAt   time.Time  `json:"started_at"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
}

type VIPOperationStatus struct {
	ID             string                   `json:"id"`
	DesiredVIP     string                   `json:"desired_vip"`
	StatusHost     string                   `json:"status_host,omitempty"`
	ObservedVIP    string                   `json:"observed_vip,omitempty"`
	ObservedHolder string                   `json:"observed_holder,omitempty"`
	Phase          VIPOperationPhase        `json:"phase"`
	Message        string                   `json:"message,omitempty"`
	StartedAt      time.Time                `json:"started_at"`
	CompletedAt    *time.Time               `json:"completed_at,omitempty"`
	NodeResults    map[string]VIPNodeResult `json:"node_results"`
}

type VIPApplyPhase string

const (
	VIPApplyPhaseIdle      VIPApplyPhase = "idle"
	VIPApplyPhaseReloading VIPApplyPhase = "reloading"
	VIPApplyPhaseComplete  VIPApplyPhase = "complete"
	VIPApplyPhaseFailed    VIPApplyPhase = "failed"
)

type VIPApplyStatus struct {
	DesiredVIP  string        `json:"desired_vip"`
	Phase       VIPApplyPhase `json:"phase"`
	Message     string        `json:"message,omitempty"`
	StartedAt   *time.Time    `json:"started_at,omitempty"`
	CompletedAt *time.Time    `json:"completed_at,omitempty"`
}

type vipAdminTarget struct {
	Node string
	Host string
}

// VIPEventType represents the type of VIP state change
type VIPEventType string

const (
	EventGainedOnLocalInterface VIPEventType = "gained_on_local_interface"
	// VIP gained locally - This is triggered when we detect VIP on local interface (could be new or same VIP).
	//  //TODO: Need to integrate with Keepalived conf file hooks??

	EventLostOnLocalInterface VIPEventType = "lost_on_local_interface"
	// VIP lost locally - This is triggered when we detect VIP is no longer on local interface - in this case, the holder will be empty
	// (could be moved to remote or removed entirely) - The VIP holder is empty in this update.
	// If things are good, we should get a VRRP update immediately after this with new holder info (could be same VIP or different VIP).

	EventGainedOnVRRPUpdate VIPEventType = "gained_on_VRRP_update"
	// Note: VRRP doesnt actually tell us who the new holder is when we gain VIP. So technically this event will never be called.

	EventLostOnVRRPUpdate VIPEventType = "lost_on_VRRP_update"
	// VIP lost locally - This is triggered when we detect VIP is empty in the packet
	// or VRRP update shows VIP is now held by different remote IP (srcIP in VRRP update)
	// This could also be triggered via VRRP

	EventMovedOnVRRPUpdate VIPEventType = "moved_on_VRRP_update"
	// VIP moved to different remote node - This is triggered when we receive VRRP update where the oldlocal and newlocal are different
	//I dont know how will this be different from EventVIPHolderChanged
	// (This node was not involved in the move, just an observer that some activity happened)

	EventAddressChanged VIPEventType = "address_changed"
	// VIP address changed - old vip != new vip

	EventVIPHolderChanged VIPEventType = "vip_holder_changed"
	// Holder changed, same IP
	// srcIP != oldHolder AND vipChanged == false AND !newLocal

	// EventAddressHealthCheck VIPEventType = "vip_health_check" //TODO
	// //This one is triggered when we have no changes. This is triggered once every x mins or every x packets
	// //The pupose of this is to notify the callback that the VIP is still the same and you can do the health checks.
	// // I noticed sometimes the cluster would partition and this would help heal itself.
)

// VIPEvent represents a VIP state change event
type VIPEvent struct {
	Holder       string       // Current holder IP address
	VIP          string       // Current VIP address
	EventType    VIPEventType // Type of event
	IsLocalOwner bool         // True if this node owns the VIP
	OldVIP       string       // Previous VIP address (for address changes)
	OldHolder    string       // Previous holder (for holder changes)
}

// VIPMonitor is the single source of truth for VIP state and monitoring
type VIPMonitor struct {
	netIface         string
	isLocal          bool // True for local dev mode (no VRRP/keepalived)
	clusterInterface transport.ClusterInterface
	updateMu         sync.Mutex
	adminClient      *http.Client

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

	operationMu     sync.RWMutex
	latestOperation *VIPOperationStatus
	operations      map[string]*VIPOperationStatus

	applyMu     sync.RWMutex
	applyStatus VIPApplyStatus
}

// NewVIPMonitor creates a new VIP monitor instance
func NewVIPMonitor(netIface string, isLocal bool, cluster transport.ClusterInterface) *VIPMonitor {
	return &VIPMonitor{
		netIface:         netIface,
		isLocal:          isLocal,
		clusterInterface: cluster,
		adminClient:      &http.Client{Timeout: api.HTTPTimeout},
		configPath:       configPath,
		vipWatcher:       coreNetwork.NewVIPWatcher(logging.GetLogger(), netIface),
		stopCh:           make(chan struct{}),
		operations:       make(map[string]*VIPOperationStatus),
		applyStatus:      VIPApplyStatus{Phase: VIPApplyPhaseIdle},
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

// Start begins VIP monitoring (VRRP listener + netlink watcher)
func (m *VIPMonitor) Start() error {
	m.stopMu.Lock()
	defer m.stopMu.Unlock()

	logger := logging.GetLogger()

	if m.monitoringActive {
		return fmt.Errorf("VIP monitoring already active")
	}

	// Always use a fresh stop channel for each monitoring session.
	// Stop() closes this channel, so reusing it across Start() calls is unsafe.
	m.stopCh = make(chan struct{})

	// // Start VRRP listener (non-local mode only)
	// NOTE: In a case where the VIP is not set, the VRRP listener will still
	// be started but the vip_watcher will only start when the vip is set
	if !m.isLocal {
		m.stopWg.Add(1)
		go m.startVRRPListener()
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

	// Parse expected VIP - handle both CIDR format (192.168.2.100/24) and plain IP (192.168.2.100)
	var expectedVIPNet *net.IPNet
	var expectedVIPIP net.IP
	expectedVIPIP, expectedVIPNet, err = net.ParseCIDR(expectedVIPStr)
	if err != nil {
		// Not a CIDR, try parsing as plain IP
		ip := net.ParseIP(expectedVIPStr)
		if ip == nil {
			logger.Error("Invalid VIP address %s: not a valid IP or CIDR", expectedVIPStr)
			return fmt.Errorf("invalid VIP address: %s", expectedVIPStr)
		}
		expectedVIPIP = ip
		// Create IPNet with /32 for IPv4 or /128 for IPv6
		if ip.To4() != nil {
			expectedVIPNet = &net.IPNet{IP: ip, Mask: net.CIDRMask(32, 32)}
		} else {
			expectedVIPNet = &net.IPNet{IP: ip, Mask: net.CIDRMask(128, 128)}
		}
		logger.Debug("Parsed plain IP %s as %s", expectedVIPStr, expectedVIPNet.String())
	} else {
		// Preserve the host IP from the CIDR string (ParseCIDR normalizes IPNet.IP to network address)
		expectedVIPNet.IP = expectedVIPIP
	}

	m.stateMu.Lock()
	m.expectedVIP = *expectedVIPNet
	// Initialize current VIP from config
	m.currentVIP = vip.Canonicalize(expectedVIPStr)
	m.stateMu.Unlock()

	// Start VIP watcher (netlink monitoring)
	if err := m.vipWatcher.Start(*expectedVIPNet, m.handleVIPWatcherUpdate); err != nil {
		logger.Error("Failed to start VIP watcher: %v", err)
		return err
	}

	m.monitoringActive = true
	logger.Debug("VIP monitoring started for %s on interface %s", expectedVIPStr, m.netIface)

	return nil
}

// Stop stops VIP monitoring
func (m *VIPMonitor) Stop() {
	m.stopMu.Lock()
	defer m.stopMu.Unlock()

	logger := logging.GetLogger()

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
	logger.Debug("VIP monitoring stopped")
}

// Restart stops and restarts VIP monitoring with fresh configuration
// This is useful when the VIP address changes and the watcher needs to monitor the new address
func (m *VIPMonitor) restart() error {
	logger := logging.GetLogger()
	logger.Debug("Restarting VIP monitoring")

	// Stop current monitoring
	m.Stop()

	// Start monitoring with fresh config
	if err := m.Start(); err != nil {
		logger.Error("Failed to restart VIP monitoring: %v", err)
		return err
	}

	logger.Debug("VIP monitoring restarted successfully")
	return nil
}

func (m *VIPMonitor) startVRRPListener() {
	defer m.stopWg.Done()

	logger := logging.GetLogger()

	err := coreNetwork.StartVRRPListener(logger, m.handleVRRPUpdate)

	// Check if we were stopped
	select {
	case <-m.stopCh:
		return
	default:
		if err != nil {
			logger.Error("VRRP listener exited with error: %v", err)
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

	logger.Debug("VIP watcher state: vip=%s holder=%s localIP=%s gained=%v",
		currentVIP, currentHolder, localIP, gained)

	if gained {
		// Update state
		m.stateMu.Lock()
		m.currentHolder = localIP
		m.stateMu.Unlock()

		// Notify
		logger.Debug("VIP watcher emit: event=%s vip=%s holder=%s oldHolder=%s isLocalOwner=%v",
			EventGainedOnLocalInterface, currentVIP, localIP, currentHolder, true)
		callback(VIPEvent{
			VIP:          currentVIP,
			Holder:       localIP,
			EventType:    EventGainedOnLocalInterface,
			IsLocalOwner: true,
			OldVIP:       currentVIP,
			OldHolder:    currentHolder,
		})
	} else {
		// We not sure of new holder - wait for VRRP update to tell us who has it
		logger.Debug("VIP watcher emit: event=%s vip=%s holder= oldHolder=%s isLocalOwner=%v",
			EventLostOnLocalInterface, currentVIP, currentHolder, false)
		callback(VIPEvent{
			VIP:          currentVIP,
			Holder:       "", // Unknown until VRRP tells us
			EventType:    EventLostOnLocalInterface,
			IsLocalOwner: false,
			OldVIP:       currentVIP,
			OldHolder:    currentHolder,
		})
	}
}

// handleVRRPUpdate is called when a VRRP advertisement is received.
// VRRP is only used to track the current holder. The VIP address itself is
// sourced from local config/update flow and must not be rewritten from remote
// advertisements.
func (m *VIPMonitor) handleVRRPUpdate(vipAddr string, srcIP string) {
	logger := logging.GetLogger()
	logger.Debug("VRRP update received: vipAddr=%s srcIP=%s", vipAddr, srcIP)

	// Validate input
	if vipAddr == "" && srcIP == "" {
		logger.Warn("VRRP update with empty vipAddr and srcIP")
		return
	}

	newVIP := vip.Canonicalize(vipAddr)

	// Atomically check and update state to prevent duplicate processing
	// Lock acquired here and held through state comparison and update
	m.stateMu.Lock()

	configuredVIP := m.currentVIP
	oldHolder := m.currentHolder
	callback := m.onStateChange

	if callback == nil {
		m.stateMu.Unlock()
		logger.Warn("VRRP update received but no callback registered")
		return
	}

	// Treat an empty VIP advertisement as holder loss only. The configured VIP
	// remains authoritative until local config changes it.
	if newVIP == "" {
		if configuredVIP == "" && oldHolder == "" {
			m.stateMu.Unlock()
			logger.Debug("Ignoring empty VRRP advertisement with no configured VIP or holder")
			return
		}

		logger.Debug("VRRP holder cleared for configured VIP %s", configuredVIP)

		m.currentHolder = ""
		m.stateMu.Unlock()

		// Notify
		callback(VIPEvent{
			VIP:          configuredVIP,
			Holder:       "",
			EventType:    EventLostOnVRRPUpdate,
			IsLocalOwner: false,
			OldVIP:       configuredVIP,
			OldHolder:    oldHolder,
		})
		return
	}

	// No change - check atomically before any goroutine updates state
	if newVIP == configuredVIP && srcIP == oldHolder {
		m.stateMu.Unlock()
		return
	}

	// Ignore remote attempts to rewrite the configured VIP. Address changes are
	// driven by config updates and watcher/local reconciliation, not VRRP.
	if configuredVIP != "" && newVIP != configuredVIP {
		m.stateMu.Unlock()
		logger.Debug("Ignoring VRRP VIP address update that differs from configured VIP: configured=%s advertised=%s srcIP=%s",
			configuredVIP, newVIP, srcIP)
		return
	}

	remoteOwner, err := vip.IsIPPresentOnLocalInterface(srcIP)
	if err != nil {
		m.stateMu.Unlock()
		logger.Error("Error checking if srcIP is local: %v", err)
		return
	}
	remoteOwner = !remoteOwner

	if remoteOwner {
		oldVIPLocal, err := vip.IsIPPresentOnLocalInterface(configuredVIP)
		if err != nil {
			m.stateMu.Unlock()
			logger.Error("Error checking if configuredVIP %s is local: %v", configuredVIP, err)
			return
		}

		// Remote VRRP advertisements can arrive out of order during a local VIP
		// transition. If the local interface still owns the configured VIP, keep
		// local interface truth and ignore the remote packet instead of poisoning
		// monitor state.
		if oldVIPLocal {
			m.stateMu.Unlock()
			logger.Debug(
				"Ignoring contradictory remote VRRP update while configured VIP remains local: configuredVIP=%s srcIP=%s oldVIPLocal=%v",
				configuredVIP,
				srcIP,
				oldVIPLocal,
			)
			return
		}
	}

	// Update holder state while still holding lock. currentVIP remains
	// config-driven and must not be changed from VRRP packets.
	m.currentHolder = srcIP
	m.stateMu.Unlock()

	// Now perform expensive operations outside the lock
	var oldLocal bool
	// Check ownership
	if oldHolder == "" {
		//first packet of VRRP received after startup.
		oldLocal = false
	} else {
		var err error
		oldLocal, err = vip.IsIPPresentOnLocalInterface(oldHolder)
		if err != nil {
			logger.Error("Error checking if oldHolder is local: %v", err)
			oldLocal = false
		}
	}

	newLocal := !remoteOwner

	logger.Debug("VIP state: oldVIP=%s newVIP=%s oldHolder=%s newHolder=%s oldLocal=%v newLocal=%v",
		configuredVIP, configuredVIP, oldHolder, srcIP, oldLocal, newLocal)

	// Determine event type and notify
	holderChanged := (srcIP != oldHolder)
	logger.Debug("VRRP decision: holderChanged=%v oldLocal=%v newLocal=%v configuredVIP=%s",
		holderChanged, oldLocal, newLocal, configuredVIP)

	switch {
	case holderChanged:
		if newLocal {
			logger.Debug("VRRP emit: event=%s vip=%s holder=%s oldVIP=%s oldHolder=%s isLocalOwner=%v",
				EventGainedOnVRRPUpdate, configuredVIP, srcIP, configuredVIP, oldHolder, true)
			callback(VIPEvent{
				VIP:          configuredVIP,
				Holder:       srcIP,
				EventType:    EventGainedOnVRRPUpdate,
				IsLocalOwner: true,
				OldVIP:       configuredVIP,
				OldHolder:    oldHolder,
			})
		} else {
			logger.Debug("VRRP emit: event=%s vip=%s holder=%s oldVIP=%s oldHolder=%s isLocalOwner=%v",
				EventVIPHolderChanged, configuredVIP, srcIP, configuredVIP, oldHolder, false)
			callback(VIPEvent{
				VIP:          configuredVIP,
				Holder:       srcIP,
				EventType:    EventVIPHolderChanged,
				IsLocalOwner: false,
				OldVIP:       configuredVIP,
				OldHolder:    oldHolder,
			})
		}

	case oldLocal && newLocal:
		// unexpected case - VIP moved but still local?
		logger.Info("VIP holder changed locally from %s to %s", oldHolder, srcIP)

	case oldLocal && !newLocal:
		// Lost VIP locally
		logger.Info("VIP lost: was local, now at %s", srcIP)
		logger.Debug("VRRP emit: event=%s vip=%s holder=%s oldVIP=%s oldHolder=%s isLocalOwner=%v",
			EventLostOnVRRPUpdate, configuredVIP, srcIP, configuredVIP, oldHolder, false)
		callback(VIPEvent{
			VIP:          configuredVIP,
			Holder:       srcIP,
			EventType:    EventLostOnVRRPUpdate,
			IsLocalOwner: false,
			OldVIP:       configuredVIP,
			OldHolder:    oldHolder,
		})

	case !oldLocal && newLocal:
		// Gained VIP locally
		logger.Info("VIP gained: now local at %s", srcIP)
		logger.Debug("VRRP emit: event=%s vip=%s holder=%s oldVIP=%s oldHolder=%s isLocalOwner=%v",
			EventGainedOnVRRPUpdate, configuredVIP, srcIP, configuredVIP, oldHolder, true)
		// Technically, this will never be called. As VRRP doesnt tell us who the new holder is when we gain VIP,
		// we will only get srcIP in VRRP update when we lose VIP to remote node.
		callback(VIPEvent{
			VIP:          configuredVIP,
			Holder:       srcIP,
			EventType:    EventGainedOnVRRPUpdate,
			IsLocalOwner: true,
			OldVIP:       configuredVIP,
			OldHolder:    oldHolder,
		})

	case !oldLocal && !newLocal:

		logger.Info("VIP moved: from %s to %s", oldHolder, srcIP)
		logger.Debug("VRRP emit: event=%s vip=%s holder=%s oldVIP=%s oldHolder=%s isLocalOwner=%v",
			EventMovedOnVRRPUpdate, configuredVIP, srcIP, configuredVIP, oldHolder, false)
		callback(VIPEvent{
			VIP:          configuredVIP,
			Holder:       srcIP,
			EventType:    EventMovedOnVRRPUpdate,
			IsLocalOwner: false,
			OldVIP:       configuredVIP,
			OldHolder:    oldHolder,
		})
	}
}

// UpdateVIP updates the VIP in the configuration file and reloads keepalived if needed.
func (m *VIPMonitor) writeVIPConfig(vipValue string) error {
	m.updateMu.Lock()
	defer m.updateMu.Unlock()

	logger := logging.GetLogger()

	if err := vip.Validate(vipValue); err != nil {
		return err
	}

	canonicalVIP := vip.Canonicalize(vipValue)

	if m.isLocal {
		return vip.WriteToLocalConfig(serverPrefix, vip.DefaultConfFile, canonicalVIP)
	}

	logger.Debug("Updating virtual_ipaddress in %s → %s", m.configPath, canonicalVIP)

	if err := vip.WriteToKeepalivedConfig(m.configPath, canonicalVIP); err != nil {
		return err
	}
	logger.Debug("VIP config updated successfully: %s", canonicalVIP)
	return nil
}

func (m *VIPMonitor) applyConfiguredVIP() error {
	m.updateMu.Lock()
	defer m.updateMu.Unlock()

	oldVIP := m.GetCurrentVIP()
	wasLocalOwner := !m.isLocal && m.IsLocalVIPHolder()

	configuredVIP := oldVIP
	if m.isLocal {
		v, err := vip.ReadFromLocalConfig(serverPrefix, vip.DefaultConfFile)
		if err != nil {
			return err
		}
		configuredVIP = vip.Canonicalize(v)
	} else {
		v, _, err := vip.ReadFromKeepalivedConfig(m.configPath)
		if err != nil {
			return err
		}
		configuredVIP = vip.Canonicalize(v)
	}

	if err := m.reloadKeepalived(); err != nil {
		return err
	}

	if err := m.restart(); err != nil {
		return err
	}

	if wasLocalOwner && oldVIP != "" && oldVIP != configuredVIP {
		// Emit the local address-change event asynchronously so follow-up
		// cluster/memberlist reconciliation does not block node-local VIP apply.
		go m.notifyLocalAddressChange(oldVIP, configuredVIP)
	}

	logging.GetLogger().Debug("Configured VIP applied successfully: %s", configuredVIP)
	return nil
}

func (m *VIPMonitor) updateVIP(vipValue string) error {
	if err := m.writeVIPConfig(vipValue); err != nil {
		return err
	}
	return m.applyConfiguredVIP()
}

// reloadKeepalived reloads the keepalived service
func (m *VIPMonitor) reloadKeepalived() error {
	logger := logging.GetLogger()

	if m.isLocal {
		logger.Debug("Skipping keepalived reload in local mode")
		return nil
	}

	logger.Debug("Reloading keepalived service")
	return exec.Command("systemctl", "reload", "keepalived").Run()
}

func (m *VIPMonitor) forwardVIPUpdateToCurrentVIP(endpoint string) error {
	currentVIP := m.GetCurrentVIP()
	if currentVIP == "" {
		return fmt.Errorf("cannot forward VIP update: current VIP is empty")
	}

	urlStr := fmt.Sprintf("http://%s:%s%s", currentVIP, api.HTTPPort, endpoint)
	resp, err := http.Post(urlStr, "", nil)
	if err != nil {
		return fmt.Errorf("forward VIP update to %s: %w", urlStr, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted {
		return fmt.Errorf("forward VIP update to %s returned status %d", urlStr, resp.StatusCode)
	}

	logging.GetLogger().Info("Forwarded VIP update request to current VIP %s with status %d", urlStr, resp.StatusCode)
	return nil
}

func requestHostName(hostport string) string {
	host, _, err := net.SplitHostPort(hostport)
	if err == nil {
		return host
	}
	return hostport
}

func newVIPOperationID() string {
	return fmt.Sprintf("vipop_%d", time.Now().UTC().UnixNano())
}

func cloneVIPOperation(op *VIPOperationStatus) *VIPOperationStatus {
	if op == nil {
		return nil
	}

	cloned := *op
	cloned.NodeResults = make(map[string]VIPNodeResult, len(op.NodeResults))
	for key, value := range op.NodeResults {
		cloned.NodeResults[key] = value
	}
	return &cloned
}

func (m *VIPMonitor) createVIPOperation(desiredVIP string) *VIPOperationStatus {
	now := time.Now().UTC()
	statusHost := ""
	if localNode := m.clusterInterface.LocalNode(); localNode != nil {
		statusHost = localNode.Addr.String()
	}
	op := &VIPOperationStatus{
		ID:          newVIPOperationID(),
		DesiredVIP:  desiredVIP,
		StatusHost:  statusHost,
		ObservedVIP: m.GetCurrentVIP(),
		Phase:       VIPOperationPhaseIdle,
		StartedAt:   now,
		NodeResults: map[string]VIPNodeResult{},
	}

	m.operationMu.Lock()
	defer m.operationMu.Unlock()
	m.operations[op.ID] = op
	m.latestOperation = op
	return cloneVIPOperation(op)
}

func (m *VIPMonitor) updateVIPOperation(id string, mutate func(op *VIPOperationStatus)) {
	m.operationMu.Lock()
	defer m.operationMu.Unlock()

	op, ok := m.operations[id]
	if !ok {
		return
	}
	mutate(op)
	m.latestOperation = op
}

func (m *VIPMonitor) setVIPOperationPhase(id string, phase VIPOperationPhase, message string) {
	m.updateVIPOperation(id, func(op *VIPOperationStatus) {
		op.Phase = phase
		op.Message = message
		op.ObservedVIP = m.GetCurrentVIP()
		op.ObservedHolder = m.GetVIPHolder()
		if phase == VIPOperationPhaseComplete || phase == VIPOperationPhaseFailed {
			now := time.Now().UTC()
			op.CompletedAt = &now
		}
	})
}

func (m *VIPMonitor) setVIPOperationResult(id string, result VIPNodeResult) {
	m.updateVIPOperation(id, func(op *VIPOperationStatus) {
		op.NodeResults[result.Host] = result
		op.ObservedVIP = m.GetCurrentVIP()
		op.ObservedHolder = m.GetVIPHolder()
	})
}

func (m *VIPMonitor) getLatestVIPOperation() *VIPOperationStatus {
	m.operationMu.RLock()
	defer m.operationMu.RUnlock()
	return cloneVIPOperation(m.latestOperation)
}

func isVIPOperationTerminal(phase VIPOperationPhase) bool {
	return phase == VIPOperationPhaseComplete || phase == VIPOperationPhaseFailed || phase == VIPOperationPhaseIdle
}

func (m *VIPMonitor) getVIPOperation(id string) *VIPOperationStatus {
	m.operationMu.RLock()
	defer m.operationMu.RUnlock()
	return cloneVIPOperation(m.operations[id])
}

func (m *VIPMonitor) getVIPApplyStatus() VIPApplyStatus {
	m.applyMu.RLock()
	defer m.applyMu.RUnlock()
	return m.applyStatus
}

func (m *VIPMonitor) setVIPApplyStatus(status VIPApplyStatus) {
	m.applyMu.Lock()
	defer m.applyMu.Unlock()
	m.applyStatus = status
}

func (m *VIPMonitor) launchVIPApply() error {
	current := m.getVIPApplyStatus()
	if current.Phase == VIPApplyPhaseReloading {
		return fmt.Errorf("VIP apply already in progress")
	}

	now := time.Now().UTC()
	desiredVIP := m.GetCurrentVIP()
	if !m.isLocal {
		if v, _, err := vip.ReadFromKeepalivedConfig(m.configPath); err == nil {
			desiredVIP = vip.Canonicalize(v)
		}
	}
	m.setVIPApplyStatus(VIPApplyStatus{
		DesiredVIP: desiredVIP,
		Phase:      VIPApplyPhaseReloading,
		Message:    fmt.Sprintf("applying configured VIP %s", desiredVIP),
		StartedAt:  &now,
	})

	go func(desired string) {
		if err := m.applyConfiguredVIP(); err != nil {
			done := time.Now().UTC()
			m.setVIPApplyStatus(VIPApplyStatus{
				DesiredVIP:  desired,
				Phase:       VIPApplyPhaseFailed,
				Message:     err.Error(),
				StartedAt:   &now,
				CompletedAt: &done,
			})
			return
		}

		done := time.Now().UTC()
		m.setVIPApplyStatus(VIPApplyStatus{
			DesiredVIP:  desired,
			Phase:       VIPApplyPhaseComplete,
			Message:     fmt.Sprintf("configured VIP %s applied", desired),
			StartedAt:   &now,
			CompletedAt: &done,
		})
	}(desiredVIP)

	return nil
}

func (m *VIPMonitor) dispatchReloadPhase(operationID string) error {
	targets := m.adminTargets()
	var wg sync.WaitGroup
	var firstErr error
	var firstErrMu sync.Mutex

	localHost := ""
	if node := m.clusterInterface.LocalNode(); node != nil {
		localHost = node.Addr.String()
	}

	for _, target := range targets {
		target := target
		wg.Add(1)
		go func() {
			defer wg.Done()

			startedAt := time.Now().UTC()
			result := VIPNodeResult{
				Node:      target.Node,
				Host:      target.Host,
				Phase:     string(VIPOperationPhaseReloading),
				StartedAt: startedAt,
			}

			if target.Host == localHost {
				if err := m.launchVIPApply(); err != nil {
					result.Error = err.Error()
				} else {
					result.Success = true
					result.StatusCode = http.StatusAccepted
				}
			} else {
				urlStr := fmt.Sprintf("%s%s", api.Protocol+net.JoinHostPort(target.Host, api.AdminPort), routes.DeviceReloadVIPEndpoint)
				resp, err := m.adminClient.Post(urlStr, "", nil)
				if err != nil {
					result.Error = err.Error()
				} else {
					result.StatusCode = resp.StatusCode
					if resp.StatusCode == http.StatusAccepted {
						result.Success = true
					} else {
						result.Error = fmt.Sprintf("unexpected status %d", resp.StatusCode)
					}
					resp.Body.Close()
				}
			}

			completedAt := time.Now().UTC()
			result.CompletedAt = &completedAt
			m.setVIPOperationResult(operationID, result)

			if !result.Success {
				firstErrMu.Lock()
				if firstErr == nil {
					firstErr = fmt.Errorf("reload dispatch failed on %s (%s): %s", target.Node, target.Host, result.Error)
				}
				firstErrMu.Unlock()
			}
		}()
	}

	wg.Wait()
	return firstErr
}

func (m *VIPMonitor) waitForReloadPhase(operationID string) error {
	targets := m.adminTargets()
	deadline := time.Now().Add(setupVIPTimeoutForMonitor())
	for time.Now().Before(deadline) {
		allDone := true
		for _, target := range targets {
			status, err := m.fetchVIPApplyStatus(target.Host)
			if err != nil {
				return err
			}
			result := m.getVIPOperation(operationID).NodeResults[target.Host]
			result.Node = target.Node
			result.Host = target.Host
			result.Phase = string(status.Phase)
			if status.Phase == VIPApplyPhaseFailed {
				result.Success = false
				result.Error = status.Message
				m.setVIPOperationResult(operationID, result)
				return fmt.Errorf("VIP apply failed on %s (%s): %s", target.Node, target.Host, status.Message)
			}
			if status.Phase != VIPApplyPhaseComplete && status.Phase != VIPApplyPhaseIdle {
				allDone = false
			} else {
				result.Success = true
			}
			m.setVIPOperationResult(operationID, result)
		}
		if allDone {
			return nil
		}
		time.Sleep(1 * time.Second)
	}
	return fmt.Errorf("VIP reload phase did not complete before timeout")
}

func setupVIPTimeoutForMonitor() time.Duration {
	return 45 * time.Second
}

func (m *VIPMonitor) fetchVIPApplyStatus(host string) (VIPApplyStatus, error) {
	if local := m.clusterInterface.LocalNode(); local != nil && host == local.Addr.String() {
		return m.getVIPApplyStatus(), nil
	}

	var status VIPApplyStatus
	urlStr := fmt.Sprintf("%s%s", api.Protocol+net.JoinHostPort(host, api.AdminPort), routes.DeviceReloadVIPStatusEndpoint)
	resp, err := m.adminClient.Get(urlStr)
	if err != nil {
		return status, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return status, fmt.Errorf("unexpected status %d from %s", resp.StatusCode, urlStr)
	}
	if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
		return status, err
	}
	return status, nil
}

func (m *VIPMonitor) adminTargets() []vipAdminTarget {
	targets := make([]vipAdminTarget, 0)
	seen := map[string]bool{}

	localNode := m.clusterInterface.LocalNode()
	if localNode != nil {
		host := localNode.Addr.String()
		targets = append(targets, vipAdminTarget{Node: localNode.Name, Host: host})
		seen[host] = true
	}

	for _, member := range m.clusterInterface.MemberListMembers() {
		host := member.Addr.String()
		if seen[host] {
			continue
		}
		targets = append(targets, vipAdminTarget{Node: member.Name, Host: host})
		seen[host] = true
	}

	return targets
}

func (m *VIPMonitor) runAdminPhase(operationID string, phase VIPOperationPhase, endpoint string, localFn func() error) error {
	targets := m.adminTargets()
	var wg sync.WaitGroup
	var firstErr error
	var firstErrMu sync.Mutex

	localHost := ""
	if node := m.clusterInterface.LocalNode(); node != nil {
		localHost = node.Addr.String()
	}

	for _, target := range targets {
		target := target
		wg.Add(1)
		go func() {
			defer wg.Done()

			startedAt := time.Now().UTC()
			result := VIPNodeResult{
				Node:      target.Node,
				Host:      target.Host,
				Phase:     string(phase),
				StartedAt: startedAt,
			}

			if target.Host == localHost {
				if err := localFn(); err != nil {
					result.Error = err.Error()
				} else {
					result.Success = true
				}
			} else {
				urlStr := fmt.Sprintf("%s%s", api.Protocol+net.JoinHostPort(target.Host, api.AdminPort), endpoint)
				resp, err := m.adminClient.Post(urlStr, "", nil)
				if err != nil {
					result.Error = err.Error()
				} else {
					result.StatusCode = resp.StatusCode
					if resp.StatusCode == http.StatusNoContent {
						result.Success = true
					} else {
						result.Error = fmt.Sprintf("unexpected status %d", resp.StatusCode)
					}
					resp.Body.Close()
				}
			}

			completedAt := time.Now().UTC()
			result.CompletedAt = &completedAt
			m.setVIPOperationResult(operationID, result)

			if !result.Success {
				firstErrMu.Lock()
				if firstErr == nil {
					firstErr = fmt.Errorf("%s phase failed on %s (%s): %s", phase, target.Node, target.Host, result.Error)
				}
				firstErrMu.Unlock()
			}
		}()
	}

	wg.Wait()
	return firstErr
}

func (m *VIPMonitor) runVIPOperation(operationID string, desiredVIP string) {
	endpoint := strings.Replace(routes.DevicesSetVIPEndpoint, "{vip}", url.QueryEscape(desiredVIP), 1)

	m.setVIPOperationPhase(operationID, VIPOperationPhaseWritingConfig, fmt.Sprintf("writing desired VIP %s to all nodes", desiredVIP))
	if err := m.runAdminPhase(operationID, VIPOperationPhaseWritingConfig, endpoint, func() error {
		return m.writeVIPConfig(desiredVIP)
	}); err != nil {
		m.setVIPOperationPhase(operationID, VIPOperationPhaseFailed, err.Error())
		return
	}

	m.setVIPOperationPhase(operationID, VIPOperationPhaseReloading, fmt.Sprintf("reloading keepalived for desired VIP %s", desiredVIP))
	if err := m.dispatchReloadPhase(operationID); err != nil {
		m.setVIPOperationPhase(operationID, VIPOperationPhaseFailed, err.Error())
		return
	}
	if err := m.waitForReloadPhase(operationID); err != nil {
		m.setVIPOperationPhase(operationID, VIPOperationPhaseFailed, err.Error())
		return
	}

	m.setVIPOperationPhase(operationID, VIPOperationPhaseConverging, fmt.Sprintf("waiting for local reconciliation to reflect %s", desiredVIP))
	m.setVIPOperationPhase(operationID, VIPOperationPhaseComplete, fmt.Sprintf("desired VIP %s written and reload requested on all nodes", desiredVIP))
}

func (m *VIPMonitor) notifyLocalAddressChange(oldVIP, newVIP string) {
	logger := logging.GetLogger()

	m.stateMu.RLock()
	callback := m.onStateChange
	oldHolder := m.currentHolder
	m.stateMu.RUnlock()

	if callback == nil {
		logger.Warn("Skipping local VIP address change notification for %s -> %s: no callback registered", oldVIP, newVIP)
		return
	}

	localIP, err := utils.GetLocalIPByInterface(m.netIface)
	if err != nil {
		logger.Error("Failed to determine local IP for interface %s during VIP change notification: %v", m.netIface, err)
		localIP = ""
	}

	callback(VIPEvent{
		VIP:          newVIP,
		Holder:       localIP,
		EventType:    EventAddressChanged,
		IsLocalOwner: true,
		OldVIP:       oldVIP,
		OldHolder:    oldHolder,
	})
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
	if vipValue == "" {
		// VIP block is empty (e.g., after deletion)
		w.WriteHeader(http.StatusNotFound)
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

// HandleGetVIPStatus handles GET /devices/vip/status
func (m *VIPMonitor) HandleGetVIPStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	status := m.getLatestVIPOperation()
	if status == nil {
		status = &VIPOperationStatus{
			DesiredVIP:     m.GetCurrentVIP(),
			StatusHost:     requestHostName(r.Host),
			ObservedVIP:    m.GetCurrentVIP(),
			ObservedHolder: m.GetVIPHolder(),
			Phase:          VIPOperationPhaseIdle,
			NodeResults:    map[string]VIPNodeResult{},
		}
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(status)
}

// HandleGetVIPOperation handles GET /devices/vip/operations/{id}
func (m *VIPMonitor) HandleGetVIPOperation(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	id, err := utils.ExtractValue(r, "id")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	status := m.getVIPOperation(id)
	if status == nil {
		http.Error(w, fmt.Sprintf("VIP operation %s not found", id), http.StatusNotFound)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(status)
}

// HandleGetVIPReloadStatus handles GET /device/reload/vip/status
func (m *VIPMonitor) HandleGetVIPReloadStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(m.getVIPApplyStatus())
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

	if err := m.writeVIPConfig(vipValue); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleReloadVIPLocal handles POST /device/reload/vip on admin port (local reload only)
func (m *VIPMonitor) HandleReloadVIPLocal(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	if err := m.launchVIPApply(); err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}

	w.WriteHeader(http.StatusAccepted)
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

	currentVIP := m.GetCurrentVIP()
	requestHost := requestHostName(r.Host)
	if currentVIP != "" && requestHost != "" && requestHost != currentVIP {
		http.Error(w, fmt.Sprintf("public VIP changes must be sent to current VIP %s, not %s", currentVIP, requestHost), http.StatusConflict)
		return
	}

	if latest := m.getLatestVIPOperation(); latest != nil && !isVIPOperationTerminal(latest.Phase) {
		http.Error(
			w,
			fmt.Sprintf("VIP operation %s is already in progress for desired VIP %s (phase=%s)", latest.ID, latest.DesiredVIP, latest.Phase),
			http.StatusConflict,
		)
		return
	}

	op := m.createVIPOperation(vipValue)
	go m.runVIPOperation(op.ID, vipValue)

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusAccepted)
	json.NewEncoder(w).Encode(op)
}

// HandleReloadVIP handles POST /device/reload/vip (reloads on all nodes)
func (m *VIPMonitor) HandleReloadVIP(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	defer r.Body.Close()

	go func() {
		if err := m.clusterInterface.PostGenericToAdmin(routes.DeviceReloadVIPEndpoint, m.applyConfiguredVIP); err != nil {
			logging.GetLogger().Error("Failed to reload VIP: %v", err)
		}
	}()

	w.WriteHeader(http.StatusNoContent)
}
