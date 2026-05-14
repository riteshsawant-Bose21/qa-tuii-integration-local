package server

import (
	"fmt"
	model "fusion/internal/gen/proto/fusion"
	"fusion/internal/utils"
	"net/http"

	"google.golang.org/protobuf/types/known/structpb"
)

// GetTimeMachine handles HTTP GET requests to retrieve a specific time machine entry.
func (s *FusionServer) GetTimeMachine(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	snapshotName, err := utils.ExtractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	snapshot, err := s.handler.HandleGetSnapshot(snapshotName)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error getting snapshot: %v", err), http.StatusNotFound)
		return
	}

	snapshotMap, ok := snapshot.(map[string]any)
	if !ok {
		http.Error(w, "Error getting snapshot: invalid snapshot format", http.StatusInternalServerError)
		return
	}

	msg, err := structpb.NewStruct(snapshotMap)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error encoding snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	if err := writeProtoJSON(w, msg); err != nil {
		http.Error(w, fmt.Sprintf("Error writing snapshot: %v", err), http.StatusInternalServerError)
	}
}

// GetActiveTimeMachineName handles HTTP GET requests to retrieve the active time machine name.
func (s *FusionServer) GetActiveTimeMachineName(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	snapshot := s.handler.HandleGetActiveSnapshotName()
	if err := writeProtoJSON(w, &model.ActiveTimeMachineResponse{ActiveSnapshot: snapshot}); err != nil {
		http.Error(w, fmt.Sprintf("Error writing active snapshot: %v", err), http.StatusInternalServerError)
	}
}

// ListTimeMachines handles HTTP GET requests to list available time machine entries.
func (s *FusionServer) ListTimeMachines(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	snapshots, err := s.handler.HandleListSnapshots()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing snapshots: %v", err), http.StatusInternalServerError)
		return
	}

	if err := writeProtoJSON(w, &model.TimeMachineListResponse{Snapshots: snapshots}); err != nil {
		http.Error(w, fmt.Sprintf("Error writing snapshot list: %v", err), http.StatusInternalServerError)
	}
}

// ActivateTimeMachine handles HTTP POST requests to activate a specific time machine entry.
func (s *FusionServer) ActivateTimeMachine(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	snapshotName, err := utils.ExtractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	exists, err := s.handler.HandleSnapshotExists(snapshotName)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking snapshot existence: %v", err), http.StatusInternalServerError)
		return
	}

	if !exists {
		http.Error(w, fmt.Sprintf("Snapshot '%s' not found", snapshotName), http.StatusNotFound)
		return
	}

	if err := s.handler.HandleActivateSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error activating snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	if err := writeProtoJSONWithStatus(w, http.StatusOK, &model.TimeMachineOperationStatus{Name: snapshotName, Status: "activated"}); err != nil {
		http.Error(w, fmt.Sprintf("Error writing activation response: %v", err), http.StatusInternalServerError)
	}
}

// CreateTimeMachine handles HTTP POST requests to create a new time machine entry.
func (s *FusionServer) CreateTimeMachine(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	snapshotName, err := utils.ExtractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if s.handler.IsDefaultSnapshot(snapshotName) {
		http.Error(w, "default snapshot cannot be overwritten", http.StatusBadRequest)
		return
	}

	exists, err := s.handler.HandleSnapshotExists(snapshotName)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking snapshot existence: %v", err), http.StatusInternalServerError)
		return
	}
	if exists {
		http.Error(w, "Snapshot already exists", http.StatusConflict)
		return
	}

	if err := s.handler.HandleCreateSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error creating snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	if err := writeProtoJSONWithStatus(w, http.StatusCreated, &model.TimeMachineOperationStatus{Name: snapshotName, Status: "created"}); err != nil {
		http.Error(w, fmt.Sprintf("Error writing creation response: %v", err), http.StatusInternalServerError)
	}
}

// DeleteTimeMachine handles HTTP DELETE requests to remove an existing time machine entry.
func (s *FusionServer) DeleteTimeMachine(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	snapshotName, err := utils.ExtractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if s.handler.IsDefaultSnapshot(snapshotName) {
		http.Error(w, "default snapshot cannot be deleted", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleDeleteSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error deleting snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	if err := writeProtoJSONWithStatus(w, http.StatusOK, &model.TimeMachineOperationStatus{Name: snapshotName, Status: "deleted"}); err != nil {
		http.Error(w, fmt.Sprintf("Error writing delete response: %v", err), http.StatusInternalServerError)
	}
}

// SaveTimeMachine handles POST /time-machine/update/{name}
// It overwrites an existing time machine entry with the current active state.
func (s *FusionServer) SaveTimeMachine(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	snapshotName, err := utils.ExtractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if s.handler.IsDefaultSnapshot(snapshotName) {
		http.Error(w, "default snapshot cannot be overwritten", http.StatusBadRequest)
		return
	}

	exists, err := s.handler.HandleSnapshotExists(snapshotName)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking snapshot existence: %v", err), http.StatusInternalServerError)
		return
	}
	if !exists {
		http.Error(w, "Snapshot does not exist", http.StatusNotFound)
		return
	}

	if err := s.handler.HandleSaveSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error saving snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	if err := writeProtoJSONWithStatus(w, http.StatusOK, &model.TimeMachineOperationStatus{Name: snapshotName, Status: "saved"}); err != nil {
		http.Error(w, fmt.Sprintf("Error writing save response: %v", err), http.StatusInternalServerError)
	}
}
