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

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (rec *statusRecorder) WriteHeader(code int) {
	rec.status = code
	rec.ResponseWriter.WriteHeader(code)
}

// loggingMiddleware logs HTTP requests in verbose mode
func loggingMiddleware() mux.MiddlewareFunc {
	logger := logging.GetLogger()
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if verbose {
				rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
				start := time.Now()
				next.ServeHTTP(rec, r)
				duration := time.Since(start)
				logger.Debug("%s %s %d Duration: %v", r.Method, r.RequestURI, rec.status, duration)
			} else {
				next.ServeHTTP(w, r)
			}
		})
	}
}

// recoveryMiddleware avoids crashing the server and logs unexpected issues
func recoveryMiddleware() mux.MiddlewareFunc {
	logger := logging.GetLogger()
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if err := recover(); err != nil {
					logger.Error("Panic recovered: %v", err)
					http.Error(w, "Internal Server Error", http.StatusInternalServerError)
				}
			}()
			next.ServeHTTP(w, r)
		})
	}
}

// Middleware for WebSocket connections
func withWebSocketMetrics(handler http.HandlerFunc, metrics *cluster.MetricsCollector) http.HandlerFunc {
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

func setupRoutes(r *mux.Router, server *server.ConfigServer, metrics *cluster.MetricsCollector, tm *timers.TimerManager, verbose bool) {

	registerEndpoint(r, "GET", "/", server.HandleRoot)
	registerEndpoint(r, "GET", "/export", server.ExportState)
	registerEndpoint(r, "GET", "/endpoints", listRegisteredEndpoints)
	registerEndpoint(r, "GET", "/members", server.GetMembers)
	registerEndpoint(r, "GET", "/version", server.HandleVersion)
	registerEndpoint(r, "PUT", "/uploadAudio", server.UploadAudio)
	registerEndpoint(r, "GET", "/ws", withWebSocketMetrics(server.HandleWebSocket, metrics))

	// Values
	registerEndpoint(r, "GET", "/value", server.GetValue)
	registerEndpoint(r, "POST", "/value", server.SetValue)
	registerEndpoint(r, "PATCH", "/value", server.UpdateValue)
	registerEndpoint(r, "DELETE", "/value", server.ClearAllValues)

	// Snapshots
	// NOTE: These must be added before the {name} parameter endpoints to avoid conflicts
	registerEndpoint(r, "GET", "/snapshots/export", server.ExportSnapshots)
	registerEndpoint(r, "POST", "/snapshots/import", server.ImportSnapshots)
	registerEndpoint(r, "GET", "/snapshots/metadata", server.GetSnapshotMetadata)

	registerEndpoint(r, "GET", "/snapshots", server.ListSnapshots)
	registerEndpoint(r, "POST", "/snapshots/{name}", server.CreateSnapshot)
	registerEndpoint(r, "GET", "/snapshots/{name}", server.GetSnapshot)
	registerEndpoint(r, "DELETE", "/snapshots/{name}", server.DeleteSnapshot)
	registerEndpoint(r, "POST", "/snapshots/{name}/activate", server.ActivateSnapshot)

	// Timers
	registerEndpoint(r, "GET", "/tasks", tm.HandleGetTasks)
	registerEndpoint(r, "POST", "/tasks", tm.HandleCreateTask)
	registerEndpoint(r, "PUT", "/tasks/{id}", tm.HandleUpdateTask)
	registerEndpoint(r, "DELETE", "/tasks/{id}", tm.HandleDeleteTask)
	registerEndpoint(r, "GET", "/tasks/history", tm.HandleHistory)

	// Metrics
	registerEndpoint(r, "GET", "/cluster/status", metrics.HandleClusterStatus)
	registerEndpoint(r, "GET", "/health", metrics.HandleHealthCheck)
	registerEndpoint(r, "GET", "/metrics", metrics.HandleMetrics)
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
		logger.Fatal("Failed to to load active snapshot: %v", err)
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
	if bleServer != nil {
		defer bleServer.Stop()
	}

	udpServer := initUDPServer(api.UDPPort, connectionHandler)
	defer udpServer.Stop()

	configServer := server.NewConfigServer(nodeName, connectionHandler, cluster.Memberlist)

	router := mux.NewRouter()
	router.Use(loggingMiddleware())
	router.Use(recoveryMiddleware())

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
