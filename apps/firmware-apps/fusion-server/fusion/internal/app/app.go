package app

import (
	"fmt"
	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/persistence"
	"fusion/internal/routes"
	"fusion/internal/server"
	"fusion/internal/server/handler"
	"fusion/internal/tasks"
	"fusion/internal/version"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/gorilla/mux"
	"github.com/hashicorp/memberlist"
)

const (
	bleCharacterUUID       = "AD10"
	bleServiceUUID         = "B053"
	clusterLeaveTime       = 5 * time.Second
	fusionDataPath         = "/var/lib/fusion"
	fusionDatabaseName     = "fusion.db"
	fusionDatabasePath     = fusionDataPath + "/" + fusionDatabaseName
	networkMonitorInterval = 5 * time.Second
	startupWaitDelay       = 100
)

var SAPGroups = []string{"224.2.127.254", "239.255.255.255"}

type App struct {
	Logger            *logging.Logger
	StateManager      *persistence.StateManager
	Persistence       *persistence.Persistence
	TaskManager       *tasks.TaskManager
	Updater           *handler.Updater
	ConnectionHandler *handler.Handler
	Cluster           *cluster.Cluster
	Delegate          *cluster.ClusterDelegate
	Server            *server.FusionServer
	BLEServer         *network.BLEServer
	SAPServer         *network.SAPServer
	UDPServer         *network.UDPServer
	memberlist        *memberlist.Memberlist
	monitor           *network.Monitor
	config            *api.AppConfig
	publicRouter      *mux.Router
	privateRouter     *mux.Router
}

// NewApp is a factory function to set up the application
func NewApp(config *api.AppConfig) *App {

	logger := initLogging(config)

	initDataPaths()

	stateManager := initStateManager(config)
	persistence := initPersistence(fusionDatabasePath, stateManager)
	taskManager := initTaskManager(config, persistence)
	updater := handler.NewUpdater()

	delegate := cluster.NewClusterDelegate(config.NodeName, persistence, stateManager, taskManager, updater)
	memberlist := cluster.CreateMemberlist(config, delegate)
	connectionHandler := handler.NewHandler(memberlist, persistence, stateManager, updater)
	clusterInstance := cluster.NewCluster(config, delegate, memberlist)
	bleServer := initBLEServer()
	sapServer := initSAPServer(config, api.SAPPort, connectionHandler)
	udpServer := initUDPServer(api.UDPPort, connectionHandler)
	fusionServer := server.NewFusionServer(config.NodeName, connectionHandler, memberlist)

	// Setup the public routes
	publicRouter := mux.NewRouter()
	publicRouter.Use(loggingMiddleware(config))
	publicRouter.Use(recoveryMiddleware())

	// Setup the private routes
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
		Server:            fusionServer,
		BLEServer:         bleServer,
		SAPServer:         sapServer,
		UDPServer:         udpServer,
		memberlist:        memberlist,
		config:            config,
		publicRouter:      publicRouter,
		privateRouter:     privateRouter,
	}

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

func (app *App) registerPublicDELETE(route string, handler http.HandlerFunc) {
	routes.RegisterPublicDELETE(app.publicRouter, route, handler)
}

func (app *App) registerPublicGET(route string, handler http.HandlerFunc) {
	routes.RegisterPublicGET(app.publicRouter, route, handler)
}

func (app *App) registerPublicPATCH(route string, handler http.HandlerFunc) {
	routes.RegisterPublicPATCH(app.publicRouter, route, handler)
}

func (app *App) registerPublicPOST(route string, handler http.HandlerFunc) {
	routes.RegisterPublicPOST(app.publicRouter, route, handler)
}

// func (app *App) registerPublicPUT(route string, handler http.HandlerFunc) {
// 	routes.RegisterPublicPUT(app.publicRouter, route, handler)
// }

func (app *App) registerPrivateGET(route string, handler http.HandlerFunc) {
	routes.RegisterPrivateGET(app.privateRouter, route, handler)
}

