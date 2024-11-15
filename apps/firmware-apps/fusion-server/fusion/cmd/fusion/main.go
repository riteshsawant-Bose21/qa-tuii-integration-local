package main

import (
	"flag"
	"fmt"
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

const (
	stateInterval = 30
)

func main() {
	// Parse command line flags
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.StringVar(&joinAddr, "join", "", "Address to join cluster (comma-separated)")
	metricsPort := flag.Int("metrics-port", 9090, "Metrics server port")
	flag.Parse()

	if nodeName == "" {
		log.Fatal("Node name is required")
	}

	// Initialize logging
	debugLogger := logging.NewDebugLogger(nodeName)
	log.Printf("Starting fusion server node: %s", nodeName)

	// Initialize state manager
	stateManager := config.NewStateManager(nodeName)
	stateManager.StartStateDumping(stateInterval * time.Second)

	// Split join addresses
	var joinAddrs []string
	if joinAddr != "" {
		joinAddrs = strings.Split(joinAddr, ",")
	}

	// Create memberlist
	list, err := cluster.CreateMemberlist(nodeName, bindAddr, bindPort, joinAddrs, stateManager)
	if err != nil {
		log.Fatalf("Failed to create memberlist: %v", err)
	}

	// Start cluster monitoring
	cluster.MonitorClusterState(list)
	cluster.StartHealthCheck(list)
	cluster.StartStateVerification(list, stateManager)

	// Initialize metrics collector
	metricsCollector := cluster.NewMetricsCollector(list, stateManager)

	// Initialize UDP server
	udpServer, err := network.NewUDPServer(":7947", stateManager)
	if err != nil {
		debugLogger.Printf("Failed to create UDP server: %v", err)
	} else {
		udpServer.Start()
		defer udpServer.Stop()
	}

	// Initialize persistence
	persistence := config.NewConfigPersistence("/var/lib/fusion/config.json", stateManager)
	if err := persistence.LoadState(); err != nil {
		log.Printf("Error loading state: %v", err)
	}

	// Initialize config server
	configServer := config.NewConfigServer(list, stateManager, persistence, udpServer)

	// Start metrics server on separate port
	go func() {
		metricsServer := &http.Server{
			Addr:    fmt.Sprintf(":%d", *metricsPort),
			Handler: setupMetricsRoutes(metricsCollector),
		}
		log.Printf("Starting metrics server on :%d", *metricsPort)
		if err := metricsServer.ListenAndServe(); err != nil {
			log.Printf("Metrics server error: %v", err)
		}
	}()

	// Set up HTTP routes
	setupHTTPRoutes(configServer, metricsCollector)

	// Start HAProxy management
	go network.ManageHAProxy(list)

	// Start the main server
	log.Printf("Starting API server on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}

func setupHTTPRoutes(server *config.ConfigServer, metrics *cluster.MetricsCollector) {
	http.HandleFunc("/setValue", withLogging(server.SetValue, "setValue"))
	http.HandleFunc("/getValue", withLogging(server.GetValue, "getValue"))
	http.HandleFunc("/clear", withLogging(server.ClearAllData, "clear"))
	http.HandleFunc("/upload", withLogging(server.UploadJSON, "upload"))
	http.HandleFunc("/download", withLogging(server.DownloadJSON, "download"))
	http.HandleFunc("/ws", withWebSocketMetrics(server.HandleWebSocket, metrics))
	http.HandleFunc("/", withLogging(server.HandleRoot, "root"))
}

func setupMetricsRoutes(metrics *cluster.MetricsCollector) *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/metrics", metrics.HandleMetrics)
	mux.HandleFunc("/cluster/status", metrics.HandleClusterStatus)
	mux.HandleFunc("/health", metrics.HandleHealthCheck)
	return mux
}

// Middleware to log HTTP requests
func withLogging(handler http.HandlerFunc, endpoint string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		handler(w, r)
		duration := time.Since(start)
		log.Printf("[HTTP] %s %s %s Duration: %v", r.Method, r.URL.Path, endpoint, duration)
	}
}

// Special middleware for WebSocket connections
func withWebSocketMetrics(handler http.HandlerFunc, metrics *cluster.MetricsCollector) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		metrics.UpdateWSCount(1)
		handler(w, r)
		metrics.UpdateWSCount(-1)
	}
}
