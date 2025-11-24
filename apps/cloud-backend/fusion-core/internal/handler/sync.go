package handler

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	fusionSync "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync"
	syncDB "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync/db"
	syncSource "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync/source"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// syncHandlerAdapter adapts syncSource.Service to fusionSync.SourceService interface
type syncHandlerAdapter struct {
	impl *syncSource.Service
}

func (s *syncHandlerAdapter) New(sourceType, sourcePath, s3Bucket, s3Key, region string) (fusionSync.DataSource, error) {
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

// Global sync service for HTTP handlers
var globalSyncService *fusionSync.Service
var globalLogger *zap.Logger

// SetupHTTPServer sets up and starts the HTTP server for sync operations
func SetupHTTPServer(host, port string, logger *zap.Logger) error {
	// Initialize environment
	env := environment.New(environment.DefaultLoadLookuper)

	// Initialize configuration service
	configSVC, err := config.NewService(env)
	if err != nil {
		return fmt.Errorf("failed to initialize config service: %w", err)
	}

	// Load Sync configuration
	syncCfg, err := fusionSync.NewSyncConfig(configSVC)
	if err != nil {
		return fmt.Errorf("failed to load Sync config: %w", err)
	}

	// Initialize the database connection
	pgs, err := sql.New(
		sql.PostgresOpener,
		syncCfg.Postgres.Host,
		syncCfg.Postgres.Port,
		syncCfg.Postgres.User,
		syncCfg.Postgres.Password,
		syncCfg.Postgres.Database,
	)
	if err != nil {
		return fmt.Errorf("failed to connect to the database: %w", err)
	}
	defer pgs.Close()

	logger.Info("Database connection established successfully")

	// Wrap in Database wrapper for sync services compatibility
	db := &syncDB.Database{DB: pgs}

	// Create fusion sync services
	productService := syncDB.NewProductService(db)
	priceService := syncDB.NewPriceService(db)
	jobService := syncDB.NewJobService(db, logger)

	// Create source service adapter
	sourceServiceImpl := syncSource.NewService()
	sourceService := &syncHandlerAdapter{impl: sourceServiceImpl}

	// Create fusion sync service
	syncService := fusionSync.NewService(productService, priceService, jobService, sourceService)

	// Set global variables for handlers
	globalSyncService = syncService
	globalLogger = logger

	// Setup Gin router
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	router.Use(gin.Recovery())

	// Register routes
	router.POST("/sync", syncHandler)
	router.GET("/health", healthHandler)

	addr := host + ":" + port
	logger.Info("Starting sync HTTP server",
		zap.String("address", addr),
		zap.String("endpoints", "POST /sync, GET /health"),
	)

	// Run server
	if err := router.Run(addr); err != nil {
		return fmt.Errorf("HTTP server failed: %w", err)
	}

	return nil
}

// syncHandler handles sync requests
func syncHandler(c *gin.Context) {
	// Parse request body
	var req struct {
		SyncType   string `json:"sync_type"`   // "product" or "price"
		SourceType string `json:"source_type"` // "local" or "s3"
		SourcePath string `json:"source_path"` // for local files
		S3Bucket   string `json:"s3_bucket"`   // for S3
		S3Key      string `json:"s3_key"`      // for S3
		Region     string `json:"region"`      // AWS region
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
		return
	}

	// Validate request
	if req.SyncType == "" || req.SourceType == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "sync_type and source_type are required"})
		return
	}

	if req.SourceType == "local" && req.SourcePath == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "source_path is required for local source"})
		return
	}

	if req.SourceType == "s3" && (req.S3Bucket == "" || req.S3Key == "") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "s3_bucket and s3_key are required for s3 source"})
		return
	}

	globalLogger.Info("Received sync request",
		zap.String("sync_type", req.SyncType),
		zap.String("source_type", req.SourceType),
	)

	// Create sync job record
	startTime := time.Now().UTC()
	syncOp := "manual_sync"
	var sourcePath, s3Bucket, s3Key string
	if req.SourceType == "local" {
		sourcePath = req.SourcePath
	} else {
		s3Bucket = req.S3Bucket
		s3Key = req.S3Key
	}

	jobID, err := globalSyncService.CreateJob(syncOp, sourcePath, s3Bucket, s3Key)
	if err != nil {
		globalLogger.Warn("Failed to create sync job", zap.Error(err))
		jobID = ""
	}

	// Update job status to in_progress
	if jobID != "" {
		if err := globalSyncService.UpdateJobStatus(jobID, "in_progress", &startTime, nil); err != nil {
			globalLogger.Warn("Failed to update job status to in_progress", zap.Error(err), zap.String("job_id", jobID))
		}
	}

	// Create data source
	sourceServiceImpl := syncSource.NewService()
	sourceService := &syncHandlerAdapter{impl: sourceServiceImpl}

	dataSource, err := sourceService.New(req.SourceType, req.SourcePath, req.S3Bucket, req.S3Key, req.Region)
	if err != nil {
		errMsg := fmt.Sprintf("failed to create data source: %v", err)
		if jobID != "" {
			if updateErr := globalSyncService.UpdateJobStatus(jobID, "failed", nil, &errMsg); updateErr != nil {
				globalLogger.Warn("Failed to update job status to failed", zap.Error(updateErr), zap.String("job_id", jobID))
			}
		}
		globalLogger.Error("Failed to create data source", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create data source: %v", err)})
		return
	}
	defer dataSource.Close()

	// Read data
	data, err := dataSource.ReadAll()
	if err != nil {
		errMsg := fmt.Sprintf("failed to read data: %v", err)
		if jobID != "" {
			if updateErr := globalSyncService.UpdateJobStatus(jobID, "failed", nil, &errMsg); updateErr != nil {
				globalLogger.Warn("Failed to update job status to failed", zap.Error(updateErr), zap.String("job_id", jobID))
			}
		}
		globalLogger.Error("Failed to read data", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to read data: %v", err)})
		return
	}

	// Execute sync
	ctx := context.Background()
	var result *types.SyncResult
	switch req.SyncType {
	case "product":
		result, err = globalSyncService.SyncProducts(ctx, data, jobID)
	case "price":
		result, err = globalSyncService.SyncPrices(ctx, data)
	default:
		if jobID != "" {
			errMsg := fmt.Sprintf("invalid sync type: %s", req.SyncType)
			if updateErr := globalSyncService.UpdateJobStatus(jobID, "failed", nil, &errMsg); updateErr != nil {
				globalLogger.Warn("Failed to update job status to failed", zap.Error(updateErr), zap.String("job_id", jobID))
			}
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid sync type: %s", req.SyncType)})
		return
	}

	if err != nil {
		errMsg := fmt.Sprintf("sync processing failed: %v", err)
		if jobID != "" {
			if updateErr := globalSyncService.UpdateJobStatus(jobID, "failed", &startTime, &errMsg); updateErr != nil {
				globalLogger.Warn("Failed to update job status to failed", zap.Error(updateErr), zap.String("job_id", jobID))
			}
		}
		globalLogger.Error("Sync failed", zap.Error(err))
		c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Sync failed: %v", err)})
		return
	}

	// Set result metadata
	result.Duration = time.Since(startTime)
	result.JobID = jobID

	// Update job status with results
	if jobID != "" {
		var errMsg *string
		if result.Failed > 0 {
			msg := fmt.Sprintf("Completed with %d failures out of %d items", result.Failed, result.TotalItems)
			errMsg = &msg
		}
		if err := globalSyncService.UpdateJobWithResults(jobID, "completed", result.TotalItems, result.Successful, result.Failed, result.ValidationWarnings, errMsg); err != nil {
			globalLogger.Warn("Failed to update job status to completed", zap.Error(err), zap.String("job_id", jobID))
		}
	}

	globalLogger.Info("Sync completed successfully",
		zap.String("sync_type", result.SyncType),
		zap.Int("total_items", result.TotalItems),
		zap.Int("successful", result.Successful),
		zap.Int("failed", result.Failed),
		zap.String("job_id", jobID),
	)

	// Return response
	c.JSON(http.StatusOK, result)
}

// healthHandler handles health check requests
func healthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "sync",
	})
}
