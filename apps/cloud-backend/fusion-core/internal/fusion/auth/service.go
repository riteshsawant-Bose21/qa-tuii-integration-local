package auth

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

type Service struct {
	auth0Service Auth0Service
}

type Auth0Service interface {
	GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error)
}

func NewService(auth0Service Auth0Service) *Service {
	if auth0Service == nil {
		panic("auth0Service cannot be nil")
	}
	return &Service{
		auth0Service: auth0Service,
	}
}
