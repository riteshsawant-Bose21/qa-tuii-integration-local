package server

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
	"fusion/internal/persistence"
	"fusion/internal/server/handler"
	"fusion/internal/utils"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/hashicorp/memberlist"
)

const (
	wsBufferSize = 1024
	wsTimeout    = 10
	wsPingTime   = 30
	wsPongTime   = 60
)

// FusionServer handles networks connections to manage Fusion state.
type FusionServer struct {
	node        string
	handler     *handler.Handler
	wsClients   map[*websocket.Conn]bool
	wsLock      sync.RWMutex
	upgrader    websocket.Upgrader
	clusterList *memberlist.Memberlist
}

// NewFusionServer creates and initializes a new configuration server with the provided node name,
// handler and cluster member list. It also sets up a WebSocket upgrader with custom options.
func NewFusionServer(node string, handler *handler.Handler, clusterList *memberlist.Memberlist) *FusionServer {
	server := &FusionServer{
		node:      node,
		handler:   handler,
		wsClients: make(map[*websocket.Conn]bool),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
			HandshakeTimeout:  wsTimeout * time.Second,
			EnableCompression: true,
			ReadBufferSize:    wsBufferSize,
			WriteBufferSize:   wsBufferSize,
		},
		clusterList: clusterList,
	}
	handler.AddBroadcaster(server)
	return server
}

// BroadcastUpdate sends a notification message to all connected WebSocket clients.
// It acquires a read lock on the clients list to ensure thread-safe access.
func (s *FusionServer) BroadcastUpdate(message *api.NotifyMessage) error {
	s.wsLock.RLock()
	defer s.wsLock.RUnlock()

	for conn := range s.wsClients {
		if err := conn.WriteJSON(message); err != nil {
			logging.GetLogger().Error("Error broadcasting to WebSocket client: %v", err)
			conn.Close()
			delete(s.wsClients, conn)
		}
	}
	return nil
}

// GetValue handles HTTP GET requests to retrieve a configuration value based on a "key" query parameter.
func (s *FusionServer) GetValue(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve the "key" query parameter.
	key, err := getSingleQueryParam(r, "key")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Use the handler to get the configuration value.
	response, err := s.handler.HandleHTTPGet(key)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Write the JSON response.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(response)
}

