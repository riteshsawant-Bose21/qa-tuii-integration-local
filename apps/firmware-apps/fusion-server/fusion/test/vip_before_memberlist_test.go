package main

import (
	"fmt"
	model "fusion/internal/gen/proto/fusion"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

const (
	memberlistIsolationChain = "FUSION_TEST_MEMBERLIST_BLOCK"
	memberlistIsolationTable = "fusion_test_memberlist"
	memberlistPort           = "7946"
	memberlistIsolatedDelay  = 8 * time.Second
)

type clusterMemberSnapshot struct {
	Name  string `json:"name"`
	Addr  string `json:"addr"`
	State any    `json:"state"`
}

func TestVIPStartupIsolationSingleNodeBootstrapAllowed(t *testing.T) {
	if len(clusterConfig.nodes) < 3 {
		t.Skipf("test requires at least 3 nodes, got %d", len(clusterConfig.nodes))
	}

	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	clearMemberlistIsolationOnAllNodes(t)
	restartFusionOnAllNodes(t)
	allCandidateVIPs := append([]string{originalVIP}, candidateVIPs(t, originalVIP)...)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, allCandidateVIPs)

	payload := waitForVIPState(t, originalVIP)
	targetHost := payload.GetLocal()
	targetNodeName := nodeNameForHost(t, targetHost)
	peerNodeNames := allOtherNodeNames(targetNodeName)
	targetURL := vipURLForHost(targetHost)

	t.Cleanup(func() {
		for _, peer := range peerNodeNames {
			_, _ = runMultipassCommandOnInstance(t, peer, "sudo systemctl start fusion-server")
		}
		restartFusionOnAllNodes(t)
	})

	for _, peer := range peerNodeNames {
		if _, err := runMultipassCommandOnInstance(t, peer, "sudo systemctl stop fusion-server"); err != nil {
			t.Fatalf("failed to stop fusion-server on peer %s: %v", peer, err)
		}
	}
	time.Sleep(bootstrapSettleDelay)

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, "sudo systemctl restart fusion-server"); err != nil {
		t.Fatalf("failed to restart fusion-server on target %s: %v", targetNodeName, err)
	}

	waitForClusterMembersCount(t, targetURL, 1)
	singleDevices := waitForDeviceCountOnURL(t, targetURL, 1)
	if countPrimaries(singleDevices) != 1 {
		t.Fatalf("expected single-node bootstrap to have exactly one primary, got %d", countPrimaries(singleDevices))
	}

	for _, peer := range peerNodeNames {
		if _, err := runMultipassCommandOnInstance(t, peer, "sudo systemctl start fusion-server"); err != nil {
			t.Fatalf("failed to restart peer %s after bootstrap check: %v", peer, err)
		}
	}
	time.Sleep(bootstrapSettleDelay)

	healedDevices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
	t.Logf("single-node bootstrap recovered to devices=%d ids=%s", len(healedDevices), summarizeDeviceIDs(healedDevices))
}

func TestVIPStartupIsolationLateSeedRecoveryWithoutRestart(t *testing.T) {
	if len(clusterConfig.nodes) < 3 {
		t.Skipf("test requires at least 3 nodes, got %d", len(clusterConfig.nodes))
	}

	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	clearMemberlistIsolationOnAllNodes(t)
	restartFusionOnAllNodes(t)
	allCandidateVIPs := append([]string{originalVIP}, candidateVIPs(t, originalVIP)...)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, allCandidateVIPs)

	devices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
	target := mustPickNonPrimaryDevice(t, devices)
	targetHost := target.Address
	targetNodeName := nodeNameForHost(t, targetHost)
	peerHosts := otherNodeHosts(devices, targetHost)

	t.Cleanup(func() {
		_, _ = runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand())
		restartFusionOnAllNodes(t)
	})

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, applyMemberlistIsolationCommand(peerHosts)); err != nil {
		t.Fatalf("failed to apply memberlist isolation to %s: %v", targetNodeName, err)
	}
	assertMemberlistIsolationActive(t, targetNodeName, peerHosts)

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, "sudo systemctl restart fusion-server"); err != nil {
		t.Fatalf("failed to restart fusion-server on %s: %v", targetNodeName, err)
	}
	time.Sleep(memberlistIsolatedDelay)

	logJoinRetrySignal(t, targetNodeName)

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand()); err != nil {
		t.Fatalf("failed to clear memberlist isolation on %s: %v", targetNodeName, err)
	}
	time.Sleep(2 * time.Second)

	waitForClusterMembersCount(t, vipURLForHost(targetHost), len(clusterConfig.nodes))
	healedDevices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
	t.Logf("late-seed recovery reached devices=%d ids=%s without extra restart", len(healedDevices), summarizeDeviceIDs(healedDevices))
}

