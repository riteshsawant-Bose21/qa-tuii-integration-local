package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type User interface {
	// GetUserByEmail retrieves a user by email
	GetUserByEmail(ctx context.Context, email string) (*types.User, error)

	// GetUserAuthorization retrieves complete user authorization information by email
	GetUserAuthorization(ctx context.Context, email string) (*types.UserAuthorizationResponse, error)

	// CheckUserPermission checks if a user has the required permission level for a specific feature
	CheckUserPermission(ctx context.Context, userEmail, featureName string, requiredLevel string) (bool, error)

	// CreateUser creates a new user
	CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error)

	// UpdateUser updates an existing user
	UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error)
}
