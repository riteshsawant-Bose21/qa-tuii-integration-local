//go:build !parallel

package main

import (
	"bytes"
	"fmt"
	"fusion/internal/api"
	"fusion-services-core/logging"
	"fusion/internal/routes"
	"io"
	"net/http"
	"os"
	"os/exec"
	"slices"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

const (
	nameParam                 = "{name}"
	snapshotDefaultBucketName = "fusion"
	snapshotSyncTime          = 5 * time.Second

	snapServerAddress   = "http://192.168.2.100"
	snapServerPort      = "8080"
	snapServerAdminPort = "9090"
	snapServerAddr      = snapServerAddress + ":" + snapServerPort
	snapAdminServerAddr = snapServerAddress + ":" + snapServerAdminPort

	// Core endpoints
	snapshotsURL        = snapServerAddr + routes.SnapshotsEndpoint
	snapshotByNameURL   = snapServerAddr + routes.SnapshotsNameEndpoint
	snapshotActivateURL = snapServerAddr + routes.SnapshotsActivateEndpoint
	snapshotUpdateURL   = snapServerAddr + routes.SnapshotsUpdateEndpoint
	valueURL            = snapServerAddr + routes.ValueEndpoint
)

func init() {
	_ = os.Setenv("GOMAXPROCS", "1")

	logging.InitLogger(logging.LogConfig{
		NodeName:    "snapshot_test",
		LogDir:      "/tmp/snapshot_test",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.ERROR,
	})
}

func TestSnapshotCreateAndList(t *testing.T) {
	snapshotName := fmt.Sprintf("test_snapshot_%d", time.Now().UnixNano())
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusCreated {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Create snapshot returned %d: %s", resp.StatusCode, string(body))
	}

	resp, err = http.Get(snapshotsURL)
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
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}
	resp.Body.Close()

	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate snapshot returned %d: %s", resp.StatusCode, string(body))
	}

	deleteURL := fmt.Sprintf("%s/%s", snapshotsURL, snapshotName)
	req, _ = http.NewRequest(http.MethodDelete, deleteURL, nil)
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to delete snapshot: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Delete snapshot returned %d: %s", resp.StatusCode, string(body))
	}
}

func TestSnapshotInvalidCreate(t *testing.T) {
	resp, err := http.Post(snapshotsURL, api.JsonMIMEType, nil)
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
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
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
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
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
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)

	// Create snapshot on origin node
	resp, err := http.Post(createURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}
	resp.Body.Close()

	// Wait until all nodes have the snapshot
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return snapshotExistsOnAllNodes(t, snapshotName)
	}) {
		logPerNodeSnapshotStatus(t, snapshotName)
		t.Fatalf("Snapshot %q did not propagate to all nodes", snapshotName)
	}

	// Activate the snapshot
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	client := &http.Client{}
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}
	resp.Body.Close()

	// Delete the snapshot
	deleteURL := fmt.Sprintf("%s/%s", snapshotsURL, snapshotName)
	req, _ = http.NewRequest(http.MethodDelete, deleteURL, nil)
	resp, err = client.Do(req)
	if err != nil {
		t.Fatalf("Failed to delete snapshot: %v", err)
	}
	resp.Body.Close()

	// Wait until all nodes remove the snapshot
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return snapshotRemovedOnAllNodes(t, snapshotName)
	}) {
		logPerNodeSnapshotStatus(t, snapshotName)
		t.Fatalf("Snapshot %q was not removed from all nodes", snapshotName)
	}
}

