package app

import (
	"bufio"
	"context"
	"fmt"
	"fusion-services-core/logging"

	"fusion-services-core/vip"
	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/controllers"
	"fusion/internal/network"
	"fusion/internal/persistence"
	"fusion/internal/pubsub"
	"fusion/internal/routes"
	"fusion/internal/server"
	"fusion/internal/server/handler"
	"fusion/internal/tasks"
	"fusion/internal/version"
	vipmonitor "fusion/internal/vip_monitor"
	"net"
	"net/http"
	"os"
	"runtime/debug"
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
	ConnectionHandler *handler.Handler
	Cluster           *cluster.Cluster
	Delegate          *cluster.ClusterDelegate
	Server            *server.FusionServer
	BLEServer         *network.BLEServer
	SAPServer         *network.SAPServer
	UDPServer         *network.UDPServer
	ControllerManager *controllers.ControllerManager
	memberlist        *memberlist.Memberlist
	monitor           *network.Monitor
	config            *api.AppConfig
	publicRouter      *mux.Router
	privateRouter     *mux.Router
	MDNSManager       *network.MDNSManager
	VIPMonitor        *vipmonitor.VIPMonitor
	Hub               *pubsub.Hub
}

// NewApp is a factory function to set up the application
func NewApp(config *api.AppConfig) *App {

	logger := initLogging(config)

	initDataPaths()

	stateManager := initStateManager(config)
	persistence := initPersistence(fusionDatabasePath, stateManager)
	hub := pubsub.NewHub(stateManager, persistence)
	taskManager := initTaskManager(config, persistence, hub)
	controllerManager := controllers.NewControllerManager(hub, api.ControllerPort)
	delegate := cluster.NewClusterDelegate(config, persistence, stateManager, taskManager, hub)

	memberlist := cluster.CreateMemberlist(config, delegate)
	clusterInstance := cluster.NewCluster(config, delegate, memberlist)
	hub.SetClusterTransport(clusterInstance)
	connectionHandler := handler.NewHandler(config, clusterInstance, persistence, stateManager, hub, controllerManager)
	mdnsManager := initMDNSManager()
	bleServer := initBLEServer()
	sapServer := initSAPServer(config, api.SAPPort, connectionHandler, hub)
	udpServer := initUDPServer(api.UDPPort, connectionHandler, hub)
	fusionServer := server.NewFusionServer(config.NodeName, connectionHandler, hub)

	// Initialize VIPMonitor
	vipMonitor := vipmonitor.NewVIPMonitor(config.NetIface, config.Local, clusterInstance)
	clusterInstance.SetVIPMonitor(vipMonitor)

	// Setup the public routes
	publicRouter := mux.NewRouter()
	publicRouter.Use(loggingMiddleware(config))
	publicRouter.Use(recoveryMiddleware())
	publicRouter.Use(corsMiddleware())

	// Setup the private routes
	privateRouter := mux.NewRouter()
	privateRouter.Use(loggingMiddleware(config))
	privateRouter.Use(recoveryMiddleware())
	privateRouter.Use(corsMiddleware())

	app := &App{
		Logger:            logger,
		StateManager:      stateManager,
		Persistence:       persistence,
		TaskManager:       taskManager,
		ConnectionHandler: connectionHandler,
		Cluster:           clusterInstance,
		Delegate:          delegate,
		Server:            fusionServer,
		BLEServer:         bleServer,
		SAPServer:         sapServer,
		UDPServer:         udpServer,
		ControllerManager: controllerManager,
		memberlist:        memberlist,
		config:            config,
		publicRouter:      publicRouter,
		privateRouter:     privateRouter,
		MDNSManager:       mdnsManager,
		VIPMonitor:        vipMonitor,
		Hub:               hub,
	}
	vipMonitor.SetCallback(app.handleVIPStateChange)
	return app
}

