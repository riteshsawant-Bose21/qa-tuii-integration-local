package server

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"
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

// ConfigServer handles HTTP and WebSocket connections to manage configuration state.
type ConfigServer struct {
	node        string
	handler     *Handler
	wsClients   map[*websocket.Conn]bool
	wsLock      sync.RWMutex
	upgrader    websocket.Upgrader
	clusterList *memberlist.Memberlist
}

// NewConfigServer creates and initializes a new configuration server with the provided node name,
// handler and cluster member list. It also sets up a WebSocket upgrader with custom options.
func NewConfigServer(node string, handler *Handler, clusterList *memberlist.Memberlist) *ConfigServer {
	server := &ConfigServer{
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
func (s *ConfigServer) BroadcastUpdate(message api.NotifyMessage) error {
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
func (s *ConfigServer) GetValue(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
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
func (s *ConfigServer) SetValue(w http.ResponseWriter, r *http.Request) {

	if !utils.IsPostRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
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
func (s *ConfigServer) UpdateValue(w http.ResponseWriter, r *http.Request) {

	if !utils.IsPatchRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
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
	configData := TransformState(s.handler.stateManager.GetFullState().State)

	// Create a deep copy of configData to preserve the original configuration.
	originalConfig, err := deepCopy(configData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error copying original configuration: %v", err), http.StatusInternalServerError)
		return
	}

	var updatedData any
	if key != "" {
		// If a key is provided, update the nested value.
		setNestedValue(configData, key, update["value"])
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
func (s *ConfigServer) ExportState(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Retrieve the full state from the state manager.
	state := map[string]any{"state": s.handler.stateManager.GetFullState()}

	// Write the JSON response.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	encoder := json.NewEncoder(w)
	if err := encoder.Encode(state); err != nil {
		logging.GetLogger().Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

// ImportState handles HTTP POST requests to import configuration state.
func (s *ConfigServer) ImportState(w http.ResponseWriter, r *http.Request) {
	if !utils.IsPostRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
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
	var data map[string]*api.StateEntry
	err = json.Unmarshal(body, &data)
	if err != nil {
		http.Error(w, fmt.Sprintf("error unmarshaling json: %v", err), http.StatusInternalServerError)
		return
	}

	s.handler.stateManager.SetState(data)
}

// HandleWebSocket upgrades an HTTP connection to a WebSocket connection, sets up ping handlers,
// sends an initial state to the client, and listens for incoming messages.
func (s *ConfigServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
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
func (s *ConfigServer) HandleRoot(w http.ResponseWriter, r *http.Request) {
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

// HandleVersion handles HTTP requests.
// It delegates the version handling to the handler.
func (s *ConfigServer) HandleVersion(w http.ResponseWriter, r *http.Request) {

	if utils.IsPostRequest(r) {
		s.handler.HandleVersionUpdate(w, r)
		return
	}

	if utils.IsPostRequest(r) {
		s.handler.HandleVersionRollback(w, r)
		return
	}
}

// UploadAudio handles HTTP POST requests for audio file uploads.
// It delegates the audio upload handling to the handler.
func (s *ConfigServer) UploadAudio(w http.ResponseWriter, r *http.Request) {
	if !utils.IsPostRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	s.handler.HandleAudioUpload(w, r)
}

// ListSnapshots handles HTTP GET requests to list available snapshots.
func (s *ConfigServer) ListSnapshots(w http.ResponseWriter, r *http.Request) {
	if !utils.IsGetRequest(r) {
		http.Error(w, "Invalid request type", http.StatusInternalServerError)
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
func (s *ConfigServer) ActivateSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	snapshotName := vars["name"]
	if snapshotName == "" {
		http.Error(w, "Snapshot name is required", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleActivateSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error activating snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "snapshot activated",
		"snapshot": snapshotName,
	})
}

// CreateSnapshot handles HTTP POST requests to create a new snapshot.
func (s *ConfigServer) CreateSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	snapshotName := vars["name"]
	if snapshotName == "" {
		http.Error(w, "Snapshot name is required", http.StatusBadRequest)
		return
	}

	if snapshotName == defaultSnapshotKey {
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

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "snapshot created",
		"snapshot": snapshotName,
	})
}

// DeleteSnapshot handles HTTP DELETE requests to remove an existing snapshot.
// It expects a query parameter "name" specifying the snapshot to delete.
func (s *ConfigServer) DeleteSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	snapshotName := vars["name"]
	if snapshotName == "" {
		http.Error(w, "Snapshot name is required", http.StatusBadRequest)
		return
	}
	if snapshotName == defaultSnapshotKey {
		http.Error(w, "default snapshot cannot be deleted", http.StatusBadRequest)
		return
	}

	if err := s.handler.HandleDeleteSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error deleting snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "snapshot deleted",
		"snapshot": snapshotName,
	})
}

// GetDatabaseMetadata handles HTTP GET requests to retrieve fusion database metadata.
func (s *ConfigServer) GetDatabaseMetadata(w http.ResponseWriter, r *http.Request) {
	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
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
func (s *ConfigServer) GetSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	vars := mux.Vars(r)
	snapshotName := vars["name"]
	if snapshotName == "" {
		http.Error(w, "Snapshot name is required", http.StatusBadRequest)
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
func (s *ConfigServer) ExportData(w http.ResponseWriter, r *http.Request) {
	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
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
func (s *ConfigServer) ImportData(w http.ResponseWriter, r *http.Request) {
	if !utils.IsPostRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
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
func (s *ConfigServer) ClearAllValues(w http.ResponseWriter, r *http.Request) {

	if !utils.IsDeleteRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Clear the data using the handler.
	if err := s.handler.HandleClearAllData(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Write the JSON response confirming the operation.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]any{
		"status":  "success",
		"message": "All data cleared successfully",
	})
}

// GetMembers handles HTTP GET requests to list all cluster members.
func (s *ConfigServer) GetMembers(w http.ResponseWriter, r *http.Request) {

	if !utils.IsGetRequest(r) {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Retrieve the list of members from the handler's member list.
	members := s.handler.memberlist.Members()
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(members); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
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
func (s *ConfigServer) handleWebSocketMessage(conn *websocket.Conn, data []byte) {
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
