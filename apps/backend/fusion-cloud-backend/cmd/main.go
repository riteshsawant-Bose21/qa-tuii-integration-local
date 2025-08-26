package main

import (
	"fmt"
	inbuiltlog "log"

	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/api"
	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/log"

	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion/product/db"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/storage/sql"
	"go.uber.org/zap"
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

	// Initaialize Product Service
	//DB first
	productDBSvc := productdb.NewService(pgs)
	if productDBSvc == nil {
		logger.Fatal("Failed to initialize product database service")
	}
	logger.Info("Initialized Product DB Service.")

	// Service
	productSVC := product.NewService(productDBSvc)
	if productSVC == nil {
		logger.Fatal("Failed to initialize product service")
	}
	logger.Info("Initialized Product Service.")

	// Initialize API (handlers)
	apiSvc, err := api.New(productSVC)
	if err != nil {
		logger.Fatal(fmt.Sprintf("Error while initializing API: %v", err))
	}
	logger.Info("Initialized the API.")

	Host := "localhost"
	Port := "8020"

	// Setup Swagger
	// Start server
	addr := fmt.Sprintf("%s:%s", Host, Port)
	logger.Info(fmt.Sprintf("Starting HTTP server at %s...", addr))

	if err := apiSvc.Engine().Run(fmt.Sprintf("%s:%s", Host, Port)); err != nil {
		logger.Fatal(fmt.Sprintf("Server error: %s", err))
	}

	// if err := http.ListenAndServe(addr, router); err != nil {
	// 	logger.Fatal(fmt.Sprintf("Server error: %s", err))
	// }
}
