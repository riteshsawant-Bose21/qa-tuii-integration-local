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
	VIPPassword      = "fusion"
	VRRPBufSize      = 1500
	VRRPProtocol     = 112
	MinIPv4HeaderLen = 20
)

type VRRPHeader struct {
	VersType    uint8
	VRID        uint8
	Priority    uint8
	IPCount     uint8
	AuthType    uint8
	AdvInterval uint8
	Checksum    uint16
}

type VRRPPacket struct {
	Header     VRRPHeader
	VirtualIPs []net.IP
	AuthData   [8]byte
}

// StartVRRPListener starts a goroutine that listens for VRRP advertisements.
// onUpdate(vip, src) is called when the VIP ownership changes.
func StartVRRPListener(onUpdate func(vip string, srcIP string)) error {
	fd, err := syscall.Socket(syscall.AF_INET, syscall.SOCK_RAW, VRRPProtocol)
	if err != nil {
		return fmt.Errorf("failed to create raw socket: %w", err)
	}

	logger := logging.GetLogger()
	logger.Debug("VRRP listener started")

	go func() {
		defer syscall.Close(fd)

		buf := make([]byte, VRRPBufSize)
		var lastSrc, lastVIP string

		for {
			n, from, err := syscall.Recvfrom(fd, buf, 0)
			if err != nil {
				logger.Error("VRRP read error: %v", err)
				continue
			}
			if n <= MinIPv4HeaderLen {
				continue
			}

			sa := from.(*syscall.SockaddrInet4)
			srcIP := fmt.Sprintf("%d.%d.%d.%d", sa.Addr[0], sa.Addr[1], sa.Addr[2], sa.Addr[3])

			vip, err := parseVRRPAddress(buf[:n])
			if err != nil {
				logger.Error("VRRP parse error: %v", err)
				continue
			}

			if srcIP != lastSrc || vip != lastVIP {
				lastSrc = srcIP
				lastVIP = vip
				logger.Debug("VRRP update: %s binds %s", srcIP, vip)
				onUpdate(vip, srcIP)
			}
		}
	}()

	return nil
}

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

	pwd := strings.TrimRight(string(pkt.AuthData[:]), "\x00")
	if pwd != VIPPassword {
		return "", fmt.Errorf("invalid VRRP auth password %q", pwd)
	}

	return pkt.VirtualIPs[0].String(), nil
}

func (h *VRRPHeader) Version() uint8 { return h.VersType >> 4 }
func (h *VRRPHeader) Type() uint8    { return h.VersType & 0x0F }

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

	required := 8 + int(hdr.IPCount)*4 + 8
	if len(data) < required {
		return nil, fmt.Errorf("packet too short: need %d, have %d", required, len(data))
	}

	pkt := &VRRPPacket{Header: hdr}
	off := 8

	pkt.VirtualIPs = make([]net.IP, hdr.IPCount)
	for i := 0; i < int(hdr.IPCount); i++ {
		ipb := data[off : off+4]
		pkt.VirtualIPs[i] = net.IPv4(ipb[0], ipb[1], ipb[2], ipb[3])
		off += 4
	}

	copy(pkt.AuthData[:], data[off:off+8])
	return pkt, nil
}
