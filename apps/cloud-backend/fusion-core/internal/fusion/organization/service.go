package organization

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Service provides organization-related business logic operations.
type Service struct {
	dbService DatabaseService
}

// DatabaseService defines the database operations required for organization management.
type DatabaseService interface {
	GetAllOrganizations(ctx context.Context, params *types.OrganizationSearchRequest, excludeAccountID string) (*types.OrganizationsOverviewResponse, error)
	GetOrganizationByID(ctx context.Context, organizationID string) (*types.OrganizationDetailsResponse, error)
	CreateOrganization(ctx context.Context, req *types.CreateOrganizationRequest) (*types.Organization, error)
	UpdateOrganization(ctx context.Context, organizationID string, req *types.UpdateOrganizationRequest) (*types.Organization, error)
	DeleteOrganization(ctx context.Context, organizationID string) error
	GetOrganizationStatistics(ctx context.Context) (*types.OrganizationStatistics, error)
	GetOrganizationUsers(ctx context.Context, organizationID string) ([]types.OrganizationUser, error)
	GetOrganizationProjects(ctx context.Context, organizationID string) ([]types.OrganizationProject, error)
	InviteUsersToOrganization(ctx context.Context, organizationID string, req *types.InviteUsersToOrganizationRequest) (*types.InviteUsersToOrganizationResponse, error)
}

// NewService creates a new organization service with the given database service.
func NewService(dbService DatabaseService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	return &Service{
		dbService: dbService,
	}
}

// GetAllOrganizations retrieves all organizations with filtering and pagination
func (s *Service) GetAllOrganizations(ctx context.Context, params *types.OrganizationSearchRequest, excludeAccountID string) (*types.OrganizationsOverviewResponse, error) {
	return s.dbService.GetAllOrganizations(ctx, params, excludeAccountID)
}

// GetOrganizationByID retrieves detailed information about a specific organization
func (s *Service) GetOrganizationByID(ctx context.Context, organizationID string) (*types.OrganizationDetailsResponse, error) {
	return s.dbService.GetOrganizationByID(ctx, organizationID)
}

// CreateOrganization creates a new organization
func (s *Service) CreateOrganization(ctx context.Context, req *types.CreateOrganizationRequest) (*types.Organization, error) {
	return s.dbService.CreateOrganization(ctx, req)
}

// UpdateOrganization updates an existing organization
func (s *Service) UpdateOrganization(ctx context.Context, organizationID string, req *types.UpdateOrganizationRequest) (*types.Organization, error) {
	return s.dbService.UpdateOrganization(ctx, organizationID, req)
}

// DeleteOrganization deletes an organization
func (s *Service) DeleteOrganization(ctx context.Context, organizationID string) error {
	return s.dbService.DeleteOrganization(ctx, organizationID)
}

// GetOrganizationStatistics gets statistics for organizations overview
func (s *Service) GetOrganizationStatistics(ctx context.Context) (*types.OrganizationStatistics, error) {
	return s.dbService.GetOrganizationStatistics(ctx)
}

// GetOrganizationUsers retrieves all users in an organization
func (s *Service) GetOrganizationUsers(ctx context.Context, organizationID string) ([]types.OrganizationUser, error) {
	return s.dbService.GetOrganizationUsers(ctx, organizationID)
}

// GetOrganizationProjects retrieves all projects in an organization
func (s *Service) GetOrganizationProjects(ctx context.Context, organizationID string) ([]types.OrganizationProject, error) {
	return s.dbService.GetOrganizationProjects(ctx, organizationID)
}

// InviteUsersToOrganization invites multiple users to an organization
func (s *Service) InviteUsersToOrganization(ctx context.Context, organizationID string, req *types.InviteUsersToOrganizationRequest) (*types.InviteUsersToOrganizationResponse, error) {
	return s.dbService.InviteUsersToOrganization(ctx, organizationID, req)
}
