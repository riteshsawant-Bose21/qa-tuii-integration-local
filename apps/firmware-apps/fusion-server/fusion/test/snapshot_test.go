//go:build !parallel

package main

import (
	"bytes"
	"fmt"
	"fusion-services-core/logging"
	"fusion/internal/api"
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
	snapshotsURL        = snapServerAddr + routes.TimeMachineEndpoint
	snapshotByNameURL   = snapServerAddr + routes.TimeMachineNameEndpoint
	snapshotActivateURL = snapServerAddr + routes.TimeMachineActivateEndpoint
	snapshotUpdateURL   = snapServerAddr + routes.TimeMachineUpdateEndpoint
	valueURL            = snapServerAddr + routes.ValueEndpoint

	// Scene catalog endpoints
	snapshotDefsActivateURL = snapServerAddr + routes.SnapshotsActivateEndpoint
	snapshotDefsListURL     = snapServerAddr + routes.SnapshotsListEndpoint
	scenesListURL           = snapServerAddr + routes.ScenesListEndpoint
	sceneSetsActivateURL    = snapServerAddr + routes.SceneSetsActivateEndpoint
	sceneSetsCurrentURL     = snapServerAddr + routes.SceneSetsCurrentEndpoint
	sceneSetsListURL        = snapServerAddr + routes.SceneSetsListEndpoint
	sceneCatalogListURL     = snapServerAddr + routes.SceneCatalogListEndpoint
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
		resp, err := http.Get(fmt.Sprintf("%s%s", addr, routes.TimeMachineEndpoint))
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
		resp, err := http.Get(fmt.Sprintf("%s%s", addr, routes.TimeMachineEndpoint))
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
		url := fmt.Sprintf("%s/time-machine", addr)
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

// =============================================================================
// Scene Catalog Foundation Tests
//
// These tests cover:
//   - Snapshot definition upsert via POST/PATCH /value
//   - Snapshot definition activation via POST /snapshots/activate
//   - Scene set upsert via POST/PATCH /value
//   - Scene activation via POST /scene-sets/activate
//   - Current scene query via POST /scene-sets/current-scene
//   - List endpoints: /snapshots/list, /scenes/list, /scene-sets/list, /scene-catalog-list
// =============================================================================

// upsertSnapshotDefs sends a POST /value payload containing snapshot definitions only.
// Fails the test if the request itself errors or returns an unexpected status.
func upsertSnapshotDefs(t *testing.T, defs []api.SnapshotDefinition) {
	t.Helper()
	payload, _ := json.Marshal(map[string]any{"snapshots": defs})
	resp, err := http.Post(valueURL, api.JsonMIMEType, bytes.NewBuffer(payload))
	if err != nil {
		t.Fatalf("upsertSnapshotDefs: POST request failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("upsertSnapshotDefs: unexpected status %d: %s", resp.StatusCode, string(body))
	}
}

// upsertSceneSets sends a POST /value payload containing scene sets only.
// Fails the test if the request itself errors or returns an unexpected status.
func upsertSceneSets(t *testing.T, sets []api.SceneSet) {
	t.Helper()
	payload, _ := json.Marshal(map[string]any{"scene_sets": sets})
	resp, err := http.Post(valueURL, api.JsonMIMEType, bytes.NewBuffer(payload))
	if err != nil {
		t.Fatalf("upsertSceneSets: POST request failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("upsertSceneSets: unexpected status %d: %s", resp.StatusCode, string(body))
	}
}

// activateSnapshotDef sends POST /snapshots/activate and returns the response.
func activateSnapshotDef(t *testing.T, id string) *http.Response {
	t.Helper()
	payload, _ := json.Marshal(api.ActivateSnapshotRequest{ID: id})
	resp, err := http.Post(snapshotDefsActivateURL, api.JsonMIMEType, bytes.NewBuffer(payload))
	if err != nil {
		t.Fatalf("activateSnapshotDef: POST request failed: %v", err)
	}
	return resp
}

// activateScene sends POST /scene-sets/activate and returns the response.
func activateScene(t *testing.T, setID, sceneID string) *http.Response {
	t.Helper()
	payload, _ := json.Marshal(api.ActivateSceneSetRequest{SetID: setID, SceneID: sceneID})
	resp, err := http.Post(sceneSetsActivateURL, api.JsonMIMEType, bytes.NewBuffer(payload))
	if err != nil {
		t.Fatalf("activateScene: POST request failed: %v", err)
	}
	return resp
}

// getCurrentScene sends POST /scene-sets/current-scene and returns the decoded response.
func getCurrentScene(t *testing.T, setID string) api.CurrentSceneResponse {
	t.Helper()
	payload, _ := json.Marshal(map[string]string{"set_id": setID})
	resp, err := http.Post(sceneSetsCurrentURL, api.JsonMIMEType, bytes.NewBuffer(payload))
	if err != nil {
		t.Fatalf("getCurrentScene: POST request failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("getCurrentScene: unexpected status %d: %s", resp.StatusCode, string(body))
	}
	var out api.CurrentSceneResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		t.Fatalf("getCurrentScene: failed to decode response: %v", err)
	}
	return out
}

// =============================================================================
// Snapshot Definition Tests
// =============================================================================

// TestSnapshotDefUpsertViaPost verifies that snapshot definitions POSTed to /value
// are persisted and show up in the /snapshots/list response.
func TestSnapshotDefUpsertViaPost(t *testing.T) {
	id := fmt.Sprintf("snap-def-post-%d", time.Now().UnixNano())
	def := api.SnapshotDefinition{
		ID:   id,
		Name: "Test Snapshot (POST)",
		Data: map[string]any{id + "_gain": -6.0},
	}

	upsertSnapshotDefs(t, []api.SnapshotDefinition{def})

	resp, err := http.Get(snapshotDefsListURL)
	if err != nil {
		t.Fatalf("GET /snapshots/list failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("List snapshot defs returned %d: %s", resp.StatusCode, string(body))
	}

	var listResp api.SnapshotListResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode snapshot list response: %v", err)
	}

	found := false
	for _, s := range listResp.Snapshots {
		if s.ID == id {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Snapshot def %s not found in /snapshots/list", id)
	}
}

// TestSnapshotDefUpsertViaPatch verifies that snapshot definitions PATCHed to /value
// are persisted and show up in /snapshots/list.
func TestSnapshotDefUpsertViaPatch(t *testing.T) {
	id := fmt.Sprintf("snap-def-patch-%d", time.Now().UnixNano())
	def := api.SnapshotDefinition{
		ID:   id,
		Name: "Test Snapshot (PATCH)",
		Data: map[string]any{id + "_gain": -3.0},
	}

	payload, _ := json.Marshal(map[string]any{"snapshots": []api.SnapshotDefinition{def}})
	req, _ := http.NewRequest(http.MethodPatch, valueURL, bytes.NewBuffer(payload))
	req.Header.Set("Content-Type", api.JsonMIMEType)
	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		t.Fatalf("PATCH /value failed: %v", err)
	}
	resp.Body.Close()

	resp, err = http.Get(snapshotDefsListURL)
	if err != nil {
		t.Fatalf("GET /snapshots/list failed: %v", err)
	}
	defer resp.Body.Close()

	var listResp api.SnapshotListResponse
	json.NewDecoder(resp.Body).Decode(&listResp)

	found := false
	for _, s := range listResp.Snapshots {
		if s.ID == id {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Snapshot def %s not found in /snapshots/list after PATCH", id)
	}
}

// TestActivateSnapshotDef_MissingID verifies that POST /snapshots/activate with no id
// returns 400.
func TestActivateSnapshotDef_MissingID(t *testing.T) {
	resp, err := http.Post(snapshotDefsActivateURL, api.JsonMIMEType, bytes.NewBufferString(`{}`))
	if err != nil {
		t.Fatalf("POST /snapshots/activate failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("Expected 400 for missing id, got %d", resp.StatusCode)
	}
}

// TestActivateSnapshotDef_NotFound verifies that POST /snapshots/activate with a
// non-existent id returns 404.
func TestActivateSnapshotDef_NotFound(t *testing.T) {
	resp := activateSnapshotDef(t, "snapshot-does-not-exist-at-all")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 404 for non-existent snapshot, got %d: %s", resp.StatusCode, string(body))
	}
}

// TestActivateSnapshotDef_PatchesState creates a snapshot definition whose data
// contains a unique key, activates it, and verifies that the key appears in DB State.
func TestActivateSnapshotDef_PatchesState(t *testing.T) {
	id := fmt.Sprintf("snap-def-activate-%d", time.Now().UnixNano())
	stateKey := id + "_gain_db"
	stateVal := -9.0

	def := api.SnapshotDefinition{
		ID:   id,
		Name: "Activation test",
		Data: map[string]any{stateKey: stateVal},
	}
	upsertSnapshotDefs(t, []api.SnapshotDefinition{def})

	resp := activateSnapshotDef(t, id)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate snapshot def returned %d: %s", resp.StatusCode, string(body))
	}

	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		val := getStateValue(t, stateKey)
		if f, ok := val.(float64); ok {
			return f == stateVal
		}
		return false
	})
	if !ok {
		t.Fatalf("State key %s not patched after snapshot def activation; got %v",
			stateKey, getStateValue(t, stateKey))
	}
}

// TestSnapshotDefClobberOnDuplicateID verifies that posting a snapshot def with the
// same ID twice overwrites the first (clobber semantics).
func TestSnapshotDefClobberOnDuplicateID(t *testing.T) {
	id := fmt.Sprintf("snap-def-clobber-%d", time.Now().UnixNano())
	stateKey := id + "_val"

	// First definition: stateKey = 1.0
	upsertSnapshotDefs(t, []api.SnapshotDefinition{
		{ID: id, Name: "First", Data: map[string]any{stateKey: 1.0}},
	})

	// Overwrite with second definition: stateKey = 2.0
	upsertSnapshotDefs(t, []api.SnapshotDefinition{
		{ID: id, Name: "Second", Data: map[string]any{stateKey: 2.0}},
	})

	// Activate the definition
	resp := activateSnapshotDef(t, id)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate returned %d: %s", resp.StatusCode, string(body))
	}

	// State should reflect the clobbered (second) definition
	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		val := getStateValue(t, stateKey)
		if f, ok := val.(float64); ok {
			return f == 2.0
		}
		return false
	})
	if !ok {
		t.Fatalf("Clobber: expected %s=2.0, got %v", stateKey, getStateValue(t, stateKey))
	}
}

