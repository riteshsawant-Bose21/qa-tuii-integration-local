package main

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

const (
	bootstrapVIPTimeout     = 60 * time.Second
	bootstrapResetTimeout   = 4 * time.Minute
	bootstrapPollInterval   = 2 * time.Second
	bootstrapSettleDelay    = 5 * time.Second
	bootstrapTargetVIP      = "192.168.2.100"
	bootstrapScriptsRelPath = "../../scripts/multipass"
	bootstrapResetScript    = "reset-vip.sh"
)

// resolveBootstrapScript locates the reset-vip.sh script relative to this file.
func resolveBootstrapScript() string {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		return filepath.Join(bootstrapScriptsRelPath, bootstrapResetScript)
	}
	return filepath.Join(filepath.Dir(thisFile), bootstrapScriptsRelPath, bootstrapResetScript)
}

// resetAllVIPs runs the reset-vip.sh script to set all nodes to VIP_NOT_SET/24.
func resetAllVIPs(t *testing.T) {
	t.Helper()

	script := resolveBootstrapScript()
	ctx, cancel := context.WithTimeout(context.Background(), bootstrapResetTimeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "/bin/bash", script)
	cmd.Stdin = strings.NewReader("y\n")
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("reset-vip.sh failed: %v\noutput:\n%s", err, string(out))
	}
	t.Logf("reset-vip.sh completed:\n%s", string(out))
}

// findReachableNodeURL returns a direct node URL (not VIP) that is responding.
func findReachableNodeURL(t *testing.T) string {
	t.Helper()

	client := &http.Client{Timeout: 3 * time.Second}
	for _, node := range clusterConfig.nodes {
		host := hostFromNodeURL(t, node.address)
		checkURL := fmt.Sprintf("http://%s:8080/health", host)
		resp, err := client.Get(checkURL)
		if err == nil {
			resp.Body.Close()
			if resp.StatusCode == http.StatusOK {
				t.Logf("Node %s (%s) is reachable", node.name, host)
				return fmt.Sprintf("http://%s:8080", host)
			}
		}
	}

	t.Fatal("no reachable node found after VIP reset")
	return ""
}

// waitForVIPUnreachable waits until the VIP is no longer serving /devices/vip.
func waitForVIPUnreachable(t *testing.T, vipHost string) {
	t.Helper()

	client := &http.Client{Timeout: 3 * time.Second}
	deadline := time.Now().Add(bootstrapVIPTimeout)
	t.Logf("Waiting for VIP %s to become unreachable after reset", vipHost)
	for time.Now().Before(deadline) {
		resp, err := client.Get(fmt.Sprintf("http://%s:8080/devices/vip", vipHost))
		if err != nil {
			t.Logf("VIP %s is unreachable (expected): %v", vipHost, err)
			return
		}
		resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			t.Logf("VIP %s returned status %d (not serving VIP)", vipHost, resp.StatusCode)
			return
		}
		time.Sleep(1 * time.Second)
	}

	t.Fatalf("VIP %s still reachable after reset within %v", vipHost, bootstrapVIPTimeout)
}

// verifyVIPStatusOnNode checks that a specific node reports the expected VIP
// via its admin endpoint.
func verifyVIPStatusOnNode(t *testing.T, nodeHost string, expectedVIP string) {
	t.Helper()

	client := &http.Client{Timeout: 3 * time.Second}
	deadline := time.Now().Add(bootstrapVIPTimeout)
	t.Logf("Waiting for node %s to report configured VIP %s", nodeHost, expectedVIP)
	for time.Now().Before(deadline) {
		resp, err := client.Get(fmt.Sprintf("http://%s:9090/devices/vip/status", nodeHost))
		if err != nil {
			time.Sleep(bootstrapPollInterval)
			continue
		}

		var status vipStatusResponse
		decErr := json.NewDecoder(resp.Body).Decode(&status)
		resp.Body.Close()
		if decErr != nil {
			time.Sleep(bootstrapPollInterval)
			continue
		}

		if status.ObservedVIP == expectedVIP {
			t.Logf("Node %s reports observed VIP %s (phase=%s)", nodeHost, expectedVIP, status.Phase)
			return
		}
		t.Logf("Node %s reports observed VIP %q (want %s), retrying", nodeHost, status.ObservedVIP, expectedVIP)
		time.Sleep(bootstrapPollInterval)
	}

	t.Fatalf("Node %s did not report VIP %s within %v", nodeHost, expectedVIP, bootstrapVIPTimeout)
}

// verifyAllNodesHaveVIPConfig checks that every node's keepalived config
// contains the expected VIP (not a placeholder).
func verifyAllNodesHaveVIPConfig(t *testing.T, expectedVIP string) {
	t.Helper()

	for _, node := range clusterConfig.nodes {
		output, err := runMultipassCommandOnInstance(t, node.name,
			fmt.Sprintf("grep -E '%s' /etc/keepalived/keepalived.conf", expectedVIP))
		if err != nil {
			t.Errorf("Node %s: keepalived.conf does not contain VIP %s: %v\noutput: %s",
				node.name, expectedVIP, err, output)
		} else {
			t.Logf("Node %s: keepalived.conf contains VIP %s", node.name, expectedVIP)
		}
	}
}

