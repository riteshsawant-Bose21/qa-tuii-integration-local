// package network

// import (
// 	"context"
// 	"fmt"
// 	"fusion/internal/logging"
// 	"fusion/internal/version"
// 	"net"
// 	"os"
// 	"strconv"
// 	"sync"

// 	"github.com/brutella/dnssd"
// )

// const (
// 	mdnsDomain            = "local"
// 	mdnsFusionServiceName = "FusionService"

// 	mdnsTTL = 120
// )

// const (
// 	// mDNS service configuration - fusion
// 	mdnsFusionServiceType = "_fusion._tcp"
// 	mdnsFusionVIPPort     = 8080

// 	// mDNS service configuration - AES70 OCA
// 	mdnsOCAServiceType = "_oca._tcp"
// 	mdnsOCAServicePort = 65000
// )

// // MDNSServer manages mDNS service registration for Fusion cluster
// type MDNSManager struct {
// 	responder           dnssd.Responder
// 	fusionServiceHandle dnssd.ServiceHandle
// 	ocaServiceHandle    dnssd.ServiceHandle
// 	ctx                 context.Context
// 	cancel              context.CancelFunc
// 	mu                  sync.Mutex
// 	running             bool
// }

// // NewMDNSManager creates a new mDNS manager instance
// func NewMDNSManager() *MDNSManager {
// 	logger := logging.GetLogger()

// 	responder, err := dnssd.NewResponder()
// 	if err != nil {
// 		logger.Error("Failed to create mDNS responder: %v", err)
// 		return nil
// 	}

// 	ctx, cancel := context.WithCancel(context.Background())

// 	return &MDNSManager{
// 		responder: responder,
// 		ctx:       ctx,
// 		cancel:    cancel,
// 	}
// }

// // Start begins mDNS service advertisement with the current VIP
// func (m *MDNSManager) StartWithVIP(vipAddr net.IP) error {

// 	logger := logging.GetLogger()
// 	logger.Debug("[Discovery] StartWithVIP called with VIP: '%s'", vipAddr)

// 	if m.running {
// 		logger.Warn("[Discovery] mDNS manager already running, removing existing services first")
// 		if err := m.Close(); err != nil {
// 			logger.Error("[Discovery] Failed to stop existing mDNS services: %v", err)
// 			return err
// 		}
// 		//init a new context as it was cancelled on Close
// 		m.ctx, m.cancel = context.WithCancel(context.Background())
// 	}

// 	m.mu.Lock()
// 	defer m.mu.Unlock()

// 	if vipAddr == nil {
// 		logger.Error("[Discovery] VIP empty")
// 		return fmt.Errorf("no VIP available for mDNS service")
// 	}

// 	// add services to responder
// 	fusionServiceHandle, err := m.addFusionMdnsService(vipAddr)
// 	if err != nil {
// 		logger.Error("[Discovery] Failed to add Fusion mDNS service: %v", err)
// 		return fmt.Errorf("failed to add Fusion mDNS service: %w", err)
// 	}
// 	m.fusionServiceHandle = fusionServiceHandle

// 	ocaServiceHandle, err1 := m.addOcaMdnsService(vipAddr)
// 	if err1 != nil {
// 		logger.Error("[Discovery] Failed to add OCA mDNS service: %v", err1)
// 		return fmt.Errorf("failed to add OCA mDNS service: %w", err1)
// 	}
// 	m.ocaServiceHandle = ocaServiceHandle

// 	m.running = true

// 	// Start responder in background
// 	logger.Debug("[Discovery] Starting mDNS responder in background...")
// 	go func() {
// 		logger.Debug("[MDNS-MGR] mDNS responder goroutine started")
// 		defer func() {
// 			if r := recover(); r != nil {
// 				logger.Error("[MDNS-MGR] mDNS responder goroutine panicked: %v", r)
// 			}
// 		}()

// 		if err := m.responder.Respond(m.ctx); err != nil {
// 			if m.ctx.Err() == nil {
// 				logger.Error("[MDNS-MGR] mDNS responder error: %v", err)
// 			} else {
// 				logger.Debug("[MDNS-MGR] mDNS responder stopped (context cancelled)")
// 			}
// 		}
// 		logger.Debug("[MDNS-MGR] mDNS responder goroutine exited")
// 	}()