func TestVIPStartupIsolationPartialPartitionMaintainsQuorum(t *testing.T) {
	if len(clusterConfig.nodes) < 3 {
		t.Skipf("test requires at least 3 nodes, got %d", len(clusterConfig.nodes))
	}

	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	clearMemberlistIsolationOnAllNodes(t)
	restartFusionOnAllNodes(t)
	allCandidateVIPs := append([]string{originalVIP}, candidateVIPs(t, originalVIP)...)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, allCandidateVIPs)

	devices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
	target := mustPickNonPrimaryDevice(t, devices)
	targetHost := target.Address
	targetNodeName := nodeNameForHost(t, targetHost)
	peerHosts := otherNodeHosts(devices, targetHost)
	if len(peerHosts) < 2 {
		t.Fatalf("expected at least two peers for partial partition target %s, got %v", targetHost, peerHosts)
	}
	blockedPeer := peerHosts[0]

	t.Cleanup(func() {
		_, _ = runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand())
		restartFusionOnAllNodes(t)
	})

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, applyMemberlistIsolationCommand([]string{blockedPeer})); err != nil {
		t.Fatalf("failed to apply partial memberlist isolation to %s: %v", targetNodeName, err)
	}
	assertMemberlistIsolationActive(t, targetNodeName, []string{blockedPeer})

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, "sudo systemctl restart fusion-server"); err != nil {
		t.Fatalf("failed to restart fusion-server on %s: %v", targetNodeName, err)
	}
	time.Sleep(memberlistIsolatedDelay)

	targetMembers := mustGetClusterMembersJSON(t, vipURLForHost(targetHost))
	if len(targetMembers) < 2 {
		t.Fatalf("expected partial partition target %s to maintain visibility of at least one peer, got %d members: %+v", targetHost, len(targetMembers), targetMembers)
	}

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand()); err != nil {
		t.Fatalf("failed to clear partial memberlist isolation on %s: %v", targetNodeName, err)
	}
	time.Sleep(2 * time.Second)

	waitForClusterMembersCount(t, vipURLForHost(targetHost), len(clusterConfig.nodes))
	healedDevices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
	t.Logf("partial partition healed to devices=%d ids=%s", len(healedDevices), summarizeDeviceIDs(healedDevices))
}

