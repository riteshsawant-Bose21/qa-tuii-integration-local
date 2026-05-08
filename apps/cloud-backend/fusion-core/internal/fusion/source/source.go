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
	dbService    DatabaseService
	AssetBaseURL string
}

// NewService creates a new source service.
func NewService(dbService DatabaseService, assetBaseURL string, logger *zap.Logger) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	return &Service{
		dbService:    dbService,
		AssetBaseURL: strings.TrimRight(assetBaseURL, "/"),
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
	if s.AssetBaseURL != "" {
		for i := range sources {
			if len(sources[i].Assets) > 0 {
				asset := &sources[i].Assets[0]
				if len(asset.Black) > 0 && asset.Black[0] != "" {
					asset.Black[0] = s.AssetBaseURL + "/" + strings.TrimLeft(asset.Black[0], "/")
				}
				if len(asset.White) > 0 && asset.White[0] != "" {
					asset.White[0] = s.AssetBaseURL + "/" + strings.TrimLeft(asset.White[0], "/")
				}
			}
		}
	}

	return sources, nil
}
