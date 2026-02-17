package device

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"go.uber.org/zap"
)

type Service struct {
	dbService  DatabaseService
	iotService cloudfs.IoT
}

type DatabaseService interface {
	Insert(ctx context.Context, project *types.DeviceCreateRequest, accountID string, certID *string, logger *zap.Logger) error
	GetDeviceByID(ctx context.Context, deviceID string, logger *zap.Logger) (*models.Device, error)
}

func NewService(dbService DatabaseService, iotService cloudfs.IoT) *Service {
	return &Service{
		dbService:  dbService,
		iotService: iotService,
	}
}
