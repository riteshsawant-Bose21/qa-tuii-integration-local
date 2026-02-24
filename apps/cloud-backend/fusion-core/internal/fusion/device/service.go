package device

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"go.uber.org/zap"
)

// Service is the implementation of the Device interface.
type Service struct {
	dbService  DatabaseService
	iotService cloudfs.IoT
}

//DatabaseService defines the interface for database operations related to devices.
type DatabaseService interface {
	Insert(ctx context.Context, project *types.DeviceCreateRequest, accountID string, certID *string, logger *zap.Logger) error
	GetDeviceByID(ctx context.Context, deviceID string, logger *zap.Logger) (*models.Device, error)
	GetProjectByID(ctx context.Context, projectID string, logger *zap.Logger) (*models.Project, error)
	Update(ctx context.Context, device models.Device, req *types.DeviceUpdateRequest, logger *zap.Logger) error
}

// NewService creates a new instance of the Device service.
func NewService(dbService DatabaseService, iotService cloudfs.IoT) *Service {
	return &Service{
		dbService:  dbService,
		iotService: iotService,
	}
}
