package device

import (
	"context"
	"database/sql"
	"errors"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/DATA-DOG/go-sqlmock"
	"github.com/aarondl/null/v8"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest"
)

// ---------------------------------------------------------------------------
// Test Constants
// ---------------------------------------------------------------------------

const (
	testDeviceID       = "device-123"
	testAccountID      = "account-123"
	testProjectID      = "project-123"
	testUserID         = "user-123"
	testUserEmail      = "user@example.com"
	testDeviceName     = "Test Device"
	testSerialNumber   = "SN123456"
	testModelName      = "Model-X"
	testFirmwareVer    = "1.0.0"
	testMacAddress     = "00:11:22:33:44:55"
	testDeviceZone     = "Zone-A"
	testDeviceLocation = "Location-1"
	testCSR            = "test-csr-content"
	testCertPem        = "test-certificate-pem"
	testCertID         = "cert-123"
	testCertArn        = "arn:aws:iot:us-east-1:123456789:cert/abc"
	testDeviceUUID     = "uuid-device-123"
	testCommandID      = "cmd-uuid-123"
)

// ---------------------------------------------------------------------------
// Mock Database Service
// ---------------------------------------------------------------------------

type mockDBService struct {
	mock.Mock
}

func (m *mockDBService) GetDB(ctx context.Context) model.DBWithTransactions {
	args := m.Called(ctx)
	return args.Get(0).(model.DBWithTransactions)
}

func (m *mockDBService) GetDeviceByID(ctx context.Context, deviceID string, logger *zap.Logger) (*models.Device, error) {
	args := m.Called(ctx, deviceID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Device), args.Error(1)
}

func (m *mockDBService) Insert(ctx context.Context, req *types.DeviceCreateRequest, accountID string, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, req, accountID, cert, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) ClaimDevice(ctx context.Context, device models.Device, accountID string, cert types.CertificateInfo, req *types.DeviceClaimRequest, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, device, accountID, cert, req, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) Update(ctx context.Context, device models.Device, req *types.DeviceUpdateRequest, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, device, req, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) UpdateCertificate(ctx context.Context, device models.Device, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, device, cert, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) Reset(ctx context.Context, device models.Device, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, device, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) InsertCommand(ctx context.Context, projectID, commandID string, request *types.CommandRequest, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, commandID, request, logger)
	return args.Error(0)
}

func (m *mockDBService) UpdateCommandStatus(ctx context.Context, commandID, status string, logger *zap.Logger) error {
	args := m.Called(ctx, commandID, status, logger)
	return args.Error(0)
}

func (m *mockDBService) GetCommandStatus(ctx context.Context, commandID string, logger *zap.Logger) (*models.DeviceCommandHistorySlice, error) {
	args := m.Called(ctx, commandID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.DeviceCommandHistorySlice), args.Error(1)
}

// ---------------------------------------------------------------------------
// Mock Project Service
// ---------------------------------------------------------------------------

type mockProjectService struct {
	mock.Mock
}

func (m *mockProjectService) GetProjectByID(ctx context.Context, projectID string, logger *zap.Logger) (*models.Project, error) {
	args := m.Called(ctx, projectID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Project), args.Error(1)
}

// ---------------------------------------------------------------------------
// Mock IoT Service
// ---------------------------------------------------------------------------

type mockIoTService struct {
	mock.Mock
}

func (m *mockIoTService) CreateCertificateFromCSR(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error) {
	args := m.Called(ctx, csrPem, logger)
	if args.Get(0) == nil {
		return nil, nil, nil, args.Error(3)
	}
	return args.Get(0).(*string), args.Get(1).(*string), args.Get(2).(*string), args.Error(3)
}

func (m *mockIoTService) RegisterThing(ctx context.Context, thingName string, logger *zap.Logger) error {
	args := m.Called(ctx, thingName, logger)
	return args.Error(0)
}

func (m *mockIoTService) AttachCertificateToThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	args := m.Called(ctx, thingName, certificateArn, logger)
	return args.Error(0)
}

