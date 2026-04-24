//go:build !parallel

package main

import (
	"bytes"
	"fmt"
	"fusion/internal/api"
	"io"
	"net/http"
	"slices"
	"strings"
	"testing"
	"time"

	json "github.com/goccy/go-json"
)

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

func activateSnapshotDef(t *testing.T, id string) *http.Response {
	t.Helper()
	activateURL := strings.Replace(snapshotDefsActivateURL, nameParam, id, 1)
	activateURL = strings.Replace(activateURL, idParam, id, 1)
	resp, err := http.Post(activateURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("activateSnapshotDef: POST request failed: %v", err)
	}
	return resp
}

func activateScene(t *testing.T, setID, sceneID string) *http.Response {
	t.Helper()
	payload, _ := json.Marshal(api.ActivateSceneSetRequest{SetID: setID, SceneID: sceneID})
	resp, err := http.Post(sceneSetsActivateURL, api.JsonMIMEType, bytes.NewBuffer(payload))
	if err != nil {
		t.Fatalf("activateScene: POST request failed: %v", err)
	}
	return resp
}

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

func deleteEndpoint(t *testing.T, endpoint string) *http.Response {
	t.Helper()
	req, err := http.NewRequest(http.MethodDelete, endpoint, nil)
	if err != nil {
		t.Fatalf("DELETE request build failed: %v", err)
	}

	resp, err := (&http.Client{}).Do(req)
	if err != nil {
		t.Fatalf("DELETE request failed: %v", err)
	}

	return resp
}

func deleteEndpointByName(t *testing.T, endpointBase string, name string) *http.Response {
	t.Helper()
	endpoint := strings.TrimRight(endpointBase, "/") + "/" + name
	return deleteEndpoint(t, endpoint)
}

