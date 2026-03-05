package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
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

// GetDeviceByID retrieves a device by its device_id field.
// Returns nil, nil if the device is not found.
func (s *Service) GetDeviceByID(ctx context.Context, deviceID string, logger *zap.Logger) (*models.Device, error) {
	device, err := models.Devices(models.DeviceWhere.DeviceID.EQ(deviceID)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		logger.Error("Failed to get device by ID", zap.String("deviceID", deviceID), zap.Error(err))
		return nil, err
	}
	return device, nil
}

// ---------------------------------------------------------------------------
// Internal Helper Functions
// ---------------------------------------------------------------------------

// insertOwnershipHistory creates a new device ownership history record.
func (s *Service) insertOwnershipHistory(ctx context.Context, deviceUUID, accountID, certID, certArn string, tx model.DBTxExecutor, logger *zap.Logger) error {
	history := models.DeviceOwnershipHistory{
		DeviceID:       deviceUUID,
		AccountID:      accountID,
		CertificateID:  certID,
		CertificateArn: certArn,
		ClaimedAt:      time.Now(),
	}

	if err := history.Insert(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to insert device ownership history", zap.Error(err))
		return err
	}
	return nil
}

// insertProjectHistory creates a new device project history record.
func (s *Service) insertProjectHistory(ctx context.Context, deviceUUID, projectID string, tx model.DBTxExecutor, logger *zap.Logger) error {
	history := models.DeviceProjectHistory{
		DeviceID:       deviceUUID,
		ProjectID:      projectID,
		CommissionedAt: time.Now(),
	}

	if err := history.Insert(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to insert device project history", zap.Error(err))
		return err
	}
	return nil
}

// decommissionCurrentProject marks the current project assignment as decommissioned.
func (s *Service) decommissionCurrentProject(ctx context.Context, deviceUUID, projectID string, tx model.DBTxExecutor, logger *zap.Logger) error {
	history, err := models.DeviceProjectHistories(
		models.DeviceProjectHistoryWhere.DeviceID.EQ(deviceUUID),
		models.DeviceProjectHistoryWhere.ProjectID.EQ(projectID),
	).One(ctx, tx)
	if err != nil {
		logger.Error("Failed to get device project history",
			zap.String("deviceUUID", deviceUUID),
			zap.String("projectID", projectID),
			zap.Error(err))
		return err
	}

	history.DecommissionedAt = null.NewTime(time.Now(), true)
	if _, err = history.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to decommission device project history", zap.Error(err))
		return err
	}
	return nil
}

// ---------------------------------------------------------------------------
// Write Operations
// ---------------------------------------------------------------------------

// Insert creates a new device record with associated ownership and project history.
func (s *Service) Insert(ctx context.Context, req *types.DeviceCreateRequest, accountID string, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error {
	// Create device record
	device := models.Device{
		DeviceID:        req.DeviceID,
		SerialNumber:    req.SerialNumber,
		Name:            null.NewString(req.DeviceName, req.DeviceName != ""),
		ModelName:       req.ModelName,
		ThingName:       req.DeviceID,
		MacAddress:      null.NewString(req.MacAddress, req.MacAddress != ""),
		IsPrimary:       null.NewBool(req.IsPrimary, true),
		CertificateID:   null.NewString(cert.ID, cert.ID != ""),
		CertificateArn:  null.NewString(cert.Arn, cert.Arn != ""),
		ClaimedBy:       null.NewString(accountID, accountID != ""),
		ClaimStatus:     "CLAIMED",
		ProjectID:       null.NewString(req.ProjectID, req.ProjectID != ""),
		FirmwareVersion: req.FirmwareVersion,
		DeviceZone:      null.NewString(req.DeviceZone, req.DeviceZone != ""),
		DeviceLocation:  null.NewString(req.DeviceLocation, req.DeviceLocation != ""),
	}

	if err := device.Insert(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to insert device", zap.String("deviceID", req.DeviceID), zap.Error(err))
		return err
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

// ClaimDevice claims an existing unclaimed device for a new owner.
func (s *Service) ClaimDevice(ctx context.Context, device models.Device, accountID string, cert types.CertificateInfo, req *types.DeviceCreateRequest, tx model.DBTxExecutor, logger *zap.Logger) error {
	// Update device with new claim details
	device.ProjectID = null.NewString(req.ProjectID, req.ProjectID != "")
	device.ClaimedBy = null.NewString(accountID, accountID != "")
	device.CertificateID = null.NewString(cert.ID, cert.ID != "")
	device.CertificateArn = null.NewString(cert.Arn, cert.Arn != "")
	device.ClaimStatus = "CLAIMED"
	device.DeviceZone = null.NewString(req.DeviceZone, req.DeviceZone != "")
	device.DeviceLocation = null.NewString(req.DeviceLocation, req.DeviceLocation != "")
	device.FirmwareVersion = req.FirmwareVersion
	device.IsPrimary = null.NewBool(req.IsPrimary, true)
	device.Name = null.NewString(req.DeviceName, req.DeviceName != "")

	if _, err := device.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to claim device", zap.String("deviceID", device.DeviceID), zap.Error(err))
		return err
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
		logger.Error("Failed to update device", zap.String("deviceID", device.DeviceID), zap.Error(err))
		return err
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
	).One(ctx, tx)
	if err != nil {
		logger.Error("Failed to get device ownership history", zap.Error(err))
		return err
	}

	ownerHistory.ReleasedAt = null.NewTime(time.Now(), true)
	if _, err = ownerHistory.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to update device ownership history", zap.Error(err))
		return err
	}

	// Decommission current project
	if err := s.decommissionCurrentProject(ctx, device.ID, device.ProjectID.String, tx, logger); err != nil {
		return err
	}

	// Clear device claim data
	device.ClaimStatus = "UNCLAIMED"
	device.ClaimedBy = null.NewString("", false)
	device.ProjectID = null.NewString("", false)
	device.CertificateID = null.NewString("", false)
	device.CertificateArn = null.NewString("", false)
	device.DeviceZone = null.NewString("", false)
	device.DeviceLocation = null.NewString("", false)
	device.FirmwareVersion = ""

	if _, err = device.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to reset device", zap.String("deviceID", device.DeviceID), zap.Error(err))
		return err
	}

	return nil
}

