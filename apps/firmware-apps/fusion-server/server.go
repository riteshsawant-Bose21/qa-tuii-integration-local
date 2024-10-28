package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/hashicorp/memberlist"
)

var (
	stateManager   *StateManager
	nodeName       string
	bindAddr       string
	bindPort       int
	wsClients      = make(map[*websocket.Conn]bool)
	wsClientsMutex sync.Mutex
	list           *memberlist.Memberlist
	persistence    *ConfigPersistence
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all connections
	},
}

type GossipDelegate struct {
	logger *log.Logger
	nodeID string
}

func (d *GossipDelegate) NodeMeta(limit int) []byte {
	return []byte{}
}

type ConfigUpdate struct {
	Key     string      `json:"key"`
	Value   interface{} `json:"value"`
	Version int64       `json:"version"`
	NodeID  string      `json:"node_id"`
	Time    time.Time   `json:"timestamp"`
}

func (d *GossipDelegate) NotifyMsg(msg []byte) {
	var update ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		d.logger.Printf("Error unmarshaling update: %v", err)
		return
	}

	if err := stateManager.ApplyUpdate(update); err != nil {
		d.logger.Printf("Error applying update: %v", err)
	}
}

func (d *GossipDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *GossipDelegate) LocalState(join bool) []byte {
	state := stateManager.GetFullState()
	// d.logger.Printf("LocalState called (join=%v): sending state with %d entries from node %s",
	// 	join, len(state), d.nodeID)

	data, err := json.Marshal(state)
	if err != nil {
		d.logger.Printf("Error marshaling local state: %v", err)
		return nil
	}

	return data
}

func (d *GossipDelegate) MergeRemoteState(buf []byte, join bool) {
	// d.logger.Printf("MergeRemoteState called with join=%v, data size=%d bytes",
	// 	join, len(buf))

	var remoteState map[string]*StateEntry
	if err := json.Unmarshal(buf, &remoteState); err != nil {
		d.logger.Printf("Error unmarshaling remote state: %v", err)
		d.logger.Printf("Raw data: %s", string(buf))
		return
	}

	// Pass both the state and the source node information
	stateManager.MergeRemoteState(remoteState, d.nodeID)
}

