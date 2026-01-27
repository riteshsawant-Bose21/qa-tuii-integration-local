package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// Auth interface defines authentication-related operations
type Auth interface {
	// GetAuthTokensByResourceOwnerPassword retrieves Auth0 tokens for automation testing
	GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error)
}
