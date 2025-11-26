package project

import (
	"context"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

// Service provides methods to interact with the project database
type Service struct {
	dbService DatabaseService
	presigner PresignerService
}

// DatabaseService defines the interface for database operations related to projects.
type DatabaseService interface {
	GetProjectByID(ctx context.Context, id string) (*models.Project, error)
	GetDB(ctx context.Context) model.DBWithTransactions
	Insert(ctx context.Context, project *types.ProjectCreateRequest, accountID string, tx model.DBTxExecutor) (string, error)
	InsertProjectUser(ctx context.Context, projectID, userID string, tx model.DBTxExecutor) error
	SelectAll(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse) ([]types.Project, error)
	Update(ctx context.Context, projectRow *models.Project, project *types.ProjectUpdateRequest) error
	Delete(ctx context.Context, projectRow *models.Project) error
	AssignUser(ctx context.Context, projectID, userID string) error
	RemoveUser(ctx context.Context, projectID, userID string) error
	IsUserAssigned(ctx context.Context, projectID, userID string) (bool, error)
	ProjectExists(ctx context.Context, projectID string) (bool, error)
	UserExists(ctx context.Context, userID string) (bool, error)
	GetUserIDByEmail(ctx context.Context, email string) (string, error)
	StarProject(ctx context.Context, projectID, userID string) error
	UnstarProject(ctx context.Context, projectID, userID string) error
	ArchiveProject(ctx context.Context, projectID string) error
	UnarchiveProject(ctx context.Context, projectID string) error
	LockProject(ctx context.Context, projectID, userID string) error
	UnlockProject(ctx context.Context, projectID string) error
	GetProjectLockUserID(ctx context.Context, projectID string) (isLocked bool, lockedByUserID string, err error)
	GetUserEmailByID(ctx context.Context, userID string) (string, error)
}

// PresignerService defines the interface for generating presigned URLs.
type PresignerService interface {
	PresignGet(ctx context.Context, objectKey string, ttl time.Duration) (string, error)
	PresignPut(ctx context.Context, objectKey string, ttl time.Duration) (string, error)
}

// NewService creates a new project service.
func NewService(dbService DatabaseService, presigner PresignerService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
		presigner: presigner,
	}
}
