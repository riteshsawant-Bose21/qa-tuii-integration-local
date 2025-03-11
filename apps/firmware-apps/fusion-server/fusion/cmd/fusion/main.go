package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"fusion/internal/api"
	"fusion/internal/cluster"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/server"
	"fusion/internal/timers"

	"github.com/hashicorp/memberlist"
)

var (
	Version     string
	Commit      string
	BuildTime   string
	nodeName    string
	bindAddr    string
	bindPort    int
	joinAddr    string
	metricsPort int
	enableBLE   bool
	verbose     bool
	endpoints   []string
)

const (
	fusionDataPath    = "/var/lib/fusion"
	configDataPath    = fusionDataPath + "/config.db"
	audioDataPath     = fusionDataPath + "/audio"
	stateDumpInterval = 30
	serialPort        = "/tmp/ttyFusionServer"
	baudRate          = 9600
	bleServiceUUID    = "B053"
	bleCharacterUUID  = "AD10"
)

func setupHTTPRoutes(server *server.ConfigServer, metrics *cluster.MetricsCollector, verbose bool) {
	registerEndpoint("/", withLogging(server.HandleRoot, "root", verbose))
	registerEndpoint("/dump", withLogging(server.DumpState, "dump", verbose))
	registerEndpoint("/dro/process", withLogging(server.DROProcess, "process", verbose))
	registerEndpoint("/endpoints", withLogging(server.GetEndpoints, "endpoints", verbose))
	registerEndpoint("/getValue", withLogging(server.GetValue, "getValue", verbose))
	registerEndpoint("/setValue", withLogging(server.SetValue, "setValue", verbose))
	registerEndpoint("/updateValue", withLogging(server.UpdateValue, "updateValue", verbose))
	registerEndpoint("/clear", withLogging(server.ClearAllData, "clear", verbose))
	registerEndpoint("/updateVersion", withLogging(server.UpdateVersion, "updateVersion", verbose))
	registerEndpoint("/rollbackVersion", withLogging(server.RollbackVersion, "rollbackVersion", verbose))
	registerEndpoint("/snapshots", withLogging(server.ListSnapshots, "listSnapshots", verbose))
	registerEndpoint("/snapshots/create", withLogging(server.CreateSnapshot, "createSnapshot", verbose))
	registerEndpoint("/snapshots/activate", withLogging(server.ActivateSnapshotHTTP, "activateSnapshot", verbose))
	registerEndpoint("/snapshots/delete", withLogging(server.DeleteSnapshot, "deleteSnapshot", verbose))
	registerEndpoint("/uploadAudio", withLogging(server.UploadAudio, "uploadAudio", verbose))
	registerEndpoint("/ws", withWebSocketMetrics(server.HandleWebSocket, metrics, verbose))

}

