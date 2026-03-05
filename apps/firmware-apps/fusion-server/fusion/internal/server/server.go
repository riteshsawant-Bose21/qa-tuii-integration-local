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

const (
	wsBufferSize = 1024
	wsPingTime   = 30
	wsPongTime   = 60
	wsTimeout    = 10
)

// FusionServer handles networks connections to manage Fusion state.
type FusionServer struct {
	node      string
	handler   *handler.Handler
	wsClients map[*websocket.Conn]bool
	wsLock    sync.RWMutex
	upgrader  websocket.Upgrader
}

// NewFusionServer creates and initializes a new configuration server with the provided node name,
// handler and cluster member list. It also sets up a WebSocket upgrader with custom options.
func NewFusionServer(node string, handler *handler.Handler, hub *pubsub.Hub) *FusionServer {
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
	}
	hub.Register(server)
	return server
}

// BroadcastMessage sends a notification message to all connected WebSocket clients.
// It acquires a read lock on the clients list to ensure thread-safe access.
func (s *FusionServer) BroadcastMessage(message *api.NotifyMessage) error {
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
	if err := json.NewEncoder(w).Encode(response); err != nil {
		logging.GetLogger().Error("Error encoding GET response: %v", err)
	}
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
	if err := json.NewEncoder(w).Encode(response); err != nil {
		logging.GetLogger().Error("Error encoding SET response: %v", err)
	}
}

// UpdateValue handles HTTP PATCH requests to update a configuration value.
// It supports partial updates based on the provided key query parameter or the entire JSON body.
func (s *FusionServer) UpdateValue(w http.ResponseWriter, r *http.Request) {
	type patchResponse struct {
		Status  string         `json:"status"`
		Updates map[string]any `json:"updates"`
	}

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
	resp := patchResponse{}
	if diff == nil {
		resp.Status = "noop"
		resp.Updates = nil
	} else {
		resp.Status = "success"
		resp.Updates = diff
	}

	// Send
	w.Header().Set(api.ContentType, api.JsonMIMEType)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		logging.GetLogger().Error("Error encoding PATCH response: %v", err)
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
	if err := json.NewEncoder(w).Encode(info); err != nil {
		logging.GetLogger().Error("Error encoding server info: %v", err)
	}
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

	// Check for nil metadata to prevent encoding panics during shutdown
	if metadata == nil {
		http.Error(w, "Metadata not available", http.StatusServiceUnavailable)
		return
	}

	// Marshal to bytes first to catch any panics before writing to response
	var data []byte
	func() {
		defer func() {
			if r := recover(); r != nil {
				logging.GetLogger().Error("Panic while encoding metadata: %v", r)
				data = nil
			}
		}()
		var marshalErr error
		data, marshalErr = json.Marshal(databaseMetadataResponse{Metadata: metadata})
		if marshalErr != nil {
			logging.GetLogger().Error("Error marshaling database metadata: %v", marshalErr)
			data = nil
		}
	}()

	if data == nil {
		http.Error(w, "Error encoding metadata", http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonMIMEType)
	w.Write(data)
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
	if err := json.NewEncoder(w).Encode(data); err != nil {
		logging.GetLogger().Error("Error encoding export data: %v", err)
	}
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
	if err := json.NewEncoder(w).Encode(result); err != nil {
		logging.GetLogger().Error("Error encoding controllers: %v", err)
	}
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

// handleWebSocketMessage processes a message received over the WebSocket connection.
// It delegates the message handling to the handler and sends the response back to the client.
func (s *FusionServer) handleWebSocketMessage(conn *websocket.Conn, data []byte) {
	type websocketErrorResponse struct {
		Type    string `json:"type"`
		Message string `json:"message"`
	}

	response, err := s.handler.HandleWebSocketMessage(data)
	if err != nil {
		if err := conn.WriteJSON(websocketErrorResponse{
			Type:    "error",
			Message: err.Error(),
		}); err != nil {
			logging.GetLogger().Error("Error sending error response: %v", err)
		}
		return
	}

	if err := conn.WriteJSON(response); err != nil {
		logging.GetLogger().Error("Error sending response: %v", err)
	}
}
