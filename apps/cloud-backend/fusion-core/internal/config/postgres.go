package config

import (
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

	return &Postgres{
		Host:     host,
		Port:     port,
		User:     user,
		Password: password,
		Database: database,
	}, nil
}

// Server retrieves the server configuration from the store.
func (p *Service) Server() (*Server, error) {
	apiHost, err := p.store.ReqString(keyAPIHost)
	if err != nil {
		apiHost = defaultAPIHost
	}

	apiPort, err := p.store.ReqString(keyAPIPort)
	if err != nil {
		apiPort = defaultAPIPort
	}

	syncPort, err := p.store.ReqString(keySyncPort)
	if err != nil {
		syncPort = defaultSyncPort
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
		region = defaultAWSRegion
	}

	profile, err := p.store.ReqString(keyAWSProfile)
	if err != nil {
		profile = defaultAWSProfile
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
		supportedVersions = defaultSupportedVersions
	}

	requireVersion, err := p.store.ReqString(keyRequireVersion)
	if err != nil {
		requireVersion = defaultRequireVersion
	}

	defaultVersionStr, err := p.store.ReqString(keyDefaultVersion)
	if err != nil {
		defaultVersionStr = defaultVersion
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
		maxWorkers = defaultMaxWorkers
	}

	batchSize, err := p.store.ReqString(keyBatchSize)
	if err != nil {
		batchSize = defaultBatchSize
	}

	retryAttempts, err := p.store.ReqString(keyRetryAttempts)
	if err != nil {
		retryAttempts = defaultRetryAttempts
	}

	retryDelay, err := p.store.ReqString(keyRetryDelay)
	if err != nil {
		retryDelay = defaultRetryDelay
	}

	maxWorkersInt, _ := strconv.Atoi(maxWorkers)
	if maxWorkersInt <= 0 {
		maxWorkersInt = defaultMaxWorkersInt
	}

	batchSizeInt, _ := strconv.Atoi(batchSize)
	if batchSizeInt <= 0 {
		batchSizeInt = defaultBatchSizeInt
	}

	retryAttemptsInt, _ := strconv.Atoi(retryAttempts)
	if retryAttemptsInt < 0 {
		retryAttemptsInt = defaultRetryAttemptsInt
	}

	return &Processing{
		MaxWorkers:    maxWorkersInt,
		BatchSize:     batchSizeInt,
		RetryAttempts: retryAttemptsInt,
		RetryDelay:    retryDelay,
	}, nil
}

// DO WE NEED DEFAULTS?
// const (
// 	defaultPostgresHost string = "127.0.0.1"
// 	defaultPostgresPort string = "5432"
// )

// Default configuration values
const (
	// Server defaults
	defaultAPIHost  = "localhost"
	defaultAPIPort  = "8080"
	defaultSyncPort = "8080"

	// AWS defaults
	defaultAWSRegion  = "us-east-2"
	defaultAWSProfile = ""

	// Validation defaults
	defaultSupportedVersions = "1.0,1.1,2.0"
	defaultRequireVersion    = "true"
	defaultVersion           = "1.0"

	// Processing defaults
	defaultMaxWorkers    = "5"
	defaultBatchSize     = "50"
	defaultRetryAttempts = "3"
	defaultRetryDelay    = "2"

	// Processing integer defaults
	defaultMaxWorkersInt    = 5
	defaultBatchSizeInt     = 50
	defaultRetryAttemptsInt = 3
)

// Environment variable keys
const (
	keyPostgresHost     string = "POSTGRES_HOST"
	keyPostgresPort     string = "POSTGRES_PORT"
	keyPostgresUser     string = "POSTGRES_USER"
	keyPostgresPass     string = "POSTGRES_PASS"
	keyPostgresInstance string = "POSTGRES_INSTANCE"

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