func (app *App) registerPrivatePATCH(route string, handler http.HandlerFunc) {
	routes.RegisterPrivatePATCH(app.privateRouter, route, handler)
}

func (app *App) registerPrivatePOST(route string, handler http.HandlerFunc) {
	routes.RegisterPrivatePOST(app.privateRouter, route, handler)
}

func (app *App) setupPublicRoutes() {

	// Cluster
	app.registerPublicGET(routes.ClusterLatencyNetworkEndpoint, app.Cluster.GetNetworkLatency)
	app.registerPublicGET(routes.ClusterLatencyNetworkFailuresEndpoint, app.Cluster.GetNetworkFailures)
	app.registerPublicGET(routes.ClusterLatencyStatusEndpoint, app.Cluster.GetLatencyStatus)
	app.registerPublicGET(routes.ClusterLatencySyncEndpoint, app.Cluster.GetSyncLatency)
	app.registerPublicGET(routes.ClusterLatencySyncAveragesEndpoint, app.Cluster.GetSyncLatencyAverages)
	app.registerPublicGET(routes.ClusterMembersEndpoint, app.Server.GetMembers)
	app.registerPublicGET(routes.ClusterNTPSkewEndpoint, app.Cluster.GetNTPSkew)
	app.registerPublicGET(routes.ClusterStatusEndpoint, app.Cluster.Metrics.GetClusterStatus)

	// Device
	app.registerPublicGET(routes.DevicesEndpoint, app.Cluster.GetDevicesInfo)
	app.registerPublicPATCH(routes.DevicesIDEndpoint, app.Cluster.UpdateDeviceInfo)
	app.registerPublicGET(routes.DevicesVIPEndpoint, app.Cluster.GetVIP)
	app.registerPublicPOST(routes.DevicesSetVIPEndpoint, app.Cluster.SetVIP)
	app.registerPublicPOST(routes.DeviceReloadVIPEndpoint, app.Cluster.ReloadVIP)

	// Endpoints
	app.registerPublicGET(routes.EndpointsEndpoint, routes.ListRegisteredEndpoints)

	// Health
	app.registerPublicGET(routes.HealthEndpoint, app.Cluster.Metrics.GetHealthCheck)

	// Metadata
	app.registerPublicGET(routes.MetadataEndpoint, app.Server.GetDatabaseMetadata)

	// Metrics
	app.registerPublicGET(routes.MetricsEndpoint, app.Cluster.Metrics.GetMetrics)

	/*
		// PAVA
		app.registerPublicPUT(routes.PAVAAudioEndpoint, app.Server.UploadMessage)
		app.registerPublicDELETE(routes.PAVAAudioDeleteEndpoint, app.Server.DeleteMessage)
		app.registerPublicGET(routes.PAVAMessagesEndpoint, app.Server.ListMessages)
		app.registerPublicPUT(routes.PAVAMessageTriggerEndpoint, app.TaskManager.TriggerMessage)
		app.registerPublicGET(routes.PAVAZonesEndpoint, app.Server.ListZones)
		app.registerPublicGET(routes.PAVAZoneStatusEndpoint, app.Server.GetZoneStatus)
		app.registerPublicGET(routes.PAVADiagnosticsEndpoint, app.Server.GetSystemDiagnostics)
		app.registerPublicGET(routes.PAVAStatusEndpoint, app.Server.GetSystemStatus)
		app.registerPublicPUT(routes.PAVAAlarmsEndpoint, app.Server.CancelAlarms)
		app.registerPublicGET(routes.PAVAMessagesEndpoint, app.Server.ListScheduledMessages)
		app.registerPublicPOST(routes.PAVAMessagesEndpoint, app.Server.ScheduleMessage)
	*/

	// Root
	app.registerPublicGET(routes.RootEndpoint, app.Server.HandleRoot)

	// Sessions
	app.registerPublicGET(routes.SessionsEndpoint, app.Server.GetSessions)
	app.registerPublicGET(routes.SessionsIdEndpoint, app.Server.GetSession)

	// Snapshots
	// NOTE: These must be added before the {name} parameter endpoints to avoid conflicts
	app.registerPublicGET(routes.SnapshotsEndpoint, app.Server.ListSnapshots)
	app.registerPublicPOST(routes.SnapshotsNameEndpoint, app.Server.CreateSnapshot)
	app.registerPublicGET(routes.SnapshotsNameEndpoint, app.Server.GetSnapshot)
	app.registerPublicDELETE(routes.SnapshotsNameEndpoint, app.Server.DeleteSnapshot)
	app.registerPublicPOST(routes.SnapshotsActivateEndpoint, app.Server.ActivateSnapshot)

	// Tasks
	// NOTE: These must be added before the {id} parameter endpoints to avoid conflicts
	app.registerPublicGET(routes.TasksHistoryEndpoint, app.TaskManager.GetHistory)
	app.registerPublicDELETE(routes.TasksHistoryEndpoint, app.TaskManager.ClearHistory)
	app.registerPublicGET(routes.TasksEndpoint, app.TaskManager.GetTasks)
	app.registerPublicPOST(routes.TasksEndpoint, app.TaskManager.CreateApplySnapshotTask)
	app.registerPublicGET(routes.TasksIdEndpoint, app.TaskManager.GetTask)
	app.registerPublicPOST(routes.TasksIdEndpoint, app.TaskManager.UpdateApplySnapshotTask)
	app.registerPublicDELETE(routes.TasksIdEndpoint, app.TaskManager.DeleteTask)
	app.registerPublicPOST(routes.TasksIdEnableEndpoint, app.TaskManager.EnableTask)
	app.registerPublicPOST(routes.TasksIdDisableEndpoint, app.TaskManager.DisableTask)

	// Values
	app.registerPublicGET(routes.ValueEndpoint, app.Server.GetValue)
	app.registerPublicPOST(routes.ValueEndpoint, app.Server.SetValue)
	app.registerPublicPATCH(routes.ValueEndpoint, app.Server.UpdateValue)
	app.registerPublicDELETE(routes.ValueEndpoint, app.Server.ClearAllValues)

	// Versioning
	app.registerPublicGET(routes.VersionEndpoint, app.Server.GetVersion)
	app.registerPublicPOST(routes.VersionRollbackEndpoint, app.Server.RollbackVersion)
	app.registerPublicPOST(routes.VersionUpdateEndpoint, app.Server.UpdateVersion)

	// WebSocket
	app.registerPublicGET(routes.WebsocketEndpoint, withWebSocketMetrics(app.config, app.Server.HandleWebSocket, app.Cluster.Metrics))
}

