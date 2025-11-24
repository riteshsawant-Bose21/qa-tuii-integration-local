package sync

import (
	"context"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
)

// Service provides methods to interact with sync operations
type Service struct {
	productDBService ProductDatabaseService
	priceDBService   PriceDatabaseService
	jobDBService     JobDatabaseService
	sourceService    SourceService
}

// ProductDatabaseService defines the interface for product database operations
type ProductDatabaseService interface {
	Insert(ctx context.Context, product *DBProduct) error
	InsertWithRetry(ctx context.Context, product *DBProduct, maxRetries int, retryDelay time.Duration) error
	LookupProductIDBySKU(ctx context.Context, sku int) (int, bool, error)
	GetProductTimestamps(ctx context.Context, productIDs []int) (map[int]*int64, error)
}

// PriceKey represents a unique identifier for a price record
type PriceKey struct {
	ProductID int    `json:"product_id"`
	Currency  string `json:"currency"`
	Variant   string `json:"variant"` // Empty string for null variants
}

// PriceDatabaseService defines the interface for price database operations
type PriceDatabaseService interface {
	UpsertPrice(ctx context.Context, price *DBPrice) error
	GetPriceByProductID(ctx context.Context, productID int) (*DBPrice, error)
	GetPriceTimestamps(ctx context.Context, priceKeys []PriceKey) (map[PriceKey]*int64, error)
}

// JobDatabaseService defines the interface for job tracking database operations
type JobDatabaseService interface {
	Create(syncOperation, sourcePath, s3Bucket, s3Key string) (string, error)
	UpdateStatus(jobID, status string, startedAt *time.Time, errorMsg *string) error
	UpdateWithResults(jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error
	GetByID(jobID string) (*types.SyncJobResult, error)
	StoreValidationErrors(jobID string, errorCollector *errors.ErrorCollector) error
}

// SourceService defines the interface for data source operations
type SourceService interface {
	New(sourceType, sourcePath, s3Bucket, s3Key, region string) (DataSource, error)
}

// DataSource defines the interface for reading data from various sources
type DataSource interface {
	ReadAll() ([]byte, error)
	Close() error
}

// NewService creates a new sync service
func NewService(productDBService ProductDatabaseService, priceDBService PriceDatabaseService, jobDBService JobDatabaseService, sourceService SourceService) *Service {
	if productDBService == nil {
		panic("productDBService cannot be nil")
	}
	if priceDBService == nil {
		panic("priceDBService cannot be nil")
	}
	if jobDBService == nil {
		panic("jobDBService cannot be nil")
	}
	if sourceService == nil {
		panic("sourceService cannot be nil")
	}

	return &Service{
		productDBService: productDBService,
		priceDBService:   priceDBService,
		jobDBService:     jobDBService,
		sourceService:    sourceService,
	}
}

// DBProduct represents a product in database format
type DBProduct struct {
	ProductID        int     `json:"product_id"`
	ProductType      string  `json:"product_type"`
	ModelName        string  `json:"model_name"`
	ModelFamily      string  `json:"model_family"`
	ShortDescription string  `json:"short_description"`
	Description      string  `json:"description"`
	Images           string  `json:"images"`         // JSON string
	Specifications   string  `json:"specifications"` // JSON string
	CreatedAt        *string `json:"created_at"`     // Epoch timestamp as string
	UpdatedAt        *string `json:"updated_at"`     // Epoch timestamp as string
}

// DBPrice represents a price in database format
type DBPrice struct {
	ProductID int     `json:"product_id"`
	Currency  string  `json:"currency"`
	Amount    float64 `json:"amount"`
	Variant   *string `json:"variant,omitempty"`    // Optional variant field
	UpdatedAt *string `json:"updated_at"`           // RFC3339 timestamp
	CreatedAt *string `json:"created_at,omitempty"` // Optional creation timestamp
}

// CreateJob creates a new sync job
func (s *Service) CreateJob(syncOperation, sourcePath, s3Bucket, s3Key string) (string, error) {
	return s.jobDBService.Create(syncOperation, sourcePath, s3Bucket, s3Key)
}

// UpdateJobStatus updates the status of a sync job
func (s *Service) UpdateJobStatus(jobID, status string, startedAt *time.Time, errorMsg *string) error {
	return s.jobDBService.UpdateStatus(jobID, status, startedAt, errorMsg)
}

// UpdateJobWithResults updates a sync job with final results
func (s *Service) UpdateJobWithResults(jobID, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error {
	return s.jobDBService.UpdateWithResults(jobID, status, totalItems, successful, failed, validationWarnings, errorMsg)
}