func monitorClusterState(list *memberlist.Memberlist, nodeName string) {
	logger := log.New(os.Stdout, fmt.Sprintf("[MONITOR-%s] ", nodeName), log.LstdFlags)

	go func() {
		for {
			// Monitor cluster membership
			members := list.Members()
			logger.Printf("Cluster Status:")
			logger.Printf("  Members (%d):", len(members))

			aliveCount := 0
			for _, member := range members {
				status := "UNKNOWN"
				switch member.State {
				case memberlist.StateAlive:
					status = "ALIVE"
					aliveCount++
				case memberlist.StateSuspect:
					status = "SUSPECT"
				case memberlist.StateDead:
					status = "DEAD"
				}

				logger.Printf("    - %s (%s:%d) Status: %s",
					member.Name, member.Addr, member.Port, status)
			}

			// Get current state
			state := stateManager.GetFullState()

			// Collect state statistics
			nodeStats := make(map[string]int)
			var oldestUpdate, newestUpdate time.Time
			var totalEntries int

			for _, entry := range state {
				nodeStats[entry.NodeID]++
				totalEntries++

				if oldestUpdate.IsZero() || entry.Timestamp.Before(oldestUpdate) {
					oldestUpdate = entry.Timestamp
				}
				if entry.Timestamp.After(newestUpdate) {
					newestUpdate = entry.Timestamp
				}
			}

			// Log state summary
			logger.Printf("State Summary:")
			logger.Printf("  Version: %d", stateManager.version)
			logger.Printf("  Total Entries: %d", totalEntries)
			logger.Printf("  Entries by Node:")
			for nodeID, count := range nodeStats {
				logger.Printf("    - %s: %d entries", nodeID, count)
			}

			if !oldestUpdate.IsZero() {
				logger.Printf("  Oldest Update: %v", oldestUpdate)
				logger.Printf("  Newest Update: %v", newestUpdate)
				logger.Printf("  State Age: %v", time.Since(oldestUpdate))
			}

			// Detailed state output (limited to prevent excessive logging)
			const maxDetailedEntries = 10
			if totalEntries > 0 {
				logger.Printf("Recent State Entries (up to %d):", maxDetailedEntries)

				// Convert to slice for sorting
				type stateEntry struct {
					key   string
					entry *StateEntry
				}
				entries := make([]stateEntry, 0, len(state))
				for k, v := range state {
					entries = append(entries, stateEntry{k, v})
				}

				// Sort by timestamp, newest first
				sort.Slice(entries, func(i, j int) bool {
					return entries[i].entry.Timestamp.After(entries[j].entry.Timestamp)
				})

				// Log most recent entries
				for i, entry := range entries {
					if i >= maxDetailedEntries {
						break
					}
					value, _ := json.Marshal(entry.entry.Value)
					logger.Printf("    %s = %s (v%d from %s at %v)",
						entry.key,
						string(value),
						entry.entry.Version,
						entry.entry.NodeID,
						entry.entry.Timestamp.Format(time.RFC3339))
				}

				if totalEntries > maxDetailedEntries {
					logger.Printf("    ... and %d more entries", totalEntries-maxDetailedEntries)
				}
			}

			// Check cluster health
			healthStatus := "HEALTHY"
			var healthIssues []string

			if aliveCount < len(members) {
				healthStatus = "DEGRADED"
				healthIssues = append(healthIssues,
					fmt.Sprintf("%d of %d nodes not fully healthy",
						len(members)-aliveCount, len(members)))
			}

			// Check for state inconsistencies across nodes
			// Instead of just calculating the hash, we'll use it for comparison
			// localHash := stateManager.VerifyState()
			// for _, member := range members {
			// 	if member.Name == nodeName || member.State != memberlist.StateAlive {
			// 		continue
			// 	}

			// 	// TODO: Make an HTTP request
			// 	// to each member to get their state hash. For now, we'll just
			// 	// log that we're checking consistency.
			// 	logger.Printf("  Checking state consistency with %s (local hash: %s)",
			// 		member.Name, localHash[:8])
			// }

			logger.Printf("Cluster Health: %s", healthStatus)
			if len(healthIssues) > 0 {
				for _, issue := range healthIssues {
					logger.Printf("  - %s", issue)
				}
			}

			time.Sleep(5 * time.Second)
		}
	}()
}

type ConfigServer struct {
	list         *memberlist.Memberlist
	stateManager *StateManager
}

func (s *ConfigServer) SetValue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var update struct {
		Key   string      `json:"key"`
		Value interface{} `json:"value"`
	}

	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request body: %v", err),
			http.StatusBadRequest)
		return
	}

	if update.Key == "" {
		http.Error(w, "Key cannot be empty", http.StatusBadRequest)
		return
	}

	if err := broadcastUpdate(update.Key, update.Value); err != nil {
		log.Printf("Error broadcasting update: %v", err)
		http.Error(w, fmt.Sprintf("Error broadcasting update: %v", err),
			http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status": "update stored and broadcasted",
		"key":    update.Key,
	})
}

