package server

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"reflect"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/logging"

	"github.com/gorilla/websocket"
	"github.com/hashicorp/memberlist"
)

const (
	keepalivedConfPath = "/etc/keepalived/keepalived.conf"
)

type ConfigServer struct {
	nodeName    string
	handler     *Handler
	wsClients   map[*websocket.Conn]bool
	wsLock      sync.RWMutex
	upgrader    websocket.Upgrader
	clusterList *memberlist.Memberlist
}

type Endpoints struct {
	API       string   `json:"api"`
	Telemetry []string `json:"telemetry"`
	Metrics   string   `json:"metrics"`
}

func NewConfigServer(nodeName string, handler *Handler, clusterList *memberlist.Memberlist) *ConfigServer {
	server := &ConfigServer{
		nodeName:  nodeName,
		handler:   handler,
		wsClients: make(map[*websocket.Conn]bool),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
			HandshakeTimeout:  10 * time.Second,
			EnableCompression: true,
			ReadBufferSize:    1024,
			WriteBufferSize:   1024,
		},
		clusterList: clusterList,
	}
	handler.AddBroadcaster(server)
	return server
}

func (s *ConfigServer) BroadcastUpdate(update map[string]any) error {
	message := map[string]any{
		"type": "set",
		"data": update,
	}

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

func (s *ConfigServer) GetValue(w http.ResponseWriter, r *http.Request) {

	if !s.IsGetRequest(w, r) {
		return
	}

	key, err := getSingleQueryParam(r, "key")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	response, err := s.handler.HandleHTTPGet(key)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(response)
}

func (s *ConfigServer) SetValue(w http.ResponseWriter, r *http.Request) {

	if !s.IsPostRequest(w, r) {
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

	response, err := s.handler.HandleHTTPSet(update)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(response)
}

func (s *ConfigServer) UpdateValue(w http.ResponseWriter, r *http.Request) {
	if !s.IsPatchRequest(w, r) {
		return
	}

	// Read the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error reading request body: %v", err), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Parse the request body into a map
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

	configData := s.handler.transformState(s.handler.stateManager.GetFullState())

	// Create a deep copy of configData to preserve the original configuration.
	originalConfig, err := deepCopy(configData)
	if err != nil {
		http.Error(w, fmt.Sprintf("Error copying original configuration: %v", err), http.StatusInternalServerError)
		return
	}

	var updatedData any
	if key != "" {
		// Use the existing config
		setNestedValue(configData, key, update["value"])
		updatedData, err = s.handler.HandleHTTPPatch(configData)
	} else {
		// If no key is provided, treat the entire body as the update map
		updatedData, err = s.handler.HandleHTTPPatch(update)
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	diffData := calculateDiff(originalConfig, updatedData)

	response := map[string]any{
		"status":  "success",
		"updates": diffData,
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, fmt.Sprintf("Error encoding response: %v", err), http.StatusInternalServerError)
	}
}

func (s *ConfigServer) DumpState(w http.ResponseWriter, r *http.Request) {

	if !s.IsGetRequest(w, r) {
		return
	}

	state := map[string]any{"state": s.handler.stateManager.GetFullState()}

	w.Header().Set(api.ContentType, api.JsonContentType)
	encoder := json.NewEncoder(w)
	if err := encoder.Encode(state); err != nil {
		logging.GetLogger().Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

func (s *ConfigServer) GetEndpoints(w http.ResponseWriter, r *http.Request) {

	if !s.IsGetRequest(w, r) {
		return
	}

	vip, err := GetVIPAddress()
	if err != nil {
		logging.GetLogger().Error("Unable to get VIP: %v", err)
	}

	clusterAddresses := s.getClusterIPs()
	var addressesWithPort []string
	for _, addr := range clusterAddresses {
		addressesWithPort = append(addressesWithPort, addr+api.ZMQPort)
	}

	endpoints := Endpoints{
		API:       vip + api.HTTPPort,
		Telemetry: addressesWithPort,
		Metrics:   vip + api.MetricsPort,
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(endpoints)
}

func (s *ConfigServer) HandleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		logging.GetLogger().Error("Failed to upgrade connection: %v", err)
		return
	}

	conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	conn.SetPongHandler(func(string) error {
		conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	pingTicker := time.NewTicker(30 * time.Second)
	go func() {
		defer pingTicker.Stop()
		for range pingTicker.C {
			if err := conn.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(10*time.Second)); err != nil {
				logging.GetLogger().Error("Ping failed: %v", err)
				return
			}
		}
	}()

	s.wsLock.Lock()
	s.wsClients[conn] = true
	s.wsLock.Unlock()

	defer func() {
		pingTicker.Stop()
		conn.Close()
		s.wsLock.Lock()
		delete(s.wsClients, conn)
		s.wsLock.Unlock()
	}()

	// Get initial state through handler
	state, err := s.handler.HandleHTTPGet("")
	if err != nil {
		logging.GetLogger().Error("Failed to get data: %v", err)
		return
	}

	if err := conn.WriteJSON(state); err != nil {
		logging.GetLogger().Error("Failure sending initial state: %v", err)
		return
	}

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

func (s *ConfigServer) getClusterIPs() []string {
	var ips []string
	for _, member := range s.clusterList.Members() {
		// Extract IP address of each member
		ips = append(ips, member.Addr.String())
	}
	return ips
}

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

func (s *ConfigServer) DownloadState(w http.ResponseWriter, r *http.Request) {

	if !s.IsGetRequest(w, r) {
		return
	}

	response, err := s.handler.HandleDownload()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=config_export_%s.json",
		time.Now().UTC().Format("20060102_150405")))

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(response); err != nil {
		logging.GetLogger().Error("Export state failed: %v", err)
		http.Error(w, "Error exporting state", http.StatusInternalServerError)
	}
}

func (s *ConfigServer) HandleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	info, err := s.handler.GetServerInfo()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(info)
}

func (s *ConfigServer) UpdateVersion(w http.ResponseWriter, r *http.Request) {
	if !s.IsPostRequest(w, r) {
		return
	}
	s.handler.HandleVersionUpdate(w, r)
}

func (s *ConfigServer) RollbackVersion(w http.ResponseWriter, r *http.Request) {
	if !s.IsPostRequest(w, r) {
		return
	}
	s.handler.HandleVersionRollback(w, r)
}

func (s *ConfigServer) UploadAudio(w http.ResponseWriter, r *http.Request) {
	if !s.IsPostRequest(w, r) {
		return
	}
	s.handler.HandleAudioUpload(w, r)
}

// ListSnapshots handles GET /snapshots.
func (s *ConfigServer) ListSnapshots(w http.ResponseWriter, r *http.Request) {
	if !s.IsGetRequest(w, r) {
		return
	}

	snapshots, err := s.handler.HandleListSnapshots()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error listing snapshots: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(map[string]any{"snapshots": snapshots})
}

// CreateSnapshot handles POST /snapshots/create.
// It expects a query parameter "name" for the snapshot to create.
func (s *ConfigServer) CreateSnapshot(w http.ResponseWriter, r *http.Request) {
	if !s.IsPostRequest(w, r) {
		return
	}

	snapshotName, err := getSingleQueryParam(r, "name")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
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

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "snapshot created",
		"snapshot": snapshotName,
	})
}

