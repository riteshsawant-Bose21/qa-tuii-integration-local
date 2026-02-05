package types

type EnvironmentAPIVariables struct {
	Host        string
	Port        string
	ReleaseMode string
	LogLevel    string
	LogDir      string
	SwaggerHost string
}

type EnvironmentDBVariables struct {
	Port     string
	Host     string
	User     string
	Password string
	Instance string
	SSLMode  string
}

type EnvironmentS3Variables struct {
	PriceBucket   string
	ProjectBucket string
	ProductBucket string
}

type EnvironmentAWSVariables struct {
	Region string
}

type EnvironmentAuth0Variables struct {
	Domain                           string
	ClientID                         string
	ClientSecret                     string
	ResourceOwnerPasswordFlowEnabled string
	TestUserDefaultPassword          string
	AccessTokenEndpoint              string
}

type EnvironmentProcessVariables struct {
	MaxWorkers   string
	BatchSize    string
	RetryAttempt string
	RetryDelay   string
}

type EnvironmentValidationVariables struct {
	RequireVersion    string
	DefaultVersion    string
	SupportedVersions string
}
