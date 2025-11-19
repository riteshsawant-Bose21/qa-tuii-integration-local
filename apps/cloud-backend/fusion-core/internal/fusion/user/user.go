package user

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// GetUserByEmail retrieves a user by email
func (s *Service) GetUserByEmail(ctx context.Context, email string) (*types.User, error) {
	return s.dbService.GetUserByEmail(ctx, email)
}

// GetUserAuthorization retrieves complete user authorization information
func (s *Service) GetUserAuthorization(ctx context.Context, email string) (*types.UserAuthorizationResponse, error) {
	return s.dbService.GetUserAuthorization(ctx, email)
}

// CheckUserPermission checks if a user has the required permission level for a specific feature
func (s *Service) CheckUserPermission(ctx context.Context, userEmail, featureName string, requiredLevel string) (bool, error) {
	return s.dbService.CheckUserPermission(ctx, userEmail, featureName, requiredLevel)
}

// CreateUser creates a new user
func (s *Service) CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error) {
	// Add any business logic validation here
	if req.Email == "" {
		return nil, fmt.Errorf("email is required")
	}
	if req.FullName == "" {
		return nil, fmt.Errorf("full name is required")
	}

	return s.dbService.CreateUser(ctx, req)
}

// UpdateUser updates an existing user
func (s *Service) UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required")
	}

	return s.dbService.UpdateUser(ctx, userID, req)
}
