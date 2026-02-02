package config

import (
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
)

// APIConfig holds the configuration settings for the API service.
type APIConfig struct {
	APIHost     string
	APIPort     string
	SwaggerHost string
	Mode        string
	LogLevel    string
	LogDir      string
}

// APIConfig retrieves the API configuration from the store.
func (s *Service) APIConfig() (*APIConfig, error) {
	apiHost, err := s.store.ReqString(environment.API.Host)
	if err != nil {
		return nil, fmt.Errorf("failed to get API host: %w", err)
	}
	apiPort, err := s.store.ReqString(environment.API.Port)
	if err != nil {
		return nil, fmt.Errorf("failed to get API port: %w", err)
	}

	swaggerHost, err := s.store.ReqString(environment.API.SwaggerHost)
	if err != nil {
		return nil, fmt.Errorf("failed to get Swagger host: %w", err)
	}

	mode, err := s.store.ReqString(environment.API.ReleaseMode)
	if err != nil {
		return nil, fmt.Errorf("failed to get release mode: %w", err)
	}

	logLevel, err := s.store.ReqString(environment.API.LogLevel)
	if err != nil {
		return nil, fmt.Errorf("failed to get log level: %w", err)
	}

	logDir, err := s.store.ReqString(environment.API.LogDir)
	if err != nil {
		return nil, fmt.Errorf("failed to get log directory: %w", err)
	}

	return &APIConfig{
		APIHost:     apiHost,
		APIPort:     apiPort,
		SwaggerHost: swaggerHost,
		Mode:        mode,
		LogLevel:    logLevel,
		LogDir:      logDir,
	}, nil
}
