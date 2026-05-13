package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

// BSF defines the interface for BSF (Bose Specification File) generation operations.
type BSF interface {
	Generate(ctx context.Context, req *types.BSFGenerateRequest, logger *zap.Logger) (*types.BSFGenerateResponse, error)
}
