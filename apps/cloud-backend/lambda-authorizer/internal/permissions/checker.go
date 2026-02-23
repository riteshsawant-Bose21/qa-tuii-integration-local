package permissions

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"strings"
)

const (
	// Project permissions
	ProjectRead   = "project.read"
	ProjectCreate = "project.create"
	ProjectUpdate = "project.update"
	ProjectDelete = "project.delete"
	ProjectSync   = "project.sync"

	// User management permissions
	UserRead   = "user.read"
	UserCreate = "user.create"
	UserUpdate = "user.update"
	UserDelete = "user.delete"

	// User profile permissions
	UserProfileRead   = "users.profile.read"
	UserProfileCreate = "users.profile.create"
	UserProfileUpdate = "users.profile.update"

	// User settings permissions
	UserSettingsRead   = "users.settings.read"
	UserSettingsCreate = "users.settings.create"
	UserSettingsUpdate = "users.settings.update"

	// Admin permissions
	AdminFull = "admin"
	AdminUser = "user.manage"

	// Wildcard permissions
	AllPermissions = "*"
)

type PermissionChecker interface {
	CheckUserPermission(ctx context.Context, userEmail, feature, level string) (bool, error)
	GetUserPermissions(ctx context.Context, userEmail string) (map[string]string, error)
	CheckEndpointPermission(ctx context.Context, userEmail, method, resource string) (bool, error)
	CheckEndpointPermissionWithContext(ctx context.Context, userEmail, method, resource string) (bool, *UserContext, error)
}
// UserContext holds user identity and permission info for Lambda response
type UserContext struct {
	UserID      string
	Email       string
	Role        string
	AccountID   string
	AccountName string
	AccountType string
	RoleID      string
	Permissions string // Comma-separated or JSON string
}

// CheckEndpointPermissionWithContext checks permission and returns user context for Lambda response
func (s *SQLPermissionChecker) CheckEndpointPermissionWithContext(ctx context.Context, userEmail, method, resource string) (bool, *UserContext, error) {
       // Check permission as before
       allowed, err := s.CheckEndpointPermission(ctx, userEmail, method, resource)
       if err != nil || !allowed {
	       return allowed, nil, err
       }

       // Fetch user info for context
       var userID, role, accountID, accountName, accountType, roleID string

       query := `SELECT u.id, r.name, u.account_id, a.name, at.name, r.id
		 FROM app_user u
		 JOIN account_type_role atr ON u.account_type_role_id = atr.id
		 JOIN role r ON atr.role_id = r.id
		 JOIN account a ON u.account_id = a.id
		 JOIN account_type at ON a.account_type_id = at.id
		 WHERE u.email = $1`

		 err = s.db.QueryRowContext(ctx, query, userEmail).Scan(&userID, &role, &accountID, &accountName, &accountType, &roleID)

		 if err != nil {
	       return false, nil, fmt.Errorf("failed to get user context: %w", err)
       }

       // Get permissions as comma-separated string
       perms, err := s.GetUserPermissions(ctx, userEmail)

	   if err != nil {
	       return false, nil, fmt.Errorf("failed to get user permissions: %w", err)
       }

	   var permsList []string

	   for k, v := range perms {
	       permsList = append(permsList, fmt.Sprintf("%s:%s", k, v))
       }

	   permissionsStr := strings.Join(permsList, ",")

       userCtx := &UserContext{
	       UserID:      userID,
	       Email:       userEmail,
	       Role:        role,
	       AccountID:   accountID,
	       AccountName: accountName,
	       AccountType: accountType,
	       RoleID:      roleID,
	       Permissions: permissionsStr,
       }

       return true, userCtx, nil
}


// EndpointPermission defines the required permission for an endpoint
type EndpointPermission struct {
	Feature       string
	RequiredLevel string
	Description   string
}

type SQLPermissionChecker struct {
	db          *sql.DB
	permissions map[string]*EndpointPermission
}

