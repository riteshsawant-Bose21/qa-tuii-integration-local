package main

import (
	"fmt"
	"net/http"
	"net/netip"
	"net/url"
	"slices"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

const (
	setupVIPTimeout        = 30 * time.Second
	setupVIPRequestTimeout = 5 * time.Second
	setupVIPAdminTimeout   = 15 * time.Second
	setupVIPPollTimeout    = 3 * time.Second
	setupVIPStressCycles   = 3
)

type vipOperationResponse struct {
	ID         string `json:"id"`
	DesiredVIP string `json:"desired_vip"`
	StatusHost string `json:"status_host"`
	Phase      string `json:"phase"`
	Message    string `json:"message"`
}

func setupVIPTarget(t *testing.T) (nodeURLs []string, originalVIP string, nodeNamesByIP map[string]string) {
	t.Helper()

	if clusterConfig == nil {
		t.Fatal("clusterConfig is nil")
	}
	if len(clusterConfig.nodes) == 0 {
		t.Fatal("no cluster nodes configured")
	}
	if clusterConfig.vip == "" {
		t.Fatal("cluster VIP is empty")
	}

	nodeURLs = make([]string, 0, len(clusterConfig.nodes))
	nodeNamesByIP = make(map[string]string, len(clusterConfig.nodes))
	for _, node := range clusterConfig.nodes {
		parsedNodeURL, err := url.Parse(node.address)
		if err != nil {
			t.Fatalf("failed to parse node URL %q: %v", node.address, err)
		}
		if parsedNodeURL.Hostname() == "" {
			t.Fatalf("node URL %q does not contain a hostname", node.address)
		}
		nodeURLs = append(nodeURLs, node.address)
		nodeNamesByIP[parsedNodeURL.Hostname()] = node.name
	}

	return nodeURLs, mustVIPHost(t, clusterConfig.vip), nodeNamesByIP
}

func mustVIPHost(t *testing.T, vipURL string) string {
	t.Helper()

	parsedVIP, err := url.Parse(vipURL)
	if err != nil {
		t.Fatalf("failed to parse VIP URL %q: %v", vipURL, err)
	}
	if parsedVIP.Hostname() == "" {
		t.Fatalf("VIP URL %q does not contain a hostname", vipURL)
	}

	return parsedVIP.Hostname()
}

func vipURLForHost(host string) string {
	return fmt.Sprintf("http://%s:8080", host)
}

func adminURLForHost(host string) string {
	return fmt.Sprintf("http://%s:9090", host)
}

func hostFromNodeURL(t *testing.T, nodeURL string) string {
	t.Helper()

	parsed, err := url.Parse(nodeURL)
	if err != nil {
		t.Fatalf("failed to parse node URL %q: %v", nodeURL, err)
	}
	if parsed.Hostname() == "" {
		t.Fatalf("node URL %q does not contain a hostname", nodeURL)
	}

	return parsed.Hostname()
}

func candidateVIPs(t *testing.T, originalVIP string) []string {
	t.Helper()

	addr, err := netip.ParseAddr(originalVIP)
	if err != nil {
		t.Fatalf("failed to parse original VIP %q: %v", originalVIP, err)
	}
	addr = addr.Unmap()
	if !addr.Is4() {
		t.Fatalf("expected IPv4 VIP, got %q", originalVIP)
	}

	raw := addr.As4()
	lastOctet := raw[3]

	candidates := make([]string, 0, 3)
	for _, octet := range []byte{101, 102, 103, 100} {
		if octet == lastOctet {
			continue
		}
		raw[3] = octet
		candidates = append(candidates, netip.AddrFrom4(raw).String())
		if len(candidates) == 2 {
			break
		}
	}
	if len(candidates) < 2 {
		t.Fatalf("could not derive alternate VIPs from %q", originalVIP)
	}

	return candidates
}

func setVIPRequest(t *testing.T, nodeURL string, targetVIP string) (vipOperationResponse, time.Duration) {
	t.Helper()

	client := &http.Client{Timeout: setupVIPRequestTimeout}
	start := time.Now()
	resp, err := client.Post(fmt.Sprintf("%s/devices/vip/%s", nodeURL, url.PathEscape(targetVIP)), "", nil)
	duration := time.Since(start)
	if err != nil {
		t.Fatalf("POST /devices/vip/%s failed after %v: %v", targetVIP, duration, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusAccepted {
		t.Fatalf("expected %d from VIP setup endpoint for %s, got %d", http.StatusAccepted, targetVIP, resp.StatusCode)
	}

	var payload vipOperationResponse
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		t.Fatalf("failed to decode VIP operation response for %s: %v", targetVIP, err)
	}
	if payload.ID == "" {
		t.Fatalf("VIP operation response for %s did not include an id", targetVIP)
	}
	if payload.StatusHost == "" {
		t.Fatalf("VIP operation response for %s did not include a status host", targetVIP)
	}

	return payload, duration
}

func postAdminNoBody(t *testing.T, adminHost string, path string) {
	t.Helper()

	client := &http.Client{Timeout: setupVIPAdminTimeout}
	resp, err := client.Post(fmt.Sprintf("%s%s", adminURLForHost(adminHost), path), "", nil)
	if err != nil {
		t.Fatalf("POST %s via admin host %s failed: %v", path, adminHost, err)
	}
	defer resp.Body.Close()

	expectedStatus := http.StatusNoContent
	if path == "/device/reload/vip" {
		expectedStatus = http.StatusAccepted
	}
	if resp.StatusCode != expectedStatus {
		t.Fatalf("expected %d from admin POST %s via %s, got %d", expectedStatus, path, adminHost, resp.StatusCode)
	}
}

func setupVIPPollClient() *http.Client {
	return &http.Client{Timeout: setupVIPPollTimeout}
}

func waitForVIPOperationComplete(t *testing.T, statusHost string, operationID string) {
	t.Helper()

	client := setupVIPPollClient()
	deadline := time.Now().Add(setupVIPTimeout)
	var lastPhase string
	var lastMessage string
	statusURL := vipURLForHost(statusHost)
	t.Logf("Waiting for VIP operation %s via %s to complete", operationID, statusURL)
	for time.Now().Before(deadline) {
		resp, err := client.Get(fmt.Sprintf("%s/devices/vip/operations/%s", statusURL, url.PathEscape(operationID)))
		if err != nil {
			lastMessage = err.Error()
			time.Sleep(1 * time.Second)
			continue
		}

		var payload vipOperationResponse
		decodeErr := json.NewDecoder(resp.Body).Decode(&payload)
		resp.Body.Close()
		if decodeErr != nil {
			lastMessage = decodeErr.Error()
			time.Sleep(1 * time.Second)
			continue
		}

		lastPhase = payload.Phase
		lastMessage = payload.Message
		switch payload.Phase {
		case "complete":
			t.Logf("VIP operation %s completed", operationID)
			return
		case "failed":
			t.Fatalf("VIP operation %s failed: %s", operationID, payload.Message)
		default:
			t.Logf("VIP operation %s still in phase %s: %s", operationID, payload.Phase, payload.Message)
			time.Sleep(1 * time.Second)
		}
	}

	t.Fatalf("VIP operation %s did not complete within %v (last phase=%s message=%s)", operationID, setupVIPTimeout, lastPhase, lastMessage)
}

func waitForVIPState(t *testing.T, vipHost string) map[string]string {
	t.Helper()

	client := setupVIPPollClient()
	deadline := time.Now().Add(setupVIPTimeout)
	var lastErr error
	t.Logf("Waiting for VIP %s to become reachable", vipHost)
	for time.Now().Before(deadline) {
		getResp, err := client.Get(fmt.Sprintf("%s/devices/vip", vipURLForHost(vipHost)))
		if err == nil {
			var payload map[string]string
			decodeErr := json.NewDecoder(getResp.Body).Decode(&payload)
			getResp.Body.Close()
			if decodeErr == nil && getResp.StatusCode == http.StatusOK && payload["vip"] == vipHost && payload["local"] != "" {
				t.Logf("VIP %s is reachable via %s and owned by %s", vipHost, vipURLForHost(vipHost), payload["local"])
				return payload
			}

			if decodeErr != nil {
				lastErr = fmt.Errorf("decode response: %w", decodeErr)
			} else {
				lastErr = fmt.Errorf("status=%d payload=%v", getResp.StatusCode, payload)
			}
		} else {
			lastErr = err
		}

		time.Sleep(1 * time.Second)
	}

	t.Fatalf("VIP %s did not become reachable within %v: %v", vipHost, setupVIPTimeout, lastErr)
	return nil
}

func waitForOldVIPRetirement(t *testing.T, oldVIP string) {
	t.Helper()

	client := setupVIPPollClient()
	deadline := time.Now().Add(setupVIPTimeout)
	t.Logf("Waiting for old VIP %s to stop reporting itself", oldVIP)
	for time.Now().Before(deadline) {
		resp, err := client.Get(fmt.Sprintf("%s/devices/vip", vipURLForHost(oldVIP)))
		if err != nil {
			t.Logf("Old VIP %s is no longer reachable: %v", oldVIP, err)
			return
		}

		var payload map[string]string
		decodeErr := json.NewDecoder(resp.Body).Decode(&payload)
		resp.Body.Close()
		if decodeErr != nil || resp.StatusCode != http.StatusOK || payload["vip"] != oldVIP {
			t.Logf("Old VIP %s stopped reporting itself", oldVIP)
			return
		}

		t.Logf("Old VIP %s is still active; retrying", oldVIP)
		time.Sleep(1 * time.Second)
	}

	t.Fatalf("old VIP %s continued to report itself after %v", oldVIP, setupVIPTimeout)
}

func waitForExclusiveVIPState(t *testing.T, activeVIP string, candidateVIPs []string) {
	t.Helper()

	client := setupVIPPollClient()
	deadline := time.Now().Add(setupVIPTimeout)
	t.Logf("Waiting for VIP %s to become the only active candidate among %v", activeVIP, candidateVIPs)
	for time.Now().Before(deadline) {
		activeReachable := false
		stillActive := make([]string, 0, len(candidateVIPs))

		for _, vip := range candidateVIPs {
			resp, err := client.Get(fmt.Sprintf("%s/devices/vip", vipURLForHost(vip)))
			if err != nil {
				continue
			}

			var payload map[string]string
			decodeErr := json.NewDecoder(resp.Body).Decode(&payload)
			resp.Body.Close()
			if decodeErr != nil || resp.StatusCode != http.StatusOK || payload["vip"] != vip {
				continue
			}

			stillActive = append(stillActive, vip)
			if vip == activeVIP {
				activeReachable = true
			}
		}

		if activeReachable && len(stillActive) == 1 && stillActive[0] == activeVIP {
			t.Logf("VIP %s is the only active candidate", activeVIP)
			return
		}

		t.Logf("VIP exclusivity not reached yet; active=%s reachable=%t stillActive=%v", activeVIP, activeReachable, stillActive)
		time.Sleep(1 * time.Second)
	}

	t.Fatalf("VIP %s did not become the exclusive active candidate within %v", activeVIP, setupVIPTimeout)
}

func resolveFusionMDNSIPsViaNode(resolverHost string, serviceName string) ([]string, error) {
	client := &http.Client{Timeout: 6 * time.Second}
	resp, err := client.Get(fmt.Sprintf("%s/device/discovery/mdns/%s", adminURLForHost(resolverHost), url.PathEscape(serviceName)))
	if err != nil {
		return nil, fmt.Errorf("node-local mDNS lookup failed via %s for %s: %w", resolverHost, serviceName, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("node-local mDNS lookup failed via %s for %s: status=%d", resolverHost, serviceName, resp.StatusCode)
	}

	var payload struct {
		IPs []string `json:"ips"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&payload); err != nil {
		return nil, fmt.Errorf("decode node-local mDNS lookup via %s for %s: %w", resolverHost, serviceName, err)
	}
	if len(payload.IPs) == 0 {
		return nil, fmt.Errorf("node-local mDNS lookup via %s for %s returned no IPs", resolverHost, serviceName)
	}
	return payload.IPs, nil
}

func choosePeerResolverHost(t *testing.T, nodeURLs []string, ownerHost string) string {
	t.Helper()

	for _, nodeURL := range nodeURLs {
		parsed, err := url.Parse(nodeURL)
		if err != nil {
			t.Fatalf("failed to parse node URL %q: %v", nodeURL, err)
		}
		if parsed.Hostname() != "" && parsed.Hostname() != ownerHost {
			return parsed.Hostname()
		}
	}

	return ownerHost
}

func waitForMDNSVIP(t *testing.T, resolverHost string, serviceName string, vipHost string) {
	t.Helper()

	deadline := time.Now().Add(setupVIPTimeout)
	var lastSeen []string
	var lastErr error
	t.Logf("Waiting for mDNS service %s to advertise VIP %s via resolver %s", serviceName, vipHost, resolverHost)
	for time.Now().Before(deadline) {
		resolved, err := resolveFusionMDNSIPsViaNode(resolverHost, serviceName)
		if err == nil {
			lastSeen = resolved
			lastErr = nil
			if slices.Contains(lastSeen, vipHost) {
				t.Logf("mDNS service %s now advertises VIP %s via %s (addresses=%v)", serviceName, vipHost, resolverHost, lastSeen)
				return
			}
			t.Logf("mDNS service %s via %s still advertises %v; waiting for %s", serviceName, resolverHost, lastSeen, vipHost)
		} else {
			lastErr = err
			t.Logf("mDNS service %s not yet resolvable via %s; waiting for %s: %v", serviceName, resolverHost, vipHost, err)
		}
		time.Sleep(1 * time.Second)
	}

	if lastErr != nil {
		t.Fatalf("mDNS for %s via %s did not converge to %s within %v: %v", serviceName, resolverHost, vipHost, setupVIPTimeout, lastErr)
	}
	t.Fatalf("mDNS for %s via %s did not converge to %s within %v, last seen %v", serviceName, resolverHost, vipHost, setupVIPTimeout, lastSeen)
}

func ensureVIPBaseline(t *testing.T, nodeURLs []string, originalVIP string, nodeNamesByIP map[string]string, candidateVIPs []string) {
	t.Helper()

	t.Logf("Ensuring baseline VIP %s across cluster before transitions", originalVIP)
	for _, nodeURL := range nodeURLs {
		adminHost := hostFromNodeURL(t, nodeURL)
		postAdminNoBody(t, adminHost, fmt.Sprintf("/devices/vip/%s", url.PathEscape(originalVIP)))
	}
	for _, nodeURL := range nodeURLs {
		adminHost := hostFromNodeURL(t, nodeURL)
		postAdminNoBody(t, adminHost, "/device/reload/vip")
	}

	payload := waitForVIPState(t, originalVIP)
	waitForExclusiveVIPState(t, originalVIP, candidateVIPs)

	serviceName, ok := nodeNamesByIP[payload["local"]]
	if !ok {
		t.Fatalf("could not map baseline VIP holder IP %s to a node name", payload["local"])
	}
	waitForMDNSVIP(t, choosePeerResolverHost(t, nodeURLs, payload["local"]), serviceName, originalVIP)
}

func runVIPTransitionSequence(t *testing.T, nodeURLs []string, originalVIP string, nodeNamesByIP map[string]string, targets []string) {
	t.Helper()

	if len(nodeURLs) == 0 {
		t.Fatal("no node URLs configured")
	}
	if slices.Contains(targets, originalVIP) {
		t.Fatalf("target list unexpectedly contains original VIP %s", originalVIP)
	}

	currentVIP := originalVIP
	allCandidateVIPs := make([]string, 0, len(targets)+1)
	allCandidateVIPs = append(allCandidateVIPs, originalVIP)
	for _, vip := range targets {
		if !slices.Contains(allCandidateVIPs, vip) {
			allCandidateVIPs = append(allCandidateVIPs, vip)
		}
	}

	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, allCandidateVIPs)

	t.Cleanup(func() {
		restoreNodeURL := vipURLForHost(currentVIP)
		t.Logf("Restoring VIP %s via %s", originalVIP, restoreNodeURL)
		operation, _ := setVIPRequest(t, restoreNodeURL, originalVIP)
		waitForVIPOperationComplete(t, operation.StatusHost, operation.ID)
		payload := waitForVIPState(t, originalVIP)
		waitForExclusiveVIPState(t, originalVIP, allCandidateVIPs)
		serviceName, ok := nodeNamesByIP[payload["local"]]
		if !ok {
			t.Fatalf("could not map restored VIP holder IP %s to a node name", payload["local"])
		}
		waitForMDNSVIP(t, choosePeerResolverHost(t, nodeURLs, payload["local"]), serviceName, originalVIP)
	})

	for _, targetVIP := range targets {
		nodeURL := vipURLForHost(currentVIP)
		t.Logf("Requesting VIP transition from %s to %s via %s", currentVIP, targetVIP, nodeURL)
		operation, duration := setVIPRequest(t, nodeURL, targetVIP)
		if duration >= setupVIPRequestTimeout {
			t.Fatalf("VIP setup request for %s took too long: %v", targetVIP, duration)
		}
		t.Logf("VIP transition request for %s returned in %v", targetVIP, duration)
		waitForVIPOperationComplete(t, operation.StatusHost, operation.ID)

		payload := waitForVIPState(t, targetVIP)
		waitForOldVIPRetirement(t, currentVIP)

		serviceName, ok := nodeNamesByIP[payload["local"]]
		if !ok {
			t.Fatalf("could not map VIP holder IP %s to a node name", payload["local"])
		}
		waitForMDNSVIP(t, choosePeerResolverHost(t, nodeURLs, payload["local"]), serviceName, targetVIP)

		currentVIP = targetVIP
	}
}

func TestSetupVIPTransitionsTwice(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	alternates := candidateVIPs(t, originalVIP)

	targets := []string{alternates[0], alternates[1]}
	runVIPTransitionSequence(t, nodeURLs, originalVIP, nodeNamesByIP, targets)
}

func TestSetupVIPStressTransitions(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	alternates := candidateVIPs(t, originalVIP)

	targets := make([]string, 0, setupVIPStressCycles*len(alternates))
	for cycle := 0; cycle < setupVIPStressCycles; cycle++ {
		for _, vip := range alternates {
			targets = append(targets, vip)
		}
	}

	runVIPTransitionSequence(t, nodeURLs, originalVIP, nodeNamesByIP, targets)
}
