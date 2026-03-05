// Package device provides integration tests for device endpoints.
package device

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/tests/testutils"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"go.uber.org/zap"
)

// MockDeviceService is a mock implementation of fusion.Device interface.
type MockDeviceService struct {
	mock.Mock
}

// CreateDevice mocks device creation.
func (m *MockDeviceService) CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error) {
	args := m.Called(ctx, request, user, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DeviceCreateResponse), args.Error(1)
}

// UpdateDevice mocks device update.
func (m *MockDeviceService) UpdateDevice(ctx context.Context, deviceID string, request *types.DeviceUpdateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, deviceID, request, user, logger)
	return args.Error(0)
}

// ResetDevice mocks device reset.
func (m *MockDeviceService) ResetDevice(ctx context.Context, deviceID string, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, deviceID, user, logger)
	return args.Error(0)
}

// ClaimDevice mocks device claiming.
func (m *MockDeviceService) ClaimDevice(ctx context.Context, deviceID string, request *types.DeviceClaimRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceClaimResponse, error) {
	args := m.Called(ctx, deviceID, request, user, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DeviceClaimResponse), args.Error(1)
}

// RotateCertificate mocks certificate rotation.
func (m *MockDeviceService) RotateCertificate(ctx context.Context, deviceID string, request *types.DeviceRotateCertRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceRotateCertResponse, error) {
	args := m.Called(ctx, deviceID, request, user, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DeviceRotateCertResponse), args.Error(1)
}

// Command mocks sending a command to device cluster.
func (m *MockDeviceService) Command(ctx context.Context, projectID string, request *types.CommandRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (string, error) {
	args := m.Called(ctx, projectID, request, user, logger)
	return args.String(0), args.Error(1)
}

// GetCommandStatus mocks getting command status.
func (m *MockDeviceService) GetCommandStatus(ctx context.Context, commandID string, logger *zap.Logger) (*types.CommandStatusResponse, error) {
	args := m.Called(ctx, commandID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.CommandStatusResponse), args.Error(1)
}

// DeviceIntegrationTestSuite defines the test suite for device integration tests.
type DeviceIntegrationTestSuite struct {
	testutils.BaseIntegrationSuite
	mockDeviceSVC *MockDeviceService
	testProjectID string
}

// SetupSuite runs once before all tests in the suite.
func (suite *DeviceIntegrationTestSuite) SetupSuite() {
	suite.BaseIntegrationSuite.SetupSuite()
	suite.setupTestProject()
}

// SetupTest runs before each test to reset the mock.
func (suite *DeviceIntegrationTestSuite) SetupTest() {
	suite.mockDeviceSVC = new(MockDeviceService)
	suite.setupRouter()
}

// setupTestProject creates a project to use for device tests.
func (suite *DeviceIntegrationTestSuite) setupTestProject() {
	// Create a project that devices can be assigned to
	suite.testProjectID = uuid.New().String()

	// Insert project directly into database
	_, err := suite.DB.Exec(`
		INSERT INTO project (
			id, name, description, application, venue, 
			project_phase, environment_type, budget_amount, currency,
			primary_owner_account_id, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())
	`,
		suite.testProjectID,
		"Device Test Project",
		"Project for device integration tests",
		"Test Application",
		"Test Venue",
		"proposal",
		"indoor",
		50000,
		"USD",
		testutils.DefaultAccountID(),
	)
	require.NoError(suite.T(), err, "Failed to create test project")
}

// setupRouter configures the Gin router with device routes.
func (suite *DeviceIntegrationTestSuite) setupRouter() {
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.ApplicationLoggerMiddleware(suite.Loggers.AppLogger))
	router.Use(testutils.CreateMockUserAuthMiddleware(suite.TestUsers))

	deviceHandler := handler.NewDeviceHandler(suite.mockDeviceSVC)

	api := router.Group("/api/v1")
	devices := api.Group("/devices")
	{
		devices.POST("", deviceHandler.CreateDevice)
		devices.PATCH("/:device_id", deviceHandler.UpdateDevice)
		devices.DELETE("/:device_id/reset", deviceHandler.ResetDevice)
		devices.POST("/:device_id/claim", deviceHandler.ClaimDevice)
		devices.POST("/:device_id/rotate-cert", deviceHandler.RotateCertificate)
	}

	suite.GinRouter = router
}

