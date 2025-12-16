package config

import (
	"fmt"
	"strconv"
	"strings"
)

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

const (
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
