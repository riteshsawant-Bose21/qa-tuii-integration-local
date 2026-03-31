package db

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Role Management Methods

// GetOrganizationRoleManagement retrieves all role management data for an organization
func (s *Service) GetOrganizationRoleManagement(ctx context.Context, accountID string) (*types.RoleManagementResponse, error) {
	response := &types.RoleManagementResponse{}

	// Get roles with permissions for this organization
	roles, err := s.getRolesWithPermissions(ctx, accountID)
	if err != nil {
		return nil, fmt.Errorf("failed to get roles: %w", err)
	}
	response.Roles = roles

	// Get all available features
	features, err := s.getAllFeatures(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get features: %w", err)
	}
	response.Features = features

	// Get all access levels
	accessLevels, err := s.getAllAccessLevels(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get access levels: %w", err)
	}
	response.AccessLevels = accessLevels

	// Get users in this organization
	users, err := s.getOrganizationUsers(ctx, accountID)
	if err != nil {
		return nil, fmt.Errorf("failed to get users: %w", err)
	}
	response.Users = users

	return response, nil
}

// CreateRole creates a new role for an organization
func (s *Service) CreateRole(ctx context.Context, accountID string, req *types.CreateRoleRequest) (*types.Role, error) {
	// Create the role
	var role types.Role
	roleQuery := `
		INSERT INTO role (name, description) 
		VALUES ($1, $2) 
		RETURNING id, name, description
	`
	err := s.db.QueryRowContext(ctx, roleQuery, req.Name, req.Description).Scan(
		&role.ID, &role.Name, &role.Description,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create role: %w", err)
	}

	// Get the account type for this account
	var accountTypeID string
	accountTypeQuery := `SELECT account_type_id FROM account WHERE id = $1`
	err = s.db.QueryRowContext(ctx, accountTypeQuery, accountID).Scan(&accountTypeID)
	if err != nil {
		return nil, fmt.Errorf("failed to get account type: %w", err)
	}

	// Create account_type_role association
	atrQuery := `
		INSERT INTO account_type_role (account_type_id, role_id) 
		VALUES ($1, $2)
	`
	_, err = s.db.ExecContext(ctx, atrQuery, accountTypeID, role.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to create account_type_role association: %w", err)
	}

	return &role, nil
}

// UpdateUserRole updates the role assignment for a user
func (s *Service) UpdateUserRole(ctx context.Context, userID, accountID string, newRoleID int) error {
	// Get the account_type_role_id for the new role and account
	var accountTypeRoleID int
	query := `
		SELECT atr.id 
		FROM account_type_role atr
		JOIN account a ON atr.account_type_id = a.account_type_id
		WHERE a.id = $1 AND atr.role_id = $2
	`
	err := s.db.QueryRowContext(ctx, query, accountID, newRoleID).Scan(&accountTypeRoleID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("role %d not available for account %s", newRoleID, accountID)
		}
		return fmt.Errorf("failed to get account_type_role_id: %w", err)
	}

	// Update the user's role
	updateQuery := `
		UPDATE app_user 
		SET account_type_role_id = $1, updated_at = NOW()
		WHERE id = $2 AND account_id = $3
	`
	result, err := s.db.ExecContext(ctx, updateQuery, accountTypeRoleID, userID, accountID)
	if err != nil {
		return fmt.Errorf("failed to update user role: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("user %s not found in account %s", userID, accountID)
	}

	return nil
}

// UpdateRolePermissions updates permissions for a specific role
func (s *Service) UpdateRolePermissions(ctx context.Context, roleID int, accountID string, permissions []types.PermissionUpdateRequest) error {
	// Get account_type_role_id
	var accountTypeRoleID int
	atrQuery := `
		SELECT atr.id 
		FROM account_type_role atr
		JOIN account a ON atr.account_type_id = a.account_type_id
		WHERE a.id = $1 AND atr.role_id = $2
	`
	err := s.db.QueryRowContext(ctx, atrQuery, accountID, roleID).Scan(&accountTypeRoleID)
	if err != nil {
		return fmt.Errorf("failed to get account_type_role_id: %w", err)
	}

	// Process each permission update
	for _, perm := range permissions {
		switch perm.Action {
		case "add", "update":
			// Insert or update permission
			upsertQuery := `
				INSERT INTO feature_permission (feature_id, account_type_role_id, access_level_id, created_at)
				VALUES ($1, $2, $3, NOW())
				ON CONFLICT (feature_id, account_type_role_id) 
				DO UPDATE SET access_level_id = $3
			`
			_, err = s.db.ExecContext(ctx, upsertQuery, perm.FeatureID, accountTypeRoleID, perm.AccessLevelID)
			if err != nil {
				return fmt.Errorf("failed to upsert permission for feature %d: %w", perm.FeatureID, err)
			}

		case "remove":
			// Remove permission
			deleteQuery := `
				DELETE FROM feature_permission 
				WHERE feature_id = $1 AND account_type_role_id = $2
			`
			_, err = s.db.ExecContext(ctx, deleteQuery, perm.FeatureID, accountTypeRoleID)
			if err != nil {
				return fmt.Errorf("failed to remove permission for feature %d: %w", perm.FeatureID, err)
			}
		}
	}

	return nil
}

