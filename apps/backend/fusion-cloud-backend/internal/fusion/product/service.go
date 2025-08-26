package product

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/fusion"
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

type DatabaseService interface {
	// Product
	SelectByID(ctx context.Context, id string) (*fusion.Product, error)
	SelectAll(ctx context.Context) (*fusion.Product, error)
}

type Product interface {
	GetProductByID(ctx context.Context, id string) (*fusion.Product, error)
	GetAllProducts(ctx context.Context) (*fusion.Product, error)
}
