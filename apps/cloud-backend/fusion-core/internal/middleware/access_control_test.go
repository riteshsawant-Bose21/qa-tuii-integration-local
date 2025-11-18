package middleware

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// MockUserService implements the UserService interface for testing
type MockUserService struct {
	permissions map[string]string
	shouldError bool
}

func (m *MockUserService) GetUserByEmail(ctx context.Context, email string) (*types.User, error) {
	if m.shouldError {
		return nil, errors.New("user not found")
	}
	return &types.User{ID: "user123", Email: email}, nil
}

func (m *MockUserService) GetUserAuthorization(ctx context.Context, email string) (*types.UserAuthorizationResponse, error) {
	if m.shouldError {
		return nil, errors.New("database error")
	}

	return &types.UserAuthorizationResponse{
		User: types.UserInfo{
			ID:    "user123",
			Email: email,
		},
		Permissions: m.permissions,
	}, nil
}

func (m *MockUserService) CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error) {
	return nil, errors.New("not implemented")
}

func (m *MockUserService) UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error) {
	return nil, errors.New("not implemented")
}

func TestAccessControlMiddleware_Success(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup mock user service with sufficient permissions
	mockUserService := &MockUserService{
		permissions: map[string]string{
			"project.read": "read",
		},
		shouldError: false,
	}

	// Setup access control
	accessControl := NewAccessControlMiddleware(mockUserService)

	// Setup gin router with middleware to simulate Auth0 setting user email
	r := gin.New()
	r.Use(func(c *gin.Context) {
		// Simulate Auth0 middleware setting user email
		c.Set("user_email", "user@example.com")
		c.Next()
	})
	r.Use(accessControl.RequirePermission("project.read", PermissionRead))
	r.GET("/api/v1/projects", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Create test request
	req, _ := http.NewRequest("GET", "/api/v1/projects", nil)
	w := httptest.NewRecorder()

	// Process the request through the router
	r.ServeHTTP(w, req)

	// Assertions
	assert.Equal(t, http.StatusOK, w.Code)
}

func TestAccessControlMiddleware_AccessDenied(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup mock user service with insufficient permissions (user doesn't have project.create)
	mockUserService := &MockUserService{
		permissions: map[string]string{
			"project.read": "read", // User only has read permission, not create
		},
		shouldError: false,
	}

	// Setup access control
	accessControl := NewAccessControlMiddleware(mockUserService)

	// Setup gin router with middleware requiring write permission
	r := gin.New()
	r.Use(func(c *gin.Context) {
		// Simulate Auth0 middleware setting user email
		c.Set("user_email", "user@example.com")
		c.Next()
	})
	r.Use(accessControl.RequirePermission("project.create", PermissionWrite))
	r.POST("/api/v1/projects", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Create test request
	req, _ := http.NewRequest("POST", "/api/v1/projects", nil)
	w := httptest.NewRecorder()

	// Process the request through the router
	r.ServeHTTP(w, req)

	// Assertions
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestAccessControlMiddleware_NoAuthentication(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup mock user service
	mockUserService := &MockUserService{
		permissions: map[string]string{},
		shouldError: false,
	}

	// Setup access control
	accessControl := NewAccessControlMiddleware(mockUserService)

	// Setup gin router WITHOUT the Auth0 middleware (no user_email set)
	r := gin.New()
	r.Use(accessControl.RequirePermission("project.read", PermissionRead))
	r.GET("/api/v1/projects", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Create test request without setting user_email in context
	req, _ := http.NewRequest("GET", "/api/v1/projects", nil)
	w := httptest.NewRecorder()

	// Process the request through the router
	r.ServeHTTP(w, req)

	// Assertions
	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestAccessControlMiddleware_UserServiceError(t *testing.T) {
	gin.SetMode(gin.TestMode)

	// Setup mock user service with error
	mockUserService := &MockUserService{
		permissions: map[string]string{},
		shouldError: true,
	}

	// Setup access control
	accessControl := NewAccessControlMiddleware(mockUserService)

	// Setup gin router
	r := gin.New()
	r.Use(func(c *gin.Context) {
		// Simulate Auth0 middleware setting user email
		c.Set("user_email", "user@example.com")
		c.Next()
	})
	r.Use(accessControl.RequirePermission("project.read", PermissionRead))
	r.GET("/api/v1/projects", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "success"})
	})

	// Create test request
	req, _ := http.NewRequest("GET", "/api/v1/projects", nil)
	w := httptest.NewRecorder()

	// Process the request through the router
	r.ServeHTTP(w, req)

	// Assertions
	assert.Equal(t, http.StatusForbidden, w.Code)
}

func TestPermissionLevelComparison(t *testing.T) {
	tests := []struct {
		name           string
		userPermission string
		requiredLevel  PermissionLevel
		expectedResult bool
	}{
		{
			name:           "None permission cannot access read",
			userPermission: "none",
			requiredLevel:  PermissionRead,
			expectedResult: false,
		},
		{
			name:           "Read permission can access read",
			userPermission: "read",
			requiredLevel:  PermissionRead,
			expectedResult: true,
		},
		{
			name:           "Read permission cannot access write",
			userPermission: "read",
			requiredLevel:  PermissionWrite,
			expectedResult: false,
		},
		{
			name:           "Write permission can access read",
			userPermission: "write",
			requiredLevel:  PermissionRead,
			expectedResult: true,
		},
		{
			name:           "Write permission can access write",
			userPermission: "write",
			requiredLevel:  PermissionWrite,
			expectedResult: true,
		},
		{
			name:           "Admin permission can access everything",
			userPermission: "admin",
			requiredLevel:  PermissionFull,
			expectedResult: true,
		},
		{
			name:           "Full permission can access everything",
			userPermission: "full",
			requiredLevel:  PermissionFull,
			expectedResult: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := hasPermissionLevel(tt.userPermission, tt.requiredLevel)
			assert.Equal(t, tt.expectedResult, result)
		})
	}
}
