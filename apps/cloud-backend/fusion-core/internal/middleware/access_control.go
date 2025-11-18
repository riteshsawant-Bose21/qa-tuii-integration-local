package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"
)

// PermissionLevel represents different access levels
type PermissionLevel string

const (
	PermissionRead  PermissionLevel = "read"
	PermissionWrite PermissionLevel = "write"
	PermissionAdmin PermissionLevel = "admin"
	PermissionFull  PermissionLevel = "full"
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
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "User authentication required",
			})
			c.Abort()
			return
		}

		email, ok := userEmail.(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Invalid user authentication",
			})
			c.Abort()
			return
		}

		// Get user authorization data
		userAuth, err := acc.UserService.GetUserAuthorization(context.Background(), email)
		if err != nil {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Access Denied",
				"message": fmt.Sprintf("Failed to retrieve user permissions: %v", err),
			})
			c.Abort()
			return
		}

		// Check if user has the required permission
		if !acc.hasPermission(userAuth.Permissions, feature, level) {
			c.JSON(http.StatusForbidden, gin.H{
				"error":   "Access Denied",
				"message": fmt.Sprintf("Insufficient permissions. Required: %s.%s", feature, level),
				"required_permission": gin.H{
					"feature": feature,
					"level":   level,
				},
				"user_permissions": userAuth.Permissions,
			})
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
		"none":  0,
		"read":  1,
		"write": 2,
		"admin": 4, // Admin should have highest privileges
		"full":  4,
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
				c.JSON(http.StatusUnauthorized, gin.H{
					"error":   "Unauthorized",
					"message": "User authentication required",
				})
				c.Abort()
				return
			}

			email, ok := userEmail.(string)
			if !ok {
				c.JSON(http.StatusUnauthorized, gin.H{
					"error":   "Unauthorized",
					"message": "Invalid user authentication",
				})
				c.Abort()
				return
			}

			// Get user authorization data
			userAuth, err := acc.UserService.GetUserAuthorization(context.Background(), email)
			if err != nil {
				c.JSON(http.StatusForbidden, gin.H{
					"error":   "Access Denied",
					"message": fmt.Sprintf("Failed to retrieve user permissions: %v", err),
				})
				c.Abort()
				return
			}

			// Check if user has the required permission
			if !acc.hasPermission(userAuth.Permissions, permission.Feature, permission.RequiredLevel) {
				c.JSON(http.StatusForbidden, gin.H{
					"error":    "Access Denied",
					"message":  fmt.Sprintf("Insufficient permissions for %s", permission.Description),
					"endpoint": key,
					"required_permission": gin.H{
						"feature": permission.Feature,
						"level":   permission.RequiredLevel,
					},
					"user_permissions": userAuth.Permissions,
				})
				c.Abort()
				return
			}

			// Store user authorization in context for potential use in handlers
			c.Set("user_auth", userAuth)
		}

		c.Next()
	}
}

// hasPermissionLevel is a helper function for testing that checks if a user permission
// level is sufficient for the required level
func hasPermissionLevel(userPermission string, requiredLevel PermissionLevel) bool {
	acc := &AccessControlConfig{}
	return acc.hasPermission(map[string]string{"test": userPermission}, "test", requiredLevel)
}
