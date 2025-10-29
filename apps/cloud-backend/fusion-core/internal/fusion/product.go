package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Product interface {
	GetProductByID(ctx context.Context, id string) (*types.ProductResponse, error)
	GetAllProducts(ctx context.Context) (*types.ProductResponse, error)
}
