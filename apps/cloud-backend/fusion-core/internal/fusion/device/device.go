package device

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// ---------------------------------------------------------------------------
// Helper Functions
// ---------------------------------------------------------------------------

// withTransaction executes a function within a database transaction.
// It handles begin, commit, and rollback automatically.
func (s *Service) withTransaction(ctx context.Context, logger *zap.Logger, fn func(tx model.DBTxExecutor) error) error {
	db := s.dbService.GetDB(ctx)
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		logger.Error("Failed to begin transaction", zap.Error(err))
		return fmt.Errorf("failed to begin transaction: %w", err)
	}

	if err := fn(tx); err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			logger.Error("Failed to rollback transaction", zap.Error(rollbackErr))
		}
		return err
	}

	if err := tx.Commit(); err != nil {
		logger.Error("Failed to commit transaction", zap.Error(err))
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

// validateProjectAccess validates that a project exists and the user has access to it.
func (s *Service) validateProjectAccess(ctx context.Context, projectID, accountID string, logger *zap.Logger) (*models.Project, error) {
	project, err := s.projectService.GetProjectByID(ctx, projectID, logger)
	if err != nil {
		return nil, err
	}
	if project == nil {
		logger.Error("Project not found", zap.String("projectID", projectID))
		return nil, errors.New(errorutil.ErrMsgProjectNotFound)
	}
	if project.PrimaryOwnerAccountID != accountID {
		logger.Error("User does not have access to the project",
			zap.String("projectID", projectID),
			zap.String("accountID", accountID))
		return nil, errors.New(errorutil.MsgUnauthorized)
	}
	return project, nil
}

// cleanupIoTResources attempts to clean up IoT resources on failure.
// This is a best-effort cleanup - errors are logged but not returned.
// If deleteThing is true, also deletes the thing from IoT (only for newly registered things).
func (s *Service) cleanupIoTResources(ctx context.Context, deviceID, certID, certArn string, deleteThing bool, logger *zap.Logger) {
	if err := s.iotService.SetCertificateInactive(ctx, certID, logger); err != nil {
		logger.Warn("Failed to cleanup: set certificate inactive",
			zap.String("certificateID", certID),
			zap.Error(err))
	}

	if err := s.iotService.DetachCertificateFromThing(ctx, deviceID, certArn, logger); err != nil {
		logger.Warn("Failed to cleanup: detach certificate from thing",
			zap.String("deviceID", deviceID),
			zap.Error(err))
	}

	if err := s.iotService.DetachPolicyFromCertificate(ctx, s.cfg.IoTDevicePolicy, certArn, logger); err != nil {
		logger.Warn("Failed to cleanup: detach policy from certificate",
			zap.String("certificateArn", certArn),
			zap.Error(err))
	}

	if deleteThing {
		if err := s.iotService.DeleteThing(ctx, deviceID, logger); err != nil {
			logger.Warn("Failed to cleanup: delete thing",
				zap.String("deviceID", deviceID),
				zap.Error(err))
		}
	}
}

// revokeOldCertificate revokes an existing certificate. Errors are logged as warnings
// since the new certificate is already active and this is best-effort cleanup.
func (s *Service) revokeOldCertificate(ctx context.Context, deviceID, certID, certArn string, logger *zap.Logger) {
	if err := s.iotService.SetCertificateInactive(ctx, certID, logger); err != nil {
		logger.Warn("Failed to set old certificate inactive (non-critical)",
			zap.String("certificateID", certID),
			zap.Error(err))
	}

	if err := s.iotService.DetachCertificateFromThing(ctx, deviceID, certArn, logger); err != nil {
		logger.Warn("Failed to detach old certificate from thing (non-critical)",
			zap.String("deviceID", deviceID),
			zap.Error(err))
	}

	if err := s.iotService.DetachPolicyFromCertificate(ctx, s.cfg.IoTDevicePolicy, certArn, logger); err != nil {
		logger.Warn("Failed to detach policy from old certificate (non-critical)",
			zap.String("certificateArn", certArn),
			zap.Error(err))
	}
}

// setupDeviceCertificate creates and attaches a certificate for a device.
// Returns the certificate info, or cleans up and returns an error.
// If deleteThingOnFailure is true, the thing will be deleted on cleanup.
func (s *Service) setupDeviceCertificate(ctx context.Context, deviceID string, csr *string, deleteThingOnFailure bool, logger *zap.Logger) (*string, types.CertificateInfo, error) {
	certPem, certID, certArn, err := s.iotService.CreateCertificateFromCSR(ctx, csr, logger)
	if err != nil {
		if deleteThingOnFailure {
			if cleanupErr := s.iotService.DeleteThing(ctx, deviceID, logger); cleanupErr != nil {
				logger.Warn("Failed to cleanup thing after certificate creation failure",
					zap.String("deviceID", deviceID),
					zap.Error(cleanupErr))
			}
		}
		return nil, types.CertificateInfo{}, err
	}

	cert := types.CertificateInfo{ID: *certID, Arn: *certArn}

	if err := s.iotService.AttachCertificateToThing(ctx, deviceID, *certArn, logger); err != nil {
		// Only cert exists at this point - just mark it inactive
		if err := s.iotService.SetCertificateInactive(ctx, *certID, logger); err != nil {
			logger.Warn("Failed to set certificate inactive after attach failure",
				zap.String("certificateID", *certID),
				zap.Error(err))
		}
		if deleteThingOnFailure {
			if err := s.iotService.DeleteThing(ctx, deviceID, logger); err != nil {
				logger.Warn("Failed to cleanup thing after certificate attach failure",
					zap.String("deviceID", deviceID),
					zap.Error(err))
			}
		}
		return nil, types.CertificateInfo{}, err
	}

	if err := s.iotService.AttachPolicyToCertificate(ctx, s.cfg.IoTDevicePolicy, *certArn, logger); err != nil {
		// Cert is attached to thing - full cleanup needed
		s.cleanupIoTResources(ctx, deviceID, *certID, *certArn, deleteThingOnFailure, logger)
		return nil, types.CertificateInfo{}, err
	}

	return certPem, cert, nil
}

// ---------------------------------------------------------------------------
// Device Operations
// ---------------------------------------------------------------------------

// CreateDevice registers a new device or claims an existing unclaimed device.
func (s *Service) CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error) {
	// Check if device already exists
	device, err := s.dbService.GetDeviceByID(ctx, request.SerialNumber, logger)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}

	// Check if device is already claimed
	if device != nil && device.ClaimStatus == models.ClaimStatusEnumCLAIMED {
		logger.Error("Device already claimed, reset to reclaim",
			zap.String("deviceID", request.SerialNumber))
		return nil, errors.New(errorutil.ErrMsgDeviceAlreadyExists)
	}

	// Validate project access
	if _, err := s.validateProjectAccess(ctx, request.ProjectID, user.Account.ID, logger); err != nil {
		return nil, err
	}

	// Register new thing in IoT if device doesn't exist
	deleteThingOnFailure := false
	if device == nil {
		if err := s.iotService.RegisterThing(ctx, request.SerialNumber, logger); err != nil {
			return nil, err
		}
		deleteThingOnFailure = true
	}

	// Setup certificate (creates, attaches to thing, attaches policy)
	certPem, cert, err := s.setupDeviceCertificate(ctx, request.SerialNumber, &request.CSR, deleteThingOnFailure, logger)
	if err != nil {
		return nil, err
	}

	// Persist device in database
	err = s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		if device == nil {
			return s.dbService.Insert(ctx, request, user.Account.ID, cert, tx, logger)
		}

		return s.dbService.ClaimDevice(ctx, *device, user.Account.ID, cert, &types.DeviceClaimRequest{
			ProjectID:       request.ProjectID,
			DeviceName:      request.DeviceName,
			ClientDeviceID:  request.ClientDeviceID,
			DeviceZone:      request.DeviceZone,
			DeviceLocation:  request.DeviceLocation,
			IsPrimary:       &request.IsPrimary,
			FirmwareVersion: request.FirmwareVersion,
		}, tx, logger)
	})

	if err != nil {
		logger.Warn("Database transaction failed, cleaning up IoT resources",
			zap.String("deviceID", request.SerialNumber))
		s.cleanupIoTResources(ctx, request.SerialNumber, cert.ID, cert.Arn, deleteThingOnFailure, logger)
		return nil, err
	}

	return &types.DeviceCreateResponse{Certificate: *certPem}, nil
}

