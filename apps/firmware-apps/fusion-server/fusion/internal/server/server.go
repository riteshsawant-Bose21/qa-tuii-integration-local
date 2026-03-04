package server

import (
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"

	json "github.com/goccy/go-json"

	"fusion-services-core/logging"
	"fusion/internal/api"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
	"fusion/internal/server/handler"
	"fusion/internal/utils"

	"github.com/gorilla/websocket"
)

// FusionServer handles networks connections to manage Fusion state.
type FusionServer struct {
	node          string
	handler       *handler.Handler
	wsClients     map[*websocket.Conn]bool
	wsWriteMutex  map[*websocket.Conn]*sync.Mutex     // Per-connection write mutexes
	subscriptions map[string]map[*websocket.Conn]bool // Topic-based subscriptions: topic -> connections
	wsLock        sync.RWMutex
	upgrader      websocket.Upgrader
	wsStats       *api.WebSocketStats
	statsLock     sync.RWMutex

	maxConnections int
}

// NewFusionServer creates and initializes a new configuration server with the provided node name,
// handler and cluster member list. It also sets up a WebSocket upgrader with custom options.
func NewFusionServer(node string, handler *handler.Handler, hub *pubsub.Hub) *FusionServer {
	server := &FusionServer{
		node:           node,
		handler:        handler,
		wsClients:      make(map[*websocket.Conn]bool),
		wsWriteMutex:   make(map[*websocket.Conn]*sync.Mutex),
		subscriptions:  make(map[string]map[*websocket.Conn]bool),
		maxConnections: wsMaxConnections,
		wsStats: &api.WebSocketStats{
			Connections:    0,
			Messages:       0,
			Errors:         0,
			Uptime:         0,
			LastReset:      time.Now(),
			MessagesByType: make(map[string]int64),
		},
	}

	// Set up the WebSocket upgrader after server creation
	server.upgrader = websocket.Upgrader{
		HandshakeTimeout:  wsTimeout * time.Second,
		EnableCompression: true,
		ReadBufferSize:    wsBufferSize,
		WriteBufferSize:   wsBufferSize,
	}
	hub.Register(server)
	return server
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

// SetValue handles HTTP PUT requests to set a configuration value.
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

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	var update map[string]any
	if err := json.Unmarshal(body, &update); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON format: %v", err), http.StatusBadRequest)
		return
	}

	key, err := getSingleQueryParam(r, "key")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Build minimal patch map
	var patch map[string]any
	if key != "" {
		patch = map[string]any{
			key: update["value"],
		}
	} else {
		patch = update
	}

	// Apply patch (diff is computed inside handler)
	diff, err := s.handler.HandleHTTPPatch(patch)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Build response
	resp := map[string]any{}
	if diff == nil {
		resp["status"] = "noop"
		resp["updates"] = nil
	} else {
		resp["status"] = "success"
		resp["updates"] = diff
	}

	// Send
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(resp)
}

// ExportState handles HTTP GET requests to export the entire configuration state.
func (s *FusionServer) ExportState(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve the full state from the state manager.
	state := s.handler.StateManager.GetFullState()

	// Write the JSON response.
	encoder := json.NewEncoder(w)
	if err := encoder.Encode(state); err != nil {
		logging.GetLogger().Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
		return
	}
	w.Header().Set(api.ContentType, api.JsonMIMEType)

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

// UploadAudio handles HTTP POST requests for audio file uploads.
// It delegates the audio upload handling to the handler.
func (s *FusionServer) UploadAudio(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	s.handler.HandleAudioUpload(w, r)
}

// GetDatabaseMetadata handles HTTP GET requests to retrieve fusion database metadata.
func (s *FusionServer) GetDatabaseMetadata(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	// Retrieve metadata from the handler.
	metadata, err := s.handler.HandleGetDatabaseMetadata()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error getting database metadata: %v", err), http.StatusInternalServerError)
		return
	}

	// Write the JSON response with metadata.
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]any{"metadata": metadata})
}

