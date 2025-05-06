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
	"fusion/internal/routes"
	"fusion/internal/server"
	"fusion/internal/version"

	"github.com/gorilla/mux"
	"github.com/hashicorp/memberlist"
)

var (
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

type App struct {
	Logger            *logging.Logger
	StateManager      *server.StateManager
	Persistence       *server.Persistence
	TaskManager       *server.TaskManager
	Updater           *server.Updater
	Memberlist        *memberlist.Memberlist
	ConnectionHandler *server.Handler
	Cluster           *cluster.Cluster
	Delegate          *cluster.ClusterDelegate
	Server            *server.ConfigServer
	BLEServer         *network.BLEServer
	UDPServer         *network.UDPServer
	MetricsCollector  *cluster.MetricsCollector
}

// Close shuts down all components gracefully.
func (app *App) Close() {
	defer app.Logger.Close()
	defer app.TaskManager.Stop()
	if app.BLEServer != nil {
		defer app.BLEServer.Stop()
	}
	defer app.UDPServer.Stop()
	defer app.Logger.Close()
}

// NewApp is a factory function to set up the application
func NewApp(config *api.AppConfig) *App {

	logger := initLogging(config)

	initDataPaths()

	stateManager := initStateManager(config.NodeName)
	persistence := initPersistence(fusionDatabasePath, stateManager)
	taskManager := initTaskManager(config, persistence)
	updater := server.NewUpdater()

	delegate := cluster.NewClusterDelegate(config.NodeName, persistence, stateManager, taskManager, updater)
	memberlist := cluster.CreateMemberlist(config, delegate)
	connectionHandler := server.NewHandler(memberlist, persistence, stateManager, updater)
	clusterInstance := cluster.NewCluster(config, delegate, memberlist)
	bleServer := initBLEServer()
	udpServer := initUDPServer(api.UDPPort, connectionHandler)
	configServer := server.NewConfigServer(config.NodeName, connectionHandler, memberlist)
	metricsCollector := clusterInstance.NewMetricsCollector()

	return &App{
		Logger:            logger,
		StateManager:      stateManager,
		Persistence:       persistence,
		TaskManager:       taskManager,
		Updater:           updater,
		Memberlist:        memberlist,
		ConnectionHandler: connectionHandler,
		Cluster:           clusterInstance,
		Delegate:          delegate,
		Server:            configServer,
		BLEServer:         bleServer,
		UDPServer:         udpServer,
		MetricsCollector:  metricsCollector,
	}
}

// parseFlags parses and validates command-line flags.
func parseFlags() *api.AppConfig {
	versionFlag := flag.Bool("version", false, "Show version information")
	nodeName := flag.String("name", "", "Node name")
	bindAddr := flag.String("addr", "0.0.0.0", "Bind address")
	bindPort := flag.Int("port", 7946, "Bind port")
	verbose := flag.Bool("verbose", false, "Verbose output")
	flag.Parse()

	if *versionFlag {
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", version.Version, version.Commit, version.BuildTime)
		os.Exit(0)
	}

	if *nodeName == "" {
		log.Fatal("Node name is required")
	}

	return &api.AppConfig{
		NodeName: *nodeName,
		BindAddr: *bindAddr,
		BindPort: *bindPort,
		Verbose:  *verbose,
	}
}

// registerEndpoint registers a handler and tracks the endpoint.
func registerEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc, public bool) {
	if public {
		endpoints = append(endpoints, fmt.Sprintf("%s %s", method, pattern))
	}
	router.HandleFunc(pattern, handler).Methods(method)
}

func registerPrivateEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc) {
	registerEndpoint(router, method, pattern, handler, false)
}

func registerPrivateGET(router *mux.Router, pattern string, handler http.HandlerFunc) {
	registerPrivateEndpoint(router, "GET", pattern, handler)
}

func registerPrivatePOST(router *mux.Router, pattern string, handler http.HandlerFunc) {
	registerPrivateEndpoint(router, "POST", pattern, handler)
}

func registerPublicEndpoint(router *mux.Router, method string, pattern string, handler http.HandlerFunc) {
	registerEndpoint(router, method, pattern, handler, true)
}

func registerPublicDELETE(router *mux.Router, pattern string, handler http.HandlerFunc) {
	registerPublicEndpoint(router, "DELETE", pattern, handler)
}

func registerPublicGET(router *mux.Router, pattern string, handler http.HandlerFunc) {
	registerPublicEndpoint(router, "GET", pattern, handler)
}

func registerPublicPATCH(router *mux.Router, pattern string, handler http.HandlerFunc) {
	registerPublicEndpoint(router, "PATCH", pattern, handler)
}

