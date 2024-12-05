package main

import (
	"bytes"
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"fusion/internal/api"
	"io"
	"net/http"
	"os"
	"os/exec"
	"sort"
	"strings"
	"testing"
	"time"
)

const (
	serverAddr      = "http://192.168.64.100:8080"
	jsonContentType = "application/json"
)

// ClusterConfig holds the test configuration for the cluster
type ClusterConfig struct {
	nodes []clusterNode
	vip   string
}

// Package level variables
var (
	clusterConfig *ClusterConfig
)

// MultipassNode represents a node discovered from multipass
type MultipassNode struct {
	Name   string
	State  string
	IPAddr string
	Image  string
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
	t.Logf("\n=== Checking Cluster Connectivity ===")

	// Get cluster info from each node
	for _, node := range nodes {
		resp, err := http.Get(node.address)
		if err != nil {
			t.Logf("❌ Failed to connect to %s: %v", node.address, err)
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
			t.Logf("❌ Failed to decode response from %s: %v", node.address, err)
			continue
		}

		t.Logf("\nNode: %s", node.address)
		t.Logf("  ID: %s", info.NodeID)
		t.Logf("  Cluster Size: %d", info.ClusterSize)
		t.Logf("  Version: %s", info.Version)
		if len(info.Members) > 0 {
			t.Logf("  Known Members: %v", info.Members)
		}
	}
}

