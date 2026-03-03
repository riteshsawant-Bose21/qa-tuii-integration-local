package firmware

import (
	"context"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"go.uber.org/zap"
)

type Service struct {
	dbService DatabaseService
	presigner PresignerService
}

// DatabaseService defines the interface for database operations related to firmware.
type DatabaseService interface {
	GetDB(ctx context.Context) customModel.DBWithTransactions
	GetReleaseByPlatformVersion(ctx context.Context, platform string, version string) (*model.FirmwareRelease, error)
	// GetReleaseByVersion(ctx context.Context, platform string, version string) (*model.FirmwareRelease, error)
	CheckIfNewerVersionExists(ctx context.Context, platform string, version string) (bool, error)
	GetReleaseByID(ctx context.Context, releaseID string) (*model.FirmwareRelease, error)
	UpdateReleaseStatus(ctx context.Context, releaseID string, status string, tx customModel.DBContextExecutor) error
	InsertRelease(ctx context.Context, releaseDetails types.FirmwareReleaseMetaData, checksum string, filePath string, tx customModel.DBContextExecutor, logger *zap.Logger) (string, error)
	InsertDeployment(ctx context.Context, releaseID string, tx customModel.DBContextExecutor, channel string, logger *zap.Logger) (string, error)
	ListReleases(ctx context.Context, limit, offset int, platform string, minVersion string) ([]*model.FirmwareRelease, int64, error)
	GetLatestReleaseNewerThan(ctx context.Context, platformName, channelName, currentVersion string) (*model.FirmwareRelease, error)
	GetReleaseByPlatformAndVersion(ctx context.Context, platform string, version string) (*model.FirmwareRelease, error)
	LogFirmwareUpdate(ctx context.Context, deviceID, releaseVersion, status string, eventTime time.Time) error

	// Bundle operations
	GetBundleByVersion(ctx context.Context, version string) (*model.Bundle, error)
	InsertBundle(ctx context.Context, payload types.NotifyBundleUploadPayload, logger *zap.Logger) (string, error)
	ListBundles(ctx context.Context, isApproved *bool, limit, offset int) ([]*model.Bundle, int64, error)
	ApproveBundle(ctx context.Context, bundleID string, approvedBy string) error
	GetBundleByID(ctx context.Context, bundleID string) (*model.Bundle, error)
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
