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

// TestGetUserProfile tests the GetUserProfile handler endpoint
func TestGetUserProfile(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validUUID := uuid.New().String()

	tests := []struct {
		name           string
		userID         string
		setupAuth      bool
		mockGetProfile func(ctx context.Context, userID string) (*types.UserProfile, error)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:      "authenticated user with profile - success",
			userID:    validUUID,
			setupAuth: true,
			mockGetProfile: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return &types.UserProfile{
					ID:        uuid.New().String(),
					UserID:    userID,
					Email:     "test@example.com",
					FirstName: "John",
					LastName:  "Doe",
				}, nil
			},
			expectedStatus: http.StatusOK,
			expectedBody:   nil, // Will verify profile is returned
		},
		{
			name:           "invalid user ID format",
			userID:         "invalid-uuid",
			setupAuth:      true,
			mockGetProfile: nil, // Handler validates before calling service
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"message": "Invalid user ID format",
			},
		},
		{
			name:      "profile not found - sql no rows",
			userID:    validUUID,
			setupAuth: true,
			mockGetProfile: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return nil, errors.New("sql: no rows in result set")
			},
			expectedStatus: http.StatusNotFound,
			expectedBody: map[string]interface{}{
				"message": "User profile not found",
			},
		},
		{
			name:      "profile not found - explicit error",
			userID:    validUUID,
			setupAuth: true,
			mockGetProfile: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return nil, errors.New("user profile not found")
			},
			expectedStatus: http.StatusNotFound,
			expectedBody: map[string]interface{}{
				"message": "User profile not found",
			},
		},
		{
			name:      "database error",
			userID:    validUUID,
			setupAuth: true,
			mockGetProfile: func(ctx context.Context, userID string) (*types.UserProfile, error) {
				return nil, errors.New("database connection failed")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"message": "Internal server error",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mock service
			mockService := &MockUserService{}

			if tt.mockGetProfile != nil {
				// Don't setup expectation for invalid user ID format as the handler returns error before calling service
				if tt.name != "invalid user ID format" {
					mockService.On("GetUserProfile", mock.Anything, tt.userID).Return(tt.mockGetProfile(context.Background(), tt.userID))
				}
			}

			// Create handler
			handler := NewUserHandler(mockService)

			// Setup Gin test context
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			// Setup request
			req, _ := http.NewRequest(http.MethodGet, "/user/profile", nil)
			c.Request = req

			// Setup authentication context
			if tt.setupAuth {
				c.Set("user_auth", &types.UserAuthorizationResponse{
					User: types.UserInfo{
						ID: tt.userID,
					},
				})
			}

			// Execute handler
			handler.GetUserProfileDetails(c)

			// Verify status code
			assert.Equal(t, tt.expectedStatus, w.Code)

			// Verify response body
			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)

				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			// For success case, verify profile is returned
			if tt.expectedStatus == http.StatusOK {
				var profile types.UserProfile
				err := json.Unmarshal(w.Body.Bytes(), &profile)
				assert.NoError(t, err)
				assert.Equal(t, "test@example.com", profile.Email)
			}

			if tt.mockGetProfile != nil && tt.name != "invalid user ID format" {
				mockService.AssertExpectations(t)
			}
		})
	}
}

