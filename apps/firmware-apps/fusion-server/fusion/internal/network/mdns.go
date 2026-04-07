package network

import (
	"context"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/version"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/brutella/dnssd"
)

const (
	mdnsDomain = "local"
	// mdnsTTL               = 120
)

const (
	mdnsFusionServiceType = "_fusion._tcp"
	mdnsFusionVIPPort     = 8080

	mdnsOCAServiceType = "_oca._tcp"
	mdnsOCAServicePort = 65000
)

type MDNSManager struct {
	// command loop
	cmdCh    chan any
	netIface string
	once     sync.Once
	wg       sync.WaitGroup // waits for loop exit (optional)
}

// Commands
type cmdStartFusionAdvertismentOnly struct {
	ip   net.IP
	resp chan error
}

type cmdStartFusionAndOcaAdvertisment struct {
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

func NewMDNSManager(netIface string) *MDNSManager {
	m := &MDNSManager{
		cmdCh:    make(chan any),
		netIface: netIface,
	}
	m.startLoop()
	return m
}

// StartFusionAdvertismentOnly starts only the Fusion mDNS service (no OCA).
func (m *MDNSManager) StartFusionAdvertismentOnly(ip net.IP) error {
	logger := logging.GetLogger()

	if ip == nil {
		logger.Error("[Discovery] StartFusionAdvertismentOnly called with nil IP")
		return fmt.Errorf("[Discovery] no IP available for mDNS service")
	}

	resp := make(chan error, 1)
	m.cmdCh <- cmdStartFusionAdvertismentOnly{ip: ip, resp: resp}
	err := <-resp

	return err
}

func (m *MDNSManager) StartFusionAndOcaAdvertisment(vip net.IP) error {
	logger := logging.GetLogger()

	if vip == nil {
		logger.Error("[Discovery] StartFusionAndOcaAdvertisment called with nil VIP")
		return fmt.Errorf("[Discovery] no VIP available for mDNS service")
	}

	resp := make(chan error, 1)
	m.cmdCh <- cmdStartFusionAndOcaAdvertisment{vip: vip, resp: resp}
	return <-resp
}

// Close can be called concurrently and is idempotent.
func (m *MDNSManager) Close() error {
	logger := logging.GetLogger()

	resp := make(chan error, 1)
	m.cmdCh <- cmdStop{resp: resp}
	err := <-resp

	if err != nil {
		logger.Error("[Discovery] Close failed: %v", err)
	}

	return err
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
	withOCA bool

	desiredRunning bool
	desiredVIP     net.IP
	desiredWithOCA bool
}

func (m *MDNSManager) loop() {
	logger := logging.GetLogger()

	st := loopState{}

	// Helper closures owned by loop goroutine only.
	newResponder := func() error {
		responder, err := dnssd.NewResponder()
		if err != nil {
			return fmt.Errorf("create responder: %w", err)
		}
		st.responder = responder
		return nil
	}

	stop := func() error {
		if !st.running {
			return nil
		}

		logger.Debug("[Discovery] Stopping mDNS responder (vip=%v withOCA=%v fusionHandle=%v ocaHandle=%v)",
			st.vip, st.withOCA, st.fusionHandle != nil, st.ocaHandle != nil)

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

		// The underlying responder closes its mDNS socket when Respond exits.
		// It cannot be safely reused for a future start.
		st.responder = nil
		st.running = false
		st.vip = nil
		st.withOCA = false
		st.ctx = nil
		logger.Debug("[Discovery] mDNS responder stopped")

		return nil
	}

	isExpectedRegistration := func(handle dnssd.ServiceHandle, serviceType string) bool {
		if handle == nil {
			return false
		}

		host := hostnameOrDefault()
		actual := handle.Service()
		expectedInstance := fmt.Sprintf("%s.%s.%s.", host, serviceType, mdnsDomain)
		expectedHost := fmt.Sprintf("%s.%s.", host, mdnsDomain)

		return actual.ServiceInstanceName() == expectedInstance &&
			strings.EqualFold(actual.Hostname(), expectedHost)
	}

	verifyLocalResolution := func(handle dnssd.ServiceHandle) {
		if handle == nil {
			return
		}

		instance := handle.Service().ServiceInstanceName()
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			defer cancel()

			svc, err := dnssd.LookupInstance(ctx, instance)
			if err != nil {
				logger.Warn("[Discovery] local mDNS resolve failed for %s: %v", instance, err)
				return
			}

			logger.Debug("[Discovery] local mDNS resolve succeeded for %s host=%s ips=%v port=%d",
				instance, svc.Hostname(), svc.IPs, svc.Port)
		}()
	}

	start := func(vip net.IP, withOCA bool) error {
		// If already running with same VIP/config, treat as idempotent success.
		if st.running && st.vip != nil && st.vip.Equal(vip) && st.withOCA == withOCA {
			logger.Debug("[Discovery] Already running with same VIP %v and withOCA=%v, treating as idempotent success", vip, withOCA)
			return nil
		}

		for attempt := 1; attempt <= 3; attempt++ {
			// If running with different VIP, restart.
			if st.running {
				logger.Debug("[Discovery] Restarting mDNS responder from VIP=%v to VIP=%v (withOCA %v -> %v)", st.vip, vip, st.withOCA, withOCA)
				if err := stop(); err != nil {
					logger.Error("[Discovery] Failed to stop existing services before restart: %v", err)
					return err
				}
			}

			if st.responder == nil {
				if err := newResponder(); err != nil {
					return fmt.Errorf("[Discovery] failed to create responder: %w", err)
				}
			}

			// Add Fusion service
			fusionHandle, err := addService(st.responder, fusionConfig(vip, m.netIface))
			if err != nil {
				logger.Error("[Discovery] Failed to add Fusion service: %v", err)
				return fmt.Errorf("add Fusion service: %w", err)
			}
			st.fusionHandle = fusionHandle

			if withOCA {
				ocaHandle, err := addService(st.responder, ocaConfig(vip, m.netIface))
				if err != nil {
					logger.Error("[Discovery] Failed to add OCA service, rolling back Fusion service: %v", err)
					// rollback Fusion so we never partially advertise
					st.responder.Remove(fusionHandle)
					st.fusionHandle = nil
					return fmt.Errorf("add OCA service: %w", err)
				}
				st.ocaHandle = ocaHandle
			}

			st.vip = vip
			st.withOCA = withOCA

			// Start responder loop
			st.ctx, st.cancel = context.WithCancel(context.Background())
			st.running = true

			st.respWg.Add(1)
			go func(ctx context.Context) {
				defer st.respWg.Done()
				if err := st.responder.Respond(ctx); err != nil {
					// Only log as error if we weren't cancelled.
					if ctx.Err() == nil {
						logger.Error("[Discovery] responder error: %v", err)
					}
				}
			}(st.ctx)

			// dnssd may automatically rename the service instance/host when a
			// previous registration has not fully disappeared yet. Retry until we
			// get the expected stable identity so clients can keep resolving the
			// node by hostname.
			if !isExpectedRegistration(st.fusionHandle, mdnsFusionServiceType) {
				actual := st.fusionHandle.Service()
				logger.Warn("[Discovery] mDNS registered unexpected Fusion identity on attempt %d: instance=%s host=%s; retrying",
					attempt,
					actual.ServiceInstanceName(),
					actual.Hostname(),
				)
				if err := stop(); err != nil {
					return fmt.Errorf("stop unexpected Fusion registration: %w", err)
				}
				time.Sleep(1 * time.Second)
				continue
			}

			if withOCA && !isExpectedRegistration(st.ocaHandle, mdnsOCAServiceType) {
				actual := st.ocaHandle.Service()
				logger.Warn("[Discovery] mDNS registered unexpected OCA identity on attempt %d: instance=%s host=%s; retrying",
					attempt,
					actual.ServiceInstanceName(),
					actual.Hostname(),
				)
				if err := stop(); err != nil {
					return fmt.Errorf("stop unexpected OCA registration: %w", err)
				}
				time.Sleep(1 * time.Second)
				continue
			}

			if withOCA {
				logger.Debug("[Discovery] mDNS started: VIP=%s hostname=%s fusion=%s.%s:%d oca=%s.%s:%d",
					vip, hostnameOrDefault(),
					hostnameOrDefault(), mdnsFusionServiceType, mdnsFusionVIPPort,
					hostnameOrDefault(), mdnsOCAServiceType, mdnsOCAServicePort,
				)
			} else {
				logger.Debug("[Discovery] mDNS started (Fusion only): VIP=%s hostname=%s fusion=%s.%s:%d",
					vip, hostnameOrDefault(),
					hostnameOrDefault(), mdnsFusionServiceType, mdnsFusionVIPPort,
				)
			}

			logger.Debug("[Discovery] Registered Fusion identity: instance=%s host=%s iface=%s",
				st.fusionHandle.Service().ServiceInstanceName(),
				st.fusionHandle.Service().Hostname(),
				m.netIface,
			)
			if withOCA && st.ocaHandle != nil {
				logger.Debug("[Discovery] Registered OCA identity: instance=%s host=%s iface=%s",
					st.ocaHandle.Service().ServiceInstanceName(),
					st.ocaHandle.Service().Hostname(),
					m.netIface,
				)
			}
			verifyLocalResolution(st.fusionHandle)

			return nil
		}

		return fmt.Errorf("mDNS registration identity did not stabilize for host %s", hostnameOrDefault())
	}

	reconcile := func() error {
		if !st.desiredRunning {
			return stop()
		}
		if st.desiredVIP == nil {
			return fmt.Errorf("desired mDNS VIP is nil")
		}
		return start(st.desiredVIP, st.desiredWithOCA)
	}

	for cmd := range m.cmdCh {
		var errResps []chan error
		shouldShutdown := false

		handle := func(command any) {
			switch c := command.(type) {
			case cmdStartFusionAdvertismentOnly:
				st.desiredRunning = true
				st.desiredVIP = c.ip
				st.desiredWithOCA = false
				errResps = append(errResps, c.resp)

			case cmdStartFusionAndOcaAdvertisment:
				st.desiredRunning = true
				st.desiredVIP = c.vip
				st.desiredWithOCA = true
				errResps = append(errResps, c.resp)

			case cmdStop:
				st.desiredRunning = false
				st.desiredVIP = nil
				st.desiredWithOCA = false
				errResps = append(errResps, c.resp)

			case cmdIsRunning:
				c.resp <- st.running

			case cmdShutdown:
				st.desiredRunning = false
				st.desiredVIP = nil
				st.desiredWithOCA = false
				errResps = append(errResps, c.resp)
				shouldShutdown = true

			default:
				logger.Warn("[Discovery] unknown command type %T", c)
			}
		}

		handle(cmd)

	drain:
		for {
			select {
			case nextCmd := <-m.cmdCh:
				handle(nextCmd)
			default:
				break drain
			}
		}

		err := reconcile()
		for _, resp := range errResps {
			resp <- err
		}

		if shouldShutdown {
			close(m.cmdCh)
			return
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

func fusionConfig(vip net.IP, netIface string) dnssd.Config {
	host := hostnameOrDefault()
	ifaces := []string{}
	if netIface != "" {
		ifaces = append(ifaces, netIface)
	}
	return dnssd.Config{
		Name:   host,
		Type:   mdnsFusionServiceType,
		Domain: mdnsDomain,
		// dnssd appends Domain when building the target hostname, so Host must
		// be the bare host label, not "host.local".
		Host:   host,
		Port:   mdnsFusionVIPPort,
		IPs:    []net.IP{vip},
		Ifaces: ifaces,
		Text: map[string]string{
			"version":  version.Version,
			"protocol": "http",
			"port":     strconv.Itoa(mdnsFusionVIPPort),
		},
	}
}

func ocaConfig(vip net.IP, netIface string) dnssd.Config {
	host := hostnameOrDefault()
	ifaces := []string{}
	if netIface != "" {
		ifaces = append(ifaces, netIface)
	}
	return dnssd.Config{
		Name:   host, // keeps your old behavior
		Type:   mdnsOCAServiceType,
		Domain: mdnsDomain,
		// dnssd appends Domain when building the target hostname, so Host must
		// be the bare host label, not "host.local".
		Host:   host,
		Port:   mdnsOCAServicePort,
		IPs:    []net.IP{vip},
		Ifaces: ifaces,
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

	svc, err := dnssd.NewService(cfg)
	if err != nil {
		return nil, fmt.Errorf("new service (%s %s): %w", cfg.Name, cfg.Type, err)
	}

	handle, err := r.Add(svc)
	if err != nil {
		return nil, fmt.Errorf("responder add (%s %s): %w", cfg.Name, cfg.Type, err)
	}

	return handle, nil
}
