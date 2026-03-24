package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

// MockFirmwareService is a mock implementation of fusion.Firmware interface
type MockFirmwareService struct {
	mock.Mock
}

func (m *MockFirmwareService) NotifyBundleUpload(ctx context.Context, payload *types.NotifyBundleUploadPayload, logger *zap.Logger) (*types.BundleResponse, error) {
	args := m.Called(ctx, payload, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.BundleResponse), args.Error(1)
}

func (m *MockFirmwareService) ListBundles(ctx context.Context, approvalStatus *string, page, limit int) (*types.BundleListResponse, error) {
	args := m.Called(ctx, approvalStatus, page, limit)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.BundleListResponse), args.Error(1)
}

func (m *MockFirmwareService) ApproveBundle(ctx context.Context, bundleID string, approvedBy string, approvalStatus string, logger *zap.Logger) error {
	args := m.Called(ctx, bundleID, approvedBy, approvalStatus, logger)
	return args.Error(0)
}

func (m *MockFirmwareService) CheckForUpdate(ctx context.Context, payload *types.FirmwareUpdateRequest, logger *zap.Logger) (*types.FirmwareUpdateResponse, error) {
	args := m.Called(ctx, payload, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.FirmwareUpdateResponse), args.Error(1)
}

func (m *MockFirmwareService) GetBundleDownloadURL(ctx context.Context, bundleID string, logger *zap.Logger) (*types.DownloadArtifactResponse, error) {
	args := m.Called(ctx, bundleID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DownloadArtifactResponse), args.Error(1)
}

func (m *MockFirmwareService) InsertBundleUpdateStatus(ctx context.Context, payload *types.LogBundleUpdateStatusPayload, logger *zap.Logger) error {
	args := m.Called(ctx, payload, logger)
	return args.Error(0)
}

// --- Helper ---

