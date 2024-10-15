package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"math"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync"
	"text/template"
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
	volumeValue    float64
	volumeMutex    sync.RWMutex
	list           *memberlist.Memberlist // Make list a global variable
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all connections
	},
}

type ConfigUpdate struct {
	Version   int64       `json:"version"`
	Key       string      `json:"key"`
	Value     interface{} `json:"value"`
	Broadcast bool        `json:"broadcast"`
}

type gossipDelegate struct{}

func (d *gossipDelegate) NodeMeta(limit int) []byte {
	return []byte{}
}

func (d *gossipDelegate) NotifyMsg(msg []byte) {
	var update ConfigUpdate
	if err := json.Unmarshal(msg, &update); err != nil {
		log.Printf("Error unmarshaling update: %v", err)
		return
	}

	applyUpdate(update)

	if update.Broadcast {
		broadcastToClients(update)
	}
}

func (d *gossipDelegate) GetBroadcasts(overhead, limit int) [][]byte {
	return nil
}

func (d *gossipDelegate) LocalState(join bool) []byte {
	configMutex.Lock()
	defer configMutex.Unlock()

	state := make(map[string]interface{})
	config.Range(func(key, value interface{}) bool {
		state[key.(string)] = value
		return true
	})

	data, _ := json.Marshal(map[string]interface{}{
		"Version": configVersion,
		"Config":  state,
	})
	return data
}

func (d *gossipDelegate) MergeRemoteState(buf []byte, join bool) {
	var remoteState struct {
		Version int64
		Config  map[string]interface{}
	}
	if err := json.Unmarshal(buf, &remoteState); err != nil {
		log.Printf("Error unmarshaling remote state: %v", err)
		return
	}

	configMutex.Lock()
	defer configMutex.Unlock()

	if remoteState.Version > configVersion {
		configVersion = remoteState.Version
		for k, v := range remoteState.Config {
			config.Store(k, v)
		}
		log.Printf("Merged remote state, new version: %d", configVersion)
	}
}

func applyUpdate(update ConfigUpdate) {
	configMutex.Lock()
	defer configMutex.Unlock()

	if update.Version > configVersion {
		config.Store(update.Key, update.Value)
		configVersion = update.Version
		log.Printf("Applied update: %s = %v (version %d)", update.Key, update.Value, update.Version)
	}
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

	msg, _ := json.Marshal(update)
	for _, node := range list.Members() {
		err := list.SendReliable(node, msg)
		if err != nil {
			log.Printf("Error sending to node %s: %v", node.Name, err)
		}
	}

	applyUpdate(update)
	broadcastToClients(update)
}

type ConfigServer struct {
	list *memberlist.Memberlist
}

func (s *ConfigServer) SetValue(w http.ResponseWriter, r *http.Request) {
	var update struct {
		Key   string      `json:"key"`
		Value interface{} `json:"value"`
	}
	if err := json.NewDecoder(r.Body).Decode(&update); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	broadcastUpdate(update.Key, update.Value)

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "update broadcasted"})
}

func (s *ConfigServer) GetValue(w http.ResponseWriter, r *http.Request) {
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

func (s *ConfigServer) SetVolume(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var volumeUpdate struct {
		Volume float64 `json:"volume"`
	}
	if err := json.NewDecoder(r.Body).Decode(&volumeUpdate); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	setVolumeValue(volumeUpdate.Volume)
	broadcastVolumeUpdate()

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "volume updated"})
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

type HAProxyConfig struct {
	Backends []string
}

func generateHAProxyConfig(members []*memberlist.Node) error {
	config := HAProxyConfig{
		Backends: make([]string, len(members)),
	}
	for i, member := range members {
		config.Backends[i] = fmt.Sprintf("%s:%d", member.Addr, 8080)
	}

	tmpl := template.Must(template.New("haproxy").Parse(`
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    pidfile /var/run/haproxy.pid

defaults
    log global
    mode http
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend http-in
    bind *:80
    default_backend servers

backend servers
    balance roundrobin
    {{range .Backends}}
    server {{.}} {{.}} check
    {{end}}

listen stats
    bind *:8404
    stats enable
    stats uri /
    stats refresh 5s

# Make sure there's a newline at the end of the file

`))

	f, err := os.Create("/etc/haproxy/haproxy.cfg")
	if err != nil {
		return err
	}
	defer f.Close()

	return tmpl.Execute(f, config)
}

