package main

import (
	"encoding/json"
	"fmt"
	"fusion/internal/logging"
	"io"
	"net/http"
	"slices"
	"testing"
	"time"
)

const (
	snapServerAddr  = "http://192.168.64.100:8080"
	snapContentType = "application/json"
)

func TestSnapshotCreateList(t *testing.T) {
	// Generate a unique snapshot name
	snapshotName := fmt.Sprintf("test_snapshot_create_list_%d", time.Now().UnixNano())

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
		LogLevel:    logging.DEBUG,
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

func TestSnapshotPropagation(t *testing.T) {
	// Generate a unique snapshot name.
	snapshotName := fmt.Sprintf("test_snapshot_propagation_%d", time.Now().UnixNano())

	t.Logf("Creating snapshot %q via %s", snapshotName, snapServerAddr)
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

	// Wait until the snapshot appears in the snapshot list.
	if !waitForSnapshotSync(5*time.Second, func() bool {
		resp, err := http.Get(fmt.Sprintf("%s/snapshots", snapServerAddr))
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
		return slices.Contains(listResp.Snapshots, snapshotName)
	}) {
		t.Fatalf("Snapshot %q was not propagated after creation", snapshotName)
	}
	t.Logf("Snapshot %q successfully created and propagated", snapshotName)

	// Activate Snapshot via VIP
	t.Logf("Activating snapshot %q via %s", snapshotName, snapServerAddr)
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
	t.Logf("Snapshot %q successfully activated", snapshotName)

	// Delete Snapshot via VIP
	t.Logf("Deleting snapshot %q via %s", snapshotName, snapServerAddr)
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

	// Wait until the snapshot is removed from the snapshot list.
	if !waitForSnapshotSync(5*time.Second, func() bool {
		resp, err := http.Get(fmt.Sprintf("%s/snapshots", snapServerAddr))
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
		return !slices.Contains(listResp.Snapshots, snapshotName)
	}) {
		t.Fatalf("Snapshot %q was not removed after deletion", snapshotName)
	}
	t.Logf("Snapshot %q successfully deleted and propagation verified", snapshotName)
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
