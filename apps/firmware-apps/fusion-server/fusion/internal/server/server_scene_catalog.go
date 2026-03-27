package server

import (
	"errors"
	"fmt"
	"io"
	"net/http"

	json "github.com/goccy/go-json"

	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/utils"
)

// ActivateSnapshot handles POST /snapshots/activate.
// Patches the snapshot data onto DB State (fire-and-forget).
// Returns 404 if the snapshot ID does not exist.
func (s *FusionServer) ActivateSnapshot(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var req api.ActivateSnapshotRequest
	if err := json.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.ID == "" {
		http.Error(w, "id is required", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleActivateSnapshotByID(req.ID); err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, fmt.Sprintf("Error: %s", req.ID), http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListSnapshotDefinitions handles GET /snapshots/list.
// Returns the list of all stored snapshot definitions.
func (s *FusionServer) ListSnapshotDefinitions(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	snapshots, err := s.handler.HandleListSnapshotDefinitions()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing snapshots: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(api.SnapshotListResponse{Snapshots: snapshots})
}

// ListScenes handles GET /scenes/list.
// Returns a flat list of all scenes across all scene sets.
func (s *FusionServer) ListScenes(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	sceneSets, err := s.handler.HandleListSceneSets()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing scenes: %v", err), http.StatusInternalServerError)
		return
	}

	scenes := make([]api.Scene, 0)
	for _, set := range sceneSets {
		scenes = append(scenes, set.Scenes...)
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(api.SceneListResponse{Scenes: scenes})
}

// ActivateSceneSet handles POST /scene-sets/activate.
// Activates a scene within a scene set and patches the scene data onto DB State.
// Returns 404 if the scene set does not exist, 409 if the scene is not a member of the set.
func (s *FusionServer) ActivateSceneSet(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var req api.ActivateSceneSetRequest
	if err := json.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.SetID == "" || req.SceneID == "" {
		http.Error(w, "set_id and scene_id are required", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleActivateScene(req.SetID, req.SceneID); err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, "Error: Scene Set not found.", http.StatusNotFound)
			return
		}
		if errors.Is(err, persistence.ErrNotMember) {
			http.Error(w, "Error: Scene is not part of the specified Scene Set.", http.StatusConflict)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetCurrentScene handles POST /scene-sets/current-scene.
// Returns the current scene ID and name for the given scene set.
func (s *FusionServer) GetCurrentScene(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var req struct {
		SetID string `json:"set_id"`
	}
	if err := json.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.SetID == "" {
		http.Error(w, "set_id is required", http.StatusBadRequest)
		return
	}

	set, err := s.handler.HandleGetSceneSet(req.SetID)
	if err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, "Error: Scene Set not found.", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Find the scene object matching CurrentSceneID so we can return its name.
	var currentSceneName string
	for _, scene := range set.Scenes {
		if scene.ID == set.CurrentSceneID {
			currentSceneName = scene.Name
			break
		}
	}

	resp := api.CurrentSceneResponse{
		SetID: set.SetID,
		CurrentScene: api.CurrentSceneMetadata{
			SceneID: set.CurrentSceneID,
			Name:    currentSceneName,
		},
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(resp)
}

// ListSceneSets handles GET /scene-sets/list.
// Returns all stored scene sets.
func (s *FusionServer) ListSceneSets(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	sceneSets, err := s.handler.HandleListSceneSets()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing scene sets: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(api.SceneSetListResponse{SceneSets: sceneSets})
}

// ListSceneCatalog handles GET /scene-catalog-list.
// Returns all stored snapshots and scene sets in a single response.
func (s *FusionServer) ListSceneCatalog(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	snapshots, err := s.handler.HandleListSnapshotDefinitions()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing snapshots: %v", err), http.StatusInternalServerError)
		return
	}

	sceneSets, err := s.handler.HandleListSceneSets()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing scene sets: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(api.SceneCatalogListResponse{
		Snapshots: snapshots,
		SceneSets: sceneSets,
	})
}
