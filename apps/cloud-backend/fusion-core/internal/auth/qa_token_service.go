package auth

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// QATokenServiceConfig holds configuration for QA token service
type QATokenServiceConfig struct {
	Auth0Domain     string
	ClientID        string
	ClientSecret    string
	DefaultPassword string
}

// QATokenService handles QA token generation using Auth0 Resource Owner Password flow
type QATokenService struct {
	config QATokenServiceConfig
}

// NewQATokenService creates a new QA token service
func NewQATokenService(config QATokenServiceConfig) *QATokenService {
	return &QATokenService{
		config: config,
	}
}

// GetTokensForUser gets Auth0 tokens for a user using Resource Owner Password flow
func (s *QATokenService) GetTokensForUser(ctx context.Context, username string) (*types.QATokenResponse, error) {
	url := fmt.Sprintf("https://%s/oauth/token", s.config.Auth0Domain)

	// Prepare the request payload for Auth0 Resource Owner Password flow
	payload := map[string]string{
		"grant_type":    "password",
		"username":      username,
		"password":      s.config.DefaultPassword,
		"client_id":     s.config.ClientID,
		"client_secret": s.config.ClientSecret,
		"scope":         "openid profile email",
	}

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
		return nil, fmt.Errorf("failed to make request to Auth0: %w", err)
	}
	defer resp.Body.Close()

	// Handle non-200 responses
	if resp.StatusCode != http.StatusOK {
		var errorResponse map[string]interface{}
		json.NewDecoder(resp.Body).Decode(&errorResponse)
		return nil, fmt.Errorf("Auth0 returned status %d: %v", resp.StatusCode, errorResponse)
	}

	// Parse the successful response
	var tokenResponse types.QATokenResponse
	if err := json.NewDecoder(resp.Body).Decode(&tokenResponse); err != nil {
		return nil, fmt.Errorf("failed to decode Auth0 response: %w", err)
	}

	return &tokenResponse, nil
}
