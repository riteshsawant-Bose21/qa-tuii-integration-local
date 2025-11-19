// @title Fusion Cloud Backend API
// @version 1.0
// @description This is the Fusion Cloud Backend API server providing comprehensive role-based access control, user management, and project management capabilities.
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.url http://www.swagger.io/support
// @contact.email support@swagger.io

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8020
// @BasePath /api/v1
// @schemes http https

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
package main

import (
	"context"
	"fmt"
	inbuiltlog "log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/id"
	// "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	// productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"go.uber.org/zap"

	// "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	// projectdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project/db"

	_ "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/docs"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
)

func main() {
	// ctx := context.Background()

	// Load logger
	logger, err := log.NewProduction() // Move it to cmd parallel

	if err != nil {
		inbuiltlog.Fatalf("Error while initializing the logger: %v\n", err)
	}

	logger.Info(fmt.Sprintf("Starting Fusion Cloud Backend in %s mode", "production"))

	// Parse the flags

	// Load the configuration from the provided .env file.

	// Initialize the database connection.
	pgs, err := sql.New(
		sql.PostgresOpener,
		"127.0.0.1",    // host
		"5432",         // port
		"fusion_cloud", // user
		"bose123",      // password
		"fusion_cloud", // instance (example: database name)
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
	// productDBSvc := productdb.NewService(pgs)
	// if productDBSvc == nil {
	// 	logger.Fatal("Failed to initialize product database service")
	// }
	// logger.Info("Initialized Product DB Service.")

	// Initialize Project DB Service
	// projectDBSvc := projectdb.NewService(pgs)
	// if projectDBSvc == nil {
	// 	logger.Fatal("Failed to initialize project service")
	// }

	// Initialize User DB Service
	userDBSvc := userdb.NewService(pgs)
	if userDBSvc == nil {
		logger.Fatal("Failed to initialize user service")
	}
	logger.Info("Initialized User DB Service.")

	// Initialize Role Management Service
	roleManagementSvc := userdb.NewRoleManagementService(pgs)
	if roleManagementSvc == nil {
		logger.Fatal("Failed to initialize role management service")
	}
	logger.Info("Initialized Role Management Service.")

	//Initialize Product Service
	// productSVC := product.NewService(productDBSvc, idSVC)
	// if productSVC == nil {
	// 	logger.Fatal("Failed to initialize product service")
	// }
	// logger.Info("Initialized Product Service.")

	//Initialize Project Service
	// projectSVC := project.NewService(projectDBSvc)
	// if projectSVC == nil {
	// 	logger.Fatal("Failed to initialize project service")
	// }
	// logger.Info("Initialized Project Service.")

	// Initialize User Service
	userSVC := user.NewService(userDBSvc)
	if userSVC == nil {
		logger.Fatal("Failed to initialize user service")
	}
	logger.Info("Initialized User Service.")

	// Initialize API Server
	server, err := api.New(&api.Config{
		Host:        "localhost",
		Port:        "8080",
		Auth0Domain: "id-dev.boseprofessional.com", // Auth0 domain
	}, userSVC, userDBSvc, roleManagementSvc)
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