// 	logger.Info("[MDNS-MGR] mDNS service started successfully:")
// 	logger.Info("[MDNS-MGR]   Service: %s.%s.%s", mdnsFusionServiceName, mdnsFusionServiceType, mdnsDomain)
// 	logger.Info("[MDNS-MGR]   Resolves to: %s:%d", vipAddr, mdnsFusionVIPPort)
// 	logger.Info("[MDNS-MGR]   Broadcasting on network interfaces...")
// 	logger.Debug("[MDNS-MGR] StartWithVIP function completed successfully")

// 	return nil
// }

// // Close stops the service and shuts down the responder
// func (m *MDNSManager) Close() error {

// 	m.mu.Lock()
// 	defer m.mu.Unlock()

// 	logger := logging.GetLogger()

// 	if !m.running {
// 		logger.Warn("[Discovery] mDNS service already stopped")
// 		return nil
// 	}

// 	logger.Debug("[Discovery] Removing services from mDNS responder...")
// 	if m.fusionServiceHandle != nil {
// 		m.responder.Remove(m.fusionServiceHandle)
// 		m.fusionServiceHandle = nil
// 	}
// 	if m.ocaServiceHandle != nil {
// 		m.responder.Remove(m.ocaServiceHandle)
// 		m.ocaServiceHandle = nil
// 	}

// 	// Cancel context to stop responder
// 	if m.cancel != nil {
// 		m.cancel()
// 		m.cancel = nil
// 	}
// 	m.running = false

// 	logging.GetLogger().Debug("[Discovery] mDNS server closed")
// 	return nil
// }

// func (m *MDNSManager) IsRunning() bool {
// 	m.mu.Lock()
// 	defer m.mu.Unlock()
// 	return m.running
// }

// func (m *MDNSManager) addFusionMdnsService(vip net.IP) (dnssd.ServiceHandle, error) {

// 	logger := logging.GetLogger()

// 	instanceName, err := os.Hostname()
// 	if err != nil || instanceName == "" {
// 		instanceName = "FusionHostDefault"
// 	}

// 	cfg := dnssd.Config{
// 		Name:   mdnsFusionServiceName,
// 		Type:   mdnsFusionServiceType,
// 		Domain: mdnsDomain,
// 		Host:   instanceName + ".local",
// 		Port:   mdnsFusionVIPPort,
// 		IPs:    []net.IP{vip},
// 		Text: map[string]string{
// 			"version":  version.Version,
// 			"protocol": "http",
// 			"port":     strconv.Itoa(mdnsFusionVIPPort),
// 		},
// 	}

// 	logger.Debug("[Discovery] mDNS service configuration:")
// 	logger.Debug("  Name: %s", cfg.Name)
// 	logger.Debug("  Type: %s", cfg.Type)
// 	logger.Debug("  Domain: %s", cfg.Domain)
// 	logger.Debug("  Host: %s", cfg.Host)
// 	logger.Debug("  Port: %d", cfg.Port)
// 	logger.Debug("  IP: %v", cfg.IPs)
// 	logger.Debug("  TXT records: %+v", cfg.Text)

// 	// Create service from config
// 	service, err := dnssd.NewService(cfg)
// 	if err != nil {
// 		logger.Error("Failed to create mDNS service: %v", err)
// 		return nil, fmt.Errorf("failed to create mDNS service: %w", err)
// 	}

// 	// Add the service to responder
// 	serviceHandle, err := m.responder.Add(service)
// 	if err != nil {
// 		logger.Error("Failed to add mDNS service to responder: %v", err)
// 		return nil, fmt.Errorf("failed to add mDNS service to responder: %w", err)
// 	}
// 	return serviceHandle, nil
// }

// func (m *MDNSManager) addOcaMdnsService(vip net.IP) (dnssd.ServiceHandle, error) {

// 	logger := logging.GetLogger()

// 	instanceName, err := os.Hostname()
// 	if err != nil || instanceName == "" {
// 		instanceName = "FusionHostDefault"
// 	}

// 	cfg := dnssd.Config{
// 		Name:   instanceName,
// 		Type:   mdnsOCAServiceType,
// 		Domain: mdnsDomain,
// 		Host:   instanceName + ".local",
// 		Port:   mdnsOCAServicePort,
// 		IPs:    []net.IP{vip},
// 		Text: map[string]string{
// 			"version":   version.Version,
// 			"protocol":  "http",
// 			"port":      strconv.Itoa(mdnsOCAServicePort),
// 			"txtvers":   "1",
// 			"protovers": "1",
// 			"modelGUID": "FUSION-0000-0000-0000-000000000001", //fixme: get from hardware
// 		},
// 	}

