package project

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	"go.uber.org/zap"
)

// Service provides methods to interact with the project database
type Service struct {
	dbService DatabaseService
	presigner cloudfs.PresignHandle
}

// DatabaseService defines the interface for database operations related to projects.
type DatabaseService interface {
	GetProjectByID(ctx context.Context, id string, logger *zap.Logger) (*models.Project, error)
	GetDB(ctx context.Context) model.DBWithTransactions
	Insert(ctx context.Context, project *types.ProjectCreateRequest, accountID string, tx model.DBTxExecutor, logger *zap.Logger) (string, error)
	InsertProjectUser(ctx context.Context, projectID, userID string, tx model.DBTxExecutor, logger *zap.Logger) error
	SelectAll(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse, logger *zap.Logger) ([]types.Project, error)
	SelectByID(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.Project, error)
	GetProjectByIDForAccount(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.Project, error)
	GetProjectByIDForUser(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.Project, error)
	Update(ctx context.Context, projectRow *models.Project, project *types.ProjectUpdateRequest, logger *zap.Logger) error
	Delete(ctx context.Context, projectRow *models.Project, logger *zap.Logger) error
	AssignUser(ctx context.Context, projectID, userID string, logger *zap.Logger) error
	RemoveUser(ctx context.Context, projectID, userID string, logger *zap.Logger) error
	IsUserAssigned(ctx context.Context, projectID, userID string, logger *zap.Logger) (bool, error)
	ProjectExists(ctx context.Context, projectID string, logger *zap.Logger) (bool, error)
	UserExists(ctx context.Context, userID string, logger *zap.Logger) (bool, error)
	GetUserIDByEmail(ctx context.Context, email string, logger *zap.Logger) (string, error)
	StarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error
	UnstarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error
	ArchiveProject(ctx context.Context, projectID string, logger *zap.Logger) error
	UnarchiveProject(ctx context.Context, projectID string, logger *zap.Logger) error
	LockProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error
	UnlockProject(ctx context.Context, projectID string, logger *zap.Logger) error
	GetProjectLockUserID(ctx context.Context, projectID string) (isLocked bool, lockedByUserID string, err error)
	GetUserEmailByID(ctx context.Context, userID string) (string, error)
}

// NewService creates a new project service.
func NewService(dbService DatabaseService, presigner cloudfs.PresignHandle) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
		presigner: presigner,
	}
}
