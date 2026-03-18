// Package middleware provides HTTP middleware functions for authentication, logging, and access control.
package middleware

import (
	"context"
	"fmt"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
)

// PermissionLevel represents different access levels
type PermissionLevel string

const (
	// PermissionRead grants read-only access
	PermissionRead PermissionLevel = "read"
	// PermissionWrite grants read and write access
	PermissionWrite PermissionLevel = "edit"
	// PermissionAdmin grants full administrative access
	PermissionAdmin PermissionLevel = "admin"
)

// EndpointPermission defines the required permission for an endpoint
type EndpointPermission struct {
	Feature       string          `json:"feature"`
	RequiredLevel PermissionLevel `json:"required_level"`
	Description   string          `json:"description"`
}

// AccessControlConfig holds the configuration for access control
type AccessControlConfig struct {
	UserService fusion.User
	Permissions map[string]*EndpointPermission // key: method:path pattern
}

// NewAccessControlMiddleware creates a new access control middleware
func NewAccessControlMiddleware(userService fusion.User) *AccessControlConfig {
	return &AccessControlConfig{
		UserService: userService,
		Permissions: make(map[string]*EndpointPermission),
	}
}

// RegisterPermission registers a permission requirement for an endpoint
func (acc *AccessControlConfig) RegisterPermission(method, path, feature string, level PermissionLevel, description string) {
	key := fmt.Sprintf("%s:%s", strings.ToUpper(method), path)
	acc.Permissions[key] = &EndpointPermission{
		Feature:       feature,
		RequiredLevel: level,
		Description:   description,
	}
}

// RequirePermission returns a middleware that checks for specific permissions
func (acc *AccessControlConfig) RequirePermission(feature string, level PermissionLevel) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get user email from context (set by Auth0 middleware)
		userEmail, exists := c.Get("user_email")
		if !exists {
			response.Unauthorized(c, "User authentication required")
			c.Abort()
			return
		}

		email, ok := userEmail.(string)
		if !ok {
			response.Unauthorized(c, "Invalid user authentication")
			c.Abort()
			return
		}

		// Get user authorization data
		userAuth, err := acc.UserService.GetUserAuthorization(context.Background(), email)
		if err != nil {
			response.Forbidden(c, fmt.Sprintf("Failed to retrieve user permissions: %v", err))
			c.Abort()
			return
		}

		// Check if user has the required permissions using database-driven approach
		hasPermission, err := acc.UserService.CheckUserPermission(context.Background(), email, feature, string(level))
		if err != nil {
			// If database check fails, fallback to the old method
			if !acc.hasPermission(userAuth.Permissions, feature, level) {
				response.Forbidden(c, fmt.Sprintf("Insufficient permissions. Required: %s.%s", feature, level))
				c.Abort()
				return
			}
		} else if !hasPermission {
			response.Forbidden(c, fmt.Sprintf("Insufficient permissions. Required: %s.%s", feature, level))
			c.Abort()
			return
		}

		// Store user authorization in context for potential use in handlers
		c.Set("user_auth", userAuth)
		c.Next()
	}
}

// hasPermission checks if the user has the required permission level for a feature
func (acc *AccessControlConfig) hasPermission(permissions map[string]string, feature string, requiredLevel PermissionLevel) bool {
	// Check direct feature permission
	if userLevel, exists := permissions[feature]; exists {
		return acc.isPermissionSufficient(userLevel, requiredLevel)
	}

	// Check for pattern-based permissions
	for permissionKey, userLevel := range permissions {
		if acc.matchesPermissionPattern(permissionKey, feature) {
			if acc.isPermissionSufficient(userLevel, requiredLevel) {
				return true
			}
		}
	}

	// Check for admin privileges (users with admin roles should have access to most features)
	if adminLevel, exists := permissions["admin"]; exists {
		if acc.isPermissionSufficient(adminLevel, requiredLevel) {
			return true
		}
	}

	// Check for full access permissions
	if fullLevel, exists := permissions["*"]; exists {
		if acc.isPermissionSufficient(fullLevel, requiredLevel) {
			return true
		}
	}

	return false
}

// isPermissionSufficient checks if the user's permission level is sufficient for the required level
func (acc *AccessControlConfig) isPermissionSufficient(userLevel string, requiredLevel PermissionLevel) bool {
	// Define permission hierarchy
	levelHierarchy := map[string]int{
		"none": 1,
		"read": 2,
		"edit": 3,
	}

	userLevelInt, userExists := levelHierarchy[strings.ToLower(userLevel)]
	requiredLevelInt, requiredExists := levelHierarchy[string(requiredLevel)]

	if !userExists || !requiredExists {
		return false
	}

	return userLevelInt >= requiredLevelInt
}

// matchesPermissionPattern checks if a permission key matches a feature pattern
func (acc *AccessControlConfig) matchesPermissionPattern(permissionKey, feature string) bool {
	// Simple pattern matching - can be extended for more complex patterns

	// Check for wildcard patterns
	if strings.HasSuffix(permissionKey, "*") {
		prefix := strings.TrimSuffix(permissionKey, "*")
		return strings.HasPrefix(feature, prefix)
	}

	// Check for exact match
	return permissionKey == feature
}

// GlobalAccessControlMiddleware returns a middleware that automatically checks permissions
// based on registered endpoint permissions
func (acc *AccessControlConfig) GlobalAccessControlMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Create key for current request
		key := fmt.Sprintf("%s:%s", c.Request.Method, c.FullPath())

		// Check if this endpoint requires permission checking
		if permission, exists := acc.Permissions[key]; exists {
			// Get user email from context (set by Auth0 middleware)
			// Try "user_email" first, then fall back to "email"
			userEmail, exists := c.Get("user_email")
			if !exists {
				userEmail, exists = c.Get("email")
			}

			if !exists {
				response.Unauthorized(c, "User authentication required")
				c.Abort()
				return
			}

			email, ok := userEmail.(string)
			if !ok {
				response.Unauthorized(c, "Invalid user authentication")
				c.Abort()
				return
			}

			// Get user authorization data
			userAuth, err := acc.UserService.GetUserAuthorization(context.Background(), email)
			if err != nil {
				response.Forbidden(c, fmt.Sprintf("Failed to retrieve user permissions: %v", err))
				c.Abort()
				return
			}

			// Check if user has the required permission
			if !acc.hasPermission(userAuth.Permissions, permission.Feature, permission.RequiredLevel) {
				response.Forbidden(c, fmt.Sprintf("Insufficient permissions for %s", permission.Description))
				c.Abort()
				return
			}

			// Store user authorization in context for potential use in handlers
			c.Set("user_auth", userAuth)
		}

		c.Next()
	}
}
