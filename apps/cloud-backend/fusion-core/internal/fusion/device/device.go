package device

import (
	"context"
	"errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"go.uber.org/zap"
)

func (s *Service) CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error) {

	device, err := s.dbService.GetDeviceByID(ctx, request.DeviceID, logger)
	if err != nil {
		logger.Error("Failed to get device by ID", zap.String("deviceID", request.DeviceID), zap.Error(err))
		return nil, err
	}

	if device != nil {
		logger.Error("Device already exists", zap.String("deviceID", request.DeviceID))
		return nil, errors.New(errorutil.ErrMsgDeviceAlreadyExists)
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
