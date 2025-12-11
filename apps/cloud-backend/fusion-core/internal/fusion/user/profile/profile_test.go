package userprofile

import (
	"context"
	"errors"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockDatabaseService is a mock implementation of the database service for testing
type MockDatabaseService struct {
	mock.Mock
}

func (m *MockDatabaseService) Insert(ctx context.Context, profile *types.UserProfile) error {
	args := m.Called(ctx, profile)
	return args.Error(0)
}

func (m *MockDatabaseService) SelectByUserID(ctx context.Context, userID string) (*types.UserProfile, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserProfile), args.Error(1)
}

func (m *MockDatabaseService) Update(ctx context.Context, profile *types.UserProfile) error {
	args := m.Called(ctx, profile)
	return args.Error(0)
}

// TestCreateUserProfileForRegistration tests the CreateUserProfileForRegistration function with all edge cases
func TestCreateUserProfileForRegistration(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name        string
		profileData *types.UserProfile
		mockInsert  func(ctx context.Context, profile *types.UserProfile) error
		wantErr     bool
		errContains string
	}{
		{
			name: "valid profile data - success",
			profileData: &types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) error {
				return nil
			},
			wantErr: false,
		},
		{
			name: "empty UserID - validation error",
			profileData: &types.UserProfile{
				UserID: "",
				Email:  "test@example.com",
			},
			wantErr:     true,
			errContains: "userID is required",
		},
		{
			name: "invalid UserID format - non-UUID string",
			profileData: &types.UserProfile{
				UserID: "invalid-uuid-format",
				Email:  "test@example.com",
			},
			wantErr:     true,
			errContains: "invalid user_id format: must be a valid UUID",
		},
		{
			name: "invalid UserID format - random string",
			profileData: &types.UserProfile{
				UserID: "abc123",
				Email:  "test@example.com",
			},
			wantErr:     true,
			errContains: "invalid user_id format: must be a valid UUID",
		},
		{
			name: "missing email - validation error",
			profileData: &types.UserProfile{
				UserID: validUUID,
				Email:  "",
			},
			wantErr:     true,
			errContains: "email is required",
		},
		{
			name: "database insertion error - propagated",
			profileData: &types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) error {
				return errors.New("database connection failed")
			},
			wantErr:     true,
			errContains: "database connection failed",
		},
		{
			name: "valid profile with additional fields",
			profileData: &types.UserProfile{
				UserID:    validUUID,
				Email:     "test@example.com",
				FirstName: "John",
				LastName:  "Doe",
				Phone:     "+1234567890",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) error {
				return nil
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		tt := tt // capture range variable
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			// Create mock database service
			mockDB := &MockDatabaseService{}

			if tt.mockInsert != nil {
				mockDB.On("Insert", mock.Anything, tt.profileData).Return(tt.mockInsert(context.Background(), tt.profileData))
			}

			// Create service with mock
			service := &Service{
				dbService: mockDB,
			}

			// Execute the function
			ctx := context.Background()
			err := service.CreateUserProfileForRegistration(ctx, tt.profileData)

			// Verify results
			if tt.wantErr {
				assert.Error(t, err)
				if tt.errContains != "" {
					assert.Contains(t, err.Error(), tt.errContains)
				}
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

// TestGetUserProfile tests the GetUserProfile function
func TestGetUserProfile(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name        string
		userID      string
		mockSelect  func(ctx context.Context, userID string) (*types.UserProfile, error)
		wantErr     bool
		wantProfile bool
	}{
		{
			name:   "valid userID - profile found",
			userID: validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return &types.UserProfile{
					ID:     uuid.New().String(),
					UserID: userID,
					Email:  "test@example.com",
				}, nil
			},
			wantErr:     false,
			wantProfile: true,
		},
		{
			name:   "profile not found",
			userID: validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return nil, errors.New("sql: no rows in result set")
			},
			wantErr:     true,
			wantProfile: false,
		},
		{
			name:   "database error",
			userID: validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return nil, errors.New("database connection failed")
			},
			wantErr:     true,
			wantProfile: false,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			mockDB := &MockDatabaseService{}

			if tt.mockSelect != nil {
				result, err := tt.mockSelect(context.Background(), tt.userID)
				mockDB.On("SelectByUserID", mock.Anything, tt.userID).Return(result, err)
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			profile, err := service.GetUserProfile(ctx, tt.userID)

			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			if tt.wantProfile {
				assert.NotNil(t, profile)
			} else {
				assert.Nil(t, profile)
			}

			if tt.mockSelect != nil {
				mockDB.AssertExpectations(t)
			}
		})
	}
}

// TestCreateUserProfile tests the CreateUserProfile function
func TestCreateUserProfile(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name           string
		profileDetails *types.UserProfile
		mockInsert     func(ctx context.Context, profile *types.UserProfile) error
		wantErr        bool
	}{
		{
			name: "successful creation",
			profileDetails: &types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) error {
				return nil
			},
			wantErr: false,
		},
		{
			name: "database error",
			profileDetails: &types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) error {
				return errors.New("insert failed")
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			mockDB := &MockDatabaseService{}

			if tt.mockInsert != nil {
				mockDB.On("Insert", mock.Anything, tt.profileDetails).Return(tt.mockInsert(context.Background(), tt.profileDetails))
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			_, err := service.CreateUserProfile(ctx, tt.profileDetails)

			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			if tt.mockInsert != nil {
				mockDB.AssertExpectations(t)
			}
		})
	}
}

// TestUpdateUserProfile tests the UpdateUserProfile function
func TestUpdateUserProfile(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name           string
		profileDetails *types.UserProfile
		mockUpdate     func(ctx context.Context, profile *types.UserProfile) error
		wantErr        bool
	}{
		{
			name: "successful update",
			profileDetails: &types.UserProfile{
				ID:     validUUID,
				UserID: validUUID,
				Email:  "updated@example.com",
			},
			mockUpdate: func(ctx context.Context, profile *types.UserProfile) error {
				return nil
			},
			wantErr: false,
		},
		{
			name: "database error",
			profileDetails: &types.UserProfile{
				ID:     validUUID,
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockUpdate: func(ctx context.Context, profile *types.UserProfile) error {
				return errors.New("update failed")
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			mockDB := &MockDatabaseService{}

			if tt.mockUpdate != nil {
				mockDB.On("Update", mock.Anything, tt.profileDetails).Return(tt.mockUpdate(context.Background(), tt.profileDetails))
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			err := service.UpdateUserProfile(ctx, tt.profileDetails)

			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			if tt.mockUpdate != nil {
				mockDB.AssertExpectations(t)
			}
		})
	}
}
