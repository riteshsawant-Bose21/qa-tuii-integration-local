// Package api provides server configuration and setup for API endpoints.
package api

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
)

// APIconfig holds the configuration settings for the API service.
type APIconfig struct {
	Server   *config.APIConfig
	Postgres *config.Postgres
	Cloud    *config.CloudConfig
	AuthZero *config.AuthZero
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

	cloudConfig, err := svc.Cloud()
	if err != nil {
		return nil, fmt.Errorf("failed to load cloud config: %w", err)
	}
	cfg.Cloud = cloudConfig

	authZeroConfig, err := svc.AuthZero()
	if err != nil {
		return nil, fmt.Errorf("failed to load auth0 config: %w", err)
	}
	cfg.AuthZero = authZeroConfig
	return cfg, nil
}

// ConfigService defines the methods required to fetch configuration settings.
type ConfigService interface {
	APIConfig() (*config.APIConfig, error)
	Postgres() (*config.Postgres, error)
	Cloud() (*config.CloudConfig, error)
	AuthZero() (*config.AuthZero, error)
}
