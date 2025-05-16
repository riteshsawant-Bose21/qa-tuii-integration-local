package app

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/routes"
	"fusion/internal/server"
	"fusion/internal/version"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gorilla/mux"
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
	ConnectionHandler *server.Handler
	Cluster           *cluster.Cluster
	Delegate          *cluster.ClusterDelegate
	Server            *server.ConfigServer
	BLEServer         *network.BLEServer
	UDPServer         *network.UDPServer
	config            *api.AppConfig
	publicRouter      *mux.Router
	privateRouter     *mux.Router
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

	// Setup the public routes available on port 8080
	publicRouter := mux.NewRouter()
	publicRouter.Use(loggingMiddleware(config))
	publicRouter.Use(recoveryMiddleware())

	// Setup the private routes available on port 9090
	privateRouter := mux.NewRouter()
	privateRouter.Use(loggingMiddleware(config))
	privateRouter.Use(recoveryMiddleware())

	app := &App{
		Logger:            logger,
		StateManager:      stateManager,
		Persistence:       persistence,
		TaskManager:       taskManager,
		Updater:           updater,
		ConnectionHandler: connectionHandler,
		Cluster:           clusterInstance,
		Delegate:          delegate,
		Server:            configServer,
		BLEServer:         bleServer,
		UDPServer:         udpServer,
		config:            config,
		publicRouter:      publicRouter,
		privateRouter:     privateRouter,
	}

	app.setupPublicRoutes()
	app.setupPrivateRoutes()

	app.ConnectionHandler.SetEndpoints(routes.Endpoints)
	app.StateManager.StartVerification(memberlist)

	return app
}

// Close shuts down all components gracefully.
func (app *App) Close() {
	app.TaskManager.Stop()
	if app.BLEServer != nil {
		app.BLEServer.Stop()
	}
	app.UDPServer.Stop()
	app.Logger.Close()
}

func (app *App) setupPublicRoutes() {

	routes.RegisterPublicGET(app.publicRouter, routes.RootEndpoint, app.Server.HandleRoot)
	routes.RegisterPublicGET(app.publicRouter, routes.EndpointsEndpoint, routes.ListRegisteredEndpoints)
	routes.RegisterPublicGET(app.publicRouter, routes.MembersEndpoint, app.Server.GetMembers)
	routes.RegisterPublicGET(app.publicRouter, routes.MetadataEndpoint, app.Server.GetDatabaseMetadata)
	routes.RegisterPublicGET(app.publicRouter, routes.VersionEndpoint, app.Server.HandleVersion)
	routes.RegisterPublicPUT(app.publicRouter, routes.UploadAudioEndpoint, app.Server.UploadAudio)
	routes.RegisterPublicGET(app.publicRouter, routes.WebsocketEndpoint, withWebSocketMetrics(app.config, app.Server.HandleWebSocket, app.Cluster.Metrics))

	// Values
	routes.RegisterPublicGET(app.publicRouter, routes.ValueEndpoint, app.Server.GetValue)
	routes.RegisterPublicPOST(app.publicRouter, routes.ValueEndpoint, app.Server.SetValue)
	routes.RegisterPublicPATCH(app.publicRouter, routes.ValueEndpoint, app.Server.UpdateValue)
	routes.RegisterPublicDELETE(app.publicRouter, routes.ValueEndpoint, app.Server.ClearAllValues)

	// Snapshots
	// NOTE: These must be added before the {name} parameter endpoints to avoid conflicts
	routes.RegisterPublicGET(app.publicRouter, routes.SnapshotsEndpoint, app.Server.ListSnapshots)
	routes.RegisterPublicPOST(app.publicRouter, routes.SnapshotsNameEndpoint, app.Server.CreateSnapshot)
	routes.RegisterPublicGET(app.publicRouter, routes.SnapshotsNameEndpoint, app.Server.GetSnapshot)
	routes.RegisterPublicDELETE(app.publicRouter, routes.SnapshotsNameEndpoint, app.Server.DeleteSnapshot)
	routes.RegisterPublicPOST(app.publicRouter, routes.SnapshotsNameActivateEndpoint, app.Server.ActivateSnapshot)

	// Tasks
	// NOTE: These must be added before the {id} parameter endpoints to avoid conflicts
	routes.RegisterPublicGET(app.publicRouter, routes.TasksHistoryEndpoint, app.TaskManager.HandleGetHistory)
	routes.RegisterPublicDELETE(app.publicRouter, routes.TasksHistoryEndpoint, app.TaskManager.HandleClearHistory)
	routes.RegisterPublicGET(app.publicRouter, routes.TasksEndpoint, app.TaskManager.HandleGetTasks)
	routes.RegisterPublicPOST(app.publicRouter, routes.TasksEndpoint, app.TaskManager.HandleCreateTask)
	routes.RegisterPublicGET(app.publicRouter, routes.TasksIdEndpoint, app.TaskManager.HandleGetTask)
	routes.RegisterPublicPUT(app.publicRouter, routes.TasksIdEndpoint, app.TaskManager.HandleUpdateTask)
	routes.RegisterPublicDELETE(app.publicRouter, routes.TasksIdEndpoint, app.TaskManager.HandleDeleteTask)
	routes.RegisterPublicPOST(app.publicRouter, routes.TasksIdEnableEndpoint, app.TaskManager.HandleEnableTask)
	routes.RegisterPublicPOST(app.publicRouter, routes.TasksIdDisableEndpoint, app.TaskManager.HandleDisableTask)

	// Cluster
	routes.RegisterPublicGET(app.publicRouter, routes.ClusterLatencyNetworkEndpoint, app.Cluster.HandleGetNetworkLatency)
	routes.RegisterPublicGET(app.publicRouter, routes.ClusterLatencyNetworkFailuresEndpoint, app.Cluster.HandleGetNetworkFailures)
	routes.RegisterPublicGET(app.publicRouter, routes.ClusterLatencyStatusEndpoint, app.Cluster.HandleGetLatencyStatus)
	routes.RegisterPublicGET(app.publicRouter, routes.ClusterLatencySyncEndpoint, app.Cluster.HandleGetSyncLatency)
	routes.RegisterPublicGET(app.publicRouter, routes.ClusterLatencySyncAveragesEndpoint, app.Cluster.HandleGetSyncLatencyAverages)
	routes.RegisterPublicGET(app.publicRouter, routes.ClusterNTPSkewEndpoint, app.Cluster.HandleGetNTPSkew)
	routes.RegisterPublicGET(app.publicRouter, routes.ClusterStatusEndpoint, app.Cluster.Metrics.HandleClusterStatus)

	// Health
	routes.RegisterPublicGET(app.publicRouter, routes.HealthEndpoint, app.Cluster.Metrics.HandleHealthCheck)

	// Metrics
	routes.RegisterPublicGET(app.publicRouter, routes.MetricsEndpoint, app.Cluster.Metrics.HandleMetrics)

	// Setup
	routes.RegisterPublicPOST(app.publicRouter, routes.SetupDeviceName, app.Server.HandeSetupDeviceName)
}