// SetValue handles HTTP POST requests to set a configuration value.
// It expects a JSON body containing the update data.
func (s *FusionServer) SetValue(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePost(w, r) {
		return
	}

	// Read the request body.
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Unmarshal the JSON into a map.
	var update map[string]any
	if err := json.Unmarshal(body, &update); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	// Use the handler to update the configuration.
	response, err := s.handler.HandleHTTPSet(update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Write the JSON response.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(response)
}

// UpdateValue handles HTTP PATCH requests to update a configuration value.
// It supports partial updates based on the provided key query parameter or the entire JSON body.
func (s *FusionServer) UpdateValue(w http.ResponseWriter, r *http.Request) {

	if !utils.RequirePatch(w, r) {
		return
	}

	// Read the request body.
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Unmarshal the request body into a map.
	var update map[string]any
	if err := json.Unmarshal(body, &update); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	// Retrieve the "key" query parameter.
	key, err := getSingleQueryParam(r, "key")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Retrieve the full current configuration state.
	configData := s.handler.StateManager.GetStateMap()

	// Create a deep copy of configData to preserve the original configuration.
	originalConfig, err := deepCopy(configData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error copying original configuration: %v", err), http.StatusInternalServerError)
		return
	}

	var updatedData any
	if key != "" {
		// If a key is provided, update the nested value.
		utils.SetNestedValue(configData, key, update["value"])
		updatedData, err = s.handler.HandleHTTPPatch(configData)
	} else {
		// If no key is provided, treat the entire body as the update map.
		updatedData, err = s.handler.HandleHTTPPatch(update)
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Calculate the difference between the original and updated configuration.
	diffData := calculateDiff(originalConfig, updatedData)

	// Prepare the response with the update diff.
	response := map[string]any{
		"status":  "success",
		"updates": diffData,
	}

	// Write the JSON response.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, fmt.Sprintf("Error encoding response: %v", err), http.StatusInternalServerError)
	}
}

// ExportState handles HTTP GET requests to export the entire configuration state.
func (s *FusionServer) ExportState(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve the full state from the state manager.
	state := s.handler.StateManager.GetFullState()

	// Write the JSON response.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	encoder := json.NewEncoder(w)
	if err := encoder.Encode(state); err != nil {
		logging.GetLogger().Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

// ImportState handles HTTP POST requests to import configuration state.
func (s *FusionServer) ImportState(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	// Read the request body.
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Unmarshal the JSON data into a map.
	var state persistence.VersionedState
	err = json.Unmarshal(body, &state)
	if err != nil {
		http.Error(w, fmt.Sprintf("error unmarshaling json: %v", err), http.StatusInternalServerError)
		return
	}

	s.handler.StateManager.SetState(state.State)
}

// HandleWebSocket upgrades an HTTP connection to a WebSocket connection, sets up ping handlers,
// sends an initial state to the client, and listens for incoming messages.
func (s *FusionServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	// Upgrade the HTTP connection to a WebSocket connection.
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		logging.GetLogger().Error("Failed to upgrade connection: %v", err)
		return
	}

	// Set initial read deadline and pong handler for connection keep-alive.
	conn.SetReadDeadline(time.Now().Add(wsPongTime * time.Second))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(wsPongTime * time.Second))
		return nil
	})

	// Start a ticker to periodically send ping messages.
	pingTicker := time.NewTicker(wsPingTime * time.Second)
	go func() {
		defer pingTicker.Stop()
		for range pingTicker.C {
			if err := conn.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(10*time.Second)); err != nil {
				logging.GetLogger().Error("Ping failed: %v", err)
				return
			}
		}
	}()

	// Add the connection to the list of WebSocket clients.
	s.wsLock.Lock()
	s.wsClients[conn] = true
	s.wsLock.Unlock()

	// Ensure cleanup when the function returns.
	defer func() {
		pingTicker.Stop()
		conn.Close()
		s.wsLock.Lock()
		delete(s.wsClients, conn)
		s.wsLock.Unlock()
	}()

	// Send the initial state to the client.
	state, err := s.handler.HandleHTTPGet("")
	if err != nil {
		logging.GetLogger().Error("Failed to get data: %v", err)
		return
	}

	if err := conn.WriteJSON(state); err != nil {
		logging.GetLogger().Error("Failure sending initial state: %v", err)
		return
	}

	// Listen for messages from the WebSocket client.
	for {
		messageType, data, err := conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				logging.GetLogger().Error("WebSocket error: %v", err)
			}
			break
		}
		if messageType == websocket.TextMessage {
			s.handleWebSocketMessage(conn, data)
		}
	}
}

// HandleRoot handles requests to the root URL ("/") and returns server information.
func (s *FusionServer) HandleRoot(w http.ResponseWriter, r *http.Request) {
	// Only serve the root path.
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	// Retrieve server info from the handler.
	info, err := s.handler.GetServerInfo()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Write the JSON response.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(info)
}

