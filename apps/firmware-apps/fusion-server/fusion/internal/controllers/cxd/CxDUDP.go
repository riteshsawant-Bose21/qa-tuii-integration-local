package cxd

import (
	"bytes"
	"crypto/sha1"
	"encoding/binary"
	"fmt"
	"net"
	"strings"
	"syscall"
	"time"

	"github.com/google/uuid"
)

// Controller handles UDP communication with devices
type Controller struct {
	conn *net.UDPConn
}

func NewController() (*Controller, error) {
	// Create socket with broadcast permission
	conn, err := net.ListenUDP("udp4", &net.UDPAddr{
		IP:   net.IPv4zero,
		Port: defaultPort,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create UDP connection: %w", err)
	}

	// Set socket options for broadcast using syscall
	fd, err := conn.File()
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to get socket file descriptor: %w", err)
	}
	defer fd.Close()

	err = syscall.SetsockoptInt(int(fd.Fd()), syscall.SOL_SOCKET, syscall.SO_BROADCAST, 1)
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("failed to set broadcast permission: %w", err)
	}

	return &Controller{
		conn: conn,
	}, nil
}

// Close closes the UDP connection
func (c *Controller) Close() error {
	return c.conn.Close()
}

// generateGUID generates a UUID v1 for the session
func generateGUID() ([16]byte, error) {
	var result [16]byte

	// Generate UUID v1
	id, err := uuid.NewUUID()
	if err != nil {
		return result, err
	}

	// Get bytes
	b, err := id.MarshalBinary()
	if err != nil {
		return result, err
	}

	// Reorder bytes to match protocol
	binary.LittleEndian.PutUint32(result[0:], binary.BigEndian.Uint32(b[0:]))
	binary.LittleEndian.PutUint16(result[4:], binary.BigEndian.Uint16(b[4:]))
	binary.LittleEndian.PutUint16(result[6:], binary.BigEndian.Uint16(b[6:]))
	copy(result[8:], b[8:])

	return result, nil
}

// calculateHash computes SHA1 hash of data
func calculateHash(data []byte) []byte {
	h := sha1.New()
	h.Write(data)
	return h.Sum(nil)
}

// Discover finds all wall controller devices
func (c *Controller) Discover() ([]*Device, error) {
	guid, err := generateGUID()
	if err != nil {
		return nil, fmt.Errorf("failed to generate GUID: %w", err)
	}

	// Create query message
	buf := &bytes.Buffer{}
	buf.Write(guid[:])
	binary.Write(buf, binary.LittleEndian, cmdQuery)
	binary.Write(buf, binary.LittleEndian, uint16(0))

	hash := calculateHash(buf.Bytes())
	buf.Write(hash)

	// Send broadcast
	broadcastAddr := &net.UDPAddr{
		IP:   net.ParseIP(broadcastAddr),
		Port: defaultPort,
	}

	if _, err := c.conn.WriteToUDP(buf.Bytes(), broadcastAddr); err != nil {
		return nil, fmt.Errorf("failed to send discover message: %w", err)
	}

	devices := make(map[string]*Device)
	deadline := time.Now().Add(messageTimeout * time.Second)

	for time.Now().Before(deadline) {
		resp := make([]byte, maxMessageSize)
		c.conn.SetReadDeadline(time.Now().Add(time.Second))

		n, _, err := c.conn.ReadFromUDP(resp)
		if err != nil {
			if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
				continue
			}
			return nil, fmt.Errorf("failed to read response: %w", err)
		}

		// Verify hash
		msgHash := resp[n-hashSize:]
		calcHash := calculateHash(resp[:n-hashSize])
		if !bytes.Equal(msgHash, calcHash) {
			continue
		}

		// Parse based on response type
		cmd := binary.LittleEndian.Uint16(resp[4:6])
		switch cmd {
		case respQuery:
			device, err := parseQueryResponse(resp[:n])
			if err != nil {
				continue
			}

			// Get version
			version, err := c.GetVersion(device)
			if err == nil {
				device.FirmwareVersion = version
			}

			hwIDStr := fmt.Sprintf("%x", device.HardwareID)
			devices[hwIDStr] = device

		case respQuery2:
			info, err := parseQuery2Response(resp[:n])
			if err != nil {
				continue
			}
			hwIDStr := fmt.Sprintf("%x", info.HardwareID)
			if device, exists := devices[hwIDStr]; exists {
				device.OperationMode = info.OperationMode
			}
		}
	}

	// Convert map to slice
	result := make([]*Device, 0, len(devices))
	for _, device := range devices {
		result = append(result, device)
	}

	return result, nil
}

