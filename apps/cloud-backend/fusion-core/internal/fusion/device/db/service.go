package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"go.uber.org/zap"
)

// Service handles database operations for device management.
type Service struct {
	db model.DBWithTransactions
}

// NewService creates a new database service instance.
func NewService(db model.DBWithTransactions) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	return &Service{db: db}
}

// GetDB returns the database instance for transaction management.
func (s *Service) GetDB(_ context.Context) model.DBWithTransactions {
	return s.db
}

// ---------------------------------------------------------------------------
// Query Operations
// ---------------------------------------------------------------------------

// GetDeviceByID retrieves a device by its serial_number field.
// Returns nil, sql.ErrNoRows if the device is not found.
func (s *Service) GetDeviceByID(ctx context.Context, deviceID string, logger *zap.Logger) (*models.Device, error) {

	// Guard against empty deviceID to prevent unnecessary DB query
	if deviceID == "" {
		return nil, fmt.Errorf(errorutil.ErrMsgDeviceIDEmpty)
	}

	device, err := models.Devices(models.DeviceWhere.SerialNumber.EQ(deviceID)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, err
		}
		logger.Error("Failed to get device by ID", zap.String("deviceID", deviceID), zap.Error(err))
		return nil, fmt.Errorf("failed to get device by ID %s: %w", deviceID, err)
	}
	return device, nil
}

// ---------------------------------------------------------------------------
// Internal Helper Functions
// ---------------------------------------------------------------------------

// insertOwnershipHistory creates a new device ownership history record.
func (s *Service) insertOwnershipHistory(ctx context.Context, deviceUUID, accountID, certID, certArn string, tx model.DBTxExecutor, logger *zap.Logger) error {
	if deviceUUID == "" {
		return fmt.Errorf(errorutil.ErrMsgDeviceUUIDEmpty)
	}
	if accountID == "" {
		return fmt.Errorf(errorutil.ErrMsgAccountIDEmpty)
	}
	if certID == "" {
		return fmt.Errorf(errorutil.ErrMsgCertIDEmpty)
	}
	if certArn == "" {
		return fmt.Errorf(errorutil.ErrMsgCertArnEmpty)
	}
	history := models.DeviceOwnershipHistory{
		DeviceID:       deviceUUID,
		AccountID:      accountID,
		CertificateID:  certID,
		CertificateArn: certArn,
		ClaimedAt:      time.Now(),
	}

	if err := history.Insert(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to insert device ownership history", zap.String("deviceUUID", deviceUUID), zap.String("accountID", accountID), zap.Error(err))
		return fmt.Errorf("failed to insert ownership history for device %s: %w", deviceUUID, err)
	}
	return nil
}

// insertProjectHistory creates a new device project history record.
func (s *Service) insertProjectHistory(ctx context.Context, deviceUUID, projectID string, tx model.DBTxExecutor, logger *zap.Logger) error {
	if deviceUUID == "" {
		return fmt.Errorf(errorutil.ErrMsgDeviceUUIDEmpty)
	}
	if projectID == "" {
		return fmt.Errorf(errorutil.ErrMsgProjectIDEmpty)
	}
	history := models.DeviceProjectHistory{
		DeviceID:       deviceUUID,
		ProjectID:      projectID,
		CommissionedAt: time.Now(),
	}

	if err := history.Insert(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to insert device project history", zap.String("deviceUUID", deviceUUID), zap.String("projectID", projectID), zap.Error(err))
		return fmt.Errorf("failed to insert project history for device %s project %s: %w", deviceUUID, projectID, err)
	}
	return nil
}

// decommissionCurrentProject marks the current project assignment as decommissioned.
func (s *Service) decommissionCurrentProject(ctx context.Context, deviceUUID, projectID string, tx model.DBTxExecutor, logger *zap.Logger) error {
	if deviceUUID == "" {
		return fmt.Errorf(errorutil.ErrMsgDeviceUUIDEmpty)
	}
	if projectID == "" {
		return fmt.Errorf(errorutil.ErrMsgProjectIDEmpty)
	}
	history, err := models.DeviceProjectHistories(
		models.DeviceProjectHistoryWhere.DeviceID.EQ(deviceUUID),
		models.DeviceProjectHistoryWhere.ProjectID.EQ(projectID),
		models.DeviceProjectHistoryWhere.DecommissionedAt.IsNull(),
	).One(ctx, tx)
	if err != nil {
		logger.Error("Failed to get device project history",
			zap.String("deviceUUID", deviceUUID),
			zap.String("projectID", projectID),
			zap.Error(err))
		return fmt.Errorf("failed to get device project history for device %s project %s: %w", deviceUUID, projectID, err)
	}

	history.DecommissionedAt = null.NewTime(time.Now(), true)
	if _, err = history.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to decommission device project history", zap.String("deviceUUID", deviceUUID), zap.String("projectID", projectID), zap.Error(err))
		return fmt.Errorf("failed to decommission project history for device %s project %s: %w", deviceUUID, projectID, err)
	}
	return nil
}

