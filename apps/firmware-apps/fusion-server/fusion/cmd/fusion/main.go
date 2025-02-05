package main

import (
	"context"
	"flag"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"fusion/internal/cluster"
	"fusion/internal/logging"
	"fusion/internal/network"
	"fusion/internal/server"
	"fusion/internal/timers"

	"github.com/hashicorp/memberlist"
)

var (
	nodeName    string
	bindAddr    string
	bindPort    int
	joinAddr    string
	metricsPort *int
	verbose     *bool
)

const (
	configDataPath        = "/var/lib/fusion/config.json"
	stateDumpInterval     = 30
	analogControllerPort  = ":8002"
	digitalControllerPort = ":8003"
	httpPort              = ":8080"
	udpPort               = ":7947"
	serialPort            = "/tmp/ttyFusionServer"
	baudRate              = 9600
)

func setupHTTPRoutes(server *server.ConfigServer, metrics *cluster.MetricsCollector, verbose bool) {
	http.HandleFunc("/", withLogging(server.HandleRoot, "root", verbose))
	http.HandleFunc("/dump", withLogging(server.DumpState, "dump", verbose))
	http.HandleFunc("/endpoints", withLogging(server.GetEndpoints, "endpoints", verbose))
	http.HandleFunc("/getValue", withLogging(server.GetValue, "getValue", verbose))
	http.HandleFunc("/setValue", withLogging(server.SetValue, "setValue", verbose))
	http.HandleFunc("/updateValue", withLogging(server.UpdateValue, "updateValue", verbose))
	http.HandleFunc("/clear", withLogging(server.ClearAllData, "clear", verbose))
	http.HandleFunc("/updateBinary", withLogging(server.UpdateBinary, "updateBinary", verbose))
	http.HandleFunc("/rollbackBinary", withLogging(server.RollbackBinary, "rollbackBinary", verbose))
	http.HandleFunc("/ws", withWebSocketMetrics(server.HandleWebSocket, metrics, verbose))
}

func setupTimerRoutes(manager *timers.TimerManager, verbose bool) {
	http.HandleFunc("/tasks", withLogging(manager.ListTasksHandler, "tasks", verbose))
	http.HandleFunc("/tasks/add", withLogging(manager.AddTaskHandler, "addTask", verbose))
	http.HandleFunc("/tasks/update", withLogging(manager.UpdateTaskHandler, "updateTask", verbose))
	http.HandleFunc("/tasks/remove", withLogging(manager.RemoveTaskHandler, "removeTask", verbose))
	http.HandleFunc("/tasks/history", withLogging(manager.ExecutionHistoryHandler, "history", verbose))
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
	flag.StringVar(&nodeName, "name", "", "Node name")
	flag.StringVar(&bindAddr, "addr", "0.0.0.0", "Bind address")
	flag.IntVar(&bindPort, "port", 7946, "Bind port")
	flag.StringVar(&joinAddr, "join", "", "Address to join cluster (comma-separated)")
	metricsPort = flag.Int("metrics-port", 9090, "Metrics server port")
	verbose = flag.Bool("verbose", false, "Verbose output")
	flag.Parse()

	if nodeName == "" {
		logging.GetLogger().Fatal("Node name is required")
	}
}

// initLogging initializes the logging system.
func initLogging(nodeName string) *logging.Logger {
	logging.InitLogger(logging.LogConfig{
		NodeName:    nodeName,
		LogDir:      "/var/log/fusion",
		MaxFileSize: 100,
		MaxFiles:    5,
		LogLevel:    logging.DEBUG,
	})
	return logging.GetLogger()
}

// initStateManager initializes the state manager.
func initStateManager(nodeName string) *server.StateManager {
	stateManager := server.NewStateManager(nodeName)
	if *verbose {
		stateManager.StartStateDumping(stateDumpInterval * time.Second)
	}
	return stateManager
}

// initPersistence initializes the persistence layer.
func initPersistence(configPath string, stateManager *server.StateManager) *server.ConfigPersistence {
	persistence := server.NewConfigPersistence(configPath, stateManager, true)
	persistence.LoadState()
	return persistence
}

// initCluster initializes the cluster memberlist.
func initCluster(nodeName, bindAddr string, bindPort int, joinAddr string, stateManager *server.StateManager, persistence *server.ConfigPersistence, updater *server.Updater) (*memberlist.Memberlist, error) {
	var joinAddrs []string
	if joinAddr != "" {
		joinAddrs = strings.Split(joinAddr, ",")
	}

	list, err := cluster.CreateMemberlist(nodeName, bindAddr, bindPort, joinAddrs, stateManager, persistence, updater, *verbose)
	if err != nil {
		return nil, fmt.Errorf("failed to create memberlist: %w", err)
	}

	if *verbose {
		cluster.MonitorClusterState(list)
		cluster.StartHealthCheck(list)
		cluster.StartStateVerification(list, stateManager)
	}

	return list, nil
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

// initUDPServer initializes the UDP server.
func initUDPServer(port string, handler *server.Handler) *network.UDPServer {

	udpServer, err := network.NewUDPServer(port, handler)
	if err != nil {
		logging.GetLogger().Error("Failed to create UDP server: %v", err)
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

func main() {
	logger := initLogging(nodeName)
	defer logger.Close()

	parseFlags()

	stateManager := initStateManager(nodeName)
	persistence := initPersistence(configDataPath, stateManager)
	updater := server.NewUpdater()

	clusterList, err := initCluster(nodeName, bindAddr, bindPort, joinAddr, stateManager, persistence, server.NewUpdater())
	if err != nil {
		logger.Error("Failed to initialize cluster: %v", err)
	}

	timerManager := initTimerManager()
	defer timerManager.Stop()

	metricsCollector := cluster.NewMetricsCollector(clusterList, stateManager)

	metricsServer := startMetricsServer(*metricsPort, metricsCollector)
	defer metricsServer.Shutdown(context.Background())

	connectionHandler := server.NewHandler(clusterList, stateManager, persistence, updater)

	udpServer := initUDPServer(udpPort, connectionHandler)
	defer udpServer.Stop()

	configServer := server.NewConfigServer(nodeName, connectionHandler)

	setupHTTPRoutes(configServer, metricsCollector, *verbose)
	setupTimerRoutes(timerManager, *verbose)

	var wg sync.WaitGroup
	wg.Add(1)

	go startAPIServer(httpPort, &wg)

	time.Sleep(100 * time.Millisecond)
	logger.Info("%s is ALIVE and RUNNING", nodeName)

	wg.Wait()
}
