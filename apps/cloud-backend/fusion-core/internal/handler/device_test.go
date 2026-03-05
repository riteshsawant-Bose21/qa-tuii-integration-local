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
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

// ---------------------------------------------------------------------------
// Test Constants
// ---------------------------------------------------------------------------

const (
	devicesEndpoint         = "/devices"
	deviceIDParam           = "device_id"
	testDeviceIDConst       = "device-123"
	testDeviceNameConst     = "Test Device"
	testProjectIDConst      = "project-123"
	testAccountIDConst      = "account-123"
	testUserIDConst         = "user-123"
	testUserEmailConst      = "user@example.com"
	testCertPemConst        = "test-certificate-pem"
	testCSRConst            = "test-csr-content"
	testSerialNumberConst   = "SN123456"
	testModelNameConst      = "Model-X"
	testFirmwareVerConst    = "1.0.0"
	testMacAddressConst     = "00:11:22:33:44:55"
	testDeviceZoneConst     = "Zone-A"
	testDeviceLocationConst = "Location-1"
)

// ---------------------------------------------------------------------------
// Mock Device Service
// ---------------------------------------------------------------------------

type MockDeviceService struct {
	mock.Mock
}

func (m *MockDeviceService) CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error) {
	args := m.Called(ctx, request, user, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DeviceCreateResponse), args.Error(1)
}

func (m *MockDeviceService) UpdateDevice(ctx context.Context, deviceID string, request *types.DeviceUpdateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, deviceID, request, user, logger)
	return args.Error(0)
}

func (m *MockDeviceService) ResetDevice(ctx context.Context, deviceID string, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, deviceID, user, logger)
	return args.Error(0)
}

func (m *MockDeviceService) ClaimDevice(ctx context.Context, deviceID string, request *types.DeviceClaimRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceClaimResponse, error) {
	args := m.Called(ctx, deviceID, request, user, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DeviceClaimResponse), args.Error(1)
}

func (m *MockDeviceService) RotateCertificate(ctx context.Context, deviceID string, request *types.DeviceRotateCertRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceRotateCertResponse, error) {
	args := m.Called(ctx, deviceID, request, user, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.DeviceRotateCertResponse), args.Error(1)
}

func (m *MockDeviceService) Command(ctx context.Context, projectID string, request *types.CommandRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (string, error) {
	args := m.Called(ctx, projectID, request, user, logger)
	return args.String(0), args.Error(1)
}

func (m *MockDeviceService) GetCommandStatus(ctx context.Context, commandID string, logger *zap.Logger) (*types.CommandStatusResponse, error) {
	args := m.Called(ctx, commandID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.CommandStatusResponse), args.Error(1)
}

// ---------------------------------------------------------------------------
// Test Setup Helpers
// ---------------------------------------------------------------------------

func setupDeviceTest() (*gin.Engine, *MockDeviceService) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	mockSvc := new(MockDeviceService)
	handler := NewDeviceHandler(mockSvc)

	// Inject authenticated user and logger into context for all test requests
	r.Use(func(c *gin.Context) {
		logger, _ := zap.NewProduction()
		c.Set("user_auth", &types.UserAuthorizationResponse{
			User:    types.UserInfo{ID: testUserIDConst, Email: testUserEmailConst},
			Account: types.AccountInfo{ID: testAccountIDConst, Name: "Test Account"},
		})
		c.Set("logger", logger)
		c.Next()
	})

	r.POST(devicesEndpoint, handler.CreateDevice)
	r.PATCH(devicesEndpoint+"/:device_id", handler.UpdateDevice)
	r.DELETE(devicesEndpoint+"/:device_id/reset", handler.ResetDevice)
	r.POST(devicesEndpoint+"/:device_id/claim", handler.ClaimDevice)
	r.POST(devicesEndpoint+"/:device_id/rotate-cert", handler.RotateCertificate)

	return r, mockSvc
}