// Close shuts down all components gracefully.
func (app *App) Close() {
	app.TaskManager.Stop()
	if app.BLEServer != nil {
		app.BLEServer.Stop()
	}
	if app.ControllerManager != nil {
		app.ControllerManager.Stop()
	}
	if app.MDNSManager != nil {
		if err := app.MDNSManager.Close(); err != nil {
			app.Logger.Error("Failed to close mDNS manager: %v", err)
		}
	}
	if app.VIPMonitor != nil {
		app.VIPMonitor.Stop()
	}
	app.Cluster.Stop()
	app.UDPServer.Stop()
	app.Persistence.Close()
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

func (app *App) registerPublicPUT(route string, handler http.HandlerFunc) {
	routes.RegisterPublicPUT(app.publicRouter, route, handler)
}

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
	app.registerPublicPOST(routes.ClusterRebootEndpoint, app.Cluster.RebootSystem)

	// Controllers
	app.registerPublicGET(routes.ControllersEndpoint, app.Server.GetControllers)
	app.registerPublicGET(routes.ControllersIDEndpoint, app.Server.GetControllerByID)
	app.registerPublicGET(routes.ControllersIDWinkEndpoint, app.Server.TriggerWinkById)

	// Device
	app.registerPublicGET(routes.DevicesEndpoint, app.Server.GetDevicesInfo)
	app.registerPublicGET(routes.DevicesVIPEndpoint, app.VIPMonitor.HandleGetVIP)
	app.registerPublicPOST(routes.DevicesSetVIPEndpoint, app.VIPMonitor.HandleSetVIP)
	app.registerPublicPOST(routes.DeviceReloadVIPEndpoint, app.VIPMonitor.HandleReloadVIP)
	app.registerPublicPATCH(routes.DevicesIDEndpoint, app.Server.UpdateDeviceInfo)

	// Endpoints
	app.registerPublicGET(routes.EndpointsEndpoint, routes.ListRegisteredEndpoints)

	// Health
	app.registerPublicGET(routes.HealthEndpoint, app.Cluster.Metrics.GetHealthCheck)

	// Metadata
	app.registerPublicGET(routes.MetadataEndpoint, app.Server.GetDatabaseMetadata)

	// Metrics
	app.registerPublicGET(routes.MetricsEndpoint, app.Cluster.Metrics.GetMetrics)

	// PAVA
	app.registerPublicPOST(routes.PAVAMessagesEndpoint, app.Server.UploadMessage)
	app.registerPublicGET(routes.PAVAMessagesTagsEndpoint, app.Server.ListMessageTags)
	app.registerPublicGET(routes.PAVAMessagesIDEndpoint, app.Server.GetMessage)
	app.registerPublicDELETE(routes.PAVAMessagesIDEndpoint, app.Server.DeleteMessage)
	app.registerPublicGET(routes.PAVAMessagesEndpoint, app.Server.ListMessages)
	app.registerPublicGET(routes.PAVAMessageStreamEndpoint, app.Server.StreamMessage)
	app.registerPublicGET(routes.PAVAScheduleEndpoint, app.TaskManager.ListScheduledMessages)
	app.registerPublicPOST(routes.PAVAScheduleEndpoint, app.TaskManager.CreateScheduleMessageTask)
	app.registerPublicPATCH(routes.PAVAScheduleIDEndpoint, app.TaskManager.UpdateScheduleMessageTask)
	app.registerPublicPUT(routes.PAVAMessageTriggerEndpoint, app.TaskManager.TriggerMessage)
	// app.registerPublicGET(routes.PAVAZonesEndpoint, app.Server.ListZones)
	// app.registerPublicGET(routes.PAVAZoneStatusEndpoint, app.Server.GetZoneStatus)
	// app.registerPublicGET(routes.PAVADiagnosticsEndpoint, app.Server.GetSystemDiagnostics)
	// app.registerPublicGET(routes.PAVAStatusEndpoint, app.Server.GetSystemStatus)
	// app.registerPublicPUT(routes.PAVAAlarmsEndpoint, app.Server.CancelAlarms)

	// Root
	app.registerPublicGET(routes.RootEndpoint, app.Server.HandleRoot)

	// Sessions
	app.registerPublicGET(routes.SessionsEndpoint, app.Server.GetSessions)
	app.registerPublicGET(routes.SessionsIdEndpoint, app.Server.GetSession)

	// Snapshots
	app.registerPublicPOST(routes.SnapshotsActivateEndpoint, app.Server.ActivateSnapshot)
	app.registerPublicPOST(routes.SnapshotsUpdateEndpoint, app.Server.SaveSnapshot)
	app.registerPublicPOST(routes.SnapshotsNameEndpoint, app.Server.CreateSnapshot)
	app.registerPublicGET(routes.SnapshotsEndpoint, app.Server.ListSnapshots)
	app.registerPublicGET(routes.SnapshotsActiveEndpoint, app.Server.GetActiveSnapshotName)
	app.registerPublicGET(routes.SnapshotsNameEndpoint, app.Server.GetSnapshot)
	app.registerPublicDELETE(routes.SnapshotsNameEndpoint, app.Server.DeleteSnapshot)

	// Tasks
	app.registerPublicGET(routes.TasksHistoryEndpoint, app.TaskManager.GetHistory)
	app.registerPublicDELETE(routes.TasksHistoryEndpoint, app.TaskManager.ClearHistory)
	app.registerPublicGET(routes.TasksEndpoint, app.TaskManager.GetTasks)
	app.registerPublicPOST(routes.TasksEndpoint, app.TaskManager.CreateApplySnapshotTask)
	app.registerPublicGET(routes.TasksIdEndpoint, app.TaskManager.GetTaskHandler)
	app.registerPublicPATCH(routes.TasksIdEndpoint, app.TaskManager.UpdateApplySnapshotTask)
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

	// WebSocket
	app.registerPublicGET(routes.WebsocketEndpoint, withWebSocketMetrics(app.config, app.Server.HandleWebSocket, app.Cluster.Metrics))
}

