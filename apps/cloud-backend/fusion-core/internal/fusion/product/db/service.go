package db

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
)

// Service is a service for managing products in the database.
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

// SelectByID retrieves a product by its ID from the database.
func (s *Service) SelectByID(ctx context.Context, id string) (*fusion.ProductResponse, error) {
	// Implement the logic to get a product by ID from the database.
	// This is a placeholder implementation.
	return nil, nil
}

// SelectAll retrieves all products from the database.
func (s *Service) SelectAll(ctx context.Context) (*fusion.ProductResponse, error) {

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

// Insert inserts a new product into the database.
func (s *Service) Insert(ctx context.Context, product *fusion.ProductResponse) error {
	if product == nil {
		return fmt.Errorf("product cannot be nil")
	}

	p := &model.Product{}

	err := p.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to insert product: %w", err)
	}

	return nil
}

// Upsert inserts or updates a product in the database.
func (s *Service) Upsert(ctx context.Context, product *fusion.ProductFetch) error {
	if product == nil {
		return fmt.Errorf("product cannot be nil")
	}

	p := &model.Product{}

	// Convert fusion.ProductFetch to model.Product
	// p = &model.Product{
	// 	ID:          product.ID,
	// 	Name:        product.Name,
	// 	Description: product.Description,
	// 	// Add other fields as needed
	// }
	// p := &model.Product{}

	// Upsert the product
	err := p.Upsert(ctx, s.db, true, []string{"id"}, boil.Infer(), boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to upsert product: %w", err)
	}

	return nil
}

// newProduct returns the Product node from the provided Product rows
