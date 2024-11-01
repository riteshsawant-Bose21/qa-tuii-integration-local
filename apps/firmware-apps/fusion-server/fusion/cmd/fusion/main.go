package main

import (
	"flag"
	"log"
	"net/http"
	"strings"
	"time"

	"fusion/internal/cluster"
	"fusion/internal/config"
	"fusion/internal/logging"
	"fusion/internal/network"
)

var (
	nodeName string
	bindAddr string
	bindPort int
	joinAddr string
)

func main() {
	// Parse command line flags
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.StringVar(&joinAddr, "join", "", "Address to join cluster (comma-separated)")
	flag.Parse()

	if nodeName == "" {
		log.Fatal("Node name is required")
	}

	// Initialize logging
	debugLogger := logging.NewDebugLogger(nodeName)
	log.Printf("Starting fusion server node: %s", nodeName)

	// Initialize state manager
	stateManager := config.NewStateManager(nodeName)
	stateManager.StartStateDumping(30 * time.Second)

	// Split join addresses
	var joinAddrs []string
	if joinAddr != "" {
		joinAddrs = strings.Split(joinAddr, ",")
	}

	// Create memberlist
	list, err := cluster.CreateMemberlist(nodeName, bindAddr, bindPort, joinAddrs)
	if err != nil {
		log.Fatalf("Failed to create memberlist: %v", err)
	}

	// Start cluster monitoring
	cluster.MonitorClusterState(list)
	cluster.StartHealthCheck(list)
	cluster.StartStateVerification(list, stateManager)

	// Initialize config server
	configServer := config.NewConfigServer(list, stateManager)

	// Initialize persistence
	persistence := config.NewConfigPersistence("/var/lib/fusion/config.json", stateManager)
	if err := persistence.LoadState(); err != nil {
		log.Printf("Error loading state: %v", err)
	}
	persistence.Start()
	defer persistence.Stop()

	// Initialize UDP server
	udpServer, err := network.NewUDPServer(":7947", stateManager)
	if err != nil {
		debugLogger.Printf("Failed to create UDP server: %v", err)
	} else {
		udpServer.Start()
		defer udpServer.Stop()
	}

	// Set up HTTP routes
	setupHTTPRoutes(configServer)

	// Start HAProxy management
	go network.ManageHAProxy(list)

	// Start the server
	log.Printf("Starting server on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func setupHTTPRoutes(server *config.ConfigServer) {
	http.HandleFunc("/setValue", server.SetValue)
	http.HandleFunc("/getValue", server.GetValue)
	http.HandleFunc("/upload", server.UploadJSON)
	http.HandleFunc("/download", server.DownloadJSON)
	http.HandleFunc("/ws", server.HandleWebSocket)
	http.HandleFunc("/", server.HandleRoot)
}