// Claim claims an existing unclaimed device for a new owner with the given project.
func (s *Service) Claim(ctx context.Context, device models.Device, accountID string, cert types.CertificateInfo, projectID string, tx model.DBTxExecutor, logger *zap.Logger) error {
	// Update device with claim details
	device.ProjectID = null.NewString(projectID, projectID != "")
	device.ClaimedBy = null.NewString(accountID, accountID != "")
	device.CertificateID = null.NewString(cert.ID, cert.ID != "")
	device.CertificateArn = null.NewString(cert.Arn, cert.Arn != "")
	device.ClaimStatus = "CLAIMED"

	if _, err := device.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to claim device", zap.String("deviceID", device.DeviceID), zap.Error(err))
		return err
	}

	// Create ownership history
	if err := s.insertOwnershipHistory(ctx, device.ID, accountID, cert.ID, cert.Arn, tx, logger); err != nil {
		return err
	}

	// Create project history
	if err := s.insertProjectHistory(ctx, device.ID, projectID, tx, logger); err != nil {
		return err
	}

	return nil
}

// UpdateCertificate updates the certificate information for a device.
func (s *Service) UpdateCertificate(ctx context.Context, device models.Device, cert types.CertificateInfo, tx model.DBTxExecutor, logger *zap.Logger) error {
	device.CertificateID = null.NewString(cert.ID, cert.ID != "")
	device.CertificateArn = null.NewString(cert.Arn, cert.Arn != "")

	if _, err := device.Update(ctx, tx, boil.Infer()); err != nil {
		logger.Error("Failed to update device certificate", zap.String("deviceID", device.DeviceID), zap.Error(err))
		return err
	}

	return nil
}

// InsertCommand inserts a new command into the device command history and publishes it to the device cluster topic.
// Returns the ID of the inserted command record.
func (s *Service) InsertCommand(ctx context.Context, projectID string, request *types.CommandRequest, logger *zap.Logger) (string, error) {

	// Marshal command request to JSON
	payload, err := json.Marshal(request)
	if err != nil {
		logger.Error("Failed to marshal command request", zap.Error(err))
		return "", err
	}

	// Insert command into database
	command := models.DeviceCommandHistory{
		ProjectID:      projectID,
		CommandName:    string(request.Command),
		CommandPayload: null.JSON{JSON: payload, Valid: true},
		Status:         "UNPUBLISHED",
		IssuedAt:       time.Now(),
	}

	if err := command.Insert(ctx, s.db, boil.Infer()); err != nil {
		logger.Error("Failed to insert command", zap.Error(err))
		return "", err
	}

	return command.ID, nil
}

// UpdateCommandStatus updates the status of a command in the device command history.
func (s *Service) UpdateCommandStatus(ctx context.Context, commandID string, status string, logger *zap.Logger) error {
	command, err := models.DeviceCommandHistories(models.DeviceCommandHistoryWhere.ID.EQ(commandID)).One(ctx, s.db)
	if err != nil {
		logger.Error("Failed to get command history", zap.String("commandID", commandID), zap.Error(err))
		return err
	}

	command.Status = status
	if _, err := command.Update(ctx, s.db, boil.Infer()); err != nil {
		logger.Error("Failed to update command status", zap.String("commandID", commandID), zap.Error(err))
		return err
	}

	return nil
}

// GetCommandStatus retrieves the status of a command by its ID.
// Returns nil, nil if the command is not found.
func (s *Service) GetCommandStatus(ctx context.Context, commandID string, logger *zap.Logger) (*models.DeviceCommandHistory, error) {
	command, err := models.DeviceCommandHistories(models.DeviceCommandHistoryWhere.ID.EQ(commandID)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		logger.Error("Failed to get command status", zap.String("commandID", commandID), zap.Error(err))
		return nil, err
	}
	return command, nil
}
