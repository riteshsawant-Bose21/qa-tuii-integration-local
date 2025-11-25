package config

import (
	"errors"
	"os"
	"strconv"
	"strings"
	"time"
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

// Config represents application configuration
type Config struct {
	Database struct {
		Host     string
		Port     int
		User     string
		Password string
		DBName   string
		SSLMode  string
	}

	Server struct {
		APIHost  string
		APIPort  string
		SyncPort string
	}

	Processing struct {
		MaxWorkers    int
		BatchSize     int
		RetryAttempts int
		RetryDelay    time.Duration
	}

	Validation struct {
		SupportedVersions []string
		RequireVersion    bool
		DefaultVersion    string
	}

	SchemaPath string
	LogLevel   string
	AWS        struct {
		Region  string
		Profile string
	}
}

// Load loads configuration from environment variables (Lambda) or file (local)
func Load() (*Config, error) {
	config := &Config{}

	// Try environment variables first
	if host := os.Getenv("POSTGRES_HOST"); host != "" {
		config.Database.Host = host
		config.Database.Port, _ = strconv.Atoi(getEnv("POSTGRES_PORT", "5432"))
		config.Database.User = getEnv("POSTGRES_USER", "postgres")
		config.Database.Password = getEnv("POSTGRES_PASS", "")
		config.Database.DBName = getEnv("POSTGRES_INSTANCE", "products")
		config.Database.SSLMode = getEnv("DB_SSLMODE", "require")

		config.Server.APIHost = getEnv("API_HOST", "localhost")
		config.Server.APIPort = getEnv("API_PORT", "8080")
		config.Server.SyncPort = getEnv("SYNC_PORT", "8080")

		config.Processing.MaxWorkers, _ = strconv.Atoi(getEnv("MAX_WORKERS", "5"))
		config.Processing.BatchSize, _ = strconv.Atoi(getEnv("BATCH_SIZE", "50"))
		config.Processing.RetryAttempts, _ = strconv.Atoi(getEnv("RETRY_ATTEMPTS", "3"))
		retryDelay := getEnv("RETRY_DELAY", "2")
		if val, err := strconv.Atoi(retryDelay); err == nil {
			config.Processing.RetryDelay = time.Duration(val) * time.Second
		} else if delay, err := time.ParseDuration(retryDelay); err == nil {
			config.Processing.RetryDelay = delay
		} else {
			config.Processing.RetryDelay = 2 * time.Second
		}

		// Validation configuration
		if supportedVersionsEnv := getEnv("SUPPORTED_VERSIONS", ""); supportedVersionsEnv != "" {
			config.Validation.SupportedVersions = strings.Split(supportedVersionsEnv, ",")
			// Trim whitespace from each version
			for i, version := range config.Validation.SupportedVersions {
				config.Validation.SupportedVersions[i] = strings.TrimSpace(version)
			}
		} else {
			config.Validation.SupportedVersions = []string{"1.0", "1.1", "2.0"} // Default supported versions
		}
		config.Validation.RequireVersion = getEnv("REQUIRE_VERSION", "true") == "true"
		config.Validation.DefaultVersion = getEnv("DEFAULT_VERSION", "1.0")

		config.LogLevel = getEnv("LOG_LEVEL", "info")
		config.AWS.Region = getEnv("AWS_REGION", "us-east-2")
		config.AWS.Profile = getEnv("AWS_PROFILE", "")
		config.SchemaPath = getEnv("SCHEMA_PATH", "project-data-standard-schema.json")

		return config, nil
	}
	return nil, errors.New("configuration not found")
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
