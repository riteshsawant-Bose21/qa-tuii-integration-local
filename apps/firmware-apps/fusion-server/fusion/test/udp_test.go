package main

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/network"
	"fusion/internal/server/handler"
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

	data := []byte(`{"action":"get"}`)

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
	if !contains(out, `"status":"success"`) {
		t.Fatalf("expected successful get response, got: %q", out)
	}
}

func TestFusionUDP_BroadcastPropagation(t *testing.T) {
	serverAddr, err := net.ResolveUDPAddr("udp4", getFusionUDPAddr())
	if err != nil {
		t.Fatalf("resolve server: %v", err)
	}
	clientConn, err := net.DialUDP("udp4", nil, serverAddr)
	if err != nil {
		t.Fatalf("dial client: %v", err)
	}
	defer clientConn.Close()

	// Send an initial registration message to server.
	if _, err := clientConn.Write([]byte(`{"action":"get"}`)); err != nil {
		t.Fatalf("register: %v", err)
	}

	buf := make([]byte, 4096)
	clientConn.SetReadDeadline(time.Now().Add(1 * time.Second))
	if _, err := clientConn.Read(buf); err != nil {
		t.Fatalf("read registration response: %v", err)
	}

	update := map[string]any{
		"action": "put",
		"payload": map[string]any{
			"udp_broadcast_test": time.Now().UnixNano(),
		},
	}
	updateData, err := json.Marshal(update)
	if err != nil {
		t.Fatalf("marshal update: %v", err)
	}
	if _, err := clientConn.Write(updateData); err != nil {
		t.Fatalf("write update: %v", err)
	}

	buf = make([]byte, 4096)
	clientConn.SetReadDeadline(time.Now().Add(3 * time.Second))
	n, err := clientConn.Read(buf)
	if err != nil {
		t.Fatalf("read broadcast: %v", err)
	}

	msg, err := parseJSON(buf[:n])
	if err != nil {
		t.Fatalf("parse broadcast: %v", err)
	}
	if _, ok := msg["udp_broadcast_test"]; !ok {
		t.Fatalf("unexpected broadcast payload: %s", string(buf[:n]))
	}
}

func TestFusionUDP_OversizedBroadcastRequiresConfigPull(t *testing.T) {
	if runtime.GOOS == "darwin" && shouldSkipMultipassOnDarwin() {
		t.Skip("macOS and Multipass networking prevents VM to host UDP responses. Set FUSION_UDP_ADDR=127.0.0.1:7947 to run locally.")
	}

	serverAddr, err := net.ResolveUDPAddr("udp4", getFusionUDPAddr())
	if err != nil {
		t.Fatalf("resolve server: %v", err)
	}
	listenerConn, err := net.ListenUDP("udp4", nil)
	if err != nil {
		t.Fatalf("listen udp: %v", err)
	}
	defer listenerConn.Close()

	if err := sendUDPJSON(listenerConn, serverAddr, map[string]any{"action": "no_op"}); err != nil {
		t.Fatalf("register udp observer: %v", err)
	}
	buf := make([]byte, 65535)
	_ = listenerConn.SetReadDeadline(time.Now().Add(2 * time.Second))
	if _, _, err := listenerConn.ReadFromUDP(buf); err != nil {
		t.Fatalf("read registration response: %v", err)
	}

	patchKey := fmt.Sprintf("settings.udp_buffer_limit.%d", time.Now().UnixNano())
	oversizedValue := strings.Repeat("x", 70*1024)

	httpBase := httpBaseForUDPAddr(getFusionUDPAddr())
	patchConfigViaWebSocket(t, httpBase, map[string]any{patchKey: oversizedValue})
	defer func() {
		patchConfigViaWebSocket(t, httpBase, map[string]any{patchKey: nil})
	}()

	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		_ = listenerConn.SetReadDeadline(time.Now().Add(500 * time.Millisecond))
		n, _, err := listenerConn.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				continue
			}
			t.Fatalf("read broadcast: %v", err)
		}
		msg, err := parseJSON(buf[:n])
		if err != nil {
			continue
		}
		op, _ := msg[api.FusionOperation].(string)
		if op == string(api.NotifyOpConfigPullRequired) {
			if _, ok := msg[api.FusionEpoch]; !ok {
				t.Fatalf("config_pull_required missing epoch: %s", string(buf[:n]))
			}
			if _, ok := msg[api.FusionVersion]; !ok {
				t.Fatalf("config_pull_required missing version: %s", string(buf[:n]))
			}
			if n > 2048 {
				t.Fatalf("config_pull_required notification too large: %d bytes", n)
			}
			return
		}
		if op == string(api.NotifyOpConfigUpdate) {
			t.Fatalf("expected config_pull_required for oversized payload, got config_update len=%d", n)
		}
	}
	t.Fatalf("timed out waiting for config_pull_required broadcast")
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
		"action": "put",
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
		"action": "put",
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
		"action": "put",
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