func (app *App) setupPrivateRoutes() {
	app.registerPrivateGET(routes.ClusterLatencyNetworkLocalEndpoint, app.Cluster.GetNetworkLatencyLocal)
	app.registerPrivateGET(routes.ClusterLatencySyncLocalEndpoint, app.Cluster.GetSyncLatencyLocal)
	app.registerPrivateGET(routes.ClusterLatencySyncAveragesLocalEndpoint, app.Cluster.GetSyncLatencyAveragesLocal)
	app.registerPrivateGET(routes.ClusterLatencyNetworkFailuresLocalEndpoint, app.Cluster.GetNetworkFailuresLocal)
	app.registerPrivateGET(routes.ClusterLatencyStatusLocalEndpoint, app.Cluster.GetLatencyStatusLocal)
	app.registerPrivatePOST(routes.ClusterRebootLocalEndpoint, app.Cluster.RebootSystemLocal)

	app.registerPrivateGET(routes.DeviceEndpoint, app.Server.GetDeviceInfoLocal)
	app.registerPrivatePATCH(routes.DeviceEndpoint, app.Server.UpdateDeviceInfoLocal)
	app.registerPrivateGET(routes.DevicesVIPEndpoint, app.VIPMonitor.HandleGetVIP)
	app.registerPrivatePOST(routes.DevicesSetVIPEndpoint, app.VIPMonitor.HandleUpdateVIPLocal)
	app.registerPrivatePOST(routes.DeviceReloadVIPEndpoint, app.VIPMonitor.HandleReloadVIPLocal)

	app.registerPrivateGET(routes.DataEndpoint, app.Server.ExportData)
	app.registerPrivatePOST(routes.DataEndpoint, app.Server.ImportData)

	app.registerPrivateGET(routes.StateEndpoint, app.Server.ExportState)
	app.registerPrivatePOST(routes.StateEndpoint, app.Server.ImportState)
}

