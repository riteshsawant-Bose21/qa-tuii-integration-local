package network

import (
	"context"
	"fmt"
	"fusion/internal/logging"
	"fusion/internal/version"
	"net"
	"os"
	"strconv"
	"sync"

	"github.com/brutella/dnssd"
)

const (
	mdnsDomain            = "local"
	mdnsFusionServiceName = "fusion"
)

const (
	// mDNS service configuration - fusion
	mdnsFusionServiceType = "_fusion._tcp"
	mdnsFusionVIPPort     = 8080

	// mDNS service configuration - AES70 OCA
	mdnsOCAServiceType = "_oca._tcp"
	mdnsOCAServicePort = 65000
)

// MDNSServer manages mDNS service registration for Fusion cluster
type MDNSManager struct {
	responder           dnssd.Responder
	fusionServiceHandle dnssd.ServiceHandle
	ocaServiceHandle    dnssd.ServiceHandle
	ctx                 context.Context
	cancel              context.CancelFunc
	mu                  sync.Mutex
	running             bool
}

// NewMDNSManager creates a new mDNS manager instance
func NewMDNSManager() *MDNSManager {
	logger := logging.GetLogger()

	responder, err := dnssd.NewResponder()
	if err != nil {
		logger.Error("Failed to create mDNS responder: %v", err)
		return nil
	}

	ctx, cancel := context.WithCancel(context.Background())

	logger.Debug("[Discovery] mDNS manager instance created successfully")
	return &MDNSManager{
		responder: responder,
		ctx:       ctx,
		cancel:    cancel,
	}
}

// Start begins mDNS service advertisement with the current VIP
func (m *MDNSManager) StartWithVIP(vipAddr net.IP) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	logger := logging.GetLogger()
	logger.Debug("[Discovery] StartWithVIP called with VIP: '%s'", vipAddr)

	if m.running {
		logger.Warn("[Discovery] mDNS manager already running, skipping start")
		return nil
	}

	if vipAddr == nil {
		logger.Error("[Discovery] VIP empty")
		return fmt.Errorf("no VIP available for mDNS service")
	}

	// add services to responder
	fusionServiceHandle, err := m.addFusionMdnsService(vipAddr)
	if err != nil {
		logger.Error("[Discovery] Failed to add Fusion mDNS service: %v", err)
		return fmt.Errorf("failed to add Fusion mDNS service: %w", err)
	}
	m.fusionServiceHandle = fusionServiceHandle

	ocaServiceHandle, err := m.addOcaMdnsService(vipAddr)
	if err != nil {
		logger.Error("[Discovery] Failed to add OCA mDNS service: %v", err)
		return fmt.Errorf("failed to add OCA mDNS service: %w", err)
	}
	m.ocaServiceHandle = ocaServiceHandle

	m.running = true

	// Start responder in background
	logger.Debug("[Discovery] Starting mDNS responder in background...")
	go func() {
		logger.Debug("[MDNS-MGR] mDNS responder goroutine started")
		defer func() {
			if r := recover(); r != nil {
				logger.Error("[MDNS-MGR] mDNS responder goroutine panicked: %v", r)
			}
		}()

		if err := m.responder.Respond(m.ctx); err != nil {
			if m.ctx.Err() == nil {
				logger.Error("[MDNS-MGR] mDNS responder error: %v", err)
			} else {
				logger.Debug("[MDNS-MGR] mDNS responder stopped (context cancelled)")
			}
		}
		logger.Debug("[MDNS-MGR] mDNS responder goroutine exited")
	}()

	logger.Info("[MDNS-MGR] mDNS service started successfully:")
	logger.Info("[MDNS-MGR]   Service: %s.%s.%s", mdnsFusionServiceName, mdnsFusionServiceType, mdnsDomain)
	logger.Info("[MDNS-MGR]   Resolves to: %s:%d", vipAddr, mdnsFusionVIPPort)
	logger.Info("[MDNS-MGR]   Broadcasting on network interfaces...")
	logger.Debug("[MDNS-MGR] StartWithVIP function completed successfully")

	return nil
}

