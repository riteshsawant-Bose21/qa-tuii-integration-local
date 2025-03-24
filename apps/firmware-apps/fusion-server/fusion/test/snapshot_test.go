package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"fusion/internal/logging"
	"fusion/internal/server"
	"io"
	"net/http"
	"path/filepath"
	"slices"
	"testing"
	"time"
)

const (
	snapshotDefaultBucketName = "fusion"
	snapshotDatabaseName      = "fusion_test.db"
	snapServerAddr            = "http://192.168.64.100:8080"
	snapServerPort            = ":8080"
	snapContentType           = "application/json"
	snapshotSyncTime          = 5
)

// TestActiveSnapshot tests the snapshot functionality.
// It verifies that saving a snapshot and activating it via the active snapshot pointer
// causes LoadActiveSnapshot() to load the snapshot's state.
func TestActiveSnapshot(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "SnapshotTest",
		LogDir:      "/tmp/snapshot_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})

	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, snapshotDatabaseName)

	// Initialize state manager and persistence.
	sm := server.NewStateManager("testnode")
	if err := sm.Set("key", "value_latest"); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Save the initial state
	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Modify state to simulate a snapshot.
	if err := sm.Set("key", "value_snapshot"); err != nil {
		t.Fatalf("Failed to update state: %v", err)
	}

	// Save the new state as a snapshot with key "snapshot1".
	if err := cp.CreateSnapshot("snapshot1"); err != nil {
		t.Fatalf("CreateSnapshot failed: %v", err)
	}

	// Change the state again to simulate a difference.
	if err := sm.Set("key", "value_modified"); err != nil {
		t.Fatalf("Failed to modify state: %v", err)
	}

	// Activate the snapshot "snapshot1".
	if err := cp.ActivateSnapshot("snapshot1"); err != nil {
		t.Fatalf("ActivateSnapshot failed: %v", err)
	}

	// Verify that the state manager now holds the snapshot's state.
	fullState := sm.GetFullState()
	entry, exists := fullState["key"]
	if !exists {
		t.Fatalf("Key 'key' not found after activating snapshot")
	}
	if entry.Data != "value_snapshot" {
		t.Errorf("Expected active snapshot state 'value_snapshot', got %v", entry.Data)
	}
	cp.Close()

	// Simulate a new instance loading state to verify the active pointer.
	newSM := server.NewStateManager("testnode")
	newCP, err := server.NewConfigPersistence(configPath, newSM, false)
	if err != nil {
		t.Fatalf("Failed to reinitialize persistence: %v", err)
	}
	defer newCP.Close()

	if err := newCP.LoadActiveSnapshot(); err != nil {
		t.Fatalf("LoadActiveSnapshot failed: %v", err)
	}

	newState := newSM.GetFullState()
	newEntry, exists := newState["key"]
	if !exists {
		t.Fatalf("Key 'key' not found after reloading state")
	}
	if newEntry.Data != "value_snapshot" {
		t.Errorf("Expected reloaded state to be 'value_snapshot', got %v", newEntry.Data)
	}
}

// TestLoadActiveSnapshotNonExistent verifies that when the state file does not exist,
// LoadActiveSnapshot logs an info message and returns nil (allowing the service to start with an empty state).
func TestLoadActiveSnapshotNonExistent(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TestLoadActiveSnapshotNonExistent",
		LogDir:      "/tmp/persistence_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})

	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "nonexistent.db")

	sm := server.NewStateManager("testnode")
	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Call LoadActiveSnapshot. Since the file doesn't exist, it should return nil.
	if err := cp.LoadActiveSnapshot(); err != nil {
		t.Fatalf("LoadActiveSnapshot failed on non-existent file: %v", err)
	}
}

