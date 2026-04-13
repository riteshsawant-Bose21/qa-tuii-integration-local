package handler

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/stretchr/testify/mock"
)

// MockUserService is a mock implementation of fusion.User interface
type MockUserService struct {
	mock.Mock
}

func (m *MockUserService) GetUserByEmail(ctx context.Context, email string) (*types.User, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.User), args.Error(1)
}

func (m *MockUserService) GetUserAuthorization(ctx context.Context, email string) (*types.UserAuthorizationResponse, error) {
	args := m.Called(ctx, email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserAuthorizationResponse), args.Error(1)
}

func (m *MockUserService) CheckUserPermission(ctx context.Context, userEmail, featureName string, requiredLevel string) (bool, error) {
	args := m.Called(ctx, userEmail, featureName, requiredLevel)
	return args.Bool(0), args.Error(1)
}

func (m *MockUserService) CreateUser(ctx context.Context, req *types.CreateUserRequest) (*types.User, error) {
	args := m.Called(ctx, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.User), args.Error(1)
}

func (m *MockUserService) UpdateUser(ctx context.Context, userID string, req *types.UpdateUserRequest) (*types.User, error) {
	args := m.Called(ctx, userID, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.User), args.Error(1)
}

// Profile Methods
func (m *MockUserService) GetUserProfile(ctx context.Context, userID string) (*types.UserProfile, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserProfile), args.Error(1)
}

func (m *MockUserService) CreateUserProfile(ctx context.Context, userProfile *types.UserProfile) (string, error) {
	args := m.Called(ctx, userProfile)
	return args.String(0), args.Error(1)
}

func (m *MockUserService) UpdateUserProfile(ctx context.Context, profileDetails *types.UserProfileUpdateRequest, profileID string, userID string) error {
	args := m.Called(ctx, profileDetails, profileID, userID)
	return args.Error(0)
}

func (m *MockUserService) CreateUserProfileForRegistration(ctx context.Context, profileData *types.UserProfile) (string, error) {
	args := m.Called(ctx, profileData)
	return args.String(0), args.Error(1)
}

// Settings Methods
func (m *MockUserService) GetUserSettings(ctx context.Context, userID string) (*types.UserSettings, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserSettings), args.Error(1)
}

func (m *MockUserService) CreateUserSettings(ctx context.Context, userSettings *types.UserSettings) (string, error) {
	args := m.Called(ctx, userSettings)
	return args.String(0), args.Error(1)
}

func (m *MockUserService) UpdateUserSettings(ctx context.Context, settingsDetails *types.UpdateUserSettingsRequest, settingsID string, userID string) error {
	args := m.Called(ctx, settingsDetails, settingsID, userID)
	return args.Error(0)
}

func (m *MockUserService) CreateUserSettingsForRegistration(ctx context.Context, userID string) (string, error) {
	args := m.Called(ctx, userID)
	return args.String(0), args.Error(1)
}

// Role Management Methods
func (m *MockUserService) GetOrganizationRoleManagement(ctx context.Context, accountID string) (*types.RoleManagementResponse, error) {
	args := m.Called(ctx, accountID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.RoleManagementResponse), args.Error(1)
}

func (m *MockUserService) CreateRole(ctx context.Context, accountID string, req *types.CreateRoleRequest) (*types.Role, error) {
	args := m.Called(ctx, accountID, req)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.Role), args.Error(1)
}

func (m *MockUserService) UpdateUserRole(ctx context.Context, userID, accountID string, newRoleID int) error {
	args := m.Called(ctx, userID, accountID, newRoleID)
	return args.Error(0)
}

func (m *MockUserService) UpdateRolePermissions(ctx context.Context, roleID int, accountID string, permissions []types.PermissionUpdateRequest) error {
	args := m.Called(ctx, roleID, accountID, permissions)
	return args.Error(0)
}

func (m *MockUserService) CheckAdminPermission(ctx context.Context, userEmail, accountID string) (bool, error) {
	args := m.Called(ctx, userEmail, accountID)
	return args.Bool(0), args.Error(1)
}