// =============================================================================
// Scene Set + Scene Tests
// =============================================================================

// TestSceneSetUpsertViaPost verifies that scene sets POSTed to /value appear in
// /scene-sets/list.
func TestSceneSetUpsertViaPost(t *testing.T) {
	setID := fmt.Sprintf("set-post-%d", time.Now().UnixNano())
	sceneID := setID + "-scene-a"
	set := api.SceneSet{
		SetID: setID,
		Name:  "Test Set (POST)",
		Scenes: []api.Scene{
			{ID: sceneID, Name: "Scene A", Data: map[string]any{sceneID + "_gain": -3.0}},
		},
	}

	upsertSceneSets(t, []api.SceneSet{set})

	resp, err := http.Get(sceneSetsListURL)
	if err != nil {
		t.Fatalf("GET /scene-sets/list failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("List scene sets returned %d: %s", resp.StatusCode, string(body))
	}

	var listResp api.SceneSetListResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode scene set list response: %v", err)
	}

	found := false
	for _, s := range listResp.SceneSets {
		if s.SetID == setID {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("Scene set %s not found in /scene-sets/list", setID)
	}
}

// TestActivateScene_MissingFields verifies that POST /scene-sets/activate with empty
// set_id or scene_id returns 400.
func TestActivateScene_MissingFields(t *testing.T) {
	cases := []struct {
		label string
		body  string
	}{
		{"empty body", `{}`},
		{"missing scene_id", `{"set_id":"x"}`},
		{"missing set_id", `{"scene_id":"y"}`},
	}

	for _, tc := range cases {
		t.Run(tc.label, func(t *testing.T) {
			resp, err := http.Post(sceneSetsActivateURL, api.JsonMIMEType, bytes.NewBufferString(tc.body))
			if err != nil {
				t.Fatalf("POST /scene-sets/activate failed: %v", err)
			}
			defer resp.Body.Close()
			if resp.StatusCode != http.StatusBadRequest {
				t.Errorf("Expected 400 for %q, got %d", tc.label, resp.StatusCode)
			}
		})
	}
}

// TestActivateScene_SetNotFound verifies 404 when the scene set does not exist.
func TestActivateScene_SetNotFound(t *testing.T) {
	resp := activateScene(t, "set-does-not-exist-xyz", "scene-abc")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 404 for missing scene set, got %d: %s", resp.StatusCode, string(body))
	}
}