func (app *App) setupPrivateRoutes() {
	app.registerPrivateGET(routes.ClusterLatencyNetworkLocalEndpoint, app.Cluster.GetNetworkLatencyLocal)
	app.registerPrivateGET(routes.ClusterLatencySyncLocalEndpoint, app.Cluster.GetSyncLatencyLocal)
	app.registerPrivateGET(routes.ClusterLatencySyncAveragesLocalEndpoint, app.Cluster.GetSyncLatencyAveragesLocal)
	app.registerPrivateGET(routes.ClusterLatencyNetworkFailuresLocalEndpoint, app.Cluster.GetNetworkFailuresLocal)
	app.registerPrivateGET(routes.ClusterLatencyStatusLocalEndpoint, app.Cluster.GetLatencyStatusLocal)

	app.registerPrivateGET(routes.DeviceEndpoint, app.Cluster.GetDeviceInfo)
	app.registerPrivatePOST(routes.DeviceEndpoint, app.Cluster.SetDeviceInfo)
	app.registerPrivatePATCH(routes.DeviceEndpoint, app.Cluster.UpdateDeviceInfoLocal)
	app.registerPrivatePOST(routes.DevicesSetVIPEndpoint, app.Cluster.UpdateVIPLocal)
	app.registerPrivatePOST(routes.DeviceReloadVIPEndpoint, app.Cluster.ReloadVIPLocal)

	app.registerPrivateGET(routes.DataEndpoint, app.Server.ExportData)
	app.registerPrivatePOST(routes.DataEndpoint, app.Server.ImportData)

	app.registerPrivateGET(routes.StateEndpoint, app.Server.ExportState)
	app.registerPrivatePOST(routes.StateEndpoint, app.Server.ImportState)
}

