package main

import (
	"fmt"
	"net"
	"os/exec"
	"strings"
	"testing"
	"time"
)

const (
	sapInstance2Name = "fusion2"
)

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

	// Build a minimal SDP payload with CRLF line endings:
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

	// Grep second instance logs for the session name
	out, err := checkSAPOnInstance(t, "HELLO_SAP_TEST")
	if err != nil {
		t.Fatalf("failed to grep on %s: %v\noutput: %s",
			sapInstance2Name, err, out)
	}

	if !strings.Contains(out, "HELLO_SAP_TEST") {
		t.Fatalf("expected session-name %q in logs, but got: %s",
			"HELLO_SAP_TEST", out)
	}
}

// runSAPCommandOnInstance executes a bash command on a given instance using multipass exec.
func runSAPCommandOnInstance(t *testing.T, instance, command string) (string, error) {
	t.Helper()
	args := []string{"exec", instance, "--", "bash", "-c", command}
	cmd := exec.Command("multipass", args...)
	output, err := cmd.CombinedOutput()
	return string(output), err
}

// checkSAPOnInstance greps for the payload (or whatever marker your handler writes) on instance2.
func checkSAPOnInstance(t *testing.T, marker string) (string, error) {
	t.Helper()
	grepCmd := fmt.Sprintf(
		`journalctl -u fusion-server --no-pager | grep '%s' || true`,
		marker,
	)
	return runSAPCommandOnInstance(t, sapInstance2Name, grepCmd)
}
