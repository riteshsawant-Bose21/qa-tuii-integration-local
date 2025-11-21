package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"go.uber.org/zap"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	config "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	fusionSync "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/sync"
	syncDB "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/sync/db"
	syncSource "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/sync/source"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
)

// sourceServiceAdapter adapts the source.Service to match the SourceService interface
type sourceServiceAdapter struct {
	impl *syncSource.Service
}

// implements the SourceService interface
func (s *sourceServiceAdapter) New(sourceType, sourcePath, s3Bucket, s3Key, region string) (fusionSync.DataSource, error) {
	sourceDS, err := s.impl.New(sourceType, sourcePath, s3Bucket, s3Key, region)
	if err != nil {
		return nil, err
	}
	return &dataSourceAdapter{impl: sourceDS}, nil
}

// dataSourceAdapter adapts source.DataSource to fusionSync.DataSource
type dataSourceAdapter struct {
	impl syncSource.DataSource
}

func (d *dataSourceAdapter) ReadAll() ([]byte, error) {
	return d.impl.ReadAll()
}

func (d *dataSourceAdapter) Close() error {
	return d.impl.Close()
}

// LambdaEvent represents the Lambda event structure
type LambdaEvent struct {
	SyncType   string `json:"syncType"`   // "product" or "price"
	SourceType string `json:"sourceType"` // "local" or "s3"
	SourcePath string `json:"sourcePath,omitempty"`
	S3Bucket   string `json:"s3Bucket,omitempty"`
	S3Key      string `json:"s3Key,omitempty"`
	Region     string `json:"region,omitempty"`
}

// LambdaResponse represents the Lambda response
type LambdaResponse struct {
	Success    bool     `json:"success"`
	JobID      string   `json:"jobId,omitempty"`
	TotalItems int      `json:"totalItems"`
	Successful int      `json:"successful"`
	Failed     int      `json:"failed"`
	Errors     []string `json:"errors,omitempty"`
	Duration   string   `json:"duration"`
	Message    string   `json:"message"`
}

