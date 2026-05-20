package main

import (
	"fmt"
	model "fusion/internal/gen/proto/fusion"
	"net/http"
	"net/url"
	"testing"
	"time"
)

func TestVIPStatusEndpoint(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, append([]string{originalVIP}, candidateVIPs(t, originalVIP)...))

	resp, err := http.Get(fmt.Sprintf("%s/devices/vip/status", clusterConfig.vip))
	if err != nil {
		t.Fatalf("GET /devices/vip/status failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 from /devices/vip/status, got %d", resp.StatusCode)
	}

	var payload model.VIPOperationStatus
	if err := decodeProtoBody(resp.Body, &payload); err != nil {
		t.Fatalf("failed to decode /devices/vip/status response: %v", err)
	}

	if payload.GetObservedVip() != originalVIP {
		t.Fatalf("expected observed_vip=%s, got %s", originalVIP, payload.GetObservedVip())
	}
	if payload.GetPhase() == "" {
		t.Fatal("expected phase in /devices/vip/status response")
	}
}

func TestVIPOperationEndpointNotFound(t *testing.T) {
	resp, err := http.Get(fmt.Sprintf("%s/devices/vip/operations/%s", clusterConfig.vip, "vipop_missing"))
	if err != nil {
		t.Fatalf("GET /devices/vip/operations/{id} failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNotFound {
		t.Fatalf("expected 404 for missing VIP operation, got %d", resp.StatusCode)
	}
}

func TestVIPReloadStatusEndpoint(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, append([]string{originalVIP}, candidateVIPs(t, originalVIP)...))

	adminHost := hostFromNodeURL(t, nodeURLs[0])
	resp, err := http.Get(fmt.Sprintf("%s/device/reload/vip/status", adminURLForHost(adminHost)))
	if err != nil {
		t.Fatalf("GET /device/reload/vip/status failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 from /device/reload/vip/status, got %d", resp.StatusCode)
	}

	var payload model.VIPApplyStatus
	if err := decodeProtoBody(resp.Body, &payload); err != nil {
		t.Fatalf("failed to decode reload status response: %v", err)
	}
	if payload.GetPhase() == "" {
		t.Fatal("expected phase in reload status response")
	}
}

func TestVIPReloadEndpointRejectsConcurrentApply(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, append([]string{originalVIP}, candidateVIPs(t, originalVIP)...))

	adminHost := hostFromNodeURL(t, nodeURLs[0])
	reloadURL := fmt.Sprintf("%s/device/reload/vip", adminURLForHost(adminHost))

	resp1, err := http.Post(reloadURL, "", nil)
	if err != nil {
		t.Fatalf("first POST /device/reload/vip failed: %v", err)
	}
	resp1.Body.Close()
	if resp1.StatusCode != http.StatusAccepted {
		t.Fatalf("expected first reload request to return 202, got %d", resp1.StatusCode)
	}

	resp2, err := http.Post(reloadURL, "", nil)
	if err != nil {
		t.Fatalf("second POST /device/reload/vip failed: %v", err)
	}
	defer resp2.Body.Close()
	if resp2.StatusCode != http.StatusConflict {
		t.Fatalf("expected second reload request to return 409, got %d", resp2.StatusCode)
	}

	waitForVIPReloadComplete(t, adminHost)
}

func TestSetVIPRejectsConcurrentOperation(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	candidates := candidateVIPs(t, originalVIP)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, append([]string{originalVIP}, candidates...))

	firstTarget := candidates[0]
	secondTarget := candidates[1]

	firstOp, _ := setVIPRequest(t, vipURLForHost(originalVIP), firstTarget)

	resp, err := http.Post(fmt.Sprintf("%s/devices/vip/%s", vipURLForHost(originalVIP), url.PathEscape(secondTarget)), "", nil)
	if err != nil {
		t.Fatalf("second POST /devices/vip/%s failed: %v", secondTarget, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusConflict {
		t.Fatalf("expected second public VIP change to return 409, got %d", resp.StatusCode)
	}

	waitForVIPOperationComplete(t, firstOp.GetStatusHost(), firstOp.GetId())
	waitForVIPState(t, firstTarget)
	waitForOldVIPRetirement(t, originalVIP)

	restoreOp, _ := setVIPRequest(t, vipURLForHost(firstTarget), originalVIP)
	waitForVIPOperationComplete(t, restoreOp.GetStatusHost(), restoreOp.GetId())
	waitForVIPState(t, originalVIP)
	waitForExclusiveVIPState(t, originalVIP, append([]string{originalVIP}, candidates...))
}

func TestSetVIPRejectsNonCurrentVIPHost(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, append([]string{originalVIP}, candidateVIPs(t, originalVIP)...))

	targetVIP := candidateVIPs(t, originalVIP)[0]
	var nonCurrentNodeURL string
	for _, nodeURL := range nodeURLs {
		if hostFromNodeURL(t, nodeURL) != originalVIP {
			nonCurrentNodeURL = nodeURL
			break
		}
	}
	if nonCurrentNodeURL == "" {
		t.Fatal("could not find non-current VIP node URL")
	}

	resp, err := http.Post(fmt.Sprintf("%s/devices/vip/%s", nonCurrentNodeURL, url.PathEscape(targetVIP)), "", nil)
	if err != nil {
		t.Fatalf("POST /devices/vip/%s via non-current host failed: %v", targetVIP, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusConflict {
		t.Fatalf("expected 409 when setting VIP through non-current host, got %d", resp.StatusCode)
	}
}

func waitForVIPReloadComplete(t *testing.T, adminHost string) {
	t.Helper()

	client := &http.Client{Timeout: setupVIPPollTimeout}
	deadline := time.Now().Add(setupVIPTimeout)
	for time.Now().Before(deadline) {
		resp, err := client.Get(fmt.Sprintf("%s/device/reload/vip/status", adminURLForHost(adminHost)))
		if err != nil {
			time.Sleep(500 * time.Millisecond)
			continue
		}

		var payload model.VIPApplyStatus
		decodeErr := decodeProtoBody(resp.Body, &payload)
		resp.Body.Close()
		if decodeErr != nil {
			time.Sleep(500 * time.Millisecond)
			continue
		}

		switch payload.GetPhase() {
		case "complete", "idle":
			return
		case "failed":
			t.Fatalf("VIP reload failed on %s: %s", adminHost, payload.GetMessage())
		default:
			time.Sleep(500 * time.Millisecond)
		}
	}

	t.Fatalf("VIP reload on %s did not complete within %v", adminHost, setupVIPTimeout)
}
