package db

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Service struct {
	db *sql.DB
}

func NewService(db *sql.DB) *Service {
	return &Service{
		db: db,
	}
}

// GetUserByEmail retrieves a user by email from the database
func (s *Service) GetUserByEmail(ctx context.Context, email string) (*types.User, error) {
	query := `
		SELECT id, email, full_name, account_type_role_id, account_id, created_at, updated_at
		FROM app_user 
		WHERE email = $1
	`

	var user types.User
	err := s.db.QueryRowContext(ctx, query, email).Scan(
		&user.ID, &user.Email, &user.FullName,
		&user.AccountTypeRoleID, &user.AccountID,
		&user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found with email: %s", email)
		}
		return nil, fmt.Errorf("failed to get user by email: %w", err)
	}

	return &user, nil
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
	accountQuery := `
		SELECT a.id, a.name, a.description, at.name as account_type
		FROM account a
		JOIN account_type at ON a.account_type_id = at.id
		WHERE a.id = $1
	`

	var accountInfo types.AccountInfo
	err = s.db.QueryRowContext(ctx, accountQuery, user.AccountID).Scan(
		&accountInfo.ID, &accountInfo.Name, &accountInfo.Description, &accountInfo.Type,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get account: %w", err)
	}

	// Get role information
	roleQuery := `
		SELECT r.id, r.name, r.description
		FROM role r
		JOIN account_type_role atr ON r.id = atr.role_id
		WHERE atr.id = $1
	`

	var role types.Role
	err = s.db.QueryRowContext(ctx, roleQuery, user.AccountTypeRoleID).Scan(
		&role.ID, &role.Name, &role.Description,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get role: %w", err)
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
	query := `
		SELECT f.name, al.key
		FROM feature_permission fp
		JOIN feature f ON fp.feature_id = f.id
		JOIN access_level al ON fp.access_level_id = al.id
		WHERE fp.account_type_role_id = $1
		ORDER BY f.name
	`

	rows, err := s.db.QueryContext(ctx, query, accountTypeRoleID)
	if err != nil {
		return nil, fmt.Errorf("failed to query permissions: %w", err)
	}
	defer rows.Close()

	permissions := make(map[string]string)
	for rows.Next() {
		var featureName, accessLevel string
		err := rows.Scan(&featureName, &accessLevel)
		if err != nil {
			return nil, fmt.Errorf("failed to scan permission: %w", err)
		}
		permissions[featureName] = accessLevel
	}

	// Add fallback permissions based on role patterns
	role, err := s.getRoleByAccountTypeRoleID(ctx, accountTypeRoleID)
	if err == nil {
		fallbackPermissions := s.getFallbackPermissions(role.Name)
		for key, value := range fallbackPermissions {
			if _, exists := permissions[key]; !exists {
				permissions[key] = value
			}
		}
	}

	return permissions, nil
}

// getRoleByAccountTypeRoleID gets role information by account type role ID
func (s *Service) getRoleByAccountTypeRoleID(ctx context.Context, accountTypeRoleID int) (*types.Role, error) {
	query := `
		SELECT r.id, r.name, r.description
		FROM role r
		JOIN account_type_role atr ON r.id = atr.role_id
		WHERE atr.id = $1
	`

	var role types.Role
	err := s.db.QueryRowContext(ctx, query, accountTypeRoleID).Scan(
		&role.ID, &role.Name, &role.Description,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to get role: %w", err)
	}

	return &role, nil
}

