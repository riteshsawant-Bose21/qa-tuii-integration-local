package network

import (
	"fmt"
	"net"
	"strings"
	"sync"
	"time"

	"github.com/vishvananda/netlink"
)

const updateChannels = 16
const stopWaitTimeout = 2 * time.Second

type VIPWatcher struct {
	logger      Logger
	iface       string
	expectedVIP net.IPNet
	onUpdate    func(gained bool)

	mu      sync.Mutex
	done    chan struct{}
	running bool
	runID   uint64
	wg      sync.WaitGroup
}

func (w *VIPWatcher) isStopping() bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	return !w.running || w.done == nil
}

func shouldSuppressNetlinkError(err error) bool {
	if err == nil {
		return false
	}

	msg := err.Error()
	return strings.Contains(msg, "use of closed file") ||
		strings.Contains(msg, "resource temporarily unavailable") ||
		strings.Contains(msg, "Wrong sender portid")
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
	w.runID++
	runID := w.runID

	link, err := netlink.LinkByName(w.iface)
	if err != nil {
		w.logger.Error("[VIP watcher] interface %s not found: %v", w.iface, err)
		return err
	}
	linkIndex := link.Attrs().Index
	w.wg.Add(1)
	go w.watch(linkIndex, w.done, runID)
	w.running = true

	return nil
}

func (w *VIPWatcher) Stop() {
	w.mu.Lock()
	done := w.done
	if w.running && done != nil {
		close(done)
		w.running = false
		w.done = nil
	}
	w.mu.Unlock()

	waitDone := make(chan struct{})
	go func() {
		w.wg.Wait()
		close(waitDone)
	}()

	select {
	case <-waitDone:
	case <-time.After(stopWaitTimeout):
		w.logger.Error("[VIP watcher] Stop timed out after %s; continuing without blocking", stopWaitTimeout)
	}
}

func (w *VIPWatcher) stopLocked() {
	if w.running && w.done != nil {
		close(w.done)
		w.running = false
		w.logger.Debug("[VIP watcher] Stopped")
	}
}

func (w *VIPWatcher) watch(linkIndex int, done <-chan struct{}, runID uint64) {
	defer w.wg.Done()

	updates := make(chan netlink.AddrUpdate, updateChannels)

	if err := netlink.AddrSubscribeWithOptions(
		updates, done,
		netlink.AddrSubscribeOptions{
			ErrorCallback: func(e error) {
				if shouldSuppressNetlinkError(e) {
					w.logger.Debug("[VIP watcher] suppressing transient netlink error: %v", e)
					return
				}
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
		case <-done:
			return
		case update, ok := <-updates:
			if !ok {
				w.logger.Debug("[VIP watcher] netlink updates channel closed")
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
			isCurrentRun := w.runID == runID
			w.mu.Unlock()

			if !isCurrentRun {
				w.logger.Debug("[VIP watcher] ignoring stale update from previous run: runID=%d", runID)
				continue
			}

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
				w.logger.Debug("[VIP watcher] VIP gained: %s", ip)
				go onUpdate(true)
			} else {
				w.logger.Debug("[VIP watcher] VIP lost: %s", ip)
				go onUpdate(false)
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
