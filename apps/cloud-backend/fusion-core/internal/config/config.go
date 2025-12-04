package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
)

// Service provides methods to fetch configuration settings.
type Service struct {
	store Store
}

// Store defines the interface for configuration storage.
type Store interface {
	ReqString(key string) (string, error)
}

// NewService creates a new configuration service with the provided store.
func NewService(store Store) (*Service, error) {
	if store == nil {
		return nil, errors.New("store cannot be nil")
	}
	return &Service{store: store}, nil
}

// NewWithSecretsManager creates a new config service with AWS Secrets Manager support
func NewWithSecretsManager(useSecretsManager bool, awsRegion string) (*Service, error) {
	if !useSecretsManager {
		env := environment.New(environment.DefaultLoadLookuper)
		return NewService(env)
	}

	// Use AWS Secrets Manager (pure secrets mode - no fallback to environment)
	postgresSecretName := os.Getenv("POSTGRES_SECRET_NAME")
	if postgresSecretName == "" {
		return nil, fmt.Errorf("POSTGRES_SECRET_NAME environment variable is required when using secrets manager")
	}

	appConfigSecretName := os.Getenv("APP_CONFIG_SECRET_NAME")
	if appConfigSecretName == "" {
		return nil, fmt.Errorf("APP_CONFIG_SECRET_NAME environment variable is required when using secrets manager")
	}

	if awsRegion == "" {
		awsRegion = os.Getenv("AWS_REGION")
		if awsRegion == "" {
			return nil, fmt.Errorf("AWS_REGION environment variable is required when using secrets manager")
		}
	}

	// Disable fallback to environment variables for pure secrets mode
	store, err := environment.NewSecretsManagerStore(awsRegion, postgresSecretName, appConfigSecretName, false)
	if err != nil {
		return nil, fmt.Errorf("failed to create secrets manager store: %w", err)
	}

	return NewService(store)
}

// ParseUseSecretsManagerFlag parses the USE_SECRETS_MANAGER environment variable
func ParseUseSecretsManagerFlag() bool {
	useSecretsManager := os.Getenv("USE_SECRETS_MANAGER")
	if useSecretsManager == "" {
		return false
	}

	result, err := strconv.ParseBool(useSecretsManager)
	if err != nil {
		// Default to false if parsing fails
		return false
	}

	return result
}
