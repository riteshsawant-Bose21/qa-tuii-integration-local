// Package types provides data structures for API request/response handling and configuration.
package types

// EnvironmentAPIVariables holds configuration variables for the API server.
type EnvironmentAPIVariables struct {
	Host        string
	Port        string
	ReleaseMode string
	LogLevel    string
	LogDir      string
	SwaggerHost string
}

// EnvironmentDBVariables holds configuration variables for database connection.
type EnvironmentDBVariables struct {
	Port     string
	Host     string
	User     string
	Password string
	Instance string
	SSLMode  string
}

// EnvironmentS3Variables holds configuration variables for S3 storage.
type EnvironmentS3Variables struct {
	PriceBucket   string
	ProjectBucket string
	ProductBucket string
}

// EnvironmentAWSVariables holds configuration variables for AWS services.
type EnvironmentAWSVariables struct {
	Region string
}

// EnvironmentIoTVariables holds configuration variables for IoT services.
type EnvironmentIoTVariables struct {
	Endpoint     string
	CommandTopic string
	DevicePolicy string
}

// EnvironmentAuth0Variables holds configuration variables for Auth0 integration.
type EnvironmentAuth0Variables struct {
	Domain                           string
	ClientID                         string
	ClientSecret                     string
	ResourceOwnerPasswordFlowEnabled string
	TestUserDefaultPassword          string
	AccessTokenEndpoint              string
}

// EnvironmentProcessVariables holds configuration variables for processing operations.
type EnvironmentProcessVariables struct {
	MaxWorkers   string
	BatchSize    string
	RetryAttempt string
	RetryDelay   string
}

// EnvironmentValidationVariables holds configuration variables for data validation.
type EnvironmentValidationVariables struct {
	RequireVersion    string
	DefaultVersion    string
	SupportedVersions string
}