// ---------------------------------------------------------------------------
// Write Operations
// ---------------------------------------------------------------------------

// Insert creates a new device record with associated ownership and project history.
func (s *Service) Insert(ctx context.Context, req *types.DeviceCreateRequest, accountID string, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error {

	if req == nil {
		return fmt.Errorf(errorutil.ErrMsgDeviceCreateReqNil)
	}
	if accountID == "" {
		return fmt.Errorf(errorutil.ErrMsgAccountIDEmpty)
	}

	// Create device record
	device := models.Device{
		ClientDeviceID:  null.NewString(req.ClientDeviceID, req.ClientDeviceID != ""),
		SerialNumber:    req.SerialNumber,
		Name:            null.NewString(req.DeviceName, req.DeviceName != ""),
		ModelName:       req.ModelName,
		MacAddress:      null.NewString(req.MacAddress, req.MacAddress != ""),
		IsPrimary:       null.NewBool(req.IsPrimary, true),
		CertificateID:   null.NewString(cert.ID, cert.ID != ""),
		CertificateArn:  null.NewString(cert.Arn, cert.Arn != ""),
		ClaimedBy:       null.NewString(accountID, accountID != ""),
		ClaimStatus:     models.ClaimStatusEnumCLAIMED,
		ProjectID:       null.NewString(req.ProjectID, req.ProjectID != ""),
		FirmwareVersion: req.FirmwareVersion,
		DeviceZone:      null.NewString(req.DeviceZone, req.DeviceZone != ""),
		DeviceLocation:  null.NewString(req.DeviceLocation, req.DeviceLocation != ""),
	}

	if err := device.Insert(ctx, tx, boil.Infer()); err != nil {
		if strings.Contains(err.Error(), "violates unique constraint") {
			return fmt.Errorf(errorutil.ErrMsgDeviceUniqueConstraint)
		}
		logger.Error("Failed to insert device", zap.String("deviceID", req.SerialNumber), zap.Error(err))
		return fmt.Errorf("failed to insert device %s: %w", req.SerialNumber, err)
	}

	// Create ownership history
	if err := s.insertOwnershipHistory(ctx, device.ID, accountID, cert.ID, cert.Arn, tx, logger); err != nil {
		return err
	}

	// Create project history
	if err := s.insertProjectHistory(ctx, device.ID, req.ProjectID, tx, logger); err != nil {
		return err
	}

	return nil
}

// Update modifies an existing device's mutable fields.
func (s *Service) Update(ctx context.Context, device models.Device, req *types.DeviceUpdateRequest, tx model.DBTxExecutor, logger *zap.Logger) error {
	if req == nil {
		return fmt.Errorf(errorutil.ErrMsgDeviceUpdateReqNil)
	}
	// Update mutable fields if provided
	if req.DeviceName != "" {
		device.Name = null.NewString(req.DeviceName, true)
	}
	if req.FirmwareVersion != "" {
		device.FirmwareVersion = req.FirmwareVersion
	}
	if req.DeviceZone != "" {
		device.DeviceZone = null.NewString(req.DeviceZone, true)
	}
	if req.DeviceLocation != "" {
		device.DeviceLocation = null.NewString(req.DeviceLocation, true)
	}
	if req.IsPrimary != nil {
		device.IsPrimary = null.NewBool(*req.IsPrimary, true)
	}

	// Handle project change if requested
	if req.ProjectID != "" && device.ProjectID.String != req.ProjectID {
		if err := s.handleProjectChange(ctx, &device, req.ProjectID, tx, logger); err != nil {
			return err
		}
	}

	if _, err := device.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to update device", zap.String("serialNumber", device.SerialNumber), zap.Error(err))
		return fmt.Errorf("failed to update device %s: %w", device.SerialNumber, err)
	}

	return nil
}

// handleProjectChange processes a device's project reassignment.
// Note: Project validation (exists & ownership) should be done by the business layer.
func (s *Service) handleProjectChange(ctx context.Context, device *models.Device, newProjectID string, tx model.DBTxExecutor, logger *zap.Logger) error {
	// Decommission current project assignment
	if err := s.decommissionCurrentProject(ctx, device.ID, device.ProjectID.String, tx, logger); err != nil {
		return err
	}

	// Update device's project reference
	device.ProjectID = null.NewString(newProjectID, newProjectID != "")

	// Create new project history record
	if err := s.insertProjectHistory(ctx, device.ID, newProjectID, tx, logger); err != nil {
		return err
	}

	return nil
}

