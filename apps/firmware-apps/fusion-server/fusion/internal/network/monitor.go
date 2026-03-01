package network

import (
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/utils"
	"net"
	"sync"
	"time"
)

type ChangeCallback func(oldIP, newIP string)

type Monitor struct {
	interval time.Duration
	lastIP   string
	onChange ChangeCallback
	stopChan chan struct{}
	wg       sync.WaitGroup
	iface    string
}

func NewMonitor(interval time.Duration, iface string, cb ChangeCallback) *Monitor {
	return &Monitor{
		interval: interval,
		onChange: cb,
		stopChan: make(chan struct{}),
		iface:    iface,
	}
}

func (m *Monitor) Start() error {

	logger := logging.GetLogger()

	ip, err := utils.GetLocalIPByInterface(m.iface)
	if err != nil {
		return err
	}
	m.lastIP = ip

	m.wg.Add(1)
	go func() {

		defer m.wg.Done()
		ticker := time.NewTicker(m.interval)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				current, err := utils.GetLocalIPByInterface(m.iface)
				if err != nil {
					logger.Error("Failed to get IP: %v", err)
					continue
				}

				if current != m.lastIP {
					logger.Debug("[NETWORK] IP change detected: %s -> %s", m.lastIP, current)
					m.onChange(m.lastIP, current)
					m.lastIP = current
				}
			case <-m.stopChan:
				return
			}
		}
	}()
	return nil
}

func (m *Monitor) Stop() {
	close(m.stopChan)
	m.wg.Wait()
}

// getLocalIP returns the primary IP address used for outbound communication
func getLocalIP() (string, error) {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "", err
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String(), nil
}

// GetMacAddress returns the MAC address of the primary network interface
func GetMacAddress() (string, error) {
	logger := logging.GetLogger()

	// Get the local IP to identify which interface is primary
	localIP, err := getLocalIP()
	if err != nil {
		logger.Info("GetMacAddress: failed to get local IP: %v", err)
		return "", err
	}
	logger.Info("GetMacAddress: local IP is %s", localIP)

	// Get all network interfaces
	interfaces, err := net.Interfaces()
	if err != nil {
		logger.Info("GetMacAddress: failed to get network interfaces: %v", err)
		return "", err
	}
	logger.Info("GetMacAddress: found %d network interfaces", len(interfaces))

	// Find the interface with the matching IP
	for _, iface := range interfaces {
		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			ipNet, ok := addr.(*net.IPNet)
			if !ok {
				continue
			}

			// Check if this interface has our local IP
			if ipNet.IP.String() == localIP {
				// Return the hardware address (MAC)
				if len(iface.HardwareAddr) > 0 {
					macAddr := iface.HardwareAddr.String()
					logger.Info("GetMacAddress: found MAC address %s for interface %s", macAddr, iface.Name)
					return macAddr, nil
				}
			}
		}
	}

	logger.Info("GetMacAddress: no MAC address found for IP %s", localIP)
	return "", fmt.Errorf("no MAC address found for IP %s", localIP)
}
