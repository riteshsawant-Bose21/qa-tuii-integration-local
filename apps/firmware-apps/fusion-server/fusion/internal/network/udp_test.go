package network

import (
	"net"
	"strings"
	"testing"
	"time"

	"fusion-services-core/logging"
	"fusion/internal/api"

	json "github.com/goccy/go-json"
)

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName: "network_udp_test",
		LogDir:   "/tmp/network_udp_test",
		LogLevel: logging.ERROR,
	})
}

func TestConfigObserverPayloadPrefersObserverDiff(t *testing.T) {
	full := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{"gain": 1},
			"other": "keep",
		},
	}
	diff := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{"gain": 2},
		},
	}

	got := configObserverPayload(&api.ConfigUpdate{
		Data:         full,
		ObserverData: diff,
	})

	settings, ok := got["settings"].(map[string]any)
	if !ok {
		t.Fatalf("expected settings map, got %#v", got)
	}
	audio, ok := settings["audio"].(map[string]any)
	if !ok {
		t.Fatalf("expected audio map, got %#v", settings)
	}
	if audio["gain"] != 2 {
		t.Fatalf("expected observer diff payload, got %#v", got)
	}
	if _, ok := settings["other"]; ok {
		t.Fatalf("expected diff payload without unrelated state, got %#v", got)
	}
}

func TestConfigObserverPayloadFallsBackToFullData(t *testing.T) {
	full := map[string]any{"settings": map[string]any{"audio": map[string]any{"gain": 1}}}

	got := configObserverPayload(&api.ConfigUpdate{Data: full})
	settings, ok := got["settings"].(map[string]any)
	if !ok {
		t.Fatalf("expected settings map, got %#v", got)
	}
	audio, ok := settings["audio"].(map[string]any)
	if !ok {
		t.Fatalf("expected audio map, got %#v", settings)
	}
	if audio["gain"] != 1 {
		t.Fatalf("expected full payload fallback, got %#v", got)
	}
}

func TestConfigBroadcastDoesNotDropWhenCachedVersionIsAhead(t *testing.T) {
	srv := &UDPServer{
		pending:            make(map[string]*pendingBroadcast),
		diagnosticsEnabled: true,
	}
	srv.lastBroadcastVersion.Store(100)

	msg := api.NewNotifyMessage(
		api.NotifyOpConfigUpdate,
		"node-a",
		api.WithConfigUpdate(&api.ConfigUpdate{
			Data: map[string]any{
				"audio": map[string]any{
					"settings": map[string]any{
						"gain_block": map[string]any{
							"mute": true,
						},
					},
				},
			},
			Version: api.Version{Counter: 1, NodeID: "node-a"},
		}),
	)

	if err := srv.BroadcastMessage(msg); err != nil {
		t.Fatalf("BroadcastMessage failed: %v", err)
	}

	if got := srv.broadcastMessages.Load(); got != 1 {
		t.Fatalf("expected broadcast path to run once, got %d", got)
	}
	if got := srv.lastBroadcastVersion.Load(); got != 1 {
		t.Fatalf("expected last broadcast version to update to 1, got %d", got)
	}
}

func TestSendResponseOversizedGetRequiresConfigPull(t *testing.T) {
	serverConn, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: 0})
	if err != nil {
		t.Fatalf("ListenUDP server failed: %v", err)
	}
	defer serverConn.Close()

	clientConn, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.ParseIP("127.0.0.1"), Port: 0})
	if err != nil {
		t.Fatalf("ListenUDP client failed: %v", err)
	}
	defer clientConn.Close()

	srv := &UDPServer{
		Listener: &Listener{conn: serverConn},
		clients:  make(map[string]*clientState),
		pending:  make(map[string]*pendingBroadcast),
	}

	response := map[string]any{
		"_fusion_op": "get",
		"status":     "success",
		"payload": map[string]any{
			"settings": map[string]any{
				"oversized": strings.Repeat("x", 70*1024),
			},
		},
	}

	version := api.Version{Counter: 42, Epoch: 7, NodeID: "node-a"}
	srv.sendResponse(clientConn.LocalAddr().(*net.UDPAddr), response, api.NotifyOpValueGet, version)

	buf := make([]byte, 4096)
	_ = clientConn.SetReadDeadline(time.Now().Add(time.Second))
	n, _, err := clientConn.ReadFromUDP(buf)
	if err != nil {
		t.Fatalf("ReadFromUDP failed: %v", err)
	}

	var msg map[string]any
	if err := json.Unmarshal(buf[:n], &msg); err != nil {
		t.Fatalf("parse response: %v", err)
	}
	if msg[api.FusionOperation] != string(api.NotifyOpConfigPullRequired) {
		t.Fatalf("expected config_pull_required, got %#v", msg)
	}
	if msg[api.FusionVersion] != float64(version.Counter) {
		t.Fatalf("expected version %d, got %#v", version.Counter, msg[api.FusionVersion])
	}
	if msg[api.FusionEpoch] != float64(version.Epoch) {
		t.Fatalf("expected epoch %d, got %#v", version.Epoch, msg[api.FusionEpoch])
	}
}