func (app *App) startNetworkMonitor() {

	logger := logging.GetLogger()
	logger.Info("Network monitor is active")

	app.monitor = network.NewMonitor(networkMonitorInterval, func(oldIP, newIP string) {
		logger.Info("IP changed from %s to %s — rejoining cluster", oldIP, newIP)

		// Leave old cluster
		app.memberlist.Leave(clusterLeaveTime)
		app.memberlist.Shutdown()

		// Recreate and join with new IP
		app.config.BindAddr = newIP
		app.memberlist = cluster.CreateMemberlist(app.config, app.Delegate)
	})
}

// startAPIServer starts the main HTTP API server
func startAPIServer(router *mux.Router, port string, wg *sync.WaitGroup) {
	defer wg.Done()

	apiPort := fmt.Sprintf(":%s", port)

	var serverType = "unknown"
	switch port {
	case api.AdminPort:
		serverType = "admin"
	case api.HTTPPort:
		serverType = "public"
	}

	logger := logging.GetLogger()
	logger.Info("Starting %s API server on %s", serverType, apiPort)

	if err := http.ListenAndServe(apiPort, router); err != nil {
		logger.Fatal("API server failed: %v", err)
	}
}

func (app *App) Start() {

	app.setupPublicRoutes()
	app.setupPrivateRoutes()
	app.ConnectionHandler.SetEndpoints(routes.Endpoints)
	app.startNetworkMonitor()

	var wg sync.WaitGroup

	// Add two items to the wait group for the public and private routers
	wg.Add(2)

	go startAPIServer(app.publicRouter, api.HTTPPort, &wg)
	go startAPIServer(app.privateRouter, api.AdminPort, &wg)

	// Wait for the API server to come up before printing info
	time.Sleep(startupWaitDelay * time.Millisecond)
	app.Logger.Info("%s is ALIVE and RUNNING", app.config.NodeName)
	app.Logger.Info("     Version: %s", version.Version)
	app.Logger.Info("     Commit: %s", version.Commit)
	app.Logger.Info("     Build Time: %s", version.BuildTime)

	app.StateManager.StartVerification(app.memberlist)

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
func initPersistence(dataPath string, stateManager *persistence.StateManager) *persistence.Persistence {

	logger := logging.GetLogger()

	persistence, err := persistence.NewPersistence(dataPath, stateManager)
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
func initStateManager(config *api.AppConfig) *persistence.StateManager {
	return persistence.NewStateManager(config)
}

// initTaskManager initializes the timer manager.
func initTaskManager(config *api.AppConfig, persistence *persistence.Persistence) *tasks.TaskManager {
	taskManager := tasks.NewTaskManager(config, persistence)
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

// initSAPServer initializes the SAP server
// See RFC 2947 (https://datatracker.ietf.org/doc/html/rfc2974)
func initSAPServer(config *api.AppConfig, port string, handler *handler.Handler) *network.SAPServer {

	if config.Local {
		logging.GetLogger().Warn("SAP Server not available in local mode")
		return nil
	}

	sapServer, err := network.NewSAPServer(SAPGroups, port, handler)
	if err != nil {
		logger := logging.GetLogger()
		logger.Fatal("Failed to create SAP server: %v", err)
	}

	handler.AddBroadcaster(sapServer)
	sapServer.Start()
	return sapServer
}

// initUDPServer initializes the UDP server.
func initUDPServer(port string, handler *handler.Handler) *network.UDPServer {

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
