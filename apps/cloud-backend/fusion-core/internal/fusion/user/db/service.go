package db

import (
	"context"
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
)

type Service struct {
	db customModel.DBContextExecutor
}

func NewService(db customModel.DBContextExecutor) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	return &Service{
		db: db,
	}
}

// GetUserByEmail retrieves a user by email from the database
func (s *Service) GetUserByEmail(ctx context.Context, email string) (*types.User, error) {
	appUser, err := models.AppUsers(
		models.AppUserWhere.Email.EQ(email),
	).One(ctx, s.db)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found with email: %s", email)
		}
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	// Convert SQLBoiler model to API type
	user := &types.User{
		ID:                appUser.ID,
		Email:             appUser.Email,
		FullName:          appUser.FullName.String, // Convert null.String to string
		AccountTypeRoleID: appUser.AccountTypeRoleID,
		AccountID:         appUser.AccountID,
		CreatedAt:         appUser.CreatedAt.Time, // Convert null.Time to time.Time
		UpdatedAt:         nil,                    // Convert null.Time to *time.Time
	}

	// Handle nullable UpdatedAt field
	if appUser.UpdatedAt.Valid {
		user.UpdatedAt = &appUser.UpdatedAt.Time
	}

	return user, nil
}

// GetUserAuthorization retrieves complete user authorization information
func (s *Service) GetUserAuthorization(ctx context.Context, email string) (*types.UserAuthorizationResponse, error) {
	// First get the user
	user, err := s.GetUserByEmail(ctx, email)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Get user permissions
	permissions, err := s.getUserPermissions(ctx, user.AccountTypeRoleID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user permissions: %w", err)
	}

	// Get account information
	account, err := models.Accounts(
		models.AccountWhere.ID.EQ(user.AccountID),
		qm.Load(models.AccountRels.AccountType),
	).One(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("failed to get account: %w", err)
	}

	accountInfo := types.AccountInfo{
		ID:          account.ID,
		Name:        account.Name,
		Description: account.Description.String, // Convert null.String to string
		Type:        "",                         // Will be set below
	}

	if account.R != nil && account.R.AccountType != nil {
		accountInfo.Type = account.R.AccountType.Name
	}

	// Get role information
	accountTypeRole, err := models.AccountTypeRoles(
		models.AccountTypeRoleWhere.ID.EQ(user.AccountTypeRoleID),
		qm.Load(models.AccountTypeRoleRels.Role),
	).One(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("failed to get role: %w", err)
	}

	var role types.Role
	if accountTypeRole.R != nil && accountTypeRole.R.Role != nil {
		role = types.Role{
			ID:          accountTypeRole.R.Role.ID,
			Name:        accountTypeRole.R.Role.Name,
			Description: accountTypeRole.R.Role.Description.String, // Convert null.String to string
		}
	}

	return &types.UserAuthorizationResponse{
		User: types.UserInfo{
			ID:    user.ID,
			Email: user.Email,
		},
		Account: accountInfo,
		Role: types.RoleInfo{
			ID:       role.ID,
			RoleName: role.Name,
		},
		Permissions: permissions,
	}, nil
}

// getUserPermissions retrieves all permissions for a user based on their account type role
func (s *Service) getUserPermissions(ctx context.Context, accountTypeRoleID int) (map[string]string, error) {
	featurePermissions, err := models.FeaturePermissions(
		models.FeaturePermissionWhere.AccountTypeRoleID.EQ(accountTypeRoleID),
		qm.Load(models.FeaturePermissionRels.Feature),
		qm.Load(models.FeaturePermissionRels.AccessLevel),
	).All(ctx, s.db)

	if err != nil {
		return nil, fmt.Errorf("failed to query permissions: %w", err)
	}

	permissions := make(map[string]string)
	for _, fp := range featurePermissions {
		if fp.R.Feature != nil && fp.R.AccessLevel != nil {
			permissions[fp.R.Feature.Name] = fp.R.AccessLevel.Key
		}
	}

	return permissions, nil
}

