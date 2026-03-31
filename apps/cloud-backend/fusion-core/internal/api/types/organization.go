package types

import (
	"time"
)

// OrganizationType represents different types of organizations
type OrganizationType string

const (
	OrganizationTypeDistributor OrganizationType = "distributor"
	OrganizationTypeReseller    OrganizationType = "reseller"
	OrganizationTypeEndUser     OrganizationType = "end_user"
)

// Organization represents an organization in the system
type Organization struct {
	ID                string           `json:"id" db:"id" example:"org_123456789"`
	Name              string           `json:"name" db:"name" example:"ProAudio Distribution NA"`
	Type              OrganizationType `json:"type" db:"type" example:"distributor"`
	Region            string           `json:"region" db:"region" example:"North America"`
	Description       string           `json:"description" db:"description" example:"Leading audio distribution company"`
	UserCount         int              `json:"user_count" example:"2"`
	OngoingProjects   int              `json:"ongoing_projects" example:"1"`
	CompletedProjects int              `json:"completed_projects" example:"0"`
	CreatedAt         time.Time        `json:"created_at" db:"created_at" example:"2023-01-15T10:30:00Z"`
	UpdatedAt         time.Time        `json:"updated_at" db:"updated_at" example:"2023-06-20T14:45:00Z"`
}

// OrganizationStatistics represents statistics for organizations overview
type OrganizationStatistics struct {
	TotalDistributors int `json:"total_distributors" example:"2"`
	TotalResellers    int `json:"total_resellers" example:"1"`
	TotalEndUsers     int `json:"total_end_users" example:"3"`
}

// OrganizationsOverviewResponse represents the response for organizations overview
type OrganizationsOverviewResponse struct {
	Statistics    OrganizationStatistics `json:"statistics"`
	Organizations []Organization         `json:"organizations"`
	Page          int                    `json:"page" example:"1"`
	TotalPages    int                    `json:"total_pages" example:"1"`
	TotalCount    int                    `json:"total_count" example:"6"`
}

// OrganizationUser represents a user within an organization
type OrganizationUser struct {
	ID       string    `json:"id" example:"usr_123456789"`
	Name     string    `json:"name" example:"Mike Chen"`
	Email    string    `json:"email" example:"mike.chen@proaudio.com"`
	Role     string    `json:"role" example:"Partner Admin"`
	JoinedAt time.Time `json:"joined_at" example:"2024-04-01T00:00:00Z"`
}

// OrganizationProject represents a project within an organization
type OrganizationProject struct {
	ID          string    `json:"id" example:"proj_123456789"`
	Name        string    `json:"name" example:"Government Building Retrofit"`
	Type        string    `json:"type" example:"opportunity"`
	Status      string    `json:"status" example:"active"`
	LastUpdated time.Time `json:"last_updated" example:"2026-02-05T00:00:00Z"`
}

// OrganizationDetailsResponse represents detailed organization information
type OrganizationDetailsResponse struct {
	Organization Organization          `json:"organization"`
	Statistics   OrganizationStats     `json:"statistics"`
	Users        []OrganizationUser    `json:"users"`
	Projects     []OrganizationProject `json:"projects"`
}

// OrganizationStats represents organization-specific statistics
type OrganizationStats struct {
	TotalUsers        int `json:"total_users" example:"2"`
	OngoingProjects   int `json:"ongoing_projects" example:"1"`
	CompletedProjects int `json:"completed_projects" example:"0"`
}

// CreateOrganizationRequest represents a request to create a new organization
type CreateOrganizationRequest struct {
	Name        string           `json:"name" validate:"required,min=3,max=100" example:"ProAudio Distribution NA"`
	Type        OrganizationType `json:"type" validate:"required,oneof=distributor reseller end_user" example:"distributor"`
	Region      string           `json:"region" validate:"required,min=3,max=50" example:"North America"`
	Description string           `json:"description" validate:"max=255" example:"Leading audio distribution company"`
}

// UpdateOrganizationRequest represents a request to update an existing organization
type UpdateOrganizationRequest struct {
	Name        string           `json:"name,omitempty" validate:"omitempty,min=3,max=100" example:"ProAudio Distribution NA"`
	Type        OrganizationType `json:"type,omitempty" validate:"omitempty,oneof=distributor reseller end_user" example:"distributor"`
	Region      string           `json:"region,omitempty" validate:"omitempty,min=3,max=50" example:"North America"`
	Description string           `json:"description,omitempty" validate:"omitempty,max=255" example:"Leading audio distribution company"`
}

// OrganizationSearchRequest represents search parameters for organizations
type OrganizationSearchRequest struct {
	Query  string             `json:"query,omitempty" form:"query" example:"ProAudio"`
	Type   []OrganizationType `json:"type,omitempty" form:"type" example:"distributor,reseller"`
	Region []string           `json:"region,omitempty" form:"region" example:"North America,Europe"`
	Page   int                `json:"page,omitempty" form:"page" example:"1"`
	Limit  int                `json:"limit,omitempty" form:"limit" example:"10"`
}

// InviteUserToOrganizationRequest represents a single user invitation
type InviteUserToOrganizationRequest struct {
	Email string `json:"email" validate:"required,email" example:"john.doe@example.com"`
	Role  string `json:"role" validate:"required,min=3,max=50" example:"Partner Admin"`
}

// InviteUsersToOrganizationRequest represents a request to invite multiple users to an organization
type InviteUsersToOrganizationRequest struct {
	Users []InviteUserToOrganizationRequest `json:"users" validate:"required,min=1,max=20"`
}

// InviteUserResult represents the result of a single user invitation
type InviteUserResult struct {
	Email   string `json:"email" example:"john.doe@example.com"`
	Success bool   `json:"success" example:"true"`
	Message string `json:"message,omitempty" example:"User invited successfully"`
	UserID  string `json:"user_id,omitempty" example:"usr_123456789"`
}

// InviteUsersToOrganizationResponse represents the response for inviting multiple users
type InviteUsersToOrganizationResponse struct {
	OrganizationID string             `json:"organization_id" example:"org_123456789"`
	Results        []InviteUserResult `json:"results"`
	TotalInvited   int                `json:"total_invited" example:"2"`
	TotalFailed    int                `json:"total_failed" example:"0"`
}