// GetVersion handles version HTTP requests.
func (s *FusionServer) GetVersion(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

// UpdateVersion handles update version HTTP requests.
func (s *FusionServer) UpdateVersion(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	s.handler.HandleVersionRollback(w, r)
}

// RollbackVersion handles version rollback HTTP requests.
func (s *FusionServer) RollbackVersion(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	s.handler.HandleVersionRollback(w, r)
}

// UploadAudio handles HTTP POST requests for audio file uploads.
// It delegates the audio upload handling to the handler.
func (s *FusionServer) UploadAudio(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	s.handler.HandleAudioUpload(w, r)
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

// ActivateSnapshot handles HTTP PUT requests to activate a specific snapshot.
// It expects a query parameter "name" specifying the snapshot to activate.
func (s *FusionServer) ActivateSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	snapshotName, err := extractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
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
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	snapshotName, err := extractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if snapshotName == persistence.DefaultSnapshotKey {
		http.Error(w, "default snapshot cannot be created", http.StatusBadRequest)
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

	w.WriteHeader(http.StatusNoContent)
}

// DeleteSnapshot handles HTTP DELETE requests to remove an existing snapshot.
// It expects a query parameter "name" specifying the snapshot to delete.
func (s *FusionServer) DeleteSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	snapshotName, err := extractName(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if snapshotName == persistence.DefaultSnapshotKey {
		http.Error(w, "default snapshot cannot be deleted", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleDeleteSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error deleting snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetDatabaseMetadata handles HTTP GET requests to retrieve fusion database metadata.
func (s *FusionServer) GetDatabaseMetadata(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve metadata from the handler.
	metadata, err := s.handler.HandleGetDatabaseMetadata()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error getting snapshot metadata: %v", err), http.StatusInternalServerError)
		return
	}

	// Write the JSON response with metadata.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]any{"metadata": metadata})
}

// GetSnapshot handles HTTP GET requests to retrieve a specific snapshot.
func (s *FusionServer) GetSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	snapshotName, err := extractName(r)
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

// ExportData handles HTTP GET requests to export all data.
func (s *FusionServer) ExportData(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve data from the handler.
	data, err := s.handler.HandleExportData()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error exporting data: %v", err), http.StatusInternalServerError)
		return
	}

	// Write the JSON response with the snapshots.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(data)
}

// ImportData handles HTTP POST requests to import data.
// It expects a JSON body containing the data.
func (s *FusionServer) ImportData(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	// Read the request body.
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Unmarshal the JSON data into a map.
	var data map[string]any
	err = json.Unmarshal(body, &data)
	if err != nil {
		http.Error(w, fmt.Sprintf("error unmarshaling json: %v", err), http.StatusInternalServerError)
		return
	}

	// Import the data using the handler.
	err = s.handler.HandleImportData(data)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error importing snapshots: %v", err), http.StatusInternalServerError)
		return
	}
}

// ClearAllValues handles HTTP DELETE requests to clear all configuration data.
func (s *FusionServer) ClearAllValues(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireDelete(w, r) {
		return
	}

	// Clear the data using the handler.
	if err := s.handler.HandleClearAllData(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// GetMembers handles HTTP GET requests to list all cluster members.
func (s *FusionServer) GetMembers(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve the list of members from the handler's member list.
	members := s.handler.Memberlist.Members()
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(members); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

// HandeSetupDeviceName set the device name
func (s *FusionServer) HandeSetupDeviceName(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}

	// Read the request body.
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Unmarshal the JSON data
	var state api.UpdateDeviceName
	err = json.Unmarshal(body, &state)
	if err != nil {
		http.Error(w, fmt.Sprintf("error unmarshaling json: %v", err), http.StatusInternalServerError)
		return
	}

	// This name is user-facing and •maybe• has no impact on the internal function
	// of the server, except as a lookup between logical device name and user-facing name.

	// We do have a local database. That database is a boltdb JSON database that is used currently to
	// store the global config state and metadata about that current state.
	// We should consider storing device specific configuation data that we want to persist across
	// launches in the database in a bucket specific to the device.
	// Look at persistance.saveMetadata for an example of how we would write this info to the database
	// We will need load, save, update functions for device-specific info

	// This name needs to fullfill a few requirements:
	//  ° Unique across network?
	//  ° Correlated to the actual device hardware and/or DRO unique ID
	//  ° Stored local to device and loaded on demand
	//  ° We will a way to get the info for each device. Consider using a private HTTP
	//    endpoint similar to get HandleGetNetworkLatencyLocal. This will be registered as a private
	//    endpoint and make no calls to other nodes.

	// Do this:  Have a public endpoint: GetDeviceNames()
	// In that public endpoint, iterate through the memberlist nodes. If we are the local node,
	// just call the function that access the database directly, otherwise make a http call on the ADMIN port (9090)
	// to the GetDeviceNameLocal()

	w.WriteHeader(http.StatusNoContent)
}

func (s *FusionServer) HandleListMessages(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) HandleUploadMessage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	s.handler.HandleAudioUpload(w, r)
}

func (s *FusionServer) HandleDeleteMessage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}
	s.handler.HandleAudioRemove(w, r)
}

func (s *FusionServer) HandleListZones(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) HandleGetZoneStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) HandleGetSystemDiagnostics(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) HandleGetSystemStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) HandleListScheduledMessages(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) HandleScheduleMessage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
}

func (s *FusionServer) HandleCancelAlarms(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePut(w, r) {
		return
	}
}

