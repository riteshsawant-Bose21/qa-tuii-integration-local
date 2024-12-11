package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"fusion/internal/cluster"
	"fusion/internal/controllers/cxa"
	"fusion/internal/controllers/cxd"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/server"
	"fusion/internal/timers"
)

var (
	nodeName string
	bindAddr string
	bindPort int
	joinAddr string
)

const (
	configDataPath        = "/var/lib/fusion/config.json"
	stateDumpInterval     = 30
	analogControllerPort  = ":8002"
	digitalControllerPort = ":8003"
	httpPort              = ":8080"
	udpPort               = ":7947"
)

func main() {
	// Parse command line flags
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.StringVar(&joinAddr, "join", "", "Address to join cluster (comma-separated)")
	metricsPort := flag.Int("metrics-port", 9090, "Metrics server port")
	verbose := flag.Bool("verbose", false, "Verbose output")
	flag.Parse()

	if nodeName == "" {
		log.Fatal("Node name is required")
		return
	}

	// Initialize logging
	logging.InitLogger(logging.LogConfig{
		NodeName:    nodeName,
		LogDir:      "/var/log/fusion",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})

	logger := logging.GetLogger()
	logger.Info("Starting fusion server node: %s", nodeName)
	defer logger.Close()

	// Initialize state manager
	stateManager := server.NewStateManager(nodeName)
	if *verbose {
		stateManager.StartStateDumping(stateDumpInterval * time.Second)
	}

	// Initialize persistence
	persistence := server.NewConfigPersistence(
		configDataPath,
		stateManager,
		true,
	)
	// Split join addresses
	var joinAddrs []string
	if joinAddr != "" {
		joinAddrs = strings.Split(joinAddr, ",")
	}

	// Create memberlist
	list, err := cluster.CreateMemberlist(nodeName, bindAddr, bindPort, joinAddrs, stateManager, persistence, *verbose)
	if err != nil {
		logger.Error("Failed to create memberlist: %v", err)
		return
	}

	// Start cluster monitoring
	if *verbose {
		cluster.MonitorClusterState(list)
		cluster.StartHealthCheck(list)
		cluster.StartStateVerification(list, stateManager)
	}

	// Timer management
	timerManager := timers.NewTimerManager("tasks.json", "history.json")
	if err := timerManager.Start(); err != nil {
		logger.Error("Error starting TimerManager: %v", err)
		return
	}

	// Initialize metrics collector
	metricsCollector := cluster.NewMetricsCollector(list, stateManager)

	if err := persistence.LoadState(); err != nil {
		logger.Error("Failed to load state: %v", err)
	}

	// Create the shared connection handler
	connectionHandler := server.NewHandler(list, stateManager, persistence)

	// Initialize UDP server
	udpServer, err := network.NewUDPServer(udpPort, connectionHandler)
	if err != nil {
		logger.Error("Failed to create UDP server: %v", err)
		return
	} else {
		connectionHandler.AddBroadcaster(udpServer)
		udpServer.Start()
		defer udpServer.Stop()
	}

	// Initialize analog controller receiver
	analogReceiver, err := cxa.NewAnalogControllerReceiver(connectionHandler, analogControllerPort)
	if err != nil {
		logger.Error("Failed to create analog receiver: %v", err)
		return
	}
	defer analogReceiver.Close()

	// Initialize digital controller receiver
	digitalReceiver, err := cxd.NewDigitalControllerReceiver(connectionHandler, digitalControllerPort)
	if err != nil {
		logger.Error("Failed to create digital receiver: %v", err)
		return
	}
	defer digitalReceiver.Close()

	// Initialize config server
	configServer := server.NewConfigServer(nodeName, connectionHandler)

	// Start metrics server on separate port
	go func() {
		metricsServer := &http.Server{
			Addr:    fmt.Sprintf(":%d", *metricsPort),
			Handler: setupMetricsRoutes(metricsCollector),
		}
		logger.Info("Starting metrics server on :%d", *metricsPort)
		if err := metricsServer.ListenAndServe(); err != nil {
			logger.Error("Metrics server error: %v", err)
		}
	}()

	setupHTTPRoutes(configServer, metricsCollector, *verbose)
	setupTimerRoutes(timerManager, *verbose)

	// Start HAProxy management
	go network.ManageHAProxy(list)

	// Start the main server
	logger.Info("Starting API server on %s", httpPort)
	if err := http.ListenAndServe(httpPort, nil); err != nil {
		logger.Error("Failed to start server: %v", err)
	}
}

func setupHTTPRoutes(server *server.ConfigServer, metrics *cluster.MetricsCollector, verbose bool) {
	http.HandleFunc("/setValue", withLogging(server.SetValue, "setValue", verbose))
	http.HandleFunc("/getValue", withLogging(server.GetValue, "getValue", verbose))
	http.HandleFunc("/clear", withLogging(server.ClearAllData, "clear", verbose))
	http.HandleFunc("/upload", withLogging(server.UploadJSON, "upload", verbose))
	http.HandleFunc("/download", withLogging(server.DownloadJSON, "download", verbose))
	http.HandleFunc("/dump", withLogging(server.DumpState, "dump", verbose))
	http.HandleFunc("/ws", withWebSocketMetrics(server.HandleWebSocket, metrics, verbose))
	http.HandleFunc("/", withLogging(server.HandleRoot, "root", verbose))
}

func setupTimerRoutes(manager *timers.TimerManager, verbose bool) {
	http.HandleFunc("/tasks", withLogging(manager.ListTasksHandler, "tasks", verbose))
	http.HandleFunc("/tasks/add", withLogging(manager.AddTaskHandler, "addTask", verbose))
	http.HandleFunc("/tasks/update", withLogging(manager.UpdateTaskHandler, "updateTask", verbose))
	http.HandleFunc("/tasks/remove", withLogging(manager.RemoveTaskHandler, "removeTask", verbose))
	http.HandleFunc("/history", withLogging(manager.ExecutionHistoryHandler, "history", verbose))
}

func setupMetricsRoutes(metrics *cluster.MetricsCollector) *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("/metrics", metrics.HandleMetrics)
	mux.HandleFunc("/cluster/status", metrics.HandleClusterStatus)
	mux.HandleFunc("/health", metrics.HandleHealthCheck)
	return mux
}

// Middleware to log HTTP requests
func withLogging(handler http.HandlerFunc, endpoint string, verbose bool) http.HandlerFunc {

	if verbose {
		return func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			handler(w, r)
			duration := time.Since(start)
			logging.GetLogger().Debug("[HTTP] %s %s %s Duration: %v", r.Method, r.URL.Path, endpoint, duration)
		}
	} else {
		return handler
	}
}

// Special middleware for WebSocket connections
func withWebSocketMetrics(handler http.HandlerFunc, metrics *cluster.MetricsCollector, verbose bool) http.HandlerFunc {
	if verbose {
		return func(w http.ResponseWriter, r *http.Request) {
			metrics.UpdateWSCount(1)
			handler(w, r)
			metrics.UpdateWSCount(-1)
		}
	} else {
		return handler
	}
}