// TestActivateScene_SceneNotMember verifies 409 when the scene_id is not part of the set.
func TestActivateScene_SceneNotMember(t *testing.T) {
	setID := fmt.Sprintf("set-notmember-%d", time.Now().UnixNano())
	sceneID := setID + "-scene-real"
	set := api.SceneSet{
		SetID: setID,
		Scenes: []api.Scene{
			{ID: sceneID, Data: map[string]any{}},
		},
	}
	upsertSceneSets(t, []api.SceneSet{set})

	resp := activateScene(t, setID, "scene-not-in-this-set-ever")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusConflict {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 409 for scene not in set, got %d: %s", resp.StatusCode, string(body))
	}
}

// TestActivateScene_PatchesState creates a scene set with one scene carrying unique
// state data, activates that scene, and verifies the data was merged into DB State.
func TestActivateScene_PatchesState(t *testing.T) {
	setID := fmt.Sprintf("set-activate-%d", time.Now().UnixNano())
	sceneID := setID + "-scene-b"
	stateKey := setID + "_level"
	stateVal := -12.0

	set := api.SceneSet{
		SetID: setID,
		Name:  "Activation test set",
		Scenes: []api.Scene{
			{ID: sceneID, Name: "Scene B", Data: map[string]any{stateKey: stateVal}},
		},
	}
	upsertSceneSets(t, []api.SceneSet{set})

	resp := activateScene(t, setID, sceneID)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate scene returned %d: %s", resp.StatusCode, string(body))
	}

	ok := waitForSnapshotSync(snapshotSyncTime, func() bool {
		val := getStateValue(t, stateKey)
		if f, ok := val.(float64); ok {
			return f == stateVal
		}
		return false
	})
	if !ok {
		t.Fatalf("State key %s not patched after scene activation; got %v",
			stateKey, getStateValue(t, stateKey))
	}
}