func setupDeviceTestWithoutLogger() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	mockSvc := new(MockDeviceService)
	handler := NewDeviceHandler(mockSvc)

	// No logger in context
	r.Use(func(c *gin.Context) {
		c.Set("user_auth", &types.UserAuthorizationResponse{
			User:    types.UserInfo{ID: testUserIDConst, Email: testUserEmailConst},
			Account: types.AccountInfo{ID: testAccountIDConst, Name: "Test Account"},
		})
		c.Next()
	})

	r.POST(devicesEndpoint, handler.CreateDevice)
	r.PATCH(devicesEndpoint+"/:device_id", handler.UpdateDevice)
	r.DELETE(devicesEndpoint+"/:device_id/reset", handler.ResetDevice)
	r.POST(devicesEndpoint+"/:device_id/claim", handler.ClaimDevice)
	r.POST(devicesEndpoint+"/:device_id/rotate-cert", handler.RotateCertificate)

	return r
}

func setupDeviceTestWithoutUserAuth() *gin.Engine {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	mockSvc := new(MockDeviceService)
	handler := NewDeviceHandler(mockSvc)

	// Logger but no user auth in context
	r.Use(func(c *gin.Context) {
		logger, _ := zap.NewProduction()
		c.Set("logger", logger)
		c.Next()
	})

	r.POST(devicesEndpoint, handler.CreateDevice)
	r.PATCH(devicesEndpoint+"/:device_id", handler.UpdateDevice)
	r.DELETE(devicesEndpoint+"/:device_id/reset", handler.ResetDevice)
	r.POST(devicesEndpoint+"/:device_id/claim", handler.ClaimDevice)
	r.POST(devicesEndpoint+"/:device_id/rotate-cert", handler.RotateCertificate)

	return r
}

func createDeviceRequest() *types.DeviceCreateRequest {
	return &types.DeviceCreateRequest{
		DeviceID:        testDeviceIDConst,
		DeviceName:      testDeviceNameConst,
		ModelName:       testModelNameConst,
		FirmwareVersion: testFirmwareVerConst,
		SerialNumber:    testSerialNumberConst,
		MacAddress:      testMacAddressConst,
		DeviceZone:      testDeviceZoneConst,
		DeviceLocation:  testDeviceLocationConst,
		ProjectID:       testProjectIDConst,
		IsPrimary:       true,
		CSR:             testCSRConst,
	}
}

// ---------------------------------------------------------------------------
// NewDeviceHandler Tests
// ---------------------------------------------------------------------------

func TestNewDeviceHandler(t *testing.T) {
	t.Run("creates handler with service", func(t *testing.T) {
		mockSvc := new(MockDeviceService)
		handler := NewDeviceHandler(mockSvc)

		assert.NotNil(t, handler)
		assert.Equal(t, mockSvc, handler.device)
	})
}

// ---------------------------------------------------------------------------
// CreateDevice Tests
// ---------------------------------------------------------------------------

