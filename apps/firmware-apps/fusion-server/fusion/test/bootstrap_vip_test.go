package main

import (
	"context"
	"fmt"
	model "fusion/internal/gen/proto/fusion"
	"net/http"
	"net/url"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"
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

		var status model.VIPOperationStatus
		decErr := decodeProtoBody(resp.Body, &status)
		resp.Body.Close()
		if decErr != nil {
			time.Sleep(bootstrapPollInterval)
			continue
		}

		if status.GetObservedVip() == expectedVIP {
			t.Logf("Node %s reports observed VIP %s (phase=%s)", nodeHost, expectedVIP, status.GetPhase())
			return
		}
		t.Logf("Node %s reports observed VIP %q (want %s), retrying", nodeHost, status.GetObservedVip(), expectedVIP)
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
			fmt.Sprintf("grep -F '%s' /etc/keepalived/keepalived.conf", expectedVIP))
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
	t.Logf("Set VIP request returned in %v (operation=%s, statusHost=%s)", duration, operation.GetId(), operation.GetStatusHost())

	// ── Phase 3: Wait for operation to complete ─────────────────────────
	t.Log("Phase 3: Waiting for VIP operation to complete")
	waitForVIPOperationComplete(t, operation.GetStatusHost(), operation.GetId())

	// ── Phase 4: Verify VIP is live and serving ─────────────────────────
	t.Log("Phase 4: Verifying VIP is reachable")
	payload := waitForVIPState(t, bootstrapTargetVIP)
	t.Logf("VIP %s is live, held by %s", bootstrapTargetVIP, payload.GetLocal())

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
	serviceName, ok := nodeNamesByIP[payload.GetLocal()]
	if !ok {
		t.Fatalf("Could not map VIP holder IP %s to a node name", payload.GetLocal())
	}
	resolverHost := choosePeerResolverHost(t, nodeURLs, payload.GetLocal())
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
	waitForVIPOperationComplete(t, operation.GetStatusHost(), operation.GetId())
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
	waitForVIPOperationComplete(t, transitionOp.GetStatusHost(), transitionOp.GetId())
	payload := waitForVIPState(t, targetVIP)
	waitForOldVIPRetirement(t, bootstrapTargetVIP)
	serviceName, ok := nodeNamesByIP[payload.GetLocal()]
	if !ok {
		t.Fatalf("Could not map VIP holder IP %s to a node name", payload.GetLocal())
	}
	waitForMDNSVIP(t, choosePeerResolverHost(t, nodeURLs, payload.GetLocal()), serviceName, targetVIP)

	// ── Phase 3: Restore original VIP ───────────────────────────────────
	t.Logf("Phase 3: Restoring VIP to %s", originalVIP)
	restoreOp, _ := setVIPRequest(t, vipURLForHost(targetVIP), originalVIP)
	waitForVIPOperationComplete(t, restoreOp.GetStatusHost(), restoreOp.GetId())
	waitForVIPState(t, originalVIP)
	waitForExclusiveVIPState(t, originalVIP, allCandidateVIPs)
	payload2 := waitForVIPState(t, originalVIP)
	serviceName2, ok := nodeNamesByIP[payload2.GetLocal()]
	if !ok {
		t.Fatalf("Could not map VIP holder IP %s to a node name", payload2.GetLocal())
	}
	waitForMDNSVIP(t, choosePeerResolverHost(t, nodeURLs, payload2.GetLocal()), serviceName2, originalVIP)

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

