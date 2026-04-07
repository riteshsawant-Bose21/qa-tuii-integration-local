package main

import (
	"bytes"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"runtime"
	"slices"
	"strconv"
	"strings"
	"testing"
	"time"

	"fusion/internal/api"
	"fusion/internal/routes"

	json "github.com/goccy/go-json"
)

type udpStatusSnapshot struct {
	QueueDepth           int    `json:"queue_depth"`
	QueueCapacity        int    `json:"queue_capacity"`
	MaxQueueDepth        uint64 `json:"max_queue_depth"`
	RegisteredClients    int    `json:"registered_clients"`
	PendingBroadcasts    int    `json:"pending_broadcasts"`
	OldestPendingAgeMs   int64  `json:"oldest_pending_age_ms"`
	EnqueuedPackets      uint64 `json:"enqueued_packets"`
	DroppedPackets       uint64 `json:"dropped_packets"`
	HandledPackets       uint64 `json:"handled_packets"`
	AckPackets           uint64 `json:"ack_packets"`
	ResponsesSent        uint64 `json:"responses_sent"`
	BroadcastMessages    uint64 `json:"broadcast_messages"`
	BroadcastDatagrams   uint64 `json:"broadcast_datagrams"`
	LastBroadcastEpoch   uint64 `json:"last_broadcast_epoch"`
	LastBroadcastVersion uint64 `json:"last_broadcast_version"`
	LastBroadcastSentAt  int64  `json:"last_broadcast_sent_at_ns"`
	MaintenanceEnabled   bool   `json:"maintenance_enabled"`
}

type udpObserverNode struct {
	name          string
	httpBase      string
	udpAddr       *net.UDPAddr
	listener      *net.UDPConn
	latestSeq     int
	maxLag        time.Duration
	maxPending    int
	maxPendingAge int64
	before        udpStatusSnapshot
	after         udpStatusSnapshot
}

