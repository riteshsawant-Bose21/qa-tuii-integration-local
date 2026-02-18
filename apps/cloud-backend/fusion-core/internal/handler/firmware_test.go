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

func (m *MockFirmwareService) InitiateRelease(ctx context.Context, releaseDetails *types.InitiateFirmwareReleasePayload, logger *zap.Logger) (string, string, error) {
	args := m.Called(ctx, releaseDetails, logger)
	return args.String(0), args.String(1), args.Error(2)
}

func (m *MockFirmwareService) MakeReleaseAvailable(ctx context.Context, releaseID string, logger *zap.Logger) error {
	args := m.Called(ctx, releaseID, logger)
	return args.Error(0)
}

func (m *MockFirmwareService) ListReleases(ctx context.Context, platform string, page, limit int, minVersion string) (*types.FirmwareReleaseListResponse, error) {
	args := m.Called(ctx, platform, page, limit, minVersion)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.FirmwareReleaseListResponse), args.Error(1)
}

func (m *MockFirmwareService) LogFirmwareUpdate(ctx context.Context, req *types.LogFirmwareUpdateRequest) error {
	args := m.Called(ctx, req)
	return args.Error(0)
}

func (m *MockFirmwareService) CheckForUpdates(ctx context.Context, request *types.CheckUpdateRequest) (*types.CheckUpdateResponse, error) {
	args := m.Called(ctx, request)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.CheckUpdateResponse), args.Error(1)
}

func (m *MockFirmwareService) GetArtifactDownloadURL(ctx context.Context, platform, version string, logger *zap.Logger) (*types.DownloadArtifactResponse, error) {
	args := m.Called(ctx, platform, version, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DownloadArtifactResponse), args.Error(1)
}

