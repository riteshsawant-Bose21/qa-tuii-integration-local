// @title Fusion Cloud Backend API
// @version 1.0
// @description This is the Fusion Cloud Backend API server.

// @host localhost:8020
// @BasePath /api/v1
// @schemes http https
package main

import (
	"fmt"
	inbuiltlog "log"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"go.uber.org/zap"

	projectdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"

	_ "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/docs"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
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

	// Initaialize s3 client

	//Initialize Product DB Service
	productDBSvc := productdb.NewService(pgs)
	if productDBSvc == nil {
		logger.Fatal("Failed to initialize product database service")
	}
	logger.Info("Initialized Product DB Service.")

	// Initialize Project DB Service
	projectDBSvc := projectdb.NewService(pgs)
	if projectDBSvc == nil {
		logger.Fatal("Failed to initialize project service")
	}

	//Initialize Product Service
	productSVC := product.NewService(productDBSvc)
	if productSVC == nil {
		logger.Fatal("Failed to initialize product service")
	}
	logger.Info("Initialized Product Service.")

	projectSVC := project.NewService(projectDBSvc)
	if projectSVC == nil {
		logger.Fatal("Failed to initialize project service")
	}
	logger.Info("Initialized Project Service.")

	engine := gin.Default()

	// Setup Swagger
	engine.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Initialize API Service
	apiSvc, err := api.New(engine, productSVC, projectSVC)
	if err != nil {
		logger.Fatal(fmt.Sprintf("Error while initializing API: %v", err))
	}
	logger.Info("Initialized the API.")

	Host := "localhost"
	Port := "8020"

	// Start server
	addr := fmt.Sprintf("%s:%s", Host, Port)
	logger.Info(fmt.Sprintf("Starting HTTP server at %s...", addr))

	if err := apiSvc.Engine().Run(fmt.Sprintf("%s:%s", Host, Port)); err != nil {
		logger.Fatal(fmt.Sprintf("Server error: %s", err))
	}
}
