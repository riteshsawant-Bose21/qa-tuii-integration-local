package auth

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/golang-jwt/jwt/v5"
)

type Service struct {
	authZeroService AuthZeroService
}

type AuthZeroService interface {
	// Token generation
	GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error)

	// JWT validation
	ValidateToken(tokenString string) (*jwt.MapClaims, error)
	ExtractUserID(claims *jwt.MapClaims) (string, error)
	ExtractUserEmail(claims *jwt.MapClaims) (string, error)
	ExtractTokenFromHeader(authHeader string) (string, error)
}

func NewService(authZeroService AuthZeroService) *Service {
	if authZeroService == nil {
		panic("auth0Service cannot be nil")
	}
	return &Service{
		authZeroService: authZeroService,
	}
}
