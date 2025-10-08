package product

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
)

// Service provides methods to interact with the product database.
type Service struct {
	dbService DatabaseService
	idService IDService
}

// DatabaseService defines the interface for database operations related to products.
type DatabaseService interface {
	// Product
	SelectByID(ctx context.Context, id string) (*fusion.ProductResponse, error)
	SelectAll(ctx context.Context) (*fusion.ProductResponse, error)
	Upsert(ctx context.Context, product *fusion.ProductFetch) error
}

type IDService interface {
	EncryptID(id string) (string, error)
	DecryptID(encryptedID string) (string, error)
}

// NewService creates a new product service.
func NewService(dbService DatabaseService, idService IDService) *Service {
	if dbService == nil {
		panic("dbService cannot be nil")
	}
	if idService == nil {
		panic("idService cannot be nil")
	}

	return &Service{
		dbService: dbService,
		idService: idService,
	}
}
