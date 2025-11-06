package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Project interface {
	CreateProject(ctx context.Context, project *types.ProjectCreateRequest) (*types.ProjectCreateResponse, error)
	GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams) (*types.GetAllProjectsResponse, error)
	UpdateProject(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*types.ProjectUpdateResponse, error)
	DeleteProject(ctx context.Context, id string) error
	AssignUserToProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error)
	RemoveUserFromProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error)
	AssignUserToProjectByEmail(ctx context.Context, projectID, userEmail string) (*types.UserAssignmentResponse, error)
	RemoveUserFromProjectByEmail(ctx context.Context, projectID, userEmail string) (*types.UserAssignmentResponse, error)
}
