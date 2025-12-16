// @title Fusion Cloud Backend API
// @version 1.0
// @description This is the Fusion Cloud Backend API server.

// @host localhost:8080
// @BasePath /api/v1
// @schemes http https
package main

import (
	"context"
	"flag"
	"fmt"
	inbuiltlog "log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	serverapi "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/api"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"go.uber.org/zap"

	// projectdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project/db"

	_ "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/docs"
)

func main() {
	// ctx := context.Background()

	// Load logger
	logger, err := log.NewProduction() // Move it to cmd parallel
	if err != nil {
		inbuiltlog.Fatalf("Error while initializing the logger: %v\n", err)
	}

	// Parse the flags
	envFile := flag.String("c", ".env", "config environment file")
	envName := flag.String("e", "local", "application environment (e.g. local, dev, staging, prod)")
	flag.Parse()

	env := environment.New(environment.DefaultLoadLookuper)
	logger.Info("Loading environment file", zap.String("file", *envFile))
	if *envName == "local" {
		if err := env.Load(*envFile); err != nil {
			logger.Fatal("error loading environment vars", zap.String("file", *envName), zap.Error(err))
		}
	}

	// Initialize configuration service
	configSVC, err := config.NewService(env)
	if err != nil {
		logger.Fatal("Failed to initialize config service", zap.Error(err))
	}

	// Load API configuration
	cfg, err := serverapi.NewAPIConfig(configSVC)
	if err != nil {
		logger.Fatal("Failed to load API config", zap.Error(err))
	}

	// Initialize the database connection.
	pgs, err := sql.New(
		sql.PostgresOpener,
		cfg.Postgres.Host,     // host
		cfg.Postgres.Port,     // port
		cfg.Postgres.User,     // user
		cfg.Postgres.Password, // password
		cfg.Postgres.Database, // instance (example: database name)
		cfg.Postgres.SSLMode,  // sslmode
	)
	if err != nil {
		logger.Fatal("Failed to connect to the database", zap.Error(err))
	}

	logger.Info("Database connection established successfully")

	//Initialize Product DB Service
	productDBSvc := productdb.NewService(pgs, logger.JobSyncLog())
	if productDBSvc == nil {
		logger.Fatal("Failed to initialize product database service")
	}
	logger.Info("Initialized Product DB Service.")

	// Initialize Project DB Service
	// projectDBSvc := projectdb.NewService(pgs)
	// if projectDBSvc == nil {
	// 	logger.Fatal("Failed to initialize project service")
	// }

	validationCfg, err := configSVC.Validation()
	if err != nil {
		logger.Fatal("Failed to get validation config", zap.Error(err))
	}

	processingCfg, err := configSVC.Processing()
	if err != nil {
		logger.Fatal("Failed to get processing config", zap.Error(err))
	}

	//Initialize Product Service (now includes sync functionality)
	productSVC := product.NewService(productDBSvc, validationCfg.DefaultVersion, validationCfg, processingCfg)
	if productSVC == nil {
		logger.Fatal("Failed to initialize product service")
	}
	logger.Info("Initialized Product Service.")

	//Initialize Project Service
	// projectSVC := project.NewService(projectDBSvc)
	// if projectSVC == nil {
	// 	logger.Fatal("Failed to initialize project service")
	// }
	// logger.Info("Initialized Project Service.")

	// Initialize API Server
	server, err := api.New(&api.Config{
		Host: cfg.Server.APIHost,
		Port: cfg.Server.APIPort,
	}, productSVC /*, projectSVC --- IGNORE --- */)
	if err != nil {
		logger.Fatal(fmt.Sprintf("Error while initializing API: %v", err))
	}
	logger.Info("Initialized the API.")

	// Setup graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	shutdownChan := make(chan os.Signal, 1)
	signal.Notify(shutdownChan, syscall.SIGINT, syscall.SIGTERM)

	// Start server in goroutine
	serverErrChan := make(chan error, 1)
	go func() {
		logger.Info("Starting server...")
		if err := server.Start(ctx); err != nil {
			serverErrChan <- err
		}
	}()

	// Wait for shutdown signal or server error
	select {
	case <-shutdownChan:
		logger.Info("Received shutdown signal, initiating graceful shutdown...")
		cancel()

		// Give server time to shutdown gracefully
		shutdownTimeout := time.NewTimer(1 * time.Second)
		defer shutdownTimeout.Stop()

		select {
		case <-serverErrChan:
			logger.Info("Server shutdown completed")
		case <-shutdownTimeout.C:
			logger.Info("Server shutdown timeout exceeded")
		}

	case err := <-serverErrChan:
		if err != nil {
			logger.Error("Server error", zap.Error(err))
		}
		cancel()
	}

	logger.Info("Application stopped gracefully")

}
