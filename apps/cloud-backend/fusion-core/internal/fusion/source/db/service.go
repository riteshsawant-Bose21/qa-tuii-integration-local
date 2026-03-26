package db

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// Service provides database operations for the source table.
type Service struct {
	db     *sql.DB
	logger *zap.Logger
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
		db:     db,
		logger: logger,
	}
}

// SelectAll retrieves all sources from the database.
func (s *Service) SelectAll(ctx context.Context, logger *zap.Logger) ([]types.SourceItem, error) {
	query := `SELECT id, name, asset_path, type, connection_type, price FROM source ORDER BY name`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		logger.Error("failed to query sources", zap.Error(err))
		return nil, fmt.Errorf("failed to query sources: %w", err)
	}

	defer func() {
    if err := rows.Close(); err != nil {
        logger.Error("failed to close source rows", zap.Error(err))
    }
	}()

	var sources []types.SourceItem
	for rows.Next() {
		var item types.SourceItem
		if err := rows.Scan(
			&item.SourceID,
			&item.Name,
			&item.AssetPath,
			&item.SourceType,
			&item.ConnectionType,
			&item.Price,
		); err != nil {
			logger.Error("failed to scan source row", zap.Error(err))
			return nil, fmt.Errorf("failed to scan source row: %w", err)
		}
		sources = append(sources, item)
	}

	if err := rows.Err(); err != nil {
		logger.Error("error iterating source rows", zap.Error(err))
		return nil, fmt.Errorf("error iterating source rows: %w", err)
	}

	return sources, nil
}
