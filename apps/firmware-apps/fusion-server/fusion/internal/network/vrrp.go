package network

import (
	"fmt"
	"fusion/internal/logging"
	"net"
	"strings"
	"syscall"
)

const (
	MinPacketLength = 40 // Minimum length for IP packet (20) + VRRP packet (20)
	VIPPassword     = "fusion"
	VRRPDataOffset  = 20 // RAW socket with IP header.
	VRRPPort        = 112
)

func StartVRRPListener(onUpdate func(string)) error {
	fd, err := syscall.Socket(syscall.AF_INET, syscall.SOCK_RAW, VRRPPort)
	if err != nil {
		return err
	}

	var lastVIP string

	go func() {

		logger := logging.GetLogger()

		buf := make([]byte, 1500)

		for {
			n, _, err := syscall.Recvfrom(fd, buf, 0)
			if err != nil {
				logger.Error("VRRP read error: %v", err)
				continue
			}

			vip, err := parseVRRPAddress(buf, n)
			if err == nil {

				if vip != "" && vip != lastVIP {
					lastVIP = vip
					onUpdate(vip)
				}
			} else {
				logger.Error("VRRP parse error: %v", err)
			}
		}
	}()

	return nil
}

func parseVRRPAddress(buffer []byte, length int) (string, error) {

	if length < MinPacketLength {
		return "", fmt.Errorf("invalid IP+VRRP packet length")
	}

	// Extract VRRP Header data.
	vrrpData := buffer[VRRPDataOffset:]

	// Get the virtual IP and the password from the VRRP packet.
	virtualIP := net.IPv4(vrrpData[8], vrrpData[9], vrrpData[10], vrrpData[11]).String()
	password := string(vrrpData[8+(vrrpData[3]*4) : 8+(vrrpData[3]*4)+8])
	password = strings.TrimRight(password, "\x00")

	// Verify this is our VRRP message
	if password != VIPPassword {
		return "", fmt.Errorf("wrong password: %s,%s", password, VIPPassword)
	}

	return virtualIP, nil
}
