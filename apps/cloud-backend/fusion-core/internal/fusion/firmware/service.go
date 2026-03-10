package firmware

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"go.uber.org/zap"
)

type Service struct {
	dbService DatabaseService
	presigner cloudfs.PresignHandle
}

// DatabaseService defines the interface for database operations related to firmware.
type DatabaseService interface {

	// Bundle operations
	GetBundleByVersion(ctx context.Context, version string) (*models.Bundle, error)
	InsertBundle(ctx context.Context, payload types.NotifyBundleUploadPayload, logger *zap.Logger) (string, error)
	ListBundles(ctx context.Context, approvalStatus *string, limit, offset int) ([]*models.Bundle, int, error)
	ApproveBundle(ctx context.Context, bundleID string, approvedBy string, approvalStatus string) error
	GetBundleByID(ctx context.Context, bundleID string) (*models.Bundle, error)
	GetLatestCompatibleBundle(ctx context.Context, currentFirmwareVersion string, currentDesktopAppVersion string, channel string) (*models.Bundle, error)
	GetLatestBundleCompatibleWithFirmware(ctx context.Context, currentFirmwareVersion string, channel string) (*models.Bundle, error)
	InsertBundleUpdateStatus(ctx context.Context, payload *types.LogBundleUpdateStatusPayload) error
}

// NewService creates a new firmware service.
func NewService(dbService DatabaseService, presigner cloudfs.PresignHandle) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
		presigner: presigner,
	}
}