// CheckUserPermission checks if a user has the required permission level for a specific feature
func (s *Service) CheckUserPermission(ctx context.Context, userEmail, featureName string, requiredLevel string) (bool, error) {
	// First try to get permission directly from database
	appUser, err := models.AppUsers(
		models.AppUserWhere.Email.EQ(userEmail),
		qm.Load(models.AppUserRels.AccountTypeRole,
			qm.Load(models.AccountTypeRoleRels.FeaturePermissions,
				qm.Load(models.FeaturePermissionRels.Feature,
					models.FeatureWhere.Name.EQ(featureName),
				),
				qm.Load(models.FeaturePermissionRels.AccessLevel),
			),
		),
	).One(ctx, s.db)

	if err == nil && appUser.R != nil && appUser.R.AccountTypeRole != nil && appUser.R.AccountTypeRole.R != nil {
		for _, fp := range appUser.R.AccountTypeRole.R.FeaturePermissions {
			if fp.R.Feature != nil && fp.R.Feature.Name == featureName && fp.R.AccessLevel != nil {
				return s.isPermissionSufficient(fp.R.AccessLevel.Key, requiredLevel), nil
			}
		}
	}

	return false, nil // No permission found
}

// isPermissionSufficient checks if the user's permission level meets the required level
func (s *Service) isPermissionSufficient(userLevel, requiredLevel string) bool {
	levelHierarchy := map[string]int{
		"none":  0,
		"read":  1,
		"write": 2,
	}

	userLevelInt, userExists := levelHierarchy[strings.ToLower(userLevel)]
	requiredLevelInt, requiredExists := levelHierarchy[strings.ToLower(requiredLevel)]

	if !userExists || !requiredExists {
		return false
	}

	return userLevelInt >= requiredLevelInt
}

// CreateUser creates a new user in the database
func (s *Service) CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error) {
	// Create new AppUser
	appUser := &models.AppUser{
		Email:             req.Email,
		FullName:          null.StringFrom(req.FullName), // Convert string to null.String
		AccountTypeRoleID: req.AccountTypeRoleID,
		AccountID:         req.AccountID,
		CreatedAt:         null.TimeFrom(time.Now()), // Set current time
	}

	err := appUser.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	// Convert SQLBoiler model to API type
	user := &types.User{
		ID:                appUser.ID,
		Email:             appUser.Email,
		FullName:          appUser.FullName.String,
		AccountTypeRoleID: appUser.AccountTypeRoleID,
		AccountID:         appUser.AccountID,
		CreatedAt:         appUser.CreatedAt.Time,
		UpdatedAt:         nil,
	}

	// Handle nullable UpdatedAt field
	if appUser.UpdatedAt.Valid {
		user.UpdatedAt = &appUser.UpdatedAt.Time
	}

	return user, nil
}

// UpdateUser updates an existing user in the database
func (s *Service) UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error) {
	// First, get the existing user
	appUser, err := models.AppUsers(
		models.AppUserWhere.ID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found with ID: %s", userID)
		}
		return nil, fmt.Errorf("failed to get user for update: %w", err)
	}

	// Update fields that are provided
	if req.FullName != nil {
		appUser.FullName = null.StringFrom(*req.FullName)
	}

	if req.AccountTypeRoleID != nil {
		appUser.AccountTypeRoleID = *req.AccountTypeRoleID
	}

	if req.AccountID != nil {
		appUser.AccountID = *req.AccountID
	}

	// Set updated_at
	appUser.UpdatedAt = null.TimeFrom(time.Now())

	// Update the user in database
	_, err = appUser.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	// Convert SQLBoiler model to API type
	user := &types.User{
		ID:                appUser.ID,
		Email:             appUser.Email,
		FullName:          appUser.FullName.String,
		AccountTypeRoleID: appUser.AccountTypeRoleID,
		AccountID:         appUser.AccountID,
		CreatedAt:         appUser.CreatedAt.Time,
		UpdatedAt:         nil,
	}

	// Handle nullable UpdatedAt field
	if appUser.UpdatedAt.Valid {
		user.UpdatedAt = &appUser.UpdatedAt.Time
	}

	return user, nil
}
