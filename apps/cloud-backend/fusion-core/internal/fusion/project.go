package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Project interface {
	CreateProject(ctx context.Context, project *types.Project) error
	GetProjectByID(ctx context.Context, id string) (*types.Project, error)
	GetAllProjects(ctx context.Context) ([]*types.Project, error)
	UpdateProject(ctx context.Context, id string, project *types.Project) error
	DeleteProject(ctx context.Context, id string) error

	SyncProject(ctx context.Context, projectID string, metaData map[string]interface{}, zipFileURL string) error
}