func (s *ConfigServer) GetValue(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Check for specific key in query parameters
	key := r.URL.Query().Get("key")

	if key != "" {
		// Return specific key
		if value, exists := s.stateManager.Get(key); exists {
			response := struct {
				Key     string      `json:"key"`
				Value   interface{} `json:"value"`
				Exists  bool        `json:"exists"`
				Version int64       `json:"version"`
			}{
				Key:     key,
				Value:   value,
				Exists:  true,
				Version: s.stateManager.version,
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
			return
		}

		// Key not found
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(struct {
			Key    string `json:"key"`
			Exists bool   `json:"exists"`
			Error  string `json:"error"`
		}{
			Key:    key,
			Exists: false,
			Error:  "key not found",
		})
		return
	}

	// Return all values with metadata
	response := make(map[string]struct {
		Value     interface{} `json:"value"`
		Timestamp time.Time   `json:"timestamp"`
		Version   int64       `json:"version"`
		NodeID    string      `json:"node_id"`
	})

	state := s.stateManager.GetFullState()
	for key, entry := range state {
		response[key] = struct {
			Value     interface{} `json:"value"`
			Timestamp time.Time   `json:"timestamp"`
			Version   int64       `json:"version"`
			NodeID    string      `json:"node_id"`
		}{
			Value:     entry.Value,
			Timestamp: entry.Timestamp,
			Version:   entry.Version,
			NodeID:    entry.NodeID,
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(struct {
		Values  interface{} `json:"values"`
		Version int64       `json:"version"`
		Count   int         `json:"count"`
	}{
		Values:  response,
		Version: s.stateManager.version,
		Count:   len(response),
	})
}

func (s *ConfigServer) GetStateInfo(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	state := s.stateManager.GetFullState()

	// Collect statistics
	nodeStats := make(map[string]int)
	var oldestTimestamp, newestTimestamp time.Time
	var oldestKey, newestKey string

	for key, entry := range state {
		// Count entries per node
		nodeStats[entry.NodeID]++

		// Track oldest and newest entries
		if oldestTimestamp.IsZero() || entry.Timestamp.Before(oldestTimestamp) {
			oldestTimestamp = entry.Timestamp
			oldestKey = key
		}
		if entry.Timestamp.After(newestTimestamp) {
			newestTimestamp = entry.Timestamp
			newestKey = key
		}
	}

	response := struct {
		TotalEntries   int                    `json:"total_entries"`
		CurrentVersion int64                  `json:"current_version"`
		EntriesPerNode map[string]int         `json:"entries_per_node"`
		OldestEntry    map[string]interface{} `json:"oldest_entry,omitempty"`
		NewestEntry    map[string]interface{} `json:"newest_entry,omitempty"`
		ClusterMembers []string               `json:"cluster_members"`
	}{
		TotalEntries:   len(state),
		CurrentVersion: s.stateManager.version,
		EntriesPerNode: nodeStats,
		ClusterMembers: make([]string, 0),
	}

	// Add oldest and newest entries if they exist
	if !oldestTimestamp.IsZero() {
		response.OldestEntry = map[string]interface{}{
			"key":       oldestKey,
			"timestamp": oldestTimestamp,
			"node_id":   state[oldestKey].NodeID,
			"version":   state[oldestKey].Version,
		}
	}

	if !newestTimestamp.IsZero() {
		response.NewestEntry = map[string]interface{}{
			"key":       newestKey,
			"timestamp": newestTimestamp,
			"node_id":   state[newestKey].NodeID,
			"version":   state[newestKey].Version,
		}
	}

	// Add cluster members
	for _, member := range s.list.Members() {
		response.ClusterMembers = append(response.ClusterMembers, member.Name)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *ConfigServer) DownloadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Get the full state
	state := s.stateManager.GetFullState()

	// Create export structure with metadata
	export := struct {
		Metadata struct {
			Version      int64     `json:"version"`
			ExportTime   time.Time `json:"export_time"`
			NodeID       string    `json:"node_id"`
			ClusterNodes []string  `json:"cluster_nodes"`
			EntryCount   int       `json:"entry_count"`
		} `json:"metadata"`
		Entries map[string]struct {
			Value     interface{} `json:"value"`
			Version   int64       `json:"version"`
			NodeID    string      `json:"node_id"`
			Timestamp time.Time   `json:"timestamp"`
		} `json:"entries"`
	}{
		Entries: make(map[string]struct {
			Value     interface{} `json:"value"`
			Version   int64       `json:"version"`
			NodeID    string      `json:"node_id"`
			Timestamp time.Time   `json:"timestamp"`
		}),
	}

	// Fill metadata
	export.Metadata.Version = s.stateManager.version
	export.Metadata.ExportTime = time.Now().UTC()
	export.Metadata.NodeID = s.stateManager.nodeID
	export.Metadata.EntryCount = len(state)

	// Add cluster nodes information
	for _, member := range s.list.Members() {
		export.Metadata.ClusterNodes = append(export.Metadata.ClusterNodes,
			fmt.Sprintf("%s (%s:%d)", member.Name, member.Addr, member.Port))
	}

	// Fill entries
	for key, entry := range state {
		export.Entries[key] = struct {
			Value     interface{} `json:"value"`
			Version   int64       `json:"version"`
			NodeID    string      `json:"node_id"`
			Timestamp time.Time   `json:"timestamp"`
		}{
			Value:     entry.Value,
			Version:   entry.Version,
			NodeID:    entry.NodeID,
			Timestamp: entry.Timestamp,
		}
	}

	// Generate filename with timestamp
	filename := fmt.Sprintf("config_%s_%s.json",
		s.stateManager.nodeID,
		time.Now().UTC().Format("20060102_150405"))

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%s", filename))

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	encoder.SetEscapeHTML(false)

	if err := encoder.Encode(export); err != nil {
		log.Printf("Error encoding JSON for download: %v", err)
		http.Error(w, "Error encoding JSON", http.StatusInternalServerError)
		return
	}

	// Log the export
	log.Printf("[EXPORT] Config exported by %s: %d entries, version %d",
		s.stateManager.nodeID, len(state), s.stateManager.version)
}

// Add a complementary upload handler that can handle the new format
func (s *ConfigServer) UploadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	if r.Header.Get("Content-Type") != "application/json" {
		http.Error(w, "Content-Type must be application/json", http.StatusUnsupportedMediaType)
		return
	}

	var jsonImport struct {
		Metadata struct {
			Version      int64     `json:"version"`
			ExportTime   time.Time `json:"export_time"`
			NodeID       string    `json:"node_id"`
			ClusterNodes []string  `json:"cluster_nodes"`
			EntryCount   int       `json:"entry_count"`
		} `json:"metadata"`
		Entries map[string]struct {
			Value     interface{} `json:"value"`
			Version   int64       `json:"version"`
			NodeID    string      `json:"node_id"`
			Timestamp time.Time   `json:"timestamp"`
		} `json:"entries"`
	}

	if err := json.NewDecoder(r.Body).Decode(&jsonImport); err != nil {
		http.Error(w, fmt.Sprintf("Error decoding JSON: %v", err), http.StatusBadRequest)
		return
	}

	// Validate import
	if len(jsonImport.Entries) != jsonImport.Metadata.EntryCount {
		http.Error(w, "Invalid import: entry count mismatch", http.StatusBadRequest)
		return
	}

	// Process entries
	importedCount := 0
	skippedCount := 0
	for key, entry := range jsonImport.Entries {
		currentEntry, exists := s.stateManager.Get(key)
		if !exists || (exists && entry.Version > currentEntry.(StateEntry).Version) {
			if err := s.stateManager.Set(key, entry.Value); err != nil {
				log.Printf("Error importing key %s: %v", key, err)
				continue
			}
			importedCount++
		} else {
			skippedCount++
		}
	}

	// Prepare response
	response := struct {
		Status         string `json:"status"`
		ImportedCount  int    `json:"imported_count"`
		SkippedCount   int    `json:"skipped_count"`
		TotalEntries   int    `json:"total_entries"`
		ImportVersion  int64  `json:"import_version"`
		CurrentVersion int64  `json:"current_version"`
	}{
		Status:         "import complete",
		ImportedCount:  importedCount,
		SkippedCount:   skippedCount,
		TotalEntries:   len(jsonImport.Entries),
		ImportVersion:  jsonImport.Metadata.Version,
		CurrentVersion: s.stateManager.version,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)

	log.Printf("[IMPORT] Config imported: %d entries imported, %d skipped, version %d",
		importedCount, skippedCount, jsonImport.Metadata.Version)
}

type VolumeUpdate struct {
	Channel int     `json:"channel"`
	Volume  float64 `json:"volume"`
}

func (s *ConfigServer) SetVolume(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var volumeUpdate VolumeUpdate
	if err := json.NewDecoder(r.Body).Decode(&volumeUpdate); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	broadcastVolumeUpdate(volumeUpdate)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "volume updated"})
}