func (app *App) startNetworkMonitor() {

	logger := logging.GetLogger()
	logger.Info("Network monitor is active")

	app.monitor = network.NewMonitor(networkMonitorInterval, app.config.NetIface, func(oldIP, newIP string) {
		logger.Debug("IP changed from %s to %s.", oldIP, newIP)
		app.leaveCluster()
		app.joinCluster(newIP)
	})

	app.monitor.Start()
}

// handleVIPStateChange is called when VIP state changes (gained/lost/moved)
func (app *App) handleVIPStateChange(event vipmonitor.VIPEvent) {

	logger := logging.GetLogger()

	logger.Debug("[VIP] State change: type=%s vip=%s holder=%s isLocal=%v",
		event.EventType, event.VIP, event.Holder, event.IsLocalOwner)

	if event.VIP == "" {
		logger.Fatal("VIP event has VIP empty")

		// // Stop mDNS service
		// if err := app.MDNSManager.Close(); err != nil {
		// 	logger.Error("[Discovery] Failed to stop mDNS service: %v", err)
		// } else {
		// 	logger.Debug("[Discovery] mDNS service stopped")
		// }

		// // Send local status notification
		// if err := vip.SendLocalStatus("", "", false); err != nil {
		// 	logger.Error("Failed to send UDP status: %v", err)
		// }
		return
	}

	// Ensure we’re in the memberlist irrespective of the event type
	// This adds a safety check for split clusters.
	if member, err := app.Cluster.IsMember(); err != nil {
		logger.Error("isMember: %v", err)
	} else if !member {
		if err := app.Cluster.JoinMemberlist(); err != nil {
			logger.Error("JoinMemberlist: %v", err)
		} else {
			logger.Info("Joined memberlist with VIP %s", event.VIP)
		}
	}

	switch event.EventType {

	case vipmonitor.EventGainedOnLocalInterface:
		// VIP gained locally
		logger.Info("VIP %s gained locally", event.VIP)

		// Send local status notification
		if err := vip.SendLocalStatus(event.VIP, app.config.BindAddr, true); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}

		// Start mDNS service
		if ip := net.ParseIP(event.VIP); ip == nil {
			logger.Error("[Discovery] Invalid VIP %s for mDNS", event.VIP)
		} else {
			if err := app.MDNSManager.StartFusionAndOcaAdvertisment(ip); err != nil {
				logger.Error("[Discovery] Failed to start mDNS service: %v", err)
			} else {
				logger.Info("[Discovery] mDNS service started with VIP %s", event.VIP)
			}
		}

	case vipmonitor.EventLostOnLocalInterface:
		// VIP lost locally
		logger.Info("VIP %s lost", event.VIP)

		// Send local status notification
		if err := vip.SendLocalStatus(event.VIP, event.Holder, false); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}

		// Stop mDNS service
		if err := app.MDNSManager.Close(); err != nil {
			logger.Error("[Discovery] Failed to stop mDNS service: %v", err)
		} else {
			logger.Debug("[Discovery] mDNS service stopped")
		}

	case vipmonitor.EventGainedOnVRRPUpdate:
		// VIP gained locally (detected via VRRP update - rare case)
		logger.Info("VIP %s gained (VRRP update), holder=%s", event.VIP, event.Holder)

		// Send local status notification
		if err := vip.SendLocalStatus(event.VIP, app.config.BindAddr, true); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}

		// Start mDNS service
		if ip := net.ParseIP(event.VIP); ip == nil {
			logger.Error("[Discovery] Invalid VIP %s for mDNS", event.VIP)
		} else {
			if err := app.MDNSManager.StartFusionAndOcaAdvertisment(ip); err != nil {
				logger.Error("[Discovery] Failed to start mDNS service: %v", err)
			} else {
				logger.Info("[Discovery] mDNS service started with VIP %s", event.VIP)
			}
		}

	case vipmonitor.EventLostOnVRRPUpdate:
		// VIP lost locally (detected via VRRP update)
		logger.Info("VIP %s lost (VRRP update), holder=%s", event.VIP, event.Holder)

		// Send local status notification
		if err := vip.SendLocalStatus(event.VIP, event.Holder, false); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}

		// Stop mDNS service
		if err := app.MDNSManager.Close(); err != nil {
			logger.Error("[Discovery] Failed to stop mDNS service: %v", err)
		} else {
			logger.Debug("[Discovery] mDNS service stopped")
		}
	case vipmonitor.EventMovedOnVRRPUpdate:
		// VIP moved to different remote node
		logger.Info("VIP %s moved from %s to %s", event.VIP, event.OldHolder, event.Holder)

		// Send status notification
		if err := vip.SendLocalStatus(event.VIP, event.Holder, false); err != nil {
			logger.Error("Failed to send UDP status: %v", err)
		}

		// Stop mDNS service if it was running
		if err := app.MDNSManager.Close(); err != nil {
			logger.Error("[Discovery] Failed to stop mDNS service: %v", err)
		} else {
			logger.Debug("[Discovery] mDNS service stopped")
		}

	case vipmonitor.EventAddressChanged:
		// VIP address changed (config already updated, need to restart monitoring)
		logger.Info("VIP address changed from %s to %s", event.OldVIP, event.VIP)

		// Update mDNS with new VIP
		if ip := net.ParseIP(event.VIP); ip == nil {
			logger.Error("[Discovery] Invalid VIP %s for mDNS", event.VIP)
		} else {
			if err := app.MDNSManager.StartFusionAndOcaAdvertisment(ip); err != nil {
				logger.Error("[Discovery] Failed to update mDNS service: %v", err)
			} else {
				logger.Info("[Discovery] mDNS service updated with new VIP %s", event.VIP)
			}
		}
	case vipmonitor.EventVIPHolderChanged:
		// VIP holder changed but same VIP (detected via VRRP update)
		logger.Info("VIP %s holder changed from %s to %s", event.VIP, event.OldHolder, event.Holder)

	}
}

