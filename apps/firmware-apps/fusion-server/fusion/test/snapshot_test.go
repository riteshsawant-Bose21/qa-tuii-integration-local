// Snapshot tests using RESTful snapshot endpoints
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"fusion/internal/api"
	"fusion/internal/logging"
	"io"
	"net/http"
	"slices"
	"testing"
	"time"
)

const (
	snapshotDefaultBucketName = "fusion"
	snapshotDatabaseName      = "fusion_test.db"
	snapServerAddr            = "http://192.168.64.100:8080"
	snapAdminServerAddr       = "http://192.168.64.100:9090"
	snapServerPort            = ":8080"
	snapshotSyncTime          = 5
)

func init() {
	logging.InitLogger(logging.LogConfig{
		NodeName:    "snapshot_test",
		LogDir:      "/tmp/snapshot_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})
}

func TestSnapshotCreateAndList(t *testing.T) {
	snapshotName := fmt.Sprintf("test_snapshot_%d", time.Now().UnixNano())
	createURL := fmt.Sprintf("%s/snapshots/%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Create snapshot returned %d: %s", resp.StatusCode, string(body))
	}

	listURL := fmt.Sprintf("%s/snapshots", snapServerAddr)
	resp, err = http.Get(listURL)
	if err != nil {
		t.Fatalf("Failed to list snapshots: %v", err)
	}
	defer resp.Body.Close()
	var listResp struct {
		Snapshots []string `json:"snapshots"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode list: %v", err)
	}
	if !slices.Contains(listResp.Snapshots, snapshotName) {
		t.Errorf("Snapshot %s not in list", snapshotName)
	}
}

func TestSnapshotActivateAndDelete(t *testing.T) {
	snapshotName := fmt.Sprintf("test_snapshot_%d", time.Now().UnixNano())
	createURL := fmt.Sprintf("%s/snapshots/%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}
	resp.Body.Close()

	activateURL := fmt.Sprintf("%s/snapshots/%s/activate", snapServerAddr, snapshotName)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate snapshot returned %d: %s", resp.StatusCode, string(body))
	}

	deleteURL := fmt.Sprintf("%s/snapshots/%s", snapServerAddr, snapshotName)
	req, _ = http.NewRequest(http.MethodDelete, deleteURL, nil)
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to delete snapshot: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Delete snapshot returned %d: %s", resp.StatusCode, string(body))
	}
}

func TestSnapshotInvalidCreate(t *testing.T) {
	createURL := fmt.Sprintf("%s/snapshots/", snapServerAddr) // invalid path
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Failed to create snapshot with empty name: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		t.Errorf("Expected error when creating snapshot with empty name")
	}
}

func TestSnapshotDuplicateCreate(t *testing.T) {
	snapshotName := fmt.Sprintf("test_snapshot_%d", time.Now().UnixNano())
	createURL := fmt.Sprintf("%s/snapshots/%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Create request failed: %v", err)
	}
	resp.Body.Close()
	resp, err = http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Duplicate create request failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		t.Errorf("Expected error on duplicate snapshot create")
	}
}

func TestSnapshotActivateNonExistent(t *testing.T) {
	snapshotName := "nonexistent"
	activateURL := fmt.Sprintf("%s/snapshots/%s/activate", snapServerAddr, snapshotName)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send activate request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusOK {
		t.Errorf("Expected failure activating nonexistent snapshot")
	}
}

func TestSnapshotPropagation(t *testing.T) {
	snapshotName := fmt.Sprintf("test_snapshot_propagation_%d", time.Now().UnixNano())
	createURL := fmt.Sprintf("%s/snapshots/%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}
	resp.Body.Close()
	if !waitForSnapshotSync(snapshotSyncTime*time.Second, func() bool {
		return snapshotExistsOnAllNodes(t, snapshotName)
	}) {
		t.Fatalf("Snapshot %q did not propagate to all nodes", snapshotName)
	}
	activateURL := fmt.Sprintf("%s/snapshots/%s/activate", snapServerAddr, snapshotName)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}
	resp.Body.Close()
	deleteURL := fmt.Sprintf("%s/snapshots/%s", snapServerAddr, snapshotName)
	req, _ = http.NewRequest(http.MethodDelete, deleteURL, nil)
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to delete snapshot: %v", err)
	}
	resp.Body.Close()
	if !waitForSnapshotSync(snapshotSyncTime*time.Second, func() bool {
		return snapshotRemovedOnAllNodes(t, snapshotName)
	}) {
		t.Fatalf("Snapshot %q was not removed from all nodes", snapshotName)
	}
}

func TestSnapshotExport(t *testing.T) {
	exportURL := fmt.Sprintf("%s/exportData", snapAdminServerAddr)
	resp, err := http.Get(exportURL)
	if err != nil {
		t.Fatalf("Failed to get full export: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Export returned %d: %s", resp.StatusCode, string(body))
	}
	var export map[string]json.RawMessage
	if err := json.NewDecoder(resp.Body).Decode(&export); err != nil {
		t.Fatalf("Failed to decode export: %v", err)
	}
	if _, ok := export[snapshotDefaultBucketName]; !ok {
		t.Errorf("Missing '%s' in export", snapshotDefaultBucketName)
	}
}

func TestSnapshotExportImport(t *testing.T) {
	exportURL := fmt.Sprintf("%s/exportData", snapAdminServerAddr)
	resp, err := http.Get(exportURL)
	if err != nil {
		t.Fatalf("Failed to export snapshots: %v", err)
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	var export map[string]json.RawMessage
	json.Unmarshal(data, &export)
	var state map[string]json.RawMessage
	json.Unmarshal(export[snapshotDefaultBucketName], &state)
	var snapshotToRemove string
	for k := range state {
		if k != "default" {
			snapshotToRemove = k
			break
		}
	}
	if snapshotToRemove == "" {
		t.Skip("No snapshot available to remove in import test")
	}
	delete(state, snapshotToRemove)
	newState, _ := json.Marshal(state)
	export[snapshotDefaultBucketName] = newState
	modified, _ := json.Marshal(export)
	importURL := fmt.Sprintf("%s/importData", snapAdminServerAddr)
	resp, err = http.Post(importURL, api.JsonMIMEType, bytes.NewReader(modified))
	if err != nil {
		t.Fatalf("Failed to import snapshot: %v", err)
	}
	resp.Body.Close()

	listURL := fmt.Sprintf("%s/snapshots", snapServerAddr)
	resp, err = http.Get(listURL)
	if err != nil {
		t.Fatalf("Failed to list snapshots: %v", err)
	}
	defer resp.Body.Close()
	var listResp struct {
		Snapshots []string `json:"snapshots"`
	}
	json.NewDecoder(resp.Body).Decode(&listResp)
	if slices.Contains(listResp.Snapshots, snapshotToRemove) {
		t.Errorf("Snapshot %q should have been removed by import", snapshotToRemove)
	}
}

func snapshotExistsOnAllNodes(t *testing.T, name string) bool {
	nodes, err := getLiveNodeAddresses()
	if err != nil {
		t.Log(err)
		return false
	}
	for _, addr := range nodes {
		resp, err := http.Get(fmt.Sprintf("%s/snapshots", addr))
		if err != nil {
			return false
		}
		defer resp.Body.Close()
		var list struct {
			Snapshots []string `json:"snapshots"`
		}
		json.NewDecoder(resp.Body).Decode(&list)
		if !slices.Contains(list.Snapshots, name) {
			return false
		}
	}
	return true
}

func snapshotRemovedOnAllNodes(t *testing.T, name string) bool {
	nodes, err := getLiveNodeAddresses()
	if err != nil {
		t.Log(err)
		return false
	}
	for _, addr := range nodes {
		resp, err := http.Get(fmt.Sprintf("%s/snapshots", addr))
		if err != nil {
			return false
		}
		defer resp.Body.Close()
		var list struct {
			Snapshots []string `json:"snapshots"`
		}
		json.NewDecoder(resp.Body).Decode(&list)
		if slices.Contains(list.Snapshots, name) {
			return false
		}
	}
	return true
}

func getLiveNodeAddresses() ([]string, error) {
	resp, err := http.Get(fmt.Sprintf("%s/members", snapServerAddr))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var members []struct {
		Addr string `json:"Addr"`
		Port int    `json:"Port"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&members); err != nil {
		return nil, err
	}
	var nodes []string
	for _, m := range members {
		nodes = append(nodes, fmt.Sprintf("http://%s%s", m.Addr, snapServerPort))
	}
	return nodes, nil
}

func waitForSnapshotSync(timeout time.Duration, check func() bool) bool {
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