func broadcastUpdate(key string, value interface{}) error {
	stateManager.Lock()
	stateManager.version++
	version := stateManager.version
	stateManager.Unlock()

	update := ConfigUpdate{
		Key:     key,
		Value:   value,
		Version: version,
		NodeID:  nodeName,
		Time:    time.Now().UTC(),
	}

	if err := stateManager.ApplyUpdate(update); err != nil {
		return fmt.Errorf("failed to apply local update: %v", err)
	}

	msg, err := json.Marshal(update)
	if err != nil {
		return fmt.Errorf("failed to marshal update: %v", err)
	}

	// Send to all cluster members
	var broadcastErrors []string
	for _, node := range list.Members() {
		// Skip sending to self
		if node.Name == nodeName {
			continue
		}

		if err := list.SendReliable(node, msg); err != nil {
			broadcastErrors = append(broadcastErrors,
				fmt.Sprintf("failed to send to %s: %v", node.Name, err))
		}
	}

	broadcastToClients(update)

	if len(broadcastErrors) > 0 {
		return fmt.Errorf("broadcast partially failed: %s",
			strings.Join(broadcastErrors, "; "))
	}

	return nil
}

func broadcastToClients(update ConfigUpdate) {
	message, err := json.Marshal(update)
	if err != nil {
		log.Printf("Error marshaling update: %v", err)
		return
	}

	wsClientsMutex.Lock()
	defer wsClientsMutex.Unlock()

	for client := range wsClients {
		err := client.WriteMessage(websocket.TextMessage, message)
		if err != nil {
			log.Printf("Error sending message to WebSocket client: %v", err)
			client.Close()
			delete(wsClients, client)
		}
	}
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection to WebSocket: %v", err)
		return
	}
	defer conn.Close()

	wsClientsMutex.Lock()
	wsClients[conn] = true
	log.Printf("New WebSocket client connected. Total clients: %d", len(wsClients))
	wsClientsMutex.Unlock()

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Printf("WebSocket read error: %v", err)
			break
		}

		processVolumeMessage(message)
	}

	wsClientsMutex.Lock()
	delete(wsClients, conn)
	wsClientsMutex.Unlock()
}

