package fusion

import (
	"context"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/golang-jwt/jwt/v5"
)

// Auth interface defines authentication-related operations
type Auth interface {
	// Token generation
	GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error)

	// JWT validation
	ValidateToken(tokenString string) (*jwt.MapClaims, error)
	ExtractUserID(claims *jwt.MapClaims) (string, error)
	ExtractUserEmail(claims *jwt.MapClaims) (string, error)
	ExtractTokenFromHeader(authHeader string) (string, error)
}
