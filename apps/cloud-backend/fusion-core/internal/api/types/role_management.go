package types

import "time"

// Role Management Types

// CreateRoleRequest represents a request to create a new role
type CreateRoleRequest struct {
	Name        string `json:"name" validate:"required,min=3,max=50"`
	Description string `json:"description" validate:"required,min=10,max=255"`
}

// UpdateRoleRequest represents a request to update an existing role
type UpdateRoleRequest struct {
	Name        *string `json:"name,omitempty" validate:"omitempty,min=3,max=50"`
	Description *string `json:"description,omitempty" validate:"omitempty,min=10,max=255"`
}

// AssignRoleRequest represents a request to assign a role to a user
type AssignRoleRequest struct {
	UserID int `json:"user_id" validate:"required"`
	RoleID int `json:"role_id" validate:"required"`
}

// UpdateUserPermissionsRequest represents a request to update user permissions
type UpdateUserPermissionsRequest struct {
	UserID      string                    `json:"user_id" validate:"required"`
	Permissions []PermissionUpdateRequest `json:"permissions" validate:"required,dive"`
}

// PermissionUpdateRequest represents a single permission update
type PermissionUpdateRequest struct {
	FeatureID     int    `json:"feature_id" validate:"required"`
	AccessLevelID int    `json:"access_level_id" validate:"required"`
	Action        string `json:"action" validate:"required,oneof=add update remove"`
}

// RoleManagementResponse represents the response for role management operations
type RoleManagementResponse struct {
	Roles        []RoleWithPermissions `json:"roles"`
	Features     []Feature             `json:"features"`
	AccessLevels []AccessLevel         `json:"access_levels"`
	Users        []UserBasicInfo       `json:"users"`
}

// RoleWithPermissions represents a role with its associated permissions
type RoleWithPermissions struct {
	ID          int                       `json:"id"`
	Name        string                    `json:"name"`
	Description string                    `json:"description"`
	Permissions []FeaturePermissionDetail `json:"permissions"`
	UserCount   int                       `json:"user_count"`
	CreatedAt   time.Time                 `json:"created_at"`
}

// FeaturePermissionDetail represents detailed permission information
type FeaturePermissionDetail struct {
	FeatureID     int    `json:"feature_id"`
	FeatureName   string `json:"feature_name"`
	AccessLevelID int    `json:"access_level_id"`
	AccessLevel   string `json:"access_level"`
	AccessLabel   string `json:"access_label"`
}

// UserBasicInfo represents basic user information for role management
type UserBasicInfo struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	FullName string `json:"full_name"`
	RoleID   int    `json:"role_id"`
	RoleName string `json:"role_name"`
}

// OrganizationUsersResponse represents users within an organization
type OrganizationUsersResponse struct {
	Users   []UserWithRole `json:"users"`
	Account AccountInfo    `json:"account"`
}

// UserWithRole represents a user with their role information
type UserWithRole struct {
	ID       string    `json:"id"`
	Email    string    `json:"email"`
	FullName string    `json:"full_name"`
	Role     RoleInfo  `json:"role"`
	JoinedAt time.Time `json:"joined_at"`
	Status   string    `json:"status"` // active, pending, suspended
}