// =============================================================================
// Current Scene Tests
// =============================================================================

// TestGetCurrentScene_MissingSetID verifies a 400 when set_id is omitted.
func TestGetCurrentScene_MissingSetID(t *testing.T) {
	resp, err := http.Post(sceneSetsCurrentURL, api.JsonMIMEType, bytes.NewBufferString(`{}`))
	if err != nil {
		t.Fatalf("POST /scene-sets/current-scene failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("Expected 400 for missing set_id, got %d", resp.StatusCode)
	}
}

// TestGetCurrentScene_SetNotFound verifies a 404 when the set does not exist.
func TestGetCurrentScene_SetNotFound(t *testing.T) {
	payload, _ := json.Marshal(map[string]string{"set_id": "set-does-not-exist-ever"})
	resp, err := http.Post(sceneSetsCurrentURL, api.JsonMIMEType, bytes.NewBuffer(payload))
	if err != nil {
		t.Fatalf("POST /scene-sets/current-scene failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 404 for missing scene set, got %d: %s", resp.StatusCode, string(body))
	}
}

// TestGetCurrentScene_BeforeActivation verifies that querying current scene before
// any activation returns 200 with empty scene_id.
func TestGetCurrentScene_BeforeActivation(t *testing.T) {
	setID := fmt.Sprintf("set-current-before-%d", time.Now().UnixNano())
	sceneID := setID + "-scene-a"
	set := api.SceneSet{
		SetID:  setID,
		Name:   "Current scene test (before)",
		Scenes: []api.Scene{{ID: sceneID, Name: "Scene A", Data: map[string]any{}}},
	}
	upsertSceneSets(t, []api.SceneSet{set})

	result := getCurrentScene(t, setID)
	if result.CurrentScene.SceneID != "" {
		t.Errorf("Expected empty scene_id before activation, got %q", result.CurrentScene.SceneID)
	}
}

// TestGetCurrentScene_AfterActivation verifies that current scene is updated after
// a successful scene activation.
func TestGetCurrentScene_AfterActivation(t *testing.T) {
	setID := fmt.Sprintf("set-current-after-%d", time.Now().UnixNano())
	sceneID := setID + "-scene-morning"
	set := api.SceneSet{
		SetID: setID,
		Name:  "Current scene test (after)",
		Scenes: []api.Scene{
			{ID: sceneID, Name: "Morning", Data: map[string]any{}},
		},
	}
	upsertSceneSets(t, []api.SceneSet{set})

	resp := activateScene(t, setID, sceneID)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate scene returned %d: %s", resp.StatusCode, string(body))
	}

	result := getCurrentScene(t, setID)
	if result.SetID != setID {
		t.Errorf("Expected set_id=%s in response, got %s", setID, result.SetID)
	}
	if result.CurrentScene.SceneID != sceneID {
		t.Errorf("Expected current scene_id=%s, got %s", sceneID, result.CurrentScene.SceneID)
	}
	if result.CurrentScene.Name != "Morning" {
		t.Errorf("Expected current scene name=%q, got %q", "Morning", result.CurrentScene.Name)
	}
}