func processVolumeMessage(message []byte) {
	var volumeUpdate VolumeUpdate
	if err := json.Unmarshal(message, &volumeUpdate); err == nil {
		if err := broadcastVolumeUpdate(volumeUpdate); err != nil {
			log.Printf("Error broadcasting volume update: %v", err)
		}
	}
}
func broadcastVolumeUpdate(volumeUpdate VolumeUpdate) error {
	return broadcastUpdate("volume", volumeUpdate)
}

func createMemberlist(nodeName, bindAddr string, bindPort int, joinAddrs []string) (*memberlist.Memberlist, error) {
	config := memberlist.DefaultLocalConfig()
	config.Name = nodeName
	config.BindAddr = bindAddr
	config.BindPort = bindPort

	delegate := &GossipDelegate{
		logger: log.New(os.Stdout, fmt.Sprintf("[GOSSIP-%s] ", nodeName), log.LstdFlags),
		nodeID: nodeName,
	}
	config.Delegate = delegate

	// Increase timeouts and intervals for better reliability in Docker
	config.TCPTimeout = 10 * time.Second           // Time to establish TCP connections
	config.PushPullInterval = 15 * time.Second     // How often to do anti-entropy
	config.ProbeTimeout = 5 * time.Second          // Timeout for probe messages
	config.ProbeInterval = 2 * time.Second         // How often to probe other nodes
	config.GossipInterval = 200 * time.Millisecond // How often to gossip
	config.GossipNodes = 3                         // Number of nodes to gossip to

	// Retry parameters
	config.RetransmitMult = 3 // Retransmit multiplier
	config.SuspicionMult = 6  // Suspicion multiplier

	// Enable detailed logging
	config.Logger = log.New(os.Stdout, fmt.Sprintf("[MEMBERLIST-%s] ", nodeName), log.LstdFlags)

	list, err := memberlist.Create(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create memberlist: %v", err)
	}

	// Join the cluster with retries if we have addresses
	if len(joinAddrs) > 0 {
		log.Printf("[DEBUG-%s] Attempting to join cluster at: %v", nodeName, joinAddrs)

		// Retry join up to 5 times
		var n int
		for retries := 0; retries < 5; retries++ {
			n, err = list.Join(joinAddrs)
			if err == nil {
				log.Printf("[DEBUG-%s] Successfully joined cluster with %d nodes", nodeName, n)
				break
			}
			log.Printf("[DEBUG-%s] Join attempt %d failed: %v", nodeName, retries+1, err)
			time.Sleep(2 * time.Second)
		}
		if err != nil {
			return nil, fmt.Errorf("failed to join cluster after retries: %v", err)
		}
	}

	return list, nil
}

