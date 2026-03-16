package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"go.uber.org/zap"
)

type Source interface {
	GetAllSources(ctx context.Context, logger *zap.Logger) ([]types.SourceItem, error)
}