func (m *MockFirmwareService) DeployRelease(ctx context.Context, releaseID string, channel string, logger *zap.Logger) error {
	args := m.Called(ctx, releaseID, channel, logger)
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

// ==================== InitiateRelease Tests ====================

func TestInitiateRelease(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validPayload := types.InitiateFirmwareReleasePayload{
		Checksum: "abc123checksum",
		MetaData: types.FirmwareReleaseMetaData{
			Platform:             "amp-8x300",
			FirmwareVersion:      "2.0.0",
			ReleaseNotes:         "Bug fixes and improvements",
			MinDesktopAppVersion: "1.0.0",
			HwCompatibility:      "rev-a",
			ApiVersion:           "v1",
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
			name:        "success - new release initiated",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("InitiateRelease", mock.Anything, mock.AnythingOfType("*types.InitiateFirmwareReleasePayload"), mock.AnythingOfType("*zap.Logger")).
					Return("release-uuid-123", "https://s3.presigned.url/upload", nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody: map[string]interface{}{
				"releaseId":    "release-uuid-123",
				"presignedUrl": "https://s3.presigned.url/upload",
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
			name: "bad request - missing required fields",
			requestBody: map[string]interface{}{
				"checksum": "abc123",
				// metaData missing
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing platform",
			requestBody: types.InitiateFirmwareReleasePayload{
				Checksum: "abc123",
				MetaData: types.FirmwareReleaseMetaData{
					FirmwareVersion:      "1.0.0",
					ReleaseNotes:         "notes",
					MinDesktopAppVersion: "1.0.0",
					HwCompatibility:      "rev-a",
					ApiVersion:           "v1",
				},
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "bad request - version already exists",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("InitiateRelease", mock.Anything, mock.AnythingOfType("*types.InitiateFirmwareReleasePayload"), mock.AnythingOfType("*zap.Logger")).
					Return("", "", errorutil.ErrVersionExists)
			},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "internal server error - service failure",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("InitiateRelease", mock.Anything, mock.AnythingOfType("*types.InitiateFirmwareReleasePayload"), mock.AnythingOfType("*zap.Logger")).
					Return("", "", errors.New("s3 connection failed"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "Internal Server Error",
			},
		},
		{
			name:           "internal server error - logger not in context",
			requestBody:    validPayload,
			setupLogger:    false,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodPost, "/firmware/releases", tt.requestBody)
			if !tt.setupLogger {
				c.Set("logger", nil)
				// Remove logger to test missing logger case
				c.Keys = map[string]interface{}{}
			}

			h.InitiateRelease(c)

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

// ==================== MakeReleaseAvailable Tests ====================

func TestMakeReleaseAvailable(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		releaseID      string
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:        "success - release made available",
			releaseID:   "release-uuid-123",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("MakeReleaseAvailable", mock.Anything, "release-uuid-123", mock.Anything).
					Return(nil)
			},
			expectedStatus: http.StatusNoContent,
		},
		{
			name:           "bad request - empty releaseID",
			releaseID:      "",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "releaseID is required",
			},
		},
		{
			name:        "not found - release does not exist",
			releaseID:   "non-existent-uuid",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("MakeReleaseAvailable", mock.Anything, "non-existent-uuid", mock.Anything).
					Return(errorutil.ErrReleaseNotFound)
			},
			expectedStatus: http.StatusNotFound,
			expectedBody: map[string]interface{}{
				"error": "Release not found",
			},
		},
		{
			name:        "internal server error - service failure",
			releaseID:   "release-uuid-123",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("MakeReleaseAvailable", mock.Anything, "release-uuid-123", mock.Anything).
					Return(errors.New("database update failed"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "Internal Server Error",
			},
		},
		{
			name:           "internal server error - logger not in context",
			releaseID:      "release-uuid-123",
			setupLogger:    false,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodPost, "/firmware/releases/"+tt.releaseID+"/mark-available", nil)
			c.Params = gin.Params{gin.Param{Key: "releaseID", Value: tt.releaseID}}
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.MakeReleaseAvailable(c)

			// Use c.Writer.Status() for no-body responses (204) since httptest.ResponseRecorder
			// only updates Code when WriteHeader is called via Write()
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

// ==================== ListReleases Tests ====================

func TestListReleases(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		queryParams    string
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   string
	}{
		{
			name:        "success - default pagination",
			queryParams: "",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "", 1, 10, "").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{
						{ID: "1", Platform: "amp-8x300", FirmwareVersion: "2.0.0", Status: "AVAILABLE", Created: time.Now()},
						{ID: "2", Platform: "amp-8x300", FirmwareVersion: "1.0.0", Status: "AVAILABLE", Created: time.Now()},
					},
					Total: 2,
					Page:  1,
					Limit: 10,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"total":2`,
		},
		{
			name:        "success - with platform filter",
			queryParams: "?platform=amp-4x150",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "amp-4x150", 1, 10, "").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{
						{ID: "3", Platform: "amp-4x150", FirmwareVersion: "1.0.0", Created: time.Now()},
					},
					Total: 1,
					Page:  1,
					Limit: 10,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"total":1`,
		},
		{
			name:        "success - with custom pagination",
			queryParams: "?page=2&limit=5",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "", 2, 5, "").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{},
					Total:    0,
					Page:     2,
					Limit:    5,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"page":2`,
		},
		{
			name:        "success - with min_version filter",
			queryParams: "?min_version=1.0.0",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "", 1, 10, "1.0.0").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{
						{ID: "1", Platform: "amp-8x300", FirmwareVersion: "2.0.0", Created: time.Now()},
					},
					Total: 1,
					Page:  1,
					Limit: 10,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"total":1`,
		},
		{
			name:        "success - with all filters combined",
			queryParams: "?platform=amp-8x300&page=1&limit=20&min_version=1.0.0",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "amp-8x300", 1, 20, "1.0.0").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{},
					Total:    0,
					Page:     1,
					Limit:    20,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"total":0`,
		},
		{
			name:        "success - empty result set",
			queryParams: "",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "", 1, 10, "").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{},
					Total:    0,
					Page:     1,
					Limit:    10,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"total":0`,
		},
		{
			name:        "success - invalid page defaults to 0",
			queryParams: "?page=abc",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "", 0, 10, "").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{},
					Total:    0,
					Page:     0,
					Limit:    10,
				}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:        "internal server error - service failure",
			queryParams: "",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "", 1, 10, "").Return(nil, errors.New("db error"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody:   `"error":"Internal Server Error"`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodGet, "/firmware/releases"+tt.queryParams, nil)

			h.ListReleases(c)

			assert.Equal(t, tt.expectedStatus, w.Code)
			if tt.expectedBody != "" {
				assert.Contains(t, w.Body.String(), tt.expectedBody)
			}

			// verify response structure on success
			if tt.expectedStatus == http.StatusOK {
				var resp types.FirmwareReleaseListResponse
				err := json.Unmarshal(w.Body.Bytes(), &resp)
				assert.NoError(t, err)
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}

// ==================== CheckUpdates Tests ====================

func TestCheckUpdates(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validPayload := types.CheckUpdateRequest{
		Channel: "stable",
		Devices: []types.DeviceUpdateCheckPayload{
			{
				DeviceID:               "device-001",
				Platform:               "amp-8x300",
				CurrentFirmwareVersion: "1.0.0",
				HardwareRevision:       "rev-a",
			},
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
			name:        "success - update available",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdates", mock.Anything, mock.AnythingOfType("*types.CheckUpdateRequest")).
					Return(&types.CheckUpdateResponse{
						Results: map[string]types.DeviceUpdateResult{
							"device-001": {
								UpdateAvailable: true,
								LatestVersion:   "2.0.0",
								ReleaseNotes:    "Bug fixes",
							},
						},
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:        "success - no update available",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdates", mock.Anything, mock.AnythingOfType("*types.CheckUpdateRequest")).
					Return(&types.CheckUpdateResponse{
						Results: map[string]types.DeviceUpdateResult{
							"device-001": {
								UpdateAvailable: false,
							},
						},
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name: "success - multiple devices",
			requestBody: types.CheckUpdateRequest{
				Channel: "stable",
				Devices: []types.DeviceUpdateCheckPayload{
					{DeviceID: "device-001", Platform: "amp-8x300", CurrentFirmwareVersion: "1.0.0"},
					{DeviceID: "device-002", Platform: "amp-4x150", CurrentFirmwareVersion: "2.0.0"},
				},
			},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("CheckForUpdates", mock.Anything, mock.AnythingOfType("*types.CheckUpdateRequest")).
					Return(&types.CheckUpdateResponse{
						Results: map[string]types.DeviceUpdateResult{
							"device-001": {UpdateAvailable: true, LatestVersion: "2.0.0"},
							"device-002": {UpdateAvailable: false},
						},
					}, nil)
			},
			expectedStatus: http.StatusOK,
		},
		{
			name:           "bad request - invalid JSON",
			requestBody:    "invalid json{",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing channel",
			requestBody: map[string]interface{}{
				"devices": []map[string]interface{}{
					{"device_id": "d1", "platform": "p1", "current_firmware_version": "1.0.0"},
				},
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing devices",
			requestBody: map[string]interface{}{
				"channel": "stable",
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
				m.On("CheckForUpdates", mock.Anything, mock.AnythingOfType("*types.CheckUpdateRequest")).
					Return(nil, errors.New("database error"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "Internal Server Error",
			},
		},
		{
			name:           "internal server error - logger not in context",
			requestBody:    validPayload,
			setupLogger:    false,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodPost, "/firmware/updates/check", tt.requestBody)
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.CheckUpdates(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			// verify response structure on success
			if tt.expectedStatus == http.StatusOK {
				var resp types.CheckUpdateResponse
				err := json.Unmarshal(w.Body.Bytes(), &resp)
				assert.NoError(t, err)
				assert.NotNil(t, resp.Results)
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}

// ==================== DownloadArtifact Tests ====================

func TestDownloadArtifact(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		platform       string
		version        string
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:        "success - download URL generated",
			platform:    "amp-8x300",
			version:     "2.0.0",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("GetArtifactDownloadURL", mock.Anything, "amp-8x300", "2.0.0", mock.AnythingOfType("*zap.Logger")).
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
			name:           "bad request - missing platform",
			platform:       "",
			version:        "2.0.0",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "platform and version are required",
			},
		},
		{
			name:           "bad request - missing version",
			platform:       "amp-8x300",
			version:        "",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "platform and version are required",
			},
		},
		{
			name:           "bad request - both missing",
			platform:       "",
			version:        "",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "platform and version are required",
			},
		},
		{
			name:        "not found - release does not exist",
			platform:    "amp-8x300",
			version:     "99.0.0",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("GetArtifactDownloadURL", mock.Anything, "amp-8x300", "99.0.0", mock.AnythingOfType("*zap.Logger")).
					Return(nil, errorutil.ErrReleaseNotFound)
			},
			expectedStatus: http.StatusNotFound,
			expectedBody: map[string]interface{}{
				"error": "Firmware release not found for the specified platform and version",
			},
		},
		{
			name:        "internal server error - S3 failure",
			platform:    "amp-8x300",
			version:     "2.0.0",
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("GetArtifactDownloadURL", mock.Anything, "amp-8x300", "2.0.0", mock.AnythingOfType("*zap.Logger")).
					Return(nil, errors.New("failed to generate presign url"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "Internal Server Error",
			},
		},
		{
			name:           "internal server error - logger not in context",
			platform:       "amp-8x300",
			version:        "2.0.0",
			setupLogger:    false,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodGet, "/firmware/updates/"+tt.platform+"/"+tt.version+"/download", nil)
			c.Params = gin.Params{
				gin.Param{Key: "platform", Value: tt.platform},
				gin.Param{Key: "version", Value: tt.version},
			}
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.DownloadArtifact(c)

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

// ==================== LogFirmwareUpdate Tests ====================

func TestLogFirmwareUpdate(t *testing.T) {
	gin.SetMode(gin.TestMode)

	eventTime := time.Now().UTC()

	validPayload := types.LogFirmwareUpdateRequest{
		DeviceID:       "device-001",
		ReleaseVersion: "2.0.0",
		Status:         "INSTALL_SUCCESS",
		EventTime:      eventTime,
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
			name:        "success - INSTALL_SUCCESS logged",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("LogFirmwareUpdate", mock.Anything, mock.AnythingOfType("*types.LogFirmwareUpdateRequest")).
					Return(nil)
			},
			expectedStatus: http.StatusAccepted,
		},
		{
			name: "success - INSTALL_FAILED logged",
			requestBody: types.LogFirmwareUpdateRequest{
				DeviceID:       "device-002",
				ReleaseVersion: "2.0.0",
				Status:         "INSTALL_FAILED",
				EventTime:      eventTime,
			},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("LogFirmwareUpdate", mock.Anything, mock.AnythingOfType("*types.LogFirmwareUpdateRequest")).
					Return(nil)
			},
			expectedStatus: http.StatusAccepted,
		},
		{
			name:           "bad request - invalid JSON",
			requestBody:    "invalid json{",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing device_id",
			requestBody: map[string]interface{}{
				"release_version": "2.0.0",
				"status":          "INSTALL_SUCCESS",
				"event_time":      eventTime,
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing release_version",
			requestBody: map[string]interface{}{
				"device_id":  "device-001",
				"status":     "INSTALL_SUCCESS",
				"event_time": eventTime,
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing status",
			requestBody: map[string]interface{}{
				"device_id":       "device-001",
				"release_version": "2.0.0",
				"event_time":      eventTime,
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - invalid status value",
			requestBody: map[string]interface{}{
				"device_id":       "device-001",
				"release_version": "2.0.0",
				"status":          "INVALID_STATUS",
				"event_time":      eventTime,
			},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name: "bad request - missing event_time",
			requestBody: map[string]interface{}{
				"device_id":       "device-001",
				"release_version": "2.0.0",
				"status":          "INSTALL_SUCCESS",
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
				m.On("LogFirmwareUpdate", mock.Anything, mock.AnythingOfType("*types.LogFirmwareUpdateRequest")).
					Return(errors.New("database insert failed"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "Internal Server Error",
			},
		},
		{
			name:           "internal server error - logger not in context",
			requestBody:    validPayload,
			setupLogger:    false,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodPost, "/firmware/updates/log", tt.requestBody)
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.LogFirmwareUpdate(c)

			// Use c.Writer.Status() for no-body responses (202) since httptest.ResponseRecorder
			// only updates Code when WriteHeader is called via Write()
			assert.Equal(t, tt.expectedStatus, c.Writer.Status())

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}

			// verify no body for 202 Accepted
			if tt.expectedStatus == http.StatusAccepted {
				assert.Empty(t, w.Body.String())
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}

// ==================== DeployRelease Tests ====================

func TestDeployRelease(t *testing.T) {
	gin.SetMode(gin.TestMode)

	validPayload := types.DeployReleasePayload{
		Channel: "testing",
	}

	tests := []struct {
		name           string
		releaseID      string
		requestBody    interface{}
		setupLogger    bool
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name:        "success - release deployed to testing channel",
			releaseID:   "release-uuid-123",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("DeployRelease", mock.Anything, "release-uuid-123", "testing", mock.Anything).
					Return(nil)
			},
			expectedStatus: http.StatusNoContent,
		},
		{
			name:        "success - release deployed to stable channel",
			releaseID:   "release-uuid-123",
			requestBody: types.DeployReleasePayload{Channel: "stable"},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("DeployRelease", mock.Anything, "release-uuid-123", "stable", mock.Anything).
					Return(nil)
			},
			expectedStatus: http.StatusNoContent,
		},
		{
			name:           "bad request - empty releaseID",
			releaseID:      "",
			requestBody:    validPayload,
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "releaseID is required",
			},
		},
		{
			name:           "bad request - invalid JSON",
			releaseID:      "release-uuid-123",
			requestBody:    "invalid json{",
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:           "bad request - missing channel",
			releaseID:      "release-uuid-123",
			requestBody:    map[string]interface{}{},
			setupLogger:    true,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:        "not found - release does not exist",
			releaseID:   "non-existent-uuid",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("DeployRelease", mock.Anything, "non-existent-uuid", "testing", mock.Anything).
					Return(errorutil.ErrReleaseNotFound)
			},
			expectedStatus: http.StatusNotFound,
			expectedBody: map[string]interface{}{
				"error": "Release not found",
			},
		},
		{
			name:        "internal server error - service failure",
			releaseID:   "release-uuid-123",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("DeployRelease", mock.Anything, "release-uuid-123", "testing", mock.Anything).
					Return(errors.New("database update failed"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "Internal Server Error",
			},
		},
		{
			name:        "bad request - invalid channel",
			releaseID:   "release-uuid-123",
			requestBody: types.DeployReleasePayload{Channel: "invalid-channel"},
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("DeployRelease", mock.Anything, "release-uuid-123", "invalid-channel", mock.Anything).
					Return(errorutil.ErrInvalidChannel)
			},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "Invalid distribution channel",
			},
		},
		{
			name:        "bad request - invalid release status",
			releaseID:   "release-uuid-123",
			requestBody: validPayload,
			setupLogger: true,
			mockSetup: func(m *MockFirmwareService) {
				m.On("DeployRelease", mock.Anything, "release-uuid-123", "testing", mock.Anything).
					Return(errorutil.ErrInvalidReleaseStatus)
			},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "Only AVAILABLE releases can be deployed",
			},
		},
		{
			name:           "internal server error - logger not in context",
			releaseID:      "release-uuid-123",
			requestBody:    validPayload,
			setupLogger:    false,
			mockSetup:      func(m *MockFirmwareService) {},
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockFirmware := new(MockFirmwareService)
			tt.mockSetup(mockFirmware)

			h := NewFirmwareUpdateHandler(mockFirmware)

			w, c := setupTestContext(http.MethodPost, "/firmware/releases/"+tt.releaseID+"/deploy", tt.requestBody)
			c.Params = gin.Params{gin.Param{Key: "releaseID", Value: tt.releaseID}}
			if !tt.setupLogger {
				c.Keys = map[string]interface{}{}
			}

			h.DeployRelease(c)

			// Use c.Writer.Status() for no-body responses (204) since httptest.ResponseRecorder
			// only updates Code when WriteHeader is called via Write()
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
