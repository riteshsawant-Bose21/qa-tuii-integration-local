package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"net/http"
	"testing"
	"time"
)

const (
	serverAddr = "http://192.168.64.100:8080"
)

func TestSetValue(t *testing.T) {
	tests := []struct {
		name       string
		payload    map[string]interface{}
		wantStatus int
	}{
		{
			name: "Valid key-value pair",
			payload: map[string]interface{}{
				"key":   "test_key",
				"value": "test_value",
			},
			wantStatus: http.StatusOK,
		},
		{
			name: "Empty key",
			payload: map[string]interface{}{
				"key":   "",
				"value": "test_value",
			},
			wantStatus: http.StatusBadRequest,
		},
		{
			name: "Missing key field",
			payload: map[string]interface{}{
				"value": "test_value",
			},
			wantStatus: http.StatusBadRequest,
		},
		{
			name: "Complex value",
			payload: map[string]interface{}{
				"key": "complex_key",
				"value": map[string]interface{}{
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
				"application/json",
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
				var response map[string]string
				if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
					t.Fatalf("Failed to decode response: %v", err)
				}
				if response["status"] != "update stored and broadcasted" {
					t.Errorf("Unexpected response status: %v", response["status"])
				}
			}
		})
	}
}

func TestGetValue(t *testing.T) {
	// First set some test data
	testData := map[string]interface{}{
		"key":   "get_test_key",
		"value": "get_test_value",
	}
	jsonData, _ := json.Marshal(testData)
	_, err := http.Post(fmt.Sprintf("%s/setValue", serverAddr),
		"application/json",
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
			key:        "get_test_key",
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

			var response map[string]interface{}
			if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
				t.Fatalf("Failed to decode response: %v", err)
			}

			if tt.key != "" {
				exists, ok := response["exists"].(bool)
				if !ok {
					t.Fatalf("Response missing 'exists' field")
				}
				if exists != tt.wantExists {
					t.Errorf("Unexpected exists value: got %v want %v", exists, tt.wantExists)
				}
			} else {
				// Check full state response
				if _, ok := response["version"]; !ok {
					t.Error("Full state response missing version field")
				}
				if _, ok := response["state"]; !ok {
					t.Error("Full state response missing state field")
				}
			}
		})
	}
}

func TestUploadDownloadJSON(t *testing.T) {
	// First download the current state
	resp, err := http.Get(fmt.Sprintf("%s/download", serverAddr))
	if err != nil {
		t.Fatalf("Failed to download initial state: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Download returned wrong status: got %v want %v",
			resp.StatusCode, http.StatusOK)
	}

	var initialState map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&initialState); err != nil {
		t.Fatalf("Failed to decode initial state: %v", err)
	}

	// Modify the state
	initialState["test_key"] = "test_value"
	initialState["timestamp"] = time.Now()

	// Upload the modified state
	jsonData, err := json.Marshal(initialState)
	if err != nil {
		t.Fatalf("Failed to marshal modified state: %v", err)
	}

	uploadResp, err := http.Post(fmt.Sprintf("%s/upload", serverAddr),
		"application/json",
		bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to upload modified state: %v", err)
	}
	defer uploadResp.Body.Close()

	if uploadResp.StatusCode != http.StatusOK {
		t.Errorf("Upload returned wrong status: got %v want %v",
			uploadResp.StatusCode, http.StatusOK)
	}

	// Verify upload response
	var uploadResponse map[string]interface{}
	if err := json.NewDecoder(uploadResp.Body).Decode(&uploadResponse); err != nil {
		t.Fatalf("Failed to decode upload response: %v", err)
	}
	if uploadResponse["status"] != "import complete" {
		t.Errorf("Unexpected upload response status: %v", uploadResponse["status"])
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

	// Try each node until we find one that responds
	var clusterSize int
	var lastErr error
	deadline := time.Now().Add(10 * time.Second)

	for time.Now().Before(deadline) {
		for _, node := range nodes {
			size, err := getClusterSize(node)
			if err == nil {
				clusterSize = size
				if clusterSize >= requiredNodes {
					t.Logf("Cluster is healthy with %d nodes", clusterSize)
					return true
				}
				t.Logf("Insufficient cluster size: got %d, want %d", clusterSize, requiredNodes)
				// Don't break here, try other nodes
				continue
			}
			lastErr = err
		}
		time.Sleep(time.Second)
	}

	if lastErr != nil {
		t.Errorf("Failed to connect to any cluster node: %v", lastErr)
	} else {
		t.Errorf("Cluster too small: got %d nodes, want %d", clusterSize, requiredNodes)
	}
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
	nodes := []clusterNode{
		{address: "http://192.168.64.100:8080", nodeID: "node1"},
		{address: "http://192.168.64.101:8080", nodeID: "node2"},
		{address: "http://192.168.64.102:8080", nodeID: "node3"},
	}

	// Verify cluster health before running tests
	if !verifyClusterHealth(t, nodes) {
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
			// Set value on the update node
			err := setValueOnNode(nodes[tt.updateNode], tt.key, tt.value)
			if err != nil {
				t.Fatalf("Failed to set value on node %d: %v", tt.updateNode, err)
			}

			// Wait for sync and verify on other nodes
			success := waitForSync(tt.timeout, func() bool {
				for _, nodeIdx := range tt.verifyNodes {
					value, exists, err := getValueFromNode(nodes[nodeIdx], tt.key)
					if err != nil {
						t.Logf("Error getting value from node %d: %v", nodeIdx, err)
						return false
					}
					if !exists {
						t.Logf("Value doesn't exist on node %d", nodeIdx)
						return false
					}
					if !valueEquals(value, tt.value) {
						t.Logf("Value mismatch on node %d: got %v, want %v", nodeIdx, value, tt.value)
						return false
					}
				}
				return true
			})

			if !success && tt.expectedSync {
				t.Errorf("Failed to sync state across cluster within timeout")
			}
		})
	}
}

