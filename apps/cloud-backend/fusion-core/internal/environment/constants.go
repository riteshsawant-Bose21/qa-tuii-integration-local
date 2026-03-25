// Package environment provides environment-specific constants and configuration.
package environment

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// All the environment variable's keys are mentioned here
var (
	API = types.EnvironmentAPIVariables{
		Host:        "API_HOST",
		Port:        "API_PORT",
		ReleaseMode: "RELEASE_MODE",
		LogLevel:    "LOG_LEVEL",
		LogDir:      "LOG_DIR",
		SwaggerHost: "SWAGGER_HOST",
	}

	DB = types.EnvironmentDBVariables{
		Port:     "POSTGRES_PORT",
		Host:     "POSTGRES_HOST",
		User:     "POSTGRES_USER",
		Password: "POSTGRES_PASS",
		Instance: "POSTGRES_INSTANCE",
		SSLMode:  "POSTGRES_SSL_MODE",
	}

	S3 = types.EnvironmentS3Variables{
		PriceBucket:          "S3_PRICE_BUCKET",
		ProjectBucket:        "S3_PROJECT_BUCKET",
		ProductBucket:        "S3_PRODUCT_BUCKET",
		FirmwareBundleBucket: "S3_FIRMWARE_BUNDLE_BUCKET",
	}

	AWS = types.EnvironmentAWSVariables{
		Region: "AWS_REGION",
	}

	IOT = types.EnvironmentIoTVariables{
		Endpoint: "IOT_ENDPOINT",
		CommandTopic: "IOT_COMMAND_TOPIC",
		DevicePolicy: "IOT_DEVICE_POLICY",
	}

	Auth0 = types.EnvironmentAuth0Variables{
		Domain:                           "AUTH0_DOMAIN",
		ClientID:                         "AUTH0_CLIENT_ID",
		ClientSecret:                     "AUTH0_CLIENT_SECRET",
		ResourceOwnerPasswordFlowEnabled: "AUTH0_RESOURCE_OWNER_PASSWORD_FLOW_ENABLED",
		TestUserDefaultPassword:          "AUTH0_TEST_USER_DEFAULT_PASSWORD",
		AccessTokenEndpoint:              "AUTH0_ACCESS_TOKEN_ENDPOINT",
	}

	Process = types.EnvironmentProcessVariables{
		MaxWorkers:   "MAX_WORKERS",
		BatchSize:    "BATCH_SIZE",
		RetryAttempt: "RETRY_ATTEMPTS",
		RetryDelay:   "RETRY_DELAY",
	}

	Validation = types.EnvironmentValidationVariables{
		RequireVersion:    "REQUIRE_VERSION",
		DefaultVersion:    "DEFAULT_VERSION",
		SupportedVersions: "SUPPORTED_VERSIONS",
	}
)