// TestVIPStartupIsolationPreventsTakeoverOrHealsCluster verifies the cluster
// behaves safely when one node starts while memberlist connectivity is blocked:
// either the node is prevented from taking VIP authority, or the cluster heals
// back to full membership once connectivity is restored.
func TestVIPStartupIsolationPreventsTakeoverOrHealsCluster(t *testing.T) {
	if len(clusterConfig.nodes) < 3 {
		t.Skipf("test requires at least 3 nodes, got %d", len(clusterConfig.nodes))
	}

	nodeURLs, originalVIP, nodeNamesByIP := setupVIPTarget(t)
	clearMemberlistIsolationOnAllNodes(t)
	restartFusionOnAllNodes(t)
	allCandidateVIPs := append([]string{originalVIP}, candidateVIPs(t, originalVIP)...)
	ensureVIPBaseline(t, nodeURLs, originalVIP, nodeNamesByIP, allCandidateVIPs)

	devices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
	primary := mustFindPrimaryDevice(t, devices)
	target := mustPickNonPrimaryDevice(t, devices)
	targetHost := target.Address
	peerHosts := otherNodeHosts(devices, targetHost)
	if len(peerHosts) < 2 {
		t.Fatalf("expected at least 2 peer hosts for target %s, got %v", targetHost, peerHosts)
	}

	targetNodeName := nodeNameForHost(t, targetHost)
	t.Logf("targeting node %s (%s) for startup memberlist isolation", targetNodeName, targetHost)

	t.Cleanup(func() {
		_, _ = runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand())
		_, _ = runMultipassCommandOnInstance(t, targetNodeName, "sudo systemctl restart fusion-server")
		time.Sleep(bootstrapSettleDelay)

		restoreCtxClient := &http.Client{Timeout: setupVIPAdminTimeout}
		for _, d := range mustGetDevicesFromURLBestEffort(vipURLForHost(originalVIP)) {
			modeValue := "default"
			endpoint := fmt.Sprintf("%s/devices/%s/vip/master-priority/%s", vipURLForHost(originalVIP), url.PathEscape(d.Id), modeValue)
			req, _ := http.NewRequest(http.MethodPost, endpoint, nil)
			if req != nil {
				if resp, err := restoreCtxClient.Do(req); err == nil && resp != nil {
					resp.Body.Close()
				}
			}
		}
	})

	if err := setMasterPriorityByModeHTTP(vipURLForHost(originalVIP), target.Id, "high"); err != nil {
		t.Fatalf("failed to set target %s high priority: %v", target.Id, err)
	}
	if err := setMasterPriorityByModeHTTP(vipURLForHost(originalVIP), primary.Id, "low"); err != nil {
		t.Fatalf("failed to demote primary %s: %v", primary.Id, err)
	}

	if _, err := runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand()); err != nil {
		t.Fatalf("failed to clear pre-existing memberlist isolation on %s: %v", targetNodeName, err)
	}
	if _, err := runMultipassCommandOnInstance(t, targetNodeName, applyMemberlistIsolationCommand(peerHosts)); err != nil {
		t.Fatalf("failed to apply memberlist isolation to %s: %v", targetNodeName, err)
	}
	assertMemberlistIsolationActive(t, targetNodeName, peerHosts)

	t.Logf("restarting fusion-server on target node %s with memberlist blocked from peers %v", targetNodeName, peerHosts)
	if _, err := runMultipassCommandOnInstance(t, targetNodeName, "sudo systemctl restart fusion-server"); err != nil {
		t.Fatalf("failed to restart fusion-server on %s: %v", targetNodeName, err)
	}
	time.Sleep(memberlistIsolatedDelay)

	payload := waitForVIPState(t, originalVIP)
	if payload.GetLocal() != targetHost {
		t.Logf("startup guard prevented isolated target %s from taking VIP %s; current holder=%s", targetHost, originalVIP, payload.GetLocal())
		if _, err := runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand()); err != nil {
			t.Fatalf("failed to clear memberlist isolation on %s after prevention outcome: %v", targetNodeName, err)
		}
		time.Sleep(2 * time.Second)
		healthyDevices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
		t.Logf("prevention outcome: cluster remained healthy with devices=%d ids=%s", len(healthyDevices), summarizeDeviceIDs(healthyDevices))
		holderMembers := waitForClusterMembersCount(t, vipURLForHost(payload.GetLocal()), len(clusterConfig.nodes))
		t.Logf("prevention outcome: VIP holder %s sees %d members", payload.GetLocal(), len(holderMembers))
		return
	}

	vipDevices := mustGetDevicesFromURL(t, vipURLForHost(originalVIP))
	targetMembers := mustGetClusterMembersJSON(t, vipURLForHost(targetHost))
	peerMembersA := mustGetClusterMembersJSON(t, vipURLForHost(peerHosts[0]))
	peerMembersB := mustGetClusterMembersJSON(t, vipURLForHost(peerHosts[1]))

	t.Logf("VIP devices=%d target members=%d peerA members=%d peerB members=%d",
		len(vipDevices), len(targetMembers), len(peerMembersA), len(peerMembersB))

	if len(targetMembers) != 1 {
		t.Fatalf("expected isolated target %s to see only itself in memberlist, got %d members: %+v", targetHost, len(targetMembers), targetMembers)
	}
	if len(peerMembersA) < 2 || len(peerMembersB) < 2 {
		t.Fatalf("expected peer nodes to retain at least 2 members, got peerA=%d peerB=%d", len(peerMembersA), len(peerMembersB))
	}
	if len(vipDevices) >= len(devices) {
		t.Fatalf("expected VIP /devices to lose visibility after takeover, baseline=%d current=%d", len(devices), len(vipDevices))
	}

	journal, err := runMultipassCommandOnInstance(t, targetNodeName, "sudo journalctl -u fusion-server --since '-5 min' --no-pager -o cat")
	if err != nil {
		t.Fatalf("failed to fetch fusion-server journal from %s: %v", targetNodeName, err)
	}
	if !strings.Contains(journal, "VIP-backed join resolved no remote seeds; treating node as first member") {
		contextLog, contextErr := runMultipassCommandOnInstance(t, targetNodeName, "sudo journalctl -u fusion-server --since '-5 min' --no-pager -o cat | grep -E 'No remote join seeds resolved|retrying join|allowing standalone bootstrap|getJoinAddresses filtered all VIP-derived seeds|\\[GOSSIP\\] seeds=|First member of cluster' | tail -n 50")
		if contextErr != nil {
			t.Fatalf("expected join instrumentation log on %s, not found; grep context also failed: %v", targetNodeName, contextErr)
		}
		if !strings.Contains(journal, "No remote join seeds resolved") {
			t.Fatalf("expected join instrumentation log on %s, not found. Filtered journal context:\n%s", targetNodeName, contextLog)
		}
		t.Logf("join path retried after zero-seed resolution on %s. Filtered journal context:\n%s", targetNodeName, contextLog)
	}

	t.Logf("clearing memberlist isolation on %s and waiting for cluster healing", targetNodeName)
	if _, err := runMultipassCommandOnInstance(t, targetNodeName, clearMemberlistIsolationCommand()); err != nil {
		t.Fatalf("failed to clear memberlist isolation on %s during healing phase: %v", targetNodeName, err)
	}
	time.Sleep(2 * time.Second)

	healedDevices := waitForHealthyBaselineDevices(t, nodeURLs, originalVIP, len(clusterConfig.nodes))
	t.Logf("healed cluster devices=%d ids=%s", len(healedDevices), summarizeDeviceIDs(healedDevices))

	targetMembersAfterHeal := waitForClusterMembersCount(t, vipURLForHost(targetHost), len(clusterConfig.nodes))
	peerMembersAAfterHeal := waitForClusterMembersCount(t, vipURLForHost(peerHosts[0]), len(clusterConfig.nodes))
	peerMembersBAfterHeal := waitForClusterMembersCount(t, vipURLForHost(peerHosts[1]), len(clusterConfig.nodes))
	t.Logf("healed member counts target=%d peerA=%d peerB=%d",
		len(targetMembersAfterHeal), len(peerMembersAAfterHeal), len(peerMembersBAfterHeal))
}