// TestSaveAndLoadActiveSnapshot tests that saving and then loading the state using the latest key works as expected.
func TestSaveAndLoadActiveSnapshot(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, snapshotDatabaseName)

	sm := server.NewStateManager("testnode")
	testKey, testValue := "testKey", "testValue"
	if err := sm.Set(testKey, testValue); err != nil {
		t.Fatalf("Failed to set initial state: %v", err)
	}

	// Create the persistence object.
	cp, err := server.NewConfigPersistence(configPath, sm, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}

	// Save the state.
	if err := cp.SaveState(); err != nil {
		t.Fatalf("SaveState failed: %v", err)
	}

	// Close the first persistence instance before simulating a restart.
	cp.Close()

	// Simulate restart by creating a new persistence object.
	newSM := server.NewStateManager("testnode")
	newCP, err := server.NewConfigPersistence(configPath, newSM, false)
	if err != nil {
		t.Fatalf("Failed to initialize persistence: %v", err)
	}
	defer newCP.Close()

	// Load the saved state.
	if err := newCP.LoadActiveSnapshot(); err != nil {
		t.Fatalf("LoadActiveSnapshot failed: %v", err)
	}

	// Check that the state was applied.
	fullState := newSM.GetFullState()
	entry, exists := fullState[testKey]
	if !exists {
		t.Fatalf("Key %s not found after load", testKey)
	}
	if entry.Data != testValue {
		t.Fatalf("Expected value %v for key %s, got %v", testValue, testKey, entry.Data)
	}
}

func TestSnapshotCreateAndList(t *testing.T) {
	// Generate a unique snapshot name
	snapshotName := fmt.Sprintf("test_snapshot_create_and_list_%d", time.Now().UnixNano())

	// Create Snapshot
	createURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, snapContentType, nil)
	if err != nil {
		t.Fatalf("Failed to send create snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Create snapshot returned status %d: %s", resp.StatusCode, string(body))
	}
	var createResp map[string]string
	if err := json.NewDecoder(resp.Body).Decode(&createResp); err != nil {
		t.Fatalf("Failed to decode create snapshot response: %v", err)
	}
	if createResp["status"] != "snapshot created" {
		t.Errorf("Unexpected create snapshot status: %v", createResp["status"])
	}
	if createResp["snapshot"] != snapshotName {
		t.Errorf("Expected snapshot name %s, got %s", snapshotName, createResp["snapshot"])
	}

	// List Snapshots
	listURL := fmt.Sprintf("%s/snapshots", snapServerAddr)
	resp, err = http.Get(listURL)
	if err != nil {
		t.Fatalf("Failed to list snapshots: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("List snapshots returned status %d: %s", resp.StatusCode, string(body))
	}
	var listResp struct {
		Snapshots []string `json:"snapshots"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode list snapshots response: %v", err)
	}
	found := false
	for _, s := range listResp.Snapshots {
		if s == snapshotName {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Snapshot %s not found in snapshot list: %v", snapshotName, listResp.Snapshots)
	}
}

func TestSnapshotActivate(t *testing.T) {
	// Generate a unique snapshot name
	snapshotName := fmt.Sprintf("test_snapshot_activate_%d", time.Now().UnixNano())

	// Create Snapshot
	createURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, snapContentType, nil)
	if err != nil {
		t.Fatalf("Failed to send create snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Create snapshot returned status %d: %s", resp.StatusCode, string(body))
	}

	// Activate Snapshot
	activateURL := fmt.Sprintf("%s/snapshots/activate?name=%s", snapServerAddr, snapshotName)
	req, err := http.NewRequest(http.MethodPut, activateURL, nil)
	if err != nil {
		t.Fatalf("Failed to create activate snapshot request: %v", err)
	}
	req.Header.Set("Content-Type", snapContentType)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send activate snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate snapshot returned status %d: %s", resp.StatusCode, string(body))
	}
	var activateResp map[string]string
	if err := json.NewDecoder(resp.Body).Decode(&activateResp); err != nil {
		t.Fatalf("Failed to decode activate snapshot response: %v", err)
	}
	if activateResp["status"] != "snapshot activated" {
		t.Errorf("Unexpected activate snapshot status: %v", activateResp["status"])
	}
	if activateResp["snapshot"] != snapshotName {
		t.Errorf("Expected snapshot name %s, got %s", snapshotName, activateResp["snapshot"])
	}
}

func TestSnapshotDelete(t *testing.T) {

	logging.InitLogger(logging.LogConfig{
		NodeName:    "TestSnapshotDelete",
		LogDir:      "/tmp/snapshot_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.INFO,
	})

	snapshotName := "test_snapshot_delete"
	// Create Snapshot
	createURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, snapContentType, nil)
	if err != nil {
		t.Fatalf("Failed to send create snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Create snapshot returned status %d: %s", resp.StatusCode, string(body))
	}

	// Delete Snapshot
	deleteURL := fmt.Sprintf("%s/snapshots/delete?name=%s", snapServerAddr, snapshotName)
	req, err := http.NewRequest(http.MethodDelete, deleteURL, nil)
	if err != nil {
		t.Fatalf("Failed to create delete snapshot request: %v", err)
	}
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send delete snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Delete snapshot returned status %d: %s", resp.StatusCode, string(body))
	}
	var deleteResp map[string]string
	if err := json.NewDecoder(resp.Body).Decode(&deleteResp); err != nil {
		t.Fatalf("Failed to decode delete snapshot response: %v", err)
	}
	if deleteResp["status"] != "snapshot deleted" {
		t.Errorf("Unexpected delete snapshot status: %v", deleteResp["status"])
	}
	if deleteResp["snapshot"] != snapshotName {
		t.Errorf("Expected snapshot name %s, got %s", snapshotName, deleteResp["snapshot"])
	}

	// Verify Deletion by Listing Snapshots
	listURL := fmt.Sprintf("%s/snapshots", snapServerAddr)
	resp, err = http.Get(listURL)
	if err != nil {
		t.Fatalf("Failed to list snapshots: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("List snapshots returned status %d: %s", resp.StatusCode, string(body))
	}
	var listResp struct {
		Snapshots []string `json:"snapshots"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode list snapshots response: %v", err)
	}
	for _, s := range listResp.Snapshots {
		if s == snapshotName {
			t.Errorf("Snapshot %s still found in snapshot list after deletion", snapshotName)
		}
	}
}