// Add this health check function to monitor cluster state
func startHealthCheck(list *memberlist.Memberlist, nodeName string) {
	go func() {
		for {
			members := list.Members()
			numMembers := len(members)
			numAlive := 0

			for _, member := range members {
				if member.State != memberlist.StateAlive {
					log.Printf("[HEALTH-%s] Node %s is not alive: state=%d",
						nodeName, member.Name, member.State)
				} else {
					numAlive++
				}
			}

			log.Printf("[HEALTH-%s] Cluster health: %d/%d nodes alive",
				nodeName, numAlive, numMembers)

			time.Sleep(10 * time.Second)
		}
	}()
}

// LogFilter is a custom io.Writer that filters log messages based on level
type LogFilter struct {
	minLevel int
}

func (f *LogFilter) Write(p []byte) (n int, err error) {
	// The first byte represents the log level in memberlist
	// 0 - Debug
	// 1 - Info
	// 2 - Warning
	// 3 - Error
	if len(p) > 0 && int(p[0]) >= f.minLevel {
		return os.Stderr.Write(p)
	}
	return len(p), nil
}

// func startStateVerification(list *memberlist.Memberlist) {
// 	go func() {
// 		for {
// 			localHash := stateManager.VerifyState()
// 			members := list.Members()

// 			// Compare state with other nodes
// 			for _, member := range members {
// 				if member.Name == nodeName {
// 					continue
// 				}

// 				// TODO: Mke an HTTP request to each member
// 				// to get their state hash and compare
// 				// For now, we'll just log our hash
// 				log.Printf("[VERIFY] Local state hash: %s", localHash)
// 			}

// 			time.Sleep(30 * time.Second)
// 		}
// 	}()
// }