// Handler is the Lambda handler function
func Handler(ctx context.Context, event LambdaEvent) (LambdaResponse, error) {
	// Load environment (for Lambda, env vars are already available)
	env := environment.New(environment.DefaultLoadLookuper)

	// Initialize configuration service
	configSVC, err := config.NewService(env)
	if err != nil {
		return LambdaResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to initialize config service: %v", err),
		}, err
	}

	apiCfg, apiErr := api.NewAPIConfig(configSVC)
	var db *syncDB.Database

	if apiErr == nil {
		sqlDB, err := sql.New(
			sql.PostgresOpener,
			apiCfg.Postgres.Host,
			apiCfg.Postgres.Port,
			apiCfg.Postgres.User,
			apiCfg.Postgres.Password,
			apiCfg.Postgres.Database,
		)
		if err != nil {
			return LambdaResponse{
				Success: false,
				Message: fmt.Sprintf("Failed to connect to database via API config: %v", err),
			}, err
		}
		// Wrap in Database wrapper for sync services compatibility
		db = &syncDB.Database{DB: sqlDB}
	} else {
		// Fallback to sync-style config
		cfg, err := config.Load()
		if err != nil {
			return LambdaResponse{
				Success: false,
				Message: fmt.Sprintf("Failed to load sync config: %v", err),
			}, err
		}

		db, err = syncDB.Connect(cfg.GetDatabaseDSN())
		if err != nil {
			return LambdaResponse{
				Success: false,
				Message: fmt.Sprintf("Failed to connect to database via sync config: %v", err),
			}, err
		}
	}
	defer db.Close()

	// Setup logger and load config
	cfg, err := config.Load() // Load sync config
	if err != nil {
		return LambdaResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to load sync config: %v", err),
		}, err
	}

	logger, err := config.SetupLogger(cfg.LogLevel)
	if err != nil {
		return LambdaResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to setup logger: %v", err),
		}, err
	}
	defer logger.Sync()
	defer logger.Sync()

	logger.Info("Database connection established successfully")

	// Create fusion sync services
	productService := syncDB.NewProductService(db)
	priceService := syncDB.NewPriceService(db)
	jobService := syncDB.NewJobService(db, logger)

	// Create source service adapter
	sourceServiceImpl := syncSource.NewService()
	sourceService := &sourceServiceAdapter{impl: sourceServiceImpl}

	// Create fusion sync service
	syncService := fusionSync.NewService(productService, priceService, jobService, sourceService)

	// Keep jobService reference for direct job operations (like sync_data)
	jobRepo := jobService

	// Create data source
	awsRegion := event.Region
	if awsRegion == "" {
		awsRegion = cfg.AWS.Region
	}

	dataSource, err := sourceService.New(event.SourceType, event.SourcePath, event.S3Bucket, event.S3Key, awsRegion)
	if err != nil {
		logger.Error("Failed to create data source", zap.Error(err))
		return LambdaResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to create data source: %v", err),
		}, err
	}
	defer dataSource.Close()

	// Create sync job
	startTime := time.Now().UTC()
	syncOp := "manual_sync"
	var sourcePath, s3Bucket, s3Key string
	if event.SourceType == "local" {
		sourcePath = event.SourcePath
	} else {
		s3Bucket = event.S3Bucket
		s3Key = event.S3Key
	}

	jobID, err := jobRepo.Create(syncOp, sourcePath, s3Bucket, s3Key)
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
		logger.Error("Failed to read data", zap.Error(err))
		return LambdaResponse{
			Success: false,
			Message: fmt.Sprintf("Failed to read data: %v", err),
		}, err
	}

	// Execute sync
	var result *fusion.SyncResult
	switch event.SyncType {
	case "product":
		result, err = syncService.SyncProducts(context.Background(), data, jobID)
	case "price":
		result, err = syncService.SyncPrices(context.Background(), data)
	default:
		return LambdaResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid sync type: %s", event.SyncType),
		}, fmt.Errorf("invalid sync type: %s", event.SyncType)
	}

	if err != nil {
		errMsg := fmt.Sprintf("processing failed: %v", err)
		if jobID != "" {
			if updateErr := jobRepo.UpdateStatus(jobID, "failed", &startTime, &errMsg); updateErr != nil {
				logger.Warn("Failed to update job status to failed", zap.Error(updateErr), zap.String("job_id", jobID))
			}
		}
		logger.Error("Sync failed", zap.Error(err))
		return LambdaResponse{
			Success: false,
			Message: fmt.Sprintf("Sync failed: %v", err),
			Errors:  []string{err.Error()},
			JobID:   jobID,
		}, err
	}

	// Set result metadata after confirming no error
	result.Duration = time.Since(startTime)
	result.JobID = jobID

	// Update job status with results
	if jobID != "" {
		var errMsg *string
		if result.Failed > 0 {
			msg := fmt.Sprintf("Completed with %d failures out of %d items", result.Failed, result.TotalItems)
			errMsg = &msg
		}
		if err := jobRepo.UpdateWithResults(jobID, "completed", result.TotalItems, result.Successful, result.Failed, result.ValidationWarnings, errMsg); err != nil {
			logger.Warn("Failed to update job status to completed", zap.Error(err), zap.String("job_id", jobID))
		}
	}

	logger.Info("Sync completed",
		zap.String("sync_type", result.SyncType),
		zap.Int("total_items", result.TotalItems),
		zap.Int("successful", result.Successful),
		zap.Int("failed", result.Failed),
		zap.Int("skipped", result.Skipped),
		zap.Duration("duration", result.Duration),
		zap.String("job_id", result.JobID),
	)

	return LambdaResponse{
		Success:    result.Failed == 0,
		JobID:      jobID,
		TotalItems: result.TotalItems,
		Successful: result.Successful,
		Failed:     result.Failed,
		Errors:     result.Errors,
		Duration:   result.Duration.String(),
		Message:    fmt.Sprintf("Sync completed: %d successful, %d failed, %d skipped", result.Successful, result.Failed, result.Skipped),
	}, nil
}

// HTTPRequest represents an HTTP request body for sync operations
type HTTPRequest struct {
	SyncType   string `json:"syncType"`   // "product" or "price"
	SourceType string `json:"sourceType"` // "local" or "s3"
	SourcePath string `json:"sourcePath,omitempty"`
	S3Bucket   string `json:"s3Bucket,omitempty"`
	S3Key      string `json:"s3Key,omitempty"`
	Region     string `json:"region,omitempty"`
}

// HTTPResponse represents an HTTP response
type HTTPResponse struct {
	Success    bool     `json:"success"`
	JobID      string   `json:"jobId,omitempty"`
	TotalItems int      `json:"totalItems"`
	Successful int      `json:"successful"`
	Failed     int      `json:"failed"`
	Errors     []string `json:"errors,omitempty"`
	Duration   string   `json:"duration"`
	Message    string   `json:"message"`
}

