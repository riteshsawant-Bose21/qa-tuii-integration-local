package middleware

import (
	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/auth"
	authutils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/auth"
)

// AuthMiddleware defines the interface for authentication middleware
type AuthMiddleware interface {
	// Middleware returns a Gin middleware function for authentication
	Middleware() gin.HandlerFunc
}

// Auth0MiddlewareImpl implements the AuthMiddleware interface using Auth0
type Auth0MiddlewareImpl struct {
	validator *auth.Auth0Validator
}

// NewAuth0Middleware creates a new Auth0 middleware implementation
func NewAuth0Middleware(validator *auth.Auth0Validator) AuthMiddleware {
	return &Auth0MiddlewareImpl{
		validator: validator,
	}
}

// Middleware implements the AuthMiddleware interface for Auth0 JWT token validation
func (a *Auth0MiddlewareImpl) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			authutils.RespondWithUnauthorized(c)
			c.Abort()
			return
		}

		// Extract token from header
		token, err := auth.ExtractTokenFromHeader(authHeader)
		if err != nil {
			authutils.RespondWithInvalidToken(c)
			c.Abort()
			return
		}

		// Validate the token
		claims, err := a.validator.ValidateToken(token)
		if err != nil {
			// Check error type and respond accordingly
			if authutils.IsTokenExpired(err.Error()) {
				authutils.RespondWithTokenExpired(c)
			} else {
				authutils.RespondWithInvalidToken(c)
			}
			c.Abort()
			return
		}

		// Extract user information from claims
		userID, err := auth.ExtractUserID(claims)
		if err != nil {
			authutils.RespondWithInvalidToken(c)
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
		}

		// Continue with the request
		c.Next()
	}
}

// Auth0Middleware creates a middleware for Auth0 JWT token validation (backward compatibility)
func Auth0Middleware(validator *auth.Auth0Validator) gin.HandlerFunc {
	authMiddleware := NewAuth0Middleware(validator)
	return authMiddleware.Middleware()
}
