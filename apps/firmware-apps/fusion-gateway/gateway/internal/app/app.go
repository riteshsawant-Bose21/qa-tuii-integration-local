package app

import (
	"bufio"
	"context"
	"fmt"
	"gateway/internal/api"
	"fusion-services-core/logging"
	"gateway/internal/server"
	"gateway/internal/server/handler"
	"gateway/internal/version"
	"net"
	"net/http"
	"runtime/debug"
	"sync"
	"time"

	"github.com/gorilla/mux"
)

const (
	startupWaitDelay = 100
)

type App struct {
	Logger            *logging.Logger
	ConnectionHandler *handler.Handler
	Gateway           *server.FusionGateway
	config            *api.AppConfig
	publicRouter      *mux.Router
	privateRouter     *mux.Router
}

// NewApp is a factory function to set up the application
func NewApp(config *api.AppConfig) *App {

	logger := initLogging(config)

	connectionHandler := handler.NewHandler(config)
	gateway := server.NewFusionGateway(config.NodeName, connectionHandler)

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
		ConnectionHandler: connectionHandler,
		Gateway:           gateway,
		config:            config,
		publicRouter:      publicRouter,
		privateRouter:     privateRouter,
	}

	return app
}

// Close shuts down all components gracefully.
func (app *App) Close() {
	app.Logger.Close()
}

func (app *App) setupPublicRoutes() {
	proxy, err := server.NewReverseProxy(app.config.UpstreamPublicURL)
	if err != nil {
		app.Logger.Fatal("Invalid public upstream URL %q: %v", app.config.UpstreamPublicURL, err)
	}

	// Forward all public requests to the upstream.
	app.publicRouter.PathPrefix("/").Handler(proxy)
}

func (app *App) setupPrivateRoutes() {
	proxy, err := server.NewReverseProxy(app.config.UpstreamPrivateURL)
	if err != nil {
		app.Logger.Fatal("Invalid private upstream URL %q: %v", app.config.UpstreamPrivateURL, err)
	}

	// Forward all private/admin requests to the upstream.
	app.privateRouter.PathPrefix("/").Handler(proxy)
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

	wg.Wait()
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
