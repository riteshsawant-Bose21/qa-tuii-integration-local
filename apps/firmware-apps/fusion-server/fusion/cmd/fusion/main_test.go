package main

import (
	"bytes"
	"encoding/json"
	"fmt"
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
