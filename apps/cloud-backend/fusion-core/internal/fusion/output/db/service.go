package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
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
	rows, err := models.Outputs(
		qm.OrderBy(models.OutputColumns.ID),
	).All(ctx, s.db)
	if err != nil {
		logger.Error("failed to query outputs", zap.Error(err))
		return nil, fmt.Errorf("failed to query outputs: %w", err)
	}

	outputs := make([]types.OutputItemResponse, 0)
	for _, row := range rows {
		var (
			item  types.OutputItemResponse
			specs types.OutputSpecifications
		)

		item.OutputID = row.ID
		item.Name = row.Name
		item.Type = row.Type

		if row.Specifications.Valid {
			if err := json.Unmarshal(row.Specifications.JSON, &specs); err != nil {
				logger.Error("failed to unmarshal output specifications", zap.Error(err))
				return nil, fmt.Errorf("failed to unmarshal output specifications: %w", err)
			}
		}
		if specs.SupportedConnections == nil {
			specs.SupportedConnections = []string{}
		}

		item.Assets = []types.OutputAsset{{Black: []string{row.Images}}}
		item.Specifications = specs

		outputs = append(outputs, item)
	}

	return outputs, nil
}