// BulkCreateDevices creates multiple devices in a single request.
// Each device is processed independently; partial failures are captured per-device.
func (s *Service) BulkCreateDevices(ctx context.Context, request *types.BulkDeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.BulkDeviceCreateResponse, error) {
	results := make([]types.BulkDeviceCreateResult, 0, len(request.Devices))

	for i := range request.Devices {
		deviceReq := &request.Devices[i]

		res, err := s.CreateDevice(ctx, deviceReq, user, logger)
		if err != nil {
			errMsg := err.Error()
			results = append(results, types.BulkDeviceCreateResult{
				DeviceID:  deviceReq.SerialNumber,
				ProjectID: deviceReq.ProjectID,
				Success:   false,
				Error:     &errMsg,
			})
			continue
		}

		results = append(results, types.BulkDeviceCreateResult{
			DeviceID:    deviceReq.SerialNumber,
			ProjectID:   deviceReq.ProjectID,
			Certificate: &res.Certificate,
			Success:     true,
		})
	}

	return &types.BulkDeviceCreateResponse{Results: results}, nil
}

// UpdateDevice modifies mutable fields of an existing device.
func (s *Service) UpdateDevice(ctx context.Context, deviceID string, request *types.DeviceUpdateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	device, err := s.dbService.GetDeviceByID(ctx, deviceID, logger)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			logger.Error("Device not found", zap.String("deviceID", deviceID))
			return errors.New(errorutil.ErrMsgDeviceNotFound)
		}
		return err
	}

	// Verify ownership
	if device.ClaimedBy.String != user.Account.ID {
		logger.Error("Unauthorized update attempt",
			zap.String("deviceID", deviceID),
			zap.String("accountID", user.Account.ID))
		return errors.New(errorutil.MsgUnauthorized)
	}

	// Validate project change if requested
	if request.ProjectID != "" && device.ProjectID.String != request.ProjectID {
		if _, err := s.validateProjectAccess(ctx, request.ProjectID, user.Account.ID, logger); err != nil {
			return err
		}
	}

	return s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		return s.dbService.Update(ctx, *device, request, tx, logger)
	})
}