func setupTestContext(method, url string, body interface{}) (*httptest.ResponseRecorder, *gin.Context) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	var req *http.Request
	if body != nil {
		var bodyBytes []byte
		if strBody, ok := body.(string); ok {
			bodyBytes = []byte(strBody)
		} else {
			bodyBytes, _ = json.Marshal(body)
		}
		req, _ = http.NewRequest(method, url, bytes.NewBuffer(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
	} else {
		req, _ = http.NewRequest(method, url, nil)
	}

	c.Request = req

	logger, _ := zap.NewDevelopment()
	c.Set("logger", logger)

	return w, c
}

func setupTestContextWithQueryParams(method, url string, queryParams map[string]string) (*httptest.ResponseRecorder, *gin.Context) {
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	req, _ := http.NewRequest(method, url, nil)
	if queryParams != nil {
		q := req.URL.Query()
		for key, value := range queryParams {
			q.Add(key, value)
		}
		req.URL.RawQuery = q.Encode()
	}

	c.Request = req

	logger, _ := zap.NewDevelopment()
	c.Set("logger", logger)

	return w, c
}

// ==================== NotifyBundleUpload Tests ====================

func TestNotifyBundleUpload(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validPayload := types.NotifyBundleUploadPayload{
		Version:              "2.0.0",
		Checksum:             "abc123checksum",
		ReleaseNotes:         "Bug fixes and improvements",
		MinPrevVersion:       "1.0.0",
		MinDesktopAppVersion: "1.0.0",
		S3Path:               "bundles/stable/bundle-2.0.0.zip",
		ManifestData: map[string]interface{}{
			"devices": []string{"amp-8x300", "amp-4x150"},
		},
	}

	tests := []struct {
		name           string
		requestBody    interface{}
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:        "success - new bundle uploaded",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("NotifyBundleUpload", mock.Anything, mock.Anything, mock.Anything).
					Return(&types.BundleResponse{ID: "bundle-uuid-123"}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody: map[string]interface{}{
				"id": "bundle-uuid-123",
			},
		},
		{
			name:           "bad request - invalid JSON payload",
			requestBody:    "invalid json{",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "bad request - version already exists",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("NotifyBundleUpload", mock.Anything, mock.Anything, mock.Anything).
					Return(nil, errorutil.ErrVersionExists)
			},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "internal server error - DB failure",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("NotifyBundleUpload", mock.Anything, mock.Anything, mock.Anything).
					Return(nil, errors.New("db connection failed"))
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodPost, "/firmware/bundles", tt.requestBody)
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.NotifyBundleUpload(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}

// ==================== ListBundles Tests ====================

func TestListBundles(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		queryParams    map[string]string
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:        "success - list all bundles (no filter)",
			queryParams: nil,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListBundles", mock.Anything, (*string)(nil), 1, 10).
					Return(&types.BundleListResponse{
						Bundles: []types.BundleDetails{{ID: "bundle-1"}},
						Total:   1,
						Page:    1,
						Limit:   10,
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:        "success - filter by APPROVED",
			queryParams: map[string]string{"approval_status": types.BundleStatusApproved},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				status := types.BundleStatusApproved
				m.On("ListBundles", mock.Anything, &status, 1, 10).
					Return(&types.BundleListResponse{
						Bundles: []types.BundleDetails{{ID: "bundle-approved"}},
						Total:   1,
						Page:    1,
						Limit:   10,
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:        "success - filter by PENDING",
			queryParams: map[string]string{"approval_status": types.BundleStatusPending},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				status := types.BundleStatusPending
				m.On("ListBundles", mock.Anything, &status, 1, 10).
					Return(&types.BundleListResponse{
						Bundles: []types.BundleDetails{{ID: "bundle-pending"}},
						Total:   1,
						Page:    1,
						Limit:   10,
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:        "success - filter by REVOKED",
			queryParams: map[string]string{"approval_status": types.BundleStatusRevoked},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				status := types.BundleStatusRevoked
				m.On("ListBundles", mock.Anything, &status, 1, 10).
					Return(&types.BundleListResponse{
						Bundles: []types.BundleDetails{{ID: "bundle-revoked"}},
						Total:   1,
						Page:    1,
						Limit:   10,
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "bad request - invalid approval_status",
			queryParams:    map[string]string{"approval_status": "INVALID"},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:           "bad request - invalid page",
			queryParams:    map[string]string{"page": "0"},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:           "bad request - invalid limit",
			queryParams:    map[string]string{"limit": "101"},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "internal server error - service failure",
			queryParams: nil,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListBundles", mock.Anything, (*string)(nil), 1, 10).
					Return(nil, errors.New("db error"))
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContextWithQueryParams(http.MethodGet, "/firmware/bundles", tt.queryParams)
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			} else if tt.name == "internal server error - logger wrong type" {
				c.Set("logger", "not-a-logger")
			}

			h.ListBundles(c)

			assert.Equal(t, tt.expectedStatus, w.Code)
			mockFirmware.AssertExpectations(t)
		})
	}
}

// ==================== ApproveBundle Tests ====================

func TestApproveBundle(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		bundleID       string
		actionParam    string
		setupLogger    bool
		setupUserAuth  bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:          "success - bundle approved",
			bundleID:      "550e8400-e29b-41d4-a716-446655440000",
			actionParam:   "approve",
			setupLogger:   true,
			setupUserAuth: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("ApproveBundle", mock.Anything, "550e8400-e29b-41d4-a716-446655440000", "user-123", types.BundleStatusApproved, mock.AnythingOfType("*zap.Logger")).
					Return(nil)
			},
			expectedStatus: http.StatusNoContent,
		},
		{
			name:          "success - bundle revoked",
			bundleID:      "550e8400-e29b-41d4-a716-446655440000",
			actionParam:   "revoke",
			setupLogger:   true,
			setupUserAuth: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("ApproveBundle", mock.Anything, "550e8400-e29b-41d4-a716-446655440000", "user-123", types.BundleStatusRevoked, mock.AnythingOfType("*zap.Logger")).
					Return(nil)
			},
			expectedStatus: http.StatusNoContent,
		},
		{
			name:           "bad request - empty bundleID",
			bundleID:       "",
			actionParam:    "approve",
			setupLogger:    true,
			setupUserAuth:  true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:           "bad request - missing action param",
			bundleID:       "550e8400-e29b-41d4-a716-446655440000",
			actionParam:    "",
			setupLogger:    true,
			setupUserAuth:  true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:           "bad request - invalid action param",
			bundleID:       "550e8400-e29b-41d4-a716-446655440000",
			actionParam:    "invalid",
			setupLogger:    true,
			setupUserAuth:  true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:          "not found - bundle does not exist",
			bundleID:      "f47ac10b-58cc-4372-a567-0e02b2c3d479", // Valid UUID
			actionParam:   "approve",
			setupLogger:   true,
			setupUserAuth: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("ApproveBundle", mock.Anything, "f47ac10b-58cc-4372-a567-0e02b2c3d479", mock.AnythingOfType("string"), types.BundleStatusApproved, mock.AnythingOfType("*zap.Logger")).
					Return(errorutil.ErrBundleNotFound)
			},
			expectedStatus: http.StatusNotFound,
		},
		{
			name:          "bad request - bundle not approved (revoke before approve)",
			bundleID:      "550e8400-e29b-41d4-a716-446655440005",
			actionParam:   "revoke",
			setupLogger:   true,
			setupUserAuth: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("ApproveBundle", mock.Anything, "550e8400-e29b-41d4-a716-446655440005", "user-123", types.BundleStatusRevoked, mock.AnythingOfType("*zap.Logger")).
					Return(errorutil.ErrBundleNotApproved)
			},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:          "internal server error - service failure",
			bundleID:      "550e8400-e29b-41d4-a716-446655440001",
			actionParam:   "approve",
			setupLogger:   true,
			setupUserAuth: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("ApproveBundle", mock.Anything, "550e8400-e29b-41d4-a716-446655440001", "user-123", types.BundleStatusApproved, mock.AnythingOfType("*zap.Logger")).
					Return(errors.New("database update failed"))
			},
			expectedStatus: http.StatusInternalServerError,
		},
		{
			name:           "unauthorized - user auth not in context",
			bundleID:       "550e8400-e29b-41d4-a716-446655440003",
			actionParam:    "approve",
			setupLogger:    true,
			setupUserAuth:  false,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusUnauthorized,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			queryParams := map[string]string{}
			if tt.actionParam != "" {
				queryParams["action"] = tt.actionParam
			}

			w, c := setupTestContextWithQueryParams(http.MethodPut, "/firmware/bundles/"+tt.bundleID+"/approve", queryParams)
			c.Params = gin.Params{gin.Param{Key: "bundleID", Value: tt.bundleID}}
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}
			if tt.setupUserAuth {
				c.Set("user_auth", &types.UserAuthorizationResponse{
					User: types.UserInfo{ID: "user-123"},
				})
			}

			h.ApproveBundle(c)

			assert.Equal(t, tt.expectedStatus, c.Writer.Status())

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}