func TestFusionUDP_ObserverLatencyDiagnostic(t *testing.T) {
	if os.Getenv("FUSION_UDP_OBSERVER_LATENCY_TEST") == "" {
		t.Skip("Skipping UDP observer latency diagnostic; set FUSION_UDP_OBSERVER_LATENCY_TEST=1 to enable")
	}
	if runtime.GOOS == "darwin" && shouldSkipMultipassOnDarwin() {
		t.Skip("macOS and Multipass networking prevents VM to host UDP responses. Set FUSION_UDP_ADDR=127.0.0.1:7947 to run locally.")
	}

	httpBase := serverAddr
	if vip := os.Getenv("FUSION_TEST_VIP"); vip != "" {
		httpBase = fmt.Sprintf("http://%s", vip)
	}
	if clusterConfig == nil || len(clusterConfig.nodes) == 0 {
		t.Fatal("cluster config missing")
	}

	nodes := make([]*udpObserverNode, 0, len(clusterConfig.nodes))
	for _, node := range clusterConfig.nodes {
		udpAddr, err := udpAddrForNode(node.address)
		if err != nil {
			t.Fatalf("resolve udp addr for %s: %v", node.name, err)
		}
		listener, err := net.ListenUDP("udp4", nil)
		if err != nil {
			t.Fatalf("listen udp for %s: %v", node.name, err)
		}
		nodes = append(nodes, &udpObserverNode{
			name:     node.name,
			httpBase: node.address,
			udpAddr:  udpAddr,
			listener: listener,
		})
	}
	defer func() {
		for _, node := range nodes {
			_ = node.listener.Close()
		}
	}()

	seedState := map[string]any{
		"settings": map[string]any{
			"observer_latency": map[string]any{
				"seq": 0,
			},
			"observer_payload_pad": buildBacklogPad(96, 192),
		},
	}
	postJSON(t, fmt.Sprintf("%s%s", httpBase, routes.ValueEndpoint), seedState)

	buf := make([]byte, 65535)
	for _, node := range nodes {
		if err := sendUDPJSON(node.listener, node.udpAddr, map[string]any{"action": "get"}); err != nil {
			t.Fatalf("register udp observer on %s: %v", node.name, err)
		}
		_ = node.listener.SetReadDeadline(time.Now().Add(2 * time.Second))
		if _, _, err := node.listener.ReadFromUDP(buf); err != nil {
			t.Fatalf("initial udp state read on %s: %v", node.name, err)
		}
		node.before = fetchUDPStatusSnapshot(t, node.httpBase)
		t.Logf("%s udp status before load: %+v", node.name, node.before)
	}

	warmupSeq := 1
	if err := patchJSON(
		&http.Client{Timeout: 3 * time.Second},
		fmt.Sprintf("%s%s?key=settings.observer_latency.seq", httpBase, routes.ValueEndpoint),
		map[string]any{"value": warmupSeq},
	); err != nil {
		t.Fatalf("warmup patch failed: %v", err)
	}

	for _, node := range nodes {
		seq, ok, err := awaitObservedSeq(node, warmupSeq, 5*time.Second)
		if err != nil {
			t.Fatalf("%s warmup receive failed: %v", node.name, err)
		}
		if !ok {
			t.Fatalf("%s is not receiving cluster config updates; warmup seq=%d observed=%d", node.name, warmupSeq, seq)
		}
	}

	const (
		iterations                 = 180
		processingDelay            = 20 * time.Millisecond
		lagFailureThreshold        = 1500 * time.Millisecond
		pendingFailureThreshold    = 120
		pendingAgeFailureThreshold = 5 * time.Second
		allowedMissesPerNode       = 1
	)

	patchDone := make(chan error, 1)
	go func() {
		client := &http.Client{Timeout: 3 * time.Second}
		for i := 1; i <= iterations; i++ {
			if err := patchJSON(
				client,
				fmt.Sprintf("%s%s?key=settings.observer_latency.seq", httpBase, routes.ValueEndpoint),
				map[string]any{"value": i},
			); err != nil {
				patchDone <- fmt.Errorf("patch iteration %d: %w", i, err)
				return
			}
		}
		patchDone <- nil
	}()

	deadline := time.Now().Add(45 * time.Second)

	for !allNodesReached(nodes, iterations) && time.Now().Before(deadline) {
		for _, node := range nodes {
			if node.latestSeq >= iterations {
				continue
			}
			_ = node.listener.SetReadDeadline(time.Now().Add(100 * time.Millisecond))
			n, _, err := node.listener.ReadFromUDP(buf)
			if err != nil {
				if ne, ok := err.(net.Error); ok && ne.Timeout() {
					continue
				}
				t.Fatalf("udp read on %s: %v", node.name, err)
			}

			msg, err := parseJSON(buf[:n])
			if err != nil {
				continue
			}

			msgID := extractMsgID(msg)
			if msgID != "" {
				if err := sendUDPJSON(node.listener, node.udpAddr, map[string]any{
					"operation": "ack",
					"id":        msgID,
				}); err != nil {
					t.Fatalf("ack msg %s on %s: %v", msgID, node.name, err)
				}
			}

			seq, ok := nestedInt(msg, "settings", "observer_latency", "seq")
			if !ok || seq < node.latestSeq {
				continue
			}
			if seq == warmupSeq {
				continue
			}
			node.latestSeq = seq

			if sentAt, ok := int64Value(msg[api.FusionSentAtNS]); ok {
				lag := time.Since(time.Unix(0, sentAt))
				if lag > node.maxLag {
					node.maxLag = lag
				}
			}

			status := fetchUDPStatusSnapshot(t, node.httpBase)
			if status.PendingBroadcasts > node.maxPending {
				node.maxPending = status.PendingBroadcasts
			}
			if status.OldestPendingAgeMs > node.maxPendingAge {
				node.maxPendingAge = status.OldestPendingAgeMs
			}

			if seq%30 == 0 || seq == iterations {
				t.Logf(
					"%s seq=%d lag=%s queue_depth=%d max_queue_depth=%d pending=%d oldest_pending_age_ms=%d clients=%d broadcasts=%d",
					node.name,
					seq,
					node.maxLag.Round(time.Millisecond),
					status.QueueDepth,
					status.MaxQueueDepth,
					status.PendingBroadcasts,
					status.OldestPendingAgeMs,
					status.RegisteredClients,
					status.BroadcastMessages,
				)
			}
		}
		time.Sleep(processingDelay)
	}

	if err := <-patchDone; err != nil {
		t.Fatal(err)
	}

	var failures []string
	reproduced := false
	for _, node := range nodes {
		node.after = fetchUDPStatusSnapshot(t, node.httpBase)
		t.Logf("%s udp status after load: %+v", node.name, node.after)
		t.Logf(
			"%s observer latency summary: latest_seq=%d/%d max_lag=%s max_pending=%d max_pending_age_ms=%d",
			node.name,
			node.latestSeq,
			iterations,
			node.maxLag.Round(time.Millisecond),
			node.maxPending,
			node.maxPendingAge,
		)
		if iterations-node.latestSeq > allowedMissesPerNode {
			failures = append(failures, fmt.Sprintf(
				"%s fell too far behind: seq=%d/%d pending=%d oldest_pending_age_ms=%d",
				node.name,
				node.latestSeq,
				iterations,
				node.after.PendingBroadcasts,
				node.after.OldestPendingAgeMs,
			))
		}
		if node.maxLag >= lagFailureThreshold ||
			node.maxPending >= pendingFailureThreshold ||
			time.Duration(node.maxPendingAge)*time.Millisecond >= pendingAgeFailureThreshold {
			reproduced = true
		}
	}
	if !reproduced {
		failures = append(failures, "observer latency diagnostic did not reproduce enough lag on any node")
	}
	if len(failures) > 0 {
		slices.Sort(failures)
		t.Fatalf("udp observer latency diagnostic failures:\n%s", strings.Join(failures, "\n"))
	}
}