// ResetDevice releases a device from its owner and revokes IoT credentials.
func (s *Service) ResetDevice(ctx context.Context, deviceID string, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	device, err := s.dbService.GetDeviceByID(ctx, deviceID, logger)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			logger.Error("Device not found", zap.String("deviceID", deviceID))
			return errors.New(errorutil.ErrMsgDeviceNotFound)
		}
		return err
	}

	if device.ClaimStatus != models.ClaimStatusEnumCLAIMED {
		logger.Info("Device is not claimed, nothing to reset",
			zap.String("deviceID", deviceID))
		return nil
	}

	// Verify ownership before allowing reset
	if device.ClaimedBy.String != user.Account.ID {
		logger.Error("Unauthorized reset attempt",
			zap.String("deviceID", deviceID),
			zap.String("accountID", user.Account.ID))
		return errors.New(errorutil.MsgUnauthorized)
	}

	// Revoke IoT credentials
	if err := s.iotService.SetCertificateInactive(ctx, device.CertificateID.String, logger); err != nil {
		return err
	}
	if err := s.iotService.DetachCertificateFromThing(ctx, deviceID, device.CertificateArn.String, logger); err != nil {
		return err
	}
	if err := s.iotService.DetachPolicyFromCertificate(ctx, s.cfg.IoTDevicePolicy, device.CertificateArn.String, logger); err != nil {
		return err
	}

	return s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		return s.dbService.Reset(ctx, *device, tx, logger)
	})
}

// ClaimDevice claims an existing unclaimed device for a user and project.
func (s *Service) ClaimDevice(ctx context.Context, deviceID string, request *types.DeviceClaimRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceClaimResponse, error) {
	device, err := s.dbService.GetDeviceByID(ctx, deviceID, logger)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			logger.Error("Device not found", zap.String("deviceID", deviceID))
			return nil, errors.New(errorutil.ErrMsgDeviceNotFound)
		}
		return nil, err
	}

	if device.ClaimStatus == models.ClaimStatusEnumCLAIMED {
		logger.Error("Device is already claimed",
			zap.String("deviceID", deviceID))
		return nil, errors.New(errorutil.ErrMsgDeviceAlreadyClaimed)
	}

	if _, err := s.validateProjectAccess(ctx, request.ProjectID, user.Account.ID, logger); err != nil {
		return nil, err
	}

	// Setup certificate (thing already exists for unclaimed device)
	certPem, cert, err := s.setupDeviceCertificate(ctx, deviceID, &request.CSR, false, logger)
	if err != nil {
		return nil, err
	}

	err = s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		return s.dbService.ClaimDevice(ctx, *device, user.Account.ID, cert, request, tx, logger)
	})
	if err != nil {
		logger.Warn("Database transaction failed, cleaning up IoT resources",
			zap.String("deviceID", deviceID))
		s.cleanupIoTResources(ctx, deviceID, cert.ID, cert.Arn, false, logger)
		return nil, err
	}

	return &types.DeviceClaimResponse{Certificate: *certPem}, nil
}

