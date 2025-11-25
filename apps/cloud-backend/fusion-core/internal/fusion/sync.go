package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Sync defines the interface for sync operations
type Sync interface {
	// Product sync operations
	SyncProducts(ctx context.Context, data []byte, jobID string) (*types.SyncResult, error)

	// Price sync operations
	SyncPrices(ctx context.Context, data []byte) (*types.SyncResult, error)
}