func TestCreateDevice(t *testing.T) {
	t.Run("successfully creates device", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := createDeviceRequest()
		expectedResponse := &types.DeviceCreateResponse{
			Certificate: testCertPemConst,
		}

		mockSvc.On("CreateDevice", mock.Anything, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(expectedResponse, nil)

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.DeviceCreateResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, testCertPemConst, response.Certificate)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request on invalid JSON", func(t *testing.T) {
		r, _ := setupDeviceTest()

		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBufferString("invalid json"))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns bad request when CSR missing", func(t *testing.T) {
		r, _ := setupDeviceTest()

		req := &types.DeviceCreateRequest{
			DeviceID:   testDeviceIDConst,
			DeviceName: testDeviceNameConst,
			// CSR is required but missing
		}

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns not found when project not found", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := createDeviceRequest()
		mockSvc.On("CreateDevice", mock.Anything, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.ErrMsgProjectNotFound))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request when device already exists", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := createDeviceRequest()
		mockSvc.On("CreateDevice", mock.Anything, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.ErrMsgDeviceAlreadyExists))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user unauthorized", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := createDeviceRequest()
		mockSvc.On("CreateDevice", mock.Anything, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.MsgUnauthorized))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error on service failure", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := createDeviceRequest()
		mockSvc.On("CreateDevice", mock.Anything, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New("unexpected error"))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error when logger missing", func(t *testing.T) {
		r := setupDeviceTestWithoutLogger()

		req := createDeviceRequest()
		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
	})

	t.Run("returns unauthorized when user auth missing", func(t *testing.T) {
		r := setupDeviceTestWithoutUserAuth()

		req := createDeviceRequest()
		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ---------------------------------------------------------------------------
// UpdateDevice Tests
// ---------------------------------------------------------------------------

func TestUpdateDevice(t *testing.T) {
	t.Run("successfully updates device", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockSvc.On("UpdateDevice", mock.Anything, testDeviceIDConst, updateReq, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil)

		body, _ := json.Marshal(updateReq)
		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request on invalid JSON", func(t *testing.T) {
		r, _ := setupDeviceTest()

		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBufferString("invalid json"))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns not found when device not found", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockSvc.On("UpdateDevice", mock.Anything, testDeviceIDConst, updateReq, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(errors.New(errorutil.ErrMsgDeviceNotFound))

		body, _ := json.Marshal(updateReq)
		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project not found", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		updateReq := &types.DeviceUpdateRequest{
			ProjectID: "new-project-id",
		}

		mockSvc.On("UpdateDevice", mock.Anything, testDeviceIDConst, updateReq, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(errors.New(errorutil.ErrMsgProjectNotFound))

		body, _ := json.Marshal(updateReq)
		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user unauthorized", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockSvc.On("UpdateDevice", mock.Anything, testDeviceIDConst, updateReq, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(errors.New(errorutil.MsgUnauthorized))

		body, _ := json.Marshal(updateReq)
		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error on service failure", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockSvc.On("UpdateDevice", mock.Anything, testDeviceIDConst, updateReq, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(errors.New("unexpected error"))

		body, _ := json.Marshal(updateReq)
		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error when logger missing", func(t *testing.T) {
		r := setupDeviceTestWithoutLogger()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}
		body, _ := json.Marshal(updateReq)
		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
	})

	t.Run("returns unauthorized when user auth missing", func(t *testing.T) {
		r := setupDeviceTestWithoutUserAuth()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}
		body, _ := json.Marshal(updateReq)
		httpReq := httptest.NewRequest(http.MethodPatch, devicesEndpoint+"/"+testDeviceIDConst, bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ---------------------------------------------------------------------------
// ResetDevice Tests
// ---------------------------------------------------------------------------

func TestResetDevice(t *testing.T) {
	t.Run("successfully resets device", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		mockSvc.On("ResetDevice", mock.Anything, testDeviceIDConst, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil)

		httpReq := httptest.NewRequest(http.MethodDelete, devicesEndpoint+"/"+testDeviceIDConst+"/reset", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when device not found", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		mockSvc.On("ResetDevice", mock.Anything, testDeviceIDConst, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(errors.New(errorutil.ErrMsgDeviceNotFound))

		httpReq := httptest.NewRequest(http.MethodDelete, devicesEndpoint+"/"+testDeviceIDConst+"/reset", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user unauthorized", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		mockSvc.On("ResetDevice", mock.Anything, testDeviceIDConst, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(errors.New(errorutil.MsgUnauthorized))

		httpReq := httptest.NewRequest(http.MethodDelete, devicesEndpoint+"/"+testDeviceIDConst+"/reset", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error on service failure", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		mockSvc.On("ResetDevice", mock.Anything, testDeviceIDConst, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(errors.New("unexpected error"))

		httpReq := httptest.NewRequest(http.MethodDelete, devicesEndpoint+"/"+testDeviceIDConst+"/reset", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error when logger missing", func(t *testing.T) {
		r := setupDeviceTestWithoutLogger()

		httpReq := httptest.NewRequest(http.MethodDelete, devicesEndpoint+"/"+testDeviceIDConst+"/reset", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
	})

	t.Run("returns unauthorized when user auth missing", func(t *testing.T) {
		r := setupDeviceTestWithoutUserAuth()

		httpReq := httptest.NewRequest(http.MethodDelete, devicesEndpoint+"/"+testDeviceIDConst+"/reset", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ---------------------------------------------------------------------------
// ClaimDevice Tests
// ---------------------------------------------------------------------------

func TestClaimDevice(t *testing.T) {
	t.Run("successfully claims device", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceClaimRequest{
			CSR:       testCSRConst,
			ProjectID: testProjectIDConst,
		}
		expectedResponse := &types.DeviceClaimResponse{
			Certificate: testCertPemConst,
		}

		mockSvc.On("ClaimDevice", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(expectedResponse, nil)

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.DeviceClaimResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, testCertPemConst, response.Certificate)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request on invalid JSON", func(t *testing.T) {
		r, _ := setupDeviceTest()

		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBufferString("invalid json"))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns bad request when CSR missing", func(t *testing.T) {
		r, _ := setupDeviceTest()

		req := &types.DeviceClaimRequest{
			ProjectID: testProjectIDConst,
			// CSR is required but missing
		}

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns not found when device not found", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceClaimRequest{
			CSR:       testCSRConst,
			ProjectID: testProjectIDConst,
		}

		mockSvc.On("ClaimDevice", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.ErrMsgDeviceNotFound))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request when device already claimed", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceClaimRequest{
			CSR:       testCSRConst,
			ProjectID: testProjectIDConst,
		}

		mockSvc.On("ClaimDevice", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.ErrMsgDeviceAlreadyClaimed))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project not found", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceClaimRequest{
			CSR:       testCSRConst,
			ProjectID: testProjectIDConst,
		}

		mockSvc.On("ClaimDevice", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.ErrMsgProjectNotFound))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error on service failure", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceClaimRequest{
			CSR:       testCSRConst,
			ProjectID: testProjectIDConst,
		}

		mockSvc.On("ClaimDevice", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New("unexpected error"))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error when logger missing", func(t *testing.T) {
		r := setupDeviceTestWithoutLogger()

		req := &types.DeviceClaimRequest{
			CSR:       testCSRConst,
			ProjectID: testProjectIDConst,
		}
		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
	})

	t.Run("returns unauthorized when user auth missing", func(t *testing.T) {
		r := setupDeviceTestWithoutUserAuth()

		req := &types.DeviceClaimRequest{
			CSR:       testCSRConst,
			ProjectID: testProjectIDConst,
		}
		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/claim", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ---------------------------------------------------------------------------
// RotateCertificate Tests
// ---------------------------------------------------------------------------

func TestRotateCertificate(t *testing.T) {
	t.Run("successfully rotates certificate", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSRConst,
		}
		expectedResponse := &types.DeviceRotateCertResponse{
			Certificate: testCertPemConst,
		}

		mockSvc.On("RotateCertificate", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(expectedResponse, nil)

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.DeviceRotateCertResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)
		assert.Equal(t, testCertPemConst, response.Certificate)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request on invalid JSON", func(t *testing.T) {
		r, _ := setupDeviceTest()

		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBufferString("invalid json"))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns bad request when CSR missing", func(t *testing.T) {
		r, _ := setupDeviceTest()

		req := &types.DeviceRotateCertRequest{
			// CSR is required but missing
		}

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns not found when device not found", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSRConst,
		}

		mockSvc.On("RotateCertificate", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.ErrMsgDeviceNotFound))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request when device not claimed", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSRConst,
		}

		mockSvc.On("RotateCertificate", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.ErrMsgDeviceNotClaimed))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user unauthorized", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSRConst,
		}

		mockSvc.On("RotateCertificate", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New(errorutil.MsgUnauthorized))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error on service failure", func(t *testing.T) {
		r, mockSvc := setupDeviceTest()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSRConst,
		}

		mockSvc.On("RotateCertificate", mock.Anything, testDeviceIDConst, req, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New("unexpected error"))

		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal error when logger missing", func(t *testing.T) {
		r := setupDeviceTestWithoutLogger()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSRConst,
		}
		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
	})

	t.Run("returns unauthorized when user auth missing", func(t *testing.T) {
		r := setupDeviceTestWithoutUserAuth()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSRConst,
		}
		body, _ := json.Marshal(req)
		httpReq := httptest.NewRequest(http.MethodPost, devicesEndpoint+"/"+testDeviceIDConst+"/rotate-cert", bytes.NewBuffer(body))
		httpReq.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, httpReq)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// ---------------------------------------------------------------------------
