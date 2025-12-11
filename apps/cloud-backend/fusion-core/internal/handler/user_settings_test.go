package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockUserSettingsService is a mock implementation of the fusion.UserSettings interface
type MockUserSettingsService struct {
	mock.Mock
}

func (m *MockUserSettingsService) GetUserSettings(ctx context.Context, userID string) (*types.UserSettings, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserSettings), args.Error(1)
}

func (m *MockUserSettingsService) CreateUserSettings(ctx context.Context, settingsDetails *types.UserSettings) (string, error) {
	args := m.Called(ctx, settingsDetails)
	return args.Get(0).(string), args.Error(1)
}

func (m *MockUserSettingsService) UpdateUserSettings(ctx context.Context, settingsDetails *types.UserSettings) error {
	args := m.Called(ctx, settingsDetails)
	return args.Error(0)
}

func (m *MockUserSettingsService) CreateUserSettingsForRegistration(ctx context.Context, userID string) error {
	args := m.Called(ctx, userID)
	return args.Error(0)
}

// TestGetUserSettings tests the GetUserSettings handler endpoint
func TestGetUserSettings(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validUUID := uuid.New().String()

	tests := []struct {
		name            string
		userID          string
		setupAuth       bool
		mockGetSettings func(ctx context.Context, userID string) (*types.UserSettings, error)
		expectedStatus  int
		expectedBody    map[string]interface{}
	}{
		{
			name:      "authenticated user with settings - success",
			userID:    validUUID,
			setupAuth: true,
			mockGetSettings: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return &types.UserSettings{
					ID:       uuid.New().String(),
					UserID:   userID,
					Language: "en-US",
					Theme:    "dark",
				}, nil
			},
			expectedStatus: http.StatusOK,
			expectedBody:   nil, // Will verify settings is returned
		},
		{
			name:            "invalid user ID format",
			userID:          "invalid-uuid",
			setupAuth:       true,
			mockGetSettings: nil, // Handler validates before calling service
			expectedStatus:  http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "Invalid user ID format",
			},
		},
		{
			name:      "settings not found - sql no rows",
			userID:    validUUID,
			setupAuth: true,
			mockGetSettings: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return nil, errors.New("sql: no rows in result set")
			},
			expectedStatus: http.StatusNotFound,
			expectedBody: map[string]interface{}{
				"error": "User settings not found",
			},
		},
		{
			name:      "settings not found - explicit error",
			userID:    validUUID,
			setupAuth: true,
			mockGetSettings: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return nil, errors.New("user settings not found")
			},
			expectedStatus: http.StatusNotFound,
			expectedBody: map[string]interface{}{
				"error": "User settings not found",
			},
		},
		{
			name:      "database error",
			userID:    validUUID,
			setupAuth: true,
			mockGetSettings: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return nil, errors.New("database connection failed")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "Internal server error",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserSettingsService{}

			if tt.mockGetSettings != nil {
				result, err := tt.mockGetSettings(context.Background(), tt.userID)
				mockService.On("GetUserSettings", mock.Anything, tt.userID).Return(result, err)
			}

			handler := NewUserSettingsHandler(mockService)

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			req, _ := http.NewRequest(http.MethodGet, "/user/settings", nil)
			c.Request = req

			if tt.setupAuth {
				c.Set("user_auth", &types.UserAuthorizationResponse{
					User: types.UserInfo{
						ID: tt.userID,
					},
				})
			}

			handler.GetUserSettings(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)

				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			if tt.expectedStatus == http.StatusOK {
				var settings types.UserSettings
				err := json.Unmarshal(w.Body.Bytes(), &settings)
				assert.NoError(t, err)
				assert.Equal(t, "en-US", settings.Language)
			}

			if tt.mockGetSettings != nil {
				mockService.AssertExpectations(t)
			}
		})
	}
}

