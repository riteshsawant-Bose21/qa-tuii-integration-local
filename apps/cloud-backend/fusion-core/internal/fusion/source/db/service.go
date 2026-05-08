package db

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/lib/pq"
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
	query := `SELECT id, model_name, asset_path, model_family, primary_connection_type, description, paging_source_type, supported_connection_types, is_fusion_compatible FROM source ORDER BY model_name`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		logger.Error("failed to query sources", zap.Error(err))
		return nil, fmt.Errorf("failed to query sources: %w", err)
	}

	defer func() { _ = rows.Close() }()

	sources := make([]types.SourceItemResponse, 0)
	for rows.Next() {
		var (
			sourceID           string
			modelName          string
			assetPath          sql.NullString
			modelFamily        string
			primaryConnection  string
			description        sql.NullString
			pagingSourceType   sql.NullString
			supportedConns     []string
			isFusionCompatible bool
		)

		if err := rows.Scan(
			&sourceID,
			&modelName,
			&assetPath,
			&modelFamily,
			&primaryConnection,
			&description,
			&pagingSourceType,
			pq.Array(&supportedConns),
			&isFusionCompatible,
		); err != nil {
			logger.Error("failed to scan source row", zap.Error(err))
			return nil, fmt.Errorf("failed to scan source row: %w", err)
		}

		if supportedConns == nil {
			supportedConns = []string{}
		}

		var descPtr *string
		if description.Valid {
			descPtr = &description.String
		}

		var pagingTypePtr *string
		if pagingSourceType.Valid {
			pagingTypePtr = &pagingSourceType.String
		}

		assetPathStr := ""
		if assetPath.Valid {
			assetPathStr = assetPath.String
		}

		item := types.SourceItemResponse{
			SourceID:    sourceID,
			Assets:      []types.SourceAsset{{Black: []string{assetPathStr}}},
			ModelName:   modelName,
			ModelFamily: modelFamily,
			Description: descPtr,
			Specifications: types.SourceSpecifications{
				PrimaryConnection:    primaryConnection,
				SupportedConnections: supportedConns,
				PagingType:           pagingTypePtr,
			},
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
