package server

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/utils"
	"net/http"

	json "github.com/goccy/go-json"
)

// GetSnapshot handles HTTP GET requests to retrieve a specific snapshot.
func (s *FusionServer) GetSnapshot(w http.ResponseWriter, r *http.Request) {

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

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(snapshot)
}

// GetActiveSnapshot handles HTTP GET requests to retrieve the active snapshot name.
func (s *FusionServer) GetActiveSnapshotName(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	snapshot := s.handler.HandleGetActiveSnapshotName()

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(snapshot)
}

// ListSnapshots handles HTTP GET requests to list available snapshots.
func (s *FusionServer) ListSnapshots(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve the list of snapshots from the handler.
	snapshots, err := s.handler.HandleListSnapshots()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing snapshots: %v", err), http.StatusInternalServerError)
		return
	}

	// Write the JSON response with the snapshots.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]any{"snapshots": snapshots})
}

// ActivateSnapshot handles HTTP POST requests to activate a specific snapshot.
// It expects a query parameter "name" specifying the snapshot to activate.
func (s *FusionServer) ActivateSnapshot(w http.ResponseWriter, r *http.Request) {

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

	w.WriteHeader(http.StatusNoContent)
}

// CreateSnapshot handles HTTP POST requests to create a new snapshot.
func (s *FusionServer) CreateSnapshot(w http.ResponseWriter, r *http.Request) {

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

	w.WriteHeader(http.StatusCreated)
}

// DeleteSnapshot handles HTTP DELETE requests to remove an existing snapshot.
func (s *FusionServer) DeleteSnapshot(w http.ResponseWriter, r *http.Request) {

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

	w.WriteHeader(http.StatusNoContent)
}

// SaveSnapshot handles POST /snapshots/{name}/save
// It overwrites an existing snapshot with the current active state.
func (s *FusionServer) SaveSnapshot(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePost(w, r) {
		return
	}

	snapshotName, err := utils.ExtractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Default snapshot cannot be overwritten
	if s.handler.IsDefaultSnapshot(snapshotName) {
		http.Error(w, "default snapshot cannot be overwritten", http.StatusBadRequest)
		return
	}

	// Verify snapshot exists before overwriting
	exists, err := s.handler.HandleSnapshotExists(snapshotName)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error checking snapshot existence: %v", err), http.StatusInternalServerError)
		return
	}
	if !exists {
		http.Error(w, "Snapshot does not exist", http.StatusNotFound)
		return
	}

	// Overwrite the snapshot from live active state
	if err := s.handler.HandleSaveSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error saving snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent) // success, no response body
}