func TestFusionUDP_ConfigBroadcastDoesNotMutateInput(t *testing.T) {
	srv, err := network.NewUDPServer("127.0.0.1:0", &handler.Handler{}, true)
	if err != nil {
		t.Fatalf("NewUDPServer failed: %v", err)
	}
	defer srv.Close()

	data := map[string]any{
		"audio": map[string]any{
			"settings": map[string]any{
				"gain_block": map[string]any{
					"mute": true,
				},
			},
		},
	}

	msg := api.NewNotifyMessage(
		api.NotifyOpConfigUpdate,
		"node-a",
		api.WithConfigUpdate(&api.ConfigUpdate{
			Data:    data,
			Version: api.Version{Counter: 7, Epoch: 3, NodeID: "node-a"},
		}),
	)

	if err := srv.BroadcastMessage(msg); err != nil {
		t.Fatalf("BroadcastMessage failed: %v", err)
	}

	for _, key := range []string{
		api.FusionVersion,
		api.FusionEpoch,
		api.FusionSentAtNS,
		api.FusionMessageID,
		api.FusionOperation,
	} {
		if _, ok := data[key]; ok {
			t.Fatalf("expected config update data to remain unmodified, found metadata key %q in %#v", key, data)
		}
	}
}

func TestFusionUDP_CloseWhilePacketsArrive(t *testing.T) {
	probeConn, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: 0})
	if err != nil {
		t.Fatalf("ListenUDP failed: %v", err)
	}
	addr := probeConn.LocalAddr().String()
	_ = probeConn.Close()

	srv, err := network.NewUDPServer(addr, &handler.Handler{}, false)
	if err != nil {
		t.Fatalf("NewUDPServer failed: %v", err)
	}

	serverAddr, err := net.ResolveUDPAddr("udp4", addr)
	if err != nil {
		_ = srv.Close()
		t.Fatalf("ResolveUDPAddr failed: %v", err)
	}

	clientConn, err := net.DialUDP("udp4", nil, serverAddr)
	if err != nil {
		_ = srv.Close()
		t.Fatalf("DialUDP failed: %v", err)
	}
	defer clientConn.Close()

	done := make(chan struct{})
	go func() {
		defer close(done)
		deadline := time.Now().Add(100 * time.Millisecond)
		payload := []byte(`{"action":"noop"}`)
		for time.Now().Before(deadline) {
			_, _ = clientConn.Write(payload)
			time.Sleep(1 * time.Millisecond)
		}
	}()

	time.Sleep(20 * time.Millisecond)
	if err := srv.Close(); err != nil {
		t.Fatalf("Close failed: %v", err)
	}

	<-done
}

func TestFusionUDP_CloseIsIdempotent(t *testing.T) {
	probeConn, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: 0})
	if err != nil {
		t.Fatalf("ListenUDP failed: %v", err)
	}
	addr := probeConn.LocalAddr().String()
	_ = probeConn.Close()

	srv, err := network.NewUDPServer(addr, &handler.Handler{}, false)
	if err != nil {
		t.Fatalf("NewUDPServer failed: %v", err)
	}

	if err := srv.Close(); err != nil {
		t.Fatalf("first Close failed: %v", err)
	}
	if err := srv.Close(); err != nil {
		t.Fatalf("second Close failed: %v", err)
	}
}

