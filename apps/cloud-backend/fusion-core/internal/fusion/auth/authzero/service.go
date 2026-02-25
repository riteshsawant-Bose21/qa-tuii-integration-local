// Package auth0 provides Auth0 authentication and JWT validation services.
package auth0

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/golang-jwt/jwt/v5"
	"go.uber.org/zap"
)

// Service provides Auth0 authentication services
type Service struct {
	authZeroConfig *config.AuthZero
	logger         *zap.Logger
	validator      *Auth0Validator
}

// NewService creates a new Auth0 service with the provided configuration and logger
func NewService(authZeroConfig *config.AuthZero, logger *zap.Logger) *Service {
	if authZeroConfig == nil {
		panic("auth0Config cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}

	// Initialize validator with domain from config
	validator := NewAuth0Validator(authZeroConfig.Domain)

	return &Service{
		authZeroConfig: authZeroConfig,
		logger:         logger,
		validator:      validator,
	}
}

// ValidateToken validates an Auth0 JWT token and returns claims
func (s *Service) ValidateToken(tokenString string) (*jwt.MapClaims, error) {
	return s.validator.ValidateToken(tokenString)
}

// ExtractUserID extracts user ID from JWT claims
func (s *Service) ExtractUserID(claims *jwt.MapClaims) (string, error) {
	return ExtractUserID(claims)
}

// ExtractUserEmail extracts user email from JWT claims
func (s *Service) ExtractUserEmail(claims *jwt.MapClaims) (string, error) {
	return ExtractUserEmail(claims)
}

// ExtractTokenFromHeader extracts Bearer token from Authorization header
func (s *Service) ExtractTokenFromHeader(authHeader string) (string, error) {
	return ExtractTokenFromHeader(authHeader)
}

// GetAuthTokensByResourceOwnerPassword gets Auth0 tokens for a user using Resource Owner Password flow
func (s *Service) GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error) {
	// Check if Resource Owner Password flow is enabled
	enabled, err := strconv.ParseBool(strings.ToLower(s.authZeroConfig.ResourceOwnerPasswordFlowEnabled))
	if err != nil {
		s.logger.Error("Error checking Resource Owner Password flow status", zap.Error(err))
		return nil, err
	}

	if !enabled {
		s.logger.Warn("Resource Owner Password flow is disabled")
		return nil, fmt.Errorf("resource owner password flow is disabled")
	}

	s.logger.Info("Generating Auth0 tokens", zap.String("username", username))

	url := s.authZeroConfig.AccessTokenEndpoint
	s.logger.Info("Auth0 URL", zap.String("url", url))

	// Prepare the request payload for Auth0 Resource Owner Password flow
	payload := map[string]string{
		"grant_type":    "password",
		"username":      username,
		"password":      s.authZeroConfig.DefaultResourceOwnerPassword,
		"client_id":     s.authZeroConfig.ClientID,
		"client_secret": s.authZeroConfig.ClientSecret,
		"scope":         "openid profile email",
	}

	s.logger.Info("Auth0 payload", zap.Any("payload_keys", []string{"grant_type", "username", "client_id", "scope"}))

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request payload: %w", err)
	}

	// Create HTTP request with context
	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(jsonPayload))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	// Make the request with timeout
	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		s.logger.Error("Failed to make request to Auth0", zap.String("username", username), zap.Error(err))
		return nil, fmt.Errorf("failed to make request to Auth0: %w", err)
	}
	defer func() {
		_ = resp.Body.Close() // Body close errors are usually not critical
	}()

	// Handle non-200 responses
	if resp.StatusCode != http.StatusOK {
		var errorResponse map[string]interface{}
		if decodeErr := json.NewDecoder(resp.Body).Decode(&errorResponse); decodeErr != nil {
			// If we can't decode the error response, use a generic error
			errorResponse = map[string]interface{}{"error": "unknown_error", "error_description": "Unable to decode error response"}
		}
		s.logger.Error("Auth0 returned non-200 status",
			zap.String("username", username),
			zap.Int("status_code", resp.StatusCode),
			zap.Any("error_response", errorResponse))
		return nil, fmt.Errorf("Auth0 returned status %d: %v", resp.StatusCode, errorResponse)
	}

	// Parse the successful response
	var tokenResponse types.AuthTokenResponse
	if err := json.NewDecoder(resp.Body).Decode(&tokenResponse); err != nil {
		s.logger.Error("Failed to decode Auth0 response", zap.String("username", username), zap.Error(err))
		return nil, fmt.Errorf("failed to decode Auth0 response: %w", err)
	}

	s.logger.Info("Successfully generated Auth0 tokens", zap.String("username", username))
	return &tokenResponse, nil
}