// leaveCluster leaves the cluster
func (app *App) leaveCluster() {
	app.memberlist.Leave(clusterLeaveTime)
	app.memberlist.Shutdown()
}

// joinCluster recreates the cluster and join it
func (app *App) joinCluster(ip string) {
	app.config.BindAddr = ip
	memberlist := cluster.CreateMemberlist(app.config, app.Delegate)
	app.memberlist = memberlist
	app.Cluster.SetMemberlist(memberlist)
	app.StateManager.SetMemberlist(memberlist)
	app.ConnectionHandler.SetClusterTransport(app.Cluster)
	app.Hub.SetClusterTransport(app.Cluster)

}

// startAPIServer starts the main HTTP API server
func startAPIServer(router *mux.Router, port string, ctx context.Context, wg *sync.WaitGroup) {
	defer wg.Done()

	apiPort := fmt.Sprintf(":%s", port)

	serverType := "unknown"
	switch port {
	case api.AdminPort:
		serverType = "admin"
	case api.HTTPPort:
		serverType = "public"
	}

	logger := logging.GetLogger()
	logger.Info("Starting %s API server on %s", serverType, apiPort)

	srv := &http.Server{
		Addr:    apiPort,
		Handler: router,
	}

	// Run the server in a goroutine
	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("API server (%s) failed: %v", serverType, err)
		}
	}()

	// Wait for shutdown signal
	<-ctx.Done()

	logger.Info("Shutting down %s API server...", serverType)

	// Shutdown the server with a timeout
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		logger.Error("Error shutting down %s server: %v", serverType, err)
	} else {
		logger.Debug("%s server shut down cleanly", serverType)
	}
}

