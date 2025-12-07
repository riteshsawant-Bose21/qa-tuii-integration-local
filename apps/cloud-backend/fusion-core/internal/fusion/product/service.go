package product

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Service provides methods to interact with the product database.
type Service struct {
	dbService DatabaseService
	idService IDService
	version   string
}

// DatabaseService defines the interface for database operations related to products.
type DatabaseService interface {
	SelectByID(ctx context.Context, id string, version string) (*types.SingleProductResponse, error)
	SelectAll(ctx context.Context, version string) (*types.ProductResponse, error)
	GetPricesByProductID(ctx context.Context, productID int, currency string, variant string) (*types.PriceResponse, error)
	GetLatestSyncVersion(ctx context.Context, syncType string) (string, error)
	// Upsert(ctx context.Context, product *types.ProductFetch) error  // Commented out for now
}

type IDService interface {
	EncryptID(id string) (string, error)
	DecryptID(encryptedID string) (string, error)
}

// NewService creates a new product service.
func NewService(dbService DatabaseService, idService IDService, version string) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if idService == nil {
		panic("idService cannot be nil")
	}

	return &Service{
		dbService: dbService,
		idService: idService,
		version:   version,
	}
}
