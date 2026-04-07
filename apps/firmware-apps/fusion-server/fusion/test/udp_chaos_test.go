package main

import (
	"fmt"
	"math/rand"
	"net"
	"net/url"
	"os"
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
	defaultChaosDeviceCount = 60
	defaultChaosDuration    = 20 * time.Second
	defaultChaosUDPPort     = 7947
)

type udpChaosConfig struct {
	NodeAddrs         []string
	DeviceCount       int
	Duration          time.Duration
	SendIntervalMin   time.Duration
	SendIntervalMax   time.Duration
	PacketLossRate    float64
	DisconnectRate    float64
	ReconnectDelayMin time.Duration
	ReconnectDelayMax time.Duration
	BurstChance       float64
	BurstMaxExtra     int
}

type udpChaosMetrics struct {
	Sent               atomic.Uint64
	ReadOK             atomic.Uint64
	ReadTimeout        atomic.Uint64
	WriteErrors        atomic.Uint64
	IntentionalLoss    atomic.Uint64
	Disconnects        atomic.Uint64
	Reconnects         atomic.Uint64
	CorruptPayloadSent atomic.Uint64
}

type virtualUDPDevice struct {
	id int

	cfg     udpChaosConfig
	metrics *udpChaosMetrics
	rng     *rand.Rand
}

// TestFusionUDP_ChaosMesh_Multipass validates high fan-out UDP traffic with
// fault injection across multiple nodes in a multipass environment.
func TestFusionUDP_ChaosMesh_Multipass(t *testing.T) {
	if os.Getenv("FUSION_UDP_CHAOS_TEST") == "" {
		t.Skip("Skipping UDP chaos mesh test; set FUSION_UDP_CHAOS_TEST=1 to enable")
	}

	cfg, err := loadUDPChaosConfig()
	if err != nil {
		t.Fatalf("invalid UDP chaos config: %v", err)
	}

	if runtime.GOOS == "darwin" && len(cfg.NodeAddrs) < 3 && shouldSkipMultipassOnDarwin() {
		t.Skip("macOS and Multipass networking may block VM-to-host UDP replies; provide explicit FUSION_UDP_NODES to run.")
	}

	if len(cfg.NodeAddrs) < 3 {
		t.Fatalf("need at least 3 UDP nodes, got %d (%v)", len(cfg.NodeAddrs), cfg.NodeAddrs)
	}

	t.Logf(
		"UDP Chaos Config\n"+
			"  Nodes           : %v\n"+
			"  Virtual devices : %d\n"+
			"  Duration        : %s\n"+
			"  Packet loss     : %.2f\n"+
			"  Disconnect rate : %.2f\n"+
			"  Burst chance    : %.2f",
		cfg.NodeAddrs,
		cfg.DeviceCount,
		cfg.Duration,
		cfg.PacketLossRate,
		cfg.DisconnectRate,
		cfg.BurstChance,
	)

	var metrics udpChaosMetrics
	var wg sync.WaitGroup
	deadline := time.Now().Add(cfg.Duration)

	for i := 0; i < cfg.DeviceCount; i++ {
		wg.Add(1)
		go func(deviceID int) {
			defer wg.Done()
			device := virtualUDPDevice{
				id:      deviceID,
				cfg:     cfg,
				metrics: &metrics,
				rng:     rand.New(rand.NewSource(time.Now().UnixNano() + int64(deviceID)*97)),
			}
			device.run(deadline)
		}(i)
	}

	wg.Wait()

	sent := metrics.Sent.Load()
	readOK := metrics.ReadOK.Load()
	readTimeout := metrics.ReadTimeout.Load()
	intentionalLoss := metrics.IntentionalLoss.Load()
	writeErrors := metrics.WriteErrors.Load()
	disconnects := metrics.Disconnects.Load()
	reconnects := metrics.Reconnects.Load()
	corrupt := metrics.CorruptPayloadSent.Load()
	totalReads := readOK + readTimeout
	successRate := ratio(readOK, totalReads)
	lossRate := ratio(intentionalLoss, sent+intentionalLoss)
	reconnectPerDisconnect := ratio(reconnects, disconnects)

	t.Logf(
		"UDP Chaos Metrics\n"+
			"  Sent packets         : %d\n"+
			"  Read OK              : %d\n"+
			"  Read timeouts        : %d\n"+
			"  Read success rate    : %.1f%%\n"+
			"  Intentional loss     : %d (%.1f%%)\n"+
			"  Write errors         : %d\n"+
			"  Disconnect events    : %d\n"+
			"  Reconnect events     : %d (%.2fx/disconnect)\n"+
			"  Corrupt payload sent : %d",
		sent,
		readOK,
		readTimeout,
		successRate*100,
		intentionalLoss,
		lossRate*100,
		writeErrors,
		disconnects,
		reconnects,
		reconnectPerDisconnect,
		corrupt,
	)

	if sent == 0 {
		t.Fatalf("no UDP messages were sent")
	}
	if readOK == 0 {
		t.Fatalf("no UDP responses were received from nodes")
	}
	if intentionalLoss == 0 && cfg.PacketLossRate > 0 {
		t.Fatalf("packet loss simulation did not trigger")
	}
	if disconnects == 0 && cfg.DisconnectRate > 0 {
		t.Fatalf("disconnect simulation did not trigger")
	}
	if reconnects == 0 && cfg.DisconnectRate > 0 {
		t.Fatalf("reconnect simulation did not trigger")
	}
}

