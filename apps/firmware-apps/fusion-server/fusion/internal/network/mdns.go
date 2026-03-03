package network

import (
	"context"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/version"
	"net"
	"os"
	"strconv"
	"sync"

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
	cmdCh chan any
	once  sync.Once
	wg    sync.WaitGroup // waits for loop exit (optional)
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

func NewMDNSManager() *MDNSManager {
	m := &MDNSManager{
		cmdCh: make(chan any),
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
	logger.Debug("[Discovery] Stopping mDNS")

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
}

func (m *MDNSManager) loop() {
	logger := logging.GetLogger()

	st := loopState{}

	responder, err := dnssd.NewResponder()
	if err != nil {
		logger.Error("[Discovery] Failed to create responder: %v", err)
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

		return nil
	}

	start := func(vip net.IP, withOCA bool) error {
		if st.responder == nil {
			return fmt.Errorf("mDNS responder not available")
		}

		// If already running with same VIP, treat as idempotent success.
		//Commented out to see if we do unneccesory calls to do restarts. We can optimize later if needed
		// if st.running && st.vip != nil && st.vip.Equal(vip) {
		// 	logger.Debug("[Discovery] Already running with same VIP %v, treating as idempotent success", vip)
		// 	return nil
		// }

		// If running with different VIP, restart.
		if st.running {
			logger.Debug("[Discovery] Already running (current VIP: %v, new: %v, current withOCA: %v, new: %v), stopping first", st.vip, vip, st.withOCA, withOCA)
			if err := stop(); err != nil {
				logger.Error("[Discovery] Failed to stop existing services before restart: %v", err)
				return err
			}

			// Create new responder
			newResponder, err := dnssd.NewResponder()
			if err != nil {
				return fmt.Errorf("[Discovery] failed to create fresh responder: %w", err)
			}
			st.responder = newResponder
		}

		// Add Fusion service
		fusionHandle, err := addService(st.responder, fusionConfig(vip))
		if err != nil {
			logger.Error("[Discovery] Failed to add Fusion service: %v", err)
			return fmt.Errorf("add Fusion service: %w", err)
		}
		st.fusionHandle = fusionHandle

		if withOCA {
			ocaHandle, err := addService(st.responder, ocaConfig(vip))
			if err != nil {
				logger.Error("[Discovery] Failed to add OCA service, rolling back Fusion service: %v", err)
				// rollback Fusion so we never partially advertise
				st.responder.Remove(fusionHandle)
				logger.Debug("[Discovery] Fusion service rolled back due to OCA service failure")
				return fmt.Errorf("add OCA service: %w", err)
			}
			st.ocaHandle = ocaHandle

		}

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
					logger.Error("[Discovery] responder error: %v", err)
				}
			}
		}(st.ctx)

		if withOCA {
			logger.Info("[Discovery] mDNS started: VIP=%s hostname=%s fusion=%s.%s:%d oca=%s.%s:%d",
				vip, hostnameOrDefault(),
				hostnameOrDefault(), mdnsFusionServiceType, mdnsFusionVIPPort,
				hostnameOrDefault(), mdnsOCAServiceType, mdnsOCAServicePort,
			)
		} else {
			logger.Info("[Discovery] mDNS started (Fusion only): VIP=%s hostname=%s fusion=%s.%s:%d",
				vip, hostnameOrDefault(),
				hostnameOrDefault(), mdnsFusionServiceType, mdnsFusionVIPPort,
			)
		}

		return nil
	}

	for cmd := range m.cmdCh {
		switch c := cmd.(type) {
		case cmdStartFusionAdvertismentOnly:
			err := start(c.ip, false)
			c.resp <- err

		case cmdStartFusionAndOcaAdvertisment:
			err := start(c.vip, true)
			c.resp <- err

		case cmdStop:
			err := stop()
			c.resp <- err

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
			logger.Warn("[Discovery] unknown command type %T", c)
		}
	}
	logger.Debug("[Discovery] Command loop exited")
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
		Name:   host,
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
