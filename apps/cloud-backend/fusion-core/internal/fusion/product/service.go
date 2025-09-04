package product

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
)

// Service provides methods to interact with the product database.
type Service struct {
	dbService DatabaseService
}

// NewService creates a new product service.
func NewService(dbService DatabaseService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}

	return &Service{
		dbService: dbService,
	}
}

// DatabaseService defines the interface for database operations related to products.
type DatabaseService interface {
	// Product
	SelectByID(ctx context.Context, id string) (*fusion.ProductResponse, error)
	SelectAll(ctx context.Context) (*fusion.ProductResponse, error)
	Upsert(ctx context.Context, product *fusion.ProductFetch) error
}

// Product defines the interface for product-related operations.
type Product interface {
	GetProductByID(ctx context.Context, id string) (*fusion.ProductResponse, error)
	GetAllProducts(ctx context.Context) (*fusion.ProductResponse, error)
}
