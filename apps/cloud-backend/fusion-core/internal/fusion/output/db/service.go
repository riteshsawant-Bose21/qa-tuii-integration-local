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
	query := `SELECT id, name, type, images, primary_connection, array_to_json(supported_connections) FROM output ORDER BY name`

	rows, err := s.db.QueryContext(ctx, query)
	if err != nil {
		logger.Error("failed to query outputs", zap.Error(err))
		return nil, fmt.Errorf("failed to query outputs: %w", err)
	}

	defer func() { _ = rows.Close() }()

	outputs := make([]types.OutputItemResponse, 0)
	for rows.Next() {
		var item types.OutputItemResponse
		var primaryConnection string
		var supportedConnectionsJSON []byte
		if err := rows.Scan(
			&item.OutputID,
			&item.Name,
			&item.Type,
			&item.Images,
			&primaryConnection,
			&supportedConnectionsJSON,
		); err != nil {
			logger.Error("failed to scan output row", zap.Error(err))
			return nil, fmt.Errorf("failed to scan output row: %w", err)
		}

		supportedConnections := make([]string, 0)
		if len(supportedConnectionsJSON) > 0 {
			if err := json.Unmarshal(supportedConnectionsJSON, &supportedConnections); err != nil {
				logger.Error("failed to parse output supported connections", zap.Error(err))
				return nil, fmt.Errorf("failed to parse output supported connections: %w", err)
			}
		}

		item.Specifications = types.OutputSpecifications{
			PrimaryConnection:    primaryConnection,
			SupportedConnections: supportedConnections,
		}

		outputs = append(outputs, item)
	}

	if err := rows.Err(); err != nil {
		logger.Error("error iterating output rows", zap.Error(err))
		return nil, fmt.Errorf("error iterating output rows: %w", err)
	}

	return outputs, nil
}