func TestSnapshotExport(t *testing.T) {
	exportURL := fmt.Sprintf("%s/data", snapAdminServerAddr)
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
	exportURL := fmt.Sprintf("%s/data", snapAdminServerAddr)
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
	importURL := fmt.Sprintf("%s/data", snapAdminServerAddr)
	resp, err = http.Post(importURL, api.JsonMIMEType, bytes.NewReader(modified))
	if err != nil {
		t.Fatalf("Failed to import snapshot: %v", err)
	}
	resp.Body.Close()

	resp, err = http.Get(snapshotsURL)
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
	t.Helper()
	nodes, err := getLiveNodeAddresses()
	if err != nil {
		t.Log(err)
		return false
	}
	for _, addr := range nodes {
		resp, err := http.Get(fmt.Sprintf("%s%s", addr, routes.SnapshotsEndpoint))
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
	t.Helper()
	nodes, err := getLiveNodeAddresses()
	if err != nil {
		t.Log(err)
		return false
	}
	for _, addr := range nodes {
		resp, err := http.Get(fmt.Sprintf("%s%s", addr, routes.SnapshotsEndpoint))
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

//
// Snapshot Epoch Consistency Tests
//

func TestSnapshotActivationBumpsEpoch(t *testing.T) {

	initial := getAnyClusterEpoch(t)

	snapshotName := fmt.Sprintf("epoch_test_%d", time.Now().UnixNano())
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)

	// Create snapshot
	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}

	// Activate snapshot
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	if _, err := (&http.Client{}).Do(req); err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}

	// Wait for cluster to converge to a single epoch > initial
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return epochsConverged(t, initial)
	}) {
		t.Fatalf("Epoch did not converge after snapshot activation; initial=%d, epochs=%v",
			initial, getClusterEpochs(t))
	}
}

func TestRejectOldEpochUpdatesAfterSnapshot(t *testing.T) {
	initialEpoch := getAnyClusterEpoch(t)

	// Create + activate snapshot
	snapshotName := fmt.Sprintf("old_epoch_reject_%d", time.Now().UnixNano())
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)

	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}

	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	if _, err := (&http.Client{}).Do(req); err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}

	// Wait for epoch convergence
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return epochsConverged(t, initialEpoch)
	}) {
		t.Fatalf("Epochs did not converge after activation; initial=%d, epochs=%v",
			initialEpoch, getClusterEpochs(t))
	}

	newEpoch := getAnyClusterEpoch(t)

	// Set known value
	setStateValue(t, "foo", 111)

	// Send a stale update with older epoch
	staleUpdate := `{"foo":123}`

	resp, err := http.Post(valueURL, api.JsonMIMEType, bytes.NewBuffer([]byte(staleUpdate)))
	if err != nil {
		t.Fatalf("Failed sending stale update: %v", err)
	}
	resp.Body.Close()

	// Verify value is unchanged
	val := getStateValue(t, "foo")
	if val == 123 {
		t.Fatalf("Old-epoch update incorrectly applied (initial=%d, new=%d)",
			initialEpoch, newEpoch)
	}
}

func TestNewEpochUpdatesApply(t *testing.T) {

	// Create + activate snapshot
	snapshotName := fmt.Sprintf("epoch_updates_apply_%d", time.Now().UnixNano())
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)

	http.Post(createURL, api.JsonMIMEType, nil)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	(&http.Client{}).Do(req)

	initialEpoch := getAnyClusterEpoch(t)

	// Wait for epoch convergence
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return epochsConverged(t, initialEpoch)
	}) {
		t.Fatalf("Epochs did not converge after activation; initial=%d, epochs=%v",
			initialEpoch, getClusterEpochs(t))
	}

	setStateValue(t, "foo_new", 999)

	// Immediate local GET to ensure the write succeeded locally
	localVal := getStateValue(t, "foo_new")
	if asInt(localVal) != 999 {
		t.Fatalf("Local value write failed: expected 999, got %v (endpoint /value may not be applying writes)",
			localVal)
	}

	// Wait for propagation across cluster
	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		val := getStateValue(t, "foo_new")
		return asInt(val) == 999
	})

	if !ok {
		t.Fatalf("Valid update did not propagate (expected 999, got %v)",
			getStateValue(t, "foo_new"))
	}
}

