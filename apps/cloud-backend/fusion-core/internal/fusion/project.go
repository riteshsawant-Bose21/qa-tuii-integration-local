package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Project interface {
	CreateProject(ctx context.Context, project *types.ProjectCreateRequest, userAuth types.UserAuthorizationResponse) (*types.ProjectCreateResponse, error)
	GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse) (*types.GetAllProjectsResponse, error)
	UpdateProject(ctx context.Context, project *types.ProjectUpdateRequest, userAuth types.UserAuthorizationResponse) (*types.ProjectUpdateResponse, error)
	DeleteProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse) error
	AssignUserToProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse) (*types.UserAssignmentResponse, error)
	RemoveUserFromProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse) (*types.UserAssignmentResponse, error)
	StarProject(ctx context.Context, projectID, userID string) error
	UnstarProject(ctx context.Context, projectID, userID string) error
	ArchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse) error
	UnarchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse) error
	LockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse) error
	UnlockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse) error
	GetProjectLockUserID(ctx context.Context, projectID string) (isLocked bool, lockedByUserID string, err error)
	GetUserEmailByID(ctx context.Context, userID string) (string, error)
	ProjectExists(ctx context.Context, projectID string) (bool, error)
	IsUserAssigned(ctx context.Context, projectID, userID string) (bool, error)
}
