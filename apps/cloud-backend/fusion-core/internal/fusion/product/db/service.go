package db

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion"
	model "github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion/model/models"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
)

type Service struct {
	db *sql.DB
}

// NewService creates a new database service.
func NewService(db *sql.DB) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

func (s *Service) SelectByID(ctx context.Context, id string) (*fusion.Product, error) {
	// Implement the logic to get a product by ID from the database.
	// This is a placeholder implementation.
	return nil, nil
}

func (s *Service) SelectAll(ctx context.Context) (*fusion.Product, error) {

	// if exec == nil {
	// 	exec = s.db
	// }
	var q []qm.QueryMod

	// Get the row by running the query.
	rows, err := model.Products(q...).All(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("can't get row: %v", err)
	}
	// Get the node from the row.
	node, err := s.newProduct(&rows)
	if err != nil {
		return nil, fmt.Errorf("can't parse row: %v", err)
	}

	return node, nil
}
