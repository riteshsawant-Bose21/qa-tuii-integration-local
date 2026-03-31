package main

import (
	"bytes"
	"encoding/csv"
	"flag"
	"fmt"
	"fusion/internal/api"
	"io"
	"net/http"
	"os"
	"os/exec"
	"reflect"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

// clusterNode represents a node in the test cluster
type clusterNode struct {
	address string
	name    string
}

// ClusterConfig holds the test configuration for the cluster
type ClusterConfig struct {
	nodes []clusterNode
	vip   string
}

// Pretty print the configuration for debugging
func (c *ClusterConfig) String() string {
	var b strings.Builder
	b.WriteString(fmt.Sprintf("VIP: %s\n", c.vip))
	b.WriteString("Nodes:\n")
	for i, node := range c.nodes {
		b.WriteString(fmt.Sprintf("  %d: %s (ID: %s)\n", i+1, node.address, node.name))
	}
	return b.String()
}

// MultipassNode represents a node discovered from multipass
type MultipassNode struct {
	Name   string
	State  string
	IPAddr string
	Image  string
}

const (
	clusterTimout = 10 * time.Second
	instancePort  = "7947"
	ncCommand     = "nc -4 -u -w 1 localhost"
	requiredNodes = 3 // Number of nodes required for cluster tests
	serverAddr    = "http://192.168.2.100:8080"
	testTimeout   = 5 * time.Second
	syncBlockID   = "sync_test"
)

var (
	clusterConfig *ClusterConfig
)

func isLocalTestMode() bool {
	if os.Getenv("FUSION_TEST_LOCAL") != "" {
		return true
	}

	nodesEnv := os.Getenv("FUSION_TEST_NODES")
	vipEnv := os.Getenv("FUSION_TEST_VIP")
	if nodesEnv == "" || vipEnv == "" {
		return false
	}

	return strings.Contains(nodesEnv, "127.0.0.1") && strings.Contains(vipEnv, "127.0.0.1")
}

func TestMain(m *testing.M) {
	flag.Parse()

	cfg, err := getClusterConfig()
	if err != nil {
		fmt.Printf("Failed to get cluster configuration: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Test Configuration:\n%s\n", cfg)

	clusterConfig = cfg
	os.Exit(m.Run())
}

func TestPatchArrayElement(t *testing.T) {
	if err := patchAudioSetting(serverAddr, "tone_eq1", "frequencies", []float64{100.0, 200.0, 300.0}); err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	if err := patchAudioIndexedSetting(serverAddr, "tone_eq1", "frequencies", 1, 250.0); err != nil {
		t.Fatalf("Failed to update array element: %v", err)
	}
	frequencies, err := getAudioSettingArray(serverAddr, "tone_eq1", "frequencies")
	if err != nil {
		t.Fatalf("Failed to get updated array: %v", err)
	}
	if len(frequencies) != 3 || frequencies[1] != 250.0 {
		t.Errorf("Failed to update array element: expected %v, got %v", 250.0, frequencies[1])
	}
	if err := patchAudioIndexedSetting(serverAddr, "tone_eq1", "frequencies", 3, 400.0); err != nil {
		t.Fatalf("Failed to insert array element: %v", err)
	}
	frequencies, err = getAudioSettingArray(serverAddr, "tone_eq1", "frequencies")
	if err != nil {
		t.Fatalf("Failed to get inserted array element: %v", err)
	}
	if len(frequencies) != 4 || frequencies[3] != 400.0 {
		t.Errorf("Failed to insert new array element: expected %v at index 3, got %v", 400.0, frequencies)
	}
}

// TestPatchDiffOutput sets an initial configuration, performs PATCH updates,
// and asserts that the diff output only contains the changed elements.
func TestPatchDiffOutput(t *testing.T) {
	if err := patchAudioSetting(serverAddr, "tone_eq1", "frequencies", []float64{100.0, 200.0, 300.0}); err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	resp, err := patchAudioIndexedRequest(serverAddr, "tone_eq1", "frequencies", 1, 250.0)
	if err != nil {
		t.Fatalf("Failed to update array element: %v", err)
	}
	defer resp.Body.Close()

	// Decode the patch response.
	var patchResp struct {
		Status  string `json:"status"`
		Updates any    `json:"updates"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&patchResp); err != nil {
		t.Fatalf("Failed to decode patch response: %v", err)
	}

	if patchResp.Status != "success" {
		t.Fatalf("Patch update failed with status: %s", patchResp.Status)
	}

	// Only the array element at index 1 should be different.
	expectedDiff := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"tone_eq1": map[string]any{
					"frequencies": map[string]any{
						"1": 250.0,
					},
				},
			},
		},
	}
	if !reflect.DeepEqual(patchResp.Updates, expectedDiff) {
		t.Errorf("Unexpected diff for frequencies update.\nExpected: %+v\nGot:      %+v", expectedDiff, patchResp.Updates)
	}

	// Verify the frequencies array update via the focused audio settings endpoint.
	frequencies, err := getAudioSettingArray(serverAddr, "tone_eq1", "frequencies")
	if err != nil {
		t.Fatalf("Failed to get updated frequencies array: %v", err)
	}
	if len(frequencies) != 3 || frequencies[1] != 250.0 {
		t.Errorf("Failed to update frequencies array: expected index 1 to be %v, got %v", 250.0, frequencies[1])
	}
}

// TestPatchOutOfBounds verifies that an update using an out‐of‑bound array index
// expands the array. For an initial array [100, 200, 300], updating index 5 with 500
// should yield [100, 200, 300, nil, nil, 500].
func TestPatchOutOfBounds(t *testing.T) {
	if err := patchAudioSetting(serverAddr, "tone_eq1", "frequencies", []float64{100.0, 200.0, 300.0}); err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	resp, err := patchAudioIndexedRequest(serverAddr, "tone_eq1", "frequencies", 5, 500.0)
	if err != nil {
		t.Fatalf("Failed to execute PATCH request for out-of-bound update: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Unexpected status code for out-of-bound update: got %d", resp.StatusCode)
	}
	frequencies, err := getAudioSettingArray(serverAddr, "tone_eq1", "frequencies")
	if err != nil {
		t.Fatalf("Failed to get updated array: %v", err)
	}
	expected := []any{100.0, 200.0, 300.0, nil, nil, 500.0}
	if !reflect.DeepEqual(frequencies, expected) {
		t.Errorf("Out-of-bound update expected array %v, got %v", expected, frequencies)
	}
}

// TestPatchRemoveArrayElement verifies that when patching an array element with a JSON null,
// the element is set to null while the array length remains unchanged. For an initial array
// [100, 200, 300], patching index 1 should yield [100, nil, 300].
func TestPatchRemoveArrayElement(t *testing.T) {
	const blockID = "tone_eq_remove_test"

	if err := patchAudioSetting(serverAddr, blockID, "frequencies", []float64{100.0, 200.0, 300.0}); err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	resp, err := patchAudioIndexedRequest(serverAddr, blockID, "frequencies", 1, nil)
	if err != nil {
		t.Fatalf("Failed to send PATCH request for removal: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code for removal: %d, response: %s", resp.StatusCode, string(body))
	}
	frequencies, err := getAudioSettingArray(serverAddr, blockID, "frequencies")
	if err != nil {
		t.Fatalf("Failed to get updated array: %v", err)
	}
	expected := []any{100.0, nil, 300.0}
	if !reflect.DeepEqual(frequencies, expected) {
		t.Errorf("Expected updated array %v, got %v", expected, frequencies)
	}
}

// TestConcurrentPatchRequests tests multiple concurrent PATCH requests
func TestConcurrentPatchRequests(t *testing.T) {
	if err := patchAudioSetting(serverAddr, "eq", "bands", []float64{100.0, 200.0, 300.0}); err != nil {
		t.Fatalf("failed to set initial configuration: %v", err)
	}

	// Prepare concurrent updates
	const numWorkers = 10
	const numRequests = 50
	errCh := make(chan error, numWorkers*numRequests)
	var wg sync.WaitGroup

	for w := range numWorkers {
		wg.Add(1)
		go func(worker int) {
			defer wg.Done()
			for i := range numRequests {
				resp, err := patchAudioIndexedRequest(serverAddr, "eq", "bands", i%3, float64(100+worker+i))
				if err != nil {
					errCh <- fmt.Errorf("worker %d request %d failed: %w", worker, i, err)
					return
				}
				io.Copy(io.Discard, resp.Body)
				resp.Body.Close()
			}
		}(w)
	}

	wg.Wait()
	close(errCh)

	for err := range errCh {
		t.Errorf("patch error: %v", err)
	}

	// Fetch final array to ensure server still responds and data is consistent
	if _, err := getAudioSettingArray(serverAddr, "eq", "bands"); err != nil {
		t.Errorf("final array missing after concurrent patches: %v", err)
	}
}

// TestPostValueOnNonVIPNode sets a value via POST on a non-VIP node
// and then verifies it through the VIP endpoint.
func TestPostValueOnNonVIPNode(t *testing.T) {
	key := "nonvip_post_test"
	value := "from_nonvip"
	preflightKey := "nonvip_preflight_post"
	preflightValue := "ready"

	if err := patchAudioSetting(clusterConfig.vip, syncBlockID, preflightKey, preflightValue); err != nil {
		t.Fatalf("Failed to seed preflight value via VIP: %v", err)
	}
	node, ok := findSyncedNonVIPNode(t, preflightKey, preflightValue, 5*time.Second)
	if !ok {
		t.Fatalf("No non-VIP node converged with VIP before write test")
	}

	if err := patchAudioSetting(node.address, syncBlockID, key, value); err != nil {
		t.Fatalf("PATCH to non-VIP node failed: %v", err)
	}

	var (
		got    any
		exists bool
		err    error
	)
	if !waitForSync(5*time.Second, func() bool {
		got, exists, err = getValueFromNode(clusterNode{address: clusterConfig.vip}, key)
		return err == nil && exists && got == value
	}) {
		if err != nil {
			t.Fatalf("GET via VIP failed: %v", err)
		}
		t.Errorf("Value not synced: want %q got %v", value, got)
	}
}

// TestPatchValueOnNonVIPNode PATCHes a value on a non-VIP node
// and then verifies the change through the VIP endpoint.
func TestPatchValueOnNonVIPNode(t *testing.T) {
	preflightKey := "nonvip_preflight_patch"
	preflightValue := "ready"
	if err := patchAudioSetting(clusterConfig.vip, syncBlockID, preflightKey, preflightValue); err != nil {
		t.Fatalf("Failed to seed preflight value via VIP: %v", err)
	}
	node, ok := findSyncedNonVIPNode(t, preflightKey, preflightValue, 5*time.Second)
	if !ok {
		t.Fatalf("No non-VIP node converged with VIP before patch test")
	}

	// first ensure a baseline via VIP
	key := "nonvip_patch_test"
	initial := "baseline"
	if err := patchAudioSetting(clusterConfig.vip, syncBlockID, key, initial); err != nil {
		t.Fatalf("Failed to seed baseline value: %v", err)
	}

	// patch on non-VIP node
	updated := "patched_value"
	resp, err := patchAudioRequest(node.address, syncBlockID, key, updated)
	if err != nil {
		t.Fatalf("PATCH to non-VIP node failed: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Unexpected status from non-VIP PATCH: %d", resp.StatusCode)
	}

	var (
		got     any
		exists  bool
		readErr error
	)
	if !waitForSync(5*time.Second, func() bool {
		got, exists, readErr = getValueFromNode(clusterNode{address: clusterConfig.vip}, key)
		return readErr == nil && exists && got == updated
	}) {
		if readErr != nil {
			t.Fatalf("GET via VIP after PATCH failed: %v", readErr)
		}
		t.Errorf("Patch not synced: want %q got %v", updated, got)
	}
}

func TestRootEndpoint(t *testing.T) {
	resp, err := http.Get(serverAddr)
	if err != nil {
		t.Fatalf("Failed to get root endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Root endpoint returned wrong status: got %v want %v",
			resp.StatusCode, http.StatusOK)
	}

	var response map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		t.Fatalf("Failed to decode root response: %v", err)
	}

	// Check required fields
	requiredFields := []string{"name", "version", "node_id", "endpoints", "cluster_size"}
	for _, field := range requiredFields {
		if _, ok := response[field]; !ok {
			t.Errorf("Root response missing required field: %s", field)
		}
	}
}

// TestClusterStateSync verifies that state changes are properly synchronized
func TestClusterStateSync(t *testing.T) {
	nodes := clusterConfig.nodes
	if len(nodes) < 3 {
		t.Fatalf("Test requires at least 3 nodes, but only %d available", len(nodes))
	}

	testNodes := nodes[:3]
	checkClusterConnectivity(t, testNodes)

	if !verifyClusterHealth(t, testNodes) {
		t.Fatal("Cluster health check failed - requires 3 running nodes")
	}

	tests := []struct {
		name         string
		key          string
		value        any
		updateNode   int
		verifyNodes  []int
		expectedSync bool
		timeout      time.Duration
	}{
		{
			name:         "Simple string value sync",
			key:          "test_sync_string",
			value:        "test_value",
			updateNode:   0,
			verifyNodes:  []int{1, 2},
			expectedSync: true,
			timeout:      testTimeout,
		},
		{
			name:         "Complex object sync",
			key:          "test_sync_object",
			value:        map[string]any{"nested": "value", "number": 42},
			updateNode:   1,
			verifyNodes:  []int{0, 2},
			expectedSync: true,
			timeout:      testTimeout,
		},
		{
			name:         "Array value sync",
			key:          "test_sync_array",
			value:        []string{"one", "two", "three"},
			updateNode:   2,
			verifyNodes:  []int{0, 1},
			expectedSync: true,
			timeout:      testTimeout,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			//t.Logf("%s", tt.name)
			//t.Logf("  Node: %s", testNodes[tt.updateNode])

			err := setValueOnNode(testNodes[tt.updateNode], tt.key, tt.value)
			if err != nil {
				t.Fatalf("Failed to set value on node %d: %v", tt.updateNode, err)
			}

			success := waitForSync(tt.timeout, func() bool {
				for _, nodeIdx := range tt.verifyNodes {
					//t.Logf("    Checking: %s", testNodes[nodeIdx])
					value, exists, err := getValueFromNode(testNodes[nodeIdx], tt.key)
					if err != nil || !exists || !valueEquals(value, tt.value) {
						return false
					}
				}
				return true
			})

			if !success && tt.expectedSync {
				t.Logf("Sync failed - Dumping state of all nodes:")
				for i, node := range testNodes {
					state, err := getFullStateFromNode(node)
					if err != nil {
						t.Logf("Failed to get state from node %d: %v", i, err)
						continue
					}
					prettyState, _ := json.MarshalIndent(state, "", "  ")
					t.Logf("Node %d state:\n%s", i, string(prettyState))
				}
				t.Errorf("Failed to sync state across cluster within %v", tt.timeout)
			}
		})
	}
}

// TestStateConsistency verifies that the entire state is consistent
func TestStateConsistency(t *testing.T) {
	if clusterConfig == nil {
		t.Fatal("Cluster configuration not initialized")
	}

	nodes := clusterConfig.nodes
	if len(nodes) < 3 {
		t.Fatalf("Test requires at least 3 nodes, but only %d available", len(nodes))
	}

	testNodes := nodes[:3]

	if !verifyClusterHealth(t, testNodes) {
		t.Fatal("Cluster health check failed - requires 3 running nodes")
	}

	testData := []struct {
		nodeIndex int
		key       string
		value     any
	}{
		{0, "consistency_test_1", "value1"},
		{1, "consistency_test_2", 42},
		{2, "consistency_test_3", []string{"a", "b", "c"}},
	}

	for _, td := range testData {
		err := setValueOnNode(testNodes[td.nodeIndex], td.key, td.value)
		if err != nil {
			t.Fatalf("Failed to set test data on node %d: %v", td.nodeIndex, err)
		}
	}

	//t.Log("Waiting for initial state sync...")
	initialSyncTime := 5 * time.Second
	logProgress(t, "Initial sync", initialSyncTime)

	states := make([]map[string]any, len(testNodes))
	for i, node := range testNodes {
		var err error
		states[i], err = getFullStateFromNode(node)
		if err != nil {
			t.Fatalf("Failed to get state from node %d: %v", i, err)
		}
	}

	for key := range states[0] {
		for i := 1; i < len(testNodes); i++ {
			value1 := states[0][key]
			value2 := states[i][key]

			if value2 == nil {
				t.Errorf("Key %s missing on node %d", key, i)
				continue
			}

			if !valueEquals(value1, value2) {
				t.Errorf("State mismatch for key %s between node 0 and node %d:\nNode 0: %+v\nNode %d: %+v",
					key, i, value1, i, value2)
			}
		}
	}

	//t.Logf("Successfully verified state consistency across nodes")
}

// TestClearEndpoint verifies that data is cleared on all nodes
func TestClearEndpoint(t *testing.T) {
	client := &http.Client{}
	for _, node := range append(clusterConfig.nodes, clusterNode{address: clusterConfig.vip}) {
		req, err := http.NewRequest(http.MethodDelete, fmt.Sprintf("%s/settings/audio", node.address), nil)
		if err != nil {
			t.Fatalf("Failed to create DELETE request for %s: %v", node.address, err)
		}
		resp, err := client.Do(req)
		if err != nil {
			t.Fatalf("Failed to send DELETE request to %s: %v", node.address, err)
		}
		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("Unexpected status code from %s: %d, response: %s", node.address, resp.StatusCode, string(body))
		}
	}

	// Verify on every node that the audio settings subtree is absent.
	for _, node := range append(clusterConfig.nodes, clusterNode{address: clusterConfig.vip}) {
		t.Run("Clear on "+node.address, func(t *testing.T) {
			deadline := time.Now().Add(5 * time.Second)
			var lastStatus int
			var lastBody string
			var lastErr error

			for time.Now().Before(deadline) {
				getResp, err := http.Get(fmt.Sprintf("%s/settings/audio", node.address))
				if err != nil {
					lastErr = err
					time.Sleep(100 * time.Millisecond)
					continue
				}

				body, _ := io.ReadAll(getResp.Body)
				getResp.Body.Close()

				lastStatus = getResp.StatusCode
				lastBody = string(body)

				if getResp.StatusCode == http.StatusNotFound {
					return
				}

				time.Sleep(100 * time.Millisecond)
			}

			if lastErr != nil {
				t.Fatalf("GET after clear failed on %s: %v", node.address, lastErr)
			}
			t.Errorf("Expected 404 Not Found from %s after clear, got %d: %s", node.address, lastStatus, lastBody)
		})
	}
}

// TestUDPGet runs the "get" command inside the default instance.
func TestUDPGet(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	command := fmt.Sprintf(`echo '{"action":"get"}' | %s %s`, ncCommand, instancePort)
	out, err := runMultipassCommand(t, command)
	if err != nil {
		t.Fatalf("Multipass get command failed: %v, output: %s", err, out)
	}
}

// TestUDPSet runs the "set" command inside the default instance.
func TestUDPSet(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	command := fmt.Sprintf(`echo '{"action":"set","test":"hello"}' | %s %s`, ncCommand, instancePort)
	out, err := runMultipassCommand(t, command)
	if err != nil {
		t.Fatalf("Multipass set command failed: %v, output: %s", err, out)
	}
}

// TestUDPSetAndGet sets a value and then verifies it with a get command on the default instance.
func TestUDPSetAndGet(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	// Set the value on instance1.
	setCommand := fmt.Sprintf(`echo '{"action":"set","payload":{"test":"hello"}}' | %s %s`, ncCommand, instancePort)
	setOut, err := runMultipassCommand(t, setCommand)
	if err != nil {
		t.Fatalf("Multipass set command failed: %v, output: %s", err, setOut)
	}

	// Retrieve the value from instance1.
	getCommand := fmt.Sprintf(`echo '{"action":"get"}' | %s %s`, ncCommand, instancePort)
	getOut, err := runMultipassCommand(t, getCommand)
	if err != nil {
		t.Fatalf("Multipass get command failed: %v, output: %s", err, getOut)
	}

	// Verify that the returned output contains the expected test value.
	if !strings.Contains(getOut, "hello") {
		t.Fatalf("Expected get output to contain 'hello', got: %s", getOut)
	}
}

// TestUDPPropagation sets a value on instance1 and verifies that it propagates to instance2.
func TestUDPPropagation(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	// Build commands once
	setCmd := fmt.Sprintf(`echo '{"action":"set","payload":{"test":"hello"}}' | %s %s`, ncCommand, instancePort)
	getCmd := fmt.Sprintf(`echo '{"action":"get"}' | %s %s`, ncCommand, instancePort)

	// Set on the "master" node
	name := clusterConfig.nodes[0].name
	if out, err := runMultipassCommandOnInstance(t, name, setCmd); err != nil {
		t.Fatalf("set on %s failed: %v (output: %q)", name, err, out)
	}

	// Verify on each of the other nodes
	for _, node := range clusterConfig.nodes[1:] {
		out, err := runMultipassCommandOnInstance(t, node.name, getCmd)
		if err != nil {
			t.Errorf("get on %s failed: %v (output: %q)", node, err, out)
			continue
		}
		if !strings.Contains(out, "hello") {
			t.Errorf("expected 'hello' on %s, got %q", node, out)
		}
	}
}

type UDPResult struct {
	Data   map[string]any `json:"data"`
	Status string         `json:"status"`
}

func TestHTTPSetAndVerifyViaUDP(t *testing.T) {
	t.Skip("legacy public /value write API removed")
}

func TestUDPSetAndVerifyViaHTTP(t *testing.T) {
	t.Skip("legacy public /value read API removed")
}

// verifyClusterHealth checks if the required number of nodes are running and healthy
func verifyClusterHealth(t *testing.T, nodes []clusterNode) bool {
	t.Helper()

	//t.Logf("Verifying cluster health across %d nodes...", len(nodes))

	deadline := time.Now().Add(clusterTimout)
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for time.Now().Before(deadline) {
		for i, node := range nodes {
			size, err := getClusterSize(node)
			if err == nil {
				if size >= requiredNodes {
					//t.Logf("Cluster is healthy with %d nodes", size)
					return true
				}
				//t.Logf("Node %d reports cluster size %d/%d", i+1, size, requiredNodes)
			} else {
				t.Logf("Node %d health check failed: %v", i+1, err)
			}
		}
		<-ticker.C
		t.Logf("Still waiting for cluster health... %v remaining", time.Until(deadline).Round(time.Second))
	}

	t.Errorf("Cluster health check failed after %v", clusterTimout)
	return false
}

// getClusterSize retrieves the number of nodes in the cluster from a given node
func getClusterSize(node clusterNode) (int, error) {
	resp, err := http.Get(node.address)
	if err != nil {
		return 0, fmt.Errorf("failed to connect to node %s: %v", node.address, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("unexpected status code from node %s: %d", node.address, resp.StatusCode)
	}

	var info struct {
		ClusterSize int `json:"cluster_size"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return 0, fmt.Errorf("failed to decode response from node %s: %v", node.address, err)
	}

	if info.ClusterSize == 0 {
		return 0, fmt.Errorf("node %s reported zero cluster size", node.address)
	}

	return info.ClusterSize, nil
}

func logProgress(t *testing.T, msg string, duration time.Duration) {
	t.Helper()
	deadline := time.Now().Add(duration)
	t.Logf("Starting: %s (timeout: %v)", msg, duration)

	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for time.Now().Before(deadline) {
		select {
		case <-ticker.C:
			remaining := time.Until(deadline).Round(time.Second)
			t.Logf("%s - %v remaining...", msg, remaining)
		default:
			time.Sleep(100 * time.Millisecond)
		}
	}
}

func checkClusterConnectivity(t *testing.T, nodes []clusterNode) {

	//t.Logf("\n=== Checking Cluster Connectivity ===")

	// Get cluster info from each node
	for _, node := range nodes {
		resp, err := http.Get(node.address)
		if err != nil {
			t.Logf("Failed to connect to %s: %v", node.address, err)
			continue
		}
		defer resp.Body.Close()

		var info struct {
			NodeID      string   `json:"node_id"`
			ClusterSize int      `json:"cluster_size"`
			Members     []string `json:"members"`
			Version     string   `json:"version"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
			t.Logf("Failed to decode response from %s: %v", node.address, err)
			continue
		}

		// t.Logf("\nNode: %s", node.address)
		// t.Logf("  ID: %s", info.NodeID)
		// t.Logf("  Cluster Size: %d", info.ClusterSize)
		// t.Logf("  Version: %s", info.Version)
		// if len(info.Members) > 0 {
		// 	t.Logf("  Known Members: %v", info.Members)
		// }
	}
}

// discoverMultipassNodes discovers fusion nodes running in multipass
func discoverMultipassNodes(baseName string) ([]MultipassNode, error) {
	// Run multipass list with CSV output for easier parsing
	cmd := exec.Command("multipass", "list", "--format", "csv")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to run multipass list: %v", err)
	}

	// Parse CSV output
	reader := csv.NewReader(bytes.NewReader(output))
	records, err := reader.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("failed to parse multipass output: %v", err)
	}

	var nodes []MultipassNode
	// Skip header row
	for _, record := range records[1:] {
		// Only process records with enough fields
		if len(record) < 4 {
			continue
		}

		name := record[0]
		// Only include nodes that match our base name
		if !strings.HasPrefix(name, baseName) {
			continue
		}

		node := MultipassNode{
			Name:   name,
			State:  record[1],
			IPAddr: record[2],
			Image:  record[3],
		}

		// Only include running nodes
		if node.State == "Running" {
			nodes = append(nodes, node)
		}
	}

	return nodes, nil
}

// getClusterConfig retrieves cluster configuration from environment, flags, or multipass
func getClusterConfig() (*ClusterConfig, error) {
	var (
		nodesFlag    = flag.String("nodes", "", "Comma-separated list of node addresses (e.g., 192.168.64.229:8080,192.168.64.230:8080)")
		vipFlag      = flag.String("vip", "", "VIP address (e.g., 192.168.2.100:8080)")
		baseNameFlag = flag.String("base-name", "fusion", "Base name for multipass instances")
		portFlag     = flag.String("port", "8080", "Port for node services")
		autoFlag     = flag.Bool("auto", false, "Automatically discover nodes using multipass")
	)

	if !flag.Parsed() {
		flag.Parse()
	}

	cfg := &ClusterConfig{}

	// Try environment variables first
	nodesEnv := os.Getenv("FUSION_TEST_NODES")
	vipEnv := os.Getenv("FUSION_TEST_VIP")
	baseNameEnv := os.Getenv("FUSION_BASE_NAME")
	autoEnv := os.Getenv("FUSION_AUTO_DISCOVER")

	// Determine if we should use auto-discovery
	useAuto := *autoFlag || autoEnv == "1" || autoEnv == "true"

	// Get base name for multipass instances
	baseName := baseNameEnv
	if baseName == "" {
		baseName = *baseNameFlag
	}

	// Auto-discover nodes if requested
	if useAuto {
		nodes, err := discoverMultipassNodes(baseName)
		if err != nil {
			return nil, fmt.Errorf("failed to discover multipass nodes: %v", err)
		}

		if len(nodes) == 0 {
			return nil, fmt.Errorf("no running multipass nodes found with base name: %s", baseName)
		}

		// Sort nodes by name to ensure consistent ordering
		// This assumes names end in numbers (fusion1, fusion2, etc.)
		sort.Slice(nodes, func(i, j int) bool {
			return nodes[i].Name < nodes[j].Name
		})

		port := *portFlag
		for _, node := range nodes {
			addr := fmt.Sprintf("%s%s:%s", api.Protocol, node.IPAddr, port)
			cfg.nodes = append(cfg.nodes, clusterNode{
				address: addr,
				name:    node.Name,
			})
		}

		// For auto-discovery, assume VIP is on .100 if not specified
		if vipEnv == "" && *vipFlag == "" {
			// Extract the subnet from the first node's IP
			parts := strings.Split(nodes[0].IPAddr, ".")
			if len(parts) == 4 {
				cfg.vip = fmt.Sprintf("%s%s.%s.%s.100:%s", api.Protocol, parts[0], parts[1], parts[2], port)
			}
		}
	}

	// If not auto-discovering or if auto-discovery failed to set VIP, use manual configuration
	if cfg.vip == "" {
		cfg.vip = vipEnv
		if cfg.vip == "" {
			cfg.vip = *vipFlag
		}
	}

	// If not auto-discovering or if we want to override discovered nodes
	if !useAuto || nodesEnv != "" || *nodesFlag != "" {
		nodesList := nodesEnv
		if nodesList == "" {
			nodesList = *nodesFlag
		}

		if nodesList != "" {
			cfg.nodes = nil // Clear any auto-discovered nodes
			addresses := strings.Split(nodesList, ",")
			for i, addr := range addresses {
				addr = strings.TrimSpace(addr)
				if addr == "" {
					continue
				}

				if !strings.HasPrefix(addr, "http://") {
					addr = "http://" + addr
				}

				cfg.nodes = append(cfg.nodes, clusterNode{
					address: addr,
					name:    fmt.Sprintf("node%d", i+1),
				})
			}
		}
	}

	// Validate configuration
	if cfg.vip == "" {
		return nil, fmt.Errorf("VIP address must be provided via FUSION_TEST_VIP, --vip flag, or auto-discovery")
	}

	if !strings.HasPrefix(cfg.vip, "http://") {
		cfg.vip = "http://" + cfg.vip
	}

	if len(cfg.nodes) == 0 {
		return nil, fmt.Errorf("no nodes configured via environment, flags, or auto-discovery")
	}

	return cfg, nil
}

func setValueOnNode(node clusterNode, key string, value any) error {
	return patchAudioSetting(node.address, syncBlockID, key, value)
}

func getValueFromNode(node clusterNode, key string) (any, bool, error) {
	value, err := getAudioSettingValue(node.address, syncBlockID, key)
	if err != nil {
		return nil, false, err
	}
	return value, true, nil
}

func getFullStateFromNode(node clusterNode) (map[string]any, error) {
	resp, err := http.Get(fmt.Sprintf("%s/settings/audio/%s", node.address, syncBlockID))
	if err != nil {
		return nil, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()

	var state map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&state); err != nil {
		return nil, fmt.Errorf("failed to decode response: %v", err)
	}

	return state, nil
}

func patchAudioSetting(baseURL, blockID, param string, value any) error {
	resp, err := patchAudioRequest(baseURL, blockID, param, value)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("unexpected status code: %d response: %s", resp.StatusCode, string(body))
	}
	return nil
}

func patchAudioRequest(baseURL, blockID, param string, value any) (*http.Response, error) {
	body, err := json.Marshal(map[string]any{"value": value})
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequest("PATCH", fmt.Sprintf("%s/settings/audio/%s/%s", baseURL, blockID, param), bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	return (&http.Client{}).Do(req)
}

func patchAudioIndexedRequest(baseURL, blockID, param string, index int, value any) (*http.Response, error) {
	body, err := json.Marshal(map[string]any{"value": value})
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequest("PATCH", fmt.Sprintf("%s/settings/audio/%s/%s/%d", baseURL, blockID, param, index), bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	return (&http.Client{}).Do(req)
}

func patchAudioIndexedSetting(baseURL, blockID, param string, index int, value any) error {
	resp, err := patchAudioIndexedRequest(baseURL, blockID, param, index, value)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("unexpected status code: %d response: %s", resp.StatusCode, string(body))
	}
	return nil
}

func getAudioSettingValue(baseURL, blockID, param string) (any, error) {
	resp, err := http.Get(fmt.Sprintf("%s/settings/audio/%s/%s", baseURL, blockID, param))
	if err != nil {
		return nil, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("unexpected status code: %d response: %s", resp.StatusCode, string(body))
	}
	var response struct {
		Value any `json:"value"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, fmt.Errorf("failed to decode response: %v", err)
	}
	return response.Value, nil
}

func getAudioSettingArray(baseURL, blockID, param string) ([]any, error) {
	value, err := getAudioSettingValue(baseURL, blockID, param)
	if err != nil {
		return nil, err
	}
	array, ok := value.([]any)
	if !ok {
		return nil, fmt.Errorf("value is not an array: %T", value)
	}
	return array, nil
}

func findSyncedNonVIPNode(t *testing.T, key string, want any, timeout time.Duration) (clusterNode, bool) {
	t.Helper()

	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		for _, node := range clusterConfig.nodes {
			got, exists, err := getValueFromNode(node, key)
			if err == nil && exists && got == want {
				return node, true
			}
		}
		time.Sleep(100 * time.Millisecond)
	}

	return clusterNode{}, false
}

func waitForSync(timeout time.Duration, check func() bool) bool {
	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if check() {
			return true
		}
		<-ticker.C
	}
	return false
}

func valueEquals(v1, v2 any) bool {
	// Handle nil cases explicitly
	if v1 == nil && v2 == nil {
		return true
	}
	if v1 == nil || v2 == nil {
		return false
	}

	// Check if v1 is a map that might contain our value
	if m1, ok := v1.(map[string]any); ok {
		if val, exists := m1["value"]; exists {
			v1 = val
		}
	}

	// Check if v2 is a map that might contain our value
	if m2, ok := v2.(map[string]any); ok {
		if val, exists := m2["value"]; exists {
			v2 = val
		}
	}

	// Convert both values to JSON for deep comparison
	j1, err1 := json.Marshal(v1)
	j2, err2 := json.Marshal(v2)
	if err1 != nil || err2 != nil {
		return false
	}
	return bytes.Equal(j1, j2)
}

// runMultipassCommand executes a bash command on the default instance using multipass exec.
func runMultipassCommand(t *testing.T, command string) (string, error) {
	t.Helper()
	name := clusterConfig.nodes[0].name
	return runMultipassCommandOnInstance(t, name, command)
}

// runMultipassCommandOnInstance executes a bash command on a given instance using multipass exec.
func runMultipassCommandOnInstance(t *testing.T, instance, command string) (string, error) {
	t.Helper()
	args := []string{"exec", instance, "--", "bash", "-c", command}
	//t.Logf("\nCommand: multipass %s", strings.Join(args, " "))
	cmd := exec.Command("multipass", args...)
	output, err := cmd.CombinedOutput()
	return string(output), err
}
