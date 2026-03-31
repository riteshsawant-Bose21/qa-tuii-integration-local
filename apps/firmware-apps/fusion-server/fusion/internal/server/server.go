package server

import (
	stdjson "encoding/json"
	"fmt"
	"io"
	"net/http"
	"strconv"
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

	"github.com/gorilla/mux"
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
		// CheckOrigin allows all origins for WebSocket connections.
		CheckOrigin: func(r *http.Request) bool {
			return true // Allow all origins
		},
	}
	hub.Register(server)
	return server
}

// GetAudioSettings handles HTTP GET requests for audio settings data.
func (s *FusionServer) GetAudioSettings(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	vars := mux.Vars(r)
	key := "settings.audio"
	if blockID := vars["blockId"]; blockID != "" {
		key += "." + blockID
	}

	value, exists := s.handler.StateManager.Get(key)
	if !exists {
		http.Error(w, "settings not found", http.StatusNotFound)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(value)
}

// GetAudioSetting handles HTTP GET requests for a single audio setting value.
func (s *FusionServer) GetAudioSetting(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireGet(w, r) {
		return
	}

	key, err := audioSettingKeyFromRequest(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	value, exists := s.handler.StateManager.Get(key)
	if !exists {
		http.Error(w, "setting not found", http.StatusNotFound)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(map[string]any{"value": value})
}

// PatchAudioSetting handles HTTP PATCH requests for audio setting updates.
func (s *FusionServer) PatchAudioSetting(w http.ResponseWriter, r *http.Request) {
	type patchResponse struct {
		Status  string         `json:"status"`
		Updates map[string]any `json:"updates"`
	}

	if !utils.RequirePatch(w, r) {
		return
	}

	key, err := audioSettingKeyFromRequest(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
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

	diff, err := s.handler.HandleHTTPPatch(map[string]any{key: update["value"]})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp := patchResponse{}
	if diff == nil {
		resp.Status = "noop"
		resp.Updates = nil
	} else {
		resp.Status = "success"
		resp.Updates = diff
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	json.NewEncoder(w).Encode(resp)
}

// ClearAudioSettings handles HTTP DELETE requests to clear audio settings.
func (s *FusionServer) ClearAudioSettings(w http.ResponseWriter, r *http.Request) {
	if !utils.RequireDelete(w, r) {
		return
	}

	diff, err := s.handler.HandleHTTPPatch(map[string]any{"settings.audio": nil})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if diff == nil {
		json.NewEncoder(w).Encode(map[string]any{"status": "noop"})
		return
	}
	json.NewEncoder(w).Encode(map[string]any{"status": "success"})
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
	type databaseMetadataResponse struct {
		Metadata *api.DatabaseMetadata `json:"metadata"`
	}

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
	stdjson.NewEncoder(w).Encode(databaseMetadataResponse{Metadata: metadata})
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

func audioSettingKeyFromRequest(r *http.Request) (string, error) {
	vars := mux.Vars(r)

	blockID := vars["blockId"]
	param := vars["param"]
	if blockID == "" || param == "" {
		return "", fmt.Errorf("blockId and param are required")
	}

	key := "settings.audio." + blockID + "." + param
	if index := vars["index"]; index != "" {
		if _, err := strconv.Atoi(index); err != nil {
			return "", fmt.Errorf("index must be an integer")
		}
		key += "[" + index + "]"
	}

	return key, nil
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
	type sessionsResponse struct {
		Sessions map[string]*handler.SAPSession `json:"sessions"`
	}

	if !utils.RequireGet(w, r) {
		return
	}

	sessions := s.handler.HandleListSessions()

	err := json.NewEncoder(w).Encode(sessionsResponse{Sessions: sessions})
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
	type winkResponse struct {
		Status       string `json:"status"`
		Message      string `json:"message"`
		ControllerID string `json:"controller_id"`
	}

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
	response := winkResponse{
		Status:       "success",
		Message:      "Wink command sent successfully",
		ControllerID: id,
	}
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, fmt.Sprintf("Failed to encode response: %v", err), http.StatusInternalServerError)
	}
}