func (app *App) Start(ctx context.Context) {

	app.setupPublicRoutes()
	app.setupPrivateRoutes()
	app.ConnectionHandler.SetEndpoints(routes.Endpoints)

	app.startNetworkMonitor()
	if err := app.VIPMonitor.Start(); err != nil {
		app.Logger.Error("Failed to start VIP monitoring: %v", err)
	}

	defer app.monitor.Stop()

	var wg sync.WaitGroup

	// Add two items to the wait group for the public and private routers
	wg.Add(2)

	go startAPIServer(app.publicRouter, api.HTTPPort, ctx, &wg)
	go startAPIServer(app.privateRouter, api.AdminPort, ctx, &wg)

	// Wait for the API server to come up before printing info
	time.Sleep(startupWaitDelay * time.Millisecond)
	app.Logger.Info("%s is ALIVE and RUNNING", app.config.NodeName)
	app.Logger.Info("     Version: %s", version.Version)
	app.Logger.Info("     Commit: %s", version.Commit)
	app.Logger.Info("     Build Time: %s", version.BuildTime)

	app.StateManager.Start(app.memberlist)

	// Start the Controller Manager for TCP wall controllers
	if err := app.ControllerManager.Start(); err != nil {
		app.Logger.Error("Failed to start ControllerManager: %v", err)
	}

	vip := app.VIPMonitor.GetCurrentVIP()
	if vip == "" {
		app.MDNSManager.StartFusionAdvertismentOnly(net.ParseIP(app.config.BindAddr))
	}

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
func initTaskManager(config *api.AppConfig, persistence *persistence.Persistence, hub *pubsub.Hub) *tasks.TaskManager {
	taskManager := tasks.NewTaskManager(config, persistence, hub)
	taskManager.Start()
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
func initSAPServer(config *api.AppConfig, port string, handler *handler.Handler, hub *pubsub.Hub) *network.SAPServer {

	if config.Local {
		logging.GetLogger().Warn("SAP Server not available in local mode")
		return nil
	}

	sapServer, err := network.NewSAPServer(SAPGroups, port, handler)
	if err != nil {
		logger := logging.GetLogger()
		logger.Fatal("Failed to create SAP server: %v", err)
	}

	hub.Register(sapServer)
	sapServer.Start()
	return sapServer
}

// initUDPServer initializes the UDP server.
func initUDPServer(port string, handler *handler.Handler, hub *pubsub.Hub) *network.UDPServer {

	udpPort := fmt.Sprintf(":%s", port)
	udpServer, err := network.NewUDPServer(udpPort, handler)
	if err != nil {
		logger := logging.GetLogger()
		logger.Fatal("Failed to create UDP server: %v", err)
	}

	hub.Register(udpServer)
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
	})
	return logging.GetLogger()
}

func initMDNSManager() *network.MDNSManager {
	logger := logging.GetLogger()
	logger.Info("Initializing mDNS manager")

	manager := network.NewMDNSManager()

	logger.Info("mDNS manager initialized successfully")
	return manager
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
					logger.Error("Panic recovered: %v\n%s", r, debug.Stack())
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

// Hijack implements http.Hijacker interface for WebSocket support
func (rec *statusRecorder) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	if hijacker, ok := rec.ResponseWriter.(http.Hijacker); ok {
		return hijacker.Hijack()
	}
	return nil, nil, fmt.Errorf("underlying ResponseWriter does not implement http.Hijacker")
}

// corsMiddleware adds CORS headers to all responses
func corsMiddleware() mux.MiddlewareFunc {
	logging.GetLogger().Warn(
		"Enabled CORS middleware for manufacturing tests. Review and adjust for production use.",
	)
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Set CORS headers
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
			w.Header().Set("Access-Control-Max-Age", "3600")

			// Handle preflight OPTIONS request
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}
