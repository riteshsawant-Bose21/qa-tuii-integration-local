// Package testutils provides shared test infrastructure for integration tests.
package testutils

import (
	"context"
	"net/http"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
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

// CreateMockAuthMiddleware creates mock authentication middleware for testing.
// It extracts X-User-ID header and sets user context.
func CreateMockAuthMiddleware(testUsers []TestUser) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetHeader("X-User-ID")
		if userID == "" && len(testUsers) > 0 {
			userID = testUsers[0].ID
		}

		var userEmail string
		for _, u := range testUsers {
			if u.ID == userID {
				userEmail = u.Email
				break
			}
		}
		if userEmail == "" && len(testUsers) > 0 {
			userEmail = testUsers[0].Email
		}

		c.Set("userID", userID)
		c.Set("email", userEmail)
		c.Set("user_email", userEmail)
		c.Next()
	}
}

// CreateMockAccessControlMiddleware creates mock access control middleware for testing.
// It builds user authorization from context or creates a default one.
func CreateMockAccessControlMiddleware(testUsers []TestUser) gin.HandlerFunc {
	return func(c *gin.Context) {
		userEmail, exists := c.Get("user_email")
		if !exists {
			c.JSON(http.StatusUnauthorized, types.ErrorResponse{ErrorMessage: errorutil.MsgUnauthorized})
			c.Abort()
			return
		}

		email, ok := userEmail.(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, types.ErrorResponse{ErrorMessage: errorutil.MsgUnauthorized})
			c.Abort()
			return
		}

		userAuth := createDefaultUserAuth(c, email, testUsers)
		c.Set("user_auth", userAuth)
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

// createDefaultUserAuth creates a default user authorization response for testing.
func createDefaultUserAuth(c *gin.Context, email string, testUsers []TestUser) *types.UserAuthorizationResponse {
	userID, _ := c.Get("userID")

	var userIDStr string
	if userID != nil {
		userIDStr, _ = userID.(string)
	}
	if userIDStr == "" {
		// Find user ID by email
		for _, u := range testUsers {
			if u.Email == email {
				userIDStr = u.ID
				break
			}
		}
	}
	if userIDStr == "" && len(testUsers) > 0 {
		userIDStr = testUsers[0].ID
	}

	return &types.UserAuthorizationResponse{
		User: types.UserInfo{
			ID:    userIDStr,
			Email: email,
		},
		Account: types.AccountInfo{
			ID:   "50000001-0000-4000-8000-000000000001",
			Name: "Bose Corporation",
			Type: "Bose Pro",
		},
		Role: types.RoleInfo{
			ID:       2,
			RoleName: "User",
		},
		Permissions: map[string]string{
			"project.read":   "read",
			"project.create": "edit",
			"project.update": "edit",
			"project.delete": "edit",
			"projects":       "edit",
			"devices":        "edit",
			"device.create":  "edit",
			"device.update":  "edit",
			"device.delete":  "edit",
			"*":              "edit",
		},
	}
}

// CreateMockUserAuthMiddleware creates middleware that sets user_auth directly from headers.
// This is simpler than the access control middleware and useful for device tests.
func CreateMockUserAuthMiddleware(testUsers []TestUser) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetHeader("X-User-ID")
		accountID := c.GetHeader("X-Account-ID")
		userEmail := c.GetHeader("X-User-Email")

		// Use defaults if not provided
		if userID == "" && len(testUsers) > 0 {
			userID = testUsers[0].ID
		}
		if accountID == "" {
			accountID = "50000001-0000-4000-8000-000000000001"
		}
		if userEmail == "" {
			for _, u := range testUsers {
				if u.ID == userID {
					userEmail = u.Email
					break
				}
			}
			if userEmail == "" && len(testUsers) > 0 {
				userEmail = testUsers[0].Email
			}
		}

		userAuth := &types.UserAuthorizationResponse{
			User: types.UserInfo{
				ID:    userID,
				Email: userEmail,
			},
			Account: types.AccountInfo{
				ID:   accountID,
				Name: "Bose Corporation",
				Type: "Bose Pro",
			},
			Role: types.RoleInfo{
				ID:       2,
				RoleName: "User",
			},
			Permissions: map[string]string{
				"*": "edit",
			},
		}

		c.Set("user_auth", userAuth)
		c.Next()
	}
}

// Ensure MockMiddleware implements the interface
var _ middleware.AuthMiddleware = (*MockMiddleware)(nil)