// handleDeviceError Tests
// ---------------------------------------------------------------------------

func TestHandleDeviceError(t *testing.T) {
	gin.SetMode(gin.TestMode)

	testCases := []struct {
		name           string
		errorMessage   string
		expectedStatus int
	}{
		{
			name:           "device not found returns 404",
			errorMessage:   errorutil.ErrMsgDeviceNotFound,
			expectedStatus: http.StatusNotFound,
		},
		{
			name:           "project not found returns 404",
			errorMessage:   errorutil.ErrMsgProjectNotFound,
			expectedStatus: http.StatusNotFound,
		},
		{
			name:           "unauthorized returns 401",
			errorMessage:   errorutil.MsgUnauthorized,
			expectedStatus: http.StatusUnauthorized,
		},
		{
			name:           "device already exists returns 400",
			errorMessage:   errorutil.ErrMsgDeviceAlreadyExists,
			expectedStatus: http.StatusBadRequest,
		},
		{
			name:           "unknown error returns 500",
			errorMessage:   "some unexpected error",
			expectedStatus: http.StatusInternalServerError,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			w := httptest.NewRecorder()
			c, _ := gin.CreateTestContext(w)

			handler := NewDeviceHandler(new(MockDeviceService))
			logger, _ := zap.NewProduction()

			handler.handleDeviceError(c, errors.New(tc.errorMessage), logger, "test")

			assert.Equal(t, tc.expectedStatus, w.Code)
		})
	}
}

