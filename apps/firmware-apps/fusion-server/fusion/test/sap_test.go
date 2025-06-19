package main

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"strings"
	"testing"
	"time"

	sdp "github.com/pion/sdp/v3"
)

const (
	sapTestServerAddr = "http://192.168.64.100:8080"
)

type SessionWrapper struct {
	Sessions map[string]struct {
		ID          string                  `json:"id"`
		Origin      string                  `json:"origin"`
		Timestamp   string                  `json:"timestamp"` // or time.Time if parsed
		Description *sdp.SessionDescription `json:"description"`
	} `json:"sessions"`
}

func TestMultipassSAPPropagation(t *testing.T) {
	// Build an 8-byte SAP header:
	//    1 B VARTEC (v1, no compression/auth)
	//    1 B AuthLen = 0
	//    2 B MsgIdHash = 0
	//    4 B Origin = 0.0.0.0
	header := []byte{
		0x20,       // version=1, no C/E/auth
		0x00,       // authLen = 0
		0x00, 0x00, // msgIdHash = 0
		0x00, 0x00, 0x00, 0x00, // origin = 0.0.0.0
	}

	// Build a minimal SDP payload with CRLF line endings
	sdpLines := []string{
		"v=0",
		"o=- 123456 1 IN IP4 0.0.0.0",
		"s=HELLO_SAP_TEST", // session name == our grep target
		"c=IN IP4 224.2.127.254/32",
		"t=0 0",
		"m=audio 5004 RTP/AVP 0",
	}
	// Join with CRLF and terminate with CRLF per RFC4566
	payload := strings.Join(sdpLines, "\r\n") + "\r\n"

	// Send it out over UDP to the first multipass instance
	conn, err := net.Dial("udp", "224.2.127.254:9875")
	if err != nil {
		t.Fatalf("dial multicast: %v", err)
	}
	defer conn.Close()

	msg := append(header, []byte(payload)...)
	if _, err := conn.Write(msg); err != nil {
		t.Fatalf("send SAP packet: %v", err)
	}
	t.Log("Sent full SAP+SDP announcement")

	// Give it a moment to propagate
	time.Sleep(500 * time.Millisecond)

	resp, err := http.Get(fmt.Sprintf("%s/sessions", sapTestServerAddr))
	if err != nil {
		t.Fatalf("Failed to get SAP session: %v", err)
	}

	var wrapper SessionWrapper
	if err := json.NewDecoder(resp.Body).Decode(&wrapper); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}
	resp.Body.Close()

	var descriptions []*sdp.SessionDescription
	for _, session := range wrapper.Sessions {
		if session.Description != nil {
			descriptions = append(descriptions, session.Description)
		}
	}

	if len(descriptions) < 1 {
		t.Fatalf("Expected at least one session")
	}

	description := descriptions[0]

	if description.SessionName != "HELLO_SAP_TEST" {
		t.Fatalf("Expected session-name %q in logs, but got: %s",
			"HELLO_SAP_TEST", description.SessionName)
	}
}
