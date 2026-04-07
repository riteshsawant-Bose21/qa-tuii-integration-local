package db

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/DATA-DOG/go-sqlmock"
	"github.com/aarondl/null/v8"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	testDeviceID        = "device-123"
	testDeviceUUID      = "uuid-device-123"
	testDeviceName      = "Test Device"
	testSerialNumber    = "SN-12345"
	testModelName       = "Model-X"
	testMacAddress      = "00:11:22:33:44:55"
	testFirmwareVersion = "1.0.0"
	testDeviceZone      = "Zone A"
	testDeviceLocation  = "Building 1"
	testProjectID       = "project-123"
	testAccountID       = "account-123"
	testCertID          = "cert-id-123"
	testCertArn         = "arn:aws:iot:cert/123"
	testNewProjectID    = "project-456"
	testCommandID       = "cmd-uuid-123"
)

func setupTestDB(t *testing.T) (*sql.DB, sqlmock.Sqlmock, *Service) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)

	service := NewService(db)
	return db, mock, service
}

func getTestLogger(t *testing.T) *log.Logger {
	logger, err := log.NewProduction()
	require.NoError(t, err)
	return logger
}

// ---------------------------------------------------------------------------
// NewService Tests
// ---------------------------------------------------------------------------

func TestNewService(t *testing.T) {
	t.Run("successfully creates new service", func(t *testing.T) {
		db, _, _ := sqlmock.New()
		defer db.Close()

		service := NewService(db)
		assert.NotNil(t, service)
		assert.NotNil(t, service.db)
	})

	t.Run("panics when db is nil", func(t *testing.T) {
		assert.Panics(t, func() {
			NewService(nil)
		})
	})
}

// ---------------------------------------------------------------------------
// GetDB Tests
// ---------------------------------------------------------------------------

func TestGetDB(t *testing.T) {
	t.Run("returns database instance", func(t *testing.T) {
		db, _, service := setupTestDB(t)
		defer db.Close()

		ctx := context.Background()
		result := service.GetDB(ctx)
		assert.NotNil(t, result)
		assert.Equal(t, db, result)
	})
}

// ---------------------------------------------------------------------------
// GetDeviceByID Tests
// ---------------------------------------------------------------------------

