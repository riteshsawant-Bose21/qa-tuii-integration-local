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
	fusionUDPAddr = "192.168.2.2:7947"
)

// contains is helper to check substring
func contains(s, sub string) bool { return strings.Contains(s, sub) }

func TestFusionUDP_BasicRoundTrip(t *testing.T) {

	if runtime.GOOS == "darwin" {
		t.Skip("macOS and Multipass networking prevents VM to host UDP responses.")
		return
	}

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
	serverAddr, _ := net.ResolveUDPAddr("udp4", fusionUDPAddr)
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

			conn, err := net.Dial("udp", fusionUDPAddr)
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
