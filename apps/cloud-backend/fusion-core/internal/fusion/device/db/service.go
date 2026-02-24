package db

import (
	"context"
	"database/sql"
	"errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"go.uber.org/zap"
)

// Service is a service for managing projects in the database.
type Service struct {
	db model.DBWithTransactions
}

// NewService creates a new database service.
func NewService(db model.DBWithTransactions) *Service {
	if db == nil {
		panic("db cannot be nil")
	}

	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

// GetDeviceByID retrieves a device by its ID from the database.
func (s *Service) GetDeviceByID(ctx context.Context, deviceID string, logger *zap.Logger) (*models.Device, error) {
	device, err := models.Devices(models.DeviceWhere.DeviceID.EQ(deviceID)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// Row not found, return nil, nil
			return nil, nil
		}
		logger.Error("Failed to get device by ID", zap.String("deviceID", deviceID), zap.Error(err))
		return nil, err
	}

	return device, nil
}

func (s *Service) GetProjectByID(ctx context.Context, projectID string, logger *zap.Logger) (*models.Project, error) {
	project, err := models.Projects(models.ProjectWhere.ID.EQ(projectID)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			// Row not found, return nil, nil
			return nil, nil
		}
		logger.Error("Failed to get project by ID", zap.String("projectID", projectID), zap.Error(err))
		return nil, err
	}

	return project, nil
}

// Insert inserts a new device into the database.
func (s *Service) Insert(ctx context.Context, req *types.DeviceCreateRequest, accountID string, certID *string, logger *zap.Logger) error {

	device := models.Device{
		DeviceID:        req.DeviceID,
		SerialNumber:    req.SerialNumber,
		Name:            null.NewString(req.DeviceName, req.DeviceName != ""),
		ModelName:       req.ModelName,
		ThingName:       req.DeviceID,
		MacAddress:      null.NewString(req.MacAddress, req.MacAddress != ""),
		CertificateID:   *certID,
		ClaimedBy:       accountID,
		ClaimStatus:     "CLAIMED",
		ProjectID:       req.ProjectID,
		FirmwareVersion: req.FirmwareVersion,
		DeviceZone:      null.NewString(req.DeviceZone, req.DeviceZone != ""),
		DeviceLocation:  null.NewString(req.DeviceLocation, req.DeviceLocation != ""),
		Timezone:        null.NewString(req.Timezone, req.Timezone != ""),
		DSTEnabled:      null.NewBool(req.DstEnabled, req.DstEnabled),
		NTPEnabled:      null.NewBool(req.NtpEnabled, req.NtpEnabled),
		NTPServer:       null.NewString(req.NtpServer, req.NtpServer != ""),
	}

	err := device.Insert(ctx, s.db, boil.Infer())

	if err != nil {
		logger.Error("Failed to insert device into database", zap.Error(err))
		return err
	}

	return nil
}

// Update updates an existing device in the database.
func (s *Service) Update(ctx context.Context, device models.Device, req *types.DeviceUpdateRequest, logger *zap.Logger) error {

	// Update only non-static fields
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
	if req.Timezone != "" {
		device.Timezone = null.NewString(req.Timezone, true)
	}
	if req.DstEnabled != nil {
		device.DSTEnabled = null.NewBool(*req.DstEnabled, true)
	}
	if req.NtpEnabled != nil {
		device.NTPEnabled = null.NewBool(*req.NtpEnabled, true)
	}
	if req.NtpServer != "" {
		device.NTPServer = null.NewString(req.NtpServer, true)
	}

	// If project ID is being updated, verify that the new project exists and belongs to the same account as the device
	if req.ProjectID != "" && device.ProjectID != req.ProjectID {
		project, err := models.Projects(models.ProjectWhere.ID.EQ(req.ProjectID)).One(ctx, s.db)
		if err != nil {
			logger.Error("Failed to get project by ID", zap.String("projectID", req.ProjectID), zap.Error(err))
			return errors.New(errorutil.ErrMsgProjectNotFound)
		}

		if project.PrimaryOwnerAccountID != device.ClaimedBy {
			logger.Error("Unauthorized project change attempt", zap.String("deviceID", device.DeviceID), zap.String("accountID", device.ClaimedBy), zap.String("newProjectID", req.ProjectID))
			return errors.New(errorutil.MsgUnauthorized)
		}

		device.ProjectID = req.ProjectID
	}

	_, err := device.Update(ctx, s.db, boil.Infer())
	if err != nil {
		logger.Error("Failed to update device in database", zap.Error(err))
		return err
	}

	return nil
}
