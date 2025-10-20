package main

import (
	"encoding/json"
	"net"
	"strings"
	"sync"
	"testing"
	"time"

	"fusion/internal/api"
)

const fusionUDPAddr = "192.168.64.100:7947"

// contains is helper to check substring
func contains(s, sub string) bool { return strings.Contains(s, sub) }

func TestFusionUDP_BasicRoundTrip(t *testing.T) {
	conn, err := net.Dial("udp", fusionUDPAddr)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer conn.Close()

	msg := api.NotifyMessage{
		ID:        "fusion-test-basic",
		Operation: api.NotifyOpValueGet,
	}
	data, _ := json.Marshal(msg)

	if _, err := conn.Write(data); err != nil {
		t.Fatalf("write: %v", err)
	}

	buf := make([]byte, 2048)
	conn.SetReadDeadline(time.Now().Add(1 * time.Second))
	n, err := conn.Read(buf)
	if err != nil {
		t.Fatalf("read: %v", err)
	}

	out := string(buf[:n])
	if !contains(out, "status") {
		t.Fatalf("expected JSON response, got: %q", out)
	}
}

func TestFusionUDP_BroadcastPropagation(t *testing.T) {
	// Prepare UDP listener to act as a "client"
	listenerAddr, err := net.ResolveUDPAddr("udp", "0.0.0.0:0")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	listenerConn, err := net.ListenUDP("udp", listenerAddr)
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer listenerConn.Close()

	// Send an initial registration message to server
	serverAddr, _ := net.ResolveUDPAddr("udp", fusionUDPAddr)
	initMsg := []byte(`{"id":"fusion-client","operation":"noop"}`)
	if _, err := listenerConn.WriteToUDP(initMsg, serverAddr); err != nil {
		t.Fatalf("register: %v", err)
	}

	// Now wait to receive broadcast messages
	buf := make([]byte, 4096)
	listenerConn.SetReadDeadline(time.Now().Add(3 * time.Second))
	n, _, err := listenerConn.ReadFromUDP(buf)
	if err != nil {
		t.Fatalf("read broadcast: %v", err)
	}

	out := string(buf[:n])
	if !contains(out, "vip") && !contains(out, "config") && !contains(out, "status") {
		t.Fatalf("unexpected broadcast payload: %s", out)
	}
}

func TestFusionUDP_Stress(t *testing.T) {
	conn, err := net.Dial("udp", fusionUDPAddr)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer conn.Close()

	msg := []byte(`{"id":"spam","operation":"noop"}`)
	stop := time.Now().Add(2 * time.Second)

	var wg sync.WaitGroup
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for time.Now().Before(stop) {
				conn.Write(msg)
			}
		}()
	}
	wg.Wait()

	t.Log("stress test completed successfully (no panic or timeout)")
}
