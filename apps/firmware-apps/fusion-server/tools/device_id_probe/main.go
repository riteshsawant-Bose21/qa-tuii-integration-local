package main

import (
	"encoding/json"
	"fmt"
	"net"
	"os"
	"time"
)

type probeResult struct {
	Status           string `json:"status"`
	DeviceID         string `json:"device_id,omitempty"`
	ExpectedDeviceID string `json:"expected_device_id,omitempty"`
	LastSeen         string `json:"last_seen,omitempty"`
}

func main() {
	if len(os.Args) < 4 {
		fmt.Fprintf(os.Stderr, "usage: %s <server_ip> <port> <expected_device_id> [timeout_seconds]\n", os.Args[0])
		os.Exit(1)
	}

	serverIP := os.Args[1]
	port := os.Args[2]
	expectedDeviceID := os.Args[3]
	timeoutSeconds := 8
	if len(os.Args) >= 5 {
		if _, err := fmt.Sscanf(os.Args[4], "%d", &timeoutSeconds); err != nil {
			fmt.Fprintf(os.Stderr, "invalid timeout: %v\n", err)
			os.Exit(1)
		}
	}

	serverAddr, err := net.ResolveUDPAddr("udp4", net.JoinHostPort(serverIP, port))
	if err != nil {
		fmt.Fprintf(os.Stderr, "resolve server addr: %v\n", err)
		os.Exit(1)
	}

	conn, err := net.ListenUDP("udp4", nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "listen udp: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	handshake := map[string]any{"action": "get"}
	if err := sendJSON(conn, serverAddr, handshake); err != nil {
		fmt.Fprintf(os.Stderr, "send handshake: %v\n", err)
		os.Exit(1)
	}

	buf := make([]byte, 64*1024)
	if err := conn.SetReadDeadline(time.Now().Add(3 * time.Second)); err != nil {
		fmt.Fprintf(os.Stderr, "set handshake deadline: %v\n", err)
		os.Exit(1)
	}
	if _, _, err := conn.ReadFromUDP(buf); err != nil {
		fmt.Fprintf(os.Stderr, "read handshake: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("ready")

	result := probeResult{
		Status:           "timeout",
		ExpectedDeviceID: expectedDeviceID,
	}
	deadline := time.Now().Add(time.Duration(timeoutSeconds) * time.Second)
	for time.Now().Before(deadline) {
		if err := conn.SetReadDeadline(time.Now().Add(500 * time.Millisecond)); err != nil {
			fmt.Fprintf(os.Stderr, "set read deadline: %v\n", err)
			os.Exit(1)
		}
		n, _, err := conn.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				continue
			}
			fmt.Fprintf(os.Stderr, "read udp: %v\n", err)
			os.Exit(1)
		}

		var msg map[string]any
		if err := json.Unmarshal(buf[:n], &msg); err != nil {
			continue
		}

		msgID, _ := msg["_fusion_msg_id"].(string)
		if msgID != "" {
			_ = sendJSON(conn, serverAddr, map[string]any{
				"operation": "ack",
				"id":        msgID,
			})
		}

		if op, _ := msg["_fusion_op"].(string); op != "device_update" {
			continue
		}
		deviceID, _ := msg["id"].(string)
		result.LastSeen = deviceID
		if deviceID != expectedDeviceID {
			continue
		}
		result.Status = "matched"
		result.DeviceID = deviceID
		break
	}

	enc := json.NewEncoder(os.Stdout)
	if err := enc.Encode(result); err != nil {
		fmt.Fprintf(os.Stderr, "encode result: %v\n", err)
		os.Exit(1)
	}
}

func sendJSON(conn *net.UDPConn, addr *net.UDPAddr, payload any) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = conn.WriteToUDP(data, addr)
	return err
}