// getFallbackPermissions provides fallback permissions based on role name patterns
func (s *Service) getFallbackPermissions(roleName string) map[string]string {
	permissions := make(map[string]string)

	// Convert role name to lowercase for comparison
	lowerRoleName := strings.ToLower(roleName)

	// Define role-based permissions
	if strings.Contains(lowerRoleName, "admin") || strings.Contains(lowerRoleName, "super") {
		// Admin roles get full permissions
		permissions["launcher.project.create"] = "full"
		permissions["launcher.project.read"] = "full"
		permissions["launcher.project.update"] = "full"
		permissions["launcher.project.delete"] = "full"
		permissions["launcher.user.create"] = "admin"
		permissions["launcher.user.read"] = "admin"
		permissions["launcher.user.update"] = "admin"
		permissions["launcher.user.delete"] = "admin"
		permissions["launcher.role.manage"] = "admin"
		permissions["launcher.project_file.create"] = "full"
		permissions["launcher.project_file.read"] = "full"
		permissions["launcher.project_file.update"] = "full"
		permissions["launcher.project_file.delete"] = "full"
	} else if strings.Contains(lowerRoleName, "manager") || strings.Contains(lowerRoleName, "lead") {
		// Manager/Lead roles get moderate permissions
		permissions["launcher.project.create"] = "write"
		permissions["launcher.project.read"] = "write"
		permissions["launcher.project.update"] = "write"
		permissions["launcher.project.delete"] = "write"
		permissions["launcher.user.create"] = "write"
		permissions["launcher.user.read"] = "write"
		permissions["launcher.user.update"] = "write"
		permissions["launcher.project_file.create"] = "write"
		permissions["launcher.project_file.read"] = "write"
		permissions["launcher.project_file.update"] = "write"
		permissions["launcher.project_file.delete"] = "write"
	} else {
		// Regular users get read permissions
		permissions["launcher.project.read"] = "read"
		permissions["launcher.user.read"] = "read"
		permissions["launcher.project_file.read"] = "read"
	}

	return permissions
}

// CreateUser creates a new user in the database
func (s *Service) CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error) {
	query := `
		INSERT INTO app_user (email, full_name, account_type_role_id, account_id, created_at)
		VALUES ($1, $2, $3, $4, NOW())
		RETURNING id, email, full_name, account_type_role_id, account_id, created_at, updated_at
	`

	var user types.User
	err := s.db.QueryRowContext(ctx, query,
		req.Email, req.FullName, req.AccountTypeRoleID, req.AccountID,
	).Scan(
		&user.ID, &user.Email, &user.FullName,
		&user.AccountTypeRoleID, &user.AccountID,
		&user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &user, nil
}

// UpdateUser updates an existing user in the database
func (s *Service) UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error) {
	// Build dynamic query based on provided fields
	setParts := []string{}
	args := []interface{}{}
	argIndex := 1

	if req.FullName != nil {
		setParts = append(setParts, fmt.Sprintf("full_name = $%d", argIndex))
		args = append(args, *req.FullName)
		argIndex++
	}

	if req.AccountTypeRoleID != nil {
		setParts = append(setParts, fmt.Sprintf("account_type_role_id = $%d", argIndex))
		args = append(args, *req.AccountTypeRoleID)
		argIndex++
	}

	if req.AccountID != nil {
		setParts = append(setParts, fmt.Sprintf("account_id = $%d", argIndex))
		args = append(args, *req.AccountID)
		argIndex++
	}

	if len(setParts) == 0 {
		return nil, fmt.Errorf("no fields to update")
	}

	// Add updated_at
	setParts = append(setParts, "updated_at = NOW()")

	// Add userID to args
	args = append(args, userID)

	query := fmt.Sprintf(`
		UPDATE app_user 
		SET %s
		WHERE id = $%d
		RETURNING id, email, full_name, account_type_role_id, account_id, created_at, updated_at
	`, strings.Join(setParts, ", "), argIndex)

	var user types.User
	err := s.db.QueryRowContext(ctx, query, args...).Scan(
		&user.ID, &user.Email, &user.FullName,
		&user.AccountTypeRoleID, &user.AccountID,
		&user.CreatedAt, &user.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found with ID: %s", userID)
		}
		return nil, fmt.Errorf("failed to update user: %w", err)
	}

	return &user, nil
}
