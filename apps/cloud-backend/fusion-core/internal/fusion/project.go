package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Project interface {
	CreateProject(ctx context.Context, project *types.ProjectCreateRequest) error
	GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams) (*types.GetAllProjectsResponse, error)
	UpdateProject(ctx context.Context, id string, project *types.ProjectUpdateRequest) error
	DeleteProject(ctx context.Context, id string) error
}