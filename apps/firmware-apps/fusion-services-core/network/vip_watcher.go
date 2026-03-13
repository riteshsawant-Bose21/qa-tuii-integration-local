package network

import (
	"fmt"
	"net"
	"sync"

	"github.com/vishvananda/netlink"
)

const updateChannels = 16

type VIPWatcher struct {
	logger      Logger
	iface       string
	expectedVIP net.IPNet
	onUpdate    func(gained bool)

	mu      sync.Mutex
	done    chan struct{}
	running bool
	wg      sync.WaitGroup
}

func NewVIPWatcher(logger Logger, iface string) *VIPWatcher {
	return &VIPWatcher{
		logger: logger,
		iface:  iface,
	}
}

func (w *VIPWatcher) Start(expectedVIP net.IPNet, onUpdate func(gained bool)) error {
	w.mu.Lock()
	defer w.mu.Unlock()

	// Prevent starting if already running
	if w.running {
		return fmt.Errorf("watcher already running, call Stop() first")
	}

	w.expectedVIP = expectedVIP
	w.onUpdate = onUpdate
	w.done = make(chan struct{})

	w.logger.Debug("[VIP watcher] Starting VIP watcher on interface: %s for VIP: %s", w.iface, expectedVIP.String())

	link, err := netlink.LinkByName(w.iface)
	if err != nil {
		w.logger.Error("[VIP watcher] interface %s not found: %v", w.iface, err)
		return err
	}
	linkIndex := link.Attrs().Index
	w.logger.Debug("[VIP watcher] Interface resolved: %s index=%d", w.iface, linkIndex)
	w.wg.Add(1)
	go w.watch(linkIndex)
	w.running = true

	return nil
}

func (w *VIPWatcher) Stop() {
	w.mu.Lock()
	if w.running && w.done != nil {
		close(w.done)
		w.running = false
	}
	w.mu.Unlock()

	// Wait for watch goroutine to exit
	w.wg.Wait()
	w.logger.Debug("[VIP watcher] Stopped")
}

func (w *VIPWatcher) stopLocked() {
	if w.running && w.done != nil {
		close(w.done)
		w.running = false
		w.logger.Debug("[VIP watcher] Stopped")
	}
}

func (w *VIPWatcher) watch(linkIndex int) {
	defer w.wg.Done()

	updates := make(chan netlink.AddrUpdate, updateChannels)

	defer func() {
		w.logger.Debug("[VIP watcher] watcher goroutine exited")
	}()

	if err := netlink.AddrSubscribeWithOptions(
		updates, w.done,
		netlink.AddrSubscribeOptions{
			ErrorCallback: func(e error) {
				w.logger.Error("[VIP watcher] netlink error: %v", e)
			},
			ListExisting: true,
		},
	); err != nil {
		w.logger.Error("[VIP watcher] AddrSubscribe failed: %v", err)
		return
	}

	w.logger.Debug("[VIP watcher] AddrSubscribe active (ListExisting=true)")

	for {
		select {
		case <-w.done:
			return
		case update, ok := <-updates:
			if !ok {
				w.logger.Error("[VIP watcher] netlink updates channel closed")
				return
			}

			if update.LinkIndex != linkIndex {
				w.logger.Debug("[VIP watcher] ignoring update for linkIndex=%d (expected %d)", update.LinkIndex, linkIndex)
				continue
			}

			ip := update.LinkAddress.IP
			if ip == nil || ip.To4() == nil {
				w.logger.Debug("[VIP watcher] ignoring non-IPv4 update: %v", update.LinkAddress)
				continue
			}

			w.logger.Debug("[VIP watcher] received update for IP: %s, NewAddr: %v", ip, update.NewAddr)

			w.mu.Lock()
			expectedVIP := w.expectedVIP
			onUpdate := w.onUpdate
			w.mu.Unlock()

			expectedIP := expectedVIP.IP
			if expectedIP == nil {
				w.logger.Error("[VIP watcher] expected VIP IP is not set: expected=%s", expectedVIP.String())
				continue
			}
			if expectedIP.To4() != nil {
				expectedIP = expectedIP.To4()
			}
			if !ip.Equal(expectedIP) {
				w.logger.Debug("[VIP watcher] ignoring IP not in expected VIP: ip=%s expected=%s", ip, expectedVIP.String())
				continue
			}

			if update.NewAddr {
				w.logger.Info("[VIP watcher] VIP gained: %s", ip)
				onUpdate(true)
			} else {
				w.logger.Info("[VIP watcher] VIP lost: %s", ip)
				onUpdate(false)
			}
		}
	}
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