// 	logger.Info("[Discovery] mDNS OCA service configuration:")
// 	logger.Info("  Name: %s", cfg.Name)
// 	logger.Info("  Type: %s", cfg.Type)
// 	logger.Info("  Domain: %s", cfg.Domain)
// 	logger.Info("  Host: %s", cfg.Host)
// 	logger.Info("  Port: %d", cfg.Port)
// 	logger.Info("  IPs: %v", cfg.IPs)
// 	logger.Info("  TXT records: %+v", cfg.Text)

// 	// Create service from config
// 	service, err := dnssd.NewService(cfg)
// 	if err != nil {
// 		logger.Error("Failed to create mDNS service: %v", err)
// 		return nil, fmt.Errorf("failed to create mDNS service: %w", err)
// 	}

// 	// Add the service to responder
// 	serviceHandle, err := m.responder.Add(service)
// 	if err != nil {
// 		logger.Error("Failed to add mDNS service to responder: %v", err)
// 		return nil, fmt.Errorf("failed to add mDNS service to responder: %w", err)
// 	}
// 	return serviceHandle, nil
// }

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
	mdnsFusionServiceName = "FusionService"
	mdnsTTL               = 120
)

const (
	mdnsFusionServiceType = "_fusion._tcp"
	mdnsFusionVIPPort     = 8080

	mdnsOCAServiceType = "_oca._tcp"
	mdnsOCAServicePort = 65000
)

type MDNSManager struct {
	// command loop
	cmdCh chan any
	once  sync.Once
	wg    sync.WaitGroup // waits for loop exit (optional)
}

// Commands
type cmdStart struct {
	vip  net.IP
	resp chan error
}

type cmdStop struct {
	resp chan error
}

type cmdIsRunning struct {
	resp chan bool
}

type cmdShutdown struct {
	resp chan error
}

func NewMDNSManager() *MDNSManager {
	m := &MDNSManager{
		cmdCh: make(chan any),
	}
	m.startLoop()
	return m
}

// StartWithVIP can be called concurrently.
func (m *MDNSManager) StartWithVIP(vip net.IP) error {
	if vip == nil {
		return fmt.Errorf("no VIP available for mDNS service")
	}
	resp := make(chan error, 1)
	m.cmdCh <- cmdStart{vip: vip, resp: resp}
	return <-resp
}

// Close can be called concurrently and is idempotent.
func (m *MDNSManager) Close() error {
	resp := make(chan error, 1)
	m.cmdCh <- cmdStop{resp: resp}
	return <-resp
}

func (m *MDNSManager) IsRunning() bool {
	resp := make(chan bool, 1)
	m.cmdCh <- cmdIsRunning{resp: resp}
	return <-resp
}

// Optional: if you ever want to permanently end the loop.
func (m *MDNSManager) Shutdown() error {
	resp := make(chan error, 1)
	m.cmdCh <- cmdShutdown{resp: resp}
	return <-resp
}

func (m *MDNSManager) startLoop() {
	m.once.Do(func() {
		m.wg.Add(1)
		go func() {
			defer m.wg.Done()
			m.loop()
		}()
	})
}

type loopState struct {
	responder dnssd.Responder

	fusionHandle dnssd.ServiceHandle
	ocaHandle    dnssd.ServiceHandle

	ctx    context.Context
	cancel context.CancelFunc
	respWg sync.WaitGroup // waits for responder.Respond(ctx) goroutine

	running bool
	vip     net.IP
}

