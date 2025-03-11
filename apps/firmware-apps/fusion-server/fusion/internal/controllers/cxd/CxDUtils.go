package cxd

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"net"
	"strings"
)

// ParseMAC parses a MAC address string with either : or - separators
func ParseMAC(s string) (net.HardwareAddr, error) {
	mac, err := net.ParseMAC(strings.ReplaceAll(s, "-", ":"))
	if err != nil {
		return nil, &DeviceError{
			Code:    "INVALID_MAC",
			Message: "invalid MAC address format",
			Err:     err,
		}
	}
	return mac, nil
}

// FormatMAC formats a MAC address with - separators
func FormatMAC(mac net.HardwareAddr) string {
	parts := make([]string, len(mac))
	for i, b := range mac {
		parts[i] = fmt.Sprintf("%02x", b)
	}
	return strings.Join(parts, "-")
}

// IPToString converts an IP address to string without IPv6 zones
func IPToString(ip net.IP) string {
	if ip == nil {
		return ""
	}
	return ip.String()
}

// WriteFixedString writes a string to a buffer with fixed length and null padding
func WriteFixedString(buf *bytes.Buffer, s string, size int) {
	b := make([]byte, size)
	copy(b, s)
	buf.Write(b)
}

// ReadFixedString reads a fixed-length string and trims null bytes
func ReadFixedString(data []byte, size int) string {
	if len(data) < size {
		return ""
	}
	return strings.TrimRight(string(data[:size]), "\x00")
}

// HardwareIDToString converts a hardware ID to string
func HardwareIDToString(id [4]uint32) string {
	return fmt.Sprintf("%08x%08x%08x%08x", id[0], id[1], id[2], id[3])
}

// StringToHardwareID converts a string to hardware ID
func StringToHardwareID(s string) ([4]uint32, error) {
	var result [4]uint32
	if len(s) != 32 {
		return result, fmt.Errorf("invalid hardware ID length")
	}

	for i := range 4 {
		value, err := fmt.Sscanf(s[i*8:(i+1)*8], "%08x", &result[i])
		if err != nil || value != 1 {
			return result, fmt.Errorf("invalid hardware ID format")
		}
	}

	return result, nil
}

// WriteUint16LE writes a uint16 in little-endian format
func WriteUint16LE(buf *bytes.Buffer, value uint16) {
	binary.Write(buf, binary.LittleEndian, value)
}

// WriteUint32LE writes a uint32 in little-endian format
func WriteUint32LE(buf *bytes.Buffer, value uint32) {
	binary.Write(buf, binary.LittleEndian, value)
}

// ReadUint16LE reads a uint16 in little-endian format
func ReadUint16LE(data []byte) uint16 {
	return binary.LittleEndian.Uint16(data)
}

// ReadUint32LE reads a uint32 in little-endian format
func ReadUint32LE(data []byte) uint32 {
	return binary.LittleEndian.Uint32(data)
}

// ValidatePortNumber checks if a port number is valid
func ValidatePortNumber(port int) error {
	if port < 1 || port > 65535 {
		return &DeviceError{
			Code:    "INVALID_PORT",
			Message: fmt.Sprintf("invalid port number: %d", port),
		}
	}
	return nil
}

// IPMaskToCIDR converts a subnet mask to CIDR notation
func IPMaskToCIDR(mask net.IPMask) int {
	ones, _ := mask.Size()
	return ones
}

// CIDRToIPMask converts a CIDR prefix length to a subnet mask
func CIDRToIPMask(cidr int) net.IPMask {
	if cidr < 0 || cidr > 32 {
		return nil
	}
	mask := make(net.IPMask, 4)
	for i := range cidr {
		mask[i/8] |= 1 << uint(7-i%8)
	}
	return mask
}

// IsPrivateIP checks if an IP address is in private ranges
func IsPrivateIP(ip net.IP) bool {
	if ip4 := ip.To4(); ip4 != nil {
		// Check private IPv4 ranges
		return ip4[0] == 10 || // 10.0.0.0/8
			(ip4[0] == 172 && ip4[1]&0xf0 == 16) || // 172.16.0.0/12
			(ip4[0] == 192 && ip4[1] == 168) // 192.168.0.0/16
	}
	return false
}

// IsZeroIP checks if an IP address is all zeros
func IsZeroIP(ip net.IP) bool {
	if ip == nil {
		return true
	}
	for _, b := range ip {
		if b != 0 {
			return false
		}
	}
	return true
}

// FormatError formats an error with optional context
func FormatError(err error, context string) error {
	if err == nil {
		return nil
	}
	if context == "" {
		return err
	}
	return fmt.Errorf("%s: %w", context, err)
}
