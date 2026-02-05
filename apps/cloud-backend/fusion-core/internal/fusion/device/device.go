package device

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

func (s *Service) CreateDevice(ctx context.Context, request *types.DeviceCreateRequest, user types.UserAuthorizationResponse, logger *zap.Logger) (*types.DeviceCreateResponse, error) {
	// Decode the base64 encoded CSR
	// csrBytes, err := base64.StdEncoding.DecodeString(request.CSR)
	// if err != nil {
	// 	logger.Error("Failed to decode base64 CSR", zap.Error(err))
	// 	return nil, err
	// }
	// csrPem := string(csrBytes)

	certPem, _, certArn, err := s.iotService.CreateCertificateFromCsr(ctx, &request.CSR, logger)
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


	err = s.dbService.Insert(ctx, request, user.Account.ID, logger)
	if err != nil {
		logger.Error("Failed to insert device into database", zap.Error(err))
		return nil, err
	}

	return &types.DeviceCreateResponse{
		Certificate: *certPem,
	}, nil
}
