//go:build darwin

package network

import "net"

type VIPWatcher struct {
	logger Logger
	iface  string
}

func NewVIPWatcher(logger Logger, iface string) *VIPWatcher {
	if logger == nil {
		logger = noopLogger{}
	}
	return &VIPWatcher{
		logger: logger,
		iface:  iface,
	}
}

func (w *VIPWatcher) Start(expectedVIP net.IPNet, onUpdate func(gained bool)) error {
	w.logger.Debug("[VIP watcher] netlink watcher is disabled on darwin for iface=%s vip=%s", w.iface, expectedVIP.String())
	return nil
}

func (w *VIPWatcher) Stop() {}