// DiscoverMultipassNodes discovers fusion nodes running in multipass
func DiscoverMultipassNodes(baseName string) ([]MultipassNode, error) {
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

// GetClusterConfig retrieves cluster configuration from environment, flags, or multipass
func GetClusterConfig() (*ClusterConfig, error) {
	var (
		nodesFlag    = flag.String("nodes", "", "Comma-separated list of node addresses (e.g., 192.168.64.229:8080,192.168.64.230:8080)")
		vipFlag      = flag.String("vip", "", "VIP address (e.g., 192.168.64.100:8080)")
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
		nodes, err := DiscoverMultipassNodes(baseName)
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
		for i, node := range nodes {
			addr := fmt.Sprintf("http://%s:%s", node.IPAddr, port)
			cfg.nodes = append(cfg.nodes, clusterNode{
				address: addr,
				nodeID:  fmt.Sprintf("node%d", i+1),
			})
		}

		// For auto-discovery, assume VIP is on .100 if not specified
		if vipEnv == "" && *vipFlag == "" {
			// Extract the subnet from the first node's IP
			parts := strings.Split(nodes[0].IPAddr, ".")
			if len(parts) == 4 {
				cfg.vip = fmt.Sprintf("http://%s.%s.%s.100:%s", parts[0], parts[1], parts[2], port)
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
					nodeID:  fmt.Sprintf("node%d", i+1),
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

// Pretty print the configuration for debugging
func (c *ClusterConfig) String() string {
	var b strings.Builder
	b.WriteString(fmt.Sprintf("VIP: %s\n", c.vip))
	b.WriteString("Nodes:\n")
	for i, node := range c.nodes {
		b.WriteString(fmt.Sprintf("  %d: %s (ID: %s)\n", i+1, node.address, node.nodeID))
	}
	return b.String()
}

func TestMain(m *testing.M) {
	cfg, err := GetClusterConfig()
	if err != nil {
		fmt.Printf("Failed to get cluster configuration: %v\n", err)
		os.Exit(1)
	}

	// Print configuration for debugging
	fmt.Printf("Test Configuration:\n%s\n", cfg)

	clusterConfig = cfg
	os.Exit(m.Run())
}

func TestSetValue(t *testing.T) {
	tests := []struct {
		name       string
		payload    map[string]interface{}
		wantStatus int
	}{
		{
			name: "Valid key-value pair",
			payload: map[string]interface{}{
				"test_key": "test_value",
			},
			wantStatus: http.StatusOK,
		},
		{
			name:       "Empty object",
			payload:    map[string]interface{}{},
			wantStatus: http.StatusOK,
		},
		{
			name: "Multiple keys",
			payload: map[string]interface{}{
				"key1": "value1",
				"key2": "value2",
			},
			wantStatus: http.StatusOK,
		},
		{
			name: "Complex value",
			payload: map[string]interface{}{
				"complex": map[string]interface{}{
					"nested": "value",
					"array":  []string{"one", "two", "three"},
					"number": 42,
				},
			},
			wantStatus: http.StatusOK,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			jsonData, err := json.Marshal(tt.payload)
			if err != nil {
				t.Fatalf("Failed to marshal payload: %v", err)
			}

			resp, err := http.Post(fmt.Sprintf("%s/setValue", serverAddr),
				jsonContentType,
				bytes.NewBuffer(jsonData))
			if err != nil {
				t.Fatalf("Failed to send request: %v", err)
			}
			defer resp.Body.Close()

			if resp.StatusCode != tt.wantStatus {
				t.Errorf("SetValue returned wrong status code: got %v want %v",
					resp.StatusCode, tt.wantStatus)
			}

			if resp.StatusCode == http.StatusOK {
				var response struct {
					Status  string                 `json:"status"`
					Message string                 `json:"message"`
					Data    map[string]interface{} `json:"data"`
				}
				if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
					t.Fatalf("Failed to decode response: %v", err)
				}
				if response.Status != "success" {
					t.Errorf("Unexpected response status: %v", response.Status)
				}
			}
		})
	}
}

func TestGetValue(t *testing.T) {
	// First set some test data
	testData := map[string]interface{}{
		"test_key": "test_value",
	}
	jsonData, _ := json.Marshal(testData)
	_, err := http.Post(fmt.Sprintf("%s/setValue", serverAddr),
		jsonContentType,
		bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set test data: %v", err)
	}

	tests := []struct {
		name       string
		key        string
		wantStatus int
		wantExists bool
	}{
		{
			name:       "Existing key",
			key:        "test_key",
			wantStatus: http.StatusOK,
			wantExists: true,
		},
		{
			name:       "Non-existent key",
			key:        "nonexistent_key",
			wantStatus: http.StatusOK,
			wantExists: false,
		},
		{
			name:       "Get full state",
			key:        "",
			wantStatus: http.StatusOK,
			wantExists: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			url := fmt.Sprintf("%s/getValue", serverAddr)
			if tt.key != "" {
				url += fmt.Sprintf("?key=%s", tt.key)
			}

			resp, err := http.Get(url)
			if err != nil {
				t.Fatalf("Failed to send request: %v", err)
			}
			defer resp.Body.Close()

			if resp.StatusCode != tt.wantStatus {
				t.Errorf("GetValue returned wrong status code: got %v want %v",
					resp.StatusCode, tt.wantStatus)
			}

			var data map[string]interface{}
			if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
				t.Fatalf("Failed to decode response: %v", err)
			}

			if tt.key != "" {
				if data["exists"] != tt.wantExists {
					t.Errorf("Unexpected exists value: got %v want %v", data["exists"], tt.wantExists)
				}
			} else {
				// For full state request, just verify we got a non-empty map
				if len(data) == 0 {
					t.Error("Empty state response")
				}
			}
		})
	}
}

func TestUpdateValue(t *testing.T) {
	// Set initial value
	initialValue := map[string]interface{}{
		"update_test_key": "initial_value",
	}
	jsonData, err := json.Marshal(initialValue)
	if err != nil {
		t.Fatalf("Failed to marshal initial value: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/setValue", serverAddr),
		jsonContentType,
		bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial value: %v", err)
	}
	resp.Body.Close()

	// Verify initial value was set
	getValue, err := http.Get(fmt.Sprintf("%s/getValue?key=update_test_key", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get initial value: %v", err)
	}

	var initialResponse struct {
		Exists bool        `json:"exists"`
		Value  interface{} `json:"value"`
	}
	if err := json.NewDecoder(getValue.Body).Decode(&initialResponse); err != nil {
		t.Fatalf("Failed to decode initial get response: %v", err)
	}
	getValue.Body.Close()

	if !initialResponse.Exists {
		t.Fatal("Initial value was not set")
	}
	if initialResponse.Value != "initial_value" {
		t.Errorf("Wrong initial value: got %v, want initial_value", initialResponse.Value)
	}

	// Update the value
	updatedValue := map[string]interface{}{
		"update_test_key": "updated_value",
	}
	jsonData, err = json.Marshal(updatedValue)
	if err != nil {
		t.Fatalf("Failed to marshal updated value: %v", err)
	}

	resp, err = http.Post(fmt.Sprintf("%s/setValue", serverAddr),
		jsonContentType,
		bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to update value: %v", err)
	}
	resp.Body.Close()

	// Verify the update
	getValue, err = http.Get(fmt.Sprintf("%s/getValue?key=update_test_key", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get updated value: %v", err)
	}

	var updatedResponse struct {
		Exists bool        `json:"exists"`
		Value  interface{} `json:"value"`
	}
	if err := json.NewDecoder(getValue.Body).Decode(&updatedResponse); err != nil {
		t.Fatalf("Failed to decode updated get response: %v", err)
	}
	getValue.Body.Close()

	if !updatedResponse.Exists {
		t.Fatal("Updated value does not exist")
	}
	if updatedResponse.Value != "updated_value" {
		t.Errorf("Wrong updated value: got %v, want updated_value", updatedResponse.Value)
	}
}

func TestUploadDownloadJSON(t *testing.T) {
	// First set some test data
	initialData := map[string]interface{}{
		"upload_test": "initial_value",
	}
	jsonData, _ := json.Marshal(initialData)
	_, err := http.Post(fmt.Sprintf("%s/setValue", serverAddr),
		jsonContentType,
		bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial data: %v", err)
	}

	// Download current state
	resp, err := http.Get(fmt.Sprintf("%s/download", serverAddr))
	if err != nil {
		t.Fatalf("Failed to download state: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Download returned wrong status: got %v want %v",
			resp.StatusCode, http.StatusOK)
	}

	// Set up new state values to upload
	newState := map[string]*api.StateEntry{
		"upload_test": {
			Data: "modified_value",
		},
		"new_key": {
			Data: "new_value",
		},
	}

	// Upload modified state
	uploadPayload := struct {
		State map[string]*api.StateEntry `json:"state"`
	}{
		State: newState,
	}

	uploadData, err := json.Marshal(uploadPayload)
	if err != nil {
		t.Fatalf("Failed to marshal upload data: %v", err)
	}

	uploadResp, err := http.Post(fmt.Sprintf("%s/upload", serverAddr),
		jsonContentType,
		bytes.NewBuffer(uploadData))
	if err != nil {
		t.Fatalf("Failed to upload state: %v", err)
	}
	defer uploadResp.Body.Close()

	if uploadResp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(uploadResp.Body)
		t.Errorf("Upload returned wrong status: got %v want %v. Body: %s",
			uploadResp.StatusCode, http.StatusOK, string(body))
		return
	}

	// Verify uploaded data
	getResp, err := http.Get(fmt.Sprintf("%s/getValue", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get state after upload: %v", err)
	}
	defer getResp.Body.Close()

	var finalState map[string]interface{}
	if err := json.NewDecoder(getResp.Body).Decode(&finalState); err != nil {
		t.Fatalf("Failed to decode final state: %v", err)
	}

	// Check if uploaded values are present with raw values
	expectedValues := map[string]interface{}{
		"upload_test": "modified_value",
		"new_key":     "new_value",
	}

	for key, value := range expectedValues {
		if finalState[key] != value {
			t.Errorf("Mismatch for key %s: got %v, want %v",
				key, finalState[key], value)
		}
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

	var response map[string]interface{}
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

// clusterNode represents a node in the test cluster
type clusterNode struct {
	address string
	nodeID  string
}

// requiredNodes is the number of nodes required for cluster tests
const requiredNodes = 3

// verifyClusterHealth checks if the required number of nodes are running and healthy
func verifyClusterHealth(t *testing.T, nodes []clusterNode) bool {
	t.Helper()

	timeout := 10 * time.Second
	t.Logf("Verifying cluster health across %d nodes...", len(nodes))

	deadline := time.Now().Add(timeout)
	ticker := time.NewTicker(time.Second)
	defer ticker.Stop()

	for time.Now().Before(deadline) {
		for i, node := range nodes {
			size, err := getClusterSize(node)
			if err == nil {
				if size >= requiredNodes {
					t.Logf("✓ Cluster is healthy with %d nodes", size)
					return true
				}
				t.Logf("Node %d reports cluster size %d/%d", i+1, size, requiredNodes)
			} else {
				t.Logf("Node %d health check failed: %v", i+1, err)
			}
		}
		<-ticker.C
		t.Logf("Still waiting for cluster health... %v remaining", time.Until(deadline).Round(time.Second))
	}

	t.Errorf("Cluster health check failed after %v", timeout)
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
		value        interface{}
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
			timeout:      5 * time.Second,
		},
		{
			name:         "Complex object sync",
			key:          "test_sync_object",
			value:        map[string]interface{}{"nested": "value", "number": 42},
			updateNode:   1,
			verifyNodes:  []int{0, 2},
			expectedSync: true,
			timeout:      5 * time.Second,
		},
		{
			name:         "Array value sync",
			key:          "test_sync_array",
			value:        []string{"one", "two", "three"},
			updateNode:   2,
			verifyNodes:  []int{0, 1},
			expectedSync: true,
			timeout:      5 * time.Second,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Logf("TEST: %s", tt.name)
			t.Logf("  Node: %s", testNodes[tt.updateNode])

			err := setValueOnNode(testNodes[tt.updateNode], tt.key, tt.value)
			if err != nil {
				t.Fatalf("Failed to set value on node %d: %v", tt.updateNode, err)
			}

			success := waitForSync(tt.timeout, func() bool {
				for _, nodeIdx := range tt.verifyNodes {
					t.Logf("    Checking: %s", testNodes[nodeIdx])
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
		value     interface{}
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

	t.Log("Waiting for initial state sync...")
	initialSyncTime := 5 * time.Second
	logProgress(t, "Initial sync", initialSyncTime)

	states := make([]map[string]interface{}, len(testNodes))
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

	t.Logf("Successfully verified state consistency across nodes")
}

// TestClearEndpoint verifies that data is cleared on all nodes
func TestClearEndpoint(t *testing.T) {
	nodes := clusterConfig.nodes
	if len(nodes) < 3 {
		t.Fatalf("Test requires at least 3 nodes, but only %d available", len(nodes))
	}

	testNodes := nodes[:3]
	if !verifyClusterHealth(t, testNodes) {
		t.Fatal("Cluster health check failed - requires 3 running nodes")
	}

	// Set test data on each node
	testData := []struct {
		key   string
		value interface{}
	}{
		{"clear_test_1", "value1"},
		{"clear_test_2", 42},
		{"clear_test_3", map[string]interface{}{"nested": "value"}},
	}

	// Set values on first node
	for _, td := range testData {
		err := setValueOnNode(testNodes[0], td.key, td.value)
		if err != nil {
			t.Fatalf("Failed to set test data: %v", err)
		}
	}

	// Wait for sync
	t.Log("Waiting for initial state sync...")
	success := waitForSync(5*time.Second, func() bool {
		for _, node := range testNodes {
			state, err := getFullStateFromNode(node)
			if err != nil {
				return false
			}
			for _, td := range testData {
				if _, exists := state[td.key]; !exists {
					return false
				}
			}
		}
		return true
	})

	if !success {
		t.Fatal("Failed to sync initial test data")
	}

	// Call clear on first node
	req, err := http.NewRequest(http.MethodDelete, fmt.Sprintf("%s/clear", testNodes[0].address), nil)
	if err != nil {
		t.Fatalf("Failed to create DELETE request: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Failed to call clear endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Clear endpoint returned wrong status: got %v want %v",
			resp.StatusCode, http.StatusOK)
	}

	// Verify all nodes are cleared
	success = waitForSync(5*time.Second, func() bool {
		for i, node := range testNodes {
			state, err := getFullStateFromNode(node)
			if err != nil {
				t.Logf("Failed to get state from node %d: %v", i, err)
				return false
			}
			if len(state) > 0 {
				t.Logf("Node %d still has %d entries", i, len(state))
				return false
			}
		}
		return true
	})

	if !success {
		t.Error("Failed to clear state across all nodes")
		// Dump final state of all nodes for debugging
		for i, node := range testNodes {
			state, err := getFullStateFromNode(node)
			if err != nil {
				t.Logf("Failed to get state from node %d: %v", i, err)
				continue
			}
			prettyState, _ := json.MarshalIndent(state, "", "  ")
			t.Logf("Node %d final state:\n%s", i, string(prettyState))
		}
	}
}

func setValueOnNode(node clusterNode, key string, value interface{}) error {
	// Create direct JSON format
	payload := map[string]interface{}{
		key: value,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/setValue", node.address),
		jsonContentType, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	return nil
}

func getValueFromNode(node clusterNode, key string) (interface{}, bool, error) {
	resp, err := http.Get(fmt.Sprintf("%s/getValue?key=%s", node.address, key))
	if err != nil {
		return nil, false, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()

	var response struct {
		Exists bool        `json:"exists"`
		Key    string      `json:"key"`
		Value  interface{} `json:"value,omitempty"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, false, fmt.Errorf("failed to decode response: %v", err)
	}

	if !response.Exists {
		return nil, false, nil
	}

	return response.Value, true, nil
}

func getFullStateFromNode(node clusterNode) (map[string]interface{}, error) {
	resp, err := http.Get(fmt.Sprintf("%s/getValue", node.address))
	if err != nil {
		return nil, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()

	var state map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&state); err != nil {
		return nil, fmt.Errorf("failed to decode response: %v", err)
	}

	return state, nil
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

func valueEquals(v1, v2 interface{}) bool {
	// Handle nil cases explicitly
	if v1 == nil && v2 == nil {
		return true
	}
	if v1 == nil || v2 == nil {
		return false
	}

	// Check if v1 is a map that might contain our value
	if m1, ok := v1.(map[string]interface{}); ok {
		if val, exists := m1["value"]; exists {
			v1 = val
		}
	}

	// Check if v2 is a map that might contain our value
	if m2, ok := v2.(map[string]interface{}); ok {
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
