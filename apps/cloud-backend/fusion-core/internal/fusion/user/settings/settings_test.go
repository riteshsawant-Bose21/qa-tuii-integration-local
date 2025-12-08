package usersettings

import (
	"context"
	"errors"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockDatabaseService is a mock implementation of the DatabaseService interface for testing
type MockDatabaseService struct {
	mock.Mock
}

func (m *MockDatabaseService) Insert(ctx context.Context, settings *types.UserSettings) error {
	args := m.Called(ctx, settings)
	return args.Error(0)
}

func (m *MockDatabaseService) SelectByUserID(ctx context.Context, userID string) (*types.UserSettings, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserSettings), args.Error(1)
}

func (m *MockDatabaseService) Update(ctx context.Context, settings *types.UserSettings) error {
	args := m.Called(ctx, settings)
	return args.Error(0)
}

// TestCreateUserSettingsForRegistration tests the CreateUserSettingsForRegistration function with all edge cases
func TestCreateUserSettingsForRegistration(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name        string
		userID      string
		mockInsert  func(ctx context.Context, settings *types.UserSettings) error
		wantErr     bool
		errContains string
	}{
		{
			name:   "valid userID - success with default values",
			userID: validUUID,
			mockInsert: func(ctx context.Context, settings *types.UserSettings) error {
				return nil
			},
			wantErr: false,
		},
		{
			name:        "empty userID - validation error",
			userID:      "",
			wantErr:     true,
			errContains: "userID is required",
		},
		{
			name:        "invalid userID format - random string",
			userID:      "abc123",
			wantErr:     true,
			errContains: "invalid user_id format: must be a valid UUID",
		},
		{
			name:        "invalid userID format - non-UUID",
			userID:      "not-a-valid-uuid",
			wantErr:     true,
			errContains: "invalid user_id format: must be a valid UUID",
		},
		{
			name:   "database insertion error - propagated",
			userID: validUUID,
			mockInsert: func(ctx context.Context, settings *types.UserSettings) error {
				return errors.New("database connection failed")
			},
			wantErr:     true,
			errContains: "database connection failed",
		},
		{
			name:   "database constraint violation",
			userID: validUUID,
			mockInsert: func(ctx context.Context, settings *types.UserSettings) error {
				return errors.New("duplicate key value violates unique constraint")
			},
			wantErr:     true,
			errContains: "duplicate key value violates unique constraint",
		},
	}

	for _, tt := range tests {
		tt := tt // capture range variable
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			// Create mock database service
			mockDB := &MockDatabaseService{}

			if tt.mockInsert != nil {
				// Set up the mock to call mockInsert and track the error
				mockDB.On("Insert", mock.Anything, mock.AnythingOfType("*types.UserSettings")).Run(func(args mock.Arguments) {
					settings := args.Get(1).(*types.UserSettings)
					// Verify default values are set correctly for successful test
					if tt.name == "valid userID - success with default values" {
						assert.Equal(t, "en-US", settings.Language)
						assert.Equal(t, "system", settings.Theme)
						assert.Equal(t, validUUID, settings.UserID)
					}
				}).Return(nil).Maybe() // Default to nil error

				// For error cases, we'll override with the actual error
				if tt.wantErr && tt.mockInsert(context.Background(), &types.UserSettings{}) != nil {
					err := tt.mockInsert(context.Background(), &types.UserSettings{})
					mockDB.ExpectedCalls = mockDB.ExpectedCalls[:0] // Clear previous expectations
					mockDB.On("Insert", mock.Anything, mock.AnythingOfType("*types.UserSettings")).Return(err)
				}
			}

			// Create service with mock
			service := &Service{
				dbService: mockDB,
			}

			// Execute the function
			ctx := context.Background()
			err := service.CreateUserSettingsForRegistration(ctx, tt.userID)

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

// TestGetUserSettings tests the GetUserSettings function
func TestGetUserSettings(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name         string
		userID       string
		mockSelect   func(ctx context.Context, userID string) (*types.UserSettings, error)
		wantErr      bool
		wantSettings bool
	}{
		{
			name:   "valid userID - settings found",
			userID: validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return &types.UserSettings{
					ID:       uuid.New().String(),
					UserID:   userID,
					Language: "en-US",
					Theme:    "dark",
				}, nil
			},
			wantErr:      false,
			wantSettings: true,
		},
		{
			name:   "settings not found",
			userID: validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return nil, errors.New("sql: no rows in result set")
			},
			wantErr:      true,
			wantSettings: false,
		},
		{
			name:   "database error",
			userID: validUUID,
			mockSelect: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return nil, errors.New("database connection failed")
			},
			wantErr:      true,
			wantSettings: false,
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
			settings, err := service.GetUserSettings(ctx, tt.userID)

			if tt.wantErr {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			if tt.wantSettings {
				assert.NotNil(t, settings)
			} else {
				assert.Nil(t, settings)
			}

			if tt.mockSelect != nil {
				mockDB.AssertExpectations(t)
			}
		})
	}
}

// TestCreateUserSettings tests the CreateUserSettings function
func TestCreateUserSettings(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name            string
		settingsDetails *types.UserSettings
		mockInsert      func(ctx context.Context, settings *types.UserSettings) error
		wantErr         bool
	}{
		{
			name: "successful creation",
			settingsDetails: &types.UserSettings{
				UserID:   validUUID,
				Language: "en-US",
				Theme:    "dark",
			},
			mockInsert: func(ctx context.Context, settings *types.UserSettings) error {
				return nil
			},
			wantErr: false,
		},
		{
			name: "database error",
			settingsDetails: &types.UserSettings{
				UserID:   validUUID,
				Language: "en-US",
				Theme:    "light",
			},
			mockInsert: func(ctx context.Context, settings *types.UserSettings) error {
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
				mockDB.On("Insert", mock.Anything, tt.settingsDetails).Return(tt.mockInsert(context.Background(), tt.settingsDetails))
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			err := service.CreateUserSettings(ctx, tt.settingsDetails)

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

// TestUpdateUserSettings tests the UpdateUserSettings function
func TestUpdateUserSettings(t *testing.T) {
	t.Parallel()

	validUUID := uuid.New().String()

	tests := []struct {
		name            string
		settingsDetails *types.UserSettings
		mockUpdate      func(ctx context.Context, settings *types.UserSettings) error
		wantErr         bool
	}{
		{
			name: "successful update",
			settingsDetails: &types.UserSettings{
				ID:       validUUID,
				UserID:   validUUID,
				Language: "fr-FR",
				Theme:    "light",
			},
			mockUpdate: func(ctx context.Context, settings *types.UserSettings) error {
				return nil
			},
			wantErr: false,
		},
		{
			name: "database error",
			settingsDetails: &types.UserSettings{
				ID:       validUUID,
				UserID:   validUUID,
				Language: "en-US",
				Theme:    "dark",
			},
			mockUpdate: func(ctx context.Context, settings *types.UserSettings) error {
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
				mockDB.On("Update", mock.Anything, tt.settingsDetails).Return(tt.mockUpdate(context.Background(), tt.settingsDetails))
			}

			service := &Service{
				dbService: mockDB,
			}

			ctx := context.Background()
			err := service.UpdateUserSettings(ctx, tt.settingsDetails)

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