func (app *App) setupPrivateRoutes() {
	routes.RegisterPrivateGET(app.privateRouter, routes.ExportDataEndport, app.Server.ExportData)
	routes.RegisterPrivatePOST(app.privateRouter, routes.ImportDataEndport, app.Server.ImportData)
	routes.RegisterPrivateGET(app.privateRouter, routes.ExportStateEndport, app.Server.ExportState)
	routes.RegisterPrivatePOST(app.privateRouter, routes.ImportStateEndport, app.Server.ImportState)
	routes.RegisterPrivateGET(app.privateRouter, routes.ClusterLatencyNetworkLocalEndpoint, app.Cluster.HandleGetNetworkLatencyLocal)
	routes.RegisterPrivateGET(app.privateRouter, routes.ClusterLatencySyncLocalEndpoint, app.Cluster.HandleGetSyncLatencyLocal)
	routes.RegisterPrivateGET(app.privateRouter, routes.ClusterLatencySyncAveragesLocalEndpoint, app.Cluster.HandleGetSyncLatencyAveragesLocal)
	routes.RegisterPrivateGET(app.privateRouter, routes.ClusterLatencyNetworkFailuresLocalEndpoint, app.Cluster.HandleGetNetworkFailuresLocal)
	routes.RegisterPrivateGET(app.privateRouter, routes.ClusterLatencyStatusLocalEndpoint, app.Cluster.HandleGetLatencyStatusLocal)
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

func (app *App) Start() {

	var wg sync.WaitGroup

	// Add two items to the wait group for the public and private routers
	wg.Add(2)

	go startAPIServer(app.publicRouter, api.HTTPPort, &wg)
	go startAPIServer(app.privateRouter, api.AdminPort, &wg)

	// Wait for the API server to come up before printing info
	time.Sleep(startupWaitDelay * time.Millisecond)
	app.Logger.Info("%s is ALIVE and RUNNING", app.config.NodeName)
	app.Logger.Info("Version: %s Commit: %s Build Time: %s", version.Version, version.Commit, version.BuildTime)

	wg.Wait()
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
		//LokiEndpoint: "http://192.168.64.1:3100",
	})
	return logging.GetLogger()
}

// withWebSocketMetrics adds metrics for WebSocket connections
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

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (rec *statusRecorder) WriteHeader(code int) {
	rec.status = code
	rec.ResponseWriter.WriteHeader(code)
}
