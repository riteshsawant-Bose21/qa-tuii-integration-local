package types

import "time"

// User represents a user in the system
type User struct {
	ID                string     `json:"id" db:"id"`
	Email             string     `json:"email" db:"email"`
	FullName          string     `json:"full_name" db:"full_name"`
	AccountTypeRoleID int        `json:"account_type_role_id" db:"account_type_role_id"`
	AccountID         string     `json:"account_id" db:"account_id"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at"`
	UpdatedAt         *time.Time `json:"updated_at" db:"updated_at"`
}

// AccountType represents the type of account
type AccountType struct {
	ID          string `json:"id" db:"id"`
	Name        string `json:"name" db:"name"`
	Description string `json:"description" db:"description"`
}

// Account represents an account in the system
type Account struct {
	ID            string    `json:"id" db:"id"`
	Name          string    `json:"name" db:"name"`
	Description   string    `json:"description" db:"description"`
	AccountTypeID string    `json:"account_type_id" db:"account_type_id"`
	CreatedAt     time.Time `json:"created_at" db:"created_at"`
}

// Role represents a role in the system
type Role struct {
	ID          int    `json:"id" db:"id"`
	Name        string `json:"name" db:"name"`
	Description string `json:"description" db:"description"`
}

// AccountTypeRole represents the relationship between account type and role
type AccountTypeRole struct {
	ID            int    `json:"id" db:"id"`
	AccountTypeID string `json:"account_type_id" db:"account_type_id"`
	RoleID        int    `json:"role_id" db:"role_id"`
}

// Feature represents a feature in the system
type Feature struct {
	ID          int    `json:"id" db:"id"`
	Name        string `json:"name" db:"name"`
	Description string `json:"description" db:"description"`
}

// AccessLevel represents access levels for permissions
type AccessLevel struct {
	ID    int    `json:"id" db:"id"`
	Key   string `json:"key" db:"key"`
	Label string `json:"label" db:"label"`
}

// FeaturePermission represents permissions for features
type FeaturePermission struct {
	ID                int       `json:"id" db:"id"`
	FeatureID         int       `json:"feature_id" db:"feature_id"`
	AccountTypeRoleID int       `json:"account_type_role_id" db:"account_type_role_id"`
	AccessLevelID     int       `json:"access_level_id" db:"access_level_id"`
	CreatedAt         time.Time `json:"created_at" db:"created_at"`
}

// UserAuthorizationResponse represents the complete user authorization information
type UserAuthorizationResponse struct {
	User        UserInfo          `json:"user"`
	Account     AccountInfo       `json:"account"`
	Role        RoleInfo          `json:"role"`
	Permissions map[string]string `json:"permissions"`
}

// UserInfo represents simplified user information for the response
type UserInfo struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

// AccountInfo represents account information for the response
type AccountInfo struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Type        string `json:"type"`
}

// RoleInfo represents simplified role information for the response
type RoleInfo struct {
	ID       int    `json:"id"`
	RoleName string `json:"role_name"`
}

// GetUserByEmailRequest represents request to get user by email
type GetUserByEmailRequest struct {
	Email string `json:"email" validate:"required,email"`
}

// CreateUserRequest represents request to create a new user
type CreateUserRequest struct {
	Email             string `json:"email" validate:"required,email"`
	FullName          string `json:"full_name" validate:"required"`
	AccountTypeRoleID int    `json:"account_type_role_id" validate:"required"`
	AccountID         string `json:"account_id" validate:"required"`
}

// UpdateUserRequest represents request to update user information
type UpdateUserRequest struct {
	FullName          *string `json:"full_name,omitempty"`
	AccountTypeRoleID *int    `json:"account_type_role_id,omitempty"`
	AccountID         *string `json:"account_id,omitempty"`
}
