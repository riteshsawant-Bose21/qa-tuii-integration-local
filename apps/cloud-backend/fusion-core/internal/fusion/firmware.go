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
	LogFirmwareUpdate(ctx context.Context, req *types.LogFirmwareUpdateRequest) error
	DeployRelease(ctx context.Context, releaseID string, channel string, logger *zap.Logger) error

	// Bundle Operations
	NotifyBundleUpload(ctx context.Context, payload *types.NotifyBundleUploadPayload, logger *zap.Logger) (*types.BundleResponse, error)
	ListBundles(ctx context.Context, isApproved *bool, page, limit int) (*types.BundleListResponse, error)
	ApproveBundle(ctx context.Context, bundleID string, approvedBy string, logger *zap.Logger) error
	CheckForUpdate(ctx context.Context, request *types.CheckForUpdateRequest, logger *zap.Logger) (*types.CheckForUpdateResponse, error)
}