func setMasterPriorityByModeHTTP(baseURL, deviceID, modeValue string) error {
	client := &http.Client{Timeout: setupVIPAdminTimeout}
	endpoint := fmt.Sprintf("%s/devices/%s/vip/master-priority/%s", baseURL, url.PathEscape(deviceID), url.PathEscape(modeValue))
	req, err := http.NewRequest(http.MethodPost, endpoint, nil)
	if err != nil {
		return err
	}

	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("unexpected status %d body=%q", resp.StatusCode, string(body))
	}
	return nil
}

func applyMemberlistIsolationCommand(peerHosts []string) string {
	var command strings.Builder
	command.WriteString("set -eu; ")
	command.WriteString("if command -v nft >/dev/null 2>&1; then ")
	command.WriteString(fmt.Sprintf("sudo nft list table inet %s >/dev/null 2>&1 || sudo nft add table inet %s; ", memberlistIsolationTable, memberlistIsolationTable))
	command.WriteString(fmt.Sprintf("sudo nft 'add chain inet %s input { type filter hook input priority -300; policy accept; }' 2>/dev/null || true; ", memberlistIsolationTable))
	command.WriteString(fmt.Sprintf("sudo nft 'add chain inet %s output { type filter hook output priority -300; policy accept; }' 2>/dev/null || true; ", memberlistIsolationTable))
	command.WriteString(fmt.Sprintf("sudo nft flush chain inet %s input; ", memberlistIsolationTable))
	command.WriteString(fmt.Sprintf("sudo nft flush chain inet %s output; ", memberlistIsolationTable))
	for _, host := range peerHosts {
		command.WriteString(fmt.Sprintf("sudo nft add rule inet %s input ip saddr %s tcp dport %s drop; ", memberlistIsolationTable, host, memberlistPort))
		command.WriteString(fmt.Sprintf("sudo nft add rule inet %s input ip saddr %s udp dport %s drop; ", memberlistIsolationTable, host, memberlistPort))
		command.WriteString(fmt.Sprintf("sudo nft add rule inet %s output ip daddr %s tcp dport %s drop; ", memberlistIsolationTable, host, memberlistPort))
		command.WriteString(fmt.Sprintf("sudo nft add rule inet %s output ip daddr %s udp dport %s drop; ", memberlistIsolationTable, host, memberlistPort))
	}
	command.WriteString("else ")
	command.WriteString(fmt.Sprintf("sudo iptables -N %s 2>/dev/null || true; ", memberlistIsolationChain))
	command.WriteString(fmt.Sprintf("sudo iptables -F %s; ", memberlistIsolationChain))
	for _, host := range peerHosts {
		command.WriteString(fmt.Sprintf("sudo iptables -A %s -p tcp -s %s --dport %s -j DROP; ", memberlistIsolationChain, host, memberlistPort))
		command.WriteString(fmt.Sprintf("sudo iptables -A %s -p udp -s %s --dport %s -j DROP; ", memberlistIsolationChain, host, memberlistPort))
		command.WriteString(fmt.Sprintf("sudo iptables -A %s -p tcp -d %s --dport %s -j DROP; ", memberlistIsolationChain, host, memberlistPort))
		command.WriteString(fmt.Sprintf("sudo iptables -A %s -p udp -d %s --dport %s -j DROP; ", memberlistIsolationChain, host, memberlistPort))
	}
	command.WriteString(fmt.Sprintf("sudo iptables -C INPUT -j %s 2>/dev/null || sudo iptables -I INPUT 1 -j %s; ", memberlistIsolationChain, memberlistIsolationChain))
	command.WriteString(fmt.Sprintf("sudo iptables -C OUTPUT -j %s 2>/dev/null || sudo iptables -I OUTPUT 1 -j %s; ", memberlistIsolationChain, memberlistIsolationChain))
	command.WriteString("fi")
	return command.String()
}