// All nodes:
//  1. have same epoch
//  2. epoch > baseline
func epochsConverged(t *testing.T, baseline int64) bool {
	t.Helper()
	epochs := getClusterEpochs(t)
	if len(epochs) == 0 {
		return false
	}

	// All must be > baseline
	for _, e := range epochs {
		if e <= baseline {
			return false
		}
	}

	// All must match
	first := epochs[0]
	for _, e := range epochs[1:] {
		if e != first {
			return false
		}
	}

	return true
}

func getClusterEpochs(t *testing.T) []int64 {
	t.Helper()

	nodes, err := getLiveNodeAddresses()
	if err != nil {
		t.Fatalf("Failed to list cluster nodes: %v", err)
	}

	epochs := make([]int64, 0, len(nodes))

	for _, addr := range nodes {
		url := fmt.Sprintf("%s/metadata", addr)
		resp, err := http.Get(url)
		if err != nil {
			t.Fatalf("Failed to GET %s: %v", url, err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			body, _ := io.ReadAll(resp.Body)
			t.Fatalf("Metadata returned %d: %s", resp.StatusCode, string(body))
		}

		var metaResp struct {
			Metadata struct {
				Version struct {
					Epoch   int64  `json:"epoch"`
					Counter int64  `json:"counter"`
					NodeID  string `json:"node_id"`
				} `json:"version"`
				ActiveSnapshot string `json:"active_snapshot"`
				Hash           string `json:"hash"`
				Valid          bool   `json:"valid"`
			} `json:"metadata"`
		}

		if err := json.NewDecoder(resp.Body).Decode(&metaResp); err != nil {
			t.Fatalf("Failed to decode metadata JSON: %v", err)
		}

		epochs = append(epochs, metaResp.Metadata.Version.Epoch)
	}

	return epochs
}

func getAnyClusterEpoch(t *testing.T) int64 {
	t.Helper()
	epochs := getClusterEpochs(t)
	if len(epochs) == 0 {
		t.Fatalf("No cluster nodes found")
	}

	max := epochs[0]
	for _, e := range epochs[1:] {
		if e > max {
			max = e
		}
	}
	return max
}

func patchStateValue(t *testing.T, key string, value any) {
	t.Helper()

	payload := map[string]any{
		key: value,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("Failed to marshal patch payload: %v", err)
	}

	req, err := http.NewRequest(http.MethodPatch, valueURL, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to create PATCH request for key %s: %v", key, err)
	}

	req.Header.Set("Content-Type", api.JsonMIMEType)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Failed to PATCH state key %s: %v", key, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("patchStateValue: unexpected status %d: %s", resp.StatusCode, string(body))
	}
}

