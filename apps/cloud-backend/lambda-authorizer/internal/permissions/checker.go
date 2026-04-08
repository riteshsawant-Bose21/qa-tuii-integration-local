package permissions

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/BoseProfessional/lambda-authorizer/internal/constants"
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
	// Find matching endpoint permission
	permission := s.findEndpointPermission(method, resource)

	// Get user permissions from database once - we'll reuse this for both auth check and context
	userPerms, err := s.GetUserPermissions(ctx, userEmail)
	if err != nil {
		return false, nil, fmt.Errorf("failed to get user permissions: %w", err)
	}

	// Check authorization if permission is registered
	if permission != nil {
		// Check if user has the required permission
		userLevel, exists := userPerms[permission.Feature]
		if !exists {
			// Check for pattern-based permissions (e.g., "project.*" grants access to all project features)
			hasPatternPermission := false
			for permKey, level := range userPerms {
				if strings.HasSuffix(permKey, "*") {
					prefix := strings.TrimSuffix(permKey, "*")
					if strings.HasPrefix(permission.Feature, prefix) {
						if isPermissionSufficient(level, permission.RequiredLevel) {
							hasPatternPermission = true
							break
						}
					}
				}
			}

			if !hasPatternPermission {
				// Check for admin privileges (users with admin roles should have access to most features)
				if adminLevel, exists := userPerms["admin"]; exists {
					if !isPermissionSufficient(adminLevel, permission.RequiredLevel) {
						// Check for full access permissions
						if fullLevel, exists := userPerms["*"]; exists {
							if !isPermissionSufficient(fullLevel, permission.RequiredLevel) {
								return false, nil, nil
							}
						} else {
							return false, nil, nil
						}
					}
				} else {
					// Check for full access permissions
					if fullLevel, exists := userPerms["*"]; exists {
						if !isPermissionSufficient(fullLevel, permission.RequiredLevel) {
							return false, nil, nil
						}
					} else {
						return false, nil, nil
					}
				}
			}
		} else {
			// User has direct permission, check if level is sufficient
			if !isPermissionSufficient(userLevel, permission.RequiredLevel) {
				return false, nil, nil
			}
		}
	}
	// If no permission registered or permission check passed, proceed to get user context

	// Fetch user info for context
	var userID, role, accountID, accountName, accountType, roleID string

	query := `SELECT u.id::text, r.name, u.account_id::text, a.name, at.name, r.id::text
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

	// Build permissions string from already-fetched permissions
	var permsList []string
	for k, v := range userPerms {
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
	s.registerPermission(constants.MethodGet, "/api/v1/projects", constants.ProjectRead, constants.PermissionRead, "View all projects")
	s.registerPermission(constants.MethodPost, "/api/v1/projects", constants.ProjectCreate, constants.PermissionWrite, "Create new project")
	s.registerPermission(constants.MethodPatch, "/api/v1/projects/:id", constants.ProjectUpdate, constants.PermissionWrite, "Update project")
	s.registerPermission(constants.MethodDelete, "/api/v1/projects/:id", constants.ProjectDelete, constants.PermissionWrite, "Delete project")
	s.registerPermission(constants.MethodPut, "/api/v1/projects/:projectId/users/:userEmail", constants.ProjectUpdate, constants.PermissionWrite, "Assign user to project")
	s.registerPermission(constants.MethodDelete, "/api/v1/projects/:projectId/users/:userEmail", constants.ProjectUpdate, constants.PermissionWrite, "Remove user from project")
	s.registerPermission(constants.MethodPost, "/api/v1/projects/:projectId/star/:userId", constants.ProjectUpdate, constants.PermissionRead, "Star or unstar project")
	s.registerPermission(constants.MethodPost, "/api/v1/projects/:projectId/archive", constants.ProjectUpdate, constants.PermissionWrite, "Archive or unarchive project")
	s.registerPermission(constants.MethodPost, "/api/v1/projects/:projectId/lock", constants.ProjectUpdate, constants.PermissionWrite, "Lock or unlock project")

	// Product permissions
	s.registerPermission(constants.MethodGet, "/api/v1/products", constants.ProductRead, constants.PermissionRead, "View all products")
	s.registerPermission(constants.MethodGet, "/api/v1/products/:id", constants.ProductRead, constants.PermissionRead, "View a product details")
	s.registerPermission(constants.MethodGet, "/api/v1/products/price", constants.ProductRead, constants.PermissionRead, "View product price")

	// User Profile permissions
	s.registerPermission(constants.MethodGet, "/api/v1/users/profile", constants.UserProfileRead, constants.PermissionRead, "View user profile")
	s.registerPermission(constants.MethodPost, "/api/v1/users/profile", constants.UserProfileCreate, constants.PermissionWrite, "Create user profile")
	s.registerPermission(constants.MethodPut, "/api/v1/users/profile/:id", constants.UserProfileUpdate, constants.PermissionWrite, "Update user profile")

	// User Settings permissions
	s.registerPermission(constants.MethodGet, "/api/v1/users/settings", constants.UserSettingsRead, constants.PermissionRead, "View user settings")
	s.registerPermission(constants.MethodPost, "/api/v1/users/settings", constants.UserSettingsCreate, constants.PermissionWrite, "Create user settings")
	s.registerPermission(constants.MethodPut, "/api/v1/users/settings/:id", constants.UserSettingsUpdate, constants.PermissionWrite, "Update user settings")

	basePath := fmt.Sprintf("%s%s", constants.APIV1Path, constants.EndpointDevices)

	// Device CREATE endpoint - require write permission
	s.registerPermission(constants.MethodPost, basePath, constants.DeviceCreate, constants.PermissionWrite, "Create new device")
	// Device BULK CREATE endpoint - require write permission
	s.registerPermission(constants.MethodPost, fmt.Sprintf("%s%s", basePath, constants.EndpointDeviceBulkCreate), constants.DeviceCreate, constants.PermissionWrite, "Bulk create devices")
	// Device UPDATE endpoint - require write permission
	s.registerPermission(constants.MethodPatch, fmt.Sprintf("%s%s", basePath, constants.EndpointDeviceByID), constants.DeviceUpdate, constants.PermissionWrite, "Update device")
	// Device RESET endpoint - require write permission
	s.registerPermission(constants.MethodDelete, fmt.Sprintf("%s%s", basePath, constants.EndpointDeviceReset), constants.DeviceDelete, constants.PermissionWrite, "Reset device")
	// Device CLAIM endpoint - require write permission
	s.registerPermission(constants.MethodPost, fmt.Sprintf("%s%s", basePath, constants.EndpointDeviceClaim), constants.DeviceClaim, constants.PermissionWrite, "Claim device")
	// Device ROTATE-CERT endpoint - require write permission
	s.registerPermission(constants.MethodPost, fmt.Sprintf("%s%s", basePath, constants.EndpointDeviceRotateCert), constants.DeviceRotateCert, constants.PermissionWrite, "Rotate device certificate")

	s.registerPermission(constants.MethodPost, fmt.Sprintf("%s%s", basePath, constants.EndpointDeviceCommand), constants.DeviceCommand, constants.PermissionWrite, "Send command to device")
	s.registerPermission(constants.MethodGet, fmt.Sprintf("%s%s", basePath, constants.EndpointCommandStatus), constants.DeviceCommandStatus, constants.PermissionRead, "Get command status")

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
	// Not using the SQLBoiler ORM since the models are defined in fusion-core, but we can switch to ORM if we want to duplicate models here
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
	// Not using the SQLBoiler ORM since the models are defined in fusion-core, but we can switch to ORM if we want to duplicate models here
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
	// Find matching endpoint permission
	permission := s.findEndpointPermission(method, resource)

	if permission == nil {
		// No specific permission registered for this endpoint - allow (authentication-only)
		// Token validation already happened, so user is authenticated
		return true, nil
	}

	// Permission is registered, so we need to check authorization
	// Get user permissions from database
	userPerms, err := s.GetUserPermissions(ctx, userEmail)
	if err != nil {
		return false, fmt.Errorf("failed to get user permissions: %w", err)
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

		// Check for admin privileges (users with admin roles should have access to most features)
		if adminLevel, exists := userPerms["admin"]; exists {
			if isPermissionSufficient(adminLevel, permission.RequiredLevel) {
				return true, nil
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

	// Length mismatch means no match
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
