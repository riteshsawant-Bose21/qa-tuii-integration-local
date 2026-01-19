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

// MockUserService is defined in mock_user_service_test.go

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
			name:      "invalid user ID format",
			userID:    "invalid-uuid",
			setupAuth: true,
			mockGetSettings: func(ctx context.Context, userID string) (*types.UserSettings, error) {
				return nil, nil
			},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"message": "Invalid user ID format",
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
				"message": "User settings not found",
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
				"message": "User settings not found",
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
				"message": "Internal server error",
			},
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserService{}

			if tt.mockGetSettings != nil {
				// Don't setup expectation for invalid user ID format as the handler returns error before calling service
				if tt.name != "invalid user ID format" {
					mockService.On("GetUserSettings", mock.Anything, tt.userID).Return(tt.mockGetSettings(context.Background(), tt.userID))
				}
			}

			handler := NewUserHandler(mockService)

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
		})
	}
}

// TestUpdateUserSettings tests the UpdateUserSettings handler endpoint
func TestUpdateUserSettings(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validUUID := uuid.New().String()
	validSettingsID := uuid.New().String()

	newLanguage := "fr-FR"

	tests := []struct {
		name              string
		requestBody       interface{}
		authenticatedUser string
		setupAuth         bool
		mockVerify        func(args mock.Arguments)
		mockReturnError   error
		expectedStatus    int
		expectedError     string
	}{
		{
			name: "successful update",
			requestBody: types.UpdateUserSettingsRequest{
				Language: &newLanguage,
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockVerify: func(args mock.Arguments) {
				settingsDetails := args.Get(1).(*types.UpdateUserSettingsRequest)
				settingsID := args.Get(2).(string)
				userID := args.Get(3).(string)

				assert.Equal(t, validSettingsID, settingsID)
				assert.Equal(t, validUUID, userID)
				assert.Equal(t, newLanguage, *settingsDetails.Language)
			},
			mockReturnError: nil,
			expectedStatus:  http.StatusOK,
		},
		{
			name:           "invalid JSON format",
			requestBody:    "{invalid json}",
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid JSON format",
		},
		{
			name:           "invalid ID format",
			requestBody:    types.UpdateUserSettingsRequest{},
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid ID format: must be a valid UUID",
		},
		{
			name: "missing authentication",
			requestBody: types.UpdateUserSettingsRequest{
				Language: &newLanguage,
			},
			setupAuth:      false,
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "Authentication required",
		},
		{
			name: "settings not found",
			requestBody: types.UpdateUserSettingsRequest{
				Language: &newLanguage,
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockReturnError:   errors.New("user settings not found"),
			expectedStatus:    http.StatusNotFound,
			expectedError:     "User settings not found",
		},
		{
			name: "database error",
			requestBody: types.UpdateUserSettingsRequest{
				Language: &newLanguage,
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockReturnError:   errors.New("database connection failed"),
			expectedStatus:    http.StatusInternalServerError,
			expectedError:     "Failed to update user settings",
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserService{}

			// Only setup mock if we expect the service to be called
			// Service is called if authn is OK and validation passes.
			// Cases where it's NOT called: invalid JSON, invalid ID, no auth.
			shouldCallService := tt.expectedStatus != http.StatusBadRequest && tt.expectedStatus != http.StatusUnauthorized

			if shouldCallService {
				call := mockService.On("UpdateUserSettings", mock.Anything, mock.AnythingOfType("*types.UpdateUserSettingsRequest"), mock.AnythingOfType("string"), mock.AnythingOfType("string"))

				if tt.mockVerify != nil {
					call.Run(tt.mockVerify)
				}

				call.Return(tt.mockReturnError)
			}

			handler := NewUserHandler(mockService)

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			// Prepare request body
			var bodyBytes []byte
			if strBody, ok := tt.requestBody.(string); ok {
				bodyBytes = []byte(strBody)
			} else {
				bodyBytes, _ = json.Marshal(tt.requestBody)
			}

			// Add settingsID to URL param
			param := ""
			if tt.name != "invalid ID format" {
				param = validSettingsID
			} else {
				param = "invalid-uuid"
			}

			req, _ := http.NewRequest(http.MethodPut, "/user/settings/"+param, bytes.NewBuffer(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			c.Request = req

			// Manually set param since we're using mock context
			c.Params = gin.Params{gin.Param{Key: "settingsID", Value: param}}

			if tt.setupAuth {
				authUserID := tt.authenticatedUser
				if authUserID == "" {
					authUserID = validUUID
				}
				// Special case for invalid context type test if applicable
				if tt.name == "invalid authentication context type" {
					c.Set("user_auth", "invalid")
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
				errMsg, ok := response["message"].(string)
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
	generatedID := uuid.New().String()

	tests := []struct {
		name               string
		requestBody        interface{}
		mockCreateSettings func(ctx context.Context, settingsDetails *types.UserSettings) (string, error)
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
			mockCreateSettings: func(ctx context.Context, settingsDetails *types.UserSettings) (string, error) {
				return generatedID, nil
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
			mockCreateSettings: func(ctx context.Context, settingsDetails *types.UserSettings) (string, error) {
				return "", errors.New("database error")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedError:  "Failed to create user settings",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserService{}

			if tt.mockCreateSettings != nil {
				mockService.On("CreateUserSettings", mock.Anything, mock.AnythingOfType("*types.UserSettings")).Return(tt.mockCreateSettings(context.Background(), &types.UserSettings{}))
			}

			handler := NewUserHandler(mockService)

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
				errMsg, ok := response["message"].(string)
				assert.True(t, ok)
				assert.Contains(t, errMsg, tt.expectedError)
			}

			// verify returned ID for success
			if tt.expectedStatus == http.StatusCreated {
				var response map[string]interface{}
				json.Unmarshal(w.Body.Bytes(), &response)
				assert.Equal(t, generatedID, response["id"])
			}
		})
	}
}
