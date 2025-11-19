package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/auth"
)

// Auth0Middleware creates a middleware for Auth0 JWT token validation
func Auth0Middleware(validator *auth.Auth0Validator) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Authorization header is required",
			})
			c.Abort()
			return
		} // Extract token from header
		token, err := auth.ExtractTokenFromHeader(authHeader)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Invalid authorization header format",
			})
			c.Abort()
			return
		}

		// Validate the token
		claims, err := validator.ValidateToken(token)
		if err != nil {
			// Provide specific error codes for different token validation failures
			errorCode := "INVALID_TOKEN"
			message := "Invalid or expired token"

			// Check for specific error types in the error message
			errStr := err.Error()
			if strings.Contains(errStr, "token is expired") || strings.Contains(errStr, "expired") {
				errorCode = "TOKEN_EXPIRED"
				message = "Token has expired"
			} else if strings.Contains(errStr, "malformed") || strings.Contains(errStr, "not a valid JWT") {
				errorCode = "TOKEN_MALFORMED"
				message = "Malformed token"
			} else if strings.Contains(errStr, "signature") {
				errorCode = "INVALID_SIGNATURE"
				message = "Invalid token signature"
			} else if strings.Contains(errStr, "JWE token") {
				errorCode = "UNSUPPORTED_TOKEN_FORMAT"
				message = "Received JWE token but JWT expected"
			}

			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": message,
				"code":    errorCode,
				"details": err.Error(),
			})
			c.Abort()
			return
		}

		// Extract user information from claims
		userID, err := auth.ExtractUserID(claims)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error":   "Unauthorized",
				"message": "Invalid token claims",
				"details": err.Error(),
			})
			c.Abort()
			return
		}

		// Store user information in context
		c.Set("userID", userID)
		c.Set("claims", claims)

		// Extract email if available and store with the key expected by role management handlers
		if email, err := auth.ExtractUserEmail(claims); err == nil {
			c.Set("email", email)
			c.Set("user_email", email) // Set the key expected by access control middleware
			// Set the email in the context for the role management handlers
			c.Request = c.Request.WithContext(context.WithValue(c.Request.Context(), "user_email", email))
		}

		// Continue with the request
		c.Next()
	}
}

// GetUserIDFromContext extracts the user ID from the Gin context
func GetUserIDFromContext(c *gin.Context) (string, bool) {
	userID, exists := c.Get("userID")
	if !exists {
		return "", false
	}

	userIDStr, ok := userID.(string)
	return userIDStr, ok
}

// GetEmailFromContext extracts the user email from the Gin context
func GetEmailFromContext(c *gin.Context) (string, bool) {
	email, exists := c.Get("email")
	if !exists {
		return "", false
	}

	emailStr, ok := email.(string)
	return emailStr, ok
}

// GetClaimsFromContext extracts the JWT claims from the Gin context
func GetClaimsFromContext(c *gin.Context) (map[string]interface{}, bool) {
	claims, exists := c.Get("claims")
	if !exists {
		return nil, false
	}

	claimsMap, ok := claims.(*jwt.MapClaims)
	if !ok {
		return nil, false
	}

	// Convert to map[string]interface{}
	result := make(map[string]interface{})
	for k, v := range *claimsMap {
		result[k] = v
	}

	return result, true
}
