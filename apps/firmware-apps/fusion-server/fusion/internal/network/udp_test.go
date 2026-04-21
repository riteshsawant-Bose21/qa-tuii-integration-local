package network

import (
	"testing"

	"fusion/internal/api"
)

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