func setupTimerRoutes(manager *timers.TimerManager, verbose bool) {
	registerEndpoint("/tasks", withLogging(manager.ListTasksHandler, "tasks", verbose))
	registerEndpoint("/tasks/add", withLogging(manager.AddTaskHandler, "addTask", verbose))
	registerEndpoint("/tasks/update", withLogging(manager.UpdateTaskHandler, "updateTask", verbose))
	registerEndpoint("/tasks/remove", withLogging(manager.RemoveTaskHandler, "removeTask", verbose))
	registerEndpoint("/tasks/history", withLogging(manager.ExecutionHistoryHandler, "history", verbose))
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

// parseFlags parses and validates command-line flags.
func parseFlags() {
	versionFlag := flag.Bool("version", false, "Show version information")
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.StringVar(&joinAddr, "join", "", "Address to join cluster (comma-separated)")
	flag.IntVar(&metricsPort, "metrics-port", 9090, "Metrics server port")
	flag.BoolVar(&enableBLE, "enableBLE", true, "Enable BLE")
	flag.BoolVar(&verbose, "verbose", false, "Verbose output")

	flag.Parse()

	if *versionFlag {
		log.Printf("Version: %s\nCommit: %s\nBuild Time: %s\n", Version, Commit, BuildTime)
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

// initStateManager initializes the state manager.
func initStateManager(nodeName string) *server.StateManager {
	stateManager := server.NewStateManager(nodeName)
	if verbose {
		stateManager.StartStateDumping(stateDumpInterval * time.Second)
	}
	return stateManager
}

// initPersistence initializes the persistence layer.
func initPersistence(configPath string, stateManager *server.StateManager) (*server.ConfigPersistence, error) {
	return server.NewConfigPersistence(configPath, stateManager, true)
}

// initCluster initializes the cluster memberlist.
func initCluster(nodeName, bindAddr string, bindPort int, joinAddr string, stateManager *server.StateManager, persistence *server.ConfigPersistence, updater *server.Updater) (*memberlist.Memberlist, error) {
	var joinAddrs []string
	if joinAddr != "" {
		joinAddrs = strings.Split(joinAddr, ",")
	}

	list, err := cluster.CreateMemberlist(nodeName, bindAddr, bindPort, joinAddrs, stateManager, persistence, updater, verbose)
	if err != nil {
		return nil, fmt.Errorf("failed to create memberlist: %w", err)
	}

	if verbose {
		cluster.MonitorClusterState(list)
		cluster.StartHealthCheck(list)
		cluster.StartStateVerification(list, stateManager)
	}

	return list, nil
}

func initDataPaths() error {
	// Check if the directory exists
	info, err := os.Stat(fusionDataPath)
	if err != nil {
		if os.IsNotExist(err) {
			// Directory does not exist; create it with mode 0777.
			if err := os.MkdirAll(fusionDataPath, 0777); err != nil {
				return fmt.Errorf("failed to create data directory: %v", err)
			}
			// Retrieve info after creation.
			info, err = os.Stat(fusionDataPath)
			if err != nil {
				return fmt.Errorf("failed to stat data directory after creation: %v", err)
			}
		} else {
			return fmt.Errorf("failed to stat audio directory: %v", err)
		}
	} else if !info.IsDir() {
		// The path exists but is not a directory.
		return fmt.Errorf("%s exists but is not a directory", fusionDataPath)
	}

	// Check if the directory has the desired permissions (0777).
	currentPerm := info.Mode().Perm()
	if currentPerm != 0777 {
		if err := os.Chmod(fusionDataPath, 0777); err != nil {
			return fmt.Errorf("failed to set permissions on data directory: %v", err)
		}
	}

	return nil
}

// initTimerManager initializes the timer manager.
func initTimerManager() *timers.TimerManager {
	timerManager := timers.NewTimerManager("tasks.json", "history.json")
	if err := timerManager.Start(); err != nil {
		logging.GetLogger().Fatal("Error starting TimerManager: %v", err)
	}
	return timerManager
}

// startMetricsServer starts the metrics HTTP server.
func startMetricsServer(port int, metrics *cluster.MetricsCollector) *http.Server {
	metricsServer := &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: setupMetricsRoutes(metrics),
	}

	go func() {
		logger := logging.GetLogger()
		logger.Info("Starting metrics server on :%d", port)
		if err := metricsServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Metrics server failed: %v", err)
		}
	}()

	return metricsServer
}

// initBLEServer initializes the Bluetooth server.
func initBLEServer() *network.BLEServer {

	logger := logging.GetLogger()

	bleServer, err := network.NewBLEServer(bleServiceUUID, bleCharacterUUID)
	if err != nil {
		logger.Error("Failed to create BLE server: %v", err)
		return nil
	}

	logger.Info("BLE server initialized: %s %s", bleServiceUUID, bleCharacterUUID)

	return bleServer
}

// initUDPServer initializes the UDP server.
func initUDPServer(port string, handler *server.Handler) *network.UDPServer {

	logger := logging.GetLogger()

	udpServer, err := network.NewUDPServer(port, handler)
	if err != nil {
		logger.Fatal("Failed to create UDP server: %v", err)
	}

	handler.AddBroadcaster(udpServer)
	udpServer.Start()
	return udpServer
}

// startAPIServer starts the main HTTP API server
func startAPIServer(port string, wg *sync.WaitGroup) {
	defer wg.Done()

	logger := logging.GetLogger()
	logger.Info("Starting API server on %s", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		logger.Fatal("API server failed: %v", err)
	}
}

// registerEndpoint registers a handler and tracks the endpoint.
func registerEndpoint(pattern string, handlerFunc http.HandlerFunc) {
	endpoints = append(endpoints, pattern)
	http.HandleFunc(pattern, handlerFunc)
}

func main() {

	parseFlags()

	logger := initLogging(nodeName, verbose)
	defer logger.Close()

	err := initDataPaths()
	if err != nil {
		logger.Fatal("Failed to create data paths: %v", err)
	}

	stateManager := initStateManager(nodeName)

	persistence, err := initPersistence(configDataPath, stateManager)
	if err != nil {
		logger.Fatal("Failed to initialize persistence: %v", err)
	}
	persistence.LoadState()

	updater := server.NewUpdater()

	clusterList, err := initCluster(nodeName, bindAddr, bindPort, joinAddr, stateManager, persistence, server.NewUpdater())
	if err != nil {
		logger.Fatal("Failed to initialize cluster: %v", err)
	}

	timerManager := initTimerManager()
	defer timerManager.Stop()

	metricsCollector := cluster.NewMetricsCollector(clusterList, stateManager)

	metricsServer := startMetricsServer(metricsPort, metricsCollector)
	defer metricsServer.Shutdown(context.Background())

	connectionHandler := server.NewHandler(clusterList, stateManager, persistence, updater)

	if enableBLE {
		bleServer := initBLEServer()
		if bleServer == nil {
			logger.Info("Bluetooth not available. Continuing with initialization.")
		} else {
			defer bleServer.Stop()
		}
	}

	udpServer := initUDPServer(api.UDPPort, connectionHandler)
	defer udpServer.Stop()

	configServer := server.NewConfigServer(nodeName, connectionHandler, clusterList)

	setupHTTPRoutes(configServer, metricsCollector, verbose)
	setupTimerRoutes(timerManager, verbose)

	connectionHandler.SetEndpoints(endpoints)

	var wg sync.WaitGroup
	wg.Add(1)

	go startAPIServer(api.HTTPPort, &wg)

	time.Sleep(100 * time.Millisecond)
	logger.Info("%s is ALIVE and RUNNING", nodeName)
	logger.Info("Version: %s Commit: %s Build Time: %s", Version, Commit, BuildTime)

	wg.Wait()
}