func setStateValue(t *testing.T, key string, value any) {
	t.Helper()

	payload := map[string]any{
		key: value,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("Failed to marshal setState payload: %v", err)
	}

	resp, err := http.Post(valueURL, api.JsonMIMEType, bytes.NewBuffer(jsonData))
	if err != nil {
		t.Fatalf("Failed to set state key %s: %v", key, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("setStateValue: unexpected status %d: %s", resp.StatusCode, string(body))
	}
}

func getStateValue(t *testing.T, key string) any {
	t.Helper()

	url := fmt.Sprintf("%s?key=%s", valueURL, key)
	resp, err := http.Get(url)
	if err != nil {
		t.Fatalf("Failed to get state key %s: %v", key, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil
	}

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("getStateValue: unexpected status %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		Exists bool `json:"exists"`
		Value  any  `json:"value"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		t.Fatalf("Failed to decode getStateValue JSON: %v", err)
	}

	if !result.Exists {
		return nil
	}

	return result.Value
}

func TestSnapshotRestoresStateExactly(t *testing.T) {
	initialEpoch := getAnyClusterEpoch(t)

	// Use unique keys to avoid interference with other tests
	snapshotName := fmt.Sprintf("exact_state_%d", time.Now().UnixNano())
	fooKey := snapshotName + "_foo"
	barKey := snapshotName + "_bar"
	bazKey := snapshotName + "_baz"

	// Set initial state
	patchStateValue(t, fooKey, 1)
	patchStateValue(t, barKey, 2)

	// Create snapshot capturing this state
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}

	// Mutate state after snapshot:
	//    - change foo
	//    - add baz
	patchStateValue(t, fooKey, 9)
	patchStateValue(t, bazKey, 3)

	// Sanity check: mutations took effect locally
	if asInt(getStateValue(t, fooKey)) != 9 {
		t.Fatalf("Pre-activation sanity: expected %s=9, got %v", fooKey, getStateValue(t, fooKey))
	}
	if asInt(getStateValue(t, barKey)) != 2 {
		t.Fatalf("Pre-activation sanity: expected %s=2, got %v", barKey, getStateValue(t, barKey))
	}
	if asInt(getStateValue(t, bazKey)) != 3 {
		t.Fatalf("Pre-activation sanity: expected %s=3, got %v", bazKey, getStateValue(t, bazKey))
	}

	// Activate the snapshot
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	if _, err := (&http.Client{}).Do(req); err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}

	// Wait for epoch convergence to ensure activation fully applied cluster-wide
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return epochsConverged(t, initialEpoch)
	}) {
		t.Fatalf("Epochs did not converge after activation; initial=%d, epochs=%v",
			initialEpoch, getClusterEpochs(t))
	}

	// Validate final state matches snapshot exactly:
	//    foo restored to 1, bar still 2, baz removed.
	if got := asInt(getStateValue(t, fooKey)); got != 1 {
		t.Fatalf("After snapshot activation: expected %s=1, got %v", fooKey, got)
	}
	if got := asInt(getStateValue(t, barKey)); got != 2 {
		t.Fatalf("After snapshot activation: expected %s=2, got %v", barKey, got)
	}
	if v := getStateValue(t, bazKey); v != nil {
		t.Fatalf("After snapshot activation: expected %s to be removed, got %v", bazKey, v)
	}
}

func TestSnapshotRestoresNestedState(t *testing.T) {
	initialEpoch := getAnyClusterEpoch(t)

	snapshotName := fmt.Sprintf("nested_state_%d", time.Now().UnixNano())
	configKey := snapshotName + "_config"

	// Set initial nested state
	initialConfig := map[string]any{
		"a": 1,
		"b": []any{10, 20},
	}
	setStateValue(t, configKey, initialConfig)

	// Sanity check
	if v := getStateValue(t, configKey); v == nil {
		t.Fatalf("Pre-snapshot sanity: expected nested value for %s, got nil", configKey)
	}

	// Create snapshot capturing this nested state
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create nested snapshot: %v", err)
	}

	// Mutate nested state after snapshot
	mutatedConfig := map[string]any{
		"a": 9,
		"b": []any{99},
	}
	patchStateValue(t, configKey, mutatedConfig)

	// Activate the snapshot
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	if _, err := (&http.Client{}).Do(req); err != nil {
		t.Fatalf("Failed to activate nested snapshot: %v", err)
	}

	// Wait for epoch convergence to ensure activation fully applied
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return epochsConverged(t, initialEpoch)
	}) {
		t.Fatalf("Epochs did not converge after nested snapshot activation; initial=%d, epochs=%v",
			initialEpoch, getClusterEpochs(t))
	}

	// Validate full config restored
	val := getStateValue(t, configKey)
	cfg, ok := val.(map[string]any)
	if !ok {
		t.Fatalf("Expected map[string]any for %s, got %T (%v)", configKey, val, val)
	}

	if asInt(cfg["a"]) != 1 {
		t.Fatalf("Expected %s.a = 1 after activation, got %v", configKey, cfg["a"])
	}

	bSlice, ok := cfg["b"].([]any)
	if !ok {
		t.Fatalf("Expected %s.b to be []any, got %T (%v)", configKey, cfg["b"], cfg["b"])
	}
	if len(bSlice) != 2 || asInt(bSlice[0]) != 10 || asInt(bSlice[1]) != 20 {
		t.Fatalf("Expected %s.b = [10,20], got %v", configKey, bSlice)
	}

	// Validate path-based lookups still work
	valA := getStateValue(t, configKey+".a")
	if asInt(valA) != 1 {
		t.Fatalf("Path lookup %s.a expected 1, got %v", configKey, valA)
	}

	valB1 := getStateValue(t, configKey+".b[1]")
	if asInt(valB1) != 20 {
		t.Fatalf("Path lookup %s.b[1] expected 20, got %v", configKey, valB1)
	}
}

// Logs snapshot list for each node to help diagnose propagation failures.
func logPerNodeSnapshotStatus(t *testing.T, snapshotName string) {
	t.Helper()

	nodes, err := getLiveNodeAddresses()
	if err != nil {
		t.Logf("Error retrieving node addresses: %v", err)
		return
	}

	t.Logf("---- Snapshot propagation debug for %q ----", snapshotName)

	for _, addr := range nodes {
		url := fmt.Sprintf("%s/snapshots", addr)
		resp, err := http.Get(url)
		if err != nil {
			t.Logf("[%s] ERROR: %v", addr, err)
			continue
		}

		var list struct {
			Snapshots []string `json:"snapshots"`
		}

		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			t.Logf("[%s] status=%d body=%s", addr, resp.StatusCode, string(body))
			continue
		}

		if err := json.Unmarshal(body, &list); err != nil {
			t.Logf("[%s] JSON decode error: %v (body=%s)", addr, err, string(body))
			continue
		}

		has := slices.Contains(list.Snapshots, snapshotName)
		mark := "❌"
		if has {
			mark = "✔️"
		}

		t.Logf("[%s] %s snapshots=%v", addr, mark, list.Snapshots)
	}

	t.Log("-------------------------------------------------")
}

func TestActiveSnapshotPropagatesClusterWide(t *testing.T) {
	snapshotName := fmt.Sprintf("active_snap_%d", time.Now().UnixNano())

	// Create
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}

	// Activate
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	if _, err := (&http.Client{}).Do(req); err != nil {
		t.Fatalf("Failed to activate snapshot: %v", err)
	}

	// Wait for propagation
	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		return activeSnapshotMatchesAllNodes(t, snapshotName)
	})
	if !ok {
		t.Fatalf("Active snapshot did not propagate; got=%v", getClusterActiveSnapshots(t))
	}
}

func activeSnapshotMatchesAllNodes(t *testing.T, expected string) bool {
	snaps := getClusterActiveSnapshots(t)
	if len(snaps) == 0 {
		return false
	}
	for _, s := range snaps {
		if s != expected {
			return false
		}
	}
	return true
}

func getClusterActiveSnapshots(t *testing.T) []string {
	t.Helper()

	nodes, err := getLiveNodeAddresses()
	if err != nil {
		t.Fatalf("failed to get nodes: %v", err)
	}

	out := make([]string, 0, len(nodes))
	for _, addr := range nodes {
		resp, err := http.Get(fmt.Sprintf("%s/metadata", addr))
		if err != nil {
			t.Fatalf("GET metadata failed: %v", err)
		}
		defer resp.Body.Close()

		var metaResp struct {
			Metadata struct {
				ActiveSnapshot string `json:"active_snapshot"`
			} `json:"metadata"`
		}

		if err := json.NewDecoder(resp.Body).Decode(&metaResp); err != nil {
			t.Fatalf("Decode metadata: %v", err)
		}

		out = append(out, metaResp.Metadata.ActiveSnapshot)
	}

	return out
}

func TestActiveSnapshotSurvivesRestart(t *testing.T) {
	snapshotName := fmt.Sprintf("persist_snap_%d", time.Now().UnixNano())

	// Create
	http.Post(fmt.Sprintf("%s/%s", snapshotsURL, snapshotName), api.JsonMIMEType, nil)

	// Activate
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	(&http.Client{}).Do(req)

	// Wait for propagation
	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		return activeSnapshotMatchesAllNodes(t, snapshotName)
	})
	if !ok {
		t.Fatalf("Active snapshot mismatch before restart: %v", getClusterActiveSnapshots(t))
	}

	restartAllNodes(t)

	if !waitForAllNodesReady(10 * time.Second) {
		t.Fatalf("Cluster did not become ready after restart")
	}

	ok = waitForSnapshotSync(snapshotSyncTime, func() bool {
		return activeSnapshotMatchesAllNodes(t, snapshotName)
	})
	if !ok {
		t.Fatalf("Active snapshot mismatch after restart: %v", getClusterActiveSnapshots(t))
	}
}

func TestSnapshotDataSurvivesRestart(t *testing.T) {
	initialEpoch := getAnyClusterEpoch(t)

	snapshotName := fmt.Sprintf("persist_data_%d", time.Now().UnixNano())

	// Unique keys to avoid collisions with other tests
	fooKey := snapshotName + "_foo"
	barKey := snapshotName + "_bar"
	nestedKey := snapshotName + "_nested"
	removedKey := snapshotName + "_to_be_removed"

	// --- Initial state (before snapshot) ---
	patchStateValue(t, fooKey, 111)
	patchStateValue(t, barKey, 222)
	patchStateValue(t, removedKey, 999)

	initialNested := map[string]any{
		"a": 1,
		"b": []any{10, 20},
	}
	patchStateValue(t, nestedKey, initialNested)

	// Make sure the state is synchronized before snapshot creation
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return asInt(getStateValue(t, fooKey)) == 111 &&
			asInt(getStateValue(t, barKey)) == 222 &&
			getStateValue(t, removedKey) != nil &&
			getStateValue(t, nestedKey) != nil
	}) {
		t.Fatalf("Pre-snapshot convergence failed: foo=%v bar=%v removed=%v nested=%v",
			getStateValue(t, fooKey),
			getStateValue(t, barKey),
			getStateValue(t, removedKey),
			getStateValue(t, nestedKey),
		)
	}

	// Create snapshot capturing the above state
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot %q: %v", snapshotName, err)
	}

	//  Mutate state after snapshot
	patchStateValue(t, fooKey, 999)
	patchStateValue(t, barKey, 444)
	patchStateValue(t, nestedKey, map[string]any{"a": 9})
	patchStateValue(t, removedKey, nil)

	// Validate post-snapshot mutations applied
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return asInt(getStateValue(t, fooKey)) == 999 &&
			asInt(getStateValue(t, barKey)) == 444
	}) {
		t.Fatalf("Post-snapshot mutation sanity check failed: foo=%v bar=%v",
			getStateValue(t, fooKey), getStateValue(t, barKey))
	}

	restartAllNodes(t)

	// Activate snapshot after restart
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	if _, err := (&http.Client{}).Do(req); err != nil {
		t.Fatalf("Failed to activate snapshot after restart: %v", err)
	}

	// Wait for cluster to converge to the new epoch
	if !waitForSnapshotSync(snapshotSyncTime, func() bool {
		return epochsConverged(t, initialEpoch)
	}) {
		t.Fatalf("Epochs did not converge after restart + activation; initial=%d, epochs=%v",
			initialEpoch, getClusterEpochs(t))
	}

	// foo restored
	if got := asInt(getStateValue(t, fooKey)); got != 111 {
		t.Fatalf("After restart+activation: expected %s=111, got %v", fooKey, got)
	}

	// bar restored
	if got := asInt(getStateValue(t, barKey)); got != 222 {
		t.Fatalf("After restart+activation: expected %s=222, got %v", barKey, got)
	}

	// nested restored
	nv := getStateValue(t, nestedKey)
	nested, ok := nv.(map[string]any)
	if !ok {
		t.Fatalf("Expected nested map for %s, got %T (%v)", nestedKey, nv, nv)
	}
	if asInt(nested["a"]) != 1 {
		t.Fatalf("Expected %s.a=1, got %v", nestedKey, nested["a"])
	}
	b := nested["b"].([]any)
	if len(b) != 2 || asInt(b[0]) != 10 || asInt(b[1]) != 20 {
		t.Fatalf("Expected %s.b=[10,20], got %v", nestedKey, b)
	}

	if got := asInt(getStateValue(t, removedKey)); got != 999 {
		t.Fatalf("After restart+activation: expected snapshot to restore %s=999, got %v",
			removedKey, got)
	}
}

func TestSnapshotActivationOutOfOrderMessages(t *testing.T) {
	snapshotName := fmt.Sprintf("ooom_%d", time.Now().UnixNano())

	// Create snapshot
	http.Post(fmt.Sprintf("%s/%s", snapshotsURL, snapshotName), api.JsonMIMEType, nil)

	//
	// Simulate out-of-order delivery:
	// 1. Apply a state update first (ConfigUpdate)
	// 2. Activate snapshot
	//
	// This is realistic because memberlist gossip does not guarantee ordering.
	//
	patchStateValue(t, "ooom_key", 123)

	// Activate snapshot
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)

	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	(&http.Client{}).Do(req)

	// Must converge to the new active snapshot on all nodes
	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		return activeSnapshotMatchesAllNodes(t, snapshotName)
	})
	if !ok {
		t.Fatalf("Active snapshot not synchronized after out-of-order handling: %v",
			getClusterActiveSnapshots(t))
	}
}

func TestDeleteActiveSnapshotResetsActiveSnapshot(t *testing.T) {
	snapshotName := fmt.Sprintf("delete_active_%d", time.Now().UnixNano())

	// Create and activate
	http.Post(fmt.Sprintf("%s/%s", snapshotsURL, snapshotName), api.JsonMIMEType, nil)
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)
	req, _ := http.NewRequest(http.MethodPost, activateURL, nil)
	(&http.Client{}).Do(req)

	waitForSnapshotSync(snapshotSyncTime, func() bool {
		return activeSnapshotMatchesAllNodes(t, snapshotName)
	})

	// Delete the active snapshot
	req, _ = http.NewRequest(http.MethodDelete, fmt.Sprintf("%s/%s", snapshotsURL, snapshotName), nil)
	(&http.Client{}).Do(req)

	// After deletion, active snapshot should be cleared uniformly
	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		snaps := getClusterActiveSnapshots(t)
		for _, s := range snaps {
			if s != "default" {
				return false
			}
		}
		return true
	})

	if !ok {
		t.Fatalf("Active snapshot not reset after deletion: %v", getClusterActiveSnapshots(t))
	}
}

func restartAllNodes(t *testing.T) {
	t.Helper()

	// I can't get the go test runner to use a relative path!!!
	script := "/Users/gragan/inprogress/bose/fusion-monorepo/apps/firmware-apps/fusion-server/scripts/multipass/restart-fusion.sh"

	cmd := exec.Command(script)
	cmd.Dir = "" // ensure it uses the test's actual working directory

	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("restart-fusion failed: %v\nOutput:\n%s", err, out)
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

func asInt(v any) int {
	switch n := v.(type) {
	case float64:
		return int(n)
	case int:
		return n
	default:
		return 0
	}
}

func getLiveNodeAddresses() ([]string, error) {
	resp, err := http.Get(fmt.Sprintf("%s/cluster/members", snapServerAddr))
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
		nodes = append(nodes, fmt.Sprintf("http://%s:%s", m.Addr, snapServerPort))
	}
	return nodes, nil
}

func waitForAllNodesReady(timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)

	for time.Now().Before(deadline) {
		nodes, err := getLiveNodeAddresses()
		if err != nil || len(nodes) == 0 {
			time.Sleep(100 * time.Millisecond)
			continue
		}

		allOK := true
		for _, addr := range nodes {
			url := fmt.Sprintf("%s/metadata", addr)
			resp, err := http.Get(url)
			if err != nil {
				allOK = false
				break
			}
			resp.Body.Close()
		}

		if allOK {
			return true
		}

		time.Sleep(100 * time.Millisecond)
	}

	return false
}

func TestSnapshotUpdateOverwritesState(t *testing.T) {
	snapshotName := fmt.Sprintf("update_test_%d", time.Now().UnixNano())
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	updateURL := strings.Replace(snapshotUpdateURL, nameParam, snapshotName, 1)
	activateURL := strings.Replace(snapshotActivateURL, nameParam, snapshotName, 1)

	key := snapshotName + "_foo"

	// Set initial state
	patchStateValue(t, key, 100)

	// Create snapshot (contains foo = 100)
	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}

	// Mutate state after snapshot (foo = 200)
	patchStateValue(t, key, 200)
	if asInt(getStateValue(t, key)) != 200 {
		t.Fatalf("Sanity check: expected foo=200, got %v", getStateValue(t, key))
	}

	// Overwrite snapshot via /save (snapshot now stores foo = 200)
	req, _ := http.NewRequest(http.MethodPost, updateURL, nil)
	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		t.Fatalf("Failed to update snapshot: %v", err)
	}
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Snapshot update returned %d: %s", resp.StatusCode, string(body))
	}

	// Mutate live state again (foo = 300)
	patchStateValue(t, key, 300)
	if asInt(getStateValue(t, key)) != 300 {
		t.Fatalf("Sanity check: expected foo=300, got %v", getStateValue(t, key))
	}

	// Activate updated snapshot (should restore foo = 200)
	req, _ = http.NewRequest(http.MethodPost, activateURL, nil)
	if _, err := (&http.Client{}).Do(req); err != nil {
		t.Fatalf("Failed to activate updated snapshot: %v", err)
	}

	// Wait for state to reflect the restored snapshot value
	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		return asInt(getStateValue(t, key)) == 200
	})
	if !ok {
		t.Fatalf(
			"After snapshot update + activation: expected %s=200, got %v",
			key, getStateValue(t, key),
		)
	}
}

func TestSnapshotUpdateDoesNotBumpEpoch(t *testing.T) {
	snapshotName := fmt.Sprintf("update_epoch_%d", time.Now().UnixNano())
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	updateURL := strings.Replace(snapshotUpdateURL, nameParam, snapshotName, 1)

	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}

	before := getAnyClusterEpoch(t)

	req, _ := http.NewRequest(http.MethodPost, updateURL, nil)
	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		t.Fatalf("Failed to update snapshot: %v", err)
	}
	resp.Body.Close()

	after := getAnyClusterEpoch(t)

	if after != before {
		t.Fatalf("Snapshot update incorrectly bumped epoch: before=%d after=%d", before, after)
	}
}

func TestSnapshotUpdateDoesNotChangeActiveSnapshot(t *testing.T) {
	snapshotName := fmt.Sprintf("update_active_%d", time.Now().UnixNano())
	createURL := strings.Replace(snapshotByNameURL, nameParam, snapshotName, 1)
	updateURL := strings.Replace(snapshotUpdateURL, nameParam, snapshotName, 1)

	if _, err := http.Post(createURL, api.JsonMIMEType, nil); err != nil {
		t.Fatalf("Failed to create snapshot: %v", err)
	}

	activeBefore := getClusterActiveSnapshots(t)

	req, _ := http.NewRequest(http.MethodPost, updateURL, nil)
	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		t.Fatalf("Failed to update snapshot: %v", err)
	}
	resp.Body.Close()

	activeAfter := getClusterActiveSnapshots(t)

	if len(activeBefore) != len(activeAfter) {
		t.Fatalf("Active snapshot count changed after update")
	}

	for i := range activeBefore {
		if activeBefore[i] != activeAfter[i] {
			t.Fatalf("Active snapshot changed after update: before=%v after=%v", activeBefore, activeAfter)
		}
	}
}