// ==================== CheckForUpdate Tests ====================

func TestCheckForUpdate(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validQueryParams := map[string]string{
		"current_firmware_version":    "1.0.0",
		"current_desktop_app_version": "2.0.0",
	}

	tests := []struct {
		name           string
		queryParams    map[string]string
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:        "success - update available (stable)",
			queryParams: validQueryParams,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdate", mock.Anything, mock.AnythingOfType("*types.FirmwareUpdateRequest"), mock.AnythingOfType("*zap.Logger")).
					Return(&types.FirmwareUpdateResponse{
						UpdateAvailable:   true,
						AppUpdateRequired: false,
						BundleID:          "bundle-123",
						Version:           "2.0.0",
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name: "success - update available (beta channel)",
			queryParams: map[string]string{
				"current_firmware_version":    "1.0.0",
				"current_desktop_app_version": "2.0.0",
				"channel":                     "beta",
			},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdate", mock.Anything, mock.AnythingOfType("*types.FirmwareUpdateRequest"), mock.AnythingOfType("*zap.Logger")).
					Return(&types.FirmwareUpdateResponse{
						UpdateAvailable:   true,
						AppUpdateRequired: false,
						BundleID:          "bundle-beta-123",
						Version:           "2.1.0-beta",
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:        "success - no update available",
			queryParams: validQueryParams,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdate", mock.Anything, mock.AnythingOfType("*types.FirmwareUpdateRequest"), mock.AnythingOfType("*zap.Logger")).
					Return(&types.FirmwareUpdateResponse{
						UpdateAvailable:   false,
						AppUpdateRequired: false,
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:        "success - app update required",
			queryParams: validQueryParams,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdate", mock.Anything, mock.AnythingOfType("*types.FirmwareUpdateRequest"), mock.AnythingOfType("*zap.Logger")).
					Return(&types.FirmwareUpdateResponse{
						UpdateAvailable:      true,
						AppUpdateRequired:    true,
						MinDesktopAppVersion: "3.0.0",
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name: "bad request - missing current firmware version",
			queryParams: map[string]string{
				"current_desktop_app_version": "2.0.0",
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing current desktop app version",
			queryParams: map[string]string{
				"current_firmware_version": "1.0.0",
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "internal server error - service failure",
			queryParams: validQueryParams,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdate", mock.Anything, mock.AnythingOfType("*types.FirmwareUpdateRequest"), mock.AnythingOfType("*zap.Logger")).
					Return(nil, errors.New("database error"))
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContextWithQueryParams(http.MethodGet, "/firmware/updates/check", tt.queryParams)
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.CheckForUpdate(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}

// ==================== GetBundleDownloadURL Tests ====================

func TestGetBundleDownloadURL(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		bundleID       string
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:        "success - download URL generated",
			bundleID:    "550e8400-e29b-41d4-a716-446655440000",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("GetBundleDownloadURL", mock.Anything, "550e8400-e29b-41d4-a716-446655440000", mock.AnythingOfType("*zap.Logger")).
					Return(&types.DownloadArtifactResponse{
						DownloadURL: "https://s3.presigned.url/download",
						Checksum:    "sha256:abc123",
					}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody: map[string]interface{}{
				"download_url": "https://s3.presigned.url/download",
				"checksum":     "sha256:abc123",
			},
		},
		{
			name:           "bad request - invalid bundleId (not UUID)",
			bundleID:       "invalid-uuid",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:           "bad request - empty bundleId",
			bundleID:       "",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "forbidden - bundle not approved",
			bundleID:    "550e8400-e29b-41d4-a716-446655440000",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("GetBundleDownloadURL", mock.Anything, "550e8400-e29b-41d4-a716-446655440000", mock.AnythingOfType("*zap.Logger")).
					Return(nil, errorutil.ErrBundleNotApprovedForDownload)
			},
			expectedStatus: http.StatusForbidden,
		},
		{
			name:        "not found - bundle does not exist",
			bundleID:    "550e8400-e29b-41d4-a716-446655440000",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("GetBundleDownloadURL", mock.Anything, "550e8400-e29b-41d4-a716-446655440000", mock.AnythingOfType("*zap.Logger")).
					Return(nil, errorutil.ErrBundleNotFound)
			},
			expectedStatus: http.StatusNotFound,
		},
		{
			name:        "internal server error - S3 failure",
			bundleID:    "550e8400-e29b-41d4-a716-446655440000",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("GetBundleDownloadURL", mock.Anything, "550e8400-e29b-41d4-a716-446655440000", mock.AnythingOfType("*zap.Logger")).
					Return(nil, errors.New("failed to generate presign url"))
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodGet, "/firmware/bundles/"+tt.bundleID+"/download", nil)
			c.Params = gin.Params{gin.Param{Key: "bundleID", Value: tt.bundleID}}
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.GetBundleDownloadURL(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}

func TestInsertBundleUpdateStatus(t *testing.T) {
	gin.SetMode(gin.TestMode)

	installedAt := time.Now().UTC()

	validPayload := types.LogBundleUpdateStatusPayload{
		UpdateID:      "550e8400-e29b-41d4-a716-446655440000",
		ProjectID:     "550e8400-e29b-41d4-a716-446655440001",
		BundleVersion: "2.0.0",
		Status:        "INSTALL_SUCCESS",
		InstalledAt:   installedAt,
	}

	tests := []struct {
		name           string
		requestBody    interface{}
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
	}{
		{
			name:        "success - INSTALL_SUCCESS logged",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("InsertBundleUpdateStatus", mock.Anything, mock.AnythingOfType("*types.LogBundleUpdateStatusPayload"), mock.AnythingOfType("*zap.Logger")).
					Return(nil)
			},
			expectedStatus: http.StatusNoContent,
		},
		{
			name: "success - INSTALL_FAIL logged",
			requestBody: types.LogBundleUpdateStatusPayload{
				UpdateID:        "550e8400-e29b-41d4-a716-446655440000",
				ProjectID:       "550e8400-e29b-41d4-a716-446655440001",
				BundleVersion:   "2.0.0",
				PreviousVersion: "1.0.0",
				Status:          "INSTALL_FAIL",
				InstalledAt:     installedAt,
			},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("InsertBundleUpdateStatus", mock.Anything, mock.AnythingOfType("*types.LogBundleUpdateStatusPayload"), mock.AnythingOfType("*zap.Logger")).
					Return(nil)
			},
			expectedStatus: http.StatusNoContent,
		},
		{
			name:           "bad request - invalid JSON",
			requestBody:    "invalid json{",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing update_id",
			requestBody: map[string]interface{}{
				"project_id":     "550e8400-e29b-41d4-a716-446655440001",
				"bundle_version": "2.0.0",
				"status":         "INSTALL_SUCCESS",
				"installed_at":   installedAt,
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - invalid status value",
			requestBody: map[string]interface{}{
				"update_id":      "550e8400-e29b-41d4-a716-446655440000",
				"project_id":     "550e8400-e29b-41d4-a716-446655440001",
				"bundle_version": "2.0.0",
				"status":         "INVALID_STATUS",
				"installed_at":   installedAt,
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "internal server error - service failure",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("InsertBundleUpdateStatus", mock.Anything, mock.Anything, mock.Anything).
					Return(errors.New("database insert failed"))
			},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodPost, "/firmware/updates/status", tt.requestBody)
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.LogBundleUpdateStatus(c)

			assert.Equal(t, tt.expectedStatus, c.Writer.Status())

			// verify no body for 204 No Content
			if tt.expectedStatus == http.StatusNoContent {
				assert.Empty(t, w.Body.String())
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}
