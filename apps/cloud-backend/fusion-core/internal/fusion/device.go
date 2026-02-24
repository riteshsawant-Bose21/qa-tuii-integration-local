package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// Device defines the interface for device operations
type Device interface {
	CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error)
	UpdateDevice(ctx context.Context, deviceID string, request *types.DeviceUpdateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) error
}