func NewSQLPermissionChecker(db *sql.DB) *SQLPermissionChecker {
	checker := &SQLPermissionChecker{
		db:          db,
		permissions: make(map[string]*EndpointPermission),
	}
	checker.setupPermissions()
	return checker
}

// setupPermissions registers all endpoint permissions (same as fusion-core API)
func (s *SQLPermissionChecker) setupPermissions() {
	// Project permissions
	s.registerPermission("GET", "/api/v1/projects", "project.read", "read", "View all projects")
	s.registerPermission("POST", "/api/v1/projects", "project.create", "write", "Create new project")
	s.registerPermission("PATCH", "/api/v1/projects/:id", "project.update", "write", "Update project")
	s.registerPermission("DELETE", "/api/v1/projects/:id", "project.delete", "write", "Delete project")
	s.registerPermission("PUT", "/api/v1/projects/assign-user", "project.update", "write", "Assign user to project")
	s.registerPermission("DELETE", "/api/v1/projects/remove-user", "project.update", "write", "Remove user from project")
	s.registerPermission("POST", "/api/v1/projects/star", "project.update", "read", "Star or unstar project")
	s.registerPermission("POST", "/api/v1/projects/archive", "project.update", "write", "Archive or unarchive project")
	s.registerPermission("POST", "/api/v1/projects/lock", "project.update", "write", "Lock or unlock project")

	// Product permissions
	s.registerPermission("GET", "/api/v1/products", "product.read", "read", "View all products")
	s.registerPermission("GET", "/api/v1/products/:id", "product.read", "read", "View a product details")
	s.registerPermission("POST", "/api/v1/products/price", "product.update", "read", "View product price")

	// User Profile permissions
	s.registerPermission("GET", "/api/v1/users/profile", "users.profile.read", "read", "View user profile")
	s.registerPermission("POST", "/api/v1/users/profile", "users.profile.create", "write", "Create user profile")
	s.registerPermission("PUT", "/api/v1/users/profile/:id", "users.profile.update", "write", "Update user profile")

	// User Settings permissions
	s.registerPermission("GET", "/api/v1/users/settings", "users.settings.read", "read", "View user settings")
	s.registerPermission("POST", "/api/v1/users/settings", "users.settings.create", "write", "Create user settings")
	s.registerPermission("PUT", "/api/v1/users/settings/:id", "users.settings.update", "write", "Update user settings")
}

// registerPermission registers a permission requirement for an endpoint
func (s *SQLPermissionChecker) registerPermission(method, path, feature, level, description string) {
	key := fmt.Sprintf("%s:%s", strings.ToUpper(method), path)
	s.permissions[key] = &EndpointPermission{
		Feature:       feature,
		RequiredLevel: level,
		Description:   description,
	}
}

func (s *SQLPermissionChecker) GetUserPermissions(ctx context.Context, userEmail string) (map[string]string, error) {
	query := `
		SELECT f.name, a.key
		FROM app_user u
		JOIN account_type_role atr ON u.account_type_role_id = atr.id
		JOIN feature_permission fp ON fp.account_type_role_id = atr.id
		JOIN feature f ON fp.feature_id = f.id
		JOIN access_level a ON fp.access_level_id = a.id
		WHERE u.email = $1
	`
	rows, err := s.db.QueryContext(ctx, query, userEmail)
	if err != nil {
		return nil, fmt.Errorf("failed to query permissions: %w", err)
	}
	defer rows.Close()
	permissions := make(map[string]string)
	for rows.Next() {
		var feature, level string
		if err := rows.Scan(&feature, &level); err != nil {
			return nil, fmt.Errorf("failed to scan permission: %w", err)
		}
		permissions[feature] = level
	}
	return permissions, nil
}

