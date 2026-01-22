package auth

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Service struct {
	authZeroService AuthZeroService
}

type AuthZeroService interface {
	GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error)
}

func NewService(authZeroService AuthZeroService) *Service {
	if authZeroService == nil {
		panic("auth0Service cannot be nil")
	}
	return &Service{
		authZeroService: authZeroService,
	}
}
