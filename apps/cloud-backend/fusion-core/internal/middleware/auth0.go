package middleware

import (
	"github.com/gin-gonic/gin"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	authutils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/auth"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
)

// AuthMiddleware defines the interface for authentication middleware
type AuthMiddleware interface {
	// Middleware returns a Gin middleware function for authentication
	Middleware() gin.HandlerFunc
}

// Auth0MiddlewareImpl implements the AuthMiddleware interface using Auth0
type Auth0MiddlewareImpl struct {
	authService fusion.Auth
}

// NewAuth0Middleware creates a new Auth0 middleware implementation
func NewAuth0Middleware(authService fusion.Auth) AuthMiddleware {
	return &Auth0MiddlewareImpl{
		authService: authService,
	}
}

// Middleware implements the AuthMiddleware interface for Auth0 JWT token validation
func (a *Auth0MiddlewareImpl) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.Unauthorized(c, errorutil.MsgUnauthorized)
			c.Abort()
			return
		}

		// Extract token from header
		token, err := a.authService.ExtractTokenFromHeader(authHeader)
		if err != nil {
			response.RespondWithInvalidToken(c)
			c.Abort()
			return
		}

		// Validate the token
		claims, err := a.authService.ValidateToken(token)
		if err != nil {
			// Check error type and respond accordingly
			if authutils.IsTokenExpired(err.Error()) {
				response.RespondWithTokenExpired(c)
			} else {
				response.RespondWithInvalidToken(c)
			}
			c.Abort()
			return
		}

		// Extract user information from claims
		userID, err := a.authService.ExtractUserID(claims)
		if err != nil {
			response.RespondWithInvalidToken(c)
			c.Abort()
			return
		}

		// Store user information in context
		c.Set("userID", userID)
		c.Set("claims", claims)

		// Extract email if available and store with the key expected by role management handlers
		if email, err := a.authService.ExtractUserEmail(claims); err == nil {
			c.Set("email", email)
			c.Set("user_email", email) // Set the key expected by access control middleware
		}

		// Continue with the request
		c.Next()
	}
}

// Auth0Middleware creates a middleware for Auth0 JWT token validation (backward compatibility)
func Auth0Middleware(authService fusion.Auth) gin.HandlerFunc {
	authMiddleware := NewAuth0Middleware(authService)
	return authMiddleware.Middleware()
}