// SetStaticIP configures static IP settings for a device
func (c *Controller) SetStaticIP(device *Device, ip net.IP, subnet net.IPMask, gateway net.IP) error {
	guid, err := generateGUID()
	if err != nil {
		return fmt.Errorf("failed to generate GUID: %w", err)
	}

	// Create setup network message
	buf := &bytes.Buffer{}

	// Write header
	buf.Write(guid[:])
	WriteUint16LE(buf, cmdSetupNW)
	WriteUint16LE(buf, 108) // Fixed payload length per spec

	// Write payload
	// Hardware ID
	for _, id := range device.HardwareID {
		WriteUint32LE(buf, id)
	}

	// MAC Address
	buf.Write(device.MAC)

	// DHCP and Operation Mode
	if device.DHCPEnabled {
		buf.WriteByte(1)
	} else {
		buf.WriteByte(0)
	}
	buf.WriteByte(device.OperationMode)

	// Network settings
	buf.Write(ip.To4())
	buf.Write(subnet)
	buf.Write(gateway.To4())

	// Fixed-length strings
	WriteFixedString(buf, device.ModelID, modelIDSize)
	WriteFixedString(buf, device.SerialNum, serialNumSize)
	WriteFixedString(buf, device.Name, nameSize)

	// Calculate and write hash
	hash := calculateHash(buf.Bytes())
	buf.Write(hash)

	// Send message
	broadcastAddr := &net.UDPAddr{
		IP:   net.ParseIP(broadcastAddr),
		Port: defaultPort,
	}

	if _, err := c.conn.WriteToUDP(buf.Bytes(), broadcastAddr); err != nil {
		return fmt.Errorf("failed to send setup message: %w", err)
	}

	// Wait for response
	resp := make([]byte, maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(messageTimeout * time.Second))

	n, _, err := c.conn.ReadFromUDP(resp)
	if err != nil {
		return fmt.Errorf("failed to read setup response: %w", err)
	}

	// Verify response
	if n < 12 { // Minimum size for response header and result
		return fmt.Errorf("response too short")
	}

	cmd := ReadUint16LE(resp[4:6])
	if cmd != respSetupNW {
		return fmt.Errorf("unexpected response command: %04x", cmd)
	}

	// Check result (4 bytes at offset 8)
	result := ReadUint32LE(resp[8:12])
	if result != 1 {
		return fmt.Errorf("setup failed with result: %d", result)
	}

	// Verify hash
	msgHash := resp[n-hashSize:]
	calcHash := calculateHash(resp[:n-hashSize])
	if !bytes.Equal(msgHash, calcHash) {
		return fmt.Errorf("invalid response hash")
	}

	return nil
}

// Update sends current device settings
func (c *Controller) Update(device *Device) error {
	return c.SetStaticIP(device, device.StaticIP, device.SubnetMask, device.Gateway)
}

// GetVersion queries device firmware version
func (c *Controller) GetVersion(device *Device) (string, error) {
	addr := &net.UDPAddr{
		IP:   device.IP,
		Port: defaultPort,
	}

	// Send version query
	if _, err := c.conn.WriteToUDP([]byte("?Version"), addr); err != nil {
		return "", fmt.Errorf("failed to send version query: %w", err)
	}

	// Read response
	resp := make([]byte, maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(messageTimeout * time.Second))

	n, _, err := c.conn.ReadFromUDP(resp)
	if err != nil {
		return "", fmt.Errorf("failed to read version response: %w", err)
	}

	// Parse version from response (format: <header byte><title 8 bytes><version n bytes><tail byte>)
	if n < 10 {
		return "", fmt.Errorf("version response too short")
	}

	versionBytes := resp[9 : n-1] // Skip header byte and title, trim end byte
	return strings.TrimRight(string(versionBytes), "\x00"), nil
}

