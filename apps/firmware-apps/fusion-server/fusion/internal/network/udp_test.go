package network

import (
	"testing"

	"fusion-services-core/logging"
	"fusion/internal/api"
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
