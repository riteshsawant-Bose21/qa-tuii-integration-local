package db

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

// Service provides database operations for organization management
type Service struct {
	db customModel.DBContextExecutor
}

// NewService creates a new organization database service
func NewService(db customModel.DBContextExecutor) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	return &Service{
		db: db,
	}
}

// GetAllOrganizations retrieves all organizations with filtering and pagination
func (s *Service) GetAllOrganizations(ctx context.Context, params *types.OrganizationSearchRequest, excludeAccountID string) (*types.OrganizationsOverviewResponse, error) {
	var queryMods []qm.QueryMod

	// Join with account_type to get type information
	queryMods = append(queryMods, qm.InnerJoin("account_type on account.account_type_id = account_type.id"))

	// Exclude the requesting user's own organization
	if excludeAccountID != "" {
		queryMods = append(queryMods, qm.Where("account.id != ?", excludeAccountID))
	}

	// Apply search filter
	if params.Query != "" {
		queryMods = append(queryMods, qm.Where("account.name ILIKE ?", "%"+params.Query+"%"))
	}

	// Apply type filter
	if len(params.Type) > 0 {
		typeNames := make([]interface{}, len(params.Type))
		placeholders := make([]string, len(params.Type))
		for i, t := range params.Type {
			// Map organization types to account type names
			switch t {
			case types.OrganizationTypeDistributor:
				typeNames[i] = "distributor"
			case types.OrganizationTypeReseller:
				typeNames[i] = "reseller"
			case types.OrganizationTypeEndUser:
				typeNames[i] = "end_user"
			default:
				typeNames[i] = string(t)
			}
			placeholders[i] = "?"
		}
		queryMods = append(queryMods, qm.Where("account_type.name IN ("+strings.Join(placeholders, ",")+")", typeNames...))
	}

	// Apply region filter
	if len(params.Region) > 0 {
		regionValues := make([]interface{}, len(params.Region))
		placeholders := make([]string, len(params.Region))
		for i, r := range params.Region {
			regionValues[i] = r
			placeholders[i] = "?"
		}
		// For now, we'll assume region is stored in description or we'll add a region field later
		queryMods = append(queryMods, qm.Where("account.description ILIKE ANY(ARRAY["+strings.Join(placeholders, ",")+"])", regionValues...))
	}

	// Get total count for pagination
	totalCount, err := models.Accounts(queryMods...).Count(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("failed to get total count: %w", err)
	}

	// Apply pagination
	page := params.Page
	if page <= 0 {
		page = 1
	}
	limit := params.Limit
	if limit <= 0 {
		limit = 10
	}
	offset := (page - 1) * limit
	queryMods = append(queryMods, qm.Limit(limit), qm.Offset(offset))

	// Add select and order by
	queryMods = append(queryMods,
		qm.Select("account.*, account_type.name as type_name"),
		qm.OrderBy("account.created_at DESC"),
	)

	// Execute query
	accounts, err := models.Accounts(queryMods...).All(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("failed to get organizations: %w", err)
	}

	// Convert to API types
	organizations := make([]types.Organization, len(accounts))
	for i, account := range accounts {
		org, err := s.convertAccountToOrganization(ctx, account)
		if err != nil {
			return nil, fmt.Errorf("failed to convert account to organization: %w", err)
		}
		organizations[i] = *org
	}

	// Calculate statistics (excluding requesting user's own organization)
	stats, err := s.getOrganizationStatistics(ctx, excludeAccountID)
	if err != nil {
		return nil, fmt.Errorf("failed to get statistics: %w", err)
	}

	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))

	return &types.OrganizationsOverviewResponse{
		Statistics:    *stats,
		Organizations: organizations,
		Page:          page,
		TotalPages:    totalPages,
		TotalCount:    int(totalCount),
	}, nil
}