// Reset releases a device from its current owner, marking it as unclaimed.
func (s *Service) Reset(ctx context.Context, device models.Device, tx model.DBTxExecutor, logger *zap.Logger) error {

	// Mark ownership as released
	ownerHistory, err := models.DeviceOwnershipHistories(
		models.DeviceOwnershipHistoryWhere.DeviceID.EQ(device.ID),
		models.DeviceOwnershipHistoryWhere.AccountID.EQ(device.ClaimedBy.String),
		models.DeviceOwnershipHistoryWhere.ReleasedAt.IsNull(),
	).One(ctx, tx)
	if err != nil {
		logger.Error("Failed to get device ownership history", zap.String("serialNumber", device.SerialNumber), zap.Error(err))
		return fmt.Errorf("failed to get ownership history for device %s: %w", device.SerialNumber, err)
	}

	ownerHistory.ReleasedAt = null.NewTime(time.Now(), true)
	if _, err = ownerHistory.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to update device ownership history", zap.String("serialNumber", device.SerialNumber), zap.Error(err))
		return fmt.Errorf("failed to update ownership history for device %s: %w", device.SerialNumber, err)
	}

	// Decommission current project
	if err := s.decommissionCurrentProject(ctx, device.ID, device.ProjectID.String, tx, logger); err != nil {
		return err
	}

	// Clear device claim data
	device.ClaimStatus = models.ClaimStatusEnumUNCLAIMED
	device.ClaimedBy = null.NewString("", false)
	device.ProjectID = null.NewString("", false)
	device.CertificateID = null.NewString("", false)
	device.CertificateArn = null.NewString("", false)
	device.DeviceZone = null.NewString("", false)
	device.DeviceLocation = null.NewString("", false)
	device.ClientDeviceID = null.NewString("", false)
	device.Name = null.NewString("", false)

	if _, err = device.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to reset device", zap.String("serialNumber", device.SerialNumber), zap.Error(err))
		return fmt.Errorf("failed to reset device %s: %w", device.SerialNumber, err)
	}

	return nil
}

// ClaimDevice claims an existing unclaimed device for a new owner with the given project.
func (s *Service) ClaimDevice(ctx context.Context, device models.Device, accountID string, cert types.CertificateInfo, req *types.DeviceClaimRequest, tx model.DBTxExecutor, logger *zap.Logger) error {
	if accountID == "" {
		return fmt.Errorf(errorutil.ErrMsgAccountIDEmpty)
	}

	if req == nil {
		return fmt.Errorf(errorutil.ErrMsgDeviceRequestInvalid)
	}

	if req.ProjectID == "" {
		return fmt.Errorf(errorutil.ErrMsgProjectIDEmpty)
	}

	// Update device with claim details
	device.ProjectID = null.NewString(req.ProjectID, req.ProjectID != "")
	device.ClaimedBy = null.NewString(accountID, accountID != "")
	device.CertificateID = null.NewString(cert.ID, cert.ID != "")
	device.CertificateArn = null.NewString(cert.Arn, cert.Arn != "")
	device.ClaimStatus = models.ClaimStatusEnumCLAIMED
	device.ClientDeviceID = null.NewString(req.ClientDeviceID, req.ClientDeviceID != "")
	device.Name = null.NewString(req.DeviceName, req.DeviceName != "")
	device.DeviceZone = null.NewString(req.DeviceZone, req.DeviceZone != "")
	device.DeviceLocation = null.NewString(req.DeviceLocation, req.DeviceLocation != "")
	device.FirmwareVersion = req.FirmwareVersion
	if req.IsPrimary != nil {
		device.IsPrimary = null.NewBool(*req.IsPrimary, true)
	}

	if _, err := device.Update(ctx, tx, boil.Infer()); err != nil {
		if strings.Contains(err.Error(), "violates unique constraint") {
			return fmt.Errorf(errorutil.ErrMsgDeviceUniqueConstraint)
		}
		logger.Error("Failed to claim device", zap.String("serialNumber", device.SerialNumber), zap.Error(err))
		return fmt.Errorf("failed to claim device %s: %w", device.SerialNumber, err)
	}

	// Create ownership history
	if err := s.insertOwnershipHistory(ctx, device.ID, accountID, cert.ID, cert.Arn, tx, logger); err != nil {
		return err
	}

	// Create project history
	if err := s.insertProjectHistory(ctx, device.ID, req.ProjectID, tx, logger); err != nil {
		return err
	}

	return nil
}