func allNodesReached(nodes []*udpObserverNode, target int) bool {
	for _, node := range nodes {
		if node.latestSeq < target {
			return false
		}
	}
	return true
}

func udpAddrForNode(httpBase string) (*net.UDPAddr, error) {
	hostPort := strings.TrimPrefix(httpBase, "http://")
	hostPort = strings.TrimPrefix(hostPort, "https://")
	host, _, err := net.SplitHostPort(hostPort)
	if err != nil {
		return nil, err
	}
	return net.ResolveUDPAddr("udp4", net.JoinHostPort(host, api.UDPPort))
}

func awaitObservedSeq(node *udpObserverNode, want int, timeout time.Duration) (int, bool, error) {
	deadline := time.Now().Add(timeout)
	buf := make([]byte, 65535)
	lastSeq := 0
	for time.Now().Before(deadline) {
		_ = node.listener.SetReadDeadline(time.Now().Add(250 * time.Millisecond))
		n, _, err := node.listener.ReadFromUDP(buf)
		if err != nil {
			if ne, ok := err.(net.Error); ok && ne.Timeout() {
				continue
			}
			return lastSeq, false, err
		}
		msg, err := parseJSON(buf[:n])
		if err != nil {
			continue
		}
		msgID := extractMsgID(msg)
		if msgID != "" {
			if err := sendUDPJSON(node.listener, node.udpAddr, map[string]any{
				"operation": "ack",
				"id":        msgID,
			}); err != nil {
				return lastSeq, false, err
			}
		}
		seq, ok := nestedInt(msg, "settings", "observer_latency", "seq")
		if !ok {
			continue
		}
		lastSeq = seq
		if seq >= want {
			return seq, true, nil
		}
	}
	return lastSeq, false, nil
}

func buildBacklogPad(keys, valueLen int) map[string]any {
	pad := make(map[string]any, keys)
	value := bytes.Repeat([]byte("x"), valueLen)
	for i := 0; i < keys; i++ {
		pad[fmt.Sprintf("k%03d", i)] = string(value)
	}
	return pad
}

func postJSON(t *testing.T, url string, payload any) {
	t.Helper()
	data, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal POST payload: %v", err)
	}
	resp, err := http.Post(url, api.JsonMIMEType, bytes.NewBuffer(data))
	if err != nil {
		t.Fatalf("POST %s: %v", url, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("POST %s status=%d body=%s", url, resp.StatusCode, string(body))
	}
}

func patchJSON(client *http.Client, url string, payload any) error {
	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	req, err := http.NewRequest(http.MethodPatch, url, bytes.NewBuffer(data))
	if err != nil {
		return err
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("status=%d body=%s", resp.StatusCode, string(body))
	}
	return nil
}

func fetchUDPStatusSnapshot(t *testing.T, baseURL string) udpStatusSnapshot {
	t.Helper()
	resp, err := http.Get(fmt.Sprintf("%s%s", baseURL, routes.ClusterUDPStatusEndpoint))
	if err != nil {
		t.Fatalf("GET udp status: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET udp status status=%d body=%s", resp.StatusCode, string(body))
	}
	var snapshot udpStatusSnapshot
	if err := json.NewDecoder(resp.Body).Decode(&snapshot); err != nil {
		t.Fatalf("decode udp status: %v", err)
	}
	return snapshot
}

func nestedInt(msg map[string]any, path ...string) (int, bool) {
	current := any(msg)
	for _, part := range path {
		obj, ok := current.(map[string]any)
		if !ok {
			return 0, false
		}
		current, ok = obj[part]
		if !ok {
			return 0, false
		}
	}
	return int(int64ValueDefault(current)), true
}

func int64Value(v any) (int64, bool) {
	switch x := v.(type) {
	case int64:
		return x, true
	case int:
		return int64(x), true
	case float64:
		return int64(x), true
	case json.Number:
		n, err := x.Int64()
		return n, err == nil
	case string:
		n, err := strconv.ParseInt(x, 10, 64)
		return n, err == nil
	default:
		return 0, false
	}
}

func int64ValueDefault(v any) int64 {
	if n, ok := int64Value(v); ok {
		return n
	}
	return 0
}
