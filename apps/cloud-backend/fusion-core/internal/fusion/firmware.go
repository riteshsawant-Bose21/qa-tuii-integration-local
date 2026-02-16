package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

type Firmware interface {
	InitiateRelease(ctx context.Context, releaseDetails *types.InitiateFirmwareReleasePayload, logger *zap.Logger) (releaseID string, presignURL string, err error)
	MakeReleaseAvailable(ctx context.Context, releaseID string, logger *zap.Logger) error
	CheckForUpdates(ctx context.Context, request *types.CheckUpdateRequest) (*types.CheckUpdateResponse, error)
	GetArtifactDownloadURL(ctx context.Context, platform, version string, logger *zap.Logger) (*types.DownloadArtifactResponse, error)
	ListReleases(ctx context.Context, platform string, page, limit int, minVersion string) (*types.FirmwareReleaseListResponse, error)
}