// parseQueryResponse parses the first query response message (RESP_QUERY)
func parseQueryResponse(data []byte) (*Device, error) {
	device := NewDevice()
	if len(data) < 8+116 { // Header + minimum payload size
		return nil, fmt.Errorf("response too short")
	}

	r := bytes.NewReader(data[8 : len(data)-hashSize]) // Skip header and hash

	// Read hardware ID
	for i := range 4 {
		if err := binary.Read(r, binary.LittleEndian, &device.HardwareID[i]); err != nil {
			return nil, fmt.Errorf("failed to read hardware ID: %w", err)
		}
	}

	// Read hardware ID
	for i := range 4 {
		if err := binary.Read(r, binary.LittleEndian, &device.HardwareID[i]); err != nil {
			return device, fmt.Errorf("failed to read hardware ID: %w", err)
		}
	}

	// Read IP address
	ip := make([]byte, 4)
	if _, err := r.Read(ip); err != nil {
		return device, fmt.Errorf("failed to read IP: %w", err)
	}
	device.IP = net.IP(ip)

	// Read MAC address
	mac := make([]byte, 6)
	if _, err := r.Read(mac); err != nil {
		return device, fmt.Errorf("failed to read MAC: %w", err)
	}
	device.MAC = mac

	// Read DHCP flag
	dhcp, err := r.ReadByte()
	if err != nil {
		return device, fmt.Errorf("failed to read DHCP flag: %w", err)
	}
	device.DHCPEnabled = dhcp != 0

	// Read static IP
	staticIP := make([]byte, 4)
	if _, err := r.Read(staticIP); err != nil {
		return device, fmt.Errorf("failed to read static IP: %w", err)
	}
	device.StaticIP = net.IP(staticIP)

	// Read subnet mask
	subnet := make([]byte, 4)
	if _, err := r.Read(subnet); err != nil {
		return device, fmt.Errorf("failed to read subnet mask: %w", err)
	}
	device.SubnetMask = net.IPMask(subnet)

	// Read gateway
	gateway := make([]byte, 4)
	if _, err := r.Read(gateway); err != nil {
		return device, fmt.Errorf("failed to read gateway: %w", err)
	}
	device.Gateway = net.IP(gateway)

	// Read model ID
	modelID := make([]byte, modelIDSize)
	if _, err := r.Read(modelID); err != nil {
		return device, fmt.Errorf("failed to read model ID: %w", err)
	}
	device.ModelID = ReadFixedString(modelID, modelIDSize)

	// Read serial number
	serialNum := make([]byte, serialNumSize)
	if _, err := r.Read(serialNum); err != nil {
		return device, fmt.Errorf("failed to read serial number: %w", err)
	}
	device.SerialNum = ReadFixedString(serialNum, serialNumSize)

	// Read name
	name := make([]byte, nameSize)
	if _, err := r.Read(name); err != nil {
		return device, fmt.Errorf("failed to read name: %w", err)
	}
	device.Name = ReadFixedString(name, nameSize)

	// Read port
	var port uint16
	if err := binary.Read(r, binary.LittleEndian, &port); err != nil {
		return device, fmt.Errorf("failed to read port: %w", err)
	}
	device.Port = port

	// Skip unknown bytes
	if _, err := r.ReadByte(); err != nil {
		return device, fmt.Errorf("failed to read unknown bytes: %w", err)
	}
	if _, err := r.ReadByte(); err != nil {
		return device, fmt.Errorf("failed to read unknown bytes: %w", err)
	}

	// Initialize state map
	device.state = make(map[string]string)

	return device, nil
}

// parseQuery2Response parses the second query response message (RESP_QUERY2)
func parseQuery2Response(data []byte) (*Device, error) {
	device := NewDevice()
	if len(data) < 8+21 { // Header + minimum payload size
		return nil, fmt.Errorf("response too short")
	}

	payload := data[8 : len(data)-hashSize] // Skip header and hash

	// Check tags
	if payload[0] != 0xA0 { // Hardware ID tag
		return device, fmt.Errorf("invalid hardware ID tag: %02x", payload[0])
	}
	if payload[1] != 16 { // Hardware ID length
		return device, fmt.Errorf("invalid hardware ID length: %d", payload[1])
	}

	// Read hardware ID
	r := bytes.NewReader(payload[2:])
	for i := range 4 {
		if err := binary.Read(r, binary.LittleEndian, &device.HardwareID[i]); err != nil {
			return device, fmt.Errorf("failed to read hardware ID: %w", err)
		}
	}

	// Check operation mode tag
	opModeTag, err := r.ReadByte()
	if err != nil || opModeTag != 0xA1 {
		return device, fmt.Errorf("invalid operation mode tag")
	}

	opModeLen, err := r.ReadByte()
	if err != nil || opModeLen != 1 {
		return device, fmt.Errorf("invalid operation mode length")
	}

	// Read operation mode
	opMode, err := r.ReadByte()
	if err != nil {
		return device, fmt.Errorf("failed to read operation mode: %w", err)
	}
	device.OperationMode = opMode

	// Initialize state map
	device.state = make(map[string]string)

	return device, nil
}
