// Package main provides the entry point for the sync service.
package main

import (
	"context"
	"fmt"
	inbuiltlog "log"
	"net/url"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"go.uber.org/zap"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/storage/cloudfs"
	sql "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/storage/sql"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	serverSync "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/server/sync"
)

var (
	logger     *log.Logger
	productSVC *product.Service

	productBucket string
	priceBucket   string
)

// init runs exactly once per each Lambda cold start, before the first handler is called.
// All expensive setup ís placed within the init
func init() {
	var err error

	logger, err = log.NewProduction()
	if err != nil {
		inbuiltlog.Fatalf("Failed to initialize logger: %v", err)
	}

	// Lambda environment variables are injected directly by the runtime.
	env := environment.New(environment.DefaultLoadLookuper)

	configSVC, err := config.NewService(env)
	if err != nil {
		logger.Fatal("Failed to initialize config service", zap.Error(err))
	}

	syncCfg, err := serverSync.NewSyncConfig(configSVC)
	if err != nil {
		logger.Fatal("Failed to load sync config", zap.Error(err))
	}

	productBucket = syncCfg.Cloud.ProductS3Bucket
	priceBucket = syncCfg.Cloud.PriceS3Bucket
	s3Region := syncCfg.Cloud.Region

	if productBucket == "" || priceBucket == "" {
		logger.Fatal("S3_PRODUCT_BUCKET and S3_PRICE_BUCKET environment variables must be set")
	}

	if s3Region == "" {
		logger.Fatal("AWS_REGION environment variable must be set.")
	}

	pgs, err := sql.New(
		sql.PostgresOpener,
		syncCfg.Postgres.Host, // Use a proxy for AWS Rds
		syncCfg.Postgres.Port,
		syncCfg.Postgres.User,
		syncCfg.Postgres.Password,
		syncCfg.Postgres.Database,
		syncCfg.Postgres.SSLMode,
	)

	if err != nil {
		logger.Fatal("Failed to connect to database", zap.Error(err))
	}

	validationCfg, err := configSVC.Validation()
	if err != nil {
		logger.Fatal("Failed to get validation config", zap.Error(err))
	}

	processingCfg, err := configSVC.Processing()
	if err != nil {
		logger.Fatal("Failed to get processing config", zap.Error(err))
	}

	// Initialize S3 client
	s3Handler, err := cloudfs.NewS3Client(context.Background(), syncCfg.Cloud.Region)
	if err != nil {
		logger.Fatal("Failed to initialize S3 client", zap.Error(err))
	}

	productDBSvc := productdb.NewService(pgs, logger.JobSyncLog())
	if productDBSvc == nil {
		logger.Fatal("Failed to initialize product database service")
	}

	productSVC = product.NewService(
		productDBSvc,
		validationCfg.DefaultVersion,
		validationCfg,
		processingCfg,
		s3Handler,
		logger.JobSyncLog(),
	)
	if productSVC == nil {
		logger.Fatal("Failed to initialize product service")
	}

	syncRequestRegion := s3Region
	if syncRequestRegion == "" {
		syncRequestRegion = syncCfg.Cloud.Region
	}
}

// inferSyncType determines the sync type from the S3 object key path.
// Prefix convention:
// s3://<S3_PRODUCT_BUCKET>/XXXX/<file>.json -> "product"
// s3://<S3_PRICE_BUCKET>/XXXX/<file>.json   -> "price"
func inferSyncType(bucket string) (string, error) {
	switch bucket {
	case productBucket:
		return "product", nil
	case priceBucket:
		return "price", nil
	default:
		return "", fmt.Errorf(
			"unknown bucket %q: must match S3_PRODUCT_BUCKET or S3_PRICE_BUCKET",
			bucket,
		)
	}
}

// handler is invoked by the Lambda runtime for each S3 event notif.
// If it returns non-nil value, it tells Lambda to retry
func handler(ctx context.Context, s3Event events.S3Event) error {
	for _, record := range s3Event.Records {

		key, err := url.QueryUnescape(record.S3.Object.Key)

		if err != nil {
			logger.Error("failed to URL-decode S3 key",
				zap.String("raw_key", record.S3.Object.Key),
				zap.Error(err),
			)
			return fmt.Errorf("invalid S3 key encoding %q: %w", record.S3.Object.Key, err)
		}

		bucket := record.S3.Bucket.Name
		region := record.AWSRegion

		logger.Info("Received S3 event",
			zap.String("bucket", bucket),
			zap.String("key", key),
			zap.String("region", region),
			zap.String("eventName", record.EventName),
		)

		syncType, err := inferSyncType(bucket)
		if err != nil {
			logger.Error("failed to infer sync type",
				zap.String("key", key),
				zap.Error(err),
			)
			return err
		}

		syncRequest := &types.SyncRequest{
			SyncType:         syncType,
			SyncOperation:    "scheduled_sync",
			SourceType:       "s3",
			S3Bucket:         bucket,
			S3Key:            key,
			Region:           region,
			EnableValidation: true,
		}

		result, err := productSVC.Execute(ctx, syncRequest)
		if err != nil {
			logger.Error("sync execution failed",
				zap.String("bucket", bucket),
				zap.String("key", key),
				zap.String("sync_type", syncType),
				zap.Error(err),
			)
			// Non-nil error -> Lambda retries according to retry policy.
			return fmt.Errorf("sync failed for s3://%s/%s: %w", bucket, key, err)
		}

		logger.Info("sync completed",
			zap.String("bucket", bucket),
			zap.String("key", key),
			zap.String("sync_type", syncType),
			zap.Int("total_items", result.TotalItems),
			zap.Int("successful", result.Successful),
			zap.Int("failed", result.Failed),
			zap.Duration("duration", result.Duration),
		)

		if result.Failed > 0 {
			logger.Warn("sync completed with partial failures",
				zap.Int("failed_count", result.Failed),
				zap.Strings("validation_warnings", result.ValidationWarnings),
			)
			return fmt.Errorf(
				"sync completed with %d item failure(s) for s3://%s/%s",
				result.Failed, bucket, key,
			)
		}
	}

	return nil
}

// main just calls the lambda handler
func main() {
	lambda.Start(handler)
}