func TestFusionUDP_InvalidSenderIsNotRegisteredForBroadcasts(t *testing.T) {
	probeConn, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: 0})
	if err != nil {
		t.Fatalf("ListenUDP failed: %v", err)
	}
	addr := probeConn.LocalAddr().String()
	_ = probeConn.Close()

	srv, err := network.NewUDPServer(addr, &handler.Handler{}, false)
	if err != nil {
		t.Fatalf("NewUDPServer failed: %v", err)
	}
	defer srv.Close()

	serverAddr, err := net.ResolveUDPAddr("udp4", addr)
	if err != nil {
		t.Fatalf("ResolveUDPAddr failed: %v", err)
	}

	validConn, err := net.ListenUDP("udp4", nil)
	if err != nil {
		t.Fatalf("ListenUDP validConn failed: %v", err)
	}
	defer validConn.Close()

	invalidConn, err := net.ListenUDP("udp4", nil)
	if err != nil {
		t.Fatalf("ListenUDP invalidConn failed: %v", err)
	}
	defer invalidConn.Close()

	if _, err := validConn.WriteToUDP([]byte(`{"action":"noop"}`), serverAddr); err != nil {
		t.Fatalf("register valid observer: %v", err)
	}
	buf := make([]byte, 4096)
	_ = validConn.SetReadDeadline(time.Now().Add(1 * time.Second))
	if _, _, err := validConn.ReadFromUDP(buf); err != nil {
		t.Fatalf("read valid observer response: %v", err)
	}

	if _, err := invalidConn.WriteToUDP([]byte(`{invalid json}`), serverAddr); err != nil {
		t.Fatalf("send invalid payload: %v", err)
	}
	_ = invalidConn.SetReadDeadline(time.Now().Add(1 * time.Second))
	if _, _, err := invalidConn.ReadFromUDP(buf); err != nil {
		t.Fatalf("read invalid sender error response: %v", err)
	}

	msg := api.NewNotifyMessage(
		api.NotifyOpConfigUpdate,
		"node-a",
		api.WithConfigUpdate(&api.ConfigUpdate{
			Data: map[string]any{
				"udp_invalid_sender_test": time.Now().UnixNano(),
			},
			Version: api.Version{Counter: 1, NodeID: "node-a"},
		}),
	)
	if err := srv.BroadcastMessage(msg); err != nil {
		t.Fatalf("BroadcastMessage failed: %v", err)
	}

	_ = validConn.SetReadDeadline(time.Now().Add(1 * time.Second))
	n, _, err := validConn.ReadFromUDP(buf)
	if err != nil {
		t.Fatalf("expected broadcast to valid observer: %v", err)
	}
	broadcast, err := parseJSON(buf[:n])
	if err != nil {
		t.Fatalf("parse valid observer broadcast: %v", err)
	}
	if _, ok := broadcast["udp_invalid_sender_test"]; !ok {
		t.Fatalf("unexpected broadcast payload for valid observer: %s", string(buf[:n]))
	}

	_ = invalidConn.SetReadDeadline(time.Now().Add(300 * time.Millisecond))
	if _, _, err := invalidConn.ReadFromUDP(buf); err == nil {
		t.Fatalf("expected invalid sender to receive no broadcast")
	} else if ne, ok := err.(net.Error); ok && ne.Timeout() {
		return
	} else {
		t.Fatalf("unexpected invalid sender read error: %v", err)
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

	for i := range numWriters {
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

func httpBaseForUDPAddr(udpAddr string) string {
	host, _, err := net.SplitHostPort(udpAddr)
	if err != nil || host == "" {
		return serverAddr
	}
	return "http://" + net.JoinHostPort(host, "8080")
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