// syncHandler handles HTTP requests for sync operations
func syncHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse request based on content type
	var event LambdaEvent
	contentType := r.Header.Get("Content-Type")

	if strings.HasPrefix(contentType, "application/json") {
		// JSON body with S3 configuration
		if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
			http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
			return
		}
	} else if strings.HasPrefix(contentType, "multipart/form-data") {
		// Multipart form with file upload (for local source)
		if err := r.ParseMultipartForm(32 << 20); err != nil { // 32MB max
			http.Error(w, fmt.Sprintf("Failed to parse form: %v", err), http.StatusBadRequest)
			return
		}

		event.SyncType = r.FormValue("syncType")
		event.SourceType = "local"
		event.Region = r.FormValue("region")

		// Handle file upload
		file, _, err := r.FormFile("file")
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to get file: %v", err), http.StatusBadRequest)
			return
		}
		defer file.Close()

		// Create temporary file
		tempDir := os.TempDir()
		tempFile, err := os.CreateTemp(tempDir, "sync-*.json")
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to create temp file: %v", err), http.StatusInternalServerError)
			return
		}
		defer os.Remove(tempFile.Name())
		defer tempFile.Close()

		// Copy uploaded file to temp file
		if _, err := io.Copy(tempFile, file); err != nil {
			http.Error(w, fmt.Sprintf("Failed to save file: %v", err), http.StatusInternalServerError)
			return
		}
		tempFile.Close()

		// Use absolute path
		absPath, err := filepath.Abs(tempFile.Name())
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to get absolute path: %v", err), http.StatusInternalServerError)
			return
		}

		event.SourcePath = absPath
	} else {
		http.Error(w, "Content-Type must be application/json or multipart/form-data", http.StatusBadRequest)
		return
	}

	// Validate required fields
	if event.SyncType == "" {
		http.Error(w, "syncType is required", http.StatusBadRequest)
		return
	}
	if event.SourceType == "local" && event.SourcePath == "" {
		http.Error(w, "sourcePath is required for local source", http.StatusBadRequest)
		return
	}
	if event.SourceType == "s3" && (event.S3Bucket == "" || event.S3Key == "") {
		http.Error(w, "s3Bucket and s3Key are required for s3 source", http.StatusBadRequest)
		return
	}

	// Call existing Handler function
	ctx := context.Background()
	response, err := Handler(ctx, event)
	if err != nil {
		http.Error(w, fmt.Sprintf("Sync failed: %v", err), http.StatusInternalServerError)
		return
	}

	// Set response headers
	w.Header().Set("Content-Type", "application/json")

	// Set status code based on success
	statusCode := http.StatusOK
	if !response.Success {
		statusCode = http.StatusInternalServerError
	}

	w.WriteHeader(statusCode)
	// LambdaResponse and HTTPResponse have identical structure, so we can encode directly
	json.NewEncoder(w).Encode(response)
}

// healthHandler handles health check requests
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "healthy",
		"service": "product-sync",
	})
}

// setupHTTPServer sets up and starts the HTTP server
func setupHTTPServer(host, port string, logger *zap.Logger) {
	mux := http.NewServeMux()

	// Register handlers
	mux.HandleFunc("/sync", syncHandler)
	mux.HandleFunc("/health", healthHandler)

	addr := host + ":" + port
	server := &http.Server{
		Addr:         addr,
		Handler:      mux,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	logger.Info("Starting HTTP server",
		zap.String("address", addr),
		zap.String("endpoints", "/sync, /health"),
	)

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		logger.Fatal("HTTP server failed", zap.Error(err))
	}
}