// UpdateCertificate updates the certificate information for a device.
func (s *Service) UpdateCertificate(ctx context.Context, device models.Device, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error {
	device.CertificateID = null.NewString(cert.ID, cert.ID != "")
	device.CertificateArn = null.NewString(cert.Arn, cert.Arn != "")

	if _, err := device.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to update device certificate", zap.String("serialNumber", device.SerialNumber), zap.Error(err))
		return fmt.Errorf("failed to update certificate for device %s: %w", device.SerialNumber, err)
	}

	return nil
}

// InsertCommand inserts a new command into the device command history and publishes it to the device cluster topic.
func (s *Service) InsertCommand(ctx context.Context, projectID, commandID string, request *types.CommandRequest, logger *zap.Logger) error {
	if projectID == "" {
		return fmt.Errorf(errorutil.ErrMsgProjectIDEmpty)
	}
	if commandID == "" {
		return fmt.Errorf(errorutil.ErrMsgCommandIDEmpty)
	}
	if request == nil {
		return fmt.Errorf(errorutil.ErrMsgCommandReqNil)
	}

	if len(request.DeviceIDs) == 0 {
		command := models.DeviceCommandHistory{
			CommandID:   commandID,
			ProjectID:   projectID,
			CommandName: string(request.Command),
			Status:      models.CommandStatusEnumUNPUBLISHED,
			IssuedAt:    time.Now(),
		}

		if err := command.Insert(ctx, s.db, boil.Infer()); err != nil {
			logger.Error("Failed to insert command", zap.String("commandID", commandID), zap.String("projectID", projectID), zap.Error(err))
			return fmt.Errorf("failed to insert command %s for project %s: %w", commandID, projectID, err)
		}
	}

	for _, deviceID := range request.DeviceIDs {
		device, err := s.GetDeviceByID(ctx, deviceID, logger)
		if err != nil {
			logger.Error("Failed to get device by ID", zap.String("deviceID", deviceID), zap.Error(err))
			return fmt.Errorf("failed to get device by ID %s: %w", deviceID, err)
		}

		// Insert command into database
		command := models.DeviceCommandHistory{
			CommandID:   commandID,
			ProjectID:   projectID,
			DeviceID:    null.NewString(device.ID, device.ID != ""),
			CommandName: string(request.Command),
			Status:      models.CommandStatusEnumUNPUBLISHED,
			IssuedAt:    time.Now(),
		}

		if err := command.Insert(ctx, s.db, boil.Infer()); err != nil {
			logger.Error("Failed to insert command", zap.String("commandID", commandID), zap.String("projectID", projectID), zap.String("deviceID", deviceID), zap.Error(err))
			return fmt.Errorf("failed to insert command %s for device %s: %w", commandID, deviceID, err)
		}
	}
	return nil
}

// UpdateCommandStatus updates the status of a command in the device command history.
func (s *Service) UpdateCommandStatus(ctx context.Context, commandID string, status string, logger *zap.Logger) error {
	if commandID == "" {
		return fmt.Errorf(errorutil.ErrMsgCommandIDEmpty)
	}
	if status == "" {
		return fmt.Errorf(errorutil.ErrMsgStatusEmpty)
	}

	commands, err := models.DeviceCommandHistories(models.DeviceCommandHistoryWhere.CommandID.EQ(commandID)).All(ctx, s.db)
	if err != nil {
		logger.Error("Failed to get command history", zap.String("commandID", commandID), zap.Error(err))
		return fmt.Errorf("failed to get command history for %s: %w", commandID, err)
	}

	for _, command := range commands {
		command.Status = status
		if _, err := command.Update(ctx, s.db, boil.Infer()); err != nil {
			logger.Error("Failed to update command status", zap.String("commandID", commandID), zap.Error(err))
			return fmt.Errorf("failed to update command status for %s: %w", commandID, err)
		}
	}

	return nil
}

// GetCommandStatus retrieves the status of a command by its ID.
func (s *Service) GetCommandStatus(ctx context.Context, commandID string, logger *zap.Logger) (*models.DeviceCommandHistorySlice, error) {
	if commandID == "" {
		return nil, fmt.Errorf(errorutil.ErrMsgCommandIDEmpty)
	}
	commands, err := models.DeviceCommandHistories(models.DeviceCommandHistoryWhere.CommandID.EQ(commandID)).All(ctx, s.db)
	if err != nil {
		logger.Error("Failed to get command status", zap.String("commandID", commandID), zap.Error(err))
		return nil, fmt.Errorf("failed to get command status for %s: %w", commandID, err)
	}
	return &commands, nil
}
