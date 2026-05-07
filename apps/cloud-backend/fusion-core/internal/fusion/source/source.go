package source

import (
	"context"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// DatabaseService defines the interface for source database operations.
type DatabaseService interface {
	SelectAll(ctx context.Context, logger *zap.Logger) ([]types.SourceItemResponse, error)
}

// Service provides source business logic.
type Service struct {
	dbService     DatabaseService
	sourceBaseURL string
}

// NewService creates a new source service.
func NewService(dbService DatabaseService, sourceBaseURL string, logger *zap.Logger) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	return &Service{
		dbService:     dbService,
		sourceBaseURL: strings.TrimRight(sourceBaseURL, "/"),
	}
}

// GetAllSources retrieves all sources.
func (s *Service) GetAllSources(ctx context.Context, logger *zap.Logger) ([]types.SourceItemResponse, error) {
	sources, err := s.dbService.SelectAll(ctx, logger)
	if err != nil {
		return nil, err
	}
	if sources == nil {
		return []types.SourceItemResponse{}, nil
	}

	// Build full public URLs from asset paths
	if s.sourceBaseURL != "" {
		for i := range sources {
			for j, assetMap := range sources[i].Assets {
				for color, paths := range assetMap {
					for k, path := range paths {
						if path != "" {
							sources[i].Assets[j][color][k] = s.sourceBaseURL + "/" + strings.TrimLeft(path, "/")
						}
					}
				}
			}
		}
	}

	return sources, nil
}
