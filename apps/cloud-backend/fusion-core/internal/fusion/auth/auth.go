package auth

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/golang-jwt/jwt/v5"
)

// GetAuthTokensByResourceOwnerPassword delegates token generation to Auth0 service
func (s *Service) GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error) {
	return s.authZeroService.GetAuthTokensByResourceOwnerPassword(ctx, username)
}

// ValidateToken validates an Auth0 JWT token and returns claims
func (s *Service) ValidateToken(tokenString string) (*jwt.MapClaims, error) {
	return s.authZeroService.ValidateToken(tokenString)
}

// ExtractUserID extracts user ID from JWT claims
func (s *Service) ExtractUserID(claims *jwt.MapClaims) (string, error) {
	return s.authZeroService.ExtractUserID(claims)
}

// ExtractUserEmail extracts user email from JWT claims
func (s *Service) ExtractUserEmail(claims *jwt.MapClaims) (string, error) {
	return s.authZeroService.ExtractUserEmail(claims)
}

// ExtractTokenFromHeader extracts Bearer token from Authorization header
func (s *Service) ExtractTokenFromHeader(authHeader string) (string, error) {
	return s.authZeroService.ExtractTokenFromHeader(authHeader)
}