// CheckAdminPermission verifies if a user has admin permissions for role management
func (s *Service) CheckAdminPermission(ctx context.Context, userEmail, accountID string) (bool, error) {
	// First, try to check database permissions
	dbQuery := `
		SELECT COUNT(*)
		FROM app_user u
		JOIN account_type_role atr ON u.account_type_role_id = atr.id
		JOIN role r ON atr.role_id = r.id
		JOIN feature_permission fp ON atr.id = fp.account_type_role_id
		JOIN feature f ON fp.feature_id = f.id
		JOIN access_level al ON fp.access_level_id = al.id
		WHERE u.email = $1 
		  AND u.account_id = $2 
		  AND (f.name IN ('launcher.role.manage', 'launcher.user.create', 'launcher.user.update', 'launcher.user.delete', 'admin', '*')
		       OR (f.name LIKE 'launcher.user.%' AND al.key IN ('admin', 'full')))
		  AND al.key IN ('admin', 'full')
	`

	var count int
	err := s.db.QueryRowContext(ctx, dbQuery, userEmail, accountID).Scan(&count)
	if err == nil && count > 0 {
		return true, nil
	}

	// If database permissions not found, check for admin role names as fallback
	roleQuery := `
		SELECT r.name
		FROM app_user u
		JOIN account_type_role atr ON u.account_type_role_id = atr.id
		JOIN role r ON atr.role_id = r.id
		WHERE u.email = $1 AND u.account_id = $2
	`

	var roleName string
	err = s.db.QueryRowContext(ctx, roleQuery, userEmail, accountID).Scan(&roleName)
	if err != nil {
		return false, fmt.Errorf("failed to check admin permission: %w", err)
	}

	// Check for common admin role patterns
	adminRolePatterns := []string{
		"Admin", "admin", "ADMIN",
		"Reseller Admin", "reseller admin", "RESELLER ADMIN",
		"Organization Admin", "organization admin", "ORGANIZATION ADMIN",
		"Super Admin", "super admin", "SUPER ADMIN",
		"User Management", "user management", "USER MANAGEMENT",
	}

	for _, pattern := range adminRolePatterns {
		if roleName == pattern {
			return true, nil
		}
	}
	return false, nil
}

// Helper methods for role management

// getRolesWithPermissions retrieves all roles for an account with their permissions
func (s *Service) getRolesWithPermissions(ctx context.Context, accountID string) ([]types.RoleWithPermissions, error) {
	query := `
		SELECT DISTINCT r.id, r.name, r.description
		FROM role r
		JOIN account_type_role atr ON r.id = atr.role_id
		JOIN account a ON atr.account_type_id = a.account_type_id
		WHERE a.id = $1
		ORDER BY r.name
	`

	rows, err := s.db.QueryContext(ctx, query, accountID)
	if err != nil {
		return nil, fmt.Errorf("failed to query roles: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			_ = err // Explicitly handle the error by acknowledging it
		}
	}()

	var roles []types.RoleWithPermissions
	for rows.Next() {
		var role types.RoleWithPermissions
		err := rows.Scan(&role.ID, &role.Name, &role.Description)
		if err != nil {
			return nil, fmt.Errorf("failed to scan role: %w", err)
		}

		// Get permissions for this role
		permissions, err := s.getRolePermissions(ctx, role.ID, accountID)
		if err != nil {
			return nil, fmt.Errorf("failed to get permissions for role %d: %w", role.ID, err)
		}
		role.Permissions = permissions

		// Get user count for this role
		userCount, err := s.getRoleUserCount(ctx, role.ID, accountID)
		if err != nil {
			return nil, fmt.Errorf("failed to get user count for role %d: %w", role.ID, err)
		}
		role.UserCount = userCount

		roles = append(roles, role)
	}

	return roles, nil
}