// TestBootstrapVIPFromReset validates the full bootstrap flow:
//
//  1. Reset all nodes to VIP_NOT_SET/24 (simulating a fresh/factory-reset cluster)
//  2. Set VIP to 192.168.2.100 via a direct node URL
//  3. Verify the VIP is reachable and all nodes converge
//
// This test captures the issue where:
//   - VIP_NOT_SET/24 caused VIPMonitor.Start() to fail
//   - Set VIP fan-out only reached the local node (memberlist was empty)
//   - Other nodes kept stale placeholder config and never converged
func TestBootstrapVIPFromReset(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	allCandidateVIPs := append([]string{originalVIP}, candidateVIPs(t, originalVIP)...)

	// ── Phase 1: Reset all VIPs to placeholder ──────────────────────────
	t.Log("Phase 1: Resetting all nodes to VIP_NOT_SET/24")
	resetAllVIPs(t)
	t.Logf("Waiting %v for services to settle after reset", bootstrapSettleDelay)
	// Give services time to restart and stabilize with no VIP
	time.Sleep(bootstrapSettleDelay)
	// Verify the old VIP is no longer served
	waitForVIPUnreachable(t, originalVIP)

	// ── Phase 2: Set VIP via direct node address ────────────────────────
	// Find a reachable node by its direct IP (not VIP, since VIP is gone)
	nodeURL := findReachableNodeURL(t)
	t.Logf("Phase 2: Setting VIP %s via direct node %s", bootstrapTargetVIP, nodeURL)
	operation, duration := setVIPRequest(t, nodeURL, bootstrapTargetVIP)
	t.Logf("Set VIP request returned in %v (operation=%s, statusHost=%s)", duration, operation.ID, operation.StatusHost)

	// ── Phase 3: Wait for operation to complete ─────────────────────────
	t.Log("Phase 3: Waiting for VIP operation to complete")
	waitForVIPOperationComplete(t, operation.StatusHost, operation.ID)

	// ── Phase 4: Verify VIP is live and serving ─────────────────────────
	t.Log("Phase 4: Verifying VIP is reachable")
	payload := waitForVIPState(t, bootstrapTargetVIP)
	t.Logf("VIP %s is live, held by %s", bootstrapTargetVIP, payload["local"])

	// ── Phase 5: Verify all nodes converged ─────────────────────────────
	t.Log("Phase 5: Verifying all nodes have correct VIP config")
	for _, node := range clusterConfig.nodes {
		host := hostFromNodeURL(t, node.address)
		verifyVIPStatusOnNode(t, host, bootstrapTargetVIP)
	}
	// Verify on-disk keepalived config on all nodes
	verifyAllNodesHaveVIPConfig(t, bootstrapTargetVIP)

	// ── Phase 6: Verify mDNS advertisement ──────────────────────────────
	t.Log("Phase 6: Verifying mDNS advertisement")
	serviceName, ok := nodeNamesByIP[payload["local"]]
	if !ok {
		t.Fatalf("Could not map VIP holder IP %s to a node name", payload["local"])
	}
	resolverHost := choosePeerResolverHost(t, nodeURLs, payload["local"])
	waitForMDNSVIP(t, resolverHost, serviceName, bootstrapTargetVIP)

	// ── Phase 7: Verify exclusive VIP ownership ─────────────────────────
	t.Log("Phase 7: Verifying exclusive VIP ownership")
	waitForExclusiveVIPState(t, bootstrapTargetVIP, allCandidateVIPs)

	t.Log("Bootstrap VIP test passed: all nodes converged from VIP_NOT_SET to configured VIP")
}

