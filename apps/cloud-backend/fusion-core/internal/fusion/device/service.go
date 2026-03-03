package device

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"go.uber.org/zap"
)

// Service orchestrates device operations between IoT and database services.
type Service struct {
	dbService      DatabaseService
	projectService ProjectService
	iotService     cloudfs.IoT
}

// ProjectService defines the contract for project query operations.
type ProjectService interface {
	GetProjectByID(ctx context.Context, projectID string, logger *zap.Logger) (*models.Project, error)
}

// DatabaseService defines the contract for device database operations.
type DatabaseService interface {
	// GetDB returns the database instance for transaction management.
	GetDB(ctx context.Context) model.DBWithTransactions

	// Query operations
	GetDeviceByID(ctx context.Context, deviceID string, logger *zap.Logger) (*models.Device, error)

	// Write operations (all require transaction)
	Insert(ctx context.Context, req *types.DeviceCreateRequest, accountID string, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error
	ClaimDevice(ctx context.Context, device models.Device, accountID string, cert types.CertificateInfo, req *types.DeviceCreateRequest, tx model.DBTxExecutor, logger *zap.Logger) error
	Claim(ctx context.Context, device models.Device, accountID string, cert types.CertificateInfo, projectID string, tx model.DBTxExecutor, logger *zap.Logger) error
	Update(ctx context.Context, device models.Device, req *types.DeviceUpdateRequest, tx model.DBTxExecutor, logger *zap.Logger) error
	UpdateCertificate(ctx context.Context, device models.Device, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error
	Reset(ctx context.Context, device models.Device, tx model.DBTxExecutor, logger *zap.Logger) error
}

// NewService creates a new device service instance.
func NewService(dbService DatabaseService, projectService ProjectService, iotService cloudfs.IoT) *Service {
	return &Service{
		dbService:      dbService,
		projectService: projectService,
		iotService:     iotService,
	}
}