func (m *MDNSManager) loop() {
	logger := logging.GetLogger()

	st := loopState{}

	// Create responder once; if dnssd requires a fresh responder per run,
	// you can move this into start() and recreate it on every start.
	responder, err := dnssd.NewResponder()
	if err != nil {
		// If responder creation fails, all commands should fail.
		// We keep looping, returning errors to callers.
		logger.Error("[MDNS-MGR] Failed to create responder: %v", err)
	} else {
		st.responder = responder
	}

	// Helper closures owned by loop goroutine only.
	stop := func() error {
		if !st.running {
			return nil
		}

		// Remove services first
		if st.fusionHandle != nil {
			st.responder.Remove(st.fusionHandle)
			st.fusionHandle = nil
		}
		if st.ocaHandle != nil {
			st.responder.Remove(st.ocaHandle)
			st.ocaHandle = nil
		}

		// Cancel responder and wait for it to exit
		if st.cancel != nil {
			st.cancel()
			st.cancel = nil
		}
		st.respWg.Wait()

		st.running = false
		st.vip = nil

		logger.Debug("[MDNS-MGR] mDNS stopped")
		return nil
	}

	start := func(vip net.IP) error {
		if st.responder == nil {
			return fmt.Errorf("mDNS responder not available")
		}

		// If already running with same VIP, treat as idempotent success.
		if st.running && st.vip != nil && st.vip.Equal(vip) {
			return nil
		}

		// If running with different VIP, restart.
		if st.running {
			if err := stop(); err != nil {
				return err
			}
		}

		// Add services transactionally.
		fusionHandle, err := addService(st.responder, fusionConfig(vip))
		if err != nil {
			return fmt.Errorf("add Fusion service: %w", err)
		}

		ocaHandle, err := addService(st.responder, ocaConfig(vip))
		if err != nil {
			// rollback Fusion so we never partially advertise
			st.responder.Remove(fusionHandle)
			return fmt.Errorf("add OCA service: %w", err)
		}

		st.fusionHandle = fusionHandle
		st.ocaHandle = ocaHandle
		st.vip = vip

		// Start responder loop
		st.ctx, st.cancel = context.WithCancel(context.Background())
		st.running = true

		st.respWg.Add(1)
		go func(ctx context.Context) {
			defer st.respWg.Done()
			if err := st.responder.Respond(ctx); err != nil {
				// Only log as error if we weren't cancelled.
				if ctx.Err() == nil {
					logger.Error("[MDNS-MGR] responder error: %v", err)
				} else {
					logger.Debug("[MDNS-MGR] responder stopped (cancelled)")
				}
			}
		}(st.ctx)

		logger.Info("[MDNS-MGR] mDNS started: VIP=%s fusion=%s.%s.%s:%d oca=%s.%s:%d",
			vip,
			mdnsFusionServiceName, mdnsFusionServiceType, mdnsDomain, mdnsFusionVIPPort,
			hostnameOrDefault(), mdnsOCAServiceType, mdnsOCAServicePort,
		)

		return nil
	}

	// Main command loop
	for cmd := range m.cmdCh {
		switch c := cmd.(type) {
		case cmdStart:
			c.resp <- start(c.vip)

		case cmdStop:
			c.resp <- stop()

		case cmdIsRunning:
			c.resp <- st.running

		case cmdShutdown:
			// stop first, then exit loop
			err := stop()
			c.resp <- err
			close(m.cmdCh)
			return

		default:
			// Should never happen; ignore to avoid deadlock.
			logger.Warn("[MDNS-MGR] unknown command type %T", c)
		}
	}
}

// ----- Config helpers (pure functions) -----

func hostnameOrDefault() string {
	instanceName, err := os.Hostname()
	if err != nil || instanceName == "" {
		return "FusionHostDefault"
	}
	return instanceName
}

func fusionConfig(vip net.IP) dnssd.Config {
	host := hostnameOrDefault()
	return dnssd.Config{
		Name:   mdnsFusionServiceName,
		Type:   mdnsFusionServiceType,
		Domain: mdnsDomain,
		Host:   host + ".local",
		Port:   mdnsFusionVIPPort,
		IPs:    []net.IP{vip},
		Text: map[string]string{
			"version":  version.Version,
			"protocol": "http",
			"port":     strconv.Itoa(mdnsFusionVIPPort),
		},
	}
}

func ocaConfig(vip net.IP) dnssd.Config {
	host := hostnameOrDefault()
	return dnssd.Config{
		Name:   host, // keeps your old behavior
		Type:   mdnsOCAServiceType,
		Domain: mdnsDomain,
		Host:   host + ".local",
		Port:   mdnsOCAServicePort,
		IPs:    []net.IP{vip},
		Text: map[string]string{
			"version":   version.Version,
			"protocol":  "http",
			"port":      strconv.Itoa(mdnsOCAServicePort),
			"txtvers":   "1",
			"protovers": "1",
			"modelGUID": "FUSION-0000-0000-0000-000000000001", // TODO: get from hardware
		},
	}
}

// ----- DNSSD helper -----

func addService(r dnssd.Responder, cfg dnssd.Config) (dnssd.ServiceHandle, error) {
	logger := logging.GetLogger()

	svc, err := dnssd.NewService(cfg)
	if err != nil {
		return nil, fmt.Errorf("new service (%s %s): %w", cfg.Name, cfg.Type, err)
	}

	handle, err := r.Add(svc)
	if err != nil {
		return nil, fmt.Errorf("responder add (%s %s): %w", cfg.Name, cfg.Type, err)
	}

	logger.Debug("[MDNS-MGR] added service: %s.%s.%s -> %v:%d",
		cfg.Name, cfg.Type, cfg.Domain, cfg.IPs, cfg.Port)

	return handle, nil
}