// TestCurrentSceneUpdatesOnSubsequentActivation verifies that activating a different
// scene in the same set overwrites the stored current scene ID.
func TestCurrentSceneUpdatesOnSubsequentActivation(t *testing.T) {
	setID := fmt.Sprintf("set-current-update-%d", time.Now().UnixNano())
	sceneAID := setID + "-scene-a"
	sceneBID := setID + "-scene-b"
	set := api.SceneSet{
		SetID: setID,
		Name:  "Current scene update test",
		Scenes: []api.Scene{
			{ID: sceneAID, Name: "Scene A", Data: map[string]any{}},
			{ID: sceneBID, Name: "Scene B", Data: map[string]any{}},
		},
	}
	upsertSceneSets(t, []api.SceneSet{set})

	// Activate A
	resp := activateScene(t, setID, sceneAID)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("Activate scene A returned %d", resp.StatusCode)
	}

	// Activate B
	resp = activateScene(t, setID, sceneBID)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("Activate scene B returned %d", resp.StatusCode)
	}

	result := getCurrentScene(t, setID)
	if result.CurrentScene.SceneID != sceneBID {
		t.Errorf("Expected current scene=%s after B activation, got %s", sceneBID, result.CurrentScene.SceneID)
	}
}

// =============================================================================
// List Endpoint Tests
// =============================================================================

// TestListScenes verifies that scenes from all scene sets appear in /scenes/list.
func TestListScenes(t *testing.T) {
	setID := fmt.Sprintf("set-list-scenes-%d", time.Now().UnixNano())
	sceneAID := setID + "-a"
	sceneBID := setID + "-b"
	set := api.SceneSet{
		SetID: setID,
		Scenes: []api.Scene{
			{ID: sceneAID, Name: "A", Data: map[string]any{}},
			{ID: sceneBID, Name: "B", Data: map[string]any{}},
		},
	}
	upsertSceneSets(t, []api.SceneSet{set})

	resp, err := http.Get(scenesListURL)
	if err != nil {
		t.Fatalf("GET /scenes/list failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("List scenes returned %d: %s", resp.StatusCode, string(body))
	}

	var listResp api.SceneListResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode scene list response: %v", err)
	}

	ids := make([]string, len(listResp.Scenes))
	for i, s := range listResp.Scenes {
		ids[i] = s.ID
	}

	if !slices.Contains(ids, sceneAID) {
		t.Errorf("Scene %s not found in /scenes/list: %v", sceneAID, ids)
	}
	if !slices.Contains(ids, sceneBID) {
		t.Errorf("Scene %s not found in /scenes/list: %v", sceneBID, ids)
	}
}

