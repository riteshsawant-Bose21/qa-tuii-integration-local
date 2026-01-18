package main

import (
	"context"
	"flag"
	inbuiltlog "log"
	"os"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"go.uber.org/zap"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	serverSync "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
)

// main supports Lambda, CLI, and HTTP server execution
func main() {
	// Load logger
	logger, err := log.NewProduction()
	if err != nil {
		inbuiltlog.Fatalf("Error while initializing the logger: %v\n", err)
	}

	// Parse the flags
	envFile := flag.String("c", ".env", "config environment file")
	envName := flag.String("e", "local", "application environment (e.g. local, dev, staging, prod)")

	// CLI mode flags
	syncType := flag.String("type", "", "Sync type: 'product' or 'price' (required)")
	syncOperation := flag.String("operation", "manual_sync", "Sync operation: 'manual_sync' or 'scheduled_sync' (default: manual_sync)")
	sourceType := flag.String("source", "", "Source type: 'local' or 's3' (required)")
	filePath := flag.String("path", "", "File path (required for local source)")
	bucket := flag.String("bucket", "", "S3 bucket name (required for s3 source)")
	key := flag.String("key", "", "S3 object key (required for s3 source)")
	region := flag.String("region", "", "AWS region (optional, uses config default)")
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

	// Load Sync configuration
	syncCfg, err := serverSync.NewSyncConfig(configSVC)
	if err != nil {
		logger.Fatal("Failed to load Sync config", zap.Error(err))
	}

	// Initialize the database connection
	pgs, err := sql.New(
		sql.PostgresOpener,
		syncCfg.Postgres.Host,
		syncCfg.Postgres.Port,
		syncCfg.Postgres.User,
		syncCfg.Postgres.Password,
		syncCfg.Postgres.Database,
		syncCfg.Postgres.SSLMode,
	)
	if err != nil {
		logger.Fatal("Failed to connect to the database", zap.Error(err))
	}
	defer pgs.Close()

	logger.Info("Database connection established successfully")

	// db := &syncDB.Database{DB: pgs}

	// CLI mode - validate required flags
	if *syncType == "" || *sourceType == "" {
		flag.Usage()
		logger.Fatal("Error: --type and --source are required (or use --server for HTTP mode)")
	}

	if *sourceType == "local" && *filePath == "" {
		logger.Fatal("Error: --path is required for local source")
	}

	if *sourceType == "s3" && (*bucket == "" || *key == "") {
		logger.Fatal("Error: --bucket and --key are required for s3 source")
	}

	// Initialize sync services
	logger.Info("Initializing sync services...")

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

	syncRequestRegion := *region
	if syncRequestRegion == "" {
		syncRequestRegion = syncCfg.S3.Region
	}

	syncRequest := &types.SyncRequest{
		SyncType:         *syncType,
		SyncOperation:    *syncOperation,
		SourceType:       *sourceType,
		FilePath:         *filePath,
		S3Bucket:         *bucket,
		S3Key:            *key,
		Region:           syncRequestRegion,
		EnableValidation: true,
	}

	result, err := productSVC.Execute(context.Background(), syncRequest)
	if err != nil {
		logger.Fatal("Sync execution failed", zap.Error(err))
	}

	// Print results
	logger.Info("Sync completed successfully",
		zap.String("sync_type", *syncType),
		zap.Int("total_items", result.TotalItems),
		zap.Int("successful", result.Successful),
		zap.Int("failed", result.Failed),
		zap.Duration("duration", result.Duration),
	)

	if result.Failed > 0 {
		logger.Warn("Some items failed",
			zap.Int("failed_count", result.Failed),
			zap.Strings("validation_warnings", result.ValidationWarnings),
		)
		os.Exit(1)
	}
}