func loadUDPChaosConfig() (udpChaosConfig, error) {
	nodes := discoverUDPChaosNodes()
	if len(nodes) == 0 {
		nodes = []string{getFusionUDPAddr()}
	}

	deviceCount := getenvIntWithDefault("FUSION_UDP_VIRTUAL_DEVICES", defaultChaosDeviceCount)
	duration := getenvDurationWithDefault("FUSION_UDP_TEST_DURATION", defaultChaosDuration)
	loss := getenvFloatWithDefault("FUSION_UDP_PACKET_LOSS", 0.2)
	disconnect := getenvFloatWithDefault("FUSION_UDP_DISCONNECT_RATE", 0.04)
	burst := getenvFloatWithDefault("FUSION_UDP_BURST_CHANCE", 0.1)
	burstMax := getenvIntWithDefault("FUSION_UDP_BURST_MAX_EXTRA", 3)

	cfg := udpChaosConfig{
		NodeAddrs:         nodes,
		DeviceCount:       deviceCount,
		Duration:          duration,
		SendIntervalMin:   getenvDurationWithDefault("FUSION_UDP_SEND_MIN", 15*time.Millisecond),
		SendIntervalMax:   getenvDurationWithDefault("FUSION_UDP_SEND_MAX", 65*time.Millisecond),
		PacketLossRate:    clamp(loss, 0, 1),
		DisconnectRate:    clamp(disconnect, 0, 1),
		ReconnectDelayMin: getenvDurationWithDefault("FUSION_UDP_RECONNECT_MIN", 200*time.Millisecond),
		ReconnectDelayMax: getenvDurationWithDefault("FUSION_UDP_RECONNECT_MAX", 1400*time.Millisecond),
		BurstChance:       clamp(burst, 0, 1),
		BurstMaxExtra:     maxInt(0, burstMax),
	}

	if cfg.DeviceCount <= 0 {
		return cfg, fmt.Errorf("FUSION_UDP_VIRTUAL_DEVICES must be > 0")
	}
	if cfg.SendIntervalMax < cfg.SendIntervalMin {
		return cfg, fmt.Errorf("FUSION_UDP_SEND_MAX must be >= FUSION_UDP_SEND_MIN")
	}
	if cfg.ReconnectDelayMax < cfg.ReconnectDelayMin {
		return cfg, fmt.Errorf("FUSION_UDP_RECONNECT_MAX must be >= FUSION_UDP_RECONNECT_MIN")
	}
	return cfg, nil
}