// TestSnapshotActivateNonExistent attempts to activate a snapshot that does not exist.
func TestSnapshotActivateNonExistent(t *testing.T) {
	snapshotName := "non_existent_snapshot"
	activateURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, snapshotName)
	req, err := http.NewRequest(http.MethodPut, activateURL, nil)
	if err != nil {
		t.Fatalf("Failed to create activate snapshot request: %v", err)
	}
	req.Header.Set("Content-Type", snapContentType)
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send activate snapshot request: %v", err)
	}
	defer resp.Body.Close()
	// Expect an error status (e.g., 404 Not Found) when trying to activate a non-existent snapshot.
	if resp.StatusCode == http.StatusOK {
		t.Errorf("Expected error when activating non-existent snapshot, got status %d", resp.StatusCode)
	}
}

// TestSnapshotCreateEmptyName ensures that creating a snapshot with an empty name is rejected.
func TestSnapshotCreateEmptyName(t *testing.T) {
	createURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, "")
	resp, err := http.Post(createURL, snapContentType, nil)
	if err != nil {
		t.Fatalf("Failed to send create snapshot request: %v", err)
	}
	defer resp.Body.Close()
	// Expect a failure (e.g., 400 Bad Request) for an empty snapshot name.
	if resp.StatusCode == http.StatusOK {
		t.Errorf("Expected error when creating snapshot with empty name, got status %d", resp.StatusCode)
	}
}

// TestSnapshotDuplicateCreation verifies that duplicate snapshot creation is handled.
func TestSnapshotDuplicateCreation(t *testing.T) {
	// Generate a unique snapshot name using the current time.
	snapshotName := fmt.Sprintf("test_snapshot_duplicate_%d", time.Now().UnixNano())
	createURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, snapshotName)
	// First creation should succeed.
	resp, err := http.Post(createURL, snapContentType, nil)
	if err != nil {
		t.Fatalf("Failed to send create snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("First create snapshot returned status %d: %s", resp.StatusCode, string(body))
	}
	// Second creation (duplicate) should fail.
	resp, err = http.Post(createURL, snapContentType, nil)
	if err != nil {
		t.Fatalf("Failed to send duplicate create snapshot request: %v", err)
	}
	defer resp.Body.Close()
	// Expect a 409 Conflict for duplicate snapshot creation.
	if resp.StatusCode == http.StatusOK {
		t.Errorf("Expected error when creating duplicate snapshot, got status %d", resp.StatusCode)
	}
}

