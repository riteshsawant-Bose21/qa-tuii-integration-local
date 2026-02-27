package db

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
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
			"id", "device_id", "name", "serial_number", "model_name", "thing_name",
			"mac_address", "is_primary", "certificate_id", "certificate_arn",
			"claim_status", "claimed_by", "project_id", "firmware_version",
			"device_zone", "device_location", "created_at", "updated_at",
		}).AddRow(
			testDeviceUUID, testDeviceID, testDeviceName, testSerialNumber, testModelName, testDeviceID,
			testMacAddress, true, testCertID, testCertArn,
			"CLAIMED", testAccountID, testProjectID, testFirmwareVersion,
			testDeviceZone, testDeviceLocation, time.Now(), time.Now(),
		)

		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."device_id" = \$1\) LIMIT 1`).
			WithArgs(testDeviceID).
			WillReturnRows(rows)

		device, err := service.GetDeviceByID(ctx, testDeviceID, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NotNil(t, device)
		assert.Equal(t, testDeviceID, device.DeviceID)
		assert.Equal(t, testDeviceUUID, device.ID)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns nil when device not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."device_id" = \$1\) LIMIT 1`).
			WithArgs("non-existent").
			WillReturnError(sql.ErrNoRows)

		device, err := service.GetDeviceByID(ctx, "non-existent", logger.JobSyncLog())
		assert.NoError(t, err)
		assert.Nil(t, device)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error on database error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "device"\.\* FROM "device" WHERE \("device"\."device_id" = \$1\) LIMIT 1`).
			WithArgs(testDeviceID).
			WillReturnError(assert.AnError)

		device, err := service.GetDeviceByID(ctx, testDeviceID, logger.JobSyncLog())
		assert.Error(t, err)
		assert.Nil(t, device)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

// ---------------------------------------------------------------------------
// GetProjectByID Tests
// ---------------------------------------------------------------------------

func TestGetProjectByID(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()
	logger := getTestLogger(t)

	t.Run("successfully retrieves project by ID", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{
			"id", "application", "budget_amount", "currency", "description",
			"name", "project_phase", "venue", "environment_type",
			"is_archived", "is_deleted", "locked_by_user_id",
			"created_at", "updated_at", "primary_owner_account_id",
		}).AddRow(
			testProjectID, "Test App", 1000.0, "USD", "Test Description",
			"Test Project", "proposal", "Test Venue", "indoor",
			false, false, nil,
			time.Now(), time.Now(), testAccountID,
		)

		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(rows)

		project, err := service.GetProjectByID(ctx, testProjectID, logger.JobSyncLog())
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, testProjectID, project.ID)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns nil when project not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs("non-existent").
			WillReturnError(sql.ErrNoRows)

		project, err := service.GetProjectByID(ctx, "non-existent", logger.JobSyncLog())
		assert.NoError(t, err)
		assert.Nil(t, project)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error on database error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(assert.AnError)

		project, err := service.GetProjectByID(ctx, testProjectID, logger.JobSyncLog())
		assert.Error(t, err)
		assert.Nil(t, project)
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
			DeviceID:        testDeviceID,
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
			DeviceID:        testDeviceID,
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
			DeviceID:       testDeviceID,
			Name:           null.NewString("", false),
			SerialNumber:   testSerialNumber,
			ModelName:      testModelName,
			ThingName:      testDeviceID,
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

	createTestRequest := func() *types.DeviceCreateRequest {
		return &types.DeviceCreateRequest{
			DeviceID:        testDeviceID,
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

	t.Run("successfully claims device", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createTestDevice()
		req := createTestRequest()

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
		req := createTestRequest()

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
		req := createTestRequest()

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
		req := createTestRequest()

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
			DeviceID:        testDeviceID,
			Name:            null.NewString(testDeviceName, true),
			SerialNumber:    testSerialNumber,
			ModelName:       testModelName,
			ThingName:       testDeviceID,
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

		projectRows := sqlmock.NewRows([]string{
			"id", "application", "budget_amount", "currency", "description",
			"name", "project_phase", "venue", "environment_type",
			"is_archived", "is_deleted", "locked_by_user_id",
			"created_at", "updated_at", "primary_owner_account_id",
		}).AddRow(
			testNewProjectID, "Test App", 1000.0, "USD", "Test Description",
			"Test Project", "proposal", "Test Venue", "indoor",
			false, false, nil,
			time.Now(), time.Now(), testAccountID,
		)
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testNewProjectID).
			WillReturnRows(projectRows)

		projectHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "project_id", "commissioned_at", "decommissioned_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testProjectID, time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) LIMIT 1`).
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

	t.Run("returns error when new project not found", func(t *testing.T) {
		db, mock, service := setupTestDB(t)
		defer db.Close()

		logger := getTestLogger(t)
		device := createClaimedDevice()
		req := &types.DeviceUpdateRequest{
			ProjectID: "non-existent-project",
		}

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs("non-existent-project").
			WillReturnError(sql.ErrNoRows)

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.Contains(t, err.Error(), errorutil.ErrMsgProjectNotFound)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns unauthorized error when project belongs to different account", func(t *testing.T) {
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

		projectRows := sqlmock.NewRows([]string{
			"id", "application", "budget_amount", "currency", "description",
			"name", "project_phase", "venue", "environment_type",
			"is_archived", "is_deleted", "locked_by_user_id",
			"created_at", "updated_at", "primary_owner_account_id",
		}).AddRow(
			testNewProjectID, "Test App", 1000.0, "USD", "Test Description",
			"Test Project", "proposal", "Test Venue", "indoor",
			false, false, nil,
			time.Now(), time.Now(), "different-account-id",
		)
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testNewProjectID).
			WillReturnRows(projectRows)

		err = service.Update(ctx, device, req, tx, logger.JobSyncLog())
		assert.Error(t, err)
		assert.Contains(t, err.Error(), errorutil.MsgUnauthorized)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

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

		projectRows := sqlmock.NewRows([]string{
			"id", "application", "budget_amount", "currency", "description",
			"name", "project_phase", "venue", "environment_type",
			"is_archived", "is_deleted", "locked_by_user_id",
			"created_at", "updated_at", "primary_owner_account_id",
		}).AddRow(
			testNewProjectID, "Test App", 1000.0, "USD", "Test Description",
			"Test Project", "proposal", "Test Venue", "indoor",
			false, false, nil,
			time.Now(), time.Now(), testAccountID,
		)
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testNewProjectID).
			WillReturnRows(projectRows)

		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) LIMIT 1`).
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
			DeviceID:        testDeviceID,
			Name:            null.NewString(testDeviceName, true),
			SerialNumber:    testSerialNumber,
			ModelName:       testModelName,
			ThingName:       testDeviceID,
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
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectExec(`UPDATE "device_ownership_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		projectHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "project_id", "commissioned_at", "decommissioned_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testProjectID, time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) LIMIT 1`).
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

		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) LIMIT 1`).
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
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) LIMIT 1`).
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
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectExec(`UPDATE "device_ownership_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) LIMIT 1`).
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
		mock.ExpectQuery(`SELECT "device_ownership_history"\.\* FROM "device_ownership_history" WHERE \("device_ownership_history"\."device_id" = \$1\) AND \("device_ownership_history"\."account_id" = \$2\) LIMIT 1`).
			WithArgs(testDeviceUUID, testAccountID).
			WillReturnRows(ownerHistoryRows)

		mock.ExpectExec(`UPDATE "device_ownership_history"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		projectHistoryRows := sqlmock.NewRows([]string{
			"id", "device_id", "project_id", "commissioned_at", "decommissioned_at", "created_at", "updated_at",
		}).AddRow(
			1, testDeviceUUID, testProjectID, time.Now(), nil, time.Now(), time.Now(),
		)
		mock.ExpectQuery(`SELECT "device_project_history"\.\* FROM "device_project_history" WHERE \("device_project_history"\."device_id" = \$1\) AND \("device_project_history"\."project_id" = \$2\) LIMIT 1`).
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
