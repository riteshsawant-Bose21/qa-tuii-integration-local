package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/server"
	"fusion/internal/timers"
	"fusion/internal/version"

	"github.com/gorilla/mux"
)

var (
	nodeName  string
	bindAddr  string
	bindPort  int
	verbose   bool
	endpoints []string
)

const (
	bleCharacterUUID   = "AD10"
	bleServiceUUID     = "B053"
	fusionDataPath     = "/var/lib/fusion"
	fusionDatabaseName = "fusion.db"
	fusionDatabasePath = fusionDataPath + "/" + fusionDatabaseName
	startupWaitDelay   = 100
)

// registerEndpoint registers a handler and tracks the endpoint.
func registerEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc) {
	endpoints = append(endpoints, fmt.Sprintf("%s %s", method, pattern))
	router.HandleFunc(pattern, handler).Methods(method)
}

func listRegisteredEndpoints(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]any{"routes": endpoints})
}

func setupRoutes(r *mux.Router, server *server.ConfigServer, metrics *cluster.MetricsCollector, tm *timers.TimerManager, verbose bool) {

	registerEndpoint(r, "GET", "/", withLogging(server.HandleRoot, "root", verbose))
	registerEndpoint(r, "GET", "/export", withLogging(server.ExportState, "export", verbose))
	registerEndpoint(r, "GET", "/endpoints", listRegisteredEndpoints)
	registerEndpoint(r, "GET", "/members", withLogging(server.GetMembers, "members", verbose))
	registerEndpoint(r, "GET", "/version", withLogging(server.HandleVersion, "version", verbose))
	registerEndpoint(r, "PUT", "/uploadAudio", withLogging(server.UploadAudio, "uploadAudio", verbose))
	registerEndpoint(r, "GET", "/ws", withWebSocketMetrics(server.HandleWebSocket, metrics, verbose))

	// Values
	registerEndpoint(r, "GET", "/value", withLogging(server.GetValue, "getValue", verbose))
	registerEndpoint(r, "POST", "/value", withLogging(server.SetValue, "setValue", verbose))
	registerEndpoint(r, "PATCH", "/value", withLogging(server.UpdateValue, "updateValue", verbose))
	registerEndpoint(r, "DELETE", "/value", withLogging(server.ClearAllValues, "clearAllValues", verbose))

	// Snapshots
	// NOTE: These must be added before the {name} parameter endpoints to avoid conflicts
	registerEndpoint(r, "GET", "/snapshots/export", withLogging(server.ExportSnapshots, "exportSnapshots", verbose))
	registerEndpoint(r, "POST", "/snapshots/import", withLogging(server.ImportSnapshots, "importSnapshots", verbose))
	registerEndpoint(r, "GET", "/snapshots/metadata", withLogging(server.GetSnapshotMetadata, "snapshotMetadata", verbose))

	registerEndpoint(r, "GET", "/snapshots", withLogging(server.ListSnapshots, "listSnapshots", verbose))
	registerEndpoint(r, "POST", "/snapshots/{name}", withLogging(server.CreateSnapshot, "createSnapshot", verbose))
	registerEndpoint(r, "GET", "/snapshots/{name}", withLogging(server.GetSnapshot, "getSnapshot", verbose))
	registerEndpoint(r, "DELETE", "/snapshots/{name}", withLogging(server.DeleteSnapshot, "deleteSnapshot", verbose))
	registerEndpoint(r, "POST", "/snapshots/{name}/activate", withLogging(server.ActivateSnapshot, "activateSnapshot", verbose))

	// Timers
	registerEndpoint(r, "GET", "/tasks", withLogging(tm.HandleGetTasks, "getTasks", verbose))
	registerEndpoint(r, "POST", "/tasks", withLogging(tm.HandleCreateTask, "createTask", verbose))
	registerEndpoint(r, "PUT", "/tasks/{id}", withLogging(tm.HandleUpdateTask, "updateTask", verbose))
	registerEndpoint(r, "DELETE", "/tasks/{id}", withLogging(tm.HandleDeleteTask, "deleteTask", verbose))
	registerEndpoint(r, "GET", "/tasks/history", withLogging(tm.HandleHistory, "history", verbose))

	// Metrics
	registerEndpoint(r, "GET", "/cluster/status", withLogging(metrics.HandleClusterStatus, "clusterStatus", verbose))
	registerEndpoint(r, "GET", "/health", withLogging(metrics.HandleHealthCheck, "health", verbose))
	registerEndpoint(r, "GET", "/metrics", withLogging(metrics.HandleMetrics, "metrics", verbose))
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

// Middleware for WebSocket connections
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

// parseFlags parses and validates command-line flags.
func parseFlags() {
	versionFlag := flag.Bool("version", false, "Show version information")
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.BoolVar(&verbose, "verbose", false, "Verbose output")

	flag.Parse()

	if *versionFlag {
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", version.Version, version.Commit, version.BuildTime)
		os.Exit(0)
	}

	if nodeName == "" {
		// We can't use Logging as it requires the node name to initalize.
		log.Fatal("Node name is required")
	}
}

// initLogging initializes the logging system.
func initLogging(nodeName string, verbose bool) *logging.Logger {

	logLevel := logging.INFO
	if verbose {
		logLevel = logging.DEBUG
	}

	logging.InitLogger(logging.LogConfig{
		NodeName:    nodeName,
		LogDir:      "/var/log/fusion",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logLevel,
	})
	return logging.GetLogger()
}

// initPersistence initializes the persistence layer.
func initPersistence(configPath string, stateManager *server.StateManager) *server.Persistence {

	logger := logging.GetLogger()

	persistence, err := server.NewPersistence(configPath, stateManager, verbose)
	if err != nil {
		logger.Fatal("Failed to initialize persistence: %v", err)
	}

	err = persistence.LoadActiveSnapshot()
	if err != nil {
		logger.Fatal("Failed to to load initial state: %v", err)
	}

	return persistence
}

// initStateManager initializes the state manager.
func initStateManager(nodeName string) *server.StateManager {
	return server.NewStateManager(nodeName)
}

func initDataPaths() {

	logger := logging.GetLogger()

	// Check if the directory exists
	info, err := os.Stat(fusionDataPath)
	if err != nil {
		if os.IsNotExist(err) {
			// Directory does not exist; create it with mode 0777.
			if err := os.MkdirAll(fusionDataPath, 0777); err != nil {
				logger.Fatal("Failed to create data directory: %v", err)
			}
			// Retrieve info after creation.
			info, err = os.Stat(fusionDataPath)
			if err != nil {
				logger.Fatal("Failed to to stat data directory after creation: %v", err)
			}
		} else {
			logger.Fatal("Failed to to stat audio directory: %v", err)
		}
	} else if !info.IsDir() {
		// The path exists but is not a directory
		logger.Fatal("%s exists but is not a directory", fusionDataPath)
	}

	// Check if the directory has the desired permissions (0777).
	currentPerm := info.Mode().Perm()
	if currentPerm != 0777 {
		if err := os.Chmod(fusionDataPath, 0777); err != nil {
			logger.Fatal("Failed to set permissions on data directory: %v", err)
		}
	}
}

// initTimerManager initializes the timer manager.
func initTimerManager() *timers.TimerManager {
	timerManager := timers.NewTimerManager("tasks.json", "history.json")
	if err := timerManager.Start(); err != nil {
		logging.GetLogger().Fatal("Error starting TimerManager: %v", err)
	}
	return timerManager
}

// initBLEServer initializes the Bluetooth server.
func initBLEServer() *network.BLEServer {

	bleServer, err := network.NewBLEServer(bleServiceUUID, bleCharacterUUID)
	if err != nil {
		logging.GetLogger().Info("Bluetooth not available: %v", err)
		return nil
	}
	return bleServer
}

// initUDPServer initializes the UDP server.
func initUDPServer(port string, handler *server.Handler) *network.UDPServer {

	udpServer, err := network.NewUDPServer(port, handler)
	if err != nil {
		logger := logging.GetLogger()
		logger.Fatal("Failed to create UDP server: %v", err)
	}

	handler.AddBroadcaster(udpServer)
	udpServer.Start()
	return udpServer
}

// startAPIServer starts the main HTTP API server
func startAPIServer(router *mux.Router, port string, wg *sync.WaitGroup) {
	defer wg.Done()

	logger := logging.GetLogger()
	logger.Info("Starting API server on %s", port)

	if err := http.ListenAndServe(port, router); err != nil {
		logger.Fatal("API server failed: %v", err)
	}
}

func main() {

	parseFlags()

	logger := initLogging(nodeName, verbose)
	defer logger.Close()

	initDataPaths()

	stateManager := initStateManager(nodeName)
	persistence := initPersistence(fusionDatabasePath, stateManager)
	updater := server.NewUpdater()
	cluster := cluster.NewCluster(nodeName, bindAddr, bindPort, stateManager, persistence, updater, verbose)

	stateManager.StartStateVerification(cluster.Memberlist)

	timerManager := initTimerManager()
	defer timerManager.Stop()

	connectionHandler := server.NewHandler(cluster.Memberlist, stateManager, persistence, updater)

	bleServer := initBLEServer()
	defer bleServer.Stop()

	udpServer := initUDPServer(api.UDPPort, connectionHandler)
	defer udpServer.Stop()

	configServer := server.NewConfigServer(nodeName, connectionHandler, cluster.Memberlist)

	router := mux.NewRouter()
	metricsCollector := cluster.NewMetricsCollector()
	setupRoutes(router, configServer, metricsCollector, timerManager, verbose)

	connectionHandler.SetEndpoints(endpoints)

	var wg sync.WaitGroup
	wg.Add(1)

	go startAPIServer(router, api.HTTPPort, &wg)

	// Wait for the API server to come up before printing info
	time.Sleep(startupWaitDelay * time.Millisecond)
	logger.Info("%s is ALIVE and RUNNING", nodeName)
	logger.Info("Version: %s Commit: %s Build Time: %s", version.Version, version.Commit, version.BuildTime)

	wg.Wait()
}
