package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

type Firmware interface {
	// Bundle Operations
	NotifyBundleUpload(ctx context.Context, payload *types.NotifyBundleUploadPayload, logger *zap.Logger) (*types.BundleResponse, error)
	ListBundles(ctx context.Context, isApproved *bool, page, limit int) (*types.BundleListResponse, error)
	ApproveBundle(ctx context.Context, bundleID string, approvedBy string, logger *zap.Logger) error
	CheckForUpdate(ctx context.Context, request *types.CheckForUpdateRequest, logger *zap.Logger) (*types.CheckForUpdateResponse, error)
	GetBundleDownloadURL(ctx context.Context, bundleID string, logger *zap.Logger) (*types.DownloadArtifactResponse, error)
	LogBundleUpdateStatus(ctx context.Context, payload *types.LogBundleUpdateStatusPayload, logger *zap.Logger) error
}
