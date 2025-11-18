package network

import (
	"fmt"
	"net"

	"golang.org/x/net/ipv4"
)

// ResolveListenUDP binds a UDP socket on the given address.
func ResolveListenUDP(bind string) (*net.UDPConn, error) {
	udpAddr, err := net.ResolveUDPAddr("udp4", bind)
	if err != nil {
		return nil, fmt.Errorf("resolve %q: %w", bind, err)
	}
	conn, err := net.ListenUDP("udp4", udpAddr)
	if err != nil {
		return nil, fmt.Errorf("listen %q: %w", bind, err)
	}
	return conn, nil
}

// JoinMulticastGroups joins each address in groups on all suitable interfaces.
func JoinMulticastGroups(conn *net.UDPConn, groups []string, port string) error {
	pconn := ipv4.NewPacketConn(conn)

	ifaces, err := net.Interfaces()
	if err != nil {
		return fmt.Errorf("list interfaces: %w", err)
	}

	for _, iface := range ifaces {

		// Skip interfaces that are down or not multicast-capable
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagMulticast == 0 {
			continue
		}

		for _, group := range groups {
			hostPort := net.JoinHostPort(group, port)
			groupAddr, err := net.ResolveUDPAddr("udp", hostPort)
			if err != nil {
				return fmt.Errorf("resolve group %q: %w", groupAddr, err)
			}
			if err := pconn.JoinGroup(&iface, groupAddr); err != nil {
				return fmt.Errorf("join %q on %q: %w", hostPort, iface.Name, err)
			}
		}
	}

	return nil
}
