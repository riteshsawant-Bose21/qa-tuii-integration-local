// Package auth provides authentication and authorization utilities.
package auth

import (
	"strings"

	"github.com/gin-gonic/gin"
)

// GetUserIDFromContext extracts user ID from Gin context
func GetUserIDFromContext(c *gin.Context) (string, bool) {
	userID, exists := c.Get("userID")
	if !exists {
		return "", false
	}
	if uid, ok := userID.(string); ok {
		return uid, true
	}
	return "", false
}

// GetEmailFromContext extracts email from Gin context
func GetEmailFromContext(c *gin.Context) (string, bool) {
	email, exists := c.Get("email")
	if !exists {
		return "", false
	}
	if em, ok := email.(string); ok {
		return em, true
	}
	return "", false
}

// GetUsernameFromContext extracts username from Gin context
func GetUsernameFromContext(c *gin.Context) (string, bool) {
	username, exists := c.Get("username")
	if !exists {
		return "", false
	}
	if un, ok := username.(string); ok {
		return un, true
	}
	return "", false
}

// GetRolesFromContext extracts roles from Gin context
func GetRolesFromContext(c *gin.Context) ([]string, bool) {
	roles, exists := c.Get("roles")
	if !exists {
		return nil, false
	}
	if r, ok := roles.([]string); ok {
		return r, true
	}
	return nil, false
}

// IsTokenExpired checks if the error indicates token expiration
func IsTokenExpired(errorMsg string) bool {
	return strings.Contains(strings.ToLower(errorMsg), "expired") ||
		strings.Contains(strings.ToLower(errorMsg), "exp")
}
