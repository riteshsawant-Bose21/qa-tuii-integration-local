package sync

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
)

// SyncConfig holds the configuration settings for the Sync service.
type SyncConfig struct {
	Postgres   *config.Postgres
	Server     *config.Server
	Validation *config.Validation
	Cloud         *config.CloudConfig
	Processing *config.Processing
}

// SyncConfigService defines the methods required to fetch configuration settings.
type SyncConfigService interface {
	Postgres() (*config.Postgres, error)
	Server() (*config.Server, error)
	Validation() (*config.Validation, error)
	Cloud() (*config.CloudConfig, error)
	Processing() (*config.Processing, error)
}

// NewSyncConfig initializes and returns the Sync configuration by loading necessary settings.
func NewSyncConfig(svc SyncConfigService) (*SyncConfig, error) {
	cfg := &SyncConfig{}
	// Load Postgres configuration
	pgConfig, err := svc.Postgres()
	if err != nil {
		return nil, fmt.Errorf("failed to load postgres config: %w", err)
	}
	cfg.Postgres = pgConfig

	// Load Server configuration
	serverConfig, err := svc.Server()
	if err != nil {
		return nil, fmt.Errorf("failed to load server config: %w", err)
	}
	cfg.Server = serverConfig

	// Load Validation configuration
	validationConfig, err := svc.Validation()
	if err != nil {
		return nil, fmt.Errorf("failed to load validation config: %w", err)
	}
	cfg.Validation = validationConfig

	// Load Cloud configuration
	cloudConfig, err := svc.Cloud()
	if err != nil {
		return nil, fmt.Errorf("failed to load cloud config: %w", err)
	}
	cfg.Cloud = cloudConfig

	// Load Processing configuration
	processingConfig, err := svc.Processing()
	if err != nil {
		return nil, fmt.Errorf("failed to load processing config: %w", err)
	}
	cfg.Processing = processingConfig

	return cfg, nil
}
