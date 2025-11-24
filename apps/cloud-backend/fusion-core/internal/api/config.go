package api

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
)

// APIconfig holds the configuration settings for the API service.
type APIconfig struct {
	Postgres *config.Postgres
}

// NewAPIConfig initializes and returns the API configuration by loading necessary settings.
func NewAPIConfig(svc ConfigService) (*APIconfig, error) {
	cfg := &APIconfig{}
	// Load Postgres configuration
	pgConfig, err := svc.Postgres()
	if err != nil {
		return nil, fmt.Errorf("failed to load postgres config: %w", err)
	}
	cfg.Postgres = pgConfig
	return cfg, nil
}

// ConfigService defines the methods required to fetch configuration settings.
type ConfigService interface {
	Postgres() (*config.Postgres, error)
}
