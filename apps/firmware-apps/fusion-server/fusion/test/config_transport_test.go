package main

import (
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"testing"
	"time"

	"fusion/internal/api"
)

func websocketURLFromHTTPBase(base string) string {
	parsed, err := url.Parse(base)
	if err != nil {
		return strings.Replace(base, "http://", "ws://", 1) + "/ws"
	}

	switch parsed.Scheme {
	case "https":
		parsed.Scheme = "wss"
	default:
		parsed.Scheme = "ws"
	}
	parsed.Path = "/ws"
	parsed.RawQuery = ""
	parsed.Fragment = ""
	return parsed.String()
}

func mustMarshalWebSocketData(t *testing.T, v any) any {
	t.Helper()
	return v
}

func patchConfigViaWebSocket(t *testing.T, baseHTTP string, patch map[string]any) *wsResponse {
	t.Helper()

	conn := connectWebSocket(t, websocketURLFromHTTPBase(baseHTTP))
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout)

	req := &wsRequest{
		ID:      fmt.Sprintf("patch-%d", time.Now().UnixNano()),
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypePatchConfiguration,
		Data:    mustMarshalWebSocketData(t, patch),
	}
	sendWebSocketRequest(t, conn, req)

	resp := readWebSocketResponse(t, conn, wsTestTimeout)
	if resp.Code != api.WSCodeUpdated && resp.Code != api.WSCodeOK {
		t.Fatalf("patch_config failed: code=%d type=%s status=%s message=%s", resp.Code, resp.Type, resp.Status, resp.Message)
	}
	return resp
}

func getFullConfigViaWebSocket(t *testing.T, baseHTTP string) map[string]any {
	t.Helper()

	conn := connectWebSocket(t, websocketURLFromHTTPBase(baseHTTP))
	defer conn.Close()

	readWebSocketResponse(t, conn, wsTestTimeout)

	req := &wsRequest{
		ID:      fmt.Sprintf("config-%d", time.Now().UnixNano()),
		Version: api.WSCurrentVersion,
		Type:    api.WSMsgTypeConfiguration,
	}
	sendWebSocketRequest(t, conn, req)

	resp := readWebSocketResponse(t, conn, wsTestTimeout)
	if resp.Code != api.WSCodeOK {
		t.Fatalf("configuration request failed: code=%d type=%s status=%s message=%s", resp.Code, resp.Type, resp.Status, resp.Message)
	}

	if resp.Data == nil {
		return map[string]any{}
	}
	data, ok := resp.Data.(map[string]any)
	if !ok {
		t.Fatalf("configuration data has unexpected type %T", resp.Data)
	}
	return data
}

func getConfigValueViaWebSocket(t *testing.T, baseHTTP, key string) any {
	t.Helper()
	return lookupConfigValue(getFullConfigViaWebSocket(t, baseHTTP), key)
}

func lookupConfigValue(data map[string]any, key string) any {
	parts := parseConfigKeyPath(key)
	var current any = data
	for _, part := range parts {
		switch c := current.(type) {
		case map[string]any:
			next, ok := c[part]
			if !ok {
				return nil
			}
			current = next
		case []any:
			idx, err := strconv.Atoi(part)
			if err != nil || idx < 0 || idx >= len(c) {
				return nil
			}
			current = c[idx]
		default:
			return nil
		}
	}
	return current
}

func parseConfigKeyPath(key string) []string {
	return strings.FieldsFunc(key, func(r rune) bool {
		return r == '.' || r == '[' || r == ']'
	})
}
