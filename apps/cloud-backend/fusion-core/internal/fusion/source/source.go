package source

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/storage/cloudfs"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
	"go.uber.org/zap"
)

// DatabaseService defines the interface for source database operations.
type DatabaseService interface {
	SelectAll(ctx context.Context, logger *zap.Logger) ([]types.SourceItemResponse, error)
}

// Service provides source business logic.
type Service struct {
	dbService DatabaseService
	presigner cloudfs.PresignHandle
	logger    *zap.Logger
}

// NewService creates a new source service.
func NewService(dbService DatabaseService, presigner cloudfs.PresignHandle, logger *zap.Logger) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	return &Service{
		dbService: dbService,
		presigner: presigner,
		logger:    logger,
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

	// Generate presigned URLs for asset paths
	if s.presigner != nil {
		for i := range sources {
			for j, assetMap := range sources[i].Assets {
				for color, paths := range assetMap {
					for k, path := range paths {
						if path != "" {
							url, err := s.presigner.PresignGet(ctx, path, constants.S3PresignedUrlTTL, logger)
							if err != nil {
								logger.Error("failed to generate presigned URL for source asset",
									zap.String("source_id", sources[i].SourceID),
									zap.String("asset_path", path),
									zap.Error(err))
								continue
							}
							sources[i].Assets[j][color][k] = url
						}
					}
				}
			}
		}
	}

	return sources, nil
}
