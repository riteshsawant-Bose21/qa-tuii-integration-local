package types

import "time"

// User represents a user in the system
type User struct {
	ID                string     `json:"id" db:"id" example:"usr_123456789"`
	Email             string     `json:"email" db:"email" example:"john.doe@company.com"`
	FullName          string     `json:"full_name" db:"full_name" example:"John Doe"`
	AccountTypeRoleID int        `json:"account_type_role_id" db:"account_type_role_id" example:"1"`
	AccountID         string     `json:"account_id" db:"account_id" example:"acc_987654321"`
	CreatedAt         time.Time  `json:"created_at" db:"created_at" example:"2023-01-15T10:30:00Z"`
	UpdatedAt         *time.Time `json:"updated_at" db:"updated_at" example:"2023-06-20T14:45:00Z"`
}

// AccountType represents the type of account
type AccountType struct {
	ID          string `json:"id" db:"id" example:"at_enterprise"`
	Name        string `json:"name" db:"name" example:"Enterprise"`
	Description string `json:"description" db:"description" example:"Enterprise level account with full features"`
}

// Account represents an account in the system
type Account struct {
	ID            string    `json:"id" db:"id" example:"acc_987654321"`
	Name          string    `json:"name" db:"name" example:"Acme Corporation"`
	Description   string    `json:"description" db:"description" example:"Leading technology company"`
	AccountTypeID string    `json:"account_type_id" db:"account_type_id" example:"at_enterprise"`
	CreatedAt     time.Time `json:"created_at" db:"created_at" example:"2023-01-01T00:00:00Z"`
}

// Role represents a role in the system
type Role struct {
	ID          int    `json:"id" db:"id" example:"1"`
	Name        string `json:"name" db:"name" example:"Admin"`
	Description string `json:"description" db:"description" example:"Administrator with full system access"`
}

// AccountTypeRole represents the relationship between account type and role
type AccountTypeRole struct {
	ID            int    `json:"id" db:"id" example:"1"`
	AccountTypeID string `json:"account_type_id" db:"account_type_id" example:"at_enterprise"`
	RoleID        int    `json:"role_id" db:"role_id" example:"1"`
}

// Feature represents a feature in the system
type Feature struct {
	ID          int    `json:"id" db:"id" example:"1"`
	Name        string `json:"name" db:"name" example:"launcher.project.create"`
	Description string `json:"description" db:"description" example:"Permission to create new projects"`
}

// AccessLevel represents access levels for permissions
type AccessLevel struct {
	ID    int    `json:"id" db:"id" example:"1"`
	Key   string `json:"key" db:"key" example:"full"`
	Label string `json:"label" db:"label" example:"Full Access"`
}

// FeaturePermission represents permissions for features
type FeaturePermission struct {
	ID                int       `json:"id" db:"id" example:"1"`
	FeatureID         int       `json:"feature_id" db:"feature_id" example:"1"`
	AccountTypeRoleID int       `json:"account_type_role_id" db:"account_type_role_id" example:"1"`
	AccessLevelID     int       `json:"access_level_id" db:"access_level_id" example:"1"`
	CreatedAt         time.Time `json:"created_at" db:"created_at" example:"2023-01-15T10:30:00Z"`
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
	ID    string `json:"id" example:"usr_123456789"`
	Email string `json:"email" example:"john.doe@company.com"`
}

// AccountInfo represents account information for the response
type AccountInfo struct {
	ID          string `json:"id" example:"acc_987654321"`
	Name        string `json:"name" example:"Acme Corporation"`
	Description string `json:"description" example:"Leading technology company"`
	Type        string `json:"type" example:"Enterprise"`
}

// RoleInfo represents simplified role information for the response
type RoleInfo struct {
	ID       int    `json:"id" example:"1"`
	RoleName string `json:"role_name" example:"Admin"`
}

// GetUserByEmailRequest represents request to get user by email
type GetUserByEmailRequest struct {
	Email string `json:"email" validate:"required,email" example:"john.doe@company.com"`
}

// CreateUserRequest represents request to create a new user
type CreateUserRequest struct {
	Email             string `json:"email" validate:"required,email" example:"jane.smith@company.com"`
	FullName          string `json:"full_name" validate:"required" example:"Jane Smith"`
	AccountTypeRoleID int    `json:"account_type_role_id" validate:"required" example:"2"`
	AccountID         string `json:"account_id" validate:"required" example:"acc_987654321"`
}

// UpdateUserRequest represents request to update user information
type UpdateUserRequest struct {
	FullName          *string `json:"full_name,omitempty" example:"John Smith"`
	AccountTypeRoleID *int    `json:"account_type_role_id,omitempty" example:"3"`
	AccountID         *string `json:"account_id,omitempty" example:"acc_111222333"`
}