// ---------------------------------------------------------------------------
// getLoggerAndUser Tests
// ---------------------------------------------------------------------------

func TestGetLoggerAndUser(t *testing.T) {
	gin.SetMode(gin.TestMode)

	t.Run("returns logger and user when both exist", func(t *testing.T) {
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)

		logger, _ := zap.NewProduction()
		user := &types.UserAuthorizationResponse{
			User: types.UserInfo{ID: testUserIDConst, Email: testUserEmailConst},
		}
		c.Set("logger", logger)
		c.Set("user_auth", user)

		handler := NewDeviceHandler(new(MockDeviceService))
		resultLogger, resultUser, ok := handler.getLoggerAndUser(c)

		assert.True(t, ok)
		assert.NotNil(t, resultLogger)
		assert.NotNil(t, resultUser)
	})

	t.Run("returns false when logger missing", func(t *testing.T) {
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)

		user := &types.UserAuthorizationResponse{
			User: types.UserInfo{ID: testUserIDConst, Email: testUserEmailConst},
		}
		c.Set("user_auth", user)

		handler := NewDeviceHandler(new(MockDeviceService))
		resultLogger, resultUser, ok := handler.getLoggerAndUser(c)

		assert.False(t, ok)
		assert.Nil(t, resultLogger)
		assert.Nil(t, resultUser)
		assert.Equal(t, http.StatusInternalServerError, w.Code)
	})

	t.Run("returns false when user auth missing", func(t *testing.T) {
		w := httptest.NewRecorder()
		c, _ := gin.CreateTestContext(w)

		logger, _ := zap.NewProduction()
		c.Set("logger", logger)

		handler := NewDeviceHandler(new(MockDeviceService))
		resultLogger, resultUser, ok := handler.getLoggerAndUser(c)

		assert.False(t, ok)
		assert.Nil(t, resultLogger)
		assert.Nil(t, resultUser)
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}