// RotateCertificate creates a new certificate for a device, attaches it, and marks the old one as inactive.
func (s *Service) RotateCertificate(ctx context.Context, deviceID string, request *types.DeviceRotateCertRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceRotateCertResponse, error) {
	device, err := s.dbService.GetDeviceByID(ctx, deviceID, logger)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			logger.Error("Device not found", zap.String("deviceID", deviceID))
			return nil, errors.New(errorutil.ErrMsgDeviceNotFound)
		}
		return nil, err
	}

	if device.ClaimStatus != models.ClaimStatusEnumCLAIMED {
		logger.Error("Device is not claimed, cannot rotate certificate",
			zap.String("deviceID", deviceID))
		return nil, errors.New(errorutil.ErrMsgDeviceNotClaimed)
	}

	if device.ClaimedBy.String != user.Account.ID {
		logger.Error("Unauthorized certificate rotation attempt",
			zap.String("deviceID", deviceID),
			zap.String("accountID", user.Account.ID))
		return nil, errors.New(errorutil.MsgUnauthorized)
	}

	// Store old certificate info for cleanup after successful rotation
	oldCertID := device.CertificateID.String
	oldCertArn := device.CertificateArn.String

	// Setup new certificate (device temporarily has both certs)
	certPem, newCert, err := s.setupDeviceCertificate(ctx, deviceID, &request.CSR, false, logger)
	if err != nil {
		return nil, err
	}

	// Update device in database with new certificate BEFORE deactivating old cert.
	// This ensures if DB fails, old cert remains active and device still works.
	err = s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		return s.dbService.UpdateCertificate(ctx, *device, newCert, tx, logger)
	})
	if err != nil {
		logger.Warn("Database transaction failed, cleaning up new IoT resources",
			zap.String("deviceID", deviceID))
		s.cleanupIoTResources(ctx, deviceID, newCert.ID, newCert.Arn, false, logger)
		return nil, err
	}

	// DB succeeded - now safe to revoke old certificate
	s.revokeOldCertificate(ctx, deviceID, oldCertID, oldCertArn, logger)

	return &types.DeviceRotateCertResponse{Certificate: *certPem}, nil
}

// Command sends a command to a device via IoT topic publish.
func (s *Service) Command(ctx context.Context, request *types.CommandRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (string, error) {
	// Validate project access
	if _, err := s.validateProjectAccess(ctx, request.ProjectID, user.Account.ID, logger); err != nil {
		return "", err
	}
	commandID := uuid.New().String()

	err := s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {

		insertErr := s.dbService.InsertCommand(ctx, request.ProjectID, commandID, request, logger)
		if insertErr != nil {
			return fmt.Errorf("failed to insert command into database: %w", insertErr)
		}
		return nil
	})

	if err != nil {
		return "", err
	}

	deviceCommand := struct {
		Command types.CommandRequest `json:"command"`
		ID      string               `json:"id"`
	}{
		Command: *request,
		ID:      commandID, // ID can be set by the device if needed
	}

	requestBytes, err := json.Marshal(deviceCommand)
	if err != nil {
		logger.Error("Failed to marshal command request", zap.Error(err))
		return "", fmt.Errorf("failed to marshal command request: %w", err)
	}

	topic := strings.ReplaceAll(s.cfg.IoTCommandTopic, "{projectID}", request.ProjectID)

	err = s.iotService.Publish(ctx, topic, requestBytes, logger)
	if err != nil {
		return "", fmt.Errorf("failed to publish command: %w", err)
	}

	err = s.dbService.UpdateCommandStatus(ctx, commandID, models.CommandStatusEnumPUBLISHED, logger)
	if err != nil {
		return "", fmt.Errorf("failed to update command status: %w", err)
	}

	return commandID, nil
}

// GetCommandStatus retrieves the status of a command by its ID.
func (s *Service) GetCommandStatus(ctx context.Context, commandID string, logger *zap.Logger) (*types.CommandStatusResponse, error) {
	commands, err := s.dbService.GetCommandStatus(ctx, commandID, logger)
	if err != nil {
		return nil, err
	}
	if commands == nil || len(*commands) == 0 {
		logger.Error("Command not found", zap.String("commandID", commandID))
		return nil, errors.New(errorutil.ErrMsgCommandNotFound)
	}

	var results []types.CommandStatusResult
	for _, command := range *commands {
		results = append(results, types.CommandStatusResult{
			CommandID:   command.CommandID,
			CommandName: command.CommandName,
			DeviceID:    command.DeviceID.String,
			Status:      command.Status,
			IssuedAt:    command.IssuedAt.Format("2006-01-02T15:04:05Z07:00"),
			UpdatedAt:   command.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	return &types.CommandStatusResponse{Results: results}, nil
}