// main supports Lambda, CLI, and HTTP server execution
func main() {
	// Check if running as Lambda (AWS_LAMBDA_RUNTIME_API is set)
	if os.Getenv("AWS_LAMBDA_RUNTIME_API") != "" {
		lambda.Start(Handler)
		return
	}

	// Check for HTTP server mode
	serverMode := flag.Bool("server", false, "Run as HTTP server")
	port := flag.String("port", "8080", "HTTP server port (only used with -server)")

	// CLI mode flags
	syncType := flag.String("type", "", "Sync type: 'product' or 'price' (required)")
	sourceType := flag.String("source", "", "Source type: 'local' or 's3' (required)")
	filePath := flag.String("path", "", "File path (required for local source)")
	bucket := flag.String("bucket", "", "S3 bucket name (required for s3 source)")
	key := flag.String("key", "", "S3 object key (required for s3 source)")
	region := flag.String("region", "", "AWS region (optional, uses config default)")
	flag.Parse()

	// HTTP Server Mode
	if *serverMode {
		cfg, err := config.Load()
		if err != nil {
			fmt.Printf("Failed to load config: %v\n", err)
			os.Exit(1)
		}

		logger, err := config.SetupLogger(cfg.LogLevel)
		if err != nil {
			fmt.Printf("Failed to setup logger: %v\n", err)
			os.Exit(1)
		}
		defer logger.Sync()

		// Use config values for server host and port, fall back to command line flag
		serverHost := cfg.Server.APIHost
		serverPort := *port // Always use the command line port parameter

		setupHTTPServer(serverHost, serverPort, logger)
		return
	}

	// CLI mode - validate required flags
	if *syncType == "" || *sourceType == "" {
		flag.Usage()
		fmt.Println("\nError: --type and --source are required (or use --server for HTTP mode)")
		os.Exit(1)
	}

	if *sourceType == "local" && *filePath == "" {
		fmt.Println("Error: --path is required for local source")
		os.Exit(1)
	}

	if *sourceType == "s3" && (*bucket == "" || *key == "") {
		fmt.Println("Error: --bucket and --key are required for s3 source")
		os.Exit(1)
	}

	// Load environment for CLI mode
	env := environment.New(environment.DefaultLoadLookuper)

	// Initialize configuration service
	configSVC, err := config.NewService(env)
	if err != nil {
		fmt.Printf("Failed to initialize config service: %v\n", err)
		os.Exit(1)
	}

	// Try to load API-style config first, fallback to sync config
	apiCfg, apiErr := api.NewAPIConfig(configSVC)
	var db *syncDB.Database

	if apiErr == nil {
		// Use API-style config with PostgreSQL connection
		sqlDB, err := sql.New(
			sql.PostgresOpener,
			apiCfg.Postgres.Host,
			apiCfg.Postgres.Port,
			apiCfg.Postgres.User,
			apiCfg.Postgres.Password,
			apiCfg.Postgres.Database,
		)
		if err != nil {
			fmt.Printf("Failed to connect to database via API config: %v\n", err)
			os.Exit(1)
		}
		// Wrap in Database wrapper for sync services compatibility
		db = &syncDB.Database{DB: sqlDB}
	} else {
		// Fallback to sync-style config
		cfg, err := config.Load()
		if err != nil {
			fmt.Printf("Failed to load sync config: %v\n", err)
			os.Exit(1)
		}

		// Connect using sync approach
		var syncErr error
		db, syncErr = syncDB.Connect(cfg.GetDatabaseDSN())
		if syncErr != nil {
			fmt.Printf("Failed to connect to database via sync config: %v\n", syncErr)
			os.Exit(1)
		}
	}
	defer db.Close()

	// Load sync config for logger and other settings
	cfg, err := config.Load()
	if err != nil {
		fmt.Printf("Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// Setup logger
	logger, err := config.SetupLogger(cfg.LogLevel)
	if err != nil {
		fmt.Printf("Failed to setup logger: %v\n", err)
		os.Exit(1)
	}
	defer logger.Sync()

	logger.Info("Database connection established successfully")

	// Create fusion sync services
	productService := syncDB.NewProductService(db)
	priceService := syncDB.NewPriceService(db)
	jobService := syncDB.NewJobService(db, logger)

	// Create source service adapter
	sourceServiceImpl := syncSource.NewService()
	sourceService := &sourceServiceAdapter{impl: sourceServiceImpl}

	// Create fusion sync service
	syncService := fusionSync.NewService(productService, priceService, jobService, sourceService)

	// Keep jobService reference for direct job operations (like sync_data)
	jobRepo := jobService

	// Create data source
	awsRegion := *region
	if awsRegion == "" {
		awsRegion = cfg.AWS.Region
	}

	dataSource, err := sourceService.New(*sourceType, *filePath, *bucket, *key, awsRegion)
	if err != nil {
		logger.Fatal("Failed to create data source", zap.Error(err))
	}
	defer dataSource.Close()

	// Create sync job
	startTime := time.Now().UTC()
	syncOp := "manual_sync"
	var sourcePath, s3Bucket, s3Key string
	if *sourceType == "local" {
		sourcePath = *filePath
	} else {
		s3Bucket = *bucket
		s3Key = *key
	}

	jobID, err := jobRepo.Create(syncOp, sourcePath, s3Bucket, s3Key)
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
	var result *fusion.SyncResult
	switch *syncType {
	case "product":
		result, err = syncService.SyncProducts(ctx, data, jobID)
	case "price":
		result, err = syncService.SyncPrices(ctx, data)
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

	// Update job status with results
	if jobID != "" {
		var errMsg *string
		if result.Failed > 0 {
			msg := fmt.Sprintf("Completed with %d failures out of %d items", result.Failed, result.TotalItems)
			errMsg = &msg
		}
		if err := jobRepo.UpdateWithResults(jobID, "completed", result.TotalItems, result.Successful, result.Failed, result.ValidationWarnings, errMsg); err != nil {
			logger.Warn("Failed to update job status to completed", zap.Error(err), zap.String("job_id", jobID))
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