func TestGetDeviceByID(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()
	logger := getTestLogger(t)

	t.Run("successfully retrieves device by ID", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{
			"id", "client_device_id", "name", "serial_number", "model_name", "thing_name",
			"mac_address", "is_primary", "certificate_id", "certificate_arn",
			"claim_status", "claimed_by", "project_id", "firmware_version",
			"device_zone", "device_location", "created_at", "updated_at",
		}).AddRow(
			testDeviceUUID, testDeviceID, testDeviceName, testSerialNumber, testModelName, testDeviceID,
			testMacAddress, true, testCertID, testCertArn,
			"CLAIMED", testAccountID, testProjectID, testFirmwareVersion,
			testDeviceZone, testDeviceLocation, time.Now(), time.Now(),
		)

		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."serial_number" = \$1\) LIMIT 1`).
			WithArgs(testSerialNumber).
			WillReturnRows(rows)

		device, err := service.GetDeviceByID(ctx, testSerialNumber, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NotNil(t, device)
		assert.Equal(t, testSerialNumber, device.SerialNumber)
		assert.Equal(t, testDeviceUUID, device.ID)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns nil when device not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."serial_number" = \$1\) LIMIT 1`).
			WithArgs("non-existent").
			WillReturnError(sql.ErrNoRows)

		device, err := service.GetDeviceByID(ctx, "non-existent", logger.JobSyncLog())
		assert.ErrorIs(t, err, sql.ErrNoRows)
		assert.Nil(t, device)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error on database error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."serial_number" = \$1\) LIMIT 1`).
			WithArgs(testDeviceID).
			WillReturnError(assert.AnError)

		device, err := service.GetDeviceByID(ctx, testDeviceID, logger.JobSyncLog())
		assert.Error(t, err)
		assert.Nil(t, device)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// Insert Tests
// ---------------------------------------------------------------------------

func TestInsert(t *testing.T) {
	ctx := context.Background()

	createTestRequest := func() *types.DeviceCreateRequest {
		return &types.DeviceCreateRequest{
			ClientDeviceID:  testDeviceID,
			DeviceName:      testDeviceName,
			ModelName:       testModelName,
			FirmwareVersion: testFirmwareVersion,
			SerialNumber:    testSerialNumber,
			MacAddress:      testMacAddress,
			DeviceZone:      testDeviceZone,
			DeviceLocation:  testDeviceLocation,
			ProjectID:       testProjectID,
			IsPrimary:       true,
			CSR:             "test-csr",
		}
	}

	cert := types.CertificateInfo{
		ID:  testCertID,
		Arn: testCertArn,
	}

	t.Run("successfully inserts device", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := createTestRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		// Device insert returns only id (auto-generated UUID) - other defaults are set
		returnRows := sqlmock.NewRows([]string{"id"}).
			AddRow(testDeviceUUID)
		mock.ExpectQuery(`INSERT INTO "device"`).
			WillReturnRows(returnRows)

		// Ownership history returns id, released_at (created_at/updated_at are set by timestamp hooks)
		ownerHistoryRows := sqlmock.NewRows([]string{"id", "released_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_ownership_history"`).
			WillReturnRows(ownerHistoryRows)

		// Project history returns id, decommissioned_at (created_at/updated_at are set by timestamp hooks)
		projectHistoryRows := sqlmock.NewRows([]string{"id", "decommissioned_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_project_history"`).
			WillReturnRows(projectHistoryRows)

		err = service.Insert(ctx, req, testAccountID, cert, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when device insert fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := createTestRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectQuery(`INSERT INTO "device"`).
			WillReturnError(assert.AnError)

		err = service.Insert(ctx, req, testAccountID, cert, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when ownership history insert fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := createTestRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		returnRows := sqlmock.NewRows([]string{"id"}).AddRow(testDeviceUUID)
		mock.ExpectQuery(`INSERT INTO "device"`).
			WillReturnRows(returnRows)

		mock.ExpectQuery(`INSERT INTO "device_ownership_history"`).
			WillReturnError(assert.AnError)

		err = service.Insert(ctx, req, testAccountID, cert, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when project history insert fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := createTestRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		returnRows := sqlmock.NewRows([]string{"id"}).AddRow(testDeviceUUID)
		mock.ExpectQuery(`INSERT INTO "device"`).
			WillReturnRows(returnRows)

		ownerHistoryRows := sqlmock.NewRows([]string{"id", "released_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_ownership_history"`).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectQuery(`INSERT INTO "device_project_history"`).
			WillReturnError(assert.AnError)

		err = service.Insert(ctx, req, testAccountID, cert, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("handles empty optional fields", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := &types.DeviceCreateRequest{
			ClientDeviceID:  testDeviceID,
			DeviceName:      "",
			ModelName:       testModelName,
			FirmwareVersion: testFirmwareVersion,
			SerialNumber:    testSerialNumber,
			MacAddress:      "",
			DeviceZone:      "",
			DeviceLocation:  "",
			ProjectID:       testProjectID,
			IsPrimary:       false,
			CSR:             "test-csr",
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		// When empty optional fields are provided, their null.String values have valid=false,
		// so they remain at zero value and SQLBoiler includes them in RETURNING
		returnRows := sqlmock.NewRows([]string{"id", "name", "mac_address", "device_zone", "device_location"}).
			AddRow(testDeviceUUID, nil, nil, nil, nil)
		mock.ExpectQuery(`INSERT INTO "device"`).
			WillReturnRows(returnRows)

		ownerHistoryRows := sqlmock.NewRows([]string{"id", "released_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_ownership_history"`).
			WillReturnRows(ownerHistoryRows)

		projectHistoryRows := sqlmock.NewRows([]string{"id", "decommissioned_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_project_history"`).
			WillReturnRows(projectHistoryRows)

		err = service.Insert(ctx, req, testAccountID, cert, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// ClaimDevice Tests
// ---------------------------------------------------------------------------

func TestClaimDevice(t *testing.T) {
	ctx := context.Background()

	createTestDevice := func() models.Device {
		return models.Device{
			ID:             testDeviceUUID,
			ClientDeviceID: null.NewString(testDeviceID, testDeviceID != ""),
			Name:           null.NewString("", false),
			SerialNumber:   testSerialNumber,
			ModelName:      testModelName,
			MacAddress:     null.NewString("", false),
			IsPrimary:      null.NewBool(false, false),
			CertificateID:  null.NewString("", false),
			CertificateArn: null.NewString("", false),
			ClaimStatus:    "UNCLAIMED",
			ClaimedBy:      null.NewString("", false),
			ProjectID:      null.NewString("", false),
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		}
	}

	createTestClaimRequest := func() *types.DeviceClaimRequest {
		return &types.DeviceClaimRequest{
			ClientDeviceID:  testDeviceID,
			DeviceName:      testDeviceName,
			FirmwareVersion: testFirmwareVersion,
			DeviceZone:      testDeviceZone,
			DeviceLocation:  testDeviceLocation,
			ProjectID:       testProjectID,
			IsPrimary:       func(b bool) *bool { return &b }(true),
			CSR:             "test-csr",
		}
	}

	cert := types.CertificateInfo{
		ID:  testCertID,
		Arn: testCertArn,
	}

	t.Run("successfully claims device", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createTestDevice()
		req := createTestClaimRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		// Ownership history returns id, released_at (created_at/updated_at are set by timestamp hooks)
		ownerHistoryRows := sqlmock.NewRows([]string{"id", "released_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_ownership_history"`).
			WillReturnRows(ownerHistoryRows)

		// Project history returns id, decommissioned_at (created_at/updated_at are set by timestamp hooks)
		projectHistoryRows := sqlmock.NewRows([]string{"id", "decommissioned_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_project_history"`).
			WillReturnRows(projectHistoryRows)

		err = service.ClaimDevice(ctx, device, testAccountID, cert, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when device update fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createTestDevice()
		req := createTestClaimRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnError(assert.AnError)

		err = service.ClaimDevice(ctx, device, testAccountID, cert, req, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when ownership history insert fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createTestDevice()
		req := createTestClaimRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		mock.ExpectQuery(`INSERT INTO "device_ownership_history"`).
			WillReturnError(assert.AnError)

		err = service.ClaimDevice(ctx, device, testAccountID, cert, req, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when project history insert fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createTestDevice()
		req := createTestClaimRequest()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		// Ownership history returns id, released_at (created_at/updated_at are set by timestamp hooks)
		ownerHistoryRows := sqlmock.NewRows([]string{"id", "released_at"}).
			AddRow(1, nil)
		mock.ExpectQuery(`INSERT INTO "device_ownership_history"`).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectQuery(`INSERT INTO "device_project_history"`).
			WillReturnError(assert.AnError)

		err = service.ClaimDevice(ctx, device, testAccountID, cert, req, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// Update Tests
// ---------------------------------------------------------------------------

func TestUpdate(t *testing.T) {
	ctx := context.Background()

	createClaimedDevice := func() models.Device {
		return models.Device{
			ID:              testDeviceUUID,
			ClientDeviceID:  null.NewString(testDeviceID, testDeviceID != ""),
			Name:            null.NewString(testDeviceName, true),
			SerialNumber:    testSerialNumber,
			ModelName:       testModelName,
			MacAddress:      null.NewString(testMacAddress, true),
			IsPrimary:       null.NewBool(true, true),
			CertificateID:   null.NewString(testCertID, true),
			CertificateArn:  null.NewString(testCertArn, true),
			ClaimStatus:     "CLAIMED",
			ClaimedBy:       null.NewString(testAccountID, true),
			ProjectID:       null.NewString(testProjectID, true),
			FirmwareVersion: testFirmwareVersion,
			DeviceZone:      null.NewString(testDeviceZone, true),
			DeviceLocation:  null.NewString(testDeviceLocation, true),
			CreatedAt:       time.Now(),
			UpdatedAt:       time.Now(),
		}
	}

	t.Run("successfully updates device name", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			DeviceName: "Updated Device Name",
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully updates firmware version", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			FirmwareVersion: "2.0.0",
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully updates device zone and location", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			DeviceZone:     "Zone B",
			DeviceLocation: "Building 2",
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully updates is_primary field", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		isPrimaryFalse := false
		req := &types.DeviceUpdateRequest{
			IsPrimary: &isPrimaryFalse,
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully updates multiple fields", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		isPrimaryTrue := true
		req := &types.DeviceUpdateRequest{
			DeviceName:      "New Device Name",
			FirmwareVersion: "3.0.0",
			DeviceZone:      "Zone C",
			DeviceLocation:  "Building 3",
			IsPrimary:       &isPrimaryTrue,
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when update fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			DeviceName: "Updated Name",
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnError(assert.AnError)

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully updates project with valid project change", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			ProjectID: testNewProjectID,
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		// Note: Project validation (exists & ownership) is done by the business layer, not the db layer
		projectHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "project_id", "commissioned_at", "decommissioned_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testProjectID, time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) AND \("device_project_history"\."decommissioned_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testProjectID).
			WillReturnRows(projectHistoryRows)

		mock.ExpectExec(`UPDATE "device_project_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		// Project history returns id, decommissioned_at (created_at/updated_at are set by timestamp hooks)
		newProjectHistoryRows := sqlmock.NewRows([]string{"id", "decommissioned_at"}).
			AddRow(2, nil)
		mock.ExpectQuery(`INSERT INTO "device_project_history"`).
			WillReturnRows(newProjectHistoryRows)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	// Note: "returns error when new project not found" and "returns unauthorized error when project belongs to different account"
	// tests are not needed in the db layer since project validation is done by the business layer

	t.Run("skips project change when same project ID", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			ProjectID: testProjectID,
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when decommission current project fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			ProjectID: testNewProjectID,
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		// Note: Project validation is done by the business layer
		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) AND \("device_project_history"\."decommissioned_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testProjectID).
			WillReturnError(sql.ErrNoRows)

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("no fields to update", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// Reset Tests
// ---------------------------------------------------------------------------

func TestReset(t *testing.T) {
	ctx := context.Background()

	createClaimedDevice := func() models.Device {
		return models.Device{
			ID:              testDeviceUUID,
			ClientDeviceID:  null.NewString(testDeviceID, testDeviceID != ""),
			Name:            null.NewString(testDeviceName, true),
			SerialNumber:    testSerialNumber,
			ModelName:       testModelName,
			MacAddress:      null.NewString(testMacAddress, true),
			IsPrimary:       null.NewBool(true, true),
			CertificateID:   null.NewString(testCertID, true),
			CertificateArn:  null.NewString(testCertArn, true),
			ClaimStatus:     "CLAIMED",
			ClaimedBy:       null.NewString(testAccountID, true),
			ProjectID:       null.NewString(testProjectID, true),
			FirmwareVersion: testFirmwareVersion,
			DeviceZone:      null.NewString(testDeviceZone, true),
			DeviceLocation:  null.NewString(testDeviceLocation, true),
			CreatedAt:       time.Now(),
			UpdatedAt:       time.Now(),
		}
	}

	t.Run("successfully resets device", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		ownerHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "account_id", "certificate_id", "certificate_arn",
			"claimed_at", "released_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testAccountID, testCertID, testCertArn,
			time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) AND \("device_ownership_history"\."released_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectExec(`UPDATE "device_ownership_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		projectHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "project_id", "commissioned_at", "decommissioned_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testProjectID, time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) AND \("device_project_history"\."decommissioned_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testProjectID).
			WillReturnRows(projectHistoryRows)

		mock.ExpectExec(`UPDATE "device_project_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err = service.Reset(ctx, device, tx, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when ownership history not found", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) AND \("device_ownership_history"\."released_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnError(sql.ErrNoRows)

		err = service.Reset(ctx, device, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when ownership history update fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		ownerHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "account_id", "certificate_id", "certificate_arn",
			"claimed_at", "released_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testAccountID, testCertID, testCertArn,
			time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) AND \("device_ownership_history"\."released_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectExec(`UPDATE "device_ownership_history"`).
			WillReturnError(assert.AnError)

		err = service.Reset(ctx, device, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when decommission project fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		ownerHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "account_id", "certificate_id", "certificate_arn",
			"claimed_at", "released_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testAccountID, testCertID, testCertArn,
			time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) AND \("device_ownership_history"\."released_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectExec(`UPDATE "device_ownership_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) AND \("device_project_history"\."decommissioned_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testProjectID).
			WillReturnError(assert.AnError)

		err = service.Reset(ctx, device, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when device update fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		ownerHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "account_id", "certificate_id", "certificate_arn",
			"claimed_at", "released_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testAccountID, testCertID, testCertArn,
			time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) AND \("device_ownership_history"\."released_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectExec(`UPDATE "device_ownership_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		projectHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "project_id", "commissioned_at", "decommissioned_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testProjectID, time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) AND \("device_project_history"\."decommissioned_at" is null\) LIMIT 1`).
			WithArgs(testDeviceUUID, testProjectID).
			WillReturnRows(projectHistoryRows)

		mock.ExpectExec(`UPDATE "device_project_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		mock.ExpectExec(`UPDATE "device"`).
			WillReturnError(assert.AnError)

		err = service.Reset(ctx, device, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// InsertCommand Tests
// ---------------------------------------------------------------------------

func TestInsertCommand(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully inserts command", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
			DeviceIDs: []string{testDeviceID},
		}

		deviceRows := sqlmock.NewRows([]string{
			"id", "serial_number", "client_device_id", "name", "model_name", "mac_address",
			"is_primary", "certificate_id", "certificate_arn", "claim_status", "claimed_by",
			"project_id", "firmware_version", "device_zone", "device_location", "created_at", "updated_at",
		}).AddRow(
			testDeviceUUID, testDeviceID, nil, nil, testModelName, nil,
			nil, nil, nil, "CLAIMED", testAccountID,
			testProjectID, testFirmwareVersion, nil, nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."serial_number" = \$1\) LIMIT 1`).
			WithArgs(testDeviceID).
			WillReturnRows(deviceRows)

		returnRows := sqlmock.NewRows([]string{"id"}).AddRow("db-generated-uuid")
		mock.ExpectQuery(`INSERT INTO "device_command_history"`).
			WillReturnRows(returnRows)

		err := service.InsertCommand(ctx, testProjectID, testCommandID, req, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully inserts command without device IDs", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
		}

		// Empty device IDs now inserts a single command row without device_id
		// device_id is not set so it appears in RETURNING along with id
		returnRows := sqlmock.NewRows([]string{"id", "device_id"}).AddRow("db-generated-uuid", nil)
		mock.ExpectQuery(`INSERT INTO "device_command_history"`).
			WillReturnRows(returnRows)

		err := service.InsertCommand(ctx, testProjectID, testCommandID, req, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when insert fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		req := &types.CommandRequest{
			Command:   types.CommandRestart,
			ProjectID: testProjectID,
			DeviceIDs: []string{testDeviceID},
		}

		deviceRows := sqlmock.NewRows([]string{
			"id", "serial_number", "client_device_id", "name", "model_name", "mac_address",
			"is_primary", "certificate_id", "certificate_arn", "claim_status", "claimed_by",
			"project_id", "firmware_version", "device_zone", "device_location", "created_at", "updated_at",
		}).AddRow(
			testDeviceUUID, testDeviceID, nil, nil, testModelName, nil,
			nil, nil, nil, "CLAIMED", testAccountID,
			testProjectID, testFirmwareVersion, nil, nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."serial_number" = \$1\) LIMIT 1`).
			WithArgs(testDeviceID).
			WillReturnRows(deviceRows)

		mock.ExpectQuery(`INSERT INTO "device_command_history"`).
			WillReturnError(assert.AnError)

		err := service.InsertCommand(ctx, testProjectID, testCommandID, req, logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// UpdateCommandStatus Tests
// ---------------------------------------------------------------------------

func TestUpdateCommandStatus(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully updates command status", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)

		rows := sqlmock.NewRows([]string{
			"id", "command_id", "project_id", "device_id", "command_name", "status", "issued_at", "created_at", "updated_at",
		}).AddRow(
			"db-id-1", testCommandID, testProjectID, testDeviceID, "REBOOT",
			"UNPUBLISHED", time.Now(), time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_command_history"\.\* FROM "device_command_history" WHERE \("device_command_history"\."command_id" = \$1\)`).
			WithArgs(testCommandID).
			WillReturnRows(rows)

		mock.ExpectExec(`UPDATE "device_command_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.UpdateCommandStatus(ctx, testCommandID, "PUBLISHED", logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when command not found", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		nonExistentID := "non-existent"

		mock.ExpectQuery(`SELECT "device_command_history"\.\* FROM "device_command_history" WHERE \("device_command_history"\."command_id" = \$1\)`).
			WithArgs(nonExistentID).
			WillReturnError(sql.ErrNoRows)

		err := service.UpdateCommandStatus(ctx, nonExistentID, "PUBLISHED", logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when update fails", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)

		rows := sqlmock.NewRows([]string{
			"id", "command_id", "project_id", "device_id", "command_name", "status", "issued_at", "created_at", "updated_at",
		}).AddRow(
			"db-id-1", testCommandID, testProjectID, testDeviceID, "REBOOT",
			"UNPUBLISHED", time.Now(), time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_command_history"\.\* FROM "device_command_history" WHERE \("device_command_history"\."command_id" = \$1\)`).
			WithArgs(testCommandID).
			WillReturnRows(rows)

		mock.ExpectExec(`UPDATE "device_command_history"`).
			WillReturnError(assert.AnError)

		err := service.UpdateCommandStatus(ctx, testCommandID, "PUBLISHED", logger.JobSyncLog())
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// GetCommandStatus Tests
// ---------------------------------------------------------------------------

func TestGetCommandStatus(t *testing.T) {
	ctx := context.Background()

	t.Run("successfully retrieves command status", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		issuedAt := time.Now()

		rows := sqlmock.NewRows([]string{
			"id", "command_id", "project_id", "device_id", "command_name", "status", "issued_at", "created_at", "updated_at",
		}).AddRow(
			"db-id-1", testCommandID, testProjectID, testDeviceID, "REBOOT",
			"COMPLETED", issuedAt, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_command_history"\.\* FROM "device_command_history" WHERE \("device_command_history"\."command_id" = \$1\)`).
			WithArgs(testCommandID).
			WillReturnRows(rows)

		commands, err := service.GetCommandStatus(ctx, testCommandID, logger.JobSyncLog())

		assert.NoError(t, err)
		assert.NotNil(t, commands)
		assert.Len(t, *commands, 1)
		cmd := (*commands)[0]
		assert.Equal(t, testCommandID, cmd.CommandID)
		assert.Equal(t, "REBOOT", cmd.CommandName)
		assert.Equal(t, "COMPLETED", cmd.Status)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns nil when command not found", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		nonExistentID := "non-existent"

		emptyRows := sqlmock.NewRows([]string{
			"id", "command_id", "project_id", "device_id", "command_name", "status", "issued_at", "created_at", "updated_at",
		})
		mock.ExpectQuery(`SELECT "device_command_history"\.\* FROM "device_command_history" WHERE \("device_command_history"\."command_id" = \$1\)`).
			WithArgs(nonExistentID).
			WillReturnRows(emptyRows)

		commands, err := service.GetCommandStatus(ctx, nonExistentID, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NotNil(t, commands)
		assert.Len(t, *commands, 0)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error on database error", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)

		mock.ExpectQuery(`SELECT "device_command_history"\.\* FROM "device_command_history" WHERE \("device_command_history"\."command_id" = \$1\)`).
			WithArgs(testCommandID).
			WillReturnError(assert.AnError)

		command, err := service.GetCommandStatus(ctx, testCommandID, logger.JobSyncLog())
		assert.Error(t, err)
		assert.Nil(t, command)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}
