package main

import (
	"fusion/internal/api"
	"net"
	"os"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

const (
	defaultFusionUDPAddr = "192.168.2.2:7947"
	localFusionUDPAddr   = "127.0.0.1:7947"
)

func getFusionUDPAddr() string {
	if addr := os.Getenv("FUSION_UDP_ADDR"); addr != "" {
		return addr
	}
	return defaultFusionUDPAddr
}

func shouldSkipMultipassOnDarwin() bool {
	if os.Getenv("FUSION_UDP_ADDR") != "" {
		return false
	}
	if os.Getenv("FUSION_UDP_LOCAL") != "" {
		return false
	}
	return runtime.GOOS == "darwin"
}

// contains is helper to check substring
func contains(s, sub string) bool { return strings.Contains(s, sub) }

func TestFusionUDP_BasicRoundTrip(t *testing.T) {

	if runtime.GOOS == "darwin" && shouldSkipMultipassOnDarwin() {
		t.Skip("macOS and Multipass networking prevents VM to host UDP responses. Set FUSION_UDP_ADDR=127.0.0.1:7947 to run locally.")
	}

	conn, err := net.Dial("udp", getFusionUDPAddr())
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
	listenerAddr, err := net.ResolveUDPAddr("udp4", "0.0.0.0:0")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	listenerConn, err := net.ListenUDP("udp4", listenerAddr)
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer listenerConn.Close()

	// Send an initial registration message to server
	serverAddr, _ := net.ResolveUDPAddr("udp4", getFusionUDPAddr())
	initMsg := []byte(`{"action":"get"}`)
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

func TestFusionUDP_BroadcastAckStopsRetries(t *testing.T) {
	if os.Getenv("FUSION_UDP_ACK_TEST") == "" {
		t.Skip("Skipping UDP ack test; set FUSION_UDP_ACK_TEST=1 to enable")
	}
	if runtime.GOOS == "darwin" && shouldSkipMultipassOnDarwin() {
		t.Skip("macOS and Multipass networking prevents VM to host UDP responses. Set FUSION_UDP_ADDR=127.0.0.1:7947 to run locally.")
	}

	listenerAddr, err := net.ResolveUDPAddr("udp4", "0.0.0.0:0")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	listenerConn, err := net.ListenUDP("udp4", listenerAddr)
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer listenerConn.Close()

	serverAddr, _ := net.ResolveUDPAddr("udp4", getFusionUDPAddr())

	update := map[string]any{
		"action": "set",
		"payload": map[string]any{
			"udp_ack_test": time.Now().UnixNano(),
		},
	}
	if err := sendUDPJSON(listenerConn, serverAddr, update); err != nil {
		t.Fatalf("send update: %v", err)
	}

	msgID, err := awaitBroadcastMessageID(listenerConn, 3*time.Second)
	if err != nil {
		t.Fatalf("await broadcast: %v", err)
	}

	ack := map[string]any{
		"operation": "ack",
		"id":        msgID,
	}
	if err := sendUDPJSON(listenerConn, serverAddr, ack); err != nil {
		t.Fatalf("send ack: %v", err)
	}

	deadline := time.Now().Add(1500 * time.Millisecond)
	for time.Now().Before(deadline) {
		remaining := time.Until(deadline)
		if remaining <= 0 {
			break
		}
		_ = listenerConn.SetReadDeadline(time.Now().Add(remaining))
		buf := make([]byte, 4096)
		n, _, err := listenerConn.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				break
			}
			t.Fatalf("read after ack: %v", err)
		}
		msg, err := parseJSON(buf[:n])
		if err != nil {
			continue
		}
		if got := extractMsgID(msg); got == msgID {
			t.Fatalf("received duplicate broadcast after ack (msg_id=%s)", msgID)
		}
	}
}

func TestFusionUDP_BroadcastRetriesWithoutAck(t *testing.T) {
	if os.Getenv("FUSION_UDP_RETRY_TEST") == "" {
		t.Skip("Skipping UDP retry test; set FUSION_UDP_RETRY_TEST=1 to enable")
	}
	if runtime.GOOS == "darwin" && shouldSkipMultipassOnDarwin() {
		t.Skip("macOS and Multipass networking prevents VM to host UDP responses. Set FUSION_UDP_ADDR=127.0.0.1:7947 to run locally.")
	}

	listenerAddr, err := net.ResolveUDPAddr("udp4", "0.0.0.0:0")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	listenerConn, err := net.ListenUDP("udp4", listenerAddr)
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer listenerConn.Close()

	serverAddr, _ := net.ResolveUDPAddr("udp4", getFusionUDPAddr())

	update := map[string]any{
		"action": "set",
		"payload": map[string]any{
			"udp_retry_test": time.Now().UnixNano(),
		},
	}
	if err := sendUDPJSON(listenerConn, serverAddr, update); err != nil {
		t.Fatalf("send update: %v", err)
	}

	msgID, err := awaitBroadcastMessageID(listenerConn, 3*time.Second)
	if err != nil {
		t.Fatalf("await broadcast: %v", err)
	}

	deadline := time.Now().Add(2 * time.Second)
	for {
		if time.Now().After(deadline) {
			t.Fatalf("expected retry for msg_id=%s but did not receive one", msgID)
		}
		_ = listenerConn.SetReadDeadline(time.Now().Add(300 * time.Millisecond))
		buf := make([]byte, 4096)
		n, _, err := listenerConn.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				continue
			}
			t.Fatalf("read for retry: %v", err)
		}
		msg, err := parseJSON(buf[:n])
		if err != nil {
			continue
		}
		if got := extractMsgID(msg); got == msgID {
			return
		}
	}
}

