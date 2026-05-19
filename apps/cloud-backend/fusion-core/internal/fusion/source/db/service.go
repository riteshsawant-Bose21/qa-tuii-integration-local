package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// Service provides database operations for the source table.
type Service struct {
	db *sql.DB
}

// NewService creates a new source database service.
func NewService(db *sql.DB, logger *zap.Logger) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	return &Service{
		db: db,
	}
}

// SelectAll retrieves all sources from the database.
func (s *Service) SelectAll(ctx context.Context, logger *zap.Logger) ([]types.SourceItemResponse, error) {
	query := `SELECT id, model_name, images, model_family, description, specifications, is_fusion_compatible FROM source ORDER BY model_name`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		logger.Error("failed to query sources", zap.Error(err))
		return nil, fmt.Errorf("failed to query sources: %w", err)
	}

	defer func() { _ = rows.Close() }()

	sources := make([]types.SourceItemResponse, 0)
	for rows.Next() {
		var (
			sourceID           int
			modelName          string
			images             sql.NullString
			modelFamily        string
			description        sql.NullString
			specificationsJSON []byte
			isFusionCompatible bool
		)

		if err := rows.Scan(
			&sourceID,
			&modelName,
			&images,
			&modelFamily,
			&description,
			&specificationsJSON,
			&isFusionCompatible,
		); err != nil {
			logger.Error("failed to scan source row", zap.Error(err))
			return nil, fmt.Errorf("failed to scan source row: %w", err)
		}

		var descPtr *string
		if description.Valid {
			descPtr = &description.String
		}

		var specs types.SourceSpecifications
		if specificationsJSON != nil {
			if err := json.Unmarshal(specificationsJSON, &specs); err != nil {
				logger.Error("failed to unmarshal specifications", zap.Error(err))
				return nil, fmt.Errorf("failed to unmarshal specifications: %w", err)
			}
		}
		if specs.SupportedConnections == nil {
			specs.SupportedConnections = []string{}
		}

		imagesStr := ""
		if images.Valid {
			imagesStr = images.String
		}

		item := types.SourceItemResponse{
			SourceID:           sourceID,
			Assets:             []types.SourceAsset{{Black: []string{imagesStr}}},
			ModelName:          modelName,
			ModelFamily:        modelFamily,
			Description:        descPtr,
			Specifications:     specs,
			IsFusionCompatible: isFusionCompatible,
		}

		sources = append(sources, item)
	}

	if err := rows.Err(); err != nil {
		logger.Error("error iterating source rows", zap.Error(err))
		return nil, fmt.Errorf("error iterating source rows: %w", err)
	}

	return sources, nil
}
