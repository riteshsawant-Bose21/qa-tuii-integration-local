package product

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion"
)

func (p *Service) GetProductByID(ctx context.Context, id string) (*fusion.Product, error) {
	// Implement the logic to get a product by ID.
	return p.dbService.SelectByID(ctx, id)
}

func (p *Service) GetAllProducts(ctx context.Context) (*fusion.Product, error) {
	// Check who is viewing

	products, err := p.dbService.SelectAll(ctx)
	if err != nil {
		return nil, fmt.Errorf("error getting products from DB: %w", err)
	}
	return products, nil
}
