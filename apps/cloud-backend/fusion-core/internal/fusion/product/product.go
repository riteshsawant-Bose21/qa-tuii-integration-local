package product

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// GetProductByID retrieves a product by its ID.
func (p *Service) GetProductByID(ctx context.Context, id string) (*types.ProductResponse, error) {
	// Implement the logic to get a product by ID.
	return p.dbService.SelectByID(ctx, id)
}

// GetAllProducts retrieves all products.
func (p *Service) GetAllProducts(ctx context.Context) (*types.ProductResponse, error) {
	// Check who is viewing

	products, err := p.dbService.SelectAll(ctx)
	if err != nil {
		return nil, fmt.Errorf("error getting products from DB: %w", err)
	}
	return products, nil
}

// UpdateProducts updates the products in the database.
func (p *Service) UpdateProducts(ctx context.Context, product *types.ProductFetch) error {
	if product == nil {
		return fmt.Errorf("product cannot be nil")
	}

	if product.Speakers != nil {
		for _, speaker := range product.Speakers {
			if speaker.ID == 0 {
				return fmt.Errorf("speaker ID is required")
			}
		}

		err := p.dbService.Upsert(ctx, product)
		if err != nil {
			return fmt.Errorf("error inserting product into DB: %w", err)
		}
	}
	return nil
}