func clearMemberlistIsolationCommand() string {
	return fmt.Sprintf("set +e; if command -v nft >/dev/null 2>&1; then sudo nft delete table inet %s 2>/dev/null || true; fi; sudo iptables -D INPUT -j %s 2>/dev/null || true; sudo iptables -D OUTPUT -j %s 2>/dev/null || true; sudo iptables -F %s 2>/dev/null || true; sudo iptables -X %s 2>/dev/null || true",
		memberlistIsolationTable,
		memberlistIsolationChain,
		memberlistIsolationChain,
		memberlistIsolationChain,
		memberlistIsolationChain,
	)
}

func clearMemberlistIsolationOnAllNodes(t *testing.T) {
	t.Helper()

	for _, node := range clusterConfig.nodes {
		if _, err := runMultipassCommandOnInstance(t, node.name, clearMemberlistIsolationCommand()); err != nil {
			t.Fatalf("failed to clear memberlist isolation on %s: %v", node.name, err)
		}
	}
	time.Sleep(2 * time.Second)
}

func restartFusionOnAllNodes(t *testing.T) {
	t.Helper()

	for _, node := range clusterConfig.nodes {
		if _, err := runMultipassCommandOnInstance(t, node.name, "sudo systemctl restart fusion-server"); err != nil {
			t.Fatalf("failed to restart fusion-server on %s: %v", node.name, err)
		}
	}
	time.Sleep(bootstrapSettleDelay)
}

