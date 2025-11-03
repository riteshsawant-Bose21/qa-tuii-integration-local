package project

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
)

// Service provides methods to interact with the project database
type Service struct {
	dbService DatabaseService
	presigner cloudfs.PresignHandle
}

// DatabaseService defines the interface for database operations related to projects.
type DatabaseService interface {
	Insert(ctx context.Context, project *fusion.ProjectCreateRequest) error
	SelectAll(ctx context.Context, queryParams *fusion.GetAllProjectsParams) ([]*fusion.Project, error)
	Update(ctx context.Context, id string, project *fusion.ProjectUpdateRequest) error
	Delete(ctx context.Context, id string) error
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
