package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	inbuiltlog "log"
	"os"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"go.uber.org/zap"

	config "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	serversync "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync"
	syncDB "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync/db"
	syncSource "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync/source"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
)

// extractVersionFromJSON reads a JSON file and extracts the version field
func extractVersionFromJSON(filePath string) (string, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %w", err)
	}

	var jsonData map[string]interface{}
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return "", fmt.Errorf("failed to parse JSON: %w", err)
	}

	version, ok := jsonData["version"]
	if !ok {
		return "unknown", nil // default version if not found
	}

	versionStr, ok := version.(string)
	if !ok {
		return "unknown", nil // default version if not a string
	}

	return versionStr, nil
}

type syncHandlerAdapter struct {
	impl *syncSource.Service
}

func (s *syncHandlerAdapter) New(sourceType, sourcePath, s3Bucket, s3Key, region string) (serversync.DataSource, error) {
	ds, err := s.impl.New(sourceType, sourcePath, s3Bucket, s3Key, region)
	if err != nil {
		return nil, err
	}
	return &dataSourceAdapter{impl: ds}, nil
}

type dataSourceAdapter struct {
	impl syncSource.DataSource
}

func (d *dataSourceAdapter) ReadAll() ([]byte, error) { return d.impl.ReadAll() }
func (d *dataSourceAdapter) Close() error             { return d.impl.Close() }

