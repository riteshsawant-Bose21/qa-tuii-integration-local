package output

import (
	"context"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// DatabaseService defines the interface for output table operations.
type DatabaseService interface {
	SelectAll(ctx context.Context, logger *zap.Logger) ([]types.OutputItemResponse, error)
}

// Service provides output business logic.
type Service struct {
	dbService    DatabaseService
	AssetBaseURL string
}

// NewService creates a new output service.
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

// GetAllOutputs retrieves all outputs.
func (s *Service) GetAllOutputs(ctx context.Context, logger *zap.Logger) ([]types.OutputItemResponse, error) {
	outputs, err := s.dbService.SelectAll(ctx, logger)
	if err != nil {
		return nil, err
	}
	if outputs == nil {
		return []types.OutputItemResponse{}, nil
	}

	// Build full public URLs from asset paths
	if s.AssetBaseURL != "" {
		for i := range outputs {
			if len(outputs[i].Assets) > 0 {
				asset := &outputs[i].Assets[0]
				if len(asset.Black) > 0 && asset.Black[0] != "" {
					asset.Black[0] = s.AssetBaseURL + "/" + strings.TrimLeft(asset.Black[0], "/")
				}
				if len(asset.White) > 0 && asset.White[0] != "" {
					asset.White[0] = s.AssetBaseURL + "/" + strings.TrimLeft(asset.White[0], "/")
				}
			}
		}
	}

	return outputs, nil
}
