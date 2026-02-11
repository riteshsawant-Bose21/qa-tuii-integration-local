package network

import (
	"fusion-services-core/logging"
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
}

func NewMonitor(interval time.Duration, cb ChangeCallback) *Monitor {
	return &Monitor{
		interval: interval,
		onChange: cb,
		stopChan: make(chan struct{}),
	}
}

func (m *Monitor) Start() error {

	logger := logging.GetLogger()

	ip, err := getLocalIP()
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
				current, err := getLocalIP()
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
