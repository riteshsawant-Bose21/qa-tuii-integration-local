package server

import (
	"errors"
	"fmt"
	"io"
	"net/http"

<<<<<<< HEAD
	"fusion/internal/api"
=======
	model "fusion/internal/gen/proto/fusion"
>>>>>>> gene/value
	"fusion/internal/persistence"
	"fusion/internal/utils"

	"google.golang.org/protobuf/types/known/structpb"
)

<<<<<<< HEAD
func snapshotDefinitionToProto(def api.SnapshotDefinition) (*model.SnapshotDefinition, error) {
	var data *structpb.Struct
	var err error
	if def.Data != nil {
		data, err = structpb.NewStruct(def.Data)
		if err != nil {
			return nil, err
		}
	}

	return &model.SnapshotDefinition{
		Id:   def.ID,
		Name: def.Name,
		Data: data,
	}, nil
}

func sceneToProto(scene api.Scene) (*model.Scene, error) {
	var data *structpb.Struct
	var err error
	if scene.Data != nil {
		data, err = structpb.NewStruct(scene.Data)
		if err != nil {
			return nil, err
		}
	}

	return &model.Scene{
		Id:   scene.ID,
		Name: scene.Name,
		Data: data,
	}, nil
}

func sceneSetToProto(set api.SceneSet) (*model.SceneSet, error) {
	scenes := make([]*model.Scene, 0, len(set.Scenes))
	for _, scene := range set.Scenes {
		sceneMsg, err := sceneToProto(scene)
		if err != nil {
			return nil, err
		}
		scenes = append(scenes, sceneMsg)
	}

	return &model.SceneSet{
		SetId:          set.SetID,
		Name:           set.Name,
		DefaultScene:   set.DefaultSceneID,
		CurrentSceneId: set.CurrentSceneID,
		Scenes:         scenes,
	}, nil
=======
// CreateSnapshotDefinition handles POST /snapshots.
func (s *FusionServer) CreateSnapshotDefinition(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var req model.SnapshotDefinition
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.GetId() == "" {
		http.Error(w, "id is required", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleCreateSnapshotDefinition(&req); err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		if err.Error() == fmt.Sprintf("snapshot definition %q already exists", req.GetId()) {
			http.Error(w, err.Error(), http.StatusConflict)
			return
		}
		http.Error(w, fmt.Sprintf("Error creating snapshot definition: %v", err), http.StatusInternalServerError)
		return
	}
	if err := writeProtoJSONWithStatus(w, http.StatusCreated, &req); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
}

// UpsertSnapshotDefinition handles PUT /snapshots/{id}.
func (s *FusionServer) UpsertSnapshotDefinition(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePut(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var req model.SnapshotDefinition
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}
	if req.GetId() != "" && req.GetId() != id {
		http.Error(w, "body id must match path id", http.StatusBadRequest)
		return
	}
	req.Id = id

	if err := s.handler.HandleUpsertSnapshotDefinition(&req); err != nil {
		http.Error(w, fmt.Sprintf("Error upserting snapshot definition: %v", err), http.StatusInternalServerError)
		return
	}
	if err := writeProtoJSON(w, &req); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
>>>>>>> gene/value
}

// ActivateSnapshot handles POST /snapshots/activate/{id}.
// Patches the snapshot data onto DB State (fire-and-forget).
// Returns 404 if the snapshot ID does not exist.
func (s *FusionServer) ActivateSnapshot(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleActivateSnapshotByID(id); err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, fmt.Sprintf("Error: %s", id), http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListSnapshotDefinitions handles GET /snapshots.
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

	resp := &model.SnapshotDefinitionListResponse{
<<<<<<< HEAD
		Snapshots: make([]*model.SnapshotDefinition, 0, len(snapshots)),
	}
	for _, snapshot := range snapshots {
		msg, err := snapshotDefinitionToProto(snapshot)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error encoding snapshot %s: %v", snapshot.ID, err), http.StatusInternalServerError)
			return
		}
		resp.Snapshots = append(resp.Snapshots, msg)
=======
		Snapshots: snapshots,
>>>>>>> gene/value
	}

	if err := writeProtoJSON(w, resp); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
}

// DeleteSnapshotDefinitions handles DELETE /snapshots.
// Removes all stored snapshot definitions.
func (s *FusionServer) DeleteSnapshotDefinitions(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	if err := s.handler.HandleDeleteAllSnapshotDefinitions(); err != nil {
		http.Error(w, fmt.Sprintf("Error deleting snapshots: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// DeleteSnapshotDefinition handles DELETE /snapshots/{id}.
// Removes one stored snapshot definition by ID.
func (s *FusionServer) DeleteSnapshotDefinition(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleDeleteSnapshotDefinition(id); err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, fmt.Sprintf("Error: %s", id), http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Error deleting snapshot %s: %v", id, err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListScenes handles GET /scenes.
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

	scenes := make([]*model.Scene, 0)
	for _, set := range sceneSets {
		scenes = append(scenes, set.GetScenes()...)
	}

	resp := &model.SceneListResponse{
<<<<<<< HEAD
		Scenes: make([]*model.Scene, 0, len(scenes)),
	}
	for _, scene := range scenes {
		msg, err := sceneToProto(scene)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error encoding scene %s: %v", scene.ID, err), http.StatusInternalServerError)
			return
		}
		resp.Scenes = append(resp.Scenes, msg)
=======
		Scenes: scenes,
>>>>>>> gene/value
	}

	if err := writeProtoJSON(w, resp); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
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

	var req model.ActivateSceneSetRequest
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.GetSetId() == "" || req.GetSceneId() == "" {
		http.Error(w, "set_id and scene_id are required", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleActivateScene(req.GetSetId(), req.GetSceneId()); err != nil {
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

// CreateSceneSet handles POST /scene-sets.
func (s *FusionServer) CreateSceneSet(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var req model.SceneSet
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}
	if req.GetSetId() == "" {
		http.Error(w, "set_id is required", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleCreateSceneSet(&req); err != nil {
		if err.Error() == fmt.Sprintf("scene set %q already exists", req.GetSetId()) {
			http.Error(w, err.Error(), http.StatusConflict)
			return
		}
		http.Error(w, fmt.Sprintf("Error creating scene set: %v", err), http.StatusInternalServerError)
		return
	}
	if err := writeProtoJSONWithStatus(w, http.StatusCreated, &req); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
}

// UpsertSceneSet handles PUT /scene-sets/{id}.
func (s *FusionServer) UpsertSceneSet(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePut(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var req model.SceneSet
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}
	if req.GetSetId() != "" && req.GetSetId() != id {
		http.Error(w, "body set_id must match path id", http.StatusBadRequest)
		return
	}
	req.SetId = id

	if err := s.handler.HandleUpsertSceneSet(&req); err != nil {
		http.Error(w, fmt.Sprintf("Error upserting scene set: %v", err), http.StatusInternalServerError)
		return
	}
	if err := writeProtoJSON(w, &req); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
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

	var req model.CurrentSceneRequest
	if err := serverProtoJSONUnmarshalOptions.Unmarshal(body, &req); err != nil {
		http.Error(w, fmt.Sprintf("invalid request body: %v", err), http.StatusBadRequest)
		return
	}

	if req.GetSetId() == "" {
		http.Error(w, "set_id is required", http.StatusBadRequest)
		return
	}

	set, err := s.handler.HandleGetSceneSet(req.GetSetId())
	if err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, "Error: Scene Set not found.", http.StatusNotFound)
			return
		}
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	var currentSceneName string
	for _, scene := range set.GetScenes() {
		if scene.GetId() == set.GetCurrentSceneId() {
			currentSceneName = scene.GetName()
			break
		}
	}

	resp := &model.CurrentSceneResponse{
<<<<<<< HEAD
		SetId: set.SetID,
		CurrentScene: &model.CurrentSceneMetadata{
			SceneId: set.CurrentSceneID,
=======
		SetId: set.GetSetId(),
		CurrentScene: &model.CurrentSceneMetadata{
			SceneId: set.GetCurrentSceneId(),
>>>>>>> gene/value
			Name:    currentSceneName,
		},
	}

	if err := writeProtoJSON(w, resp); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
}

// ListSceneSets handles GET /scene-sets.
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

	resp := &model.SceneSetListResponse{
<<<<<<< HEAD
		SceneSets: make([]*model.SceneSet, 0, len(sceneSets)),
	}
	for _, sceneSet := range sceneSets {
		msg, err := sceneSetToProto(sceneSet)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error encoding scene set %s: %v", sceneSet.SetID, err), http.StatusInternalServerError)
			return
		}
		resp.SceneSets = append(resp.SceneSets, msg)
=======
		SceneSets: sceneSets,
>>>>>>> gene/value
	}

	if err := writeProtoJSON(w, resp); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
}

// DeleteSceneSets handles DELETE /scene-sets.
// Removes all stored scene sets (and therefore all scenes contained in those sets).
func (s *FusionServer) DeleteSceneSets(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	if err := s.handler.HandleDeleteAllSceneSets(); err != nil {
		http.Error(w, fmt.Sprintf("Error deleting scene sets: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// DeleteSceneSet handles DELETE /scene-sets/{id}.
// Removes one stored scene set by set ID.
func (s *FusionServer) DeleteSceneSet(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleDeleteSceneSet(id); err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, fmt.Sprintf("Error: %s", id), http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Error deleting scene set %s: %v", id, err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// DeleteScene handles DELETE /scenes/{id}.
// Removes one stored scene by ID from any scene set containing it.
func (s *FusionServer) DeleteScene(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleDeleteScene(id); err != nil {
		if errors.Is(err, persistence.ErrNotFound) {
			http.Error(w, fmt.Sprintf("Error: %s", id), http.StatusNotFound)
			return
		}
		http.Error(w, fmt.Sprintf("Error deleting scene %s: %v", id, err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListSceneCatalog handles GET /scene-catalog.
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

	resp := &model.SceneCatalogListResponse{
<<<<<<< HEAD
		Snapshots: make([]*model.SnapshotDefinition, 0, len(snapshots)),
		SceneSets: make([]*model.SceneSet, 0, len(sceneSets)),
	}

	for _, snapshot := range snapshots {
		msg, err := snapshotDefinitionToProto(snapshot)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error encoding snapshot %s: %v", snapshot.ID, err), http.StatusInternalServerError)
			return
		}
		resp.Snapshots = append(resp.Snapshots, msg)
	}
	for _, sceneSet := range sceneSets {
		msg, err := sceneSetToProto(sceneSet)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error encoding scene set %s: %v", sceneSet.SetID, err), http.StatusInternalServerError)
			return
		}
		resp.SceneSets = append(resp.SceneSets, msg)
=======
		Snapshots: snapshots,
		SceneSets: sceneSets,
>>>>>>> gene/value
	}

	if err := writeProtoJSON(w, resp); err != nil {
		http.Error(w, fmt.Sprintf("Error writing response: %v", err), http.StatusInternalServerError)
	}
}