// TestUpdateUserSettings tests the UpdateUserSettings handler endpoint
func TestUpdateUserSettings(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validUUID := uuid.New().String()
	anotherUUID := uuid.New().String()

	tests := []struct {
		name               string
		requestBody        interface{}
		authenticatedUser  string
		setupAuth          bool
		mockUpdateSettings func(ctx context.Context, settingsDetails *types.UserSettings) error
		expectedStatus     int
		expectedError      string
	}{
		{
			name: "successful update",
			requestBody: types.UserSettings{
				ID:       validUUID,
				UserID:   validUUID,
				Language: "fr-FR",
				Theme:    "light",
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockUpdateSettings: func(ctx context.Context, settingsDetails *types.UserSettings) error {
				return nil
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "invalid JSON format",
			requestBody:    "{invalid json}",
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid JSON format",
		},
		{
			name: "missing ID",
			requestBody: map[string]interface{}{
				"user_id":  validUUID,
				"language": "en-US",
			},
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "id is required for updating settings",
		},
		{
			name: "invalid ID format",
			requestBody: types.UserSettings{
				ID:       "invalid-uuid",
				UserID:   validUUID,
				Language: "en-US",
			},
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid ID format: must be a valid UUID",
		},
		{
			name: "missing user_id",
			requestBody: map[string]interface{}{
				"id":       validUUID,
				"language": "en-US",
			},
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "user_id is required for updating settings",
		},
		{
			name: "invalid user_id format",
			requestBody: types.UserSettings{
				ID:       validUUID,
				UserID:   "invalid",
				Language: "en-US",
			},
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid user_id format: must be a valid UUID",
		},
		{
			name: "unauthorized - different user",
			requestBody: types.UserSettings{
				ID:       validUUID,
				UserID:   anotherUUID,
				Language: "en-US",
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			expectedStatus:    http.StatusUnauthorized,
			expectedError:     "Unauthorized: You are not allowed to update this user's settings",
		},
		{
			name: "missing authentication",
			requestBody: types.UserSettings{
				ID:       validUUID,
				UserID:   validUUID,
				Language: "en-US",
			},
			setupAuth:      false,
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "Authentication required",
		},
		{
			name: "invalid authentication context type",
			requestBody: types.UserSettings{
				ID:       validUUID,
				UserID:   validUUID,
				Language: "en-US",
			},
			setupAuth:      true,
			expectedStatus: http.StatusUnauthorized,
			// Will be set in test using wrong type
		},
		{
			name: "settings not found",
			requestBody: types.UserSettings{
				ID:       validUUID,
				UserID:   validUUID,
				Language: "en-US",
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockUpdateSettings: func(ctx context.Context, settingsDetails *types.UserSettings) error {
				return errors.New("user settings not found")
			},
			expectedStatus: http.StatusNotFound,
			expectedError:  "User settings not found",
		},
		{
			name: "database error",
			requestBody: types.UserSettings{
				ID:       validUUID,
				UserID:   validUUID,
				Language: "en-US",
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockUpdateSettings: func(ctx context.Context, settingsDetails *types.UserSettings) error {
				return errors.New("database connection failed")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedError:  "Failed to update user settings",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserSettingsService{}

			if tt.mockUpdateSettings != nil {
				mockService.On("UpdateUserSettings", mock.Anything, mock.AnythingOfType("*types.UserSettings")).Return(tt.mockUpdateSettings(context.Background(), &types.UserSettings{}))
			}

			handler := NewUserSettingsHandler(mockService)

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			var bodyBytes []byte
			if strBody, ok := tt.requestBody.(string); ok {
				bodyBytes = []byte(strBody)
			} else {
				bodyBytes, _ = json.Marshal(tt.requestBody)
			}

			req, _ := http.NewRequest(http.MethodPut, "/user/settings", bytes.NewBuffer(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			c.Request = req

			if tt.setupAuth {
				authUserID := tt.authenticatedUser
				if authUserID == "" {
					authUserID = validUUID
				}

				// Special case for testing invalid auth context type
				if tt.name == "invalid authentication context type" {
					c.Set("user_auth", "invalid type")
				} else {
					c.Set("user_auth", &types.UserAuthorizationResponse{
						User: types.UserInfo{
							ID: authUserID,
						},
					})
				}
			}

			handler.UpdateUserSettings(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedError != "" {
				var response map[string]interface{}
				json.Unmarshal(w.Body.Bytes(), &response)
				errMsg, ok := response["error"].(string)
				assert.True(t, ok)
				assert.Contains(t, errMsg, tt.expectedError)
			}
		})
	}
}

// TestCreateUserSettings tests the CreateUserSettings handler endpoint
func TestCreateUserSettings(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validUUID := uuid.New().String()

	tests := []struct {
		name               string
		requestBody        interface{}
		mockCreateSettings func(ctx context.Context, settingsDetails *types.UserSettings) error
		expectedStatus     int
		expectedError      string
	}{
		{
			name: "valid settings creation",
			requestBody: types.UserSettings{
				UserID:   validUUID,
				Language: "en-US",
				Theme:    "dark",
			},
			mockCreateSettings: func(ctx context.Context, settingsDetails *types.UserSettings) error {
				return nil
			},
			expectedStatus: http.StatusCreated,
		},
		{
			name:           "invalid JSON format",
			requestBody:    "invalid json",
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid request body",
		},
		{
			name: "missing user_id",
			requestBody: map[string]interface{}{
				"language": "en-US",
			},
			expectedStatus: http.StatusBadRequest,
			expectedError:  "user_id is required for creating settings",
		},
		{
			name: "invalid user_id format",
			requestBody: types.UserSettings{
				UserID:   "invalid-uuid",
				Language: "en-US",
			},
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid user_id format: must be a valid UUID",
		},
		{
			name: "database error",
			requestBody: types.UserSettings{
				UserID:   validUUID,
				Language: "en-US",
			},
			mockCreateSettings: func(ctx context.Context, settingsDetails *types.UserSettings) error {
				return errors.New("database error")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedError:  "Failed to create user settings",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserSettingsService{}

			if tt.mockCreateSettings != nil {
				mockService.On("CreateUserSettings", mock.Anything, mock.AnythingOfType("*types.UserSettings")).Return(tt.mockCreateSettings(context.Background(), &types.UserSettings{}))
			}

			handler := NewUserSettingsHandler(mockService)

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			var bodyBytes []byte
			if strBody, ok := tt.requestBody.(string); ok {
				bodyBytes = []byte(strBody)
			} else {
				bodyBytes, _ = json.Marshal(tt.requestBody)
			}

			req, _ := http.NewRequest(http.MethodPost, "/user/settings", bytes.NewBuffer(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			c.Request = req

			handler.CreateUserSettings(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedError != "" {
				var response map[string]interface{}
				json.Unmarshal(w.Body.Bytes(), &response)
				errMsg, ok := response["error"].(string)
				assert.True(t, ok)
				assert.Contains(t, errMsg, tt.expectedError)
			}
		})
	}
}