// createDeviceRequest returns a valid device create request.
func (suite *DeviceIntegrationTestSuite) createDeviceRequest() types.DeviceCreateRequest {
	return types.DeviceCreateRequest{
		DeviceID:        uuid.New().String(),
		DeviceName:      "Test Device",
		ModelName:       "Fusion-Mini",
		FirmwareVersion: "1.0.0",
		SerialNumber:    "SN" + uuid.New().String()[:8],
		MacAddress:      "00:11:22:33:44:55",
		DeviceZone:      "Zone A",
		DeviceLocation:  "Conference Room 1",
		ProjectID:       suite.testProjectID,
		IsPrimary:       true,
		CSR:             "-----BEGIN CERTIFICATE REQUEST-----\nMIIBkTCB+wIBADBSMQswCQYDVQQGEwJVUzELMAkGA1UECAwCTUExDzANBgNVBAcM\nBkJvc3RvbjENMAsGA1UECgwEQm9zZTEWMBQGA1UEAwwNdGVzdC1kZXZpY2UtMTBZ\nMBMGByqGSM49AgEGCCqGSM49AwEHA0IABDummykZ3hhNgOvCdPFxPCp8B9p0hpT8\nfZGhOnAzQi+hVGLHLBPKI9MpHcZKVBaAJz2s8z1Z5E7fzZ+3SzK1qL6gPDAyBgkq\nhkiG9w0BCQ4xJTAjMCEGA1UdEQQaMBiCFnRlc3QtZGV2aWNlLTEuYm9zZS5jb20w\nCgYIKoZIzj0EAwIDSAAwRQIhAJHDKYCZFxlEGJMJNa2ItXq9nHpw8qLhR0XCcOp0\ndmUAAiAmRoZ5iVLPBJGshZ2h8g0fKdE/P5sHvKIvC8qPz7z8Xw==\n-----END CERTIFICATE REQUEST-----",
	}
}

// TestCreateDevice tests the POST /api/v1/devices endpoint.
func (suite *DeviceIntegrationTestSuite) TestCreateDevice() {
	suite.T().Run("should create device successfully", func(t *testing.T) {
		req := suite.createDeviceRequest()
		expectedResponse := &types.DeviceCreateResponse{
			Certificate: "-----BEGIN CERTIFICATE-----\nMIIB...\n-----END CERTIFICATE-----",
		}

		suite.mockDeviceSVC.On("CreateDevice", mock.Anything, mock.MatchedBy(func(r *types.DeviceCreateRequest) bool {
			return r.DeviceID == req.DeviceID && r.DeviceName == req.DeviceName
		}), mock.Anything, mock.Anything).Return(expectedResponse, nil).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.DeviceCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.Certificate)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail with invalid request payload", func(t *testing.T) {
		invalidReq := map[string]string{
			"device_name": "Missing required fields",
		}

		w, err := suite.MakeRequest("POST", "/api/v1/devices", invalidReq)
		require.NoError(t, err)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should fail when project not found", func(t *testing.T) {
		req := suite.createDeviceRequest()
		req.ProjectID = uuid.New().String() // Non-existent project

		suite.mockDeviceSVC.On("CreateDevice", mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.ErrMsgProjectNotFound)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when device already exists", func(t *testing.T) {
		req := suite.createDeviceRequest()

		suite.mockDeviceSVC.On("CreateDevice", mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.ErrMsgDeviceAlreadyExists)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})
}

// TestUpdateDevice tests the PATCH /api/v1/devices/{device_id} endpoint.
func (suite *DeviceIntegrationTestSuite) TestUpdateDevice() {
	deviceID := uuid.New().String()

	suite.T().Run("should update device successfully", func(t *testing.T) {
		updateReq := &types.DeviceUpdateRequest{
			DeviceName:      "Updated Device Name",
			FirmwareVersion: "2.0.0",
			DeviceZone:      "Zone B",
			DeviceLocation:  "Conference Room 2",
		}

		suite.mockDeviceSVC.On("UpdateDevice", mock.Anything, deviceID, mock.MatchedBy(func(r *types.DeviceUpdateRequest) bool {
			return r.DeviceName == updateReq.DeviceName
		}), mock.Anything, mock.Anything).Return(nil).Once()

		w, err := suite.MakeRequest("PATCH", "/api/v1/devices/"+deviceID, updateReq)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail with missing device_id", func(t *testing.T) {
		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Name",
		}

		w, err := suite.MakeRequest("PATCH", "/api/v1/devices/", updateReq)
		require.NoError(t, err)

		// Should match no route
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should fail when device not found", func(t *testing.T) {
		nonExistentID := uuid.New().String()
		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Name",
		}

		suite.mockDeviceSVC.On("UpdateDevice", mock.Anything, nonExistentID, mock.Anything, mock.Anything, mock.Anything).
			Return(errors.New(errorutil.ErrMsgDeviceNotFound)).Once()

		w, err := suite.MakeRequest("PATCH", "/api/v1/devices/"+nonExistentID, updateReq)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when unauthorized", func(t *testing.T) {
		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Name",
		}

		suite.mockDeviceSVC.On("UpdateDevice", mock.Anything, deviceID, mock.Anything, mock.Anything, mock.Anything).
			Return(errors.New(errorutil.MsgUnauthorized)).Once()

		w, err := suite.MakeRequest("PATCH", "/api/v1/devices/"+deviceID, updateReq)
		require.NoError(t, err)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})
}