// snapshotExistsOnAllNodes checks all live nodes for the named snapshot
func snapshotExistsOnAllNodes(t *testing.T, snapshotName string) bool {
	liveAddrs, err := getLiveNodeAddresses()
	if err != nil {
		t.Error("Unable to get node adresses", err)
		return false
	}

	for _, addr := range liveAddrs {
		// Check each member's /snapshots endpoint.
		url := fmt.Sprintf("%s/snapshots", addr)
		resp, err := http.Get(url)
		if err != nil {
			t.Errorf("Unable to get snapshots at %s: %v", url, err)
			return false
		}
		defer resp.Body.Close()

		var listResp struct {
			Snapshots []string `json:"snapshots"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			t.Errorf("Unable to decode snapshots at %s: %v", url, err)
			return false
		}

		if !slices.Contains(listResp.Snapshots, snapshotName) {
			return false
		}
	}
	return true
}

// getLiveNodeAddresses calls the /members API to obtain all node addresses.
// It assumes that the snapshot HTTP API is available on a fixed port.
func getLiveNodeAddresses() ([]string, error) {
	membersURL := fmt.Sprintf("%s/members", snapServerAddr)
	resp, err := http.Get(membersURL)
	if err != nil {
		return nil, fmt.Errorf("unable to get node addresses: %w", err)
	}
	defer resp.Body.Close()

	// Define a structure matching the JSON response.
	var members []struct {
		Name string `json:"Name"`
		Addr string `json:"Addr"`
		Port int    `json:"Port"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&members); err != nil {
		return nil, err
	}

	var addresses []string
	// Assuming that the snapshot API is served on port 8080.
	for _, member := range members {
		addresses = append(addresses, fmt.Sprintf("http://%s%s", member.Addr, snapServerPort))
	}
	return addresses, nil
}

func snapshotRemovedOnAllNodes(t *testing.T, snapshotName string) bool {
	liveAddrs, err := getLiveNodeAddresses()
	if err != nil {
		t.Errorf("GetLiveNodeAddresses error: %v", err)
		return false
	}

	for _, addr := range liveAddrs {
		url := fmt.Sprintf("%s/snapshots", addr)
		resp, err := http.Get(url)
		if err != nil {
			return false
		}
		defer resp.Body.Close()

		var listResp struct {
			Snapshots []string `json:"snapshots"`
		}
		if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
			return false
		}
		// If any member still has the snapshot, then it's not fully removed.
		if slices.Contains(listResp.Snapshots, snapshotName) {
			return false
		}
	}
	return true
}

func TestSnapshotPropagation(t *testing.T) {

	// Generate a unique snapshot name.
	snapshotName := fmt.Sprintf("test_snapshot_propagation_%d", time.Now().UnixNano())

	// Create snapshot using the VIP address.
	createURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, snapshotName)
	resp, err := http.Post(createURL, snapContentType, nil)
	if err != nil {
		t.Fatalf("Failed to send create snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Create snapshot returned status %d: %s", resp.StatusCode, string(body))
	}

	// Wait until the snapshot appears on all member nodes.
	if !waitForSnapshotSync(snapshotSyncTime*time.Second, func() bool {
		return snapshotExistsOnAllNodes(t, snapshotName)
	}) {
		t.Fatalf("Snapshot %q was not propagated to all member nodes after creation", snapshotName)
	}

	// Activate Snapshot via VIP.
	activateURL := fmt.Sprintf("%s/snapshots/activate?name=%s", snapServerAddr, snapshotName)
	req, err := http.NewRequest(http.MethodPut, activateURL, nil)
	if err != nil {
		t.Fatalf("Failed to create activate snapshot request: %v", err)
	}
	req.Header.Set("Content-Type", snapContentType)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send activate snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate snapshot returned status %d: %s", resp.StatusCode, string(body))
	}

	// Delete Snapshot via VIP.
	deleteURL := fmt.Sprintf("%s/snapshots/delete?name=%s", snapServerAddr, snapshotName)
	req, err = http.NewRequest(http.MethodDelete, deleteURL, nil)
	if err != nil {
		t.Fatalf("Failed to create delete snapshot request: %v", err)
	}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to send delete snapshot request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Delete snapshot returned status %d: %s", resp.StatusCode, string(body))
	}

	// Wait until the snapshot is removed on all member nodes.
	if !waitForSnapshotSync(snapshotSyncTime*time.Second, func() bool {
		return snapshotRemovedOnAllNodes(t, snapshotName)
	}) {
		t.Fatalf("Snapshot %q was not removed from all member nodes after deletion", snapshotName)
	}
}