func reloadHAProxy() error {
	pidFile := "/var/run/haproxy.pid"

	if _, err := os.Stat(pidFile); os.IsNotExist(err) {
		// If PID file doesn't exist, start HAProxy
		cmd := exec.Command("haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-W")
		return cmd.Start()
	}

	pidBytes, err := os.ReadFile(pidFile)
	if err != nil {
		return fmt.Errorf("failed to read HAProxy PID: %v", err)
	}
	pid := strings.TrimSpace(string(pidBytes))

	cmd := exec.Command("haproxy", "-f", "/etc/haproxy/haproxy.cfg", "-sf", pid)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to reload HAProxy: %v, output: %s", err, output)
	}
	return nil
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

		// Process incoming volume messages
		var volumeUpdate struct {
			Volume float64 `json:"volume"`
		}

		if err := json.Unmarshal(message, &volumeUpdate); err == nil {
			setVolumeValue(volumeUpdate.Volume)
			broadcastVolumeUpdate()
		}
	}

	wsClientsMutex.Lock()
	delete(wsClients, conn)
	wsClientsMutex.Unlock()
}

func setVolumeValue(value float64) {
	volumeMutex.Lock()
	defer volumeMutex.Unlock()
	volumeValue = value
}

func getVolumeValue() float64 {
	volumeMutex.RLock()
	defer volumeMutex.RUnlock()
	return volumeValue
}

// Updated broadcastVolumeUpdate function
func broadcastVolumeUpdate() {
	value := getVolumeValue()
	broadcastUpdate("volume", value)
}

// Updated testVolumePublisher function
func testVolumePublisher(ctx context.Context) {
	const rate = 60

	ticker := time.NewTicker(time.Second / rate)
	defer ticker.Stop()

	// Variables for sine wave generation
	var phase float64
	const frequency = 0.5 // Adjust this to change the frequency of the sine wave

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			// Generate a sine wave value between 0 and 1
			value := (math.Sin(phase) + 1) / 2 // This transforms the sine wave to range 0-1
			phase += frequency * 2 * math.Pi / rate
			if phase > 2*math.Pi {
				phase -= 2 * math.Pi // Keep phase within 0-2π
			}

			broadcastUpdate("volume", value)
		}
	}
}

func createMemberlist(nodeName, bindAddr string, bindPort int) (*memberlist.Memberlist, error) {
	config := memberlist.DefaultLocalConfig()
	config.Name = nodeName
	config.BindAddr = bindAddr
	config.BindPort = bindPort
	config.Delegate = &gossipDelegate{}
	config.Logger = log.New(&logFilter{minLevel: 3}, "", log.LstdFlags)

	return memberlist.Create(config)
}

// logFilter is a custom io.Writer that filters log messages based on level
type logFilter struct {
	minLevel int
}

func (f *logFilter) Write(p []byte) (n int, err error) {
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

	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.Parse()

	if nodeName == "" {
		log.Fatal("Node name is required")
	}

	var err error
	list, err = createMemberlist(nodeName, bindAddr, bindPort)
	if err != nil {
		log.Fatalf("Failed to create memberlist: %v", err)
	}

	log.Printf("Node %s listening on %s:%d", nodeName, bindAddr, bindPort)

	// Initialize HAProxy
	if err := generateHAProxyConfig(list.Members()); err != nil {
		log.Fatalf("Failed to generate HAProxy config: %v", err)
	}
	if err := reloadHAProxy(); err != nil {
		log.Fatalf("Failed to reload HAProxy: %v", err)
	}

	// // Start the WebSocket test publisher
	// ctx, cancel := context.WithCancel(context.Background())
	// defer cancel()
	// go testVolumePublisher(ctx)

	configServer := &ConfigServer{
		list: list,
	}

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
