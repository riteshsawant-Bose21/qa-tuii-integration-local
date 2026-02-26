package device

import (
	"context"
	"errors"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"go.uber.org/zap"
)

// ---------------------------------------------------------------------------
// Transaction Helper
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

// ---------------------------------------------------------------------------
// Device Operations
// ---------------------------------------------------------------------------

// CreateDevice registers a new device or claims an existing unclaimed device.
func (s *Service) CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error) {
	// Check if device already exists
	device, err := s.dbService.GetDeviceByID(ctx, request.DeviceID, logger)
	if err != nil {
		return nil, err
	}

	// Validate project access
	project, err := s.dbService.GetProjectByID(ctx, request.ProjectID, logger)
	if err != nil {
		return nil, err
	}
	if project == nil {
		logger.Error("Project not found", zap.String("projectID", request.ProjectID))
		return nil, errors.New(errorutil.ErrMsgProjectNotFound)
	}
	if project.PrimaryOwnerAccountID != user.Account.ID {
		logger.Error("User does not have access to the project",
			zap.String("projectID", request.ProjectID),
			zap.String("accountID", user.Account.ID))
		return nil, errors.New(errorutil.MsgUnauthorized)
	}

	// Check if device is already claimed
	if device != nil && device.ClaimStatus == "CLAIMED" {
		logger.Error("Device already claimed, reset to reclaim",
			zap.String("deviceID", request.DeviceID))
		return nil, errors.New(errorutil.ErrMsgDeviceAlreadyExists)
	}

	// Create IoT certificate
	certPem, certID, certArn, err := s.iotService.CreateCertificateFromCsr(ctx, &request.CSR, logger)
	if err != nil {
		logger.Error("Failed to create certificate from CSR", zap.Error(err))
		return nil, err
	}

	cert := types.CertificateInfo{ID: *certID, Arn: *certArn}

	// Register new thing in IoT if device doesn't exist
	if device == nil {
		if err := s.iotService.RegisterThing(ctx, request.DeviceID, logger); err != nil {
			logger.Error("Failed to register thing", zap.Error(err))
			return nil, err
		}
	}

	// Attach certificate and policy to thing
	if err := s.iotService.AttachCertificateToThing(ctx, request.DeviceID, *certArn, logger); err != nil {
		logger.Error("Failed to attach certificate to thing", zap.Error(err))
		return nil, err
	}
	if err := s.iotService.AttachPolicyToCertificate(ctx, "testdevicepolicy", *certArn, logger); err != nil {
		logger.Error("Failed to attach policy to certificate", zap.Error(err))
		return nil, err
	}

	// Persist device in database
	err = s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		if device == nil {
			return s.dbService.Insert(ctx, request, user.Account.ID, cert, tx, logger)
		}
		return s.dbService.ClaimDevice(ctx, *device, user.Account.ID, cert, request, tx, logger)
	})
	if err != nil {
		return nil, err
	}

	return &types.DeviceCreateResponse{Certificate: *certPem}, nil
}

// UpdateDevice modifies mutable fields of an existing device.
func (s *Service) UpdateDevice(ctx context.Context, deviceID string, request *types.DeviceUpdateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	// Fetch and validate device
	device, err := s.dbService.GetDeviceByID(ctx, deviceID, logger)
	if err != nil {
		return err
	}
	if device == nil {
		logger.Error("Device not found", zap.String("deviceID", deviceID))
		return errors.New(errorutil.ErrMsgDeviceNotFound)
	}

	// Verify ownership
	if device.ClaimedBy.String != user.Account.ID {
		logger.Error("Unauthorized update attempt",
			zap.String("deviceID", deviceID),
			zap.String("accountID", user.Account.ID))
		return errors.New(errorutil.MsgUnauthorized)
	}

	// Perform update in transaction
	return s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		return s.dbService.Update(ctx, *device, request, tx, logger)
	})
}

// ResetDevice releases a device from its owner and revokes IoT credentials.
func (s *Service) ResetDevice(ctx context.Context, deviceID string, user types.UserAuthorizationResponse, logger *zap.Logger) error {
	// Fetch and validate device
	device, err := s.dbService.GetDeviceByID(ctx, deviceID, logger)
	if err != nil {
		return err
	}
	if device == nil {
		logger.Error("Device not found", zap.String("deviceID", deviceID))
		return errors.New(errorutil.ErrMsgDeviceNotFound)
	}

	if device.ClaimStatus != "CLAIMED" {
		logger.Info("Device is not claimed, cannot reset",
			zap.String("deviceID", deviceID),
			zap.String("claimStatus", device.ClaimStatus))
		return nil
	}

	// Revoke IoT credentials
	if err := s.iotService.SetCertificateInactive(ctx, device.CertificateID.String, logger); err != nil {
		logger.Error("Failed to set certificate inactive",
			zap.String("certificateID", device.CertificateID.String),
			zap.Error(err))
		return err
	}
	if err := s.iotService.DetatchCertificateFromThing(ctx, deviceID, device.CertificateArn.String, logger); err != nil {
		logger.Error("Failed to detach certificate from thing", zap.Error(err))
		return err
	}
	if err := s.iotService.DetatchPolicyFromCertificate(ctx, "testdevicepolicy", device.CertificateArn.String, logger); err != nil {
		logger.Error("Failed to detach policy from certificate", zap.Error(err))
		return err
	}

	// Reset device in database
	return s.withTransaction(ctx, logger, func(tx model.DBTxExecutor) error {
		return s.dbService.Reset(ctx, *device, tx, logger)
	})
}