// TestCreateUserProfile tests the CreateUserProfile handler endpoint
func TestCreateUserProfile(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validUUID := uuid.New().String()
	generatedID := uuid.New().String()

	tests := []struct {
		name              string
		requestBody       interface{}
		mockCreateProfile func(ctx context.Context, profileDetails *types.UserProfile) (string, error)
		expectedStatus    int
		expectedError     string
	}{
		{
			name: "valid profile creation",
			requestBody: types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockCreateProfile: func(ctx context.Context, profileDetails *types.UserProfile) (string, error) {
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
				"email": "test@example.com",
			},
			expectedStatus: http.StatusBadRequest,
			expectedError:  "user_id is required for creating profile",
		},
		{
			name: "invalid user_id format",
			requestBody: types.UserProfile{
				UserID: "invalid-uuid",
				Email:  "test@example.com",
			},
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid user_id format: must be a valid UUID",
		},
		{
			name: "missing email",
			requestBody: types.UserProfile{
				UserID: validUUID,
			},
			expectedStatus: http.StatusBadRequest,
			expectedError:  "email is required for creating profile",
		},
		{
			name: "database error",
			requestBody: types.UserProfile{
				UserID: validUUID,
				Email:  "test@example.com",
			},
			mockCreateProfile: func(ctx context.Context, profileDetails *types.UserProfile) (string, error) {
				return "", errors.New("database error")
			},
			expectedStatus: http.StatusInternalServerError,
			expectedError:  "Failed to create user profile",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserService{}

			if tt.mockCreateProfile != nil {
				mockService.On("CreateUserProfile", mock.Anything, mock.AnythingOfType("*types.UserProfile")).Return(tt.mockCreateProfile(context.Background(), &types.UserProfile{}))
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

			req, _ := http.NewRequest(http.MethodPost, "/user/profile", bytes.NewBuffer(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			c.Request = req

			handler.CreateUserProfile(c)

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

// TestUpdateUserProfile tests the UpdateUserProfile handler endpoint
func TestUpdateUserProfile(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validUUID := uuid.New().String()
	validID := uuid.New().String()

	newEmail := "updated@example.com"

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
			requestBody: types.UserProfileUpdateRequest{
				Email: &newEmail,
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockVerify: func(args mock.Arguments) {
				profileDetails := args.Get(1).(*types.UserProfileUpdateRequest)
				profileID := args.Get(2).(string)
				userID := args.Get(3).(string)

				assert.Equal(t, validID, profileID)
				assert.Equal(t, validUUID, userID)
				assert.Equal(t, newEmail, *profileDetails.Email)
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
			requestBody:    types.UserProfileUpdateRequest{},
			setupAuth:      true,
			expectedStatus: http.StatusBadRequest,
			expectedError:  "Invalid ID format: must be a valid UUID",
		},
		{
			name: "missing authentication",
			requestBody: types.UserProfileUpdateRequest{
				Email: &newEmail,
			},
			setupAuth:      false,
			expectedStatus: http.StatusUnauthorized,
			expectedError:  "Authentication required",
		},
		{
			name: "profile not found",
			requestBody: types.UserProfileUpdateRequest{
				Email: &newEmail,
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockReturnError:   errors.New("user profile not found"),
			expectedStatus:    http.StatusNotFound,
			expectedError:     "User profile not found",
		},
		{
			name: "database error",
			requestBody: types.UserProfileUpdateRequest{
				Email: &newEmail,
			},
			authenticatedUser: validUUID,
			setupAuth:         true,
			mockReturnError:   errors.New("database connection failed"),
			expectedStatus:    http.StatusInternalServerError,
			expectedError:     "Failed to update user profile",
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockUserService{}

			// Only setup mock if we expect the service to be called
			shouldCallService := tt.expectedStatus != http.StatusBadRequest && tt.expectedStatus != http.StatusUnauthorized

			if shouldCallService {
				call := mockService.On("UpdateUserProfile", mock.Anything, mock.AnythingOfType("*types.UserProfileUpdateRequest"), mock.AnythingOfType("string"), mock.AnythingOfType("string"))

				if tt.mockVerify != nil {
					call.Run(tt.mockVerify)
				}

				call.Return(tt.mockReturnError)
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

			// Add ID to URL param
			param := ""
			if tt.name != "invalid ID format" {
				param = validID
			} else {
				param = "invalid-uuid"
			}

			req, _ := http.NewRequest(http.MethodPut, "/user/profile/"+param, bytes.NewBuffer(bodyBytes))
			req.Header.Set("Content-Type", "application/json")
			c.Request = req

			// Manually set param since we're using mock context
			c.Params = gin.Params{gin.Param{Key: "profileID", Value: param}}

			if tt.setupAuth {
				authUserID := tt.authenticatedUser
				if authUserID == "" {
					authUserID = validUUID
				}
				c.Set("user_auth", &types.UserAuthorizationResponse{
					User: types.UserInfo{
						ID: authUserID,
					},
				})
			}

			handler.UpdateUserProfile(c)

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
