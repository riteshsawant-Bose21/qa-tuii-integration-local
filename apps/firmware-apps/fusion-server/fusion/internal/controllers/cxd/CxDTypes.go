package cxd

import (
	"fmt"
	"net"
	"sync"
)

// Command codes
const (
	cmdQuery    uint16 = 0xC101 // 49409 little-endian
	cmdSetupNW  uint16 = 0xC102 // 49410 little-endian
	cmdReboot   uint16 = 0xC103 // 49411 little-endian
	respQuery   uint16 = 0x5501 // 21761 little-endian
	respQuery2  uint16 = 0x5504 // 21764 little-endian
	respReboot  uint16 = 0x5503 // 21763 little-endian
	respSetupNW uint16 = 0x5502 // 21762 little-endian
)

// Protocol constants
const (
	defaultPort    = 9010
	broadcastAddr  = "255.255.255.255"
	messageTimeout = 5 // seconds
	maxMessageSize = 1024
	hardwareIDSize = 16
	guidSize       = 16
	hashSize       = 20
	modelIDSize    = 8
	serialNumSize  = 24
	nameSize       = 40
)

// Operation modes
const (
	OpModeCSP byte = 0x01
	// Add other operation modes as needed
)

// Device represents a wall controller device
type Device struct {
	HardwareID      [4]uint32
	MAC             net.HardwareAddr
	IP              net.IP
	StaticIP        net.IP
	SubnetMask      net.IPMask
	Gateway         net.IP
	ModelID         string
	SerialNum       string
	Name            string
	Port            uint16
	DHCPEnabled     bool
	OperationMode   byte
	FirmwareVersion string

	// Internal state
	state    map[string]string
	stateMux sync.RWMutex
}

// Config represents device configuration
type Config struct {
	Type          string     `json:"type"`
	Name          string     `json:"name"`
	IP            net.IP     `json:"ip"`
	SubnetMask    net.IPMask `json:"subnet_mask"`
	Gateway       net.IP     `json:"gateway"`
	DHCPEnabled   bool       `json:"dhcp_enabled"`
	OperationMode byte       `json:"operation_mode"`
}

// Error types
type DeviceError struct {
	Code    string
	Message string
	Err     error
}

// Error codes
const (
	ErrInvalidDevice    = "INVALID_DEVICE"
	ErrNotConnected     = "NOT_CONNECTED"
	ErrAlreadyConnected = "ALREADY_CONNECTED"
	ErrTimeout          = "TIMEOUT"
)

func (e *DeviceError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%s: %s (%v)", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}