// TestListSnapshotDefinitions verifies that multiple snapshot definitions all appear
// in /snapshots/list.
func TestListSnapshotDefinitions(t *testing.T) {
	prefix := fmt.Sprintf("snap-list-%d", time.Now().UnixNano())
	ids := []string{prefix + "-one", prefix + "-two", prefix + "-three"}
	defs := make([]api.SnapshotDefinition, len(ids))
	for i, id := range ids {
		defs[i] = api.SnapshotDefinition{ID: id, Data: map[string]any{}}
	}
	upsertSnapshotDefs(t, defs)

	resp, err := http.Get(snapshotDefsListURL)
	if err != nil {
		t.Fatalf("GET /snapshots/list failed: %v", err)
	}
	defer resp.Body.Close()

	var listResp api.SnapshotListResponse
	json.NewDecoder(resp.Body).Decode(&listResp)

	listed := make([]string, len(listResp.Snapshots))
	for i, s := range listResp.Snapshots {
		listed[i] = s.ID
	}

	for _, id := range ids {
		if !slices.Contains(listed, id) {
			t.Errorf("Snapshot def %s missing from /snapshots/list: %v", id, listed)
		}
	}
}

// TestListSceneSets verifies that multiple scene sets all appear in /scene-sets/list.
func TestListSceneSets(t *testing.T) {
	prefix := fmt.Sprintf("set-list-%d", time.Now().UnixNano())
	setIDs := []string{prefix + "-alpha", prefix + "-beta"}
	sets := make([]api.SceneSet, len(setIDs))
	for i, id := range setIDs {
		sets[i] = api.SceneSet{SetID: id, Scenes: []api.Scene{{ID: id + "-s1", Data: map[string]any{}}}}
	}
	upsertSceneSets(t, sets)

	resp, err := http.Get(sceneSetsListURL)
	if err != nil {
		t.Fatalf("GET /scene-sets/list failed: %v", err)
	}
	defer resp.Body.Close()

	var listResp api.SceneSetListResponse
	json.NewDecoder(resp.Body).Decode(&listResp)

	listed := make([]string, len(listResp.SceneSets))
	for i, s := range listResp.SceneSets {
		listed[i] = s.SetID
	}

	for _, id := range setIDs {
		if !slices.Contains(listed, id) {
			t.Errorf("Scene set %s missing from /scene-sets/list: %v", id, listed)
		}
	}
}

// =============================================================================
// Scene Catalog List Test
// =============================================================================

// TestSceneCatalogList verifies that /scene-catalog-list returns both snapshot
// definitions and scene sets in the same response.
func TestSceneCatalogList(t *testing.T) {
	prefix := fmt.Sprintf("catalog-%d", time.Now().UnixNano())
	snapID := prefix + "-snap"
	setID := prefix + "-set"

	upsertSnapshotDefs(t, []api.SnapshotDefinition{
		{ID: snapID, Data: map[string]any{}},
	})
	upsertSceneSets(t, []api.SceneSet{
		{SetID: setID, Scenes: []api.Scene{{ID: setID + "-s1", Data: map[string]any{}}}},
	})

	resp, err := http.Get(sceneCatalogListURL)
	if err != nil {
		t.Fatalf("GET /scene-catalog-list failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Scene catalog list returned %d: %s", resp.StatusCode, string(body))
	}

	var catalog api.SceneCatalogListResponse
	if err := json.NewDecoder(resp.Body).Decode(&catalog); err != nil {
		t.Fatalf("Failed to decode catalog response: %v", err)
	}

	snapIDs := make([]string, len(catalog.Snapshots))
	for i, s := range catalog.Snapshots {
		snapIDs[i] = s.ID
	}
	setIDs := make([]string, len(catalog.SceneSets))
	for i, s := range catalog.SceneSets {
		setIDs[i] = s.SetID
	}

	if !slices.Contains(snapIDs, snapID) {
		t.Errorf("Snapshot %s missing from catalog snapshots: %v", snapID, snapIDs)
	}
	if !slices.Contains(setIDs, setID) {
		t.Errorf("Scene set %s missing from catalog scene sets: %v", setID, setIDs)
	}
}