func registerPublicPOST(router *mux.Router, pattern string, handler http.HandlerFunc) {
	registerPublicEndpoint(router, "POST", pattern, handler)
}

func registerPublicPUT(router *mux.Router, pattern string, handler http.HandlerFunc) {
	registerPublicEndpoint(router, "PUT", pattern, handler)
}

func listRegisteredEndpoints(w http.ResponseWriter, r *http.Request) {
	w.Header().Set(api.ContentType, api.JsonMIMEType)
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
func loggingMiddleware(config *api.AppConfig) mux.MiddlewareFunc {
	logger := logging.GetLogger()
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if config.Verbose {
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
func withWebSocketMetrics(config *api.AppConfig, handler http.HandlerFunc, metrics *cluster.MetricsCollector) http.HandlerFunc {
	if config.Verbose {
		return func(w http.ResponseWriter, r *http.Request) {
			metrics.UpdateWSCount(1)
			handler(w, r)
			metrics.UpdateWSCount(-1)
		}
	} else {
		return handler
	}
}

func setupPublicRoutes(config *api.AppConfig, r *mux.Router, app *App) {

	registerPublicGET(r, routes.RootEndpoint, app.Server.HandleRoot)
	registerPublicGET(r, routes.EndpointsEndpoint, listRegisteredEndpoints)
	registerPublicGET(r, routes.MembersEndpoint, app.Server.GetMembers)
	registerPublicGET(r, routes.MetadataEndpoint, app.Server.GetDatabaseMetadata)
	registerPublicGET(r, routes.VersionEndpoint, app.Server.HandleVersion)
	registerPublicPUT(r, routes.UploadAudioEndpoint, app.Server.UploadAudio)
	registerPublicGET(r, routes.WebsocketEndpoint, withWebSocketMetrics(config, app.Server.HandleWebSocket, app.MetricsCollector))

	// Values
	registerPublicGET(r, routes.ValueEndpoint, app.Server.GetValue)
	registerPublicPOST(r, routes.ValueEndpoint, app.Server.SetValue)
	registerPublicPATCH(r, routes.ValueEndpoint, app.Server.UpdateValue)
	registerPublicDELETE(r, routes.ValueEndpoint, app.Server.ClearAllValues)

	// Snapshots
	// NOTE: These must be added before the {name} parameter endpoints to avoid conflicts
	registerPublicGET(r, routes.SnapshotsEndpoint, app.Server.ListSnapshots)
	registerPublicPOST(r, routes.SnapshotsNameEndpoint, app.Server.CreateSnapshot)
	registerPublicGET(r, routes.SnapshotsNameEndpoint, app.Server.GetSnapshot)
	registerPublicDELETE(r, routes.SnapshotsNameEndpoint, app.Server.DeleteSnapshot)
	registerPublicPOST(r, routes.SnapshotsNameActivateEndpoint, app.Server.ActivateSnapshot)

	// Tasks
	// NOTE: These must be added before the {id} parameter endpoints to avoid conflicts
	registerPublicGET(r, routes.TasksHistoryEndpoint, app.TaskManager.HandleGetHistory)
	registerPublicDELETE(r, routes.TasksHistoryEndpoint, app.TaskManager.HandleClearHistory)
	registerPublicGET(r, routes.TasksEndpoint, app.TaskManager.HandleGetTasks)
	registerPublicPOST(r, routes.TasksEndpoint, app.TaskManager.HandleCreateTask)
	registerPublicGET(r, routes.TasksIdEndpoint, app.TaskManager.HandleGetTask)
	registerPublicPUT(r, routes.TasksIdEndpoint, app.TaskManager.HandleUpdateTask)
	registerPublicDELETE(r, routes.TasksIdEndpoint, app.TaskManager.HandleDeleteTask)
	registerPublicPOST(r, routes.TasksIdEnableEndpoint, app.TaskManager.HandleEnableTask)
	registerPublicPOST(r, routes.TasksIdDisableEndpoint, app.TaskManager.HandleDisableTask)

	// Cluster
	registerPublicGET(r, routes.ClusterLatencyNetworkEndpoint, app.Cluster.HandleGetNetworkLatency)
	registerPublicGET(r, routes.ClusterLatencyNetworkFailuresEndpoint, app.Cluster.HandleGetNetworkFailures)
	registerPublicGET(r, routes.ClusterLatencyStatusEndpoint, app.Cluster.HandleGetLatencyStatus)
	registerPublicGET(r, routes.ClusterLatencySyncEndpoint, app.Cluster.HandleGetSyncLatency)
	registerPublicGET(r, routes.ClusterLatencySyncAveragesEndpoint, app.Cluster.HandleGetSyncLatencyAverages)
	registerPublicGET(r, routes.ClusterNTPSkewEndpoint, app.Cluster.HandleGetNTPSkew)
	registerPublicGET(r, routes.ClusterStatusEndpoint, app.MetricsCollector.HandleClusterStatus)

	// Health
	registerPublicGET(r, routes.HealthEndpoint, app.MetricsCollector.HandleHealthCheck)

	// Metrics
	registerPublicGET(r, routes.MetricsEndpoint, app.MetricsCollector.HandleMetrics)
}

func setupPrivateRoutes(r *mux.Router, app *App) {
	registerPrivateGET(r, routes.ExportDataEndport, app.Server.ExportData)
	registerPrivatePOST(r, routes.ImportDataEndport, app.Server.ImportData)
	registerPrivateGET(r, routes.ExportStateEndport, app.Server.ExportState)
	registerPrivatePOST(r, routes.ImportStateEndport, app.Server.ImportState)
	registerPrivateGET(r, routes.ClusterLatencyNetworkLocalEndpoint, app.Cluster.HandleGetNetworkLatencyLocal)
	registerPrivateGET(r, routes.ClusterLatencySyncLocalEndpoint, app.Cluster.HandleGetSyncLatencyLocal)
	registerPrivateGET(r, routes.ClusterLatencySyncAveragesLocalEndpoint, app.Cluster.HandleGetSyncLatencyAveragesLocal)
	registerPrivateGET(r, routes.ClusterLatencyNetworkFailuresLocalEndpoint, app.Cluster.HandleGetNetworkFailuresLocal)
	registerPrivateGET(r, routes.ClusterLatencyStatusLocalEndpoint, app.Cluster.HandleGetLatencyStatusLocal)
}

// initLogging initializes the logging system.
func initLogging(config *api.AppConfig) *logging.Logger {

	logLevel := logging.INFO
	if config.Verbose {
		logLevel = logging.DEBUG
	}

	logging.InitLogger(logging.LogConfig{
		NodeName:    config.NodeName,
		LogDir:      "/var/log/fusion",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logLevel,
	})
	return logging.GetLogger()
}

// initPersistence initializes the persistence layer.
func initPersistence(dataPath string, stateManager *server.StateManager) *server.Persistence {

	logger := logging.GetLogger()

	persistence, err := server.NewPersistence(dataPath, stateManager)
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
func initStateManager(node string) *server.StateManager {
	return server.NewStateManager(node)
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

// initTaskManager initializes the timer manager.
func initTaskManager(config *api.AppConfig, persistence *server.Persistence) *server.TaskManager {
	taskManager := server.NewTaskManager(config, persistence)
	if err := taskManager.Start(); err != nil {
		logging.GetLogger().Fatal("Failed to start TaskManager: %v", err)
	}
	return taskManager
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

	udpPort := fmt.Sprintf(":%s", port)
	udpServer, err := network.NewUDPServer(udpPort, handler)
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

	apiPort := fmt.Sprintf(":%s", port)

	logger := logging.GetLogger()
	logger.Info("Starting API server on %s", apiPort)

	if err := http.ListenAndServe(apiPort, router); err != nil {
		logger.Fatal("API server failed: %v", err)
	}
}

func main() {

	config := parseFlags()

	app := NewApp(config)
	defer app.Close()

	// Setup the public routes available on port 8080
	publicRouter := mux.NewRouter()
	publicRouter.Use(loggingMiddleware(config))
	publicRouter.Use(recoveryMiddleware())

	setupPublicRoutes(config, publicRouter, app)

	// Setup the private routes available on port 9090
	privateRouter := mux.NewRouter()
	privateRouter.Use(loggingMiddleware(config))
	privateRouter.Use(recoveryMiddleware())
	setupPrivateRoutes(privateRouter, app)

	app.ConnectionHandler.SetEndpoints(endpoints)

	app.StateManager.StartVerification(app.Memberlist)

	var wg sync.WaitGroup

	// Add two items to the wait group for the public and private routers
	wg.Add(2)

	go startAPIServer(publicRouter, api.HTTPPort, &wg)
	go startAPIServer(privateRouter, api.AdminPort, &wg)

	// Wait for the API server to come up before printing info
	time.Sleep(startupWaitDelay * time.Millisecond)
	app.Logger.Info("%s is ALIVE and RUNNING", config.NodeName)
	app.Logger.Info("Version: %s Commit: %s Build Time: %s", version.Version, version.Commit, version.BuildTime)

	wg.Wait()
}
