package api

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
)

// APIconfig holds the configuration settings for the API service.
type APIconfig struct {
	Server   *config.APIConfig
	Postgres *config.Postgres
	S3       *config.S3
	Auth0    *config.Auth0
}

// NewAPIConfig initializes and returns the API configuration by loading necessary settings.
func NewAPIConfig(svc ConfigService) (*APIconfig, error) {
	cfg := &APIconfig{}

	apiCfg, err := svc.APIConfig()
	if err != nil {
		return nil, fmt.Errorf("failed to load api config: %w", err)
	}
	cfg.Server = apiCfg

	// Load Postgres configuration
	pgConfig, err := svc.Postgres()
	if err != nil {
		return nil, fmt.Errorf("failed to load postgres config: %w", err)
	}
	cfg.Postgres = pgConfig

	s3Config, err := svc.S3()
	if err != nil {
		return nil, fmt.Errorf("failed to load s3 config: %w", err)
	}
	cfg.S3 = s3Config

	auth0Config, err := svc.Auth0()
	if err != nil {
		return nil, fmt.Errorf("failed to load auth0 config: %w", err)
	}
	cfg.Auth0 = auth0Config

	return cfg, nil
}

// ConfigService defines the methods required to fetch configuration settings.
type ConfigService interface {
	APIConfig() (*config.APIConfig, error)
	Postgres() (*config.Postgres, error)
	S3() (*config.S3, error)
	Auth0() (*config.Auth0, error)
}
