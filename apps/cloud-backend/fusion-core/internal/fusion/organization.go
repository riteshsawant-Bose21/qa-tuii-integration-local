package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Organization defines the interface for organization-related operations
type Organization interface {
	// GetAllOrganizations retrieves all organizations with filtering and pagination
	GetAllOrganizations(ctx context.Context, params *types.OrganizationSearchRequest, excludeAccountID string) (*types.OrganizationsOverviewResponse, error)

	// GetOrganizationByID retrieves detailed information about a specific organization
	GetOrganizationByID(ctx context.Context, organizationID string) (*types.OrganizationDetailsResponse, error)

	// CreateOrganization creates a new organization
	CreateOrganization(ctx context.Context, req *types.CreateOrganizationRequest) (*types.Organization, error)

	// UpdateOrganization updates an existing organization
	UpdateOrganization(ctx context.Context, organizationID string, req *types.UpdateOrganizationRequest) (*types.Organization, error)

	// DeleteOrganization deletes an organization (soft delete recommended)
	DeleteOrganization(ctx context.Context, organizationID string) error

	// GetOrganizationStatistics gets statistics for organizations overview
	GetOrganizationStatistics(ctx context.Context) (*types.OrganizationStatistics, error)

	// GetOrganizationUsers retrieves all users in an organization
	GetOrganizationUsers(ctx context.Context, organizationID string) ([]types.OrganizationUser, error)

	// GetOrganizationProjects retrieves all projects in an organization
	GetOrganizationProjects(ctx context.Context, organizationID string) ([]types.OrganizationProject, error)

	// InviteUsersToOrganization invites multiple users to an organization
	InviteUsersToOrganization(ctx context.Context, organizationID string, req *types.InviteUsersToOrganizationRequest) (*types.InviteUsersToOrganizationResponse, error)
}
