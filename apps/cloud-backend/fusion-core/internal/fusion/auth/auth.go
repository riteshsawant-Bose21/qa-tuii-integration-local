package auth

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

func (s *Service) GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error) {
	return s.auth0Service.GetAuthTokensByResourceOwnerPassword(ctx, username)
}
