//	@title			Fusion Cloud Backend API
//	@version		1.0
//	@description	This is the Fusion Cloud Backend API server.

// @host		localhost:8080
// @BasePath	/api/v1
// @schemes	http https
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

	api "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	serverapi "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/api"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/id"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"go.uber.org/zap"

	// "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
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
	useSecretsManager := flag.Bool("secrets", false, "use AWS Secrets Manager for configuration (overrides USE_SECRETS_MANAGER env var)")
	flag.Parse()

	// Determine if we should use secrets manager
	useSecrets := *useSecretsManager || config.ParseUseSecretsManagerFlag()

	var configSVC *config.Service
	if useSecrets {
		logger.Info("Using AWS Secrets Manager for configuration (pure secrets mode)")

		// Always load .env file to get secret names and AWS region for secrets manager
		env := environment.New(environment.DefaultLoadLookuper)
		logger.Info("Loading environment file for secret names", zap.String("file", *envFile))
		if err := env.Load(*envFile); err != nil {
			logger.Warn("Failed to load environment file for secret names", zap.String("file", *envFile), zap.Error(err))
		}

		configSVC, err = config.NewWithSecretsManager(true, "")
		if err != nil {
			logger.Fatal("Failed to initialize config service with secrets manager", zap.Error(err))
		}
	} else {
		// Pure local environment variable loading
		env := environment.New(environment.DefaultLoadLookuper)

		// Only load .env file in local environment
		if *envName == "local" {
			logger.Info("Using local environment configuration (pure local mode)", zap.String("file", *envFile))
			if err := env.Load(*envFile); err != nil {
				logger.Fatal("error loading environment vars", zap.String("file", *envFile), zap.Error(err))
			}
		} else {
			logger.Info("Using environment variables (production mode without secrets)", zap.String("env", *envName))
		}

		// Initialize configuration service
		configSVC, err = config.NewService(env)
		if err != nil {
			logger.Fatal("Failed to initialize config service", zap.Error(err))
		}
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
		cfg.Postgres.SSLMode,  // ssl mode
	)
	if err != nil {
		logger.Fatal("Failed to connect to the database", zap.Error(err))
	}

	logger.Info("Database connection established successfully")

	// Initialize ID Service
	idSVC := id.NewService()
	if idSVC == nil {
		logger.Fatal("Failed to initialize ID service")
	}
	logger.Info("Initialized ID Service.")
	//Initialize Product DB Service
	productDBSvc := productdb.NewService(pgs)
	if productDBSvc == nil {
		logger.Fatal("Failed to initialize product database service")
	}
	logger.Info("Initialized Product DB Service.")

	// Initialize Project DB Service
	// projectDBSvc := projectdb.NewService(pgs)
	// if projectDBSvc == nil {
	// 	logger.Fatal("Failed to initialize project service")
	// }

	//Initialize Product Service
	productSVC := product.NewService(productDBSvc, idSVC)
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

	// Initialize API Server (with configurable host and port)
	server, err := api.New(&api.Config{
		Host: cfg.Server.APIHost,
		Port: cfg.Server.APIPort,
	}, productSVC, nil)
	if err != nil {
		logger.Fatal(fmt.Sprintf("Error while initializing API: %v", err))
	}
	logger.Info("Initialized the API.",
		zap.String("host", cfg.Server.APIHost),
		zap.String("port", cfg.Server.APIPort))

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
		shutdownTimeout := time.NewTimer(2 * time.Second)
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