func (s *SQLPermissionChecker) CheckUserPermission(ctx context.Context, userEmail, feature, requiredLevel string) (bool, error) {
	query := `
		SELECT a.key
		FROM app_user u
		JOIN account_type_role atr ON u.account_type_role_id = atr.id
		JOIN feature_permission fp ON fp.account_type_role_id = atr.id
		JOIN feature f ON fp.feature_id = f.id
		JOIN access_level a ON fp.access_level_id = a.id
		WHERE u.email = $1 AND f.name = $2
	`
	var userLevel string
	err := s.db.QueryRowContext(ctx, query, userEmail, feature).Scan(&userLevel)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("failed to check user permission: %w", err)
	}
	return isPermissionSufficient(userLevel, requiredLevel), nil
}

func isPermissionSufficient(userLevel, requiredLevel string) bool {
	levelHierarchy := map[string]int{
		"none":  0,
		"read":  1,
		"edit":  2,
		"write": 2, // alias for edit
		"admin": 3,
	}
	userLevelInt, userExists := levelHierarchy[strings.ToLower(userLevel)]
	requiredLevelInt, requiredExists := levelHierarchy[strings.ToLower(requiredLevel)]
	if !userExists || !requiredExists {
		return false
	}
	return userLevelInt >= requiredLevelInt
}

// CheckEndpointPermission checks if a user has permission to access a specific endpoint
func (s *SQLPermissionChecker) CheckEndpointPermission(ctx context.Context, userEmail, method, resource string) (bool, error) {
	// Get user permissions
	userPerms, err := s.GetUserPermissions(ctx, userEmail)
	if err != nil {
		return false, fmt.Errorf("failed to get user permissions: %w", err)
	}

	// Find matching endpoint permission
	permission := s.findEndpointPermission(method, resource)
	if permission == nil {
		// No specific permission registered for this endpoint - deny by default
		return false, nil
	}

	// Check if user has the required permission
	userLevel, exists := userPerms[permission.Feature]
	if !exists {
		// Check for pattern-based permissions (e.g., "project.*" grants access to all project features)
		for permKey, level := range userPerms {
			if strings.HasSuffix(permKey, "*") {
				prefix := strings.TrimSuffix(permKey, "*")
				if strings.HasPrefix(permission.Feature, prefix) {
					return isPermissionSufficient(level, permission.RequiredLevel), nil
				}
			}
		}
		return false, nil
	}

	return isPermissionSufficient(userLevel, permission.RequiredLevel), nil
}

// findEndpointPermission finds the permission requirement for a given method and resource
func (s *SQLPermissionChecker) findEndpointPermission(method, resource string) *EndpointPermission {
	// Try exact match first
	key := fmt.Sprintf("%s:%s", strings.ToUpper(method), resource)
	if perm, exists := s.permissions[key]; exists {
		return perm
	}

	// Try pattern matching for paths with parameters (e.g., /api/v1/projects/123 matches /api/v1/projects/:id)
	for permKey, perm := range s.permissions {
		parts := strings.SplitN(permKey, ":", 2)
		if len(parts) != 2 {
			continue
		}
		permMethod, permPath := parts[0], parts[1]

		if strings.ToUpper(method) != permMethod {
			continue
		}

		if matchesPathPattern(permPath, resource) {
			return perm
		}
	}

	return nil
}

// matchesPathPattern checks if a resource path matches a path pattern with parameters
// e.g., /api/v1/projects/:id matches /api/v1/projects/123
func matchesPathPattern(pattern, path string) bool {
	patternParts := strings.Split(pattern, "/")
	pathParts := strings.Split(path, "/")

	if len(patternParts) != len(pathParts) {
		return false
	}

	for i := 0; i < len(patternParts); i++ {
		// Parameter placeholder (e.g., :id) matches any value
		if strings.HasPrefix(patternParts[i], ":") {
			continue
		}
		// Exact match required for non-parameter segments
		if patternParts[i] != pathParts[i] {
			return false
		}
	}

	return true
}