func TestFusionUDP_StaleClientPruned(t *testing.T) {
	if os.Getenv("FUSION_UDP_STALE_TEST") == "" {
		t.Skip("Skipping UDP stale test; set FUSION_UDP_STALE_TEST=1 to enable")
	}
	if runtime.GOOS == "darwin" && shouldSkipMultipassOnDarwin() {
		t.Skip("macOS and Multipass networking prevents VM to host UDP responses. Set FUSION_UDP_ADDR=127.0.0.1:7947 to run locally.")
	}

	listenerAddr, err := net.ResolveUDPAddr("udp4", "0.0.0.0:0")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	listenerConn, err := net.ListenUDP("udp4", listenerAddr)
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer listenerConn.Close()

	serverAddr, _ := net.ResolveUDPAddr("udp4", getFusionUDPAddr())

	// Register the client.
	initMsg := []byte(`{"action":"get"}`)
	if _, err := listenerConn.WriteToUDP(initMsg, serverAddr); err != nil {
		t.Fatalf("register: %v", err)
	}

	// Wait beyond server stale TTL (10s) to ensure pruning.
	time.Sleep(12 * time.Second)

	update := map[string]any{
		"action": "set",
		"payload": map[string]any{
			"udp_stale_test": time.Now().UnixNano(),
		},
	}
	if err := sendUDPJSON(listenerConn, serverAddr, update); err != nil {
		t.Fatalf("send update: %v", err)
	}

	_ = listenerConn.SetReadDeadline(time.Now().Add(2 * time.Second))
	buf := make([]byte, 4096)
	if _, _, err := listenerConn.ReadFromUDP(buf); err == nil {
		t.Fatalf("expected no broadcast after stale pruning, but received data")
	} else if ne, ok := err.(net.Error); ok && ne.Timeout() {
		return
	} else {
		t.Fatalf("read error: %v", err)
	}
}

// High-load UDP stress test for profiling
func TestFusionUDP_Stress(t *testing.T) {
	if os.Getenv("FUSION_UDP_STRESS") == "" {
		t.Skip("Skipping UDP stress test; set FUSION_UDP_STRESS=1 to enable")
	}

	const (
		testDuration = 15 * time.Second
		numWriters   = 8
		message      = `{"action":"noop"}`
	)

	var totalWrites uint64
	var wg sync.WaitGroup
	stop := time.Now().Add(testDuration)

	for i := 0; i < numWriters; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()

			conn, err := net.Dial("udp", localFusionUDPAddr)
			if err != nil {
				t.Errorf("writer %d: dial error: %v", id, err)
				return
			}
			defer conn.Close()

			buf := []byte(message)
			var count uint64

			for time.Now().Before(stop) {
				if _, err := conn.Write(buf); err != nil {
					continue
				}
				count++
				runtime.Gosched()
			}

			atomic.AddUint64(&totalWrites, count)
		}(i)
	}

	wg.Wait()

	elapsed := testDuration.Seconds()
	wps := float64(totalWrites) / elapsed
	t.Logf("completed %d total writes (%.0f writes/sec)", totalWrites, wps)
}

func sendUDPJSON(conn *net.UDPConn, addr *net.UDPAddr, payload any) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = conn.WriteToUDP(data, addr)
	return err
}

func parseJSON(data []byte) (map[string]any, error) {
	var msg map[string]any
	if err := json.Unmarshal(data, &msg); err != nil {
		return nil, err
	}
	return msg, nil
}

func extractMsgID(msg map[string]any) string {
	if msg == nil {
		return ""
	}
	if id, ok := msg["_fusion_msg_id"].(string); ok {
		return id
	}
	if data, ok := msg["data"].(map[string]any); ok {
		if id, ok := data["_fusion_msg_id"].(string); ok {
			return id
		}
	}
	return ""
}

func awaitBroadcastMessageID(conn *net.UDPConn, timeout time.Duration) (string, error) {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		_ = conn.SetReadDeadline(time.Now().Add(300 * time.Millisecond))
		buf := make([]byte, 4096)
		n, _, err := conn.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				continue
			}
			return "", err
		}
		msg, err := parseJSON(buf[:n])
		if err != nil {
			continue
		}
		if id := extractMsgID(msg); id != "" {
			return id, nil
		}
	}
	return "", net.ErrClosed
}