// GetOrganizationByID retrieves detailed information about a specific organization
func (s *Service) GetOrganizationByID(ctx context.Context, organizationID string) (*types.OrganizationDetailsResponse, error) {
	account, err := models.Accounts(
		models.AccountWhere.ID.EQ(organizationID),
	).One(ctx, s.db)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("organization not found with ID: %s", organizationID)
		}
		return nil, fmt.Errorf("failed to get organization: %w", err)
	}

	// Convert to API type
	organization, err := s.convertAccountToOrganization(ctx, account)
	if err != nil {
		return nil, err
	}

	// Get organization statistics
	stats := &types.OrganizationStats{
		TotalUsers:        organization.UserCount,
		OngoingProjects:   organization.OngoingProjects,
		CompletedProjects: organization.CompletedProjects,
	}

	// Get organization users (simplified for now)
	users, err := s.GetOrganizationUsers(ctx, organizationID)
	if err != nil {
		return nil, fmt.Errorf("failed to get organization users: %w", err)
	}

	// Get organization projects (simplified for now)
	projects, err := s.GetOrganizationProjects(ctx, organizationID)
	if err != nil {
		return nil, fmt.Errorf("failed to get organization projects: %w", err)
	}

	return &types.OrganizationDetailsResponse{
		Organization: *organization,
		Statistics:   *stats,
		Users:        users,
		Projects:     projects,
	}, nil
}

// CreateOrganization creates a new organization
func (s *Service) CreateOrganization(ctx context.Context, req *types.CreateOrganizationRequest) (*types.Organization, error) {
	// Get or create account type
	accountTypeID, err := s.getAccountTypeID(ctx, string(req.Type))
	if err != nil {
		return nil, fmt.Errorf("failed to get account type: %w", err)
	}

	// Create new account
	account := &models.Account{
		Name:          req.Name,
		Description:   null.StringFrom(req.Description),
		AccountTypeID: accountTypeID,
	}

	err = account.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return nil, fmt.Errorf("failed to create organization: %w", err)
	}

	// Convert to API type
	return s.convertAccountToOrganization(ctx, account)
}

// UpdateOrganization updates an existing organization
func (s *Service) UpdateOrganization(ctx context.Context, organizationID string, req *types.UpdateOrganizationRequest) (*types.Organization, error) {
	account, err := models.FindAccount(ctx, s.db, organizationID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("organization not found with ID: %s", organizationID)
		}
		return nil, fmt.Errorf("failed to find organization: %w", err)
	}

	// Update fields if provided
	if req.Name != "" {
		account.Name = req.Name
	}
	if req.Description != "" {
		account.Description = null.StringFrom(req.Description)
	}
	if req.Type != "" {
		accountTypeID, err := s.getAccountTypeID(ctx, string(req.Type))
		if err != nil {
			return nil, fmt.Errorf("failed to get account type: %w", err)
		}
		account.AccountTypeID = accountTypeID
	}

	_, err = account.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return nil, fmt.Errorf("failed to update organization: %w", err)
	}

	return s.convertAccountToOrganization(ctx, account)
}

// DeleteOrganization deletes an organization
func (s *Service) DeleteOrganization(ctx context.Context, organizationID string) error {
	account, err := models.FindAccount(ctx, s.db, organizationID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("organization not found with ID: %s", organizationID)
		}
		return fmt.Errorf("failed to find organization: %w", err)
	}

	_, err = account.Delete(ctx, s.db)
	if err != nil {
		return fmt.Errorf("failed to delete organization: %w", err)
	}

	return nil
}

// GetOrganizationStatistics gets statistics for organizations overview
func (s *Service) GetOrganizationStatistics(ctx context.Context) (*types.OrganizationStatistics, error) {
	return s.getOrganizationStatistics(ctx, "")
}

// GetOrganizationUsers retrieves all users in an organization
func (s *Service) GetOrganizationUsers(ctx context.Context, organizationID string) ([]types.OrganizationUser, error) {
	// Get users for this organization
	users, err := models.AppUsers(
		models.AppUserWhere.AccountID.EQ(organizationID),
		qm.Load("AccountTypeRole.Role"),
	).All(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("failed to get organization users: %w", err)
	}

	orgUsers := make([]types.OrganizationUser, len(users))
	for i, user := range users {
		roleName := "User"
		if user.R.AccountTypeRole != nil && user.R.AccountTypeRole.R.Role != nil {
			roleName = user.R.AccountTypeRole.R.Role.Name
		}

		orgUsers[i] = types.OrganizationUser{
			ID:       user.ID,
			Name:     user.FullName.String,
			Email:    user.Email,
			Role:     roleName,
			JoinedAt: user.CreatedAt.Time,
		}
	}

	return orgUsers, nil
}

