package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/hashicorp/memberlist"
)

var (
	config         sync.Map
	configMutex    sync.Mutex
	configVersion  int64
	nodeName       string
	bindAddr       string
	bindPort       int
	wsClients      = make(map[*websocket.Conn]bool)
	wsClientsMutex sync.Mutex
	list           *memberlist.Memberlist // Make list a global variable
	persistence    *ConfigPersistence
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all connections
	},
}

type GossipDelegate struct {
	logger *log.Logger
}

func (d *GossipDelegate) NodeMeta(limit int) []byte {
	//d.logger.Printf("NodeMeta called with limit: %d", limit)
	return []byte{}
}

type ConfigUpdate struct {
	Version   int64       `json:"version"`
	Key       string      `json:"key"`
	Value     interface{} `json:"value"`
	Broadcast bool        `json:"broadcast"`
}

func (d *GossipDelegate) NotifyMsg(msg []byte) {
	var update ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		d.logger.Printf("Error unmarshaling update: %v", err)
		return
	}

	// d.logger.Printf("Received gossip message: version=%d, key=%s",
	// 	update.Version, update.Key)

	applyUpdate(update)
}

func (d *GossipDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	//d.logger.Printf("GetBroadcasts called: overhead=%d, limit=%d", overhead, limit)
	return nil
}

func (d *GossipDelegate) LocalState(join bool) []byte {
	configMutex.Lock()
	defer configMutex.Unlock()

	state := make(map[string]interface{})
	config.Range(func(key, value interface{}) bool {
		state[key.(string)] = value
		return true
	})

	data, err := json.Marshal(map[string]interface{}{
		"Version": configVersion,
		"Config":  state,
	})
	if err != nil {
		d.logger.Printf("Error marshaling local state: %v", err)
		return nil
	}

	d.logger.Printf("LocalState called (join=%v): sending version %d with %d keys",
		join, configVersion, len(state))
	return data
}

func (d *GossipDelegate) MergeRemoteState(buf []byte, join bool) {
	d.logger.Printf("MergeRemoteState called with join=%v, data size=%d bytes",
		join, len(buf))

	var remoteState struct {
		Version int64
		Config  map[string]interface{}
	}
	if err := json.Unmarshal(buf, &remoteState); err != nil {
		d.logger.Printf("Error unmarshaling remote state: %v", err)
		d.logger.Printf("Raw data: %s", string(buf))
		return
	}

	// d.logger.Printf("Processing remote state: version=%d, keys=%d",
	// 	remoteState.Version, len(remoteState.Config))

	configMutex.Lock()
	defer configMutex.Unlock()

	if remoteState.Version > configVersion {
		//oldVersion := configVersion
		oldState := make(map[string]interface{})
		config.Range(func(key, value interface{}) bool {
			oldState[key.(string)] = value
			return true
		})

		configVersion = remoteState.Version
		for k, v := range remoteState.Config {
			config.Store(k, v)
		}

		// d.logger.Printf("State merged: version %d -> %d", oldVersion, configVersion)
		// d.logger.Printf("Old state: %+v", oldState)
		// d.logger.Printf("New state: %+v", remoteState.Config)
	} else {
		// d.logger.Printf("Skipping merge: remote version %d not newer than local %d",
		// 	remoteState.Version, configVersion)
	}
}

func monitorClusterState(list *memberlist.Memberlist, nodeName string) {
	go func() {
		for {
			members := list.Members()
			log.Printf("[CLUSTER-%s] Current members (%d):", nodeName, len(members))
			for _, member := range members {
				log.Printf("[CLUSTER-%s]   - %s at %s:%d",
					nodeName, member.Name, member.Addr, member.Port)
			}

			// Log current config state
			configMap := make(map[string]interface{})
			config.Range(func(key, value interface{}) bool {
				configMap[key.(string)] = value
				return true
			})
			state, _ := json.MarshalIndent(configMap, "", "  ")
			log.Printf("[STATE-%s] Current config (version %d):\n%s",
				nodeName, configVersion, string(state))

			time.Sleep(5 * time.Second)
		}
	}()
}

