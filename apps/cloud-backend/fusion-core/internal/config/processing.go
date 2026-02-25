package config

import (
	"fmt"
	"strconv"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/environment"
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

// Validation retrieves the validation configuration from the store.
func (p *Service) Validation() (*Validation, error) {
	supportedVersions, err := p.store.ReqString(environment.Validation.SupportedVersions)
	if err != nil {
		return nil, fmt.Errorf("SUPPORTED_VERSIONS environment variable is required")
	}

	requireVersion, err := p.store.ReqString(environment.Validation.RequireVersion)
	if err != nil {
		return nil, fmt.Errorf("REQUIRE_VERSION environment variable is required")
	}

	defaultVersionStr, err := p.store.ReqString(environment.Validation.DefaultVersion)
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
	maxWorkers, err := p.store.ReqString(environment.Process.MaxWorkers)
	if err != nil {
		return nil, fmt.Errorf("MAX_WORKERS environment variable is required")
	}

	batchSize, err := p.store.ReqString(environment.Process.BatchSize)
	if err != nil {
		return nil, fmt.Errorf("BATCH_SIZE environment variable is required")
	}

	retryAttempts, err := p.store.ReqString(environment.Process.RetryAttempt)
	if err != nil {
		return nil, fmt.Errorf("RETRY_ATTEMPTS environment variable is required")
	}

	retryDelay, err := p.store.ReqString(environment.Process.RetryDelay)
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