// TestBootstrapVIPThenTransition validates that after bootstrapping from a
// reset state, normal VIP transitions continue to work correctly.
func TestBootstrapVIPThenTransition(t *testing.T) {
	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	alternates := candidateVIPs(t, originalVIP)
	allCandidateVIPs := append([]string{originalVIP}, alternates...)

	// ── Phase 1: Reset and bootstrap ────────────────────────────────────
	t.Log("Phase 1: Resetting all nodes to VIP_NOT_SET/24")
	resetAllVIPs(t)
	time.Sleep(bootstrapSettleDelay)
	waitForVIPUnreachable(t, originalVIP)

	nodeURL := findReachableNodeURL(t)
	t.Logf("Setting VIP %s via %s", bootstrapTargetVIP, nodeURL)
	operation, _ := setVIPRequest(t, nodeURL, bootstrapTargetVIP)
	waitForVIPOperationComplete(t, operation.StatusHost, operation.ID)
	waitForVIPState(t, bootstrapTargetVIP)

	// Verify all nodes converged before transitioning
	for _, node := range clusterConfig.nodes {
		host := hostFromNodeURL(t, node.address)
		verifyVIPStatusOnNode(t, host, bootstrapTargetVIP)
	}
	verifyAllNodesHaveVIPConfig(t, bootstrapTargetVIP)

	// ── Phase 2: Transition to alternate VIP ────────────────────────────
	targetVIP := alternates[0]
	t.Logf("Phase 2: Transitioning VIP from %s to %s", bootstrapTargetVIP, targetVIP)
	transitionOp, _ := setVIPRequest(t, vipURLForHost(bootstrapTargetVIP), targetVIP)
	waitForVIPOperationComplete(t, transitionOp.StatusHost, transitionOp.ID)
	payload := waitForVIPState(t, targetVIP)
	waitForOldVIPRetirement(t, bootstrapTargetVIP)
	serviceName, ok := nodeNamesByIP[payload["local"]]
	if !ok {
		t.Fatalf("Could not map VIP holder IP %s to a node name", payload["local"])
	}
	waitForMDNSVIP(t, choosePeerResolverHost(t, nodeURLs, payload["local"]), serviceName, targetVIP)

	// ── Phase 3: Restore original VIP ───────────────────────────────────
	t.Logf("Phase 3: Restoring VIP to %s", originalVIP)
	restoreOp, _ := setVIPRequest(t, vipURLForHost(targetVIP), originalVIP)
	waitForVIPOperationComplete(t, restoreOp.StatusHost, restoreOp.ID)
	waitForVIPState(t, originalVIP)
	waitForExclusiveVIPState(t, originalVIP, allCandidateVIPs)
	payload2 := waitForVIPState(t, originalVIP)
	serviceName2, ok := nodeNamesByIP[payload2["local"]]
	if !ok {
		t.Fatalf("Could not map VIP holder IP %s to a node name", payload2["local"])
	}
	waitForMDNSVIP(t, choosePeerResolverHost(t, nodeURLs, payload2["local"]), serviceName2, originalVIP)

	t.Log("Bootstrap + transition test passed")
}

// TestBootstrapVIPNodeConvergenceViaSelfHeal verifies the VRRP self-heal path:
// when one node has a real VIP but others still have VIP_NOT_SET, the other
// nodes should self-heal by fetching config from the configured peer via VRRP.
func TestBootstrapVIPNodeConvergenceViaSelfHeal(t *testing.T) {
	_, _, _ = setupVIPTarget(t)

	// ── Phase 1: Reset all VIPs ─────────────────────────────────────────
	t.Log("Phase 1: Resetting all nodes to VIP_NOT_SET/24")
	resetAllVIPs(t)
	time.Sleep(bootstrapSettleDelay)

	// ── Phase 2: Manually write VIP config on only ONE node ─────────────
	// This simulates the case where Set VIP fan-out only reached one node.
	firstNode := clusterConfig.nodes[0]
	firstHost := hostFromNodeURL(t, firstNode.address)
	t.Logf("Phase 2: Writing VIP %s to only node %s (%s) via admin endpoint", bootstrapTargetVIP, firstNode.name, firstHost)
	client := &http.Client{Timeout: setupVIPAdminTimeout}
	writeURL := fmt.Sprintf("http://%s:9090/devices/vip/%s", firstHost, url.PathEscape(bootstrapTargetVIP))
	resp, err := client.Post(writeURL, "", nil)
	if err != nil {
		t.Fatalf("Failed to write VIP config to %s: %v", firstHost, err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("Expected 204 from admin VIP write on %s, got %d", firstHost, resp.StatusCode)
	}

	// Trigger reload on that single node
	reloadURL := fmt.Sprintf("http://%s:9090/device/reload/vip", firstHost)
	resp, err = client.Post(reloadURL, "", nil)
	if err != nil {
		t.Fatalf("Failed to reload VIP on %s: %v", firstHost, err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusAccepted {
		t.Fatalf("Expected 202 from admin VIP reload on %s, got %d", firstHost, resp.StatusCode)
	}
	// Wait for reload to complete on that node
	waitForVIPReloadComplete(t, firstHost)
	t.Logf("Node %s now has VIP %s configured and reloaded", firstNode.name, bootstrapTargetVIP)

	// ── Phase 3: Wait for other nodes to self-heal via VRRP ─────────────
	t.Log("Phase 3: Waiting for remaining nodes to self-heal via VRRP advertisements")
	for _, node := range clusterConfig.nodes[1:] {
		host := hostFromNodeURL(t, node.address)
		t.Logf("Waiting for node %s (%s) to self-heal VIP config", node.name, host)
		verifyVIPStatusOnNode(t, host, bootstrapTargetVIP)
	}

	// ── Phase 4: Verify on-disk convergence ─────────────────────────────
	t.Log("Phase 4: Verifying all nodes have correct on-disk keepalived config")
	verifyAllNodesHaveVIPConfig(t, bootstrapTargetVIP)

	// ── Phase 5: Verify VIP is live ─────────────────────────────────────
	t.Log("Phase 5: Verifying VIP is live and reachable")
	waitForVIPState(t, bootstrapTargetVIP)

	t.Log("Self-heal convergence test passed: all nodes converged from single-node config via VRRP")
}