func (m *mockIoTService) AttachPolicyToCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	args := m.Called(ctx, policyName, certificateArn, logger)
	return args.Error(0)
}

func (m *mockIoTService) DetachCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	args := m.Called(ctx, thingName, certificateArn, logger)
	return args.Error(0)
}

func (m *mockIoTService) SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error {
	args := m.Called(ctx, certificateId, logger)
	return args.Error(0)
}

func (m *mockIoTService) DetachPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	args := m.Called(ctx, policyName, certificateArn, logger)
	return args.Error(0)
}

func (m *mockIoTService) DeleteThing(ctx context.Context, thingName string, logger *zap.Logger) error {
	args := m.Called(ctx, thingName, logger)
	return args.Error(0)
}

func (m *mockIoTService) Publish(ctx context.Context, topic string, payload []byte, logger *zap.Logger) error {
	args := m.Called(ctx, topic, payload, logger)
	return args.Error(0)
}

// ---------------------------------------------------------------------------
// Mock DB With Transactions
// ---------------------------------------------------------------------------

type mockDBWithTransactions struct {
	*sql.DB
	sqlMock sqlmock.Sqlmock
}

func newMockDBWithTransactions(t *testing.T) (*mockDBWithTransactions, sqlmock.Sqlmock) {
	db, sqlMock, err := sqlmock.New()
	if err != nil {
		t.Fatalf("Failed to create sqlmock: %v", err)
	}
	return &mockDBWithTransactions{DB: db, sqlMock: sqlMock}, sqlMock
}

// ---------------------------------------------------------------------------
// Test Helpers
// ---------------------------------------------------------------------------

func createTestLogger(t *testing.T) *zap.Logger {
	return zaptest.NewLogger(t)
}

func createTestUserAuth() types.UserAuthorizationResponse {
	return types.UserAuthorizationResponse{
		User: types.UserInfo{
			ID:    testUserID,
			Email: testUserEmail,
		},
		Account: types.AccountInfo{
			ID:   testAccountID,
			Name: "Test Account",
		},
	}
}

func createTestRequest() *types.DeviceCreateRequest {
	return &types.DeviceCreateRequest{
		ClientDeviceID:  testDeviceID,
		DeviceName:      testDeviceName,
		ModelName:       testModelName,
		FirmwareVersion: testFirmwareVer,
		SerialNumber:    testSerialNumber,
		MacAddress:      testMacAddress,
		DeviceZone:      testDeviceZone,
		DeviceLocation:  testDeviceLocation,
		ProjectID:       testProjectID,
		IsPrimary:       true,
		CSR:             testCSR,
	}
}

func createTestProject() *models.Project {
	return &models.Project{
		ID:                    testProjectID,
		Name:                  null.NewString("Test Project", true),
		PrimaryOwnerAccountID: testAccountID,
		CreatedAt:             time.Now(),
		UpdatedAt:             time.Now(),
	}
}

func createUnclaimedDevice() *models.Device {
	return &models.Device{
		ID:             testDeviceUUID,
		ClientDeviceID: null.NewString(testDeviceID, testDeviceID != ""),
		SerialNumber:   testSerialNumber,
		ModelName:      testModelName,
		ClaimStatus:    "UNCLAIMED",
		ClaimedBy:      null.NewString("", false),
		ProjectID:      null.NewString("", false),
		CertificateID:  null.NewString("", false),
		CertificateArn: null.NewString("", false),
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}
}

func createClaimedDevice() *models.Device {
	return &models.Device{
		ID:             testDeviceUUID,
		ClientDeviceID: null.NewString(testDeviceID, testDeviceID != ""),
		SerialNumber:   testSerialNumber,
		ModelName:      testModelName,
		ClaimStatus:    "CLAIMED",
		ClaimedBy:      null.NewString(testAccountID, true),
		ProjectID:      null.NewString(testProjectID, true),
		CertificateID:  null.NewString(testCertID, true),
		CertificateArn: null.NewString(testCertArn, true),
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}
}

