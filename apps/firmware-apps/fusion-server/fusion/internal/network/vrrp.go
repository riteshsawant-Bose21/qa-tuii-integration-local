package network

import (
	"encoding/binary"
	"fmt"
	"fusion/internal/logging"
	"net"
	"strings"
	"syscall"
)

const (
	MinPacketLength  = 40 // Minimum length for IP packet (20) + VRRP packet (20)
	VIPPassword      = "fusion"
	VRRPDataOffset   = 20 // RAW socket with IP header.
	VRRPPort         = 112
	MinIPv4HeaderLen = 20
)

type VRRPHeader struct {
	VersType    uint8 // high-nibble = Version, low-nibble = Type
	VRID        uint8
	Priority    uint8
	IPCount     uint8 // number of virtual IPs
	AuthType    uint8
	AdvInterval uint8
	Checksum    uint16 // big-endian
}

// VRRPPacket bundles header, IP list, and auth data.
type VRRPPacket struct {
	Header     VRRPHeader
	VirtualIPs []net.IP // length = Header.IPCount
	AuthData   [8]byte  // text password (null-padded)
}

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
			_, _, err := syscall.Recvfrom(fd, buf, 0)
			if err != nil {
				logger.Error("VRRP read error: %v", err)
				continue
			}

			vip, err := parseVRRPAddress(buf)
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

// ParseVRRPAddress extracts the first VIP from a full IPv4+VRRP packet.
func parseVRRPAddress(buffer []byte) (string, error) {
	if len(buffer) < MinIPv4HeaderLen {
		return "", fmt.Errorf("packet too short for IPv4 header")
	}
	ihl := int(buffer[0]&0x0F) * 4
	if len(buffer) < ihl {
		return "", fmt.Errorf("packet shorter than IHL: %d < %d", len(buffer), ihl)
	}
	vrrpData := buffer[ihl:]
	pkt, err := Unmarshal(vrrpData)
	if err != nil {
		return "", err
	}
	if len(pkt.VirtualIPs) < 1 {
		return "", fmt.Errorf("no virtual IPs in VRRP packet")
	}
	// validate password
	pwd := strings.TrimRight(string(pkt.AuthData[:]), "\x00")
	if pwd != VIPPassword {
		return "", fmt.Errorf("wrong password %q (expected %q)", pwd, VIPPassword)
	}
	return pkt.VirtualIPs[0].String(), nil
}

// Version returns the VRRP version.
func (h *VRRPHeader) Version() uint8 {
	return h.VersType >> 4
}

// Type returns the VRRP message type.
func (h *VRRPHeader) Type() uint8 {
	return h.VersType & 0x0F
}

// Unmarshal parses a raw VRRP byte-slice (starting at the VRRP header).
func Unmarshal(data []byte) (*VRRPPacket, error) {
	if len(data) < 8 {
		return nil, fmt.Errorf("too short for VRRP header: %d bytes", len(data))
	}

	hdr := VRRPHeader{
		VersType:    data[0],
		VRID:        data[1],
		Priority:    data[2],
		IPCount:     data[3],
		AuthType:    data[4],
		AdvInterval: data[5],
		Checksum:    binary.BigEndian.Uint16(data[6:8]),
	}

	if hdr.Version() != 2 || hdr.Type() != 1 {
		return nil, fmt.Errorf("unexpected VRRP version/type %d/%d", hdr.Version(), hdr.Type())
	}
	if hdr.AuthType != 1 {
		return nil, fmt.Errorf("unsupported auth type %d", hdr.AuthType)
	}

	// compute total length needed: header + IP list + auth
	need := 8 + int(hdr.IPCount)*4 + 8
	if len(data) < need {
		return nil, fmt.Errorf("packet too short: need %d, have %d", need, len(data))
	}

	pkt := &VRRPPacket{Header: hdr}
	off := 8

	// parse virtual IPs
	pkt.VirtualIPs = make([]net.IP, hdr.IPCount)
	for i := 0; i < int(hdr.IPCount); i++ {
		b := data[off : off+4]
		pkt.VirtualIPs[i] = net.IPv4(b[0], b[1], b[2], b[3])
		off += 4
	}

	// copy auth data
	copy(pkt.AuthData[:], data[off:off+8])
	return pkt, nil
}