func assertMemberlistIsolationActive(t *testing.T, instance string, peerHosts []string) {
	t.Helper()

	probeOutput, err := runMultipassCommandOnInstance(t, instance, memberlistIsolationProbeCommand(peerHosts))
	if err != nil {
		t.Fatalf("failed to probe memberlist isolation on %s: %v\noutput:\n%s", instance, err, probeOutput)
	}
	t.Logf("memberlist isolation probe on %s:\n%s", instance, probeOutput)

	for _, host := range peerHosts {
		if !strings.Contains(probeOutput, fmt.Sprintf("BLOCKED %s:%s", host, memberlistPort)) {
			rulesOutput, rulesErr := runMultipassCommandOnInstance(t, instance, memberlistIsolationRulesDumpCommand())
			if rulesErr != nil {
				t.Fatalf("memberlist isolation ineffective for %s:%s and rules dump failed: %v", host, memberlistPort, rulesErr)
			}
			t.Fatalf("memberlist isolation ineffective for %s:%s on %s\nprobe:\n%s\nrules:\n%s", host, memberlistPort, instance, probeOutput, rulesOutput)
		}
	}
}

func memberlistIsolationProbeCommand(peerHosts []string) string {
	var command strings.Builder
	command.WriteString("set -eu; ")
	command.WriteString("for host in")
	for _, host := range peerHosts {
		command.WriteString(" ")
		command.WriteString(host)
	}
	command.WriteString("; do ")
	command.WriteString(fmt.Sprintf("if timeout 2 bash -lc '</dev/tcp/$host/%s' >/dev/null 2>&1; then echo \"OPEN $host:%s\"; else echo \"BLOCKED $host:%s\"; fi; ", memberlistPort, memberlistPort, memberlistPort))
	command.WriteString("done")
	return command.String()
}

func memberlistIsolationRulesDumpCommand() string {
	return fmt.Sprintf("set +e; if command -v nft >/dev/null 2>&1; then echo '=== nft ==='; sudo nft list table inet %s 2>/dev/null || true; fi; echo '=== iptables ==='; sudo iptables -S 2>/dev/null || true",
		memberlistIsolationTable,
	)
}