// ---------------------------------------------------------------------------
// CreateDevice Tests
// ---------------------------------------------------------------------------

func TestCreateDevice(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully creates new device", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}

		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		// Device doesn't exist
		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		// IoT operations
		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(nil)
		mockIoT.On("AttachCertificateToThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)

		// Transaction expectations
		sqlMock.ExpectBegin()
		mockDB.On("Insert", ctx, req, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit()

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.NoError(t, err)
		assert.NotNil(t, resp)
		assert.Equal(t, certPem, resp.Certificate)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("successfully claims unclaimed device", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		claimReq := &types.DeviceClaimRequest{
			ProjectID:       req.ProjectID,
			DeviceName:      req.DeviceName,
			ClientDeviceID:  req.ClientDeviceID,
			DeviceZone:      req.DeviceZone,
			DeviceLocation:  req.DeviceLocation,
			IsPrimary:       &req.IsPrimary,
			FirmwareVersion: req.FirmwareVersion,
		}
		project := createTestProject()
		device := createUnclaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		// Device exists but is unclaimed
		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(device, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		// IoT operations (no RegisterThing for existing device)
		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)

		// Transaction - ClaimDevice for existing unclaimed device
		sqlMock.ExpectBegin()
		mockDB.On("ClaimDevice", ctx, *device, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, claimReq, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit()

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.NoError(t, err)
		assert.NotNil(t, resp)
		assert.Equal(t, certPem, resp.Certificate)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when device already claimed", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()
		device := createClaimedDevice()

		// Device exists and is already claimed
		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(device, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), errorutil.ErrMsgDeviceAlreadyExists)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(nil, nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), errorutil.ErrMsgProjectNotFound)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when user does not have project access", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		// Project belongs to different account
		project := &models.Project{
			ID:                    testProjectID,
			Name:                  null.NewString("Other Project", true),
			PrimaryOwnerAccountID: "other-account-id",
		}

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), errorutil.MsgUnauthorized)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetDeviceByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, errors.New("database error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetProjectByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(nil, errors.New("database error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when certificate creation fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(nil, nil, nil, errors.New("IoT error"))
		// Cleanup since thing was registered but cert creation failed
		mockIoT.On("DeleteThing", ctx, testSerialNumber, mock.Anything).Return(nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when RegisterThing fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		// RegisterThing is called before CreateCertificateFromCSR when device doesn't exist
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(errors.New("IoT error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when AttachCertificateToThing fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testSerialNumber, certArn, mock.Anything).
			Return(errors.New("IoT error"))
		// Cleanup: SetCertificateInactive and DeleteThing (since thing was registered)
		mockIoT.On("SetCertificateInactive", ctx, certID, mock.Anything).Return(nil)
		mockIoT.On("DeleteThing", ctx, testSerialNumber, mock.Anything).Return(nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when AttachPolicyToCertificate fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).
			Return(errors.New("IoT error"))
		// cleanupIoTResources is called on failure
		mockIoT.On("SetCertificateInactive", ctx, certID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)
		mockIoT.On("DeleteThing", ctx, testSerialNumber, mock.Anything).Return(nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when transaction begin fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)

		// Transaction begin fails
		sqlMock.ExpectBegin().WillReturnError(errors.New("connection error"))

		// cleanupIoTResources is called when transaction fails
		mockIoT.On("SetCertificateInactive", ctx, certID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)
		mockIoT.On("DeleteThing", ctx, testSerialNumber, mock.Anything).Return(nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), "failed to begin transaction")
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error and rolls back when Insert fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).Return(nil)

		sqlMock.ExpectBegin()
		mockDB.On("Insert", ctx, req, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, mock.AnythingOfType("*sql.Tx"), mock.Anything).
			Return(errors.New("insert error"))
		sqlMock.ExpectRollback()

		// cleanupIoTResources is called after transaction fails
		mockIoT.On("SetCertificateInactive", ctx, certID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)
		mockIoT.On("DeleteThing", ctx, testSerialNumber, mock.Anything).Return(nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when commit fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testSerialNumber, mock.Anything).Return(nil, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("RegisterThing", ctx, testSerialNumber, mock.Anything).Return(nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)

		sqlMock.ExpectBegin()
		mockDB.On("Insert", ctx, req, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit().WillReturnError(errors.New("commit error"))

		// cleanupIoTResources is called after commit fails
		mockIoT.On("SetCertificateInactive", ctx, certID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testSerialNumber, certArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, cfg.IoTDevicePolicy, certArn, mock.Anything).Return(nil)
		mockIoT.On("DeleteThing", ctx, testSerialNumber, mock.Anything).Return(nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), "failed to commit transaction")
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})
}

// ---------------------------------------------------------------------------
// UpdateDevice Tests
// ---------------------------------------------------------------------------

func TestUpdateDevice(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully updates device", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin()
		mockDB.On("Update", ctx, *device, updateReq, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit()

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.NoError(t, err)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when device not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, sql.ErrNoRows)

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), errorutil.ErrMsgDeviceNotFound)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetDeviceByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, errors.New("database error"))

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when user is not device owner", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		// Device owned by different account
		device := &models.Device{
			ID:             testDeviceUUID,
			ClientDeviceID: null.NewString(testDeviceID, testDeviceID != ""),
			ClaimStatus:    "CLAIMED",
			ClaimedBy:      null.NewString("other-account-id", true),
		}

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), errorutil.MsgUnauthorized)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when transaction begin fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin().WillReturnError(errors.New("connection error"))

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "failed to begin transaction")
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error and rolls back when Update fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin()
		mockDB.On("Update", ctx, *device, updateReq, mock.AnythingOfType("*sql.Tx"), mock.Anything).
			Return(errors.New("update error"))
		sqlMock.ExpectRollback()

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when commit fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin()
		mockDB.On("Update", ctx, *device, updateReq, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit().WillReturnError(errors.New("commit error"))

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "failed to commit transaction")
		mockDB.AssertExpectations(t)
	})
}

