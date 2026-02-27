package device

import (
	"context"
	"database/sql"
	"errors"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
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

func (m *mockDBService) GetProjectByID(ctx context.Context, projectID string, logger *zap.Logger) (*models.Project, error) {
	args := m.Called(ctx, projectID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Project), args.Error(1)
}

func (m *mockDBService) Insert(ctx context.Context, req *types.DeviceCreateRequest, accountID string, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, req, accountID, cert, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) ClaimDevice(ctx context.Context, device models.Device, accountID string, cert types.CertificateInfo, req *types.DeviceCreateRequest, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, device, accountID, cert, req, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) Update(ctx context.Context, device models.Device, req *types.DeviceUpdateRequest, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, device, req, tx, logger)
	return args.Error(0)
}

func (m *mockDBService) Reset(ctx context.Context, device models.Device, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, device, tx, logger)
	return args.Error(0)
}

// ---------------------------------------------------------------------------
// Mock IoT Service
// ---------------------------------------------------------------------------

type mockIoTService struct {
	mock.Mock
}

func (m *mockIoTService) CreateCertificateFromCsr(ctx context.Context, csrPem *string, logger *zap.Logger) (certificatePem *string, certificateId *string, certificateArn *string, err error) {
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

func (m *mockIoTService) DetatchCertificateFromThing(ctx context.Context, thingName string, certificateArn string, logger *zap.Logger) error {
	args := m.Called(ctx, thingName, certificateArn, logger)
	return args.Error(0)
}

func (m *mockIoTService) SetCertificateInactive(ctx context.Context, certificateId string, logger *zap.Logger) error {
	args := m.Called(ctx, certificateId, logger)
	return args.Error(0)
}

func (m *mockIoTService) DetatchPolicyFromCertificate(ctx context.Context, policyName string, certificateArn string, logger *zap.Logger) error {
	args := m.Called(ctx, policyName, certificateArn, logger)
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
		DeviceID:        testDeviceID,
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
		DeviceID:       testDeviceID,
		SerialNumber:   testSerialNumber,
		ModelName:      testModelName,
		ThingName:      testDeviceID,
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
		DeviceID:       testDeviceID,
		SerialNumber:   testSerialNumber,
		ModelName:      testModelName,
		ThingName:      testDeviceID,
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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		// Device doesn't exist
		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		// IoT operations
		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testDeviceID, mock.Anything).Return(nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).Return(nil)

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()
		device := createUnclaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		// Device exists but is unclaimed
		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		// IoT operations (no RegisterThing for existing device)
		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).Return(nil)

		// Transaction - ClaimDevice for existing unclaimed device
		sqlMock.ExpectBegin()
		mockDB.On("ClaimDevice", ctx, *device, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, req, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()
		device := createClaimedDevice()

		// Device exists and is already claimed
		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), errorutil.ErrMsgDeviceAlreadyExists)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(nil, nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), errorutil.ErrMsgProjectNotFound)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when user does not have project access", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		// Project belongs to different account
		project := &models.Project{
			ID:                    testProjectID,
			Name:                  null.NewString("Other Project", true),
			PrimaryOwnerAccountID: "other-account-id",
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), errorutil.MsgUnauthorized)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetDeviceByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, errors.New("database error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetProjectByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(nil, errors.New("database error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when certificate creation fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(nil, nil, nil, errors.New("IoT error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when RegisterThing fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testDeviceID, mock.Anything).Return(errors.New("IoT error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when AttachCertificateToThing fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testDeviceID, mock.Anything).Return(nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).
			Return(errors.New("IoT error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when AttachPolicyToCertificate fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testDeviceID, mock.Anything).Return(nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).
			Return(errors.New("IoT error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when transaction begin fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testDeviceID, mock.Anything).Return(nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).Return(nil)

		// Transaction begin fails
		sqlMock.ExpectBegin().WillReturnError(errors.New("connection error"))

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		assert.Contains(t, err.Error(), "failed to begin transaction")
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error and rolls back when Insert fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testDeviceID, mock.Anything).Return(nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).Return(nil)

		sqlMock.ExpectBegin()
		mockDB.On("Insert", ctx, req, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, mock.AnythingOfType("*sql.Tx"), mock.Anything).
			Return(errors.New("insert error"))
		sqlMock.ExpectRollback()

		resp, err := service.CreateDevice(ctx, req, user, logger)

		assert.Error(t, err)
		assert.Nil(t, resp)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when commit fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		req := createTestRequest()
		project := createTestProject()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)
		mockDB.On("GetProjectByID", ctx, testProjectID, mock.Anything).Return(project, nil)
		mockDB.On("GetDB", ctx).Return(dbWithTx)

		certPem := testCertPem
		certID := testCertID
		certArn := testCertArn
		mockIoT.On("CreateCertificateFromCsr", ctx, &req.CSR, mock.Anything).
			Return(&certPem, &certID, &certArn, nil)
		mockIoT.On("RegisterThing", ctx, testDeviceID, mock.Anything).Return(nil)
		mockIoT.On("AttachCertificateToThing", ctx, testDeviceID, certArn, mock.Anything).Return(nil)
		mockIoT.On("AttachPolicyToCertificate", ctx, "testdevicepolicy", certArn, mock.Anything).Return(nil)

		sqlMock.ExpectBegin()
		mockDB.On("Insert", ctx, req, testAccountID, types.CertificateInfo{ID: certID, Arn: certArn}, mock.AnythingOfType("*sql.Tx"), mock.Anything).Return(nil)
		sqlMock.ExpectCommit().WillReturnError(errors.New("commit error"))

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		updateReq := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)

		err := service.UpdateDevice(ctx, testDeviceID, updateReq, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), errorutil.ErrMsgDeviceNotFound)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetDeviceByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		// Device owned by different account
		device := &models.Device{
			ID:          testDeviceUUID,
			DeviceID:    testDeviceID,
			ClaimStatus: "CLAIMED",
			ClaimedBy:   null.NewString("other-account-id", true),
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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

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
// ResetDevice Tests
// ---------------------------------------------------------------------------

func TestResetDevice(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully resets device", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)

		// IoT revocation operations
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetatchCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetatchPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, nil)

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), errorutil.ErrMsgDeviceNotFound)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when GetDeviceByID fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(nil, errors.New("database error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
	})

	t.Run("returns error when SetCertificateInactive fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

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

	t.Run("returns error when DetatchCertificateFromThing fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetatchCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).
			Return(errors.New("IoT error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when DetatchPolicyFromCertificate fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetatchCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetatchPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).
			Return(errors.New("IoT error"))

		err := service.ResetDevice(ctx, testDeviceID, user, logger)

		assert.Error(t, err)
		mockDB.AssertExpectations(t)
		mockIoT.AssertExpectations(t)
	})

	t.Run("returns error when transaction begin fails", func(t *testing.T) {
		mockDB := new(mockDBService)
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetatchCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetatchPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)
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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetatchCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetatchPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)
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
		mockIoT := new(mockIoTService)
		service := NewService(mockDB, mockIoT)

		logger := createTestLogger(t)
		user := createTestUserAuth()
		device := createClaimedDevice()

		dbWithTx, sqlMock := newMockDBWithTransactions(t)
		defer dbWithTx.Close()

		mockDB.On("GetDeviceByID", ctx, testDeviceID, mock.Anything).Return(device, nil)
		mockIoT.On("SetCertificateInactive", ctx, testCertID, mock.Anything).Return(nil)
		mockIoT.On("DetatchCertificateFromThing", ctx, testDeviceID, testCertArn, mock.Anything).Return(nil)
		mockIoT.On("DetatchPolicyFromCertificate", ctx, "testdevicepolicy", testCertArn, mock.Anything).Return(nil)
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
		mockIoT := new(mockIoTService)

		service := NewService(mockDB, mockIoT)

		assert.NotNil(t, service)
		assert.Equal(t, mockDB, service.dbService)
		assert.Equal(t, mockIoT, service.iotService)
	})
}
