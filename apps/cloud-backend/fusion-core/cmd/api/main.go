// @title Fusion Cloud Backend API
// @version 1.0
// @description This is the Fusion Cloud Backend API server providing comprehensive role-based access control, user management, and project management capabilities.
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @BasePath /api/v1
// @schemes http https
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/docs"
	api "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	serverapi "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/api"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"

	"go.uber.org/zap"

	projectdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project/db"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/auth"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"

	authZero "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/auth/authzero"
)

func main() {
	ctx := context.Background()

	// Parse the flags
	envFile := flag.String("c", ".env", "config environment file")
	envName := flag.String("e", "local", "application environment (e.g. local, dev, staging, prod)")
	flag.Parse()

	// Check for environment variable first, then fallback to command line flag
	actualEnvName := *envName
	if envFromVar := os.Getenv("FUSION_ENVIRONMENT"); envFromVar != "" {
		actualEnvName = envFromVar
	}

	env := environment.New(environment.DefaultLoadLookuper)

	if actualEnvName == "local" {
		fmt.Println("Loading environment from file:", *envFile)
		if err := env.Load(*envFile); err != nil {
			fmt.Printf("Error loading environment file %s: %v\n", *envFile, err)
			os.Exit(1)
		}
		fmt.Println("Environment loaded from file successfully")
	} else {
		fmt.Printf("Running in %s environment, loading from environment variables\n", actualEnvName)
	}

	// Initialize configuration service
	configSVC, err := config.NewService(env)
	if err != nil {
		fmt.Printf("Failed to initialize config service: %v\n", err)
		panic(err)
	}

	// Load API configuration
	cfg, err := serverapi.NewAPIConfig(configSVC)
	if err != nil {
		fmt.Printf("Failed to load API config: %v\n", err)
		panic(err)
	}

	// Initialize dual loggers with lumberjack rotation
	loggerConfig := log.DefaultLoggerConfig()
	loggerConfig.Mode = cfg.Server.LogLevel
	if cfg.Server.LogDir != "" {
		loggerConfig.LogDir = cfg.Server.LogDir
	}

	loggers, err := log.NewLoggers(loggerConfig)
	if err != nil {
		panic(fmt.Errorf("failed to initialize loggers: %w", err))
	}

	// // Set host dynamically from configuration
	docs.SwaggerInfo.Host = cfg.Server.SwaggerHost

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
		loggers.AppLogger.Fatal("Failed to connect to the database", zap.Error(err))
	}

	loggers.AppLogger.Info("Database connection established successfully")

	//Initialize Product DB Service
	productDBSvc := productdb.NewService(pgs, loggers.AppLogger)
	if productDBSvc == nil {
		loggers.AppLogger.Fatal("Failed to initialize product database service")
	}
	loggers.AppLogger.Info("Initialized Product DB Service.")
	validationCfg, err := configSVC.Validation()
	if err != nil {
		loggers.AppLogger.Fatal("Failed to get validation config", zap.Error(err))
	}

	processingCfg, err := configSVC.Processing()
	if err != nil {
		loggers.AppLogger.Fatal("Failed to get processing config", zap.Error(err))
	}

	s3Handler, err := cloudfs.NewS3Client(ctx, cfg.S3.Region)
	if err != nil {
		loggers.AppLogger.Fatal("Failed to initialize S3 client", zap.Error(err))
	}
	loggers.AppLogger.Info("Initialized S3 client")

	//Initialize Product Service (now includes sync functionality)
	productSVC := product.NewService(productDBSvc, validationCfg.DefaultVersion, validationCfg, processingCfg, s3Handler, loggers.AppLogger)
	if productSVC == nil {
		loggers.AppLogger.Fatal("Failed to initialize product service")
	}
	loggers.AppLogger.Info("Initialized Product Service.")

	// Initialize Project DB Service
	projectDBSvc := projectdb.NewService(pgs)
	if projectDBSvc == nil {
		loggers.AppLogger.Fatal("Failed to initialize project service")
	}

	//Initialize Project Service
	projectSVC := project.NewService(projectDBSvc, s3Handler.Bucket(cfg.S3.ProjectBucket))
	if projectSVC == nil {
		loggers.AppLogger.Fatal("Failed to initialize project service")
	}
	loggers.AppLogger.Info("Initialized Project Service.")
	// Initialize User DB Service
	userDBSvc := userdb.NewService(pgs)
	if userDBSvc == nil {
		loggers.AppLogger.Fatal("Failed to initialize user service")
	}
	loggers.AppLogger.Info("Initialized User DB Service.")

	// Initialize User Service
	userSVC := user.NewService(userDBSvc)
	if userSVC == nil {
		loggers.AppLogger.Fatal("Failed to initialize user service")
	}
	loggers.AppLogger.Info("Initialized User Service.")

	// Initialize Auth0 Service
	authZeroSVC := authZero.NewService(cfg.AuthZero, loggers.AppLogger)
	if authZeroSVC == nil {
		loggers.AppLogger.Fatal("Failed to initialize auth0 service")
	}
	loggers.AppLogger.Info("Initialized Auth0 Service.")

	// Initialize Auth Service
	authSVC := auth.NewService(authZeroSVC)
	if authSVC == nil {
		loggers.AppLogger.Fatal("Failed to initialize auth service")
	}
	loggers.AppLogger.Info("Initialized Auth Service.")

	// Initialize Auth middleware using Auth service (consolidates all authentication functionality)
	authMiddleware := middleware.NewAuth0Middleware(authSVC)
	loggers.AppLogger.Info("Initialized Auth0 middleware")

	// Initialize API Server (with configurable host and port)
	server, err := api.New(&api.Config{
		Host: cfg.Server.APIHost,
		Port: cfg.Server.APIPort,
	}, productSVC, projectSVC, userSVC, authSVC, authMiddleware, loggers)
	if err != nil {
		loggers.AppLogger.Fatal(fmt.Sprintf("Error while initializing API: %v", err))
	}

	loggers.AppLogger.Info("Initialized the API.",
		zap.String("host", cfg.Server.APIHost),
		zap.String("port", cfg.Server.APIPort))
	// Setup graceful shutdown
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	shutdownChan := make(chan os.Signal, 1)
	signal.Notify(shutdownChan, syscall.SIGINT, syscall.SIGTERM)

	// Start server in goroutine
	serverDoneChan := make(chan error, 1)
	go func() {
		loggers.AppLogger.Info("Starting server...")
		err := server.Start(ctx)
		serverDoneChan <- err // Send result regardless of error or nil
	}()

	// Wait for shutdown signal or server error
	select {
	case <-shutdownChan:
		loggers.AppLogger.Info("Received shutdown signal, initiating graceful shutdown...")
		cancel()

		// Give server time to shutdown gracefully
		shutdownTimeout := time.NewTimer(30 * time.Second)
		defer shutdownTimeout.Stop()

		select {
		case err := <-serverDoneChan:
			if err != nil {
				loggers.AppLogger.Error("Server shutdown with error", zap.Error(err))
			} else {
				loggers.AppLogger.Info("Server shutdown completed successfully")
			}
		case <-shutdownTimeout.C:
			loggers.AppLogger.Info("Server shutdown timeout exceeded - forcing exit")
		}

	case err := <-serverDoneChan:
		if err != nil {
			loggers.AppLogger.Error("Server error", zap.Error(err))
		} else {
			loggers.AppLogger.Info("Server exited normally")
		}
		cancel()
	}

	loggers.AppLogger.Info("Application stopped gracefully")
}
