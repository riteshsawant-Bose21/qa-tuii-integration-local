package main

import (
	"fmt"
	"fusion/internal/api"
	"net"
	"runtime"
	"strconv"
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
	const (
		testDuration = 15 * time.Second // sustain load long enough for profiling
		numWriters   = 8                // parallel senders
		message      = `{{"action":"set","settings":{{"audio":{{"gainID1":{{"gain":{100}}}}}}}}}`
	)

	var totalWrites uint64
	var wg sync.WaitGroup
	stop := time.Now().Add(testDuration)

	//t.Logf("Starting %d UDP writers for %v\n", numWriters, testDuration)

	for i := range numWriters {
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
					// rare, ignore transient errors
					continue
				}
				count++
				// yield to let other goroutines run
				runtime.Gosched()
			}

			atomic.AddUint64(&totalWrites, count)
			//t.Logf("writer %d sent %d packets", id, count)
		}(i)
	}

	wg.Wait()

	elapsed := testDuration.Seconds()
	wps := float64(totalWrites) / elapsed
	t.Logf("completed %d total writes (%.0f writes/sec)", totalWrites, wps)
}

func TestFusionUDP_StaleBroadcastBug(t *testing.T) {

	const (
		bufferSize   = 4096
		drainTime    = 1000 * time.Millisecond
		gatherTime   = 2 * time.Second
		maxValues    = 2000
		numUpdates   = 50
		readDeadline = 200 * time.Millisecond
	)

	laddr, err := net.ResolveUDPAddr("udp4", "0.0.0.0:0")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}

	recvConn, err := net.ListenUDP("udp4", laddr)
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	defer recvConn.Close()

	drainUDP(recvConn, drainTime)

	saddr, _ := net.ResolveUDPAddr("udp4", fusionUDPAddr)

	initMsg := []byte(`{"action":"get"}`)
	if _, err := recvConn.WriteToUDP(initMsg, saddr); err != nil {
		t.Fatalf("register write: %v", err)
	}

	recvConn.SetReadDeadline(time.Now().Add(1 * time.Second))
	respBuf := make([]byte, bufferSize)
	n, _, err := recvConn.ReadFromUDP(respBuf)
	if err != nil {
		t.Fatalf("register read: %v", err)
	}
	t.Logf("Registration response: %s", string(respBuf[:n]))

	values := make(chan int, maxValues)
	stop := make(chan struct{})

	go func() {
		buf := make([]byte, bufferSize)
		for {
			select {
			case <-stop:
				return
			default:
			}
			recvConn.SetReadDeadline(time.Now().Add(readDeadline))
			n, _, err := recvConn.ReadFromUDP(buf)
			if err != nil {
				continue
			}

			var m map[string]any
			if json.Unmarshal(buf[:n], &m) == nil {
				if v, ok := m["testKey"]; ok {
					if s, ok := v.(string); ok {
						if iv, err := strconv.Atoi(s); err == nil {
							values <- iv
						}
					}
				}
			}
		}
	}()

	for i := 1; i <= numUpdates; i++ {
		msg := fmt.Sprintf(
			`{"action":"set","payload":{"testKey":"%d","timestamp":"%d"}}`,
			i, time.Now().UnixMilli(),
		)
		t.Logf("sending: %s", msg)

		if _, err := recvConn.WriteToUDP([]byte(msg), saddr); err != nil {
			t.Fatalf("write update: %v", err)
		}
	}

	time.Sleep(gatherTime)
	close(stop)

	maxSeen := -1
	staleDetected := false

loop:
	for {
		select {
		case v := <-values:
			if v > maxSeen {
				maxSeen = v
			} else if v < maxSeen {
				staleDetected = true
				break loop
			}
		default:
			break loop
		}
	}

	if staleDetected {
		t.Fatalf("Stale broadcast detected: received %d after maxSeen=%d",
			maxSeen, maxSeen)
	}

	if maxSeen < numUpdates {
		t.Fatalf("Did not receive all updates (maxSeen=%d, expected=%d)",
			maxSeen, numUpdates)
	}

	t.Logf("No stale broadcasts detected (maxSeen=%d)", maxSeen)
}

func drainUDP(conn *net.UDPConn, d time.Duration) {
	buf := make([]byte, 4096)
	deadline := time.Now().Add(d)

	for time.Now().Before(deadline) {
		conn.SetReadDeadline(time.Now().Add(50 * time.Millisecond))
		if _, _, err := conn.ReadFromUDP(buf); err != nil {
			// timeout → nothing to drain
			continue
		}
	}
}
