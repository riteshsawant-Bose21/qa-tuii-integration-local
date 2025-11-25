package product

import (
	"context"
	"fmt"
	"strconv"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// GetProductByID retrieves a product by its ID.
func (p *Service) GetProductByID(ctx context.Context, id string) (*types.SingleProductResponse, error) {
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

// GetProductPrices retrieves prices for a product by its ID.
func (p *Service) GetProductPrices(ctx context.Context, id string, currency string, variant string) (*types.PriceResponse, error) {
	// Convert id string to int
	productID, err := strconv.Atoi(id)
	if err != nil {
		return nil, fmt.Errorf("invalid product ID: %w", err)
	}

	prices, err := p.dbService.GetPricesByProductID(ctx, productID, currency, variant)
	if err != nil {
		return nil, fmt.Errorf("error getting prices from DB: %w", err)
	}

	// Check if no prices found
	if len(prices.Prices) == 0 {
		return nil, fmt.Errorf("no prices found for product ID %s", id)
	}

	return prices, nil
}