// TestSnapshotFullDump verifies that the full export endpoint returns both the metadata and state buckets.
func TestSnapshotFullDump(t *testing.T) {
	exportURL := fmt.Sprintf("%s/snapshots/export", snapServerAddr)
	resp, err := http.Get(exportURL)
	if err != nil {
		t.Fatalf("Failed to get full export: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Full export returned status %d: %s", resp.StatusCode, string(body))
	}

	var export map[string]json.RawMessage
	if err := json.NewDecoder(resp.Body).Decode(&export); err != nil {
		t.Fatalf("Failed to decode full export JSON: %v", err)
	}

	if _, ok := export["snapshot_metadata"]; !ok {
		t.Errorf("Full export missing 'snapshot_metadata' key")
	}
	if _, ok := export[snapshotDefaultBucketName]; !ok {
		t.Errorf("Full export missing 'fusion' key")
	}
}

// TestSnapshotImport simulates importing a modified export (with one snapshot removed)
// and then verifies that the local state reflects the change.
func TestSnapshotImport(t *testing.T) {

	exportURL := fmt.Sprintf("%s/snapshots/export", snapServerAddr)
	resp, err := http.Get(exportURL)
	if err != nil {
		t.Fatalf("Failed to get full export: %v", err)
	}

	exportData, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		t.Fatalf("Failed to read full export data: %v", err)
	}

	var export map[string]json.RawMessage
	if err := json.Unmarshal(exportData, &export); err != nil {
		t.Fatalf("Failed to unmarshal export JSON: %v", err)
	}

	// Unmarshal the fusion bucket.
	var snapshotsMap map[string]json.RawMessage
	if err := json.Unmarshal(export[snapshotDefaultBucketName], &snapshotsMap); err != nil {
		t.Fatalf("Failed to unmarshal fusion bucket: %v", err)
	}

	// Choose a snapshot to remove (if available, other than "default").
	var snapshotToRemove string
	for k := range snapshotsMap {
		if k != "default" {
			snapshotToRemove = k
			break
		}
	}

	// If no candidate is found, create one for testing.
	if snapshotToRemove == "" {
		snapshotToRemove = fmt.Sprintf("test_snapshot_import_%d", time.Now().UnixNano())
		createURL := fmt.Sprintf("%s/snapshots/create?name=%s", snapServerAddr, snapshotToRemove)
		resp, err := http.Post(createURL, snapContentType, nil)
		if err != nil {
			t.Fatalf("Failed to create snapshot for import test: %v", err)
		}
		resp.Body.Close()

		// Wait briefly for the snapshot to propagate.
		time.Sleep(500 * time.Millisecond)

		// Re-fetch the full export.
		resp, err = http.Get(exportURL)
		if err != nil {
			t.Fatalf("Failed to get full export after snapshot creation: %v", err)
		}
		exportData, err = io.ReadAll(resp.Body)
		resp.Body.Close()

		if err != nil {
			t.Fatalf("Failed to read full export data: %v", err)
		}

		if err := json.Unmarshal(exportData, &export); err != nil {
			t.Fatalf("Failed to unmarshal export JSON: %v", err)
		}

		if err := json.Unmarshal(export[snapshotDefaultBucketName], &snapshotsMap); err != nil {
			t.Fatalf("Failed to unmarshal state bucket: %v", err)
		}
	}

	// Remove the chosen snapshot from the state.
	delete(snapshotsMap, snapshotToRemove)
	modifiedState, err := json.Marshal(snapshotsMap)
	if err != nil {
		t.Fatalf("Failed to marshal modified state: %v", err)
	}
	export[snapshotDefaultBucketName] = modifiedState

	modifiedDump, err := json.Marshal(export)
	if err != nil {
		t.Fatalf("Failed to marshal modified export: %v", err)
	}

	// POST the modified export to the import endpoint.
	importURL := fmt.Sprintf("%s/snapshots/import", snapServerAddr)
	resp, err = http.Post(importURL, snapContentType, bytes.NewReader(modifiedDump))
	if err != nil {
		t.Fatalf("Failed to send import request: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Import returned status %d: %s", resp.StatusCode, string(body))
	}

	// // Verify that the removed snapshot is no longer present.
	listURL := fmt.Sprintf("%s/snapshots", snapServerAddr)
	resp, err = http.Get(listURL)
	if err != nil {
		t.Fatalf("Failed to list snapshots after import: %v", err)
	}
	defer resp.Body.Close()
	var listResp struct {
		Snapshots []string `json:"snapshots"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode list snapshots response: %v", err)
	}
	for _, s := range listResp.Snapshots {
		if s == snapshotToRemove {
			t.Errorf("Snapshot %s should have been removed by import, but is still present", snapshotToRemove)
		}
	}
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