func mustGetDevicesFromURL(t *testing.T, baseURL string) []*model.DeviceInfo {
	t.Helper()

	client := &http.Client{Timeout: setupVIPPollTimeout}
	resp, err := client.Get(baseURL + "/devices")
	if err != nil {
		t.Fatalf("GET %s/devices failed: %v", baseURL, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET %s/devices returned %d body=%s", baseURL, resp.StatusCode, string(body))
	}

	var payload model.DeviceListResponse
	if err := decodeProtoBody(resp.Body, &payload); err != nil {
		t.Fatalf("decode /devices from %s failed: %v", baseURL, err)
	}
	return payload.GetDevices()
}

func mustGetDevicesFromURLBestEffort(baseURL string) []*model.DeviceInfo {
	client := &http.Client{Timeout: setupVIPPollTimeout}
	resp, err := client.Get(baseURL + "/devices")
	if err != nil {
		return nil
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil
	}

	var payload model.DeviceListResponse
	if err := decodeProtoBody(resp.Body, &payload); err != nil {
		return nil
	}
	return payload.GetDevices()
}

func waitForHealthyBaselineDevices(t *testing.T, nodeURLs []string, vipHost string, expectedCount int) []*model.DeviceInfo {
	t.Helper()

	deadline := time.Now().Add(setupVIPTimeout)
	var lastSummary string
	for time.Now().Before(deadline) {
		candidates := make([][]*model.DeviceInfo, 0, len(nodeURLs)+1)
		seen := make(map[string]struct{}, len(nodeURLs)+1)

		for _, nodeURL := range nodeURLs {
			if _, ok := seen[nodeURL]; ok {
				continue
			}
			seen[nodeURL] = struct{}{}
			if devices := mustGetDevicesFromURLBestEffort(nodeURL); len(devices) > 0 {
				candidates = append(candidates, devices)
			}
		}

		vipURL := vipURLForHost(vipHost)
		if _, ok := seen[vipURL]; !ok {
			if devices := mustGetDevicesFromURLBestEffort(vipURL); len(devices) > 0 {
				candidates = append(candidates, devices)
			}
		}

		sort.Slice(candidates, func(i, j int) bool {
			if len(candidates[i]) == len(candidates[j]) {
				return summarizeDeviceIDs(candidates[i]) < summarizeDeviceIDs(candidates[j])
			}
			return len(candidates[i]) > len(candidates[j])
		})

		if len(candidates) > 0 {
			best := candidates[0]
			lastSummary = fmt.Sprintf("best_count=%d ids=%s primaries=%d", len(best), summarizeDeviceIDs(best), countPrimaries(best))
			if len(best) == expectedCount && countPrimaries(best) == 1 && hasNonPrimary(best) {
				return best
			}
		} else {
			lastSummary = "no reachable /devices endpoint"
		}

		time.Sleep(1 * time.Second)
	}

	t.Fatalf("cluster did not reach healthy baseline before isolation: %s", lastSummary)
	return nil
}

func mustGetClusterMembersJSON(t *testing.T, baseURL string) []clusterMemberSnapshot {
	t.Helper()

	client := &http.Client{Timeout: setupVIPPollTimeout}
	resp, err := client.Get(baseURL + "/cluster/members")
	if err != nil {
		t.Fatalf("GET %s/cluster/members failed: %v", baseURL, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("GET %s/cluster/members returned %d body=%s", baseURL, resp.StatusCode, string(body))
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatalf("read /cluster/members from %s failed: %v", baseURL, err)
	}

	var members []clusterMemberSnapshot
	if err := json.Unmarshal(body, &members); err != nil {
		t.Fatalf("decode /cluster/members from %s failed: %v body=%s", baseURL, err, string(body))
	}
	return members
}

func getClusterMembersJSONBestEffort(baseURL string) []clusterMemberSnapshot {
	client := &http.Client{Timeout: setupVIPPollTimeout}
	resp, err := client.Get(baseURL + "/cluster/members")
	if err != nil {
		return nil
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil
	}

	var members []clusterMemberSnapshot
	if err := json.Unmarshal(body, &members); err != nil {
		return nil
	}
	return members
}

func waitForClusterMembersCount(t *testing.T, baseURL string, expectedCount int) []clusterMemberSnapshot {
	t.Helper()

	deadline := time.Now().Add(setupVIPTimeout)
	lastCount := -1
	for time.Now().Before(deadline) {
		members := getClusterMembersJSONBestEffort(baseURL)
		if len(members) == expectedCount {
			return members
		}
		lastCount = len(members)
		time.Sleep(1 * time.Second)
	}

	t.Fatalf("%s/cluster/members did not reach count=%d within %v (last_count=%d)", baseURL, expectedCount, setupVIPTimeout, lastCount)
	return nil
}

func waitForDeviceCountOnURL(t *testing.T, baseURL string, expectedCount int) []*model.DeviceInfo {
	t.Helper()

	deadline := time.Now().Add(setupVIPTimeout)
	lastCount := -1
	for time.Now().Before(deadline) {
		devices := mustGetDevicesFromURLBestEffort(baseURL)
		if len(devices) == expectedCount {
			return devices
		}
		lastCount = len(devices)
		time.Sleep(1 * time.Second)
	}

	t.Fatalf("%s/devices did not reach count=%d within %v (last_count=%d)", baseURL, expectedCount, setupVIPTimeout, lastCount)
	return nil
}

func mustFindPrimaryDevice(t *testing.T, devices []*model.DeviceInfo) *model.DeviceInfo {
	t.Helper()

	var primary *model.DeviceInfo
	for _, device := range devices {
		if device != nil && device.GetIsPrimary() {
			if primary != nil {
				t.Fatalf("expected a single primary, found at least %s and %s", primary.GetId(), device.GetId())
			}
			primary = device
		}
	}
	if primary == nil {
		t.Fatal("no primary device found")
	}
	return primary
}

func mustPickNonPrimaryDevice(t *testing.T, devices []*model.DeviceInfo) *model.DeviceInfo {
	t.Helper()

	var selected *model.DeviceInfo
	for _, device := range devices {
		if device == nil || device.GetIsPrimary() {
			continue
		}
		if selected == nil || device.GetId() < selected.GetId() {
			selected = device
		}
	}
	if selected == nil {
		t.Fatal("no non-primary device found")
	}
	return selected
}

func countPrimaries(devices []*model.DeviceInfo) int {
	count := 0
	for _, device := range devices {
		if device != nil && device.GetIsPrimary() {
			count++
		}
	}
	return count
}

func hasNonPrimary(devices []*model.DeviceInfo) bool {
	for _, device := range devices {
		if device != nil && !device.GetIsPrimary() {
			return true
		}
	}
	return false
}

func summarizeDeviceIDs(devices []*model.DeviceInfo) string {
	ids := make([]string, 0, len(devices))
	for _, device := range devices {
		if device == nil {
			continue
		}
		ids = append(ids, device.GetId())
	}
	sort.Strings(ids)
	return strings.Join(ids, ",")
}

func otherNodeHosts(devices []*model.DeviceInfo, targetHost string) []string {
	seen := make(map[string]struct{})
	hosts := make([]string, 0, len(devices))
	for _, device := range devices {
		if device == nil || device.GetAddress() == "" || device.GetAddress() == targetHost {
			continue
		}
		if _, ok := seen[device.GetAddress()]; ok {
			continue
		}
		seen[device.GetAddress()] = struct{}{}
		hosts = append(hosts, device.GetAddress())
	}
	return hosts
}

func allOtherNodeNames(targetNodeName string) []string {
	names := make([]string, 0, len(clusterConfig.nodes)-1)
	for _, node := range clusterConfig.nodes {
		if node.name == targetNodeName {
			continue
		}
		names = append(names, node.name)
	}
	return names
}

func nodeNameForHost(t *testing.T, host string) string {
	t.Helper()

	for _, node := range clusterConfig.nodes {
		if hostFromNodeURL(t, node.address) == host {
			return node.name
		}
	}
	t.Fatalf("could not map host %s to cluster node", host)
	return ""
}

func logJoinRetrySignal(t *testing.T, nodeName string) {
	t.Helper()

	deadline := time.Now().Add(setupVIPTimeout)
	for time.Now().Before(deadline) {
		out, err := runMultipassCommandOnInstance(t, nodeName, "sudo journalctl -u fusion-server --since '-5 min' --no-pager -o cat | grep -E 'No remote join seeds resolved during startup; retrying join|No remote join seeds resolved' | tail -n 20")
		if err == nil && strings.Contains(out, "No remote join seeds resolved") {
			t.Logf("join retry signal observed on %s:\n%s", nodeName, out)
			return
		}
		time.Sleep(1 * time.Second)
	}

	t.Logf("join retry signal not observed on %s within %v; continuing with functional recovery checks", nodeName, setupVIPTimeout)
}