// getSingleQueryParam retrieves the value of a query parameter if it exists exactly once.
// It returns an empty string if the parameter is missing and an error if it appears multiple times
// or contains invalid characters.
func getSingleQueryParam(r *http.Request, param string) (string, error) {
	if strings.Count(r.RequestURI, "?") > 1 {
		return "", fmt.Errorf("multiple values provided for parameter %q", param)
	}

	params := r.URL.Query()[param]
	if len(params) > 1 {
		return "", fmt.Errorf("multiple values provided for parameter %q", param)
	}

	if len(params) == 0 {
		return "", nil
	}

	// Validate that the parameter contains only allowed characters.
	validKey := regexp.MustCompile(`^[a-zA-Z0-9_.\[\]*]+$`)
	if !validKey.MatchString(params[0]) {
		return "", fmt.Errorf("invalid characters in parameter %q", param)
	}
	return params[0], nil
}

// deepCopy creates a deep copy of data using JSON marshalling.
// It is suitable for data types that can be represented as JSON (e.g., maps and slices).
func deepCopy(data any) (any, error) {
	bytes, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}
	var copy any
	if err := json.Unmarshal(bytes, &copy); err != nil {
		return nil, err
	}
	return copy, nil
}

// calculateDiff recursively compares two data structures (maps or slices) and returns the differences.
// If the data is not equal, it returns the updated data.
func calculateDiff(oldData, newData any) any {
	// If both values are slices, delegate to calculateSliceDiff.
	if oldSlice, ok := oldData.([]any); ok {
		if newSlice, ok2 := newData.([]any); ok2 {
			return calculateSliceDiff(oldSlice, newSlice)
		}
	}

	// If both values are maps, compare them key by key.
	if oldMap, ok := oldData.(map[string]any); ok {
		if newMap, ok2 := newData.(map[string]any); ok2 {
			diff := make(map[string]any)

			// Check keys present in the new map.
			for key, newVal := range newMap {
				if oldVal, exists := oldMap[key]; exists {
					subDiff := calculateDiff(oldVal, newVal)
					if subDiff != nil {
						diff[key] = subDiff
					}
				} else {
					// New key added.
					diff[key] = newVal
				}
			}

			// Check for keys that were removed.
			for key := range oldMap {
				if _, exists := newMap[key]; !exists {
					diff[key] = nil
				}
			}
			if len(diff) > 0 {
				return diff
			}
			return nil
		}
	}

	// For atomic types, if they differ, return the new value.
	if !reflect.DeepEqual(oldData, newData) {
		return newData
	}
	return nil
}

// calculateSliceDiff compares two slices element by element.
// If the slices have different lengths, it returns the new slice entirely.
// Otherwise, it returns a map with indices (as strings) where differences are found.
func calculateSliceDiff(oldSlice, newSlice []any) any {
	if len(oldSlice) != len(newSlice) {
		return newSlice
	}

	diffMap := make(map[string]any)
	for i, newVal := range newSlice {
		subDiff := calculateDiff(oldSlice[i], newVal)
		if subDiff != nil {
			// Use the index (converted to string) as the key.
			diffMap[strconv.Itoa(i)] = subDiff
		}
	}

	if len(diffMap) > 0 {
		return diffMap
	}
	return nil
}

// handleWebSocketMessage processes a message received over the WebSocket connection.
// It delegates the message handling to the handler and sends the response back to the client.
func (s *FusionServer) handleWebSocketMessage(conn *websocket.Conn, data []byte) {
	response, err := s.handler.HandleWebSocketMessage(data)
	if err != nil {
		if err := conn.WriteJSON(map[string]any{
			"type":    "error",
			"message": err.Error(),
		}); err != nil {
			logging.GetLogger().Error("Error sending error response: %v", err)
		}
		return
	}

	if err := conn.WriteJSON(response); err != nil {
		logging.GetLogger().Error("Error sending response: %v", err)
	}
}

// extractName pulls the “name” var from mux and returns a proper error if it’s missing.
func extractName(r *http.Request) (string, error) {
	name := mux.Vars(r)["name"]
	if name == "" {
		return "", fmt.Errorf("name is required")
	}
	return filepath.Base(name), nil
}