// ---------------------------------------------------------------------------
// ClaimDevice Tests
// ---------------------------------------------------------------------------

func TestClaimDevice(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully claims unclaimed device", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createUnclaimedDevice()
		project := createTestProject()

		req := &types.DeviceClaimRequest{
			CSR:       testCSR,
			ProjectID: testProjectID,
		}

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		// IoT operations
		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).Return(nil)

		mockDB.On("GetDB", ctx).Return(dbWithTx)
		sqlMock.ExpectBegin()
		mockDB.On("ClaimDevice", ctx, *device, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, req, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit()

		resp, err := service.ClaimDevice(ctx, testDeviceID, req, user, logger)

		assert.NoError(t, err)
		assert.NotNil(t, resp)
		assert.Equal(t, certPem, resp.Certificate)
		mockDB.AssertExpectations(t)
		mockProject.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when device not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		req := &types.DeviceClaimRequest{
			CSR:       testCSR,
			ProjectID: testProjectID,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, sql.ErrNoRows)

		resp, err := service.ClaimDevice(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Equal(t, errorutil.ErrMsgDeviceNotFound, err.Error())
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when device already claimed", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		req := &types.DeviceClaimRequest{
			CSR:       testCSR,
			ProjectID: testProjectID,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		resp, err := service.ClaimDevice(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Equal(t, errorutil.ErrMsgDeviceAlreadyClaimed, err.Error())
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createUnclaimedDevice()

		req := &types.DeviceClaimRequest{
			CSR:       testCSR,
			ProjectID: testProjectID,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(nil, nil)

		resp, err := service.ClaimDevice(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Equal(t, errorutil.ErrMsgProjectNotFound, err.Error())
		mockDB.AssertExpectations(t)
		mockProject.AssertExpectations(t)
	})

	t.Run("returns error when user does not have project access", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createUnclaimedDevice()

		// Project belongs to different account
		project := &models.Project{
			ID:                    testProjectID,
			Name:                  null.NewString("Test Project", true),
			PrimaryOwnerAccountID: "different-account",
			CreatedAt:             time.Now(),
			UpdatedAt:             time.Now(),
		}

		req := &types.DeviceClaimRequest{
			CSR:       testCSR,
			ProjectID: testProjectID,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		resp, err := service.ClaimDevice(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Equal(t, errorutil.MsgUnauthorized, err.Error())
		mockDB.AssertExpectations(t)
		mockProject.AssertExpectations(t)
	})

	t.Run("returns error when certificate creation fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createUnclaimedDevice()
		project := createTestProject()

		req := &types.DeviceClaimRequest{
			CSR:       testCSR,
			ProjectID: testProjectID,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockProject.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(nil, nil, nil, errors.New("iot error"))

		resp, err := service.ClaimDevice(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockProject.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})
}

// ---------------------------------------------------------------------------
// RotateCertificate Tests
// ---------------------------------------------------------------------------

func TestRotateCertificate(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully rotates certificate", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSR,
		}

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		// IoT operations - create new cert
		newCertPem := "new-certificate-pem"
		newCertID := "new-cert-id"
		newCertArn := "arn:aws:iot:us-east-1:123456789:cert/new"
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(&newCertPem, &newCertID, &newCertArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, newCertArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", newCertArn, mock.Anything).Return(nil)

		// IoT operations - revoke old cert
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)

		mockDB.On("GetDB", ctx).Return(dbWithTx)
		sqlMock.ExpectBegin()
		mockDB.On("UpdateCertificate", ctx, *device, types.CertificateInfo{ID: newCertID, Arn: newCertArn}, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit()

		resp, err := service.RotateCertificate(ctx, testDeviceID, req, user, logger)

		assert.NoError(t, err)
		assert.NotNil(t, resp)
		assert.Equal(t, newCertPem, resp.Certificate)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when device not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSR,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, sql.ErrNoRows)

		resp, err := service.RotateCertificate(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Equal(t, errorutil.ErrMsgDeviceNotFound, err.Error())
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when device not claimed", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createUnclaimedDevice()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSR,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		resp, err := service.RotateCertificate(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Equal(t, errorutil.ErrMsgDeviceNotClaimed, err.Error())
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when user is not device owner", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		// Device owned by different account
		device := &models.Device{
			ID:             testDeviceUUID,
			ClientDeviceID: null.NewString(testDeviceID, testDeviceID != ""),
			SerialNumber:   testSerialNumber,
			ModelName:      testModelName,
			ClaimStatus:    "CLAIMED",
			ClaimedBy:      null.NewString("different-account", true),
			ProjectID:      null.NewString(testProjectID, true),
			CertificateID:  null.NewString(testCertID, true),
			CertificateArn: null.NewString(testCertArn, true),
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		}

		req := &types.DeviceRotateCertRequest{
			CSR: testCSR,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		resp, err := service.RotateCertificate(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Equal(t, errorutil.MsgUnauthorized, err.Error())
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when certificate creation fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		req := &types.DeviceRotateCertRequest{
			CSR: testCSR,
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("CreateCertificateFromCSR", ctx, &req.CSR, mock.Anything).
			Return(nil, nil, nil, errors.New("iot error"))

		resp, err := service.RotateCertificate(ctx, testDeviceID, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})
}

// ---------------------------------------------------------------------------
// ResetDevice Tests
// ---------------------------------------------------------------------------

func TestResetDevice(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully resets device", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		// IoT revocation operations
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)

		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin()
		mockDB.On("Reset", ctx, *device, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit()

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.NoError(t, err)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns nil when device is not claimed", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createUnclaimedDevice()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.NoError(t, err)
		mockDB.AssertExpectations(t)
		// IoT operations should not be called for unclaimed devices
		mockIoT.AssertNotCalled(t, "SetCertificateInactive")
	})

	t.Run("returns error when device not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, sql.ErrNoRows)

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), errorutil.ErrMsgDeviceNotFound)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetDeviceByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, errors.New("database error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when SetCertificateInactive fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(errors.New("IoT error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when DetachCertificateFromThing fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).
			Return(errors.New("IoT error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when DetachPolicyFromCertificate fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).
			Return(errors.New("IoT error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when transaction begin fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin().WillReturnError(errors.New("connection error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "failed to begin transaction")
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error and rolls back when Reset fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin()
		mockDB.On("Reset", ctx, *device, mock.AnythingOfType("*sql.Tx"), mock.Anything).
			Return(errors.New("reset error"))
		sqlMock.ExpectRollback()

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when commit fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{}
		cfg.IoTDevicePolicy = "testdevicepolicy"
		service := NewService(mockDB, mockProject, mockIoT, cfg)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetachCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetachPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		sqlMock.ExpectBegin()
		mockDB.On("Reset", ctx, *device, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit().WillReturnError(errors.New("commit error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "failed to commit transaction")
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})
}

// ---------------------------------------------------------------------------
// NewService Tests
// ---------------------------------------------------------------------------

func TestNewService(t *testing.T) {
	t.Run("creates service with dependencies", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		cfg := config.CloudConfig{
			Region:          "us-east-1",
			IoTEndpoint:     "test-endpoint.iot.us-east-1.amazonaws.com",
			IoTCommandTopic: "cluster/%s/command",
		}

		service := NewService(mockDB, mockProject, mockIoT, cfg)

		assert.NotNil(t, service)
		assert.Equal(t, mockDB, service.dbService)
		assert.Equal(t, mockProject, service.projectService)
		assert.Equal(t, mockIoT, service.iotService)
	})
}

// ---------------------------------------------------------------------------
// Command Tests
// ---------------------------------------------------------------------------

func TestCommand(t *testing.T) {
	ctx := context.Background()

	createTestConfig := func() config.CloudConfig {
		return config.CloudConfig{
			Region:          "us-east-1",
			IoTEndpoint:     "test-endpoint.iot.us-east-1.amazonaws.com",
			IoTCommandTopic: "cluster/{project_id}/command",
			IoTDevicePolicy: "testdevicepolicy",
		}
	}

	t.Run("successfully sends command", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)
		user := createTestUserAuth()

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
			DeviceIDs: []string{testDeviceID},
		}

		mockProject.On("GetProjectByID", ctx, testProjectID, mock.AnythingOfType("*zap.Logger")).
			Return(createTestProject(), nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)
		sqlMock.ExpectBegin()
		mockDB.On("InsertCommand", ctx, testProjectID, mock.AnythingOfType("string"), req, mock.AnythingOfType("*zap.Logger")).
			Return(nil)
		sqlMock.ExpectCommit()
		mockIoT.On("Publish", ctx, "cluster/{project_id}/command", mock.Anything, mock.AnythingOfType("*zap.Logger")).
			Return(nil)
		mockDB.On("UpdateCommandStatus", ctx, mock.AnythingOfType("string"), "PUBLISHED", mock.AnythingOfType("*zap.Logger")).
			Return(nil)

		commandID, err := service.Command(ctx, req, user, logger)
		assert.NoError(t, err)
		assert.NotEmpty(t, commandID) // UUID is generated internally
		mockProject.AssertExpectations(t)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)
		user := createTestUserAuth()

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
		}

		mockProject.On("GetProjectByID", ctx, testProjectID, mock.AnythingOfType("*zap.Logger")).
			Return(nil, nil)

		commandID, err := service.Command(ctx, req, user, logger)
		assert.Error(t, err)
		assert.Empty(t, commandID)
		assert.Contains(t, err.Error(), errorutil.ErrMsgProjectNotFound)
		mockProject.AssertExpectations(t)
	})

	t.Run("returns error when user unauthorized for project", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)
		user := createTestUserAuth()
		user.Account.ID = "different-account"

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
		}

		mockProject.On("GetProjectByID", ctx, testProjectID, mock.AnythingOfType("*zap.Logger")).
			Return(createTestProject(), nil)

		commandID, err := service.Command(ctx, req, user, logger)
		assert.Error(t, err)
		assert.Empty(t, commandID)
		assert.Contains(t, err.Error(), errorutil.MsgUnauthorized)
		mockProject.AssertExpectations(t)
	})

	t.Run("returns error when db insert fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)
		user := createTestUserAuth()

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
		}

		mockProject.On("GetProjectByID", ctx, testProjectID, mock.AnythingOfType("*zap.Logger")).
			Return(createTestProject(), nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)
		sqlMock.ExpectBegin()
		mockDB.On("InsertCommand", ctx, testProjectID, mock.AnythingOfType("string"), req, mock.AnythingOfType("*zap.Logger")).
			Return(errors.New("database error"))
		sqlMock.ExpectRollback()

		commandID, err := service.Command(ctx, req, user, logger)
		assert.Error(t, err)
		assert.Empty(t, commandID)
		mockProject.AssertExpectations(t)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when publish fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)
		user := createTestUserAuth()

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
		}

		mockProject.On("GetProjectByID", ctx, testProjectID, mock.AnythingOfType("*zap.Logger")).
			Return(createTestProject(), nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)
		sqlMock.ExpectBegin()
		mockDB.On("InsertCommand", ctx, testProjectID, mock.AnythingOfType("string"), req, mock.AnythingOfType("*zap.Logger")).
			Return(nil)
		sqlMock.ExpectCommit()
		mockIoT.On("Publish", ctx, "cluster/{project_id}/command", mock.Anything, mock.AnythingOfType("*zap.Logger")).
			Return(errors.New("publish error"))

		commandID, err := service.Command(ctx, req, user, logger)
		assert.Error(t, err)
		assert.Empty(t, commandID)
		mockProject.AssertExpectations(t)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})
}