func discoverUDPChaosNodes() []string {
	if explicit := strings.TrimSpace(os.Getenv("FUSION_UDP_NODES")); explicit != "" {
		return uniqueNonEmpty(splitAndNormalizeUDPAddrs(explicit))
	}

	// Reuse cluster discovery performed by TestMain in fusion_test.go.
	if clusterConfig != nil && len(clusterConfig.nodes) > 0 {
		udpPort := getenvIntWithDefault("FUSION_UDP_PORT", defaultChaosUDPPort)
		out := make([]string, 0, len(clusterConfig.nodes))
		for _, n := range clusterConfig.nodes {
			host := nodeHost(n.address)
			if host == "" {
				continue
			}
			out = append(out, net.JoinHostPort(host, strconv.Itoa(udpPort)))
		}
		if len(out) > 0 {
			return uniqueNonEmpty(out)
		}
	}

	httpNodes := strings.TrimSpace(os.Getenv("FUSION_TEST_NODES"))
	if httpNodes == "" {
		return nil
	}

	udpPort := getenvIntWithDefault("FUSION_UDP_PORT", defaultChaosUDPPort)
	parts := strings.Split(httpNodes, ",")
	out := make([]string, 0, len(parts))

	for _, raw := range parts {
		raw = strings.TrimSpace(raw)
		if raw == "" {
			continue
		}

		host := ""
		if strings.Contains(raw, "://") {
			if u, err := url.Parse(raw); err == nil {
				host = u.Hostname()
			}
		}
		if host == "" {
			// Try host:port and plain host fallback.
			if h, _, err := net.SplitHostPort(raw); err == nil {
				host = h
			} else {
				host = raw
			}
		}
		if host == "" {
			continue
		}
		out = append(out, net.JoinHostPort(host, strconv.Itoa(udpPort)))
	}

	return uniqueNonEmpty(out)
}

func nodeHost(raw string) string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return ""
	}
	if strings.Contains(raw, "://") {
		if u, err := url.Parse(raw); err == nil {
			return u.Hostname()
		}
	}
	if h, _, err := net.SplitHostPort(raw); err == nil {
		return h
	}
	return raw
}