// getRolePermissions retrieves permissions for a specific role
func (s *Service) getRolePermissions(ctx context.Context, roleID int, accountID string) ([]types.FeaturePermissionDetail, error) {
	query := `
		SELECT 
			f.id as feature_id, f.name as feature_name,
			al.id as access_level_id, al.key as access_level, al.label as access_label
		FROM feature_permission fp
		JOIN feature f ON fp.feature_id = f.id
		JOIN access_level al ON fp.access_level_id = al.id
		JOIN account_type_role atr ON fp.account_type_role_id = atr.id
		JOIN account a ON atr.account_type_id = a.account_type_id
		WHERE atr.role_id = $1 AND a.id = $2
		ORDER BY f.name
	`

	rows, err := s.db.QueryContext(ctx, query, roleID, accountID)
	if err != nil {
		return nil, fmt.Errorf("failed to query role permissions: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			_ = err
		}
	}()

	var permissions []types.FeaturePermissionDetail
	for rows.Next() {
		var perm types.FeaturePermissionDetail
		err := rows.Scan(
			&perm.FeatureID, &perm.FeatureName,
			&perm.AccessLevelID, &perm.AccessLevel, &perm.AccessLabel,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan permission: %w", err)
		}
		permissions = append(permissions, perm)
	}

	return permissions, nil
}

// getRoleUserCount gets the number of users assigned to a role
func (s *Service) getRoleUserCount(ctx context.Context, roleID int, accountID string) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM app_user u
		JOIN account_type_role atr ON u.account_type_role_id = atr.id
		WHERE atr.role_id = $1 AND u.account_id = $2
	`

	var count int
	err := s.db.QueryRowContext(ctx, query, roleID, accountID).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to get role user count: %w", err)
	}

	return count, nil
}

// getAllFeatures retrieves all available features
func (s *Service) getAllFeatures(ctx context.Context) ([]types.Feature, error) {
	query := `SELECT id, name, description FROM feature ORDER BY name`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query features: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			_ = err // Explicitly acknowledge the error
		}
	}()

	var features []types.Feature
	for rows.Next() {
		var feature types.Feature
		err := rows.Scan(&feature.ID, &feature.Name, &feature.Description)
		if err != nil {
			return nil, fmt.Errorf("failed to scan feature: %w", err)
		}
		features = append(features, feature)
	}

	return features, nil
}

// getAllAccessLevels retrieves all available access levels
func (s *Service) getAllAccessLevels(ctx context.Context) ([]types.AccessLevel, error) {
	query := `SELECT id, key, label FROM access_level ORDER BY id`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to query access levels: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			_ = err // Explicitly acknowledge the error
		}
	}()

	var accessLevels []types.AccessLevel
	for rows.Next() {
		var level types.AccessLevel
		err := rows.Scan(&level.ID, &level.Key, &level.Label)
		if err != nil {
			return nil, fmt.Errorf("failed to scan access level: %w", err)
		}
		accessLevels = append(accessLevels, level)
	}

	return accessLevels, nil
}

// getOrganizationUsers retrieves all users in an organization
func (s *Service) getOrganizationUsers(ctx context.Context, accountID string) ([]types.UserBasicInfo, error) {
	query := `
		SELECT u.id, u.email, u.full_name, r.id as role_id, r.name as role_name
		FROM app_user u
		JOIN account_type_role atr ON u.account_type_role_id = atr.id
		JOIN role r ON atr.role_id = r.id
		WHERE u.account_id = $1
		ORDER BY u.full_name
	`

	rows, err := s.db.QueryContext(ctx, query, accountID)
	if err != nil {
		return nil, fmt.Errorf("failed to query organization users: %w", err)
	}
	defer func() {
		err = rows.Close()
		if err != nil {
			_ = err // Explicitly handle the error by acknowledging it
		}
	}()

	var users []types.UserBasicInfo
	for rows.Next() {
		var user types.UserBasicInfo
		err := rows.Scan(&user.ID, &user.Email, &user.FullName, &user.RoleID, &user.RoleName)
		if err != nil {
			return nil, fmt.Errorf("failed to scan user: %w", err)
		}
		users = append(users, user)
	}

	return users, nil
}
