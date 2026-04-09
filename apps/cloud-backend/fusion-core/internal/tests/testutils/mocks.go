// Package testutils provides shared test infrastructure for integration tests.
package testutils

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// MockAuthService implements the fusion.Auth interface for testing.
type MockAuthService struct{}

// GetAuthTokensByResourceOwnerPassword returns mock auth tokens.
func (m *MockAuthService) GetAuthTokensByResourceOwnerPassword(_ context.Context, _ string) (*types.AuthTokenResponse, error) {
	return nil, nil
}

// ValidateToken validates a mock token.
func (m *MockAuthService) ValidateToken(_ string) (*jwt.MapClaims, error) {
	return nil, nil
}

// ExtractUserID extracts user ID from mock claims.
func (m *MockAuthService) ExtractUserID(_ *jwt.MapClaims) (string, error) {
	return "", nil
}

// ExtractUserEmail extracts user email from mock claims.
func (m *MockAuthService) ExtractUserEmail(_ *jwt.MapClaims) (string, error) {
	return "", nil
}

// ExtractTokenFromHeader extracts token from authorization header.
func (m *MockAuthService) ExtractTokenFromHeader(_ string) (string, error) {
	return "", nil
}

// MockMiddleware implements the middleware.AuthMiddleware interface for testing.
type MockMiddleware struct{}

// Middleware returns a pass-through middleware for testing.
func (m *MockMiddleware) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}

// CreateSimpleLoggerMiddleware creates a middleware that adds a logger to the context.
func CreateSimpleLoggerMiddleware(logger interface{}) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set("logger", logger)
		c.Next()
	}
}

// Ensure MockMiddleware implements the interface
var _ middleware.AuthMiddleware = (*MockMiddleware)(nil)
