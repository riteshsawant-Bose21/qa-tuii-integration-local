package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// Device defines the interface for device operations
type Device interface {
	CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error)
	BulkCreateDevices(ctx context.Context, request *types.BulkDeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.BulkDeviceCreateResponse, error)
	UpdateDevice(ctx context.Context, deviceID string, request *types.DeviceUpdateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) error
	ResetDevice(ctx context.Context, deviceID string, user types.UserAuthorizationResponse, logger *zap.Logger) error
	ClaimDevice(ctx context.Context, deviceID string, request *types.DeviceClaimRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceClaimResponse, error)
	RotateCertificate(ctx context.Context, deviceID string, request *types.DeviceRotateCertRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceRotateCertResponse, error)
	Command(ctx context.Context, request *types.CommandRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (string, error)
	GetCommandStatus(ctx context.Context, commandID string, logger *zap.Logger) (*types.CommandStatusResponse, error)
}
