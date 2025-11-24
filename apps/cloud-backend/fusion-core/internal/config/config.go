package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"go.uber.org/zap"
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

	// Try environment variables first (for Lambda)
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

	// Fallback to default configuration with .env file defaults
	config.Database.Host = getEnv("POSTGRES_HOST", "localhost")
	config.Database.Port, _ = strconv.Atoi(getEnv("POSTGRES_PORT", "5432"))
	config.Database.User = getEnv("POSTGRES_USER", "fusion_cloud")
	config.Database.Password = getEnv("POSTGRES_PASS", "bose123")
	config.Database.DBName = getEnv("POSTGRES_INSTANCE", "fusion_cloud")
	config.Database.SSLMode = getEnv("DB_SSLMODE", "disable")

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
		config.Validation.SupportedVersions = []string{"1.0", "1.1", "2.0", "3.0"} // Default supported versions
	}
	config.Validation.RequireVersion = getEnv("REQUIRE_VERSION", "true") == "true"
	config.Validation.DefaultVersion = getEnv("DEFAULT_VERSION", "1.0")

	config.SchemaPath = getEnv("SCHEMA_PATH", "project-data-standard-schema.json")
	config.LogLevel = getEnv("LOG_LEVEL", "info")
	config.AWS.Region = getEnv("AWS_REGION", "us-east-2")
	config.AWS.Profile = getEnv("AWS_PROFILE", "")

	return config, nil
}

// GetDatabaseDSN returns the database connection string
func (c *Config) GetDatabaseDSN() string {
	return fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s timezone=UTC",
		c.Database.Host,
		c.Database.Port,
		c.Database.User,
		c.Database.Password,
		c.Database.DBName,
		c.Database.SSLMode,
	)
}

// SetupLogger configures the zap logger
func SetupLogger(level string) (*zap.Logger, error) {
	var zapLevel zap.AtomicLevel
	switch level {
	case "debug":
		zapLevel = zap.NewAtomicLevelAt(zap.DebugLevel)
	case "info":
		zapLevel = zap.NewAtomicLevelAt(zap.InfoLevel)
	case "warn":
		zapLevel = zap.NewAtomicLevelAt(zap.WarnLevel)
	case "error":
		zapLevel = zap.NewAtomicLevelAt(zap.ErrorLevel)
	default:
		zapLevel = zap.NewAtomicLevelAt(zap.InfoLevel)
	}

	config := zap.Config{
		Level:            zapLevel,
		Development:      false,
		Encoding:         "json",
		EncoderConfig:    zap.NewProductionEncoderConfig(),
		OutputPaths:      []string{"stdout"},
		ErrorOutputPaths: []string{"stderr"},
	}

	logger, err := config.Build()
	if err != nil {
		return nil, fmt.Errorf("failed to setup logger: %w", err)
	}

	return logger, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
