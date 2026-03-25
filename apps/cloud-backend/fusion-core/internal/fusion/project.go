package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// Project defines the interface for project-related operations
type Project interface {
	CreateProject(ctx context.Context, project *types.ProjectCreateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectCreateResponse, error)
	GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.GetAllProjectsResponse, error)
	GetProjectById(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.Project, error)
	UpdateProject(ctx context.Context, project *types.ProjectUpdateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectUpdateResponse, error)
	DeleteProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error
	AssignUserToProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error)
	RemoveUserFromProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error)
	StarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error
	UnstarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error
	ArchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error
	UnarchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error
	LockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error
	UnlockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error
	GetProjectLockUserID(ctx context.Context, projectID string) (isLocked bool, lockedByUserID string, err error)
	GetUserEmailByID(ctx context.Context, userID string) (string, error)
	ProjectExists(ctx context.Context, projectID string, logger *zap.Logger) (bool, error)
	IsUserAssigned(ctx context.Context, projectID, userID string, logger *zap.Logger) (bool, error)
}
