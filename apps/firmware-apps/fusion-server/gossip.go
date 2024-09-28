package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/hashicorp/memberlist"
)

var (
	config        sync.Map
	configMutex   sync.Mutex
	configVersion int64
	nodeName      string
	bindAddr      string
	bindPort      int
)

type ConfigUpdate struct {
	Version int64
	Key     string
	Value   interface{}
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
		Version: configVersion,
		Key:     key,
		Value:   value,
	}
	configMutex.Unlock()

	msg, _ := json.Marshal(update)
	for _, node := range list.Members() {
		list.SendReliable(node, msg)
	}
	applyUpdate(update)
}

type ConfigServer struct {
	list *memberlist.Memberlist
}

func (s *ConfigServer) UpdateKey(w http.ResponseWriter, r *http.Request) {
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
	// Check if the Content-Type is application/json
	if r.Header.Get("Content-Type") != "application/json" {
		http.Error(w, "Content-Type must be application/json", http.StatusUnsupportedMediaType)
		return
	}

	// Read the request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusInternalServerError)
		return
	}
	defer r.Body.Close()

	// Parse the JSON
	var jsonConfig map[string]interface{}
	err = json.Unmarshal(body, &jsonConfig)
	if err != nil {
		http.Error(w, "Error parsing JSON", http.StatusBadRequest)
		return
	}

	// Broadcast each key-value pair
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
	encoder.SetIndent("", "  ") // Pretty print the JSON
	if err := encoder.Encode(configMap); err != nil {
		http.Error(w, "Error encoding JSON", http.StatusInternalServerError)
		return
	}
}

func main() {
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.Parse()

	fmt.Printf("Arguments received: %v\n", os.Args)

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

	configServer := &ConfigServer{
		list: list,
	}

	http.HandleFunc("/updateKey", configServer.UpdateKey)
	http.HandleFunc("/getValue", configServer.GetValue)
	http.HandleFunc("/upload", configServer.UploadJSON)
	http.HandleFunc("/download", configServer.DownloadJSON)

	log.Println("Registered routes:")
	log.Println(" - /update")
	log.Println(" - /config")
	log.Println(" - /upload")
	log.Println(" - /download")

	addr := ":8080"
	log.Printf("Starting server on %s", addr)
	go func() {
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

		time.Sleep(10 * time.Second)
		broadcastUpdate(list, "example_key", time.Now().String())
	}
}
