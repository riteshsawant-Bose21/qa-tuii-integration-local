package device

import (
	"context"
	"database/sql"
	"errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"go.uber.org/zap"
)

// CreateDevice creates a new device in the system.
func (s *Service) CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error) {

	device, err := s.dbService.GetDeviceByID(ctx, request.DeviceID, logger)
	if err != nil {
		logger.Error("Failed to get device by ID", zap.String("deviceID", request.DeviceID), zap.Error(err))
		return nil, err
	}

	// Check if the project exists and if the user has access to it
	project, err := s.dbService.GetProjectByID(ctx, request.ProjectID, logger)
	if err != nil {
		logger.Error("Failed to get project by ID", zap.String("projectID", request.ProjectID), zap.Error(err))
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New(errorutil.ErrMsgProjectNotFound)
		}

		return nil, err
	}

	if project.PrimaryOwnerAccountID != user.Account.ID {
		logger.Error("Unauthorized device creation attempt, user does not have access to the project", zap.String("projectID", request.ProjectID), zap.String("accountID", user.Account.ID))
		return nil, errors.New(errorutil.MsgUnauthorized)
	}

	if device != nil {
		if device.ClaimStatus == "CLAIMED" {
			logger.Error("Device already exists", zap.String("deviceID", request.DeviceID))
			return nil, errors.New(errorutil.ErrMsgDeviceAlreadyExists)
		}
	}

	certPem, certID, certArn, err := s.iotService.CreateCertificateFromCsr(ctx, &request.CSR, logger)
	if err != nil {
		logger.Error("Failed to create certificate from CSR", zap.Error(err))
		return nil, err
	}

	err = s.iotService.RegisterThing(ctx, request.DeviceID, logger)
	if err != nil {
		logger.Error("Failed to register thing", zap.Error(err))
		return nil, err
	}

	err = s.iotService.AttachCertificateToThing(ctx, request.DeviceID, *certArn, logger)
	if err != nil {
		logger.Error("Failed to attach certificate to thing", zap.Error(err))
		return nil, err
	}

	err = s.iotService.AttachPolicyToCertificate(ctx, "testdevicepolicy", *certArn, logger)
	if err != nil {
		logger.Error("Failed to attach policy to certificate", zap.Error(err))
		return nil, err
	}

	err = s.dbService.Insert(ctx, request, user.Account.ID, certID, logger)
	if err != nil {
		logger.Error("Failed to insert device into database", zap.Error(err))
		return nil, err
	}

	return &types.DeviceCreateResponse{
		Certificate: *certPem,
	}, nil
}

// UpdateDevice updates an existing device in the system.
func (s *Service) UpdateDevice(ctx context.Context, deviceID string, request *types.DeviceUpdateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) error {

	device, err := s.dbService.GetDeviceByID(ctx, deviceID, logger)
	if err != nil {
		logger.Error("Failed to get device by ID", zap.String("deviceID", deviceID), zap.Error(err))
		if errors.Is(err, sql.ErrNoRows) {
			return errors.New(errorutil.ErrMsgDeviceNotFound)
		}
		return err
	}

	if device.ClaimedBy != user.Account.ID {
		logger.Error("Unauthorized update attempt", zap.String("deviceID", deviceID), zap.String("accountID", user.Account.ID))
		return errors.New(errorutil.MsgUnauthorized)
	}

	err = s.dbService.Update(ctx, *device, request, logger)
	if err != nil {
		logger.Error("Failed to update device", zap.String("deviceID", deviceID), zap.Error(err))
		return err
	}

	return nil
}
