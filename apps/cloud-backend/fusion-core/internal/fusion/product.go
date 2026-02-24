package fusion

import (
	"context"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"go.uber.org/zap"
)

// Product defines the interface for product operations
type Product interface {
	GetProductByID(ctx context.Context, id string, logger *zap.Logger) (*types.SingleProductResponse, error)
	GetAllProducts(ctx context.Context, logger *zap.Logger) (*types.ProductResponse, error)
	GetProductPrices(ctx context.Context, id string, currency string, variant string, logger *zap.Logger) (*types.PriceResponse, error)

	// Job management methods
	CreateJob(ctx context.Context, job *types.DBSyncJob) (string, error)
	UpdateJobStatus(ctx context.Context, jobID string, status string, startedAt *time.Time, errorMsg *string) error
	UpdateStatusAndResults(ctx context.Context, jobID string, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error

	// Main sync execution
	Execute(ctx context.Context, request *types.SyncRequest) (*types.SyncResult, error)

	// Core sync operations
	SyncProducts(ctx context.Context, jsonData []byte, jobID string, validationEnabled bool) (*types.SyncResult, error)
	// SyncPrices(ctx context.Context, jsonData []byte, validationEnabled bool) (*types.SyncResult, error)
	SyncPrices(context.Context, []byte, *config.Validation) (*types.SyncResult, error)
}
