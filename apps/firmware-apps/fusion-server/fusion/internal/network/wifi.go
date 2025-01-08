package network

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"sync"
	"time"
)

// Device represents a discovered network device
type Device struct {
	ID       string    `json:"device_id"`
	Name     string    `json:"device_name"`
	IP       string    `json:"ip"`
	LastSeen time.Time `json:"last_seen"`
}

// Message represents the structure of network messages
type Message struct {
	Type       string `json:"type"`
	DeviceID   string `json:"device_id"`
	DeviceName string `json:"device_name"`
	IP         string `json:"ip"`
	Content    string `json:"content,omitempty"`
}

// Communicator handles device discovery and communication
type WifiCommunicator struct {
	deviceID   string
	deviceName string
	localIP    string
	port       int

	devices    map[string]Device
	devicesMux sync.RWMutex

	stopping chan struct{}
	stopped  sync.WaitGroup
}

// NewWifiCommunicator creates a new device communicator
func NewWifiCommunicator(deviceID, deviceName string, port int) (*WifiCommunicator, error) {
	// Get local IP address
	localIP, err := getLocalIP()
	if err != nil {
		return nil, fmt.Errorf("failed to get local IP: %v", err)
	}

	return &WifiCommunicator{
		deviceID:   deviceID,
		deviceName: deviceName,
		localIP:    localIP,
		port:       port,
		devices:    make(map[string]Device),
		stopping:   make(chan struct{}),
	}, nil
}

// Start begins the device discovery and communication processes
func (c *WifiCommunicator) Start() error {
	// Start discovery broadcast
	c.stopped.Add(1)
	go c.broadcastPresence()

	// Start discovery listener
	c.stopped.Add(1)
	go c.listenForDiscovery()

	// Start TCP message listener
	c.stopped.Add(1)
	go c.listenForMessages()

	log.Printf("Device %s (%s) started on %s:%d\n", c.deviceName, c.deviceID, c.localIP, c.port)
	return nil
}

// Stop gracefully shuts down the communicator
func (c *WifiCommunicator) Stop() {
	close(c.stopping)
	c.stopped.Wait()
}

// SendMessage sends a message to a specific device
func (c *WifiCommunicator) SendMessage(targetID string, content string) error {
	c.devicesMux.RLock()
	device, exists := c.devices[targetID]
	c.devicesMux.RUnlock()

	if !exists {
		return fmt.Errorf("device %s not found", targetID)
	}

	conn, err := net.Dial("tcp", fmt.Sprintf("%s:%d", device.IP, c.port))
	if err != nil {
		return fmt.Errorf("failed to connect to device: %v", err)
	}
	defer conn.Close()

	msg := Message{
		Type:       "message",
		DeviceID:   c.deviceID,
		DeviceName: c.deviceName,
		IP:         c.localIP,
		Content:    content,
	}

	encoder := json.NewEncoder(conn)
	return encoder.Encode(msg)
}

// GetDevices returns a list of all discovered devices
func (c *WifiCommunicator) GetDevices() []Device {
	c.devicesMux.RLock()
	defer c.devicesMux.RUnlock()

	devices := make([]Device, 0, len(c.devices))
	for _, device := range c.devices {
		devices = append(devices, device)
	}
	return devices
}

func (c *WifiCommunicator) broadcastPresence() {
	defer c.stopped.Done()

	addr := fmt.Sprintf("255.255.255.255:%d", c.port)
	conn, err := net.Dial("udp", addr)
	if err != nil {
		log.Printf("Failed to create broadcast connection: %v\n", err)
		return
	}
	defer conn.Close()

	msg := Message{
		Type:       "presence",
		DeviceID:   c.deviceID,
		DeviceName: c.deviceName,
		IP:         c.localIP,
	}

	data, err := json.Marshal(msg)
	if err != nil {
		log.Printf("Failed to marshal presence message: %v\n", err)
		return
	}

	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-c.stopping:
			return
		case <-ticker.C:
			if _, err := conn.Write(data); err != nil {
				log.Printf("Failed to broadcast presence: %v\n", err)
			}
		}
	}
}

func (c *WifiCommunicator) listenForDiscovery() {
	defer c.stopped.Done()

	addr := fmt.Sprintf(":%d", c.port)
	conn, err := net.ListenPacket("udp", addr)
	if err != nil {
		log.Printf("Failed to create discovery listener: %v\n", err)
		return
	}
	defer conn.Close()

	buffer := make([]byte, 1024)
	for {
		select {
		case <-c.stopping:
			return
		default:
			conn.SetReadDeadline(time.Now().Add(1 * time.Second))
			n, _, err := conn.ReadFrom(buffer)
			if err != nil {
				if !isTimeout(err) {
					log.Printf("Failed to read discovery message: %v\n", err)
				}
				continue
			}

			var msg Message
			if err := json.Unmarshal(buffer[:n], &msg); err != nil {
				log.Printf("Failed to unmarshal discovery message: %v\n", err)
				continue
			}

			if msg.Type == "presence" && msg.DeviceID != c.deviceID {
				c.devicesMux.Lock()
				c.devices[msg.DeviceID] = Device{
					ID:       msg.DeviceID,
					Name:     msg.DeviceName,
					IP:       msg.IP,
					LastSeen: time.Now(),
				}
				c.devicesMux.Unlock()
				log.Printf("Discovered device: %s (%s)\n", msg.DeviceName, msg.IP)
			}
		}
	}
}

func (c *WifiCommunicator) listenForMessages() {
	defer c.stopped.Done()

	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", c.port))
	if err != nil {
		log.Printf("Failed to create message listener: %v\n", err)
		return
	}
	defer listener.Close()

	for {
		select {
		case <-c.stopping:
			return
		default:
			conn, err := listener.Accept()
			if err != nil {
				log.Printf("Failed to accept connection: %v\n", err)
				continue
			}

			go c.handleMessage(conn)
		}
	}
}

func (c *WifiCommunicator) handleMessage(conn net.Conn) {
	defer conn.Close()

	var msg Message
	decoder := json.NewDecoder(conn)
	if err := decoder.Decode(&msg); err != nil {
		log.Printf("Failed to decode message: %v\n", err)
		return
	}

	if msg.Type == "message" {
		log.Printf("Received message from %s: %s\n", msg.DeviceName, msg.Content)
	}
}

// Helper functions
func getLocalIP() (string, error) {
	conn, err := net.Dial("udp", "8.8.8.8:80")
	if err != nil {
		return "", err
	}
	defer conn.Close()

	localAddr := conn.LocalAddr().(*net.UDPAddr)
	return localAddr.IP.String(), nil
}

func isTimeout(err error) bool {
	if netErr, ok := err.(net.Error); ok {
		return netErr.Timeout()
	}
	return false
}

// 	comm, err := NewWifiCommunicator("fusion01", "Fusion One", 5000)
// 	if err != nil {
// 		log.Fatalf("Failed to create communicator: %v", err)
// 	}

// 	if err := comm.Start(); err != nil {
// 		log.Fatalf("Failed to start communicator: %v", err)
// 	}

// 	// Keep the program running
// 	select {}
// }