func checkConnectivity() error {
	// Test direct backend connections
	for _, addr := range []string{"172.18.0.3:8080", "172.18.0.4:8080"} {
		log.Printf("Testing connection to %s...", addr)
		conn, err := net.DialTimeout("tcp", addr, 2*time.Second)
		if err != nil {
			log.Printf("Failed to connect to %s: %v", addr, err)
		} else {
			log.Printf("Successfully connected to %s", addr)
			conn.Close()
		}

		// Try HTTP request
		resp, err := http.Get(fmt.Sprintf("http://%s/getValue", addr))
		if err != nil {
			log.Printf("HTTP request to %s failed: %v", addr, err)
		} else {
			log.Printf("HTTP request to %s succeeded with status: %d", addr, resp.StatusCode)
			resp.Body.Close()
		}
	}

	// Test VIP connection
	log.Printf("Testing connection to VIP (172.18.0.2:80)...")
	conn, err := net.DialTimeout("tcp", "172.18.0.2:80", 2*time.Second)
	if err != nil {
		log.Printf("Failed to connect to VIP: %v", err)
	} else {
		log.Printf("Successfully connected to VIP")
		conn.Close()
	}

	// Check routing
	cmd := exec.Command("ip", "route", "get", "172.18.0.2")
	output, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("Failed to check routing: %v", err)
	} else {
		log.Printf("Route to VIP: %s", string(output))
	}

	return nil
}

func main() {
	var joinAddr string
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.StringVar(&joinAddr, "join", "", "Address to join cluster (comma-separated)")
	flag.Parse()

	if nodeName == "" {
		log.Fatal("Node name is required")
	}

	stateManager = NewStateManager(nodeName)
	//stateManager.StartStateDumping(30 * time.Second)

	// Split join addresses
	var joinAddrs []string
	if joinAddr != "" {
		joinAddrs = strings.Split(joinAddr, ",")
	}

	var err error
	list, err = createMemberlist(nodeName, bindAddr, bindPort, joinAddrs)
	if err != nil {
		log.Fatalf("Failed to create memberlist: %v", err)
	}

	monitorClusterState(list, nodeName)
	startHealthCheck(list, nodeName)
	//startStateVerification(list)

	// Initialize ConfigServer with StateManager
	configServer := &ConfigServer{
		list:         list,
		stateManager: stateManager,
	}

	// Subscribe to state changes for persistence
	stateChan := stateManager.Subscribe()
	go func() {
		for range stateChan {
			if persistence != nil {
				persistence.MarkDirty()
			}
		}
	}()

	// Initialize persistence
	persistence = NewConfigPersistence("/var/lib/fusion/config.json", stateManager)
	if err := persistence.LoadState(); err != nil {
		log.Printf("Error loading state: %v", err)
	}
	persistence.Start()
	defer persistence.Stop()

	// Set up routes
	http.HandleFunc("/setValue", configServer.SetValue)
	http.HandleFunc("/getValue", configServer.GetValue)
	http.HandleFunc("/setVolume", configServer.SetVolume)
	http.HandleFunc("/upload", configServer.UploadJSON)
	http.HandleFunc("/download", configServer.DownloadJSON)
	http.HandleFunc("/ws", handleWebSocket)

	addr := ":8080"
	log.Printf("Starting server on %s", addr)
	go func() {
		http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path != "/" {
				http.NotFound(w, r)
				return
			}
			fmt.Fprintf(w, "Fusion Server is running. Available endpoints: /setValue, /getValue, /setVolume, /upload, /download, /ws")
		})

		if err := http.ListenAndServe(addr, nil); err != nil {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	go func() {
		for {
			if err := checkConnectivity(); err != nil {
				log.Printf("Connectivity check failed: %v", err)
			}
			time.Sleep(10 * time.Second)
		}
	}()

	for {
		members := list.Members()
		log.Printf("Current cluster members:")
		for _, member := range members {
			log.Printf("  %s: %s:%d", member.Name, member.Addr, member.Port)
		}

		// Update HAProxy configuration when membership changes
		if err := generateHAProxyConfig(members); err != nil {
			log.Printf("Failed to update HAProxy config: %v", err)
		} else if err := reloadHAProxy(); err != nil {
			log.Printf("Failed to reload HAProxy: %v", err)
		}

		time.Sleep(10 * time.Second)
	}

}