func TestSceneCatalogSnapshotDefUpsertViaPost(t *testing.T) {
	id := fmt.Sprintf("snap-def-post-%d", time.Now().UnixNano())
	def := api.SnapshotDefinition{ID: id, Name: "Test Snapshot (POST)", Data: map[string]any{id + "_gain": -6.0}}

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

func TestSceneCatalogSnapshotDefUpsertViaPatch(t *testing.T) {
	id := fmt.Sprintf("snap-def-patch-%d", time.Now().UnixNano())
	def := api.SnapshotDefinition{ID: id, Name: "Test Snapshot (PATCH)", Data: map[string]any{id + "_gain": -3.0}}

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

func TestSceneCatalogActivateSnapshotDefMissingName(t *testing.T) {
	activateURL := strings.Replace(snapshotDefsActivateURL, nameParam, "", 1)
	activateURL = strings.Replace(activateURL, idParam, "", 1)
	resp, err := http.Post(activateURL, api.JsonMIMEType, nil)
	if err != nil {
		t.Fatalf("POST /snapshots/activate/ failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound && resp.StatusCode != http.StatusMovedPermanently {
		t.Errorf("Expected 404 or 301 for missing name, got %d", resp.StatusCode)
	}
}

func TestSceneCatalogActivateSnapshotDefNotFound(t *testing.T) {
	resp := activateSnapshotDef(t, "snapshot-does-not-exist-at-all")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 404 for non-existent snapshot, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestSceneCatalogActivateSnapshotDefPatchesState(t *testing.T) {
	id := fmt.Sprintf("snap-def-activate-%d", time.Now().UnixNano())
	stateKey := fmt.Sprintf("snap_def_activate_%d_gain_db", time.Now().UnixNano())
	stateVal := -9.0

	def := api.SnapshotDefinition{ID: id, Name: "Activation test", Data: map[string]any{stateKey: stateVal}}
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
		t.Fatalf("State key %s not patched after snapshot def activation; got %v", stateKey, getStateValue(t, stateKey))
	}
}

func TestSceneCatalogSnapshotDefClobberOnDuplicateID(t *testing.T) {
	id := fmt.Sprintf("snap-def-clobber-%d", time.Now().UnixNano())
	stateKey := fmt.Sprintf("snap_def_clobber_%d_val", time.Now().UnixNano())

	upsertSnapshotDefs(t, []api.SnapshotDefinition{{ID: id, Name: "First", Data: map[string]any{stateKey: 1.0}}})
	upsertSnapshotDefs(t, []api.SnapshotDefinition{{ID: id, Name: "Second", Data: map[string]any{stateKey: 2.0}}})

	resp := activateSnapshotDef(t, id)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Activate returned %d: %s", resp.StatusCode, string(body))
	}

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

func TestSceneCatalogSceneSetUpsertViaPost(t *testing.T) {
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

func TestSceneCatalogActivateSceneMissingFields(t *testing.T) {
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

func TestSceneCatalogActivateSceneSetNotFound(t *testing.T) {
	resp := activateScene(t, "set-does-not-exist-xyz", "scene-abc")
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Errorf("Expected 404 for missing scene set, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestSceneCatalogActivateSceneNotMember(t *testing.T) {
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

func TestSceneCatalogActivateScenePatchesState(t *testing.T) {
	setID := fmt.Sprintf("set-activate-%d", time.Now().UnixNano())
	sceneID := setID + "-scene-b"
	stateKey := fmt.Sprintf("set_activate_%d_level", time.Now().UnixNano())
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
		t.Fatalf("State key %s not patched after scene activation; got %v", stateKey, getStateValue(t, stateKey))
	}
}

func TestSceneCatalogGetCurrentSceneMissingSetID(t *testing.T) {
	resp, err := http.Post(sceneSetsCurrentURL, api.JsonMIMEType, bytes.NewBufferString(`{}`))
	if err != nil {
		t.Fatalf("POST /scene-sets/current-scene failed: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusBadRequest {
		t.Errorf("Expected 400 for missing set_id, got %d", resp.StatusCode)
	}
}

func TestSceneCatalogGetCurrentSceneSetNotFound(t *testing.T) {
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

func TestSceneCatalogGetCurrentSceneBeforeActivation(t *testing.T) {
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

func TestSceneCatalogGetCurrentSceneAfterActivation(t *testing.T) {
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

func TestSceneCatalogCurrentSceneUpdatesOnSubsequentActivation(t *testing.T) {
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

	resp := activateScene(t, setID, sceneAID)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("Activate scene A returned %d", resp.StatusCode)
	}

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

func TestSceneCatalogListScenes(t *testing.T) {
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

func TestSceneCatalogListSnapshotDefinitions(t *testing.T) {
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

func TestSceneCatalogListSceneSets(t *testing.T) {
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

func TestSceneCatalogListAll(t *testing.T) {
	prefix := fmt.Sprintf("catalog-%d", time.Now().UnixNano())
	snapID := prefix + "-snap"
	setID := prefix + "-set"

	upsertSnapshotDefs(t, []api.SnapshotDefinition{{ID: snapID, Data: map[string]any{}}})
	upsertSceneSets(t, []api.SceneSet{{SetID: setID, Scenes: []api.Scene{{ID: setID + "-s1", Data: map[string]any{}}}}})

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

func TestSceneCatalogDeleteAllSnapshotDefinitions(t *testing.T) {
	prefix := fmt.Sprintf("snap-delete-all-%d", time.Now().UnixNano())
	defs := []api.SnapshotDefinition{
		{ID: prefix + "-a", Data: map[string]any{}},
		{ID: prefix + "-b", Data: map[string]any{}},
	}
	upsertSnapshotDefs(t, defs)

	resp := deleteEndpoint(t, snapshotDefsListURL)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE /snapshots returned %d: %s", resp.StatusCode, string(body))
	}

	resp, err := http.Get(snapshotDefsListURL)
	if err != nil {
		t.Fatalf("GET /snapshots failed after delete-all: %v", err)
	}
	defer resp.Body.Close()

	var listResp api.SnapshotListResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode snapshot list response: %v", err)
	}

	for _, def := range defs {
		for _, item := range listResp.Snapshots {
			if item.ID == def.ID {
				t.Fatalf("Snapshot definition %s still present after delete-all", def.ID)
			}
		}
	}
}

func TestSceneCatalogDeleteSnapshotDefinitionByName(t *testing.T) {
	prefix := fmt.Sprintf("snap-delete-one-%d", time.Now().UnixNano())
	deleteID := prefix + "-delete"
	keepID := prefix + "-keep"
	upsertSnapshotDefs(t, []api.SnapshotDefinition{
		{ID: deleteID, Data: map[string]any{}},
		{ID: keepID, Data: map[string]any{}},
	})

	resp := deleteEndpointByName(t, snapshotDefsListURL, deleteID)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE /snapshots/%s returned %d: %s", deleteID, resp.StatusCode, string(body))
	}

	resp, err := http.Get(snapshotDefsListURL)
	if err != nil {
		t.Fatalf("GET /snapshots failed after targeted delete: %v", err)
	}
	defer resp.Body.Close()

	var listResp api.SnapshotListResponse
	if err := json.NewDecoder(resp.Body).Decode(&listResp); err != nil {
		t.Fatalf("Failed to decode snapshot list response: %v", err)
	}

	for _, item := range listResp.Snapshots {
		if item.ID == deleteID {
			t.Fatalf("Snapshot definition %s still present after targeted delete", deleteID)
		}
	}

	foundKeep := false
	for _, item := range listResp.Snapshots {
		if item.ID == keepID {
			foundKeep = true
			break
		}
	}
	if !foundKeep {
		t.Fatalf("Snapshot definition %s should remain after deleting %s", keepID, deleteID)
	}
}

func TestSceneCatalogDeleteSnapshotDefinitionByNameNotFound(t *testing.T) {
	missingID := fmt.Sprintf("snap-delete-missing-%d", time.Now().UnixNano())
	resp := deleteEndpointByName(t, snapshotDefsListURL, missingID)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Expected 404 for missing snapshot definition, got %d: %s", resp.StatusCode, string(body))
	}
}

func TestSceneCatalogDeleteAllSceneSetsAlsoRemovesScenes(t *testing.T) {
	prefix := fmt.Sprintf("scene-sets-delete-all-%d", time.Now().UnixNano())
	setID := prefix + "-set"
	sceneID := prefix + "-scene"
	upsertSceneSets(t, []api.SceneSet{{
		SetID:  setID,
		Scenes: []api.Scene{{ID: sceneID, Data: map[string]any{}}},
	}})

	resp := deleteEndpoint(t, sceneSetsListURL)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE /scene-sets returned %d: %s", resp.StatusCode, string(body))
	}

	resp, err := http.Get(sceneSetsListURL)
	if err != nil {
		t.Fatalf("GET /scene-sets failed after delete-all: %v", err)
	}
	defer resp.Body.Close()

	var setsResp api.SceneSetListResponse
	if err := json.NewDecoder(resp.Body).Decode(&setsResp); err != nil {
		t.Fatalf("Failed to decode scene set list response: %v", err)
	}

	for _, set := range setsResp.SceneSets {
		if set.SetID == setID {
			t.Fatalf("Scene set %s still present after delete-all", setID)
		}
	}

	resp, err = http.Get(scenesListURL)
	if err != nil {
		t.Fatalf("GET /scenes failed after scene-set delete-all: %v", err)
	}
	defer resp.Body.Close()

	var scenesResp api.SceneListResponse
	if err := json.NewDecoder(resp.Body).Decode(&scenesResp); err != nil {
		t.Fatalf("Failed to decode scene list response: %v", err)
	}

	for _, scene := range scenesResp.Scenes {
		if scene.ID == sceneID {
			t.Fatalf("Scene %s still present after deleting all scene sets", sceneID)
		}
	}
}

func TestSceneCatalogDeleteSceneSetByNameAlsoRemovesItsScenes(t *testing.T) {
	prefix := fmt.Sprintf("scene-set-delete-one-%d", time.Now().UnixNano())
	deleteSetID := prefix + "-set-delete"
	deleteSceneID := prefix + "-scene-delete"
	keepSetID := prefix + "-set-keep"
	keepSceneID := prefix + "-scene-keep"

	upsertSceneSets(t, []api.SceneSet{
		{SetID: deleteSetID, Scenes: []api.Scene{{ID: deleteSceneID, Data: map[string]any{}}}},
		{SetID: keepSetID, Scenes: []api.Scene{{ID: keepSceneID, Data: map[string]any{}}}},
	})

	resp := deleteEndpointByName(t, sceneSetsListURL, deleteSetID)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE /scene-sets/%s returned %d: %s", deleteSetID, resp.StatusCode, string(body))
	}

	resp, err := http.Get(sceneSetsListURL)
	if err != nil {
		t.Fatalf("GET /scene-sets failed after targeted delete: %v", err)
	}
	defer resp.Body.Close()

	var setsResp api.SceneSetListResponse
	if err := json.NewDecoder(resp.Body).Decode(&setsResp); err != nil {
		t.Fatalf("Failed to decode scene set list response: %v", err)
	}

	for _, set := range setsResp.SceneSets {
		if set.SetID == deleteSetID {
			t.Fatalf("Scene set %s still present after targeted delete", deleteSetID)
		}
	}

	foundKeepSet := false
	for _, set := range setsResp.SceneSets {
		if set.SetID == keepSetID {
			foundKeepSet = true
			break
		}
	}
	if !foundKeepSet {
		t.Fatalf("Scene set %s should remain after deleting %s", keepSetID, deleteSetID)
	}

	resp, err = http.Get(scenesListURL)
	if err != nil {
		t.Fatalf("GET /scenes failed after targeted scene-set delete: %v", err)
	}
	defer resp.Body.Close()

	var scenesResp api.SceneListResponse
	if err := json.NewDecoder(resp.Body).Decode(&scenesResp); err != nil {
		t.Fatalf("Failed to decode scene list response: %v", err)
	}

	for _, scene := range scenesResp.Scenes {
		if scene.ID == deleteSceneID {
			t.Fatalf("Scene %s still present after deleting scene set %s", deleteSceneID, deleteSetID)
		}
	}

	foundKeepScene := false
	for _, scene := range scenesResp.Scenes {
		if scene.ID == keepSceneID {
			foundKeepScene = true
			break
		}
	}
	if !foundKeepScene {
		t.Fatalf("Scene %s should remain after deleting scene set %s", keepSceneID, deleteSetID)
	}
}

func TestSceneCatalogDeleteSceneByName(t *testing.T) {
	prefix := fmt.Sprintf("scene-delete-one-%d", time.Now().UnixNano())
	setID := prefix + "-set"
	deleteSceneID := prefix + "-scene-delete"
	keepSceneID := prefix + "-scene-keep"

	upsertSceneSets(t, []api.SceneSet{{
		SetID: setID,
		Scenes: []api.Scene{
			{ID: deleteSceneID, Name: "Delete", Data: map[string]any{}},
			{ID: keepSceneID, Name: "Keep", Data: map[string]any{}},
		},
	}})

	resp := activateScene(t, setID, deleteSceneID)
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		t.Fatalf("Activate scene returned %d", resp.StatusCode)
	}

	resp = deleteEndpointByName(t, scenesListURL, deleteSceneID)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("DELETE /scenes/%s returned %d: %s", deleteSceneID, resp.StatusCode, string(body))
	}

	resp, err := http.Get(scenesListURL)
	if err != nil {
		t.Fatalf("GET /scenes failed after targeted delete: %v", err)
	}
	defer resp.Body.Close()

	var scenesResp api.SceneListResponse
	if err := json.NewDecoder(resp.Body).Decode(&scenesResp); err != nil {
		t.Fatalf("Failed to decode scene list response: %v", err)
	}

	for _, scene := range scenesResp.Scenes {
		if scene.ID == deleteSceneID {
			t.Fatalf("Scene %s still present after targeted delete", deleteSceneID)
		}
	}

	foundKeep := false
	for _, scene := range scenesResp.Scenes {
		if scene.ID == keepSceneID {
			foundKeep = true
			break
		}
	}
	if !foundKeep {
		t.Fatalf("Scene %s should remain after deleting %s", keepSceneID, deleteSceneID)
	}

	current := getCurrentScene(t, setID)
	if current.CurrentScene.SceneID != "" {
		t.Fatalf("Expected current scene to be cleared after deleting active scene, got %q", current.CurrentScene.SceneID)
	}
}

func TestSceneCatalogDeleteSceneByNameNotFound(t *testing.T) {
	missingID := fmt.Sprintf("scene-delete-missing-%d", time.Now().UnixNano())
	resp := deleteEndpointByName(t, scenesListURL, missingID)
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusNotFound {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Expected 404 for missing scene, got %d: %s", resp.StatusCode, string(body))
	}
}
