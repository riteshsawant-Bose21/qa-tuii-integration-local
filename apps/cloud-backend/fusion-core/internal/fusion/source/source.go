package source

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// DatabaseService defines the interface for source database operations.
type DatabaseService interface {
	SelectAll(ctx context.Context, logger *zap.Logger) ([]types.SourceItem, error)
}

// Service provides source business logic.
type Service struct {
	dbService DatabaseService
	logger    *zap.Logger
}

// NewService creates a new source service.
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

// GetAllSources retrieves all sources.
func (s *Service) GetAllSources(ctx context.Context, logger *zap.Logger) ([]types.SourceItem, error) {
	return s.dbService.SelectAll(ctx, logger)
}
