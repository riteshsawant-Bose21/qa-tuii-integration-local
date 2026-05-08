package output

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// DatabaseService defines the interface for output table operations.
type DatabaseService interface {
	SelectAll(ctx context.Context, logger *zap.Logger) ([]types.OutputItemResponse, error)
}

// Service provides output business logic.
type Service struct {
	dbService DatabaseService
	logger    *zap.Logger
}

// NewService creates a new output service.
func NewService(dbService DatabaseService, logger *zap.Logger) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	return &Service{
		dbService: dbService,
		logger:    logger,
	}
}

// GetAllOutputs retrieves all outputs.
func (s *Service) GetAllOutputs(ctx context.Context, logger *zap.Logger) ([]types.OutputItemResponse, error) {
	outputs, err := s.dbService.SelectAll(ctx, logger)
	if err != nil {
		return nil, err
	}
	if outputs == nil {
		return []types.OutputItemResponse{}, nil
	}
	return outputs, nil
}