// GetOrganizationProjects retrieves all projects in an organization
func (s *Service) GetOrganizationProjects(ctx context.Context, organizationID string) ([]types.OrganizationProject, error) {
	// Get projects for this organization using PrimaryOwnerAccountID
	projects, err := models.Projects(
		models.ProjectWhere.PrimaryOwnerAccountID.EQ(organizationID),
	).All(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("failed to get organization projects: %w", err)
	}

	orgProjects := make([]types.OrganizationProject, len(projects))
	for i, project := range projects {
		// Handle null.String fields properly
		projectName := "Unnamed Project"
		if project.Name.Valid {
			projectName = project.Name.String
		}

		orgProjects[i] = types.OrganizationProject{
			ID:          project.ID,
			Name:        projectName,
			Type:        "General", // Default type since field doesn't exist
			Status:      "Active",  // Default status since field doesn't exist
			LastUpdated: project.UpdatedAt,
		}
	}

	return orgProjects, nil
}

// Helper functions

// convertAccountToOrganization converts a database Account to API Organization type
func (s *Service) convertAccountToOrganization(ctx context.Context, account *models.Account) (*types.Organization, error) {
	// Get account type information
	accountType, err := models.FindAccountType(ctx, s.db, account.AccountTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get account type: %w", err)
	}

	// Map account type to organization type
	var orgType types.OrganizationType
	switch strings.ToLower(accountType.Name) {
	case "distributor":
		orgType = types.OrganizationTypeDistributor
	case "reseller":
		orgType = types.OrganizationTypeReseller
	case "end_user":
		orgType = types.OrganizationTypeEndUser
	default:
		orgType = types.OrganizationType(accountType.Name)
	}

	// Get user count for this organization
	userCount, err := models.AppUsers(
		models.AppUserWhere.AccountID.EQ(account.ID),
	).Count(ctx, s.db)
	if err != nil {
		// Log error but don't fail - default to 0
		userCount = 0
	}

	// Get project counts using PrimaryOwnerAccountID
	ongoingCount, _ := models.Projects(
		models.ProjectWhere.PrimaryOwnerAccountID.EQ(account.ID),
	).Count(ctx, s.db)

	// Set completed to 0 since no status field exists in the schema
	completedCount := int64(0)

	// Extract region from description (simple approach for now)
	region := "Unknown"
	if account.Description.Valid {
		desc := account.Description.String
		if strings.Contains(desc, "North America") {
			region = "North America"
		} else if strings.Contains(desc, "Europe") {
			region = "Europe"
		} else if strings.Contains(desc, "Asia") {
			region = "Asia"
		}
	}

	return &types.Organization{
		ID:                account.ID,
		Name:              account.Name,
		Type:              orgType,
		Region:            region,
		Description:       account.Description.String,
		UserCount:         int(userCount),
		OngoingProjects:   int(ongoingCount),
		CompletedProjects: int(completedCount),
		CreatedAt:         account.CreatedAt.Time,
		UpdatedAt:         account.CreatedAt.Time, // Use CreatedAt for now since there's no UpdatedAt
	}, nil
}

// getOrganizationStatistics calculates overall organization statistics
func (s *Service) getOrganizationStatistics(ctx context.Context, excludeAccountID string) (*types.OrganizationStatistics, error) {
	// Build base query mods for excluding user's own organization
	var baseQueryMods []qm.QueryMod
	baseQueryMods = append(baseQueryMods, qm.InnerJoin("account_type on account.account_type_id = account_type.id"))
	if excludeAccountID != "" {
		baseQueryMods = append(baseQueryMods, qm.Where("account.id != ?", excludeAccountID))
	}

	// Get distributor count (case-insensitive)
	distributorQueryMods := append(baseQueryMods, qm.Where("LOWER(account_type.name) = LOWER(?)", "distributor"))
	distributorCount, err := models.Accounts(distributorQueryMods...).Count(ctx, s.db)
	if err != nil {
		distributorCount = 0
	}

	// Get reseller count (case-insensitive)
	resellerQueryMods := append(baseQueryMods, qm.Where("LOWER(account_type.name) = LOWER(?)", "reseller"))
	resellerCount, err := models.Accounts(resellerQueryMods...).Count(ctx, s.db)
	if err != nil {
		resellerCount = 0
	}

	// Get end user count (case-insensitive)
	endUserQueryMods := append(baseQueryMods, qm.Where("LOWER(account_type.name) = LOWER(?)", "end_user"))
	endUserCount, err := models.Accounts(endUserQueryMods...).Count(ctx, s.db)
	if err != nil {
		endUserCount = 0
	}

	return &types.OrganizationStatistics{
		TotalDistributors: int(distributorCount),
		TotalResellers:    int(resellerCount),
		TotalEndUsers:     int(endUserCount),
	}, nil
}

