package config

import (
	"fmt"
	"strconv"
	"strings"
)

// Postgres holds the configuration settings for connecting to a PostgreSQL database.
type Postgres struct {
	Host     string
	Port     string
	User     string
	Password string
	Database string
	SSLMode  string
}

// Server holds the configuration settings for server binding.
type Server struct {
	APIHost  string
	APIPort  string
	SyncPort string
}

// AWS holds the configuration settings for AWS services.
type AWS struct {
	Region  string
	Profile string
}

// Validation holds the configuration settings for data validation.
type Validation struct {
	SupportedVersions []string
	RequireVersion    bool
	DefaultVersion    string
}

// Processing holds the configuration settings for data processing.
type Processing struct {
	MaxWorkers    int
	BatchSize     int
	RetryAttempts int
	RetryDelay    string
}

// Postgres retrieves the PostgreSQL configuration from the store.
func (p *Service) Postgres() (*Postgres, error) {
	host, err := p.store.ReqString(keyPostgresHost)
	if err != nil {
		return nil, err
	}

	port, err := p.store.ReqString(keyPostgresPort)
	if err != nil {
		return nil, err
	}

	user, err := p.store.ReqString(keyPostgresUser)
	if err != nil {
		return nil, err
	}

	password, err := p.store.ReqString(keyPostgresPass)
	if err != nil {
		return nil, err
	}

	database, err := p.store.ReqString(keyPostgresInstance)
	if err != nil {
		return nil, err
	}

	sslMode, err := p.store.ReqString(keyPostgresSSLMode)
	if err != nil {
		return nil, fmt.Errorf("POSTGRES_SSL_MODE environment variable is required")
	}

	return &Postgres{
		Host:     host,
		Port:     port,
		User:     user,
		Password: password,
		Database: database,
		SSLMode:  sslMode,
	}, nil
}

// Server retrieves the server configuration from the store.
func (p *Service) Server() (*Server, error) {
	apiHost, err := p.store.ReqString(keyAPIHost)
	if err != nil {
		return nil, fmt.Errorf("API_HOST environment variable is required")
	}

	apiPort, err := p.store.ReqString(keyAPIPort)
	if err != nil {
		return nil, fmt.Errorf("API_PORT environment variable is required")
	}

	syncPort, err := p.store.ReqString(keySyncPort)
	if err != nil {
		return nil, fmt.Errorf("SYNC_PORT environment variable is required")
	}

	return &Server{
		APIHost:  apiHost,
		APIPort:  apiPort,
		SyncPort: syncPort,
	}, nil
}

// AWS retrieves the AWS configuration from the store.
func (p *Service) AWS() (*AWS, error) {
	region, err := p.store.ReqString(keyAWSRegion)
	if err != nil {
		return nil, fmt.Errorf("AWS_REGION environment variable is required")
	}

	profile, err := p.store.ReqString(keyAWSProfile)
	if err != nil {
		return nil, fmt.Errorf("AWS_PROFILE environment variable is required")
	}

	return &AWS{
		Region:  region,
		Profile: profile,
	}, nil
}

// Validation retrieves the validation configuration from the store.
func (p *Service) Validation() (*Validation, error) {
	supportedVersions, err := p.store.ReqString(keySupportedVersions)
	if err != nil {
		return nil, fmt.Errorf("SUPPORTED_VERSIONS environment variable is required")
	}

	requireVersion, err := p.store.ReqString(keyRequireVersion)
	if err != nil {
		return nil, fmt.Errorf("REQUIRE_VERSION environment variable is required")
	}

	defaultVersionStr, err := p.store.ReqString(keyDefaultVersion)
	if err != nil {
		return nil, fmt.Errorf("DEFAULT_VERSION environment variable is required")
	}

	// Clean up the supported versions
	versions := strings.Split(supportedVersions, ",")
	for i, version := range versions {
		versions[i] = strings.TrimSpace(version)
	}

	return &Validation{
		SupportedVersions: versions,
		RequireVersion:    requireVersion == "true",
		DefaultVersion:    defaultVersionStr,
	}, nil
}

// Processing retrieves the processing configuration from the store.
func (p *Service) Processing() (*Processing, error) {
	maxWorkers, err := p.store.ReqString(keyMaxWorkers)
	if err != nil {
		return nil, fmt.Errorf("MAX_WORKERS environment variable is required")
	}

	batchSize, err := p.store.ReqString(keyBatchSize)
	if err != nil {
		return nil, fmt.Errorf("BATCH_SIZE environment variable is required")
	}

	retryAttempts, err := p.store.ReqString(keyRetryAttempts)
	if err != nil {
		return nil, fmt.Errorf("RETRY_ATTEMPTS environment variable is required")
	}

	retryDelay, err := p.store.ReqString(keyRetryDelay)
	if err != nil {
		return nil, fmt.Errorf("RETRY_DELAY environment variable is required")
	}

	maxWorkersInt, err := strconv.Atoi(maxWorkers)
	if err != nil || maxWorkersInt <= 0 {
		return nil, fmt.Errorf("MAX_WORKERS must be a positive integer, got: %s", maxWorkers)
	}

	batchSizeInt, err := strconv.Atoi(batchSize)
	if err != nil || batchSizeInt <= 0 {
		return nil, fmt.Errorf("BATCH_SIZE must be a positive integer, got: %s", batchSize)
	}

	retryAttemptsInt, err := strconv.Atoi(retryAttempts)
	if err != nil || retryAttemptsInt < 0 {
		return nil, fmt.Errorf("RETRY_ATTEMPTS must be a non-negative integer, got: %s", retryAttempts)
	}

	return &Processing{
		MaxWorkers:    maxWorkersInt,
		BatchSize:     batchSizeInt,
		RetryAttempts: retryAttemptsInt,
		RetryDelay:    retryDelay,
	}, nil
}

// Environment variable keys
const (
	keyPostgresHost     string = "POSTGRES_HOST"
	keyPostgresPort     string = "POSTGRES_PORT"
	keyPostgresUser     string = "POSTGRES_USER"
	keyPostgresPass     string = "POSTGRES_PASS"
	keyPostgresInstance string = "POSTGRES_INSTANCE"
	keyPostgresSSLMode  string = "POSTGRES_SSL_MODE"

	// Server configuration keys
	keyAPIHost  string = "API_HOST"
	keyAPIPort  string = "API_PORT"
	keySyncPort string = "SYNC_PORT"

	// AWS configuration keys
	keyAWSRegion  string = "AWS_REGION"
	keyAWSProfile string = "AWS_PROFILE"

	// Validation configuration keys
	keySupportedVersions string = "SUPPORTED_VERSIONS"
	keyRequireVersion    string = "REQUIRE_VERSION"
	keyDefaultVersion    string = "DEFAULT_VERSION"

	// Processing configuration keys
	keyMaxWorkers    string = "MAX_WORKERS"
	keyBatchSize     string = "BATCH_SIZE"
	keyRetryAttempts string = "RETRY_ATTEMPTS"
	keyRetryDelay    string = "RETRY_DELAY"
)