// TestStateConsistency verifies that the entire state is consistent
func TestStateConsistency(t *testing.T) {
	nodes := []clusterNode{
		{address: "http://192.168.64.100:8080", nodeID: "node1"},
		{address: "http://192.168.64.101:8080", nodeID: "node2"},
		{address: "http://192.168.64.102:8080", nodeID: "node3"},
	}

	// Verify cluster health before running tests
	if !verifyClusterHealth(t, nodes) {
		t.Fatal("Cluster health check failed - requires 3 running nodes")
	}

	// First, set some test data on different nodes
	testData := []struct {
		nodeIndex int
		key       string
		value     interface{}
	}{
		{0, "consistency_test_1", "value1"},
		{1, "consistency_test_2", 42},
		{2, "consistency_test_3", []string{"a", "b", "c"}},
	}

	// Set test data
	for _, td := range testData {
		err := setValueOnNode(nodes[td.nodeIndex], td.key, td.value)
		if err != nil {
			t.Fatalf("Failed to set test data on node %d: %v", td.nodeIndex, err)
		}
	}

	// Wait for initial sync
	time.Sleep(5 * time.Second)

	// Get full state from all nodes
	states := make([]map[string]*api.StateEntry, len(nodes))
	versions := make([]int64, len(nodes))

	for i, node := range nodes {
		var err error
		states[i], versions[i], err = getFullStateFromNode(node)
		if err != nil {
			t.Fatalf("Failed to get state from node %d: %v", i, err)
		}
	}

	// Verify states match
	for key := range states[0] {
		for i := 1; i < len(states); i++ {
			entry1 := states[0][key]
			entry2 := states[i][key]

			if entry2 == nil {
				t.Errorf("Key %s missing on node %d", key, i)
				continue
			}

			if !valueEquals(entry1.Value, entry2.Value) {
				t.Errorf("State mismatch for key %s between node 0 and node %d", key, i)
			}
		}
	}
}

// Helper functions remain the same but with improved error handling
func setValueOnNode(node clusterNode, key string, value interface{}) error {
	payload := map[string]interface{}{
		"key":   key,
		"value": value,
	}
	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/setValue", node.address),
		"application/json", bytes.NewBuffer(jsonData))
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

	var response map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, false, fmt.Errorf("failed to decode response: %v", err)
	}

	exists, ok := response["exists"].(bool)
	if !ok {
		return nil, false, fmt.Errorf("missing or invalid 'exists' field in response")
	}
	if !exists {
		return nil, false, nil
	}

	value, ok := response["value"]
	if !ok {
		return nil, false, fmt.Errorf("missing 'value' field in response")
	}

	return value, true, nil
}

func getFullStateFromNode(node clusterNode) (map[string]*api.StateEntry, int64, error) {
	resp, err := http.Get(fmt.Sprintf("%s/getValue", node.address))
	if err != nil {
		return nil, 0, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()

	var response struct {
		Version int64                      `json:"version"`
		State   map[string]*api.StateEntry `json:"state"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, 0, fmt.Errorf("failed to decode response: %v", err)
	}

	if response.State == nil {
		return nil, 0, fmt.Errorf("node returned nil state")
	}

	return response.State, response.Version, nil
}

func waitForSync(timeout time.Duration, check func() bool) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if check() {
			return true
		}
		time.Sleep(100 * time.Millisecond)
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

	// Convert both values to JSON for deep comparison
	j1, err1 := json.Marshal(v1)
	j2, err2 := json.Marshal(v2)
	if err1 != nil || err2 != nil {
		return false
	}
	return bytes.Equal(j1, j2)
}