// TestStaleVIPSelfHealAfterOfflineVIPChange verifies the split-brain fix for
// the following real-world scenario:
//
//  1. Cluster has nodes x (leader/VIP holder), y, z.
//  2. y and z are stopped (simulating them being offline).
//  3. VIP is changed on x via Set VIP — fan-out only reaches x since y/z are down.
//  4. y and z are restarted with their stale on-disk VIP config.
//  5. Expected: y and z detect the mismatch via VRRP and self-heal by syncing
//     config from x, then all three nodes converge to the new VIP.
func TestStaleVIPSelfHealAfterOfflineVIPChange(t *testing.T) {
	if len(clusterConfig.nodes) < 3 {
		t.Skipf("test requires at least 3 nodes, got %d", len(clusterConfig.nodes))
	}

	_, originalVIP, _ := setupVIPTarget(t)
	allCandidateVIPs := append([]string{originalVIP}, candidateVIPs(t, originalVIP)...)

	// Restore original VIP at end of test regardless of outcome.
	t.Cleanup(func() {
		t.Log("Cleanup: restoring original VIP")
		client := &http.Client{Timeout: setupVIPAdminTimeout}
		firstHost := hostFromNodeURL(t, clusterConfig.nodes[0].address)
		writeURL := fmt.Sprintf("http://%s:9090/devices/vip/%s", firstHost, url.PathEscape(originalVIP))
		if resp, err := client.Post(writeURL, "", nil); err == nil {
			resp.Body.Close()
		}
		reloadURL := fmt.Sprintf("http://%s:9090/device/reload/vip", firstHost)
		if resp, err := client.Post(reloadURL, "", nil); err == nil {
			resp.Body.Close()
		}
	})

	leaderNode := clusterConfig.nodes[0]
	offlineNodes := clusterConfig.nodes[1:]
	leaderHost := hostFromNodeURL(t, leaderNode.address)

	// ── Phase 1: Stop y and z ────────────────────────────────────────────
	t.Logf("Phase 1: Stopping %d offline node(s)", len(offlineNodes))
	for _, node := range offlineNodes {
		t.Logf("Stopping fusion-server on node %s", node.name)
		if _, err := runMultipassCommandOnInstance(t, node.name, "sudo systemctl stop fusion-server"); err != nil {
			t.Fatalf("Failed to stop fusion-server on node %s: %v", node.name, err)
		}
	}
	// Give memberlist time to mark them as dead on x.
	time.Sleep(bootstrapSettleDelay)

	// ── Phase 2: Change VIP on x while y and z are offline ───────────────
	newVIP := candidateVIPs(t, originalVIP)[0]
	t.Logf("Phase 2: Changing VIP from %s to %s on leader %s (%s)", originalVIP, newVIP, leaderNode.name, leaderHost)
	client := &http.Client{Timeout: setupVIPAdminTimeout}
	writeURL := fmt.Sprintf("http://%s:9090/devices/vip/%s", leaderHost, url.PathEscape(newVIP))
	resp, err := client.Post(writeURL, "", nil)
	if err != nil {
		t.Fatalf("Failed to write new VIP to leader %s: %v", leaderHost, err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("Expected 204 from admin VIP write on %s, got %d", leaderHost, resp.StatusCode)
	}

	reloadURL := fmt.Sprintf("http://%s:9090/device/reload/vip", leaderHost)
	resp, err = client.Post(reloadURL, "", nil)
	if err != nil {
		t.Fatalf("Failed to reload VIP on leader %s: %v", leaderHost, err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusAccepted {
		t.Fatalf("Expected 202 from admin VIP reload on %s, got %d", leaderHost, resp.StatusCode)
	}
	waitForVIPReloadComplete(t, leaderHost)
	t.Logf("Leader %s now has new VIP %s configured", leaderNode.name, newVIP)

	// ── Phase 3: Bring y and z back online ───────────────────────────────
	t.Logf("Phase 3: Restarting %d offline node(s) with stale VIP config", len(offlineNodes))
	for _, node := range offlineNodes {
		t.Logf("Starting fusion-server on node %s (stale VIP %s on disk)", node.name, originalVIP)
		if _, err := runMultipassCommandOnInstance(t, node.name, "sudo systemctl start fusion-server"); err != nil {
			t.Fatalf("Failed to start fusion-server on node %s: %v", node.name, err)
		}
	}
	time.Sleep(bootstrapSettleDelay)

	// ── Phase 4: Wait for y and z to self-heal to the new VIP ────────────
	t.Logf("Phase 4: Waiting for offline nodes to self-heal stale VIP %s → new VIP %s", originalVIP, newVIP)
	for _, node := range offlineNodes {
		host := hostFromNodeURL(t, node.address)
		t.Logf("Waiting for node %s (%s) to self-heal to VIP %s", node.name, host, newVIP)
		verifyVIPStatusOnNode(t, host, newVIP)
	}

	// ── Phase 5: Verify on-disk keepalived config on all nodes ───────────
	t.Log("Phase 5: Verifying all nodes have correct on-disk keepalived config")
	verifyAllNodesHaveVIPConfig(t, newVIP)

	// ── Phase 6: Verify the cluster reunifies under the new VIP ──────────
	t.Log("Phase 6: Verifying all nodes are in a single cluster under new VIP")
	waitForVIPState(t, newVIP)
	waitForExclusiveVIPState(t, newVIP, allCandidateVIPs)

	t.Logf("Stale-VIP self-heal test passed: all %d nodes converged to new VIP %s after offline VIP change", len(clusterConfig.nodes), newVIP)
}
