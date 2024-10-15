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

	"github.com/go-zeromq/zmq4"
	"github.com/hashicorp/memberlist"
)

var (
	config        sync.Map
	configMutex   sync.Mutex
	configVersion int64
	nodeName      string
	bindAddr      string
	bindPort      int
	zmqPubSocket  zmq4.Socket
)

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

func broadcastUpdate(list *memberlist.Memberlist, key string, value interface{}) {
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
		list.SendReliable(node, msg)
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

	broadcastUpdate(s.list, update.Key, update.Value)

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
		broadcastUpdate(s.list, key, value)
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

func broadcastToClients(update ConfigUpdate) {
	message, err := json.Marshal(update)
	if err != nil {
		log.Printf("Error marshaling update: %v", err)
		return
	}

	msg := zmq4.NewMsgFrom([]byte("fusion-server"), message)
	err = zmqPubSocket.Send(msg)
	if err != nil {
		log.Printf("Error sending message: %v", err)
		return
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

func testZeroMQPublisher(ctx context.Context, socket zmq4.Socket) {

	// 60Hz
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

			update := ConfigUpdate{
				Version:   time.Now().UnixNano(),
				Key:       "volume",
				Value:     value,
				Broadcast: false,
			}

			message, err := json.Marshal(update)
			if err != nil {
				log.Printf("Error marshaling update: %v", err)
				continue
			}

			msg := zmq4.NewMsgFrom([]byte("fusion-server"), message)
			err = socket.Send(msg)
			if err != nil {
				log.Printf("Error sending message: %v", err)
			}
		}
	}
}

func main() {
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.Parse()

	if nodeName == "" {
		log.Fatal("Node name is required")
	}

	config := memberlist.DefaultLocalConfig()
	config.Name = nodeName
	config.BindAddr = bindAddr
	config.BindPort = bindPort
	config.Delegate = &gossipDelegate{}

	list, err := memberlist.Create(config)
	if err != nil {
		log.Fatalf("Failed to create memberlist: %v", err)
	}

	if members := flag.Args(); len(members) > 0 {
		_, err := list.Join(members)
		if err != nil {
			log.Fatalf("Failed to join cluster: %v", err)
		}
	}

	log.Printf("Node %s listening on %s:%d", nodeName, bindAddr, bindPort)

	// Initialize ZeroMQ PUB socket
	zmqPubSocket = zmq4.NewPub(context.Background())
	zmqBindAddr := fmt.Sprintf("tcp://%s:5555", bindAddr)
	if err := zmqPubSocket.Listen(zmqBindAddr); err != nil {
		log.Fatalf("Failed to bind ZeroMQ PUB socket: %v", err)
	}
	log.Printf("ZeroMQ PUB socket bound to %s", zmqBindAddr)

	// Start the ZeroMQ test publisher
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go testZeroMQPublisher(ctx, zmqPubSocket)

	// Initialize HAProxy
	if err := generateHAProxyConfig(list.Members()); err != nil {
		log.Fatalf("Failed to generate HAProxy config: %v", err)
	}
	if err := reloadHAProxy(); err != nil {
		log.Fatalf("Failed to reload HAProxy: %v", err)
	}

	configServer := &ConfigServer{
		list: list,
	}

	http.HandleFunc("/setValue", configServer.SetValue)
	http.HandleFunc("/getValue", configServer.GetValue)
	http.HandleFunc("/upload", configServer.UploadJSON)
	http.HandleFunc("/download", configServer.DownloadJSON)

	addr := ":8080"
	log.Printf("Starting server on %s", addr)
	go func() {
		http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path != "/" {
				http.NotFound(w, r)
				return
			}
			fmt.Fprintf(w, "Fusion Server is running. Available endpoints: /setValue, /getValue, /upload, /download")
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
