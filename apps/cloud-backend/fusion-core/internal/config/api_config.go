package config

import (
	"fmt"
)

// APIConfig holds the configuration settings for the API service.
type APIConfig struct {
	APIHost     string
	APIPort     string
	SwaggerHost string
}

// APIConfig retrieves the API configuration from the store.
func (s *Service) APIConfig() (*APIConfig, error) {
	apiHost, err := s.store.ReqString(keyAPIHost)
	if err != nil {
		return nil, fmt.Errorf("failed to get API host: %w", err)
	}
	apiPort, err := s.store.ReqString(keyAPIPort)
	if err != nil {
		return nil, fmt.Errorf("failed to get API port: %w", err)
	}

	swaggerHost, err := s.store.ReqString(keySwaggerHost)
	if err != nil {
		return nil, fmt.Errorf("failed to get Swagger host: %w", err)
	}

	return &APIConfig{
		APIHost:     apiHost,
		APIPort:     apiPort,
		SwaggerHost: swaggerHost,
	}, nil
}

const (
	keyAPIHost     string = "API_HOST"
	keyAPIPort     string = "API_PORT"
	keySwaggerHost string = "SWAGGER_HOST"
)
