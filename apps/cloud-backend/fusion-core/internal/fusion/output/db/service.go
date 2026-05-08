package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// Service provides database operations for the output table.
type Service struct {
	db     *sql.DB
	logger *zap.Logger
}

// NewService creates a new output database service.
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

// SelectAll retrieves all outputs from the database.
func (s *Service) SelectAll(ctx context.Context, logger *zap.Logger) ([]types.OutputItemResponse, error) {
	query := `SELECT id, name, type, images, specifications FROM output ORDER BY name`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		logger.Error("failed to query outputs", zap.Error(err))
		return nil, fmt.Errorf("failed to query outputs: %w", err)
	}

	defer func() { _ = rows.Close() }()

	outputs := make([]types.OutputItemResponse, 0)
	for rows.Next() {
		var (
			item               types.OutputItemResponse
			images             sql.NullString
			specificationsJSON []byte
		)
		if err := rows.Scan(
			&item.OutputID,
			&item.Name,
			&item.Type,
			&images,
			&specificationsJSON,
		); err != nil {
			logger.Error("failed to scan output row", zap.Error(err))
			return nil, fmt.Errorf("failed to scan output row: %w", err)
		}

		var specs types.OutputSpecifications
		if specificationsJSON != nil {
			if err := json.Unmarshal(specificationsJSON, &specs); err != nil {
				logger.Error("failed to unmarshal output specifications", zap.Error(err))
				return nil, fmt.Errorf("failed to unmarshal output specifications: %w", err)
			}
		}
		if specs.SupportedConnections == nil {
			specs.SupportedConnections = []string{}
		}

		imagesStr := ""
		if images.Valid {
			imagesStr = images.String
		}

		item.Assets = []types.OutputAsset{{Black: []string{imagesStr}}}
		item.Specifications = specs

		outputs = append(outputs, item)
	}

	if err := rows.Err(); err != nil {
		logger.Error("error iterating output rows", zap.Error(err))
		return nil, fmt.Errorf("error iterating output rows: %w", err)
	}

	return outputs, nil
}