// ActivateSnapshotHTTP handles PUT /snapshots/activate.
// It expects a query parameter "name" for the snapshot to activate.
func (s *ConfigServer) ActivateSnapshotHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPut {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	snapshotName, err := getSingleQueryParam(r, "name")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	if snapshotName == "" {
		http.Error(w, "Snapshot name is required", http.StatusBadRequest)
		return
	}
	if err := s.handler.HandleActivateSnapshot(snapshotName); err != nil {
		http.Error(w, fmt.Sprintf("Error activating snapshot: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "snapshot activated",
		"snapshot": snapshotName,
	})
}

// DeleteSnapshot handles DELETE /snapshots/delete.
// It expects a query parameter "name" for the snapshot to delete.
func (s *ConfigServer) DeleteSnapshot(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	snapshotName, err := getSingleQueryParam(r, "name")
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
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

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(map[string]string{
		"status":   "snapshot deleted",
		"snapshot": snapshotName,
	})
}

// GetSnapshotMetadata handles GET /snapshots/metadata
func (s *ConfigServer) GetSnapshotMetadata(w http.ResponseWriter, r *http.Request) {
	if !s.IsGetRequest(w, r) {
		return
	}

	metadata, err := s.handler.HandleGetSnapshotMetadata()
	if err != nil {
		http.Error(w, fmt.Sprintf("Error getting snapshot metadata: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set(api.ContentType, api.JsonContentType)
	json.NewEncoder(w).Encode(map[string]any{"metadata": metadata})
}

func (s *ConfigServer) IsGetRequest(w http.ResponseWriter, r *http.Request) bool {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return false
	}
	return true
}

func (s *ConfigServer) IsPostRequest(w http.ResponseWriter, r *http.Request) bool {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return false
	}
	return true
}

func (s *ConfigServer) IsPatchRequest(w http.ResponseWriter, r *http.Request) bool {
	if r.Method != http.MethodPatch {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return false
	}
	return true
}

// GetVIPAddress returns the VIP address retrieved from keepalived
func GetVIPAddress() (string, error) {
	file, err := os.Open(keepalivedConfPath)
	if err != nil {
		return "", fmt.Errorf("failed to open Keepalived config file: %v", err)
	}
	defer file.Close()

	var vip string
	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		// Look for "virtual_ipaddress {" and get the next IP
		if strings.HasPrefix(line, "virtual_ipaddress") {
			for scanner.Scan() {
				nextLine := strings.TrimSpace(scanner.Text())
				if strings.HasPrefix(nextLine, "}") { // End of block
					break
				}

				// Extract IP address (e.g., 192.168.1.100/24)
				vipRegex := regexp.MustCompile(`(\d+\.\d+\.\d+\.\d+)(/\d+)?`)
				matches := vipRegex.FindStringSubmatch(nextLine)
				if len(matches) > 0 {
					vip = matches[1] // Get the IP portion
					break
				}
			}
		}
	}

	if err := scanner.Err(); err != nil {
		return "", fmt.Errorf("error reading Keepalived config: %v", err)
	}

	if vip == "" {
		return "", fmt.Errorf("no VIP found in Keepalived config")
	}

	return vip, nil
}

// getSingleQueryParam returns the value of the parameter if it exists exactly once.
// If the key missing it returns an empty string.
// If the key appears more than once it returns an error.
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

	// Optionally, validate that the key contains only allowed characters.
	// For example, allow letters, digits, underscores, periods, square brackets:
	validKey := regexp.MustCompile(`^[a-zA-Z0-9_.\[\]*]+$`)
	if !validKey.MatchString(params[0]) {
		return "", fmt.Errorf("invalid characters in parameter %q", param)
	}
	return params[0], nil
}

// deepCopy creates a deep copy of the provided data using JSON marshalling.
// It works well for data structures that can be represented in JSON, such as maps.
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

// calculateDiff compares the original and updated configurations and returns the differences.
// It handles maps and slices (arrays) recursively.
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

			// Check keys in newMap.
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

	// For other (atomic) types, if they are not deeply equal, return newData.
	if !reflect.DeepEqual(oldData, newData) {
		return newData
	}
	return nil
}

// calculateSliceDiff compares two slices element by element.
// If the slices have different lengths, it returns the new slice entirely.
// Otherwise, it returns a map where the keys are the (stringified) indices of changed elements.
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
