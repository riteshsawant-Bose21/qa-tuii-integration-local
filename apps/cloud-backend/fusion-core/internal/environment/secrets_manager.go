package environment

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

// SecretsManagerStore implements the Store interface using AWS Secrets Manager
type SecretsManagerStore struct {
	client              *secretsmanager.Client
	postgresSecretName  string
	appConfigSecretName string
	secretsCache        map[string]map[string]string
	fallbackToEnv       bool
}

// NewSecretsManagerStore creates a new secrets manager store
func NewSecretsManagerStore(region, postgresSecretName, appConfigSecretName string, fallbackToEnv bool) (*SecretsManagerStore, error) {
	cfg, err := config.LoadDefaultConfig(context.TODO(),
		config.WithRegion(region),
	)
	if err != nil {
		return nil, fmt.Errorf("unable to load AWS SDK config: %w", err)
	}

	client := secretsmanager.NewFromConfig(cfg)

	store := &SecretsManagerStore{
		client:              client,
		postgresSecretName:  postgresSecretName,
		appConfigSecretName: appConfigSecretName,
		secretsCache:        make(map[string]map[string]string),
		fallbackToEnv:       fallbackToEnv,
	}

	// Try to pre-load secrets
	if err := store.loadSecrets(); err != nil {
		return nil, fmt.Errorf("failed to load secrets: %w", err)
	}

	return store, nil
}

// loadSecrets loads both postgres and app config secrets
func (s *SecretsManagerStore) loadSecrets() error {
	// Load Postgres secrets
	if err := s.loadSecret(s.postgresSecretName); err != nil {
		return fmt.Errorf("failed to load postgres secrets: %w", err)
	}

	// Load App config secrets
	if err := s.loadSecret(s.appConfigSecretName); err != nil {
		return fmt.Errorf("failed to load app config secrets: %w", err)
	}

	return nil
}

// loadSecret loads a specific secret and caches it
func (s *SecretsManagerStore) loadSecret(secretName string) error {
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretName),
	}

	result, err := s.client.GetSecretValue(context.TODO(), input)
	if err != nil {
		return fmt.Errorf("failed to retrieve secret %s: %w", secretName, err)
	}

	if result.SecretString == nil {
		return fmt.Errorf("secret %s has no string value", secretName)
	}

	// Parse the secret as a generic map first to handle mixed data types
	var rawSecretData map[string]interface{}
	if err := json.Unmarshal([]byte(*result.SecretString), &rawSecretData); err != nil {
		return fmt.Errorf("failed to parse secret %s: %w", secretName, err)
	}

	// Convert all values to strings
	secretData := make(map[string]string)
	for key, value := range rawSecretData {
		secretData[key] = fmt.Sprintf("%v", value)
	}

	s.secretsCache[secretName] = secretData
	fmt.Printf("Successfully loaded secret: %s\n", secretName)
	return nil
}

// ReqString retrieves a string value from the secrets or environment
func (s *SecretsManagerStore) ReqString(key string) (string, error) {
	// First, try to find the key in cached secrets
	for _, secretData := range s.secretsCache {
		if value, exists := secretData[key]; exists {
			return value, nil
		}

		// Handle AWS RDS secret key mapping (from fusion-rds)
		switch key {
		case "POSTGRES_USER":
			if value, exists := secretData["username"]; exists {
				return value, nil
			}
		case "POSTGRES_PASS":
			if value, exists := secretData["password"]; exists {
				return value, nil
			}
		case "POSTGRES_HOST":
			if value, exists := secretData["host"]; exists {
				return value, nil
			}
		case "POSTGRES_PORT":
			if value, exists := secretData["port"]; exists {
				return fmt.Sprintf("%v", value), nil
			}
		case "POSTGRES_INSTANCE":
			if value, exists := secretData["dbname"]; exists {
				return value, nil
			}
		}

		// Handle application config keys (from fusion-sync-jobs)
		// These should be directly available in the secret
		switch key {
		case "API_HOST", "API_PORT", "SYNC_PORT", "AWS_REGION", "AWS_PROFILE",
			"SUPPORTED_VERSIONS", "REQUIRE_VERSION", "DEFAULT_VERSION",
			"MAX_WORKERS", "BATCH_SIZE", "RETRY_ATTEMPTS", "RETRY_DELAY",
			"POSTGRES_SSL_MODE":
			if value, exists := secretData[key]; exists {
				return value, nil
			}
		}
	} // If fallback to environment is enabled, try environment variables
	if s.fallbackToEnv {
		if value := os.Getenv(key); value != "" {
			return value, nil
		}
	}

	return "", fmt.Errorf("key %s not found in secrets manager or environment", key)
}

// Load method for compatibility with LoadLookuper interface (no-op for secrets manager)
func (s *SecretsManagerStore) Load(filenames ...string) error {
	// Secrets are already loaded during initialization
	return nil
}

// Lookup method for compatibility with LoadLookuper interface
func (s *SecretsManagerStore) Lookup(key string) (string, bool) {
	value, err := s.ReqString(key)
	if err != nil {
		return "", false
	}
	return value, true
}