// TestResetDevice tests the DELETE /api/v1/devices/{device_id}/reset endpoint.
func (suite *DeviceIntegrationTestSuite) TestResetDevice() {
	deviceID := uuid.New().String()

	suite.T().Run("should reset device successfully", func(t *testing.T) {
		suite.mockDeviceSVC.On("ResetDevice", mock.Anything, deviceID, mock.Anything, mock.Anything).
			Return(nil).Once()

		w, err := suite.MakeRequest("DELETE", "/api/v1/devices/"+deviceID+"/reset", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail with missing device_id", func(t *testing.T) {
		w, err := suite.MakeRequest("DELETE", "/api/v1/devices//reset", nil)
		require.NoError(t, err)

		// Should match no route or return bad request
		assert.True(t, w.Code == http.StatusNotFound || w.Code == http.StatusBadRequest)
	})

	suite.T().Run("should fail when device not found", func(t *testing.T) {
		nonExistentID := uuid.New().String()

		suite.mockDeviceSVC.On("ResetDevice", mock.Anything, nonExistentID, mock.Anything, mock.Anything).
			Return(errors.New(errorutil.ErrMsgDeviceNotFound)).Once()

		w, err := suite.MakeRequest("DELETE", "/api/v1/devices/"+nonExistentID+"/reset", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when unauthorized", func(t *testing.T) {
		suite.mockDeviceSVC.On("ResetDevice", mock.Anything, deviceID, mock.Anything, mock.Anything).
			Return(errors.New(errorutil.MsgUnauthorized)).Once()

		w, err := suite.MakeRequest("DELETE", "/api/v1/devices/"+deviceID+"/reset", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})
}

// TestClaimDevice tests the POST /api/v1/devices/{device_id}/claim endpoint.
func (suite *DeviceIntegrationTestSuite) TestClaimDevice() {
	deviceID := uuid.New().String()

	suite.T().Run("should claim device successfully", func(t *testing.T) {
		req := types.DeviceClaimRequest{
			CSR:       "-----BEGIN CERTIFICATE REQUEST-----\nMIIBkTCB+wIBADBSMQswCQYDVQQGEwJVUzELMAkGA1UECAwCTUExDzANBgNVBAcM\nBkJvc3RvbjENMAsGA1UECgwEQm9zZTEWMBQGA1UEAwwNdGVzdC1kZXZpY2UtMTBZ\nMBMGByqGSM49AgEGCCqGSM49AwEHA0IABDummykZ3hhNgOvCdPFxPCp8B9p0hpT8\nfZGhOnAzQi+hVGLHLBPKI9MpHcZKVBaAJz2s8z1Z5E7fzZ+3SzK1qL6gPDAyBgkq\nhkiG9w0BCQ4xJTAjMCEGA1UdEQQaMBiCFnRlc3QtZGV2aWNlLTEuYm9zZS5jb20w\nCgYIKoZIzj0EAwIDSAAwRQIhAJHDKYCZFxlEGJMJNa2ItXq9nHpw8qLhR0XCcOp0\ndmUAAiAmRoZ5iVLPBJGshZ2h8g0fKdE/P5sHvKIvC8qPz7z8Xw==\n-----END CERTIFICATE REQUEST-----",
			ProjectID: suite.testProjectID,
		}
		expectedResponse := &types.DeviceClaimResponse{
			Certificate: "-----BEGIN CERTIFICATE-----\nMIIB...\n-----END CERTIFICATE-----",
		}

		suite.mockDeviceSVC.On("ClaimDevice", mock.Anything, deviceID, mock.MatchedBy(func(r *types.DeviceClaimRequest) bool {
			return r.ProjectID == req.ProjectID
		}), mock.Anything, mock.Anything).Return(expectedResponse, nil).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+deviceID+"/claim", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.DeviceClaimResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.Certificate)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when device not found", func(t *testing.T) {
		req := types.DeviceClaimRequest{
			CSR:       "test-csr",
			ProjectID: suite.testProjectID,
		}

		suite.mockDeviceSVC.On("ClaimDevice", mock.Anything, mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.ErrMsgDeviceNotFound)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+uuid.New().String()+"/claim", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when device already claimed", func(t *testing.T) {
		req := types.DeviceClaimRequest{
			CSR:       "test-csr",
			ProjectID: suite.testProjectID,
		}

		suite.mockDeviceSVC.On("ClaimDevice", mock.Anything, mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.ErrMsgDeviceAlreadyClaimed)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+deviceID+"/claim", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when project not found", func(t *testing.T) {
		req := types.DeviceClaimRequest{
			CSR:       "test-csr",
			ProjectID: uuid.New().String(),
		}

		suite.mockDeviceSVC.On("ClaimDevice", mock.Anything, mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.ErrMsgProjectNotFound)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+deviceID+"/claim", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})
}

// TestRotateCertificate tests the POST /api/v1/devices/{device_id}/rotate-cert endpoint.
func (suite *DeviceIntegrationTestSuite) TestRotateCertificate() {
	deviceID := uuid.New().String()

	suite.T().Run("should rotate certificate successfully", func(t *testing.T) {
		req := types.DeviceRotateCertRequest{
			CSR: "-----BEGIN CERTIFICATE REQUEST-----\nMIIBkTCB+wIBADBSMQswCQYDVQQGEwJVUzELMAkGA1UECAwCTUExDzANBgNVBAcM\nBkJvc3RvbjENMAsGA1UECgwEQm9zZTEWMBQGA1UEAwwNdGVzdC1kZXZpY2UtMTBZ\nMBMGByqGSM49AgEGCCqGSM49AwEHA0IABDummykZ3hhNgOvCdPFxPCp8B9p0hpT8\nfZGhOnAzQi+hVGLHLBPKI9MpHcZKVBaAJz2s8z1Z5E7fzZ+3SzK1qL6gPDAyBgkq\nhkiG9w0BCQ4xJTAjMCEGA1UdEQQaMBiCFnRlc3QtZGV2aWNlLTEuYm9zZS5jb20w\nCgYIKoZIzj0EAwIDSAAwRQIhAJHDKYCZFxlEGJMJNa2ItXq9nHpw8qLhR0XCcOp0\ndmUAAiAmRoZ5iVLPBJGshZ2h8g0fKdE/P5sHvKIvC8qPz7z8Xw==\n-----END CERTIFICATE REQUEST-----",
		}
		expectedResponse := &types.DeviceRotateCertResponse{
			Certificate: "-----BEGIN CERTIFICATE-----\nMIIB...\n-----END CERTIFICATE-----",
		}

		suite.mockDeviceSVC.On("RotateCertificate", mock.Anything, deviceID, mock.MatchedBy(func(r *types.DeviceRotateCertRequest) bool {
			return len(r.CSR) > 0
		}), mock.Anything, mock.Anything).Return(expectedResponse, nil).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+deviceID+"/rotate-cert", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.DeviceRotateCertResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.Certificate)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when device not found", func(t *testing.T) {
		req := types.DeviceRotateCertRequest{
			CSR: "test-csr",
		}

		suite.mockDeviceSVC.On("RotateCertificate", mock.Anything, mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.ErrMsgDeviceNotFound)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+uuid.New().String()+"/rotate-cert", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when device not claimed", func(t *testing.T) {
		req := types.DeviceRotateCertRequest{
			CSR: "test-csr",
		}

		suite.mockDeviceSVC.On("RotateCertificate", mock.Anything, mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.ErrMsgDeviceNotClaimed)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+deviceID+"/rotate-cert", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})

	suite.T().Run("should fail when unauthorized", func(t *testing.T) {
		req := types.DeviceRotateCertRequest{
			CSR: "test-csr",
		}

		suite.mockDeviceSVC.On("RotateCertificate", mock.Anything, mock.Anything, mock.Anything, mock.Anything, mock.Anything).
			Return(nil, errors.New(errorutil.MsgUnauthorized)).Once()

		w, err := suite.MakeRequest("POST", "/api/v1/devices/"+deviceID+"/rotate-cert", req)
		require.NoError(t, err)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		suite.mockDeviceSVC.AssertExpectations(t)
	})
}

// TestDeviceIntegrationSuite runs the complete test suite.
func TestDeviceIntegrationSuite(t *testing.T) {
	suite.Run(t, new(DeviceIntegrationTestSuite))
}
