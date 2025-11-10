package project

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
)

// Service provides methods to interact with the project database
type Service struct {
	dbService DatabaseService
	presigner cloudfs.PresignHandle
}

// DatabaseService defines the interface for database operations related to projects.
type DatabaseService interface {
	Insert(ctx context.Context, project *types.ProjectCreateRequest) (string, error)
	SelectAll(ctx context.Context, queryParams *types.GetAllProjectsParams) ([]*types.Project, error)
	Update(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*models.Project, error)
	Delete(ctx context.Context, id string) error
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

type DatabaseService interface {
	Insert(ctx context.Context, project *fusion.Project) error
	GetByID(ctx context.Context, id string) (*fusion.Project, error)
	GetAll(ctx context.Context) ([]*fusion.Project, error)
	Update(ctx context.Context, id string, project *fusion.Project) error
	Delete(ctx context.Context, id string) error

	SyncProject(ctx context.Context, projectID string, metaData map[string]interface{}, zipFileURL string) error
}

type Project interface {
	Insert(ctx context.Context, project *fusion.Project) error
	GetByID(ctx context.Context, id string) (*fusion.Project, error)
	GetAll(ctx context.Context) ([]*fusion.Project, error)
	Update(ctx context.Context, id string, project *fusion.Project) error
	Delete(ctx context.Context, id string) error

	SyncProject(ctx context.Context, projectID string, metaData map[string]interface{}, zipFileURL string) error
}
