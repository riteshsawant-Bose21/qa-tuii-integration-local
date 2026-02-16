package handler

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
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

func TestFirmwareUpdateHandler_ListReleases(t *testing.T) {
	gin.SetMode(gin.TestMode)

	tests := []struct {
		name           string
		queryParams    string
		mockSetup      func(m *MockFirmwareService)
		expectedStatus int
		expectedBody   string
	}{
		{
			name:        "Happy Path - Default Pagination",
			queryParams: "",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "", 1, 10, "").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{
						{ID: "1", Platform: "p1", FirmwareVersion: "1.0.0", Created: time.Now()},
					},
					Total: 1,
					Page:  1,
					Limit: 10,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"releases":[{"id":"1"`,
		},
		{
			name:        "Happy Path - With Filtering and Pagination",
			queryParams: "?platform=p1&page=2&limit=5",
			mockSetup: func(m *MockFirmwareService) {
				m.On("ListReleases", mock.Anything, "p1", 2, 5, "").Return(&types.FirmwareReleaseListResponse{
					Releases: []types.FirmwareReleaseDetails{},
					Total:    0,
					Page:     2,
					Limit:    5,
				}, nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody:   `"total":0`,
		},
		{
			name:        "Internal Error",
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

			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)
			c.Request, _ = http.NewRequest("GET", "/firmware"+tt.queryParams, nil)

			// Inject logger into context
			logger, _ := zap.NewDevelopment()
			c.Set("logger", logger)

			h.ListReleases(c)

			assert.Equal(t, tt.expectedStatus, w.Code)
			if tt.expectedBody != "" {
				assert.Contains(t, w.Body.String(), tt.expectedBody)
			}

			// If we want to verify structure on non-error response
			if tt.expectedStatus == http.StatusOK {
				var resp types.FirmwareReleaseListResponse
				err := json.Unmarshal(w.Body.Bytes(), &resp)
				assert.NoError(t, err)
			}

			mockFirmware.AssertExpectations(t)
		})
	}
}
