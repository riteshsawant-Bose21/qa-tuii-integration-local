package firmware

import (
	"context"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"go.uber.org/zap"
)

type Service struct {
	dbService DatabaseService
	presigner PresignerService
}

// DatabaseService defines the interface for database operations related to firmware.
type DatabaseService interface {

	// Bundle operations
	GetBundleByVersion(ctx context.Context, version string) (*models.Bundle, error)
	InsertBundle(ctx context.Context, payload types.NotifyBundleUploadPayload, logger *zap.Logger) (string, error)
	ListBundles(ctx context.Context, isApproved *bool, limit, offset int) ([]*models.Bundle, int, error)
	ApproveBundle(ctx context.Context, bundleID string, approvedBy string) error
	GetBundleByID(ctx context.Context, bundleID string) (*models.Bundle, error)
	GetLatestCompatibleBundle(ctx context.Context, currentFirmwareVersion string, currentDesktopAppVersion string, channel string) (*models.Bundle, error)
	GetLatestApprovedBundleNewerThan(ctx context.Context, currentFirmwareVersion string) (*models.Bundle, error)
	GetLatestBundleCompatibleWithFirmware(ctx context.Context, currentFirmwareVersion string, channel string) (*models.Bundle, error)
	LogBundleUpdateStatus(ctx context.Context, payload *types.LogBundleUpdateStatusPayload) error
}

// PresignerService defines the interface for generating presigned URLs.
type PresignerService interface {
	PresignGet(ctx context.Context, objectKey string, ttl time.Duration, logger *zap.Logger) (string, error)
	PresignPut(ctx context.Context, objectKey string, ttl time.Duration, logger *zap.Logger) (string, error)
}

// NewService creates a new project service.
func NewService(dbService DatabaseService, presigner PresignerService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
		presigner: presigner,
	}
}
