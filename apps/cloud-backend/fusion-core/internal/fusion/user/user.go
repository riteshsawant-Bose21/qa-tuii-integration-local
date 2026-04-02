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

// Role Management Methods

// GetOrganizationRoleManagement retrieves complete role management data for an organization
func (s *Service) GetOrganizationRoleManagement(ctx context.Context, accountID string) (*types.RoleManagementResponse, error) {
	if accountID == "" {
		return nil, fmt.Errorf("account ID is required")
	}
	return s.dbService.GetOrganizationRoleManagement(ctx, accountID)
}

// CreateRole creates a new role for an organization
func (s *Service) CreateRole(ctx context.Context, accountID string, req *types.CreateRoleRequest) (*types.Role, error) {
	if accountID == "" {
		return nil, fmt.Errorf("account ID is required")
	}
	if req.Name == "" {
		return nil, fmt.Errorf("role name is required")
	}
	return s.dbService.CreateRole(ctx, accountID, req)
}

// UpdateUserRole updates the role assignment for a user
func (s *Service) UpdateUserRole(ctx context.Context, userID, accountID string, newRoleID int) error {
	if userID == "" {
		return fmt.Errorf("user ID is required")
	}
	if accountID == "" {
		return fmt.Errorf("account ID is required")
	}
	if newRoleID <= 0 {
		return fmt.Errorf("valid role ID is required")
	}
	return s.dbService.UpdateUserRole(ctx, userID, accountID, newRoleID)
}

// UpdateRolePermissions updates permissions for a specific role
func (s *Service) UpdateRolePermissions(ctx context.Context, roleID int, accountID string, permissions []types.PermissionUpdateRequest) error {
	if roleID <= 0 {
		return fmt.Errorf("valid role ID is required")
	}
	if accountID == "" {
		return fmt.Errorf("account ID is required")
	}
	return s.dbService.UpdateRolePermissions(ctx, roleID, accountID, permissions)
}

// CheckAdminPermission verifies if a user has admin permissions for role management
func (s *Service) CheckAdminPermission(ctx context.Context, userEmail, accountID string) (bool, error) {
	if userEmail == "" {
		return false, fmt.Errorf("user email is required")
	}
	if accountID == "" {
		return false, fmt.Errorf("account ID is required")
	}
	return s.dbService.CheckAdminPermission(ctx, userEmail, accountID)
}