// Stop stops the mDNS service advertisement
func (m *MDNSManager) Stop() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	logger := logging.GetLogger()

	if !m.running {
		logger.Warn("[Discovery] mDNS service already stopped")
		return nil
	}

	logger.Debug("[Discovery] Removing services from mDNS responder...")
	if m.fusionServiceHandle != nil {
		m.responder.Remove(m.fusionServiceHandle)
		m.fusionServiceHandle = nil
	}
	if m.ocaServiceHandle != nil {
		m.responder.Remove(m.ocaServiceHandle)
		m.ocaServiceHandle = nil
	}

	m.running = false

	return nil
}

// Close stops the service and shuts down the responder
func (m *MDNSManager) Close() error {

	if err := m.Stop(); err != nil {
		return err
	}

	// Cancel context to stop responder
	if m.cancel != nil {
		m.cancel()
		m.cancel = nil
	}

	logging.GetLogger().Debug("[Discovery] mDNS server closed")
	return nil
}

func (m *MDNSManager) IsRunning() bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.running
}

func (m *MDNSManager) addFusionMdnsService(vip net.IP) (dnssd.ServiceHandle, error) {

	logger := logging.GetLogger()

	instanceName, err := os.Hostname()
	if err != nil || instanceName == "" {
		instanceName = "FusionHostDefault"
	}

	cfg := dnssd.Config{
		Name:   mdnsFusionServiceName,
		Type:   mdnsFusionServiceType,
		Domain: mdnsDomain,
		Host:   instanceName + ".local",
		Port:   mdnsFusionVIPPort,
		IPs:    []net.IP{vip},
		Text: map[string]string{
			"version":  version.Version,
			"protocol": "http",
			"port":     strconv.Itoa(mdnsFusionVIPPort),
		},
	}

	logger.Debug("[Discovery] mDNS service configuration:")
	logger.Debug("  Name: %s", cfg.Name)
	logger.Debug("  Type: %s", cfg.Type)
	logger.Debug("  Domain: %s", cfg.Domain)
	logger.Debug("  Host: %s", cfg.Host)
	logger.Debug("  Port: %d", cfg.Port)
	logger.Debug("  IP: %v", cfg.IPs)
	logger.Debug("  TXT records: %+v", cfg.Text)

	// Create service from config
	service, err := dnssd.NewService(cfg)
	if err != nil {
		logger.Error("Failed to create mDNS service: %v", err)
		return nil, fmt.Errorf("failed to create mDNS service: %w", err)
	}

	// Add the service to responder
	serviceHandle, err := m.responder.Add(service)
	if err != nil {
		logger.Error("Failed to add mDNS service to responder: %v", err)
		return nil, fmt.Errorf("failed to add mDNS service to responder: %w", err)
	}
	return serviceHandle, nil
}

func (m *MDNSManager) addOcaMdnsService(vip net.IP) (dnssd.ServiceHandle, error) {

	logger := logging.GetLogger()

	instanceName, err := os.Hostname()
	if err != nil || instanceName == "" {
		instanceName = "FusionHostDefault"
	}

	cfg := dnssd.Config{
		Name:   instanceName,
		Type:   mdnsOCAServiceType,
		Domain: mdnsDomain,
		Host:   instanceName + ".local",
		Port:   mdnsOCAServicePort,
		IPs:    []net.IP{vip},
		Text: map[string]string{
			"version":   version.Version,
			"protocol":  "http",
			"port":      strconv.Itoa(mdnsOCAServicePort),
			"txtvers":   "1",
			"protovers": "1",
			"modelGUID": "FUSION-0000-0000-0000-000000000001", //fixme: get from hardware
		},
	}

	logger.Debug("[Discovery] mDNS OCA service configuration:")
	logger.Debug("  Name: %s", cfg.Name)
	logger.Debug("  Type: %s", cfg.Type)
	logger.Debug("  Domain: %s", cfg.Domain)
	logger.Debug("  Host: %s", cfg.Host)
	logger.Debug("  Port: %d", cfg.Port)
	logger.Debug("  IPs: %v", cfg.IPs)
	logger.Debug("  TXT records: %+v", cfg.Text)

	// Create service from config
	service, err := dnssd.NewService(cfg)
	if err != nil {
		logger.Error("Failed to create mDNS service: %v", err)
		return nil, fmt.Errorf("failed to create mDNS service: %w", err)
	}

	// Add the service to responder
	serviceHandle, err := m.responder.Add(service)
	if err != nil {
		logger.Error("Failed to add mDNS service to responder: %v", err)
		return nil, fmt.Errorf("failed to add mDNS service to responder: %w", err)
	}
	return serviceHandle, nil
}