// ---------------------------------------------------------------------------
// GetCommandStatus Tests
// ---------------------------------------------------------------------------

func TestGetCommandStatus(t *testing.T) {
	ctx := context.Background()

	createTestConfig := func() config.CloudConfig {
		return config.CloudConfig{
			Region:          "us-east-1",
			IoTEndpoint:     "test-endpoint.iot.us-east-1.amazonaws.com",
			IoTCommandTopic: "cluster/%s/command",
		}
	}

	t.Run("successfully retrieves command status", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		issuedAt := time.Now()
		commands := models.DeviceCommandHistorySlice{
			&models.DeviceCommandHistory{
				ID:          "db-generated-id",
				CommandID:   testCommandID,
				ProjectID:   testProjectID,
				DeviceID:    null.NewString(testDeviceID, testDeviceID != ""),
				CommandName: "REBOOT",
				Status:      "COMPLETED",
				IssuedAt:    issuedAt,
				UpdatedAt:   issuedAt,
			},
		}

		mockDB.On("GetCommandStatus", ctx, testCommandID, mock.AnythingOfType("*zap.Logger")).
			Return(&commands, nil)

		result, err := service.GetCommandStatus(ctx, testCommandID, logger)
		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, testCommandID, result.Results[0].CommandID)
		assert.Equal(t, "REBOOT", result.Results[0].CommandName)
		assert.Equal(t, "COMPLETED", result.Results[0].Status)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when command not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		mockDB.On("GetCommandStatus", ctx, testCommandID, mock.AnythingOfType("*zap.Logger")).
			Return(nil, nil)

		result, err := service.GetCommandStatus(ctx, testCommandID, logger)
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Contains(t, err.Error(), errorutil.ErrMsgCommandNotFound)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error on database error", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockProject := new(mockProjectService)
		mockIoT := new(mockIoTService)
		logger := zaptest.NewLogger(t)

		service := NewService(mockDB, mockProject, mockIoT, createTestConfig())

		mockDB.On("GetCommandStatus", ctx, testCommandID, mock.AnythingOfType("*zap.Logger")).
			Return(nil, errors.New("database error"))

		result, err := service.GetCommandStatus(ctx, testCommandID, logger)
		assert.Error(t, err)
		assert.Nil(t, result)
		mockDB.AssertExpectations(t)
	})
}
