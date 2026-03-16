// Package product provides product management and synchronization functionality.
package product

import (
	"context"
	"fmt"
	"strconv"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// GetProductByID retrieves a product by its ID.
func (p *Service) GetProductByID(ctx context.Context, id string, logger *zap.Logger) (*types.SingleProductResponse, error) {
	// Get the latest version from successful product sync
	version, err := p.dbService.GetLatestSyncVersion(ctx, "product", logger)
	if err != nil {
		// Fallback to configured version if no sync version found
		version = p.version
	}
	return p.dbService.SelectByID(ctx, id, version, logger)
}

// GetAllProducts retrieves all products.
func (p *Service) GetAllProducts(ctx context.Context, logger *zap.Logger) (*types.ProductResponse, error) {
	// Get the latest version from successful product sync
	version, err := p.dbService.GetLatestSyncVersion(ctx, "product", logger)
	if err != nil {
		// Fallback to configured version if no sync version found
		version = p.version
	}

	products, err := p.dbService.SelectAll(ctx, version, logger)
	if err != nil {
		return nil, fmt.Errorf("error getting products from DB: %w", err)
	}

	// Fetch sources and attach to response
	sources, err := p.sourceService.GetAllSources(ctx, logger)
	if err != nil {
		logger.Warn("failed to fetch sources, continuing without source data", zap.Error(err))
	} else {
		products.Source = sources
	}

	return products, nil
}

// GetProductPrices retrieves prices for a product by its ID.
func (p *Service) GetProductPrices(ctx context.Context, id string, currency string, variant string, logger *zap.Logger) (*types.PriceResponse, error) {
	// Convert id string to int
	productID, err := strconv.Atoi(id)
	if err != nil {
		return nil, fmt.Errorf("invalid product ID: %w", err)
	}

	prices, err := p.dbService.GetPricesByProductID(ctx, productID, currency, variant, logger)
	if err != nil {
		return nil, fmt.Errorf("error getting prices from DB: %w", err)
	}

	// Check if no prices found
	if len(prices.Prices) == 0 {
		return nil, fmt.Errorf("no prices found for product ID %s", id)
	}

	return prices, nil
}
