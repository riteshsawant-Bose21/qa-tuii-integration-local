package userprofile

import (
	"context"
	"database/sql"
	"errors"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
)

// MockDatabaseService is a mock implementation of the database service for testing
type MockDatabaseService struct {
	InsertFunc         func(ctx context.Context, profile *types.UserProfile) (string, error)
	SelectByUserIDFunc func(ctx context.Context, userID string) (*types.UserProfile, error)
	UpdateFunc         func(ctx context.Context, profile *types.UserProfile) error
}

func (m *MockDatabaseService) Insert(ctx context.Context, profile *types.UserProfile) (string, error) {
	if m.InsertFunc != nil {
		return m.InsertFunc(ctx, profile)
	}
	return "", nil
}

func (m *MockDatabaseService) SelectByUserID(ctx context.Context, userID string) (*types.UserProfile, error) {
	if m.SelectByUserIDFunc != nil {
		return m.SelectByUserIDFunc(ctx, userID)
	}
	return nil, nil
}

func (m *MockDatabaseService) Update(ctx context.Context, profile *types.UserProfile) error {
	if m.UpdateFunc != nil {
		return m.UpdateFunc(ctx, profile)
	}
	return nil
}

// TestCreateUserProfileForRegistration tests the CreateUserProfileForRegistration function with all edge cases
func TestCreateUserProfileForRegistration(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()
	generatedID := uuid.New().String()

	tests := []struct {
		name        string
		profileData *types.UserProfile
		mockInsert  func(ctx context.Context, profile *types.UserProfile) (string, error)
		wantErr     bool
		errContains string
	}{
		{
			name: "valid profile data - success",
			profileData: &types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) (string, error) {
				return generatedID, nil
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
			mockInsert: func(ctx context.Context, profile *types.UserProfile) (string, error) {
				return "", errors.New("database connection failed")
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
			mockInsert: func(ctx context.Context, profile *types.UserProfile) (string, error) {
				return generatedID, nil
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		tt := tt // capture range variable
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			// Create mock database service
			mockDB := &MockDatabaseService{
				InsertFunc: tt.mockInsert,
			}

			// Create service with mock
			service := &Service{
				dbService: mockDB,
			}

			// Execute the function
			ctx := context.Background()
			id, err := service.CreateUserProfileForRegistration(ctx, tt.profileData)

			// Verify results
			if tt.wantErr {
				if err == nil {
					t.Errorf("CreateUserProfileForRegistration() expected error but got nil")
					return
				}
				if tt.errContains != "" && !contains(err.Error(), tt.errContains) {
					t.Errorf("CreateUserProfileForRegistration() error = %v, want error containing %q", err, tt.errContains)
				}
			} else {
				if err != nil {
					t.Errorf("CreateUserProfileForRegistration() unexpected error = %v", err)
				}
				if id != generatedID {
					t.Errorf("CreateUserProfileForRegistration() returned id = %v, want %v", id, generatedID)
				}
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
				return nil, sql.ErrNoRows
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

			mockDB := &MockDatabaseService{
				SelectByUserIDFunc: tt.mockSelect,
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			profile, err := service.GetUserProfile(ctx, tt.userID)

			if tt.wantErr {
				if err == nil {
					t.Errorf("GetUserProfile() expected error but got nil")
				}
			} else {
				if err != nil {
					t.Errorf("GetUserProfile() unexpected error = %v", err)
				}
			}

			if tt.wantProfile && profile == nil {
				t.Errorf("GetUserProfile() expected profile but got nil")
			}
			if !tt.wantProfile && profile != nil {
				t.Errorf("GetUserProfile() expected nil profile but got %v", profile)
			}
		})
	}
}

// TestCreateUserProfile tests the CreateUserProfile function
func TestCreateUserProfile(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()
	generatedID := uuid.New().String()

	tests := []struct {
		name           string
		profileDetails *types.UserProfile
		mockInsert     func(ctx context.Context, profile *types.UserProfile) (string, error)
		wantErr        bool
	}{
		{
			name: "successful creation",
			profileDetails: &types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) (string, error) {
				return generatedID, nil
			},
			wantErr: false,
		},
		{
			name: "database error",
			profileDetails: &types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockInsert: func(ctx context.Context, profile *types.UserProfile) (string, error) {
				return "", errors.New("insert failed")
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			mockDB := &MockDatabaseService{
				InsertFunc: tt.mockInsert,
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			id, err := service.CreateUserProfile(ctx, tt.profileDetails)

			if tt.wantErr && err == nil {
				t.Errorf("CreateUserProfile() expected error but got nil")
			}
			if !tt.wantErr && err != nil {
				t.Errorf("CreateUserProfile() unexpected error = %v", err)
			}
			if !tt.wantErr && id != generatedID {
				t.Errorf("CreateUserProfile() returned id = %v, want %v", id, generatedID)
			}
		})
	}
}

// TestUpdateUserProfile tests the UpdateUserProfile function
func TestUpdateUserProfile(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()
	profileID := uuid.New().String()

	newEmail := "updated@example.com"
	newFirstName := "Updated"

	tests := []struct {
		name           string
		profileDetails *types.UserProfileUpdateRequest
		profileID      string
		userID         string
		mockSelect     func(ctx context.Context, userID string) (*types.UserProfile, error)
		mockUpdate     func(ctx context.Context, profile *types.UserProfile) error
		wantErr        bool
		errContains    string
	}{
		{
			name: "successful update",
			profileDetails: &types.UserProfileUpdateRequest{
				Email:     &newEmail,
				FirstName: &newFirstName,
			},
			profileID: profileID,
			userID:    validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return &types.UserProfile{
					ID:        profileID,
					UserID:    userID,
					Email:     "old@example.com",
					FirstName: "Old",
				}, nil
			},
			mockUpdate: func(ctx context.Context, profile *types.UserProfile) error {
				if profile.Email != "old@example.com" {
					t.Errorf("Expected email to remain %v, got %v", "old@example.com", profile.Email)
				}
				if profile.FirstName != newFirstName {
					t.Errorf("Expected first name to be updated to %v, got %v", newFirstName, profile.FirstName)
				}
				return nil
			},
			wantErr: false,
		},
		{
			name:           "user profile not found",
			profileDetails: &types.UserProfileUpdateRequest{},
			profileID:      profileID,
			userID:         validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return nil, sql.ErrNoRows
			},
			wantErr:     true,
			errContains: "user profile not found",
		},
		{
			name:           "database select error",
			profileDetails: &types.UserProfileUpdateRequest{},
			profileID:      profileID,
			userID:         validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return nil, errors.New("connection failed")
			},
			wantErr:     true,
			errContains: "failed to fetch user profile",
		},
		{
			name:           "profile ID mismatch",
			profileDetails: &types.UserProfileUpdateRequest{},
			profileID:      profileID,
			userID:         validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return &types.UserProfile{
					ID:     "different-id",
					UserID: userID,
				}, nil
			},
			wantErr:     true,
			errContains: "user profile does not belong to the specified user",
		},
		{
			name: "database update error",
			profileDetails: &types.UserProfileUpdateRequest{
				Email: &newEmail,
			},
			profileID: profileID,
			userID:    validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return &types.UserProfile{
					ID:     profileID,
					UserID: userID,
					Email:  "old@example.com",
				}, nil
			},
			mockUpdate: func(ctx context.Context, profile *types.UserProfile) error {
				return errors.New("update failed")
			},
			wantErr: true,
		},
		{
			name:           "nil request",
			profileDetails: nil,
			profileID:      profileID,
			userID:         validUUID,
			wantErr:        true,
			errContains:    "userProfile cannot be nil",
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			mockDB := &MockDatabaseService{
				UpdateFunc:         tt.mockUpdate,
				SelectByUserIDFunc: tt.mockSelect,
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			err := service.UpdateUserProfile(ctx, tt.profileDetails, tt.profileID, tt.userID)

			if tt.wantErr {
				if err == nil {
					t.Errorf("UpdateUserProfile() expected error but got nil")
					return
				}
				if tt.errContains != "" && !contains(err.Error(), tt.errContains) {
					t.Errorf("UpdateUserProfile() error = %v, want error containing %q", err, tt.errContains)
				}
			} else {
				if err != nil {
					t.Errorf("UpdateUserProfile() unexpected error = %v", err)
				}
			}
		})
	}
}

// contains is a helper function to check if a string contains a substring.
func contains(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(substr) == 0 ||
		(len(s) > 0 && len(substr) > 0 && stringContains(s, substr)))
}

func stringContains(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
