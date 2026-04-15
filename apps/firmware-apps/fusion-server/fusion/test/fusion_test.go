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
)

var (
	clusterConfig *ClusterConfig
	nodesFlag     = flag.String("nodes", "", "Comma-separated list of node addresses (e.g., 192.168.64.229:8080,192.168.64.230:8080)")
	vipFlag       = flag.String("vip", "", "VIP address (e.g., 192.168.2.100:8080)")
	baseNameFlag  = flag.String("base-name", "fusion", "Base name for multipass instances")
	portFlag      = flag.String("port", "8080", "Port for node services")
	autoFlag      = flag.Bool("auto", false, "Automatically discover nodes using multipass")
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

func TestSetValue(t *testing.T) {
	tests := []struct {
		name       string
		payload    map[string]any
		wantStatus int
	}{
		{
			name: "Valid key-value pair",
			payload: map[string]any{
				"test_key": "test_value",
			},
			wantStatus: http.StatusOK,
		},
		{
			name:       "Empty object",
			payload:    map[string]any{},
			wantStatus: http.StatusOK,
		},
		{
			name: "Multiple keys",
			payload: map[string]any{
				"key1": "value1",
				"key2": "value2",
			},
			wantStatus: http.StatusOK,
		},
		{
			name: "Complex value",
			payload: map[string]any{
				"complex": map[string]any{
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

			resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr),
				api.JsonMIMEType,
				bytes.NewBuffer(jsonData))
			if err != nil {
				t.Fatalf("Failed to send request: %v", err)
			}
			defer resp.Body.Close()

			if resp.StatusCode != tt.wantStatus {
				t.Errorf("Value returned wrong status code: got %v want %v",
					resp.StatusCode, tt.wantStatus)
			}

			if resp.StatusCode == http.StatusOK {
				var response struct {
					Status  string         `json:"status"`
					Message string         `json:"message"`
					Data    map[string]any `json:"data"`
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
	testData := map[string]any{
		"test_key": "test_value",
	}
	jsonData, _ := json.Marshal(testData)
	_, err := http.Post(fmt.Sprintf("%s/value", serverAddr),
		api.JsonMIMEType,
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
			url := fmt.Sprintf("%s/value", serverAddr)
			if tt.key != "" {
				url += fmt.Sprintf("?key=%s", tt.key)
			}

			resp, err := http.Get(url)
			if err != nil {
				t.Fatalf("Failed to send request: %v", err)
			}
			defer resp.Body.Close()

			if resp.StatusCode != tt.wantStatus {
				t.Errorf("Value returned wrong status code: got %v want %v",
					resp.StatusCode, tt.wantStatus)
			}

			var data map[string]any
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
	initialValue := map[string]any{
		"update_test_key": "initial_value",
	}
	jsonData, err := json.Marshal(initialValue)
	if err != nil {
		t.Fatalf("Failed to marshal initial value: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr),
		api.JsonMIMEType,
		bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial value: %v", err)
	}
	resp.Body.Close()

	// Verify initial value was set
	getValue, err := http.Get(fmt.Sprintf("%s/value?key=update_test_key", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get initial value: %v", err)
	}

	var initialResponse struct {
		Exists bool `json:"exists"`
		Value  any  `json:"value"`
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
	updatedValue := map[string]any{
		"update_test_key": "updated_value",
	}
	jsonData, err = json.Marshal(updatedValue)
	if err != nil {
		t.Fatalf("Failed to marshal updated value: %v", err)
	}

	resp, err = http.Post(fmt.Sprintf("%s/value", serverAddr),
		api.JsonMIMEType,
		bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to update value: %v", err)
	}
	resp.Body.Close()

	// Verify the update
	getValue, err = http.Get(fmt.Sprintf("%s/value?key=update_test_key", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get updated value: %v", err)
	}

	var updatedResponse struct {
		Exists bool `json:"exists"`
		Value  any  `json:"value"`
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

func TestSetAndUpdateValues(t *testing.T) {
	// Set the initial value with nested vectors
	initialValue := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"tone_eq1": map[string]any{
					"low_gain":    3.0,
					"high_gain":   4.0,
					"frequencies": []float64{100.0, 200.0, 300.0},
				},
			},
		},
	}
	jsonData, err := json.Marshal(initialValue)
	if err != nil {
		t.Fatalf("Failed to marshal initial value: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr), api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial value: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code: %d, response: %s", resp.StatusCode, string(body))
	}

	// Verify the initial value
	getValue, err := http.Get(fmt.Sprintf("%s/value?key=settings.audio.tone_eq1", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get initial value: %v", err)
	}
	defer getValue.Body.Close()

	var initialResponse struct {
		Exists bool           `json:"exists"`
		Value  map[string]any `json:"value"`
	}
	if err := json.NewDecoder(getValue.Body).Decode(&initialResponse); err != nil {
		t.Fatalf("Failed to decode initial get response: %v", err)
	}

	if !initialResponse.Exists {
		t.Fatal("Initial value was not set")
	}

	// Verify numeric arrays
	frequencies, ok := initialResponse.Value["frequencies"].([]any)
	if !ok || len(frequencies) != 3 || frequencies[0] != 100.0 {
		t.Errorf("Frequencies mismatch: got %v", frequencies)
	}

	// Update the value with `null` for `high_gain` and update `frequencies`
	updatedValue := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"tone_eq1": map[string]any{
					"high_gain":   nil,
					"frequencies": []float64{400.0, 500.0},
				},
			},
		},
	}
	jsonData, err = json.Marshal(updatedValue)
	if err != nil {
		t.Fatalf("Failed to marshal updated value: %v", err)
	}

	req, err := http.NewRequest("PATCH", fmt.Sprintf("%s/value", serverAddr), bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to create PATCH request: %v", err)
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to update value: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code: %d, response: %s", resp.StatusCode, string(body))
	}

	// Verify the update
	getValue, err = http.Get(fmt.Sprintf("%s/value?key=settings.audio.tone_eq1", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get updated value: %v", err)
	}
	defer getValue.Body.Close()

	var updatedResponse struct {
		Exists bool           `json:"exists"`
		Value  map[string]any `json:"value"`
	}
	if err := json.NewDecoder(getValue.Body).Decode(&updatedResponse); err != nil {
		t.Fatalf("Failed to decode updated get response: %v", err)
	}

	if !updatedResponse.Exists {
		t.Fatal("Updated value does not exist")
	}
	if _, exists := updatedResponse.Value["high_gain"]; exists {
		t.Errorf("high_gain key was not removed as expected: got %v", updatedResponse.Value)
	}
	if updatedResponse.Value["low_gain"] != 3.0 {
		t.Errorf("Wrong value for low_gain: got %v, want 3.0", updatedResponse.Value["low_gain"])
	}
	frequencies, ok = updatedResponse.Value["frequencies"].([]any)
	if !ok || len(frequencies) != 2 || frequencies[0] != 400.0 {
		t.Errorf("Frequencies update mismatch: got %v", frequencies)
	}
}

func TestPatchArrayElement(t *testing.T) {

	initialConfig := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"tone_eq1": map[string]any{
					"frequencies": []float64{100.0, 200.0, 300.0},
				},
			},
		},
	}
	jsonData, err := json.Marshal(initialConfig)
	if err != nil {
		t.Fatalf("Failed to marshal initial configuration: %v", err)
	}

	// Send initial configuration
	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr), api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code when setting initial config: %d, response: %s", resp.StatusCode, string(body))
	}

	// PATCH update an array element using query key parameter
	updateData := map[string]any{
		"value": 250.0, // Update index 1 of `frequencies` to 250.0
	}
	jsonUpdate, err := json.Marshal(updateData)
	if err != nil {
		t.Fatalf("Failed to marshal update data: %v", err)
	}

	req, err := http.NewRequest("PATCH", fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies[1]", serverAddr), bytes.NewBuffer(jsonUpdate))
	if err != nil {
		t.Fatalf("Failed to create PATCH request for updating array element: %v", err)
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to update array element: %v", err)
	}
	defer resp.Body.Close()

	// Verify update to array element
	getValue, err := http.Get(fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get updated array: %v", err)
	}
	defer getValue.Body.Close()

	var updatedResponse struct {
		Exists bool  `json:"exists"`
		Value  []any `json:"value"`
	}
	if err := json.NewDecoder(getValue.Body).Decode(&updatedResponse); err != nil {
		t.Fatalf("Failed to decode updated array response: %v", err)
	}

	if !updatedResponse.Exists {
		t.Fatal("Array does not exist after update")
	}
	if len(updatedResponse.Value) != 3 || updatedResponse.Value[1] != 250.0 {
		t.Errorf("Failed to update array element: expected %v, got %v", 250.0, updatedResponse.Value[1])
	}

	// PATCH insert a new element into the array at index 3
	insertData := map[string]any{
		"value": 400.0,
	}
	jsonInsert, err := json.Marshal(insertData)
	if err != nil {
		t.Fatalf("Failed to marshal insert data: %v", err)
	}

	req, err = http.NewRequest("PATCH", fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies[3]", serverAddr), bytes.NewBuffer(jsonInsert))
	if err != nil {
		t.Fatalf("Failed to create PATCH request for inserting array element: %v", err)
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to insert array element: %v", err)
	}
	defer resp.Body.Close()

	// Verify new insertion in `frequencies`
	getValue, err = http.Get(fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get inserted array element: %v", err)
	}
	defer getValue.Body.Close()

	if err := json.NewDecoder(getValue.Body).Decode(&updatedResponse); err != nil {
		t.Fatalf("Failed to decode inserted array response: %v", err)
	}

	if len(updatedResponse.Value) != 4 || updatedResponse.Value[3] != 400.0 {
		t.Errorf("Failed to insert new array element: expected %v at index 3, got %v", 400.0, updatedResponse.Value)
	}

	defer resp.Body.Close()
}

// TestPatchDiffOutput sets an initial configuration, performs PATCH updates,
// and asserts that the diff output only contains the changed elements.
func TestPatchDiffOutput(t *testing.T) {
	// Define the initial configuration.
	initialConfig := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"tone_eq1": map[string]any{
					"frequencies": []float64{100.0, 200.0, 300.0},
				},
			},
		},
	}

	// Marshal and send the initial configuration using the /value endpoint.
	jsonData, err := json.Marshal(initialConfig)
	if err != nil {
		t.Fatalf("Failed to marshal initial configuration: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr), api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code when setting initial config: %d, response: %s", resp.StatusCode, string(body))
	}

	updateData := map[string]any{
		"value": 250.0,
	}
	jsonUpdate, err := json.Marshal(updateData)
	if err != nil {
		t.Fatalf("Failed to marshal update data: %v", err)
	}

	// Use the query key to update the array element.
	patchURL := fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies[1]", serverAddr)
	req, err := http.NewRequest("PATCH", patchURL, bytes.NewBuffer(jsonUpdate))
	if err != nil {
		t.Fatalf("Failed to create PATCH request for updating array element: %v", err)
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	client := &http.Client{}
	resp, err = client.Do(req)
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

	// Verify the frequencies array update via the /value endpoint.
	getURL := fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies", serverAddr)
	resp, err = http.Get(getURL)
	if err != nil {
		t.Fatalf("Failed to get updated frequencies array: %v", err)
	}
	defer resp.Body.Close()

	var getResp struct {
		Exists bool  `json:"exists"`
		Value  []any `json:"value"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&getResp); err != nil {
		t.Fatalf("Failed to decode get response: %v", err)
	}
	if !getResp.Exists {
		t.Fatal("Frequencies array does not exist after update")
	}
	if len(getResp.Value) != 3 || getResp.Value[1] != 250.0 {
		t.Errorf("Failed to update frequencies array: expected index 1 to be %v, got %v", 250.0, getResp.Value[1])
	}

	defer resp.Body.Close()
}

// TestPatchOutOfBounds verifies that an update using an out‐of‑bound array index
// expands the array. For an initial array [100, 200, 300], updating index 5 with 500
// should yield [100, 200, 300, nil, nil, 500].
func TestPatchOutOfBounds(t *testing.T) {
	// Set initial configuration with an array of three elements.
	initialConfig := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"tone_eq1": map[string]any{
					"frequencies": []float64{100.0, 200.0, 300.0},
				},
			},
		},
	}
	jsonData, err := json.Marshal(initialConfig)
	if err != nil {
		t.Fatalf("Failed to marshal initial configuration: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr), api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code when setting initial config: %d, response: %s", resp.StatusCode, string(body))
	}

	// Attempt to update an element at index 5 (which is out-of-bound for an array of length 3).
	updateData := map[string]any{
		"value": 500.0,
	}
	jsonUpdate, err := json.Marshal(updateData)
	if err != nil {
		t.Fatalf("Failed to marshal update data: %v", err)
	}

	req, err := http.NewRequest("PATCH", fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies[5]", serverAddr), bytes.NewBuffer(jsonUpdate))
	if err != nil {
		t.Fatalf("Failed to create PATCH request for out-of-bound update: %v", err)
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to execute PATCH request for out-of-bound update: %v", err)
	}
	defer resp.Body.Close()

	// The current implementation returns 200.
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Unexpected status code for out-of-bound update: got %d", resp.StatusCode)
	}

	// Verify that the array is expanded.
	getValue, err := http.Get(fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get updated array: %v", err)
	}
	defer getValue.Body.Close()

	var updatedResponse struct {
		Exists bool  `json:"exists"`
		Value  []any `json:"value"`
	}
	if err := json.NewDecoder(getValue.Body).Decode(&updatedResponse); err != nil {
		t.Fatalf("Failed to decode updated array response: %v", err)
	}

	if !updatedResponse.Exists {
		t.Fatal("Array does not exist after out-of-bound update")
	}

	// Expecting that the array is expanded to length 6 with nil placeholders.
	expected := []any{100.0, 200.0, 300.0, nil, nil, 500.0}
	if !reflect.DeepEqual(updatedResponse.Value, expected) {
		t.Errorf("Out-of-bound update expected array %v, got %v", expected, updatedResponse.Value)
	}
}

// TestPatchRemoveArrayElement verifies that when patching an array element with a JSON null,
// the element is set to null while the array length remains unchanged. For an initial array
// [100, 200, 300], patching index 1 should yield [100, nil, 300].
func TestPatchRemoveArrayElement(t *testing.T) {
	// Set initial configuration with an array of three elements.
	initialConfig := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"tone_eq1": map[string]any{
					"frequencies": []float64{100.0, 200.0, 300.0},
				},
			},
		},
	}
	jsonData, err := json.Marshal(initialConfig)
	if err != nil {
		t.Fatalf("Failed to marshal initial configuration: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr), api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set initial configuration: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code when setting initial config: %d, response: %s", resp.StatusCode, string(body))
	}

	// PATCH update: set the element at index 1 to null.
	removeData := map[string]any{
		"value": nil,
	}
	jsonRemove, err := json.Marshal(removeData)
	if err != nil {
		t.Fatalf("Failed to marshal removal data: %v", err)
	}

	req, err := http.NewRequest("PATCH", fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies[1]", serverAddr), bytes.NewBuffer(jsonRemove))
	if err != nil {
		t.Fatalf("Failed to create PATCH request for removing array element: %v", err)
	}
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send PATCH request for removal: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code for removal: %d, response: %s", resp.StatusCode, string(body))
	}

	// Verify that the element at index 1 has been set to null.
	getValue, err := http.Get(fmt.Sprintf("%s/value?key=settings.audio.tone_eq1.frequencies", serverAddr))
	if err != nil {
		t.Fatalf("Failed to get updated array: %v", err)
	}
	defer getValue.Body.Close()

	var updatedResponse struct {
		Exists bool  `json:"exists"`
		Value  []any `json:"value"`
	}
	if err := json.NewDecoder(getValue.Body).Decode(&updatedResponse); err != nil {
		t.Fatalf("Failed to decode updated array response: %v", err)
	}

	if !updatedResponse.Exists {
		t.Fatal("Array does not exist after removal update")
	}

	// Expecting that the array remains length 3 with the second element set to nil.
	expected := []any{100.0, nil, 300.0}
	if !reflect.DeepEqual(updatedResponse.Value, expected) {
		t.Errorf("Expected updated array %v, got %v", expected, updatedResponse.Value)
	}
}

// TestConcurrentPatchRequests tests multiple concurrent PATCH requests
func TestConcurrentPatchRequests(t *testing.T) {

	// Initial config with nested maps and arrays
	initialConfig := map[string]any{
		"settings": map[string]any{
			"audio": map[string]any{
				"eq": map[string]any{
					"bands": []float64{100.0, 200.0, 300.0},
				},
			},
		},
	}

	jsonData, _ := json.Marshal(initialConfig)
	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr), api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("failed to set initial configuration: %v", err)
	}
	resp.Body.Close()

	// Prepare concurrent updates
	client := &http.Client{}
	const numWorkers = 10
	const numRequests = 50
	errCh := make(chan error, numWorkers*numRequests)
	var wg sync.WaitGroup

	for w := range numWorkers {
		wg.Add(1)
		go func(worker int) {
			defer wg.Done()
			for i := range numRequests {
				updateData := map[string]any{
					"value": float64(100 + worker + i),
				}
				jsonUpdate, _ := json.Marshal(updateData)

				req, _ := http.NewRequest("PATCH",
					fmt.Sprintf("%s/value?key=settings.audio.eq.bands[%d]", serverAddr, i%3),
					bytes.NewBuffer(jsonUpdate))
				req.Header.Set(api.ContentType, api.JsonMIMEType)

				resp, err := client.Do(req)
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
	getResp, err := http.Get(fmt.Sprintf("%s/value?key=settings.audio.eq.bands", serverAddr))
	if err != nil {
		t.Fatalf("failed to get final array: %v", err)
	}
	defer getResp.Body.Close()

	var finalResp struct {
		Exists bool      `json:"exists"`
		Value  []float64 `json:"value"`
	}
	if err := json.NewDecoder(getResp.Body).Decode(&finalResp); err != nil {
		t.Fatalf("failed to decode final array: %v", err)
	}

	if !finalResp.Exists {
		t.Error("final array missing after concurrent patches")
	}
}

// TestPostValueOnNonVIPNode sets a value via POST on a non-VIP node
// and then verifies it through the VIP endpoint.
func TestPostValueOnNonVIPNode(t *testing.T) {
	// pick a non-VIP node (e.g. first node in clusterConfig.nodes)
	node := clusterConfig.nodes[0]
	key := "nonvip_post_test"
	value := "from_nonvip"

	// POST to non-VIP node
	payload := map[string]any{key: value}
	body, _ := json.Marshal(payload)
	resp, err := http.Post(fmt.Sprintf("%s/value", node.address),
		api.JsonMIMEType, bytes.NewBuffer(body))
	if err != nil {
		t.Fatalf("POST to non-VIP node failed: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Unexpected status from non-VIP POST: %d", resp.StatusCode)
	}

	// Give cluster a moment to sync
	time.Sleep(500 * time.Millisecond)

	// GET via VIP
	vipResp, err := http.Get(fmt.Sprintf("%s/value?key=%s", clusterConfig.vip, key))
	if err != nil {
		t.Fatalf("GET via VIP failed: %v", err)
	}
	defer vipResp.Body.Close()
	if vipResp.StatusCode != http.StatusOK {
		t.Fatalf("Unexpected status from VIP GET: %d", vipResp.StatusCode)
	}

	var v struct {
		Exists bool `json:"exists"`
		Value  any  `json:"value"`
	}
	if err := json.NewDecoder(vipResp.Body).Decode(&v); err != nil {
		t.Fatalf("Decoding VIP GET failed: %v", err)
	}
	if !v.Exists || v.Value != value {
		t.Errorf("Value not synced: want %q got %v", value, v.Value)
	}
}

// TestPatchValueOnNonVIPNode PATCHes a value on a non-VIP node
// and then verifies the change through the VIP endpoint.
func TestPatchValueOnNonVIPNode(t *testing.T) {
	// first ensure a baseline via VIP
	key := "nonvip_patch_test"
	initial := "baseline"
	initBody, _ := json.Marshal(map[string]any{key: initial})
	http.Post(fmt.Sprintf("%s/value", clusterConfig.vip),
		api.JsonMIMEType, bytes.NewBuffer(initBody))

	// patch on non-VIP node
	node := clusterConfig.nodes[0]
	updated := "patched_value"
	patchBody, _ := json.Marshal(map[string]any{"value": updated})
	req, _ := http.NewRequest("PATCH",
		fmt.Sprintf("%s/value?key=%s", node.address, key),
		bytes.NewBuffer(patchBody))
	req.Header.Set(api.ContentType, api.JsonMIMEType)
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("PATCH to non-VIP node failed: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Unexpected status from non-VIP PATCH: %d", resp.StatusCode)
	}

	// Give cluster a moment to sync
	time.Sleep(500 * time.Millisecond)

	// GET via VIP to verify
	vipResp, err := http.Get(fmt.Sprintf("%s/value?key=%s", clusterConfig.vip, key))
	if err != nil {
		t.Fatalf("GET via VIP after PATCH failed: %v", err)
	}
	defer vipResp.Body.Close()
	if vipResp.StatusCode != http.StatusOK {
		t.Fatalf("Unexpected VIP GET status: %d", vipResp.StatusCode)
	}

	var v struct {
		Exists bool `json:"exists"`
		Value  any  `json:"value"`
	}
	if err := json.NewDecoder(vipResp.Body).Decode(&v); err != nil {
		t.Fatalf("Decoding VIP GET failed: %v", err)
	}
	if !v.Exists || v.Value != updated {
		t.Errorf("Patch not synced: want %q got %v", updated, v.Value)
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

	req, err := http.NewRequest("DELETE", fmt.Sprintf("%s/value", clusterConfig.vip), nil)
	if err != nil {
		t.Fatalf("Failed to create DELETE request: %v", err)
	}
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send DELETE request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Unexpected status code: %d, response: %s", resp.StatusCode, string(body))
	}

	// Verify on every node that /value returns an empty map
	for _, node := range append(clusterConfig.nodes, clusterNode{address: clusterConfig.vip}) {
		t.Run("Clear on "+node.address, func(t *testing.T) {
			getResp, err := http.Get(fmt.Sprintf("%s/value", node.address))
			if err != nil {
				t.Fatalf("GET after clear failed on %s: %v", node.address, err)
			}
			defer getResp.Body.Close()

			if getResp.StatusCode != http.StatusOK {
				t.Errorf("Expected 200 OK from %s, got %d", node.address, getResp.StatusCode)
				return
			}

			var data map[string]any
			if err := json.NewDecoder(getResp.Body).Decode(&data); err != nil {
				t.Fatalf("Failed to decode GET response from %s: %v", node.address, err)
			}
			if len(data) != 0 {
				t.Errorf("Data was not cleared on %s: got %v", node.address, data)
			}
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

// TestUDPPut runs the "put" command inside the default instance.
func TestUDPPut(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	command := fmt.Sprintf(`echo '{"action":"put","payload":{"test":"hello"}}' | %s %s`, ncCommand, instancePort)
	out, err := runMultipassCommand(t, command)
	if err != nil {
		t.Fatalf("Multipass put command failed: %v, output: %s", err, out)
	}
}

// TestUDPPutAndGet sets a value and then verifies it with a get command on the default instance.
func TestUDPPutAndGet(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	// Set the value on instance1.
	setCommand := fmt.Sprintf(`echo '{"action":"put","payload":{"test":"hello"}}' | %s %s`, ncCommand, instancePort)
	setOut, err := runMultipassCommand(t, setCommand)
	if err != nil {
		t.Fatalf("Multipass put command failed: %v, output: %s", err, setOut)
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

// TestUDPPatchAndGetKey patches a nested value and then verifies it with a keyed UDP get.
func TestUDPPatchAndGetKey(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}

	putCommand := fmt.Sprintf(`echo '{"action":"put","payload":{"settings":{"audio":{"gain":1}}}}' | %s %s`, ncCommand, instancePort)
	putOut, err := runMultipassCommand(t, putCommand)
	if err != nil {
		t.Fatalf("Multipass put command failed: %v, output: %s", err, putOut)
	}

	patchCommand := fmt.Sprintf(`echo '{"action":"patch","key":"settings.audio.gain","value":5}' | %s %s`, ncCommand, instancePort)
	patchOut, err := runMultipassCommand(t, patchCommand)
	if err != nil {
		t.Fatalf("Multipass patch command failed: %v, output: %s", err, patchOut)
	}

	getCommand := fmt.Sprintf(`echo '{"action":"get","key":"settings.audio.gain"}' | %s %s`, ncCommand, instancePort)
	getOut, err := runMultipassCommand(t, getCommand)
	if err != nil {
		t.Fatalf("Multipass keyed get command failed: %v, output: %s", err, getOut)
	}

	if !strings.Contains(getOut, `"exists":true`) || !strings.Contains(getOut, `"value":5`) {
		t.Fatalf("Expected keyed get output to contain exists=true and value=5, got: %s", getOut)
	}
}

// TestUDPPropagation puts a value on instance1 and verifies that it propagates to instance2.
func TestUDPPropagation(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	// Build commands once
	setCmd := fmt.Sprintf(`echo '{"action":"put","payload":{"test":"hello"}}' | %s %s`, ncCommand, instancePort)
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

// TestHTTPSetAndVerifyViaUDP POSTs to /value and then does a UDP "get"
// to verify the entire state is returned over UDP.
func TestHTTPSetAndVerifyViaUDP(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}
	// Define the payload
	payload := map[string]any{
		"alpha": "one",
		"beta":  2,
		"gamma": []string{"x", "y", "z"},
	}
	jsonData, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("Failed to marshal payload: %v", err)
	}

	// POST it to the HTTP endpoint
	resp, err := http.Post(fmt.Sprintf("%s/value", serverAddr),
		api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("HTTP POST failed: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("HTTP POST returned status %d", resp.StatusCode)
	}

	deadline := time.Now().Add(5 * time.Second)
	var raw string
	var errRun error

	for i := 0; time.Now().Before(deadline); i++ {
		// note the "2>&1" so we capture nc's stderr (where -v prints)
		cmd := fmt.Sprintf(
			`(echo '{"action":"get"}' | nc -4 -u -w1 localhost %s) 2>/dev/null || true`,
			instancePort,
		)

		var resp string
		resp, errRun = runMultipassCommand(t, cmd)
		raw = strings.TrimSpace(resp)

		//t.Logf("iter %02d, nc err: %v, raw UDP payload: %q", i, errRun, raw)

		if raw != "" {

			if idx := strings.Index(raw, "{"); idx > 0 {
				raw = raw[idx:]
			}

			var result UDPResult
			if err := json.Unmarshal([]byte(raw), &result); err == nil {
				// check status
				if result.Status != "success" {
					t.Logf("  status != success: %q", result.Status)
				} else {
					ok := true
					for key, want := range payload {
						got, exists := result.Data[key]
						if !exists || fmt.Sprintf("%v", got) != fmt.Sprintf("%v", want) {
							t.Logf("  key %q: got %v want %v", key, got, want)
							ok = false
							break
						}
					}
					if ok {
						break
					}
				}
			} else {
				t.Logf("  json unmarshal into envelope failed: %v", err)
			}
		}

		time.Sleep(100 * time.Millisecond)
	}

	if raw == "" {
		t.Fatalf("timed out waiting for UDP state; last raw payload: %q, last err: %v", raw, errRun)
	}
}

func TestUDPPutAndVerifyViaHTTP(t *testing.T) {
	if isLocalTestMode() {
		t.Skip("Skipping multipass UDP test in local mode; use fusion/test/udp_test.go instead.")
	}

	payload := map[string]any{
		"alpha": "one",
		"beta":  2,
		"gamma": []string{"x", "y", "z"},
	}

	udpPacket := make(map[string]any, len(payload)+1)
	udpPacket["action"] = "put"
	udpPacket["payload"] = payload
	udpData, err := json.Marshal(udpPacket)
	if err != nil {
		t.Fatalf("Failed to marshal UDP packet: %v", err)
	}

	cmd := fmt.Sprintf(
		`(echo '%s' | nc -4 -u -w1 localhost %s)`,
		string(udpData),
		instancePort,
	)
	if _, err := runMultipassCommand(t, cmd); err != nil {
		t.Fatalf("UDP put failed: %v", err)
	}

	deadline := time.Now().Add(5 * time.Second)
	var lastErr error

	for time.Now().Before(deadline) {
		resp, err := http.Get(fmt.Sprintf("%s/value", serverAddr))
		if err != nil {
			lastErr = err
			time.Sleep(100 * time.Millisecond)
			continue
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			lastErr = fmt.Errorf("unexpected status: %d", resp.StatusCode)
			time.Sleep(100 * time.Millisecond)
			continue
		}

		var result map[string]any
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			lastErr = err
			time.Sleep(100 * time.Millisecond)
			continue
		}

		// Verify every key matches
		ok := true
		for key, want := range payload {
			got, exists := result[key]
			if !exists || fmt.Sprintf("%v", got) != fmt.Sprintf("%v", want) {
				lastErr = fmt.Errorf("key %q: got %v want %v", key, got, want)
				ok = false
				break
			}
		}
		if ok {
			return
		}
		time.Sleep(100 * time.Millisecond)
	}

	t.Fatalf("timed out waiting for HTTP /value; last error: %v", lastErr)
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
	// Create direct JSON format
	payload := map[string]any{
		key: value,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %v", err)
	}

	resp, err := http.Post(fmt.Sprintf("%s/value", node.address),
		api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		return fmt.Errorf("failed to send request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}
	return nil
}

func getValueFromNode(node clusterNode, key string) (any, bool, error) {
	resp, err := http.Get(fmt.Sprintf("%s/value?key=%s", node.address, key))
	if err != nil {
		return nil, false, fmt.Errorf("request failed: %v", err)
	}
	defer resp.Body.Close()

	var response struct {
		Exists bool   `json:"exists"`
		Key    string `json:"key"`
		Value  any    `json:"value,omitempty"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, false, fmt.Errorf("failed to decode response: %v", err)
	}

	if !response.Exists {
		return nil, false, nil
	}

	return response.Value, true, nil
}

func getFullStateFromNode(node clusterNode) (map[string]any, error) {
	resp, err := http.Get(fmt.Sprintf("%s/value", node.address))
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
