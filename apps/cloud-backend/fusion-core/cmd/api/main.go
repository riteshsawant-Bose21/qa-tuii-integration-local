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
	inbuiltlog "log"
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

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
)

func main() {
	ctx := context.Background()

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

	// // Set host dynamically from configuration
	docs.SwaggerInfo.Host = cfg.Server.SwaggerHost

	// Load general application configuration
	appConfig, err := config.Load()
	if err != nil {
		logger.Fatal("Failed to load application config", zap.Error(err))
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

	validationCfg, err := configSVC.Validation()
	if err != nil {
		logger.Fatal("Failed to get validation config", zap.Error(err))
	}

	processingCfg, err := configSVC.Processing()
	if err != nil {
		logger.Fatal("Failed to get processing config", zap.Error(err))
	}

	//Initialize Product Service (now includes sync functionality)
	productSVC := product.NewService(productDBSvc, validationCfg.DefaultVersion, validationCfg, processingCfg, logger.JobSyncLog())
	if productSVC == nil {
		logger.Fatal("Failed to initialize product service")
	}
	logger.Info("Initialized Product Service.")

	s3Handler, err := cloudfs.NewS3Client(ctx, cfg.S3.Region)

	if err != nil {
		logger.Fatal("Failed to initialize S3 client", zap.Error(err))
	}
	logger.Info("Initialized S3 client")

	// Initialize Project DB Service
	projectDBSvc := projectdb.NewService(pgs, logger)
	if projectDBSvc == nil {
		logger.Fatal("Failed to initialize project service")
	}

	//Initialize Project Service
	projectSVC := project.NewService(projectDBSvc, s3Handler.Bucket(cfg.S3.ProjectBucket))
	if projectSVC == nil {
		logger.Fatal("Failed to initialize project service")
	}
	logger.Info("Initialized Project Service.")

	// Initialize User DB Service
	userDBSvc := userdb.NewService(pgs)
	if userDBSvc == nil {
		logger.Fatal("Failed to initialize user service")
	}
	logger.Info("Initialized User DB Service.")

	// Initialize User Service
	userSVC := user.NewService(userDBSvc)
	if userSVC == nil {
		logger.Fatal("Failed to initialize user service")
	}
	logger.Info("Initialized User Service.")

	// Initialize Role Management Service
	roleManagementSvc := userdb.NewRoleManagementService(pgs)
	if roleManagementSvc == nil {
		logger.Fatal("Failed to initialize role management service")
	}
	logger.Info("Initialized Role Management Service.")

	// Initialize API Server (with configurable host and port)
	server, err := api.New(&api.Config{
		Host:        appConfig.Server.APIHost,
		Port:        appConfig.Server.APIPort,
		Auth0Domain: cfg.Auth0.Domain,
	}, productSVC, projectSVC, userSVC)
	if err != nil {
		logger.Fatal(fmt.Sprintf("Error while initializing API: %v", err))
	}
	logger.Info("Initialized the API.",
		zap.String("host", appConfig.Server.APIHost),
		zap.String("port", appConfig.Server.APIPort))

	// Setup graceful shutdown
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	shutdownChan := make(chan os.Signal, 1)
	signal.Notify(shutdownChan, syscall.SIGINT, syscall.SIGTERM)

	// Start server in goroutine
	serverDoneChan := make(chan error, 1)
	go func() {
		logger.Info("Starting server...")
		err := server.Start(ctx)
		serverDoneChan <- err // Send result regardless of error or nil
	}()

	// Wait for shutdown signal or server error
	select {
	case <-shutdownChan:
		logger.Info("Received shutdown signal, initiating graceful shutdown...")
		cancel()

		// Give server time to shutdown gracefully
		shutdownTimeout := time.NewTimer(30 * time.Second)
		defer shutdownTimeout.Stop()

		select {
		case err := <-serverDoneChan:
			if err != nil {
				logger.Error("Server shutdown with error", zap.Error(err))
			} else {
				logger.Info("Server shutdown completed successfully")
			}
		case <-shutdownTimeout.C:
			logger.Info("Server shutdown timeout exceeded - forcing exit")
		}

	case err := <-serverDoneChan:
		if err != nil {
			logger.Error("Server error", zap.Error(err))
		} else {
			logger.Info("Server exited normally")
		}
		cancel()
	}

	logger.Info("Application stopped gracefully")

}