func applyUpdate(update ConfigUpdate) {
	configMutex.Lock()
	defer configMutex.Unlock()

	if update.Version > configVersion {
		config.Store(update.Key, update.Value)
		configVersion = update.Version
		log.Printf("Applied update: %s = %v (version %d)", update.Key, update.Value, update.Version)

		// Mark state as dirty for persistence
		if persistence != nil {
			persistence.MarkDirty()
		}
	}
}

type ConfigServer struct {
	list *memberlist.Memberlist
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
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Store value directly in the config map before broadcasting
	config.Store(update.Key, update.Value)

	// Then broadcast the update
	broadcastUpdate(update.Key, update.Value)

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

	configMap := make(map[string]interface{})
	config.Range(func(key, value interface{}) bool {
		configMap[key.(string)] = value
		return true
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(configMap)
}

func (s *ConfigServer) UploadJSON(w http.ResponseWriter, r *http.Request) {
	if r.Header.Get("Content-Type") != "application/json" {
		http.Error(w, "Content-Type must be application/json", http.StatusUnsupportedMediaType)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()

	var jsonConfig map[string]interface{}
	err = json.Unmarshal(body, &jsonConfig)
	if err != nil {
		http.Error(w, "Error parsing JSON", http.StatusBadRequest)
		return
	}

	for key, value := range jsonConfig {
		broadcastUpdate(key, value)
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "JSON data uploaded and broadcasted"})
}

func (s *ConfigServer) DownloadJSON(w http.ResponseWriter, r *http.Request) {
	configMap := make(map[string]interface{})
	config.Range(func(key, value interface{}) bool {
		configMap[key.(string)] = value
		return true
	})

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Disposition", "attachment; filename=config.json")

	encoder := json.NewEncoder(w)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(configMap); err != nil {
		http.Error(w, "Error encoding JSON", http.StatusInternalServerError)
		return
	}
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

func broadcastUpdate(key string, value interface{}) {
	configMutex.Lock()
	configVersion++
	update := ConfigUpdate{
		Version:   configVersion,
		Key:       key,
		Value:     value,
		Broadcast: true,
	}
	configMutex.Unlock()

	// Marshal update to JSON
	msg, err := json.Marshal(update)
	if err != nil {
		log.Printf("Error marshaling update: %v", err)
		return
	}

	// Send to all members
	for _, node := range list.Members() {
		if err := list.SendReliable(node, msg); err != nil {
			log.Printf("Error sending to node %s: %v", node.Name, err)
		}
	}

	// Apply update locally
	applyUpdate(update)

	// Broadcast to WebSocket clients
	broadcastToClients(update)
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
		broadcastVolumeUpdate(volumeUpdate)
	}
}

func broadcastVolumeUpdate(volumeUpdate VolumeUpdate) {
	broadcastUpdate("volume", volumeUpdate)
}

func createMemberlist(nodeName, bindAddr string, bindPort int, joinAddrs []string) (*memberlist.Memberlist, error) {
	config := memberlist.DefaultLocalConfig()
	config.Name = nodeName
	config.BindAddr = bindAddr
	config.BindPort = bindPort

	delegate := &GossipDelegate{
		logger: log.New(os.Stdout, fmt.Sprintf("[GOSSIP-%s] ", nodeName), log.LstdFlags),
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

	log.Printf("Node %s listening on %s:%d", nodeName, bindAddr, bindPort)

	if err := generateHAProxyConfig(list.Members()); err != nil {
		log.Fatalf("Failed to generate HAProxy config: %v", err)
	}

	if err := reloadHAProxy(); err != nil {
		log.Fatalf("Failed to reload HAProxy: %v", err)
	}

	configServer := &ConfigServer{
		list: list,
	}

	// Initialize persistence
	persistence = NewConfigPersistence("/var/lib/fusion/config.json")
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