// ExportData handles HTTP GET requests to export all data.
func (s *FusionServer) ExportData(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	data, err := s.handler.HandleExportData()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error exporting data: %v", err), http.StatusInternalServerError)
		return
	}

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
	members := s.handler.GetMembers()
	if err := json.NewEncoder(w).Encode(members); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set(api.ContentType, api.JsonMIMEType)
}

func (s *FusionServer) ListMessages(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	s.handler.HandleAudioList(w, r)
}

func (s *FusionServer) ListMessageTags(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	s.handler.HandleAudioTagList(w, r)
}

func (s *FusionServer) GetMessage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	s.handler.HandleAudioGet(w, r)
}

func (s *FusionServer) StreamMessage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
	s.handler.HandleAudioStream(w, r)
}

func (s *FusionServer) UploadMessage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePost(w, r) {
		return
	}
	s.handler.HandleAudioUpload(w, r)
}

func (s *FusionServer) DeleteMessage(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}
	s.handler.HandleAudioRemove(w, r)
}

func (s *FusionServer) ListZones(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) GetZoneStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) GetSystemDiagnostics(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) GetSystemStatus(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}
}

func (s *FusionServer) CancelAlarms(w http.ResponseWriter, r *http.Request) {
	if !utils.RequirePut(w, r) {
		return
	}
}

// GetSessions handles HTTP GET requests to get SAP sessions
func (s *FusionServer) GetSessions(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	sessions := s.handler.HandleListSessions()

	err := json.NewEncoder(w).Encode(map[string]any{"sessions": sessions})
	if err != nil {
		logging.GetLogger().Error("Failed to encode JSON: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	w.Header().Set(api.ContentType, api.JsonMIMEType)
}

// GetSession handles HTTP GET requests to get a SAP session by identifier
func (s *FusionServer) GetSession(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	session := s.handler.HandleGetSession(id)
	if session == nil {
		http.Error(w, fmt.Sprintf("Session %s not found.", id), http.StatusNotFound)
		return
	}

	if err := json.NewEncoder(w).Encode(session); err != nil {
		logging.GetLogger().Error("Failed to encode JSON: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
}

// GetControllers handles HTTP GET requests to list registered controllers.
func (s *FusionServer) GetControllers(w http.ResponseWriter, r *http.Request) {

	if !utils.RequireGet(w, r) {
		return
	}

	result := s.handler.HandleGetControllers()
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(result)
}

// GetControllerByID handles HTTP GET requests to get a specific controller info.
func (s *FusionServer) GetControllerByID(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid controller ID: %v", err), http.StatusBadRequest)
		return
	}

	ctrl, err := s.handler.HandleGetControllerByID(id)
	if err != nil {
		// If the handler returns a not found error, return 404
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			http.Error(w, err.Error(), http.StatusNotFound)
		} else {
			http.Error(w, fmt.Sprintf("Error retrieving controller: %v", err), http.StatusInternalServerError)
		}
		return
	}

	if ctrl == nil {
		http.Error(w, "Controller not found", http.StatusNotFound)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(ctrl); err != nil {
		http.Error(w, fmt.Sprintf("Failed to encode response: %v", err), http.StatusInternalServerError)
	}
}
func (s *FusionServer) TriggerWinkById(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	id, err := utils.ExtractId(r)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid controller ID: %v", err), http.StatusBadRequest)
		return
	}

	err = s.handler.HandleTriggerWink(id)
	if err != nil {
		// If the handler returns a not found error, return 404
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			http.Error(w, err.Error(), http.StatusNotFound)
		} else {
			http.Error(w, fmt.Sprintf("Error triggering wink for controller: %v", err), http.StatusInternalServerError)
		}
		return
	}

	// Return success response for wink command
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.WriteHeader(http.StatusOK)
	response := map[string]any{
		"status":        "success",
		"message":       "Wink command sent successfully",
		"controller_id": id,
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, fmt.Sprintf("Failed to encode response: %v", err), http.StatusInternalServerError)
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
