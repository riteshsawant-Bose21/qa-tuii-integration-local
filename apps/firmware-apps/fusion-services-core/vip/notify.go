package vip

import (
	"encoding/json"
	"fmt"
	"net"
	"time"
)

const Port = 7948

const (
	EventGained = "gained"
	EventLost   = "lost"
)

type Payload struct {
	VIP       string `json:"vip"`
	Host      string `json:"host"`
	Event     string `json:"event"`
	Timestamp int64  `json:"timestamp"`
}

// SendLocalStatus sends a VIP status update to localhost using the shared UDP schema.
func SendLocalStatus(vip, host string, gained bool) error {
	event := EventLost
	if gained {
		event = EventGained
	}

	msg := Payload{
		VIP:       vip,
		Host:      host,
		Event:     event,
		Timestamp: time.Now().Unix(),
	}

	addr := &net.UDPAddr{IP: net.IPv4(127, 0, 0, 1), Port: Port}
	return sendUDPJSON(addr, msg)
}

func sendUDPJSON(addr *net.UDPAddr, payload any) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal UDP payload: %w", err)
	}

	conn, err := net.ListenPacket("udp4", "")
	if err != nil {
		return fmt.Errorf("failed to open UDP socket: %w", err)
	}
	defer conn.Close()

	if _, err := conn.WriteTo(data, addr); err != nil {
		return fmt.Errorf("failed to send UDP packet: %w", err)
	}
	return nil
}