// main supports Lambda, CLI, and HTTP server execution
func main() {
	// Load logger
	logger, err := log.NewProduction()
	if err != nil {
		inbuiltlog.Fatalf("Error while initializing the logger: %v\n", err)
	}

	// Parse the flags
	serverMode := flag.Bool("server", false, "Run as HTTP server")
	port := flag.String("port", "8081", "HTTP server port (only used with -server)")
	envFile := flag.String("c", ".env", "config environment file")
	envName := flag.String("e", "local", "application environment (e.g. local, dev, staging, prod)")
	useSecretsManager := flag.Bool("secrets", false, "use AWS Secrets Manager for configuration (overrides USE_SECRETS_MANAGER env var)")

	// CLI mode flags
	syncType := flag.String("type", "", "Sync type: 'product' or 'price' (required)")
	sourceType := flag.String("source", "", "Source type: 'local' or 's3' (required)")
	filePath := flag.String("path", "", "File path (required for local source)")
	bucket := flag.String("bucket", "", "S3 bucket name (required for s3 source)")
	key := flag.String("key", "", "S3 object key (required for s3 source)")
	region := flag.String("region", "", "AWS region (optional, uses config default)")
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

	// Load Sync configuration
	syncCfg, err := serversync.NewSyncConfig(configSVC)
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

	db := &syncDB.Database{DB: pgs}

	// HTTP Server Mode
	if *serverMode {
		// Use config values for server host, fall back to command line port
		serverHost := syncCfg.Server.APIHost
		serverPort := *port

		if err := handler.SetupHTTPServer(serverHost, serverPort, logger.Zap()); err != nil {
			logger.Fatal("Failed to start HTTP server", zap.Error(err))
		}
		return
	}

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

	// Create Product Service
	productService := syncDB.NewProductService(db)
	if productService == nil {
		logger.Fatal("Failed to initialize product service")
	}
	logger.Info("Initialized Product Service.")

	// Create Price Service
	priceService := syncDB.NewPriceService(db)
	if priceService == nil {
		logger.Fatal("Failed to initialize price service")
	}
	logger.Info("Initialized Price Service.")

	// Create Job Service
	jobService := syncDB.NewJobService(db, logger.Zap())
	if jobService == nil {
		logger.Fatal("Failed to initialize job service")
	}
	logger.Info("Initialized Job Service.")

	// Create source service adapter
	sourceServiceImpl := syncSource.NewService()
	sourceService := &syncHandlerAdapter{impl: sourceServiceImpl}

	// Create fusion sync service
	syncService := serversync.NewService(productService, priceService, jobService, sourceService)
	if syncService == nil {
		logger.Fatal("Failed to initialize sync service")
	}
	logger.Info("Initialized Sync Service.")

	jobRepo := jobService

	// Create data source
	awsRegion := *region
	if awsRegion == "" {
		awsRegion = syncCfg.AWS.Region
	}

	dataSource, err := sourceService.New(*sourceType, *filePath, *bucket, *key, awsRegion)
	if err != nil {
		logger.Fatal("Failed to create data source", zap.Error(err))
	}
	defer dataSource.Close()

	// Create sync job
	startTime := time.Now().UTC()
	syncOp := "manual_sync"

	// Extract version from the source file if it's local, otherwise use default
	var version string
	if *sourceType == "local" && *filePath != "" {
		extractedVersion, err := extractVersionFromJSON(*filePath)
		if err != nil {
			logger.Warn("Failed to extract version from JSON file, using default", zap.Error(err), zap.String("file", *filePath))
			version = "1.0" // fallback to default
		} else {
			version = extractedVersion
			logger.Info("Extracted version from JSON file", zap.String("version", version), zap.String("file", *filePath))
		}
	} else {
		version = "1.0" // Default version for non-local sources
	}
	var sourcePath, s3Bucket, s3Key string
	if *sourceType == "local" {
		sourcePath = *filePath
	} else {
		s3Bucket = *bucket
		s3Key = *key
	}

	jobID, err := jobRepo.Create(syncOp, *syncType, version, sourcePath, s3Bucket, s3Key)
	if err != nil {
		logger.Warn("Failed to create sync job", zap.Error(err))
		jobID = ""
	}

	// Update job status to in_progress
	if jobID != "" {
		if err := jobRepo.UpdateStatus(jobID, "in_progress", &startTime, nil); err != nil {
			logger.Warn("Failed to update job status to in_progress", zap.Error(err), zap.String("job_id", jobID))
		}
	}

	// Read data
	data, err := dataSource.ReadAll()
	if err != nil {
		errMsg := fmt.Sprintf("failed to read from source: %v", err)
		if jobID != "" {
			if updateErr := jobRepo.UpdateStatus(jobID, "failed", nil, &errMsg); updateErr != nil {
				logger.Warn("Failed to update job status to failed", zap.Error(updateErr), zap.String("job_id", jobID))
			}
		}
		logger.Fatal("Failed to read data", zap.Error(err))
	}

	// Execute sync
	ctx := context.Background()
	var result *types.SyncResult
	switch *syncType {
	case "product":
		result, err = syncService.SyncProducts(ctx, data, jobID, syncCfg.Validation)
	case "price":
		result, err = syncService.SyncPrices(ctx, data, syncCfg.Validation)
	default:
		logger.Fatal("Invalid sync type", zap.String("type", *syncType))
	}

	if err != nil {
		errMsg := fmt.Sprintf("processing failed: %v", err)
		if jobID != "" {
			if updateErr := jobRepo.UpdateStatus(jobID, "failed", &startTime, &errMsg); updateErr != nil {
				logger.Warn("Failed to update job status to failed", zap.Error(updateErr), zap.String("job_id", jobID))
			}
		}
		logger.Fatal("Sync failed", zap.Error(err))
	}

	// Set result metadata after confirming no error
	result.Duration = time.Since(startTime)
	result.JobID = jobID

	// Update job status with results atomically
	if jobID != "" {
		var errMsg *string
		if result.Failed > 0 {
			msg := fmt.Sprintf("Completed with %d failures out of %d items", result.Failed, result.TotalItems)
			errMsg = &msg
		}

		// Use atomic update to ensure consistency
		if err := jobRepo.UpdateStatusAndResults(
			context.Background(),
			jobID,
			"completed",
			result.TotalItems,
			result.Successful,
			result.Failed,
			result.ValidationWarnings,
			errMsg,
		); err != nil {
			logger.Warn("Failed to update job status and results atomically",
				zap.Error(err),
				zap.String("job_id", jobID),
			)
		}
	}

	// Print results
	logger.Info("Sync completed successfully",
		zap.String("sync_type", result.SyncType),
		zap.Int("total_items", result.TotalItems),
		zap.Int("successful", result.Successful),
		zap.Int("failed", result.Failed),
		zap.Int("skipped", result.Skipped),
		zap.Duration("duration", result.Duration),
	)

	if result.Failed > 0 {
		logger.Warn("Some items failed",
			zap.Int("failed_count", result.Failed),
			zap.Strings("errors", result.Errors),
		)
		os.Exit(1)
	}
}