func splitAndNormalizeUDPAddrs(v string) []string {
	parts := strings.Split(v, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func uniqueNonEmpty(in []string) []string {
	seen := make(map[string]struct{}, len(in))
	out := make([]string, 0, len(in))
	for _, v := range in {
		if v == "" {
			continue
		}
		if _, ok := seen[v]; ok {
			continue
		}
		seen[v] = struct{}{}
		out = append(out, v)
	}
	return out
}

func (d *virtualUDPDevice) run(deadline time.Time) {
	var (
		conn         *net.UDPConn
		currentNode  = -1
		reconnectAt  time.Time
		seq          uint64
		shouldRead   = true
		retryReadBuf = make([]byte, 4096)
	)

	closeConn := func() {
		if conn != nil {
			_ = conn.Close()
			conn = nil
		}
	}
	defer closeConn()

	for time.Now().Before(deadline) {
		now := time.Now()
		if now.Before(reconnectAt) {
			time.Sleep(10 * time.Millisecond)
			continue
		}

		if conn == nil || d.rng.Intn(5) == 0 {
			next := d.rng.Intn(len(d.cfg.NodeAddrs))
			if currentNode != next {
				closeConn()
			}
			currentNode = next
			target := d.cfg.NodeAddrs[currentNode]
			udpAddr, err := net.ResolveUDPAddr("udp4", target)
			if err == nil {
				conn, err = net.DialUDP("udp4", nil, udpAddr)
			}
			if err != nil {
				d.metrics.WriteErrors.Add(1)
				reconnectAt = now.Add(100 * time.Millisecond)
				continue
			}
			d.metrics.Reconnects.Add(1)
		}

		if d.rng.Float64() < d.cfg.DisconnectRate {
			d.metrics.Disconnects.Add(1)
			closeConn()
			reconnectAt = now.Add(randomDuration(d.rng, d.cfg.ReconnectDelayMin, d.cfg.ReconnectDelayMax))
			continue
		}

		seq++
		payload := d.makePayload(seq)
		if d.rng.Float64() < 0.02 {
			payload = []byte(`{"action":"put","payload":{"broken":`)
			d.metrics.CorruptPayloadSent.Add(1)
		}

		sendCount := 1
		if d.rng.Float64() < d.cfg.BurstChance {
			sendCount += d.rng.Intn(d.cfg.BurstMaxExtra + 1)
		}

		for i := 0; i < sendCount; i++ {
			if d.rng.Float64() < d.cfg.PacketLossRate {
				d.metrics.IntentionalLoss.Add(1)
				continue
			}

			if conn == nil {
				d.metrics.WriteErrors.Add(1)
				break
			}
			_ = conn.SetWriteDeadline(time.Now().Add(250 * time.Millisecond))
			if _, err := conn.Write(payload); err != nil {
				d.metrics.WriteErrors.Add(1)
				closeConn()
				reconnectAt = time.Now().Add(100 * time.Millisecond)
				break
			}
			d.metrics.Sent.Add(1)

			// Alternate reads to avoid filling receive buffers and to validate responses.
			shouldRead = !shouldRead
			if !shouldRead {
				continue
			}
			_ = conn.SetReadDeadline(time.Now().Add(180 * time.Millisecond))
			if _, err := conn.Read(retryReadBuf); err != nil {
				if ne, ok := err.(net.Error); ok && ne.Timeout() {
					d.metrics.ReadTimeout.Add(1)
				} else {
					d.metrics.WriteErrors.Add(1)
					closeConn()
					reconnectAt = time.Now().Add(100 * time.Millisecond)
				}
				continue
			}
			d.metrics.ReadOK.Add(1)
		}

		time.Sleep(randomDuration(d.rng, d.cfg.SendIntervalMin, d.cfg.SendIntervalMax))
	}
}

func (d *virtualUDPDevice) makePayload(seq uint64) []byte {
	setPayload := map[string]any{
		"action": "put",
		"payload": map[string]any{
			"vd_id": d.id,
			"seq":   seq,
			"ts":    time.Now().UnixNano(),
		},
	}
	getPayload := map[string]any{
		"action": "get",
	}

	msg := setPayload
	if seq%3 == 0 {
		msg = getPayload
	}
	data, err := json.Marshal(msg)
	if err != nil {
		// Keep device running even if marshaling fails unexpectedly.
		return []byte(`{"action":"get"}`)
	}
	return data
}

func randomDuration(r *rand.Rand, min, max time.Duration) time.Duration {
	if max <= min {
		return min
	}
	delta := max - min
	return min + time.Duration(r.Int63n(int64(delta)+1))
}

func getenvIntWithDefault(key string, def int) int {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	n, err := strconv.Atoi(v)
	if err != nil {
		return def
	}
	return n
}

func getenvFloatWithDefault(key string, def float64) float64 {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	n, err := strconv.ParseFloat(v, 64)
	if err != nil {
		return def
	}
	return n
}

func getenvDurationWithDefault(key string, def time.Duration) time.Duration {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	if d, err := time.ParseDuration(v); err == nil {
		return d
	}
	if secs, err := strconv.Atoi(v); err == nil {
		return time.Duration(secs) * time.Second
	}
	return def
}

func clamp(v, lo, hi float64) float64 {
	return min(max(v, lo), hi)
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func ratio(numerator, denominator uint64) float64 {
	if denominator == 0 {
		return 0
	}
	return float64(numerator) / float64(denominator)
}