// getAccountTypeID gets or creates an account type by name
func (s *Service) getAccountTypeID(ctx context.Context, typeName string) (string, error) {
	accountType, err := models.AccountTypes(
		models.AccountTypeWhere.Name.EQ(typeName),
	).One(ctx, s.db)
	if err != nil {
		// Account type doesn't exist, create it
		if err == sql.ErrNoRows {
			newAccountType := &models.AccountType{
				Name:        typeName,
				Description: null.StringFrom("Organization type: " + typeName),
			}
			err = newAccountType.Insert(ctx, s.db, boil.Infer())
			if err != nil {
				return "", fmt.Errorf("failed to create account type: %w", err)
			}
			return newAccountType.ID, nil
		}
		return "", fmt.Errorf("failed to get account type: %w", err)
	}
	return accountType.ID, nil
}

// InviteUsersToOrganization invites multiple users to an organization
func (s *Service) InviteUsersToOrganization(ctx context.Context, organizationID string, req *types.InviteUsersToOrganizationRequest) (*types.InviteUsersToOrganizationResponse, error) {
	// First, verify that the organization exists
	_, err := models.FindAccount(ctx, s.db, organizationID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("organization not found with ID: %s", organizationID)
		}
		return nil, fmt.Errorf("failed to verify organization: %w", err)
	}

	results := make([]types.InviteUserResult, len(req.Users))
	successCount := 0

	for i, userInvite := range req.Users {
		result, success := s.inviteUser(ctx, organizationID, userInvite)
		results[i] = result
		if success {
			successCount++
		}
	}

	return &types.InviteUsersToOrganizationResponse{
		OrganizationID: organizationID,
		Results:        results,
		TotalInvited:   successCount,
		TotalFailed:    len(req.Users) - successCount,
	}, nil
}

// inviteUser handles the invitation of a single user to an organization
func (s *Service) inviteUser(ctx context.Context, organizationID string, userInvite types.InviteUserToOrganizationRequest) (types.InviteUserResult, bool) {
	// Check if user already exists
	existingUser, err := models.AppUsers(
		models.AppUserWhere.Email.EQ(userInvite.Email),
	).One(ctx, s.db)

	if err != nil && err != sql.ErrNoRows {
		return types.InviteUserResult{
			Email:   userInvite.Email,
			Success: false,
			Message: "Failed to check existing user: " + err.Error(),
		}, false
	}

	var userID string

	if err == sql.ErrNoRows {
		// User doesn't exist, create new user
		newUser := &models.AppUser{
			Email:     userInvite.Email,
			AccountID: organizationID,
		}

		err = newUser.Insert(ctx, s.db, boil.Infer())
		if err != nil {
			return types.InviteUserResult{
				Email:   userInvite.Email,
				Success: false,
				Message: "Failed to create new user: " + err.Error(),
			}, false
		}
		userID = newUser.ID
	} else {
		// User exists, check if already in organization
		if existingUser.AccountID == organizationID {
			return types.InviteUserResult{
				Email:   userInvite.Email,
				Success: false,
				Message: "User is already a member of this organization",
			}, false
		}

		// Update user's organization
		existingUser.AccountID = organizationID
		_, err = existingUser.Update(ctx, s.db, boil.Infer())
		if err != nil {
			return types.InviteUserResult{
				Email:   userInvite.Email,
				Success: false,
				Message: "Failed to update user organization: " + err.Error(),
			}, false
		}
		userID = existingUser.ID
	}

	// TODO: In a real implementation, you would:
	// 1. Create a role assignment for the user based on userInvite.Role
	// 2. Send an invitation email to the user
	// 3. Create an invitation record with expiration

	return types.InviteUserResult{
		Email:   userInvite.Email,
		Success: true,
		Message: "User invited successfully",
		UserID:  userID,
	}, true
}
