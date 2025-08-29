package project

import (
	"context"
	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion"
)

// Service provides methods to interact with the project database
type Service struct {
	dbService DatabaseService
}

// NewService creates a new project service.
func NewService(dbService DatabaseService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
	}
}

type DatabaseService interface {
	Insert(ctx context.Context, project *fusion.Project) error
	GetByID(ctx context.Context, id string) (*fusion.Project, error)
	GetAll(ctx context.Context) ([]*fusion.Project, error)
	Update(ctx context.Context, id string, project *fusion.Project) error
	Delete(ctx context.Context, id string) error
}

type Project interface {
	Insert(ctx context.Context, project *fusion.Project) error
	GetByID(ctx context.Context, id string) (*fusion.Project, error)
	GetAll(ctx context.Context) ([]*fusion.Project, error)
	Update(ctx context.Context, id string, project *fusion.Project) error
	Delete(ctx context.Context, id string) error
}
