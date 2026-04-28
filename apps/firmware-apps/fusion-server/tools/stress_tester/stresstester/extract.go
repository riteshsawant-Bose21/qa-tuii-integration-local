package stresstester

import "encoding/json"

// extractGain navigates the nested path settings.audio.GAIN.gain from a
// decoded JSON map and returns the integer gain value.
func extractGain(data map[string]any) (int, bool) {
	settings, ok := asMap(data["settings"])
	if !ok {
		return 0, false
	}
	audio, ok := asMap(settings["audio"])
	if !ok {
		return 0, false
	}
	gainObj, ok := asMap(audio["GAIN"])
	if !ok {
		return 0, false
	}
	return asInt(gainObj["gain"])
}

// extractGainFromWSData extracts gain from a WebSocket config_update push.
// The push data is the full config state: {"settings":{"audio":{"GAIN":{"gain":N}}},...}
func extractGainFromWSData(data any) (int, bool) {
	m, ok := data.(map[string]any)
	if !ok {
		return 0, false
	}
	return extractGain(m)
}

func asMap(v any) (map[string]any, bool) {
	m, ok := v.(map[string]any)
	return m, ok
}

func asInt(v any) (int, bool) {
	switch n := v.(type) {
	case float64:
		return int(n), true
	case int:
		return n, true
	case int64:
		return int(n), true
	case json.Number:
		i, err := n.Int64()
		if err != nil {
			return 0, false
		}
		return int(i), true
	}
	return 0, false
}
