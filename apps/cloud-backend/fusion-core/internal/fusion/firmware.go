package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

type Firmware interface {
	// Bundle Operations
	NotifyBundleUpload(ctx context.Context, payload *types.NotifyBundleUploadPayload, logger *zap.Logger) (*types.BundleResponse, error)
	ListBundles(ctx context.Context, approvalStatus *string, page, limit int) (*types.BundleListResponse, error)
	ApproveBundle(ctx context.Context, bundleID string, approvedBy string, approvalStatus string, logger *zap.Logger) error
	CheckForUpdate(ctx context.Context, request *types.FirmwareUpdateRequest, logger *zap.Logger) (*types.FirmwareUpdateResponse, error)
	GetBundleDownloadURL(ctx context.Context, bundleID string, logger *zap.Logger) (*types.DownloadArtifactResponse, error)
	InsertBundleUpdateStatus(ctx context.Context, payload *types.LogBundleUpdateStatusPayload, logger *zap.Logger) error
}
