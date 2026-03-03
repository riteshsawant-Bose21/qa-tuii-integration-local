package product

import (
	"context"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/validation"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	errorutil "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"go.uber.org/zap"
)

// Service provides methods to interact with the product database and sync operations.
type Service struct {
	dbService     DatabaseService
	version       string
	validator     *validation.FieldValidator
	validationCfg *config.Validation
	processingCfg *config.Processing
	logger        *zap.Logger
	s3Client      *cloudfs.S3
}

// DatabaseService defines the interface for database operations related to products and sync.
type DatabaseService interface {
	// Product query operations
	SelectByID(ctx context.Context, id string, version string, logger *zap.Logger) (*types.SingleProductResponse, error)
	SelectAll(ctx context.Context, version string, logger *zap.Logger) (*types.ProductResponse, error)
	GetPricesByProductID(ctx context.Context, productID int, currency string, variant string, logger *zap.Logger) (*types.PriceResponse, error)
	GetLatestSyncVersion(ctx context.Context, syncType string, logger *zap.Logger) (string, error)

	// Product sync operations
	Insert(ctx context.Context, product *types.DBProduct, logger *zap.Logger) error
	Upsert(ctx context.Context, product *types.DBProduct, logger *zap.Logger) error
	InsertBatch(ctx context.Context, products []*types.DBProduct, logger *zap.Logger) error
	InsertWithRetry(ctx context.Context, product *types.DBProduct, maxRetries int, retryDelay time.Duration, logger *zap.Logger) error
	LookupProductIDBySKU(ctx context.Context, sku int, logger *zap.Logger) (int, bool, error)
	BatchLookupExistingProductIDs(ctx context.Context, productIDs []int, logger *zap.Logger) (map[int]bool, error)
	GetProductTimestamps(ctx context.Context, productIDs []int, logger *zap.Logger) (map[int]*int64, error)
	GetExistingProduct(ctx context.Context, productID int, logger *zap.Logger) (*types.DBProduct, error)

	// Price operations
	UpsertPrice(ctx context.Context, price *types.DBPrice, logger *zap.Logger) error
	UpsertBatch(ctx context.Context, prices []*types.DBPrice, logger *zap.Logger) error
	InsertPriceBatch(ctx context.Context, prices []*types.DBPrice, logger *zap.Logger) error
	GetPriceByProductID(ctx context.Context, productID int, logger *zap.Logger) (*types.DBPrice, error)
	GetPriceTimestamps(ctx context.Context, priceKeys []types.PriceKey, logger *zap.Logger) (map[types.PriceKey]*int64, error)

	// Job operations
	Create(ctx context.Context, syncOperation, syncType, version, sourcePath, s3Bucket, s3Key string, logger *zap.Logger) (string, error)
	UpdateStatus(ctx context.Context, jobID, status string, startedAt *time.Time, errorMsg *string, logger *zap.Logger) error
	UpdateWithResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string, logger *zap.Logger) error
	UpdateStatusAndResults(ctx context.Context, jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string, logger *zap.Logger) error
	GetByID(ctx context.Context, jobID string, logger *zap.Logger) (*types.SyncJobResult, error)
	StoreValidationErrors(ctx context.Context, jobID string, errorCollector *errorutil.ErrorCollector, logger *zap.Logger) error
}

// NewService creates a new product service.
func NewService(dbService DatabaseService, version string, validationCfg *config.Validation, processingCfg *config.Processing, s3Client *cloudfs.S3, logger *zap.Logger) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if validationCfg == nil {
		panic("validationCfg cannot be nil")
	}
	if processingCfg == nil {
		panic("processingCfg cannot be nil")
	}
	if s3Client == nil {
		panic("s3Client cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}

	return &Service{
		dbService:     dbService,
		version:       version,
		validator:     validation.NewFieldValidator(),
		validationCfg: validationCfg,
		processingCfg: processingCfg,
		s3Client:      s3Client,
		logger:        logger,
	}
}
