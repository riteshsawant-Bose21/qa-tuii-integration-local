package types

import "time"

// Role Management Types

// CreateRoleRequest represents a request to create a new role
type CreateRoleRequest struct {
	Name        string `json:"name" validate:"required,min=3,max=50" example:"Project Manager"`
	Description string `json:"description" validate:"required,min=10,max=255" example:"Role for managing projects and team members"`
}

// UpdateRoleRequest represents a request to update an existing role
type UpdateRoleRequest struct {
	Name        *string `json:"name,omitempty" validate:"omitempty,min=3,max=50" example:"Senior Project Manager"`
	Description *string `json:"description,omitempty" validate:"omitempty,min=10,max=255" example:"Senior role for managing complex projects and team leadership"`
}

// AssignRoleRequest represents a request to assign a role to a user
type AssignRoleRequest struct {
	UserID int `json:"user_id" validate:"required" example:"123"`
	RoleID int `json:"role_id" validate:"required" example:"2"`
}

// UpdateUserPermissionsRequest represents a request to update user permissions
type UpdateUserPermissionsRequest struct {
	UserID      string                    `json:"user_id" validate:"required" example:"usr_123456789"`
	Permissions []PermissionUpdateRequest `json:"permissions" validate:"required,dive"`
}

// PermissionUpdateRequest represents a single permission update
type PermissionUpdateRequest struct {
	FeatureID     int    `json:"feature_id" validate:"required" example:"1"`
	AccessLevelID int    `json:"access_level_id" validate:"required" example:"2"`
	Action        string `json:"action" validate:"required,oneof=add update remove" example:"update"`
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
	ID          int                       `json:"id" example:"1"`
	Name        string                    `json:"name" example:"Admin"`
	Description string                    `json:"description" example:"Administrator with full system access"`
	Permissions []FeaturePermissionDetail `json:"permissions"`
	UserCount   int                       `json:"user_count" example:"5"`
	CreatedAt   time.Time                 `json:"created_at" example:"2023-01-15T10:30:00Z"`
}

// FeaturePermissionDetail represents detailed permission information
type FeaturePermissionDetail struct {
	FeatureID     int    `json:"feature_id" example:"1"`
	FeatureName   string `json:"feature_name" example:"launcher.project.create"`
	AccessLevelID int    `json:"access_level_id" example:"1"`
	AccessLevel   string `json:"access_level" example:"full"`
	AccessLabel   string `json:"access_label" example:"Full Access"`
}

// UserBasicInfo represents basic user information for role management
type UserBasicInfo struct {
	ID       string `json:"id" example:"usr_123456789"`
	Email    string `json:"email" example:"john.doe@company.com"`
	FullName string `json:"full_name" example:"John Doe"`
	RoleID   int    `json:"role_id" example:"1"`
	RoleName string `json:"role_name" example:"Admin"`
}

// OrganizationUsersResponse represents users within an organization
type OrganizationUsersResponse struct {
	Users   []UserWithRole `json:"users"`
	Account AccountInfo    `json:"account"`
}

// UserWithRole represents a user with their role information
type UserWithRole struct {
	ID       string    `json:"id" example:"usr_123456789"`
	Email    string    `json:"email" example:"john.doe@company.com"`
	FullName string    `json:"full_name" example:"John Doe"`
	Role     RoleInfo  `json:"role"`
	JoinedAt time.Time `json:"joined_at" example:"2023-01-15T10:30:00Z"`
	Status   string    `json:"status" example:"active"` // active, pending, suspended
}
