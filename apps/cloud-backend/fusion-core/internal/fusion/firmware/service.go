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
	GetReleaseByVersion(ctx context.Context, platform string, version string) (*model.FirmwareRelease, error)
	CheckIfNewerVersionExists(ctx context.Context, platform string, version string) (bool, error)
	GetReleaseByID(ctx context.Context, releaseID string) (*model.FirmwareRelease, error)
	UpdateReleaseStatus(ctx context.Context, releaseID string, status string, tx customModel.DBContextExecutor) error
	InsertRelease(ctx context.Context, releaseDetails types.FirmwareReleaseMetaData, checksum string, filePath string, tx customModel.DBContextExecutor, logger *zap.Logger) (string, error)
	InsertDeployment(ctx context.Context, releaseID string, tx customModel.DBContextExecutor, channel string, logger *zap.Logger) (string, error)
	ListReleases(ctx context.Context, limit, offset int, platform string) ([]*model.FirmwareRelease, int64, error)
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

func (s *Service) ListReleases(ctx context.Context, platform string, page, limit int) (*types.FirmwareReleaseListResponse, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}
	offset := (page - 1) * limit

	releases, total, err := s.dbService.ListReleases(ctx, limit, offset, platform)
	if err != nil {
		return nil, err
	}

	var releaseDetails []types.FirmwareReleaseDetails
	for _, r := range releases {
		releaseDetails = append(releaseDetails, types.FirmwareReleaseDetails{
			ID:                   r.ID,
			Platform:             r.Platform,
			FirmwareVersion:      r.Version,
			ReleaseNotes:         r.ReleaseNotes,
			MinDesktopAppVersion: r.MinDesktopAppVersion,
			HwCompatibility:      r.HWCompatibility,
			ApiVersion:           r.APILevel,
			Created:              r.CreatedAt,
			Updated:              r.CreatedAt,
		})
	}

	return &types.FirmwareReleaseListResponse{
		Releases: releaseDetails,
		Total:    total,
		Page:     page,
		Limit:    limit,
	}, nil
}
