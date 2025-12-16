package environment

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/joho/godotenv"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Configuration for AWS Secrets Manager
var (
	UseSecretsManager bool
	AWSRegion         string
	RDSSecretName     string
	AppSecretName     string
)

// Internal state for secrets manager
var (
	secretsClient   *secretsmanager.Client
	rdsSecret       map[string]string
	appConfigSecret map[string]string
	secretsLoaded   bool
)

var DefaultLoadLookuper = defaultLoadLookuperService{}

// defaultLoadLookuperService is the unified implementation of LoadLookuper
type defaultLoadLookuperService struct{}

// Load loads environment variables from the specified files or AWS Secrets Manager
func (d defaultLoadLookuperService) Load(filenames ...string) error {
	fmt.Printf("[DEBUG] Load called with UseSecretsManager=%t, files=%v\n", UseSecretsManager, filenames)
	if UseSecretsManager {
		fmt.Printf("[DEBUG] Using AWS Secrets Manager for configuration\n")
		err := d.loadFromSecretsManager()
		if err != nil {
			return err
		}
		// Also load local .env file for fallback values
		fmt.Printf("[DEBUG] Loading local .env file for fallback values\n")
		err = godotenv.Load(filenames...)
		if err != nil {
			fmt.Printf("[DEBUG] Warning: could not load .env file for fallback: %v\n", err)
		}
		return nil
	}
	fmt.Printf("[DEBUG] Using local .env file for configuration\n")
	return godotenv.Load(filenames...)
}

// Lookup retrieves the value of the environment variable from local env or AWS Secrets Manager
func (d defaultLoadLookuperService) Lookup(key string) (string, bool) {
	if UseSecretsManager {
		value, found := d.lookupFromSecrets(key)
		if found {
			return value, true
		}
		// Fallback to local environment if not found in secrets
		fmt.Printf("[DEBUG] Key '%s' not found in secrets, falling back to local environment\n", key)
		return os.LookupEnv(key)
	}
	return os.LookupEnv(key)
}

// loadFromSecretsManager loads configuration from AWS Secrets Manager
func (d defaultLoadLookuperService) loadFromSecretsManager() error {
	if secretsLoaded {
		fmt.Printf("[DEBUG] Secrets already loaded, skipping\n")
		return nil // Already loaded
	}

	fmt.Printf("[DEBUG] Loading secrets from AWS Secrets Manager...\n")
	fmt.Printf("[DEBUG] AWS Region: %s\n", AWSRegion)
	fmt.Printf("[DEBUG] RDS Secret Name: %s\n", RDSSecretName)
	fmt.Printf("[DEBUG] App Secret Name: %s\n", AppSecretName)

	// Initialize AWS client if not done
	if secretsClient == nil {
		fmt.Printf("[DEBUG] Initializing AWS Secrets Manager client...\n")
		cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(AWSRegion))
		if err != nil {
			fmt.Printf("[ERROR] Failed to load AWS config: %v\n", err)
			return fmt.Errorf("failed to load AWS config: %w", err)
		}
		secretsClient = secretsmanager.NewFromConfig(cfg)
		fmt.Printf("[DEBUG] AWS Secrets Manager client initialized successfully\n")
	}

	// Load RDS secret
	fmt.Printf("[DEBUG] Loading RDS secret: %s\n", RDSSecretName)
	rdsSecretData, err := d.getSecretAsMap(RDSSecretName)
	if err != nil {
		fmt.Printf("[ERROR] Failed to load RDS secret '%s': %v\n", RDSSecretName, err)
		return fmt.Errorf("failed to load RDS secret '%s': %w", RDSSecretName, err)
	}
	rdsSecret = rdsSecretData
	fmt.Printf("[DEBUG] RDS secret loaded successfully with %d keys\n", len(rdsSecret))

	// Load app config secret
	fmt.Printf("[DEBUG] Loading app config secret: %s\n", AppSecretName)
	appSecretData, err := d.getSecretAsMap(AppSecretName)
	if err != nil {
		fmt.Printf("[ERROR] Failed to load app config secret '%s': %v\n", AppSecretName, err)
		return fmt.Errorf("failed to load app config secret '%s': %w", AppSecretName, err)
	}
	appConfigSecret = appSecretData
	fmt.Printf("[DEBUG] App config secret loaded successfully with %d keys\n", len(appConfigSecret))

	secretsLoaded = true
	fmt.Printf("[DEBUG] All secrets loaded successfully\n")
	return nil
}

// lookupFromSecrets looks up configuration from AWS Secrets Manager
func (d defaultLoadLookuperService) lookupFromSecrets(key string) (string, bool) {
	fmt.Printf("[DEBUG] Looking up key '%s' from secrets\n", key)
	if !secretsLoaded {
		fmt.Printf("[ERROR] Secrets not loaded, cannot lookup key '%s'\n", key)
		return "", false
	}

	// Map environment variable names to secret keys and sources
	switch key {
	// Database configuration from RDS secret
	case "POSTGRES_HOST":
		return d.lookupInSecret(rdsSecret, "host")
	case "POSTGRES_PORT":
		if port, ok := d.lookupInSecret(rdsSecret, "port"); ok {
			return port, true
		}
		return "", false
	case "POSTGRES_USER":
		return d.lookupInSecret(rdsSecret, "username")
	case "POSTGRES_PASS":
		return d.lookupInSecret(rdsSecret, "password")
	case "POSTGRES_INSTANCE":
		return d.lookupInSecret(rdsSecret, "dbname")

	// Application configuration from app config secret
	case "API_HOST", "API_PORT", "SYNC_PORT", "AWS_REGION", "AWS_PROFILE",
		"SUPPORTED_VERSIONS", "REQUIRE_VERSION", "DEFAULT_VERSION",
		"MAX_WORKERS", "BATCH_SIZE", "RETRY_ATTEMPTS", "RETRY_DELAY",
		"POSTGRES_SSL_MODE":
		fmt.Printf("[DEBUG] Looking up '%s' in app config secret\n", key)
		value, found := d.lookupInSecret(appConfigSecret, key)
		if found {
			fmt.Printf("[DEBUG] Found '%s' = '%s' in app config secret\n", key, value)
			return value, found
		} else {
			fmt.Printf("[ERROR] Key '%s' not found in app config secret\n", key)
			fmt.Printf("[DEBUG] Available keys in app config secret: %v\n", getMapKeys(appConfigSecret))

			// Provide fallback values for missing keys
			switch key {
			case "API_PORT":
				fmt.Printf("[DEBUG] Using fallback value for API_PORT: 8080\n")
				return "8080", true
			case "SYNC_PORT":
				fmt.Printf("[DEBUG] Using fallback value for SYNC_PORT: 8081\n")
				return "8081", true
			case "AWS_REGION":
				fmt.Printf("[DEBUG] Using fallback value for AWS_REGION: us-east-2\n")
				return "us-east-2", true
			}
			return "", false
		}

	default:
		fmt.Printf("[ERROR] Key '%s' not handled by secrets manager\n", key)
		return "", false
	}
}

// getSecretAsMap retrieves and parses a secret as JSON
func (d defaultLoadLookuperService) getSecretAsMap(secretName string) (map[string]string, error) {
	fmt.Printf("[DEBUG] Retrieving secret: %s\n", secretName)

	input := &secretsmanager.GetSecretValueInput{
		SecretId:     aws.String(secretName),
		VersionStage: aws.String("AWSCURRENT"),
	}

	fmt.Printf("[DEBUG] Calling AWS Secrets Manager GetSecretValue...\n")
	result, err := secretsClient.GetSecretValue(context.TODO(), input)
	if err != nil {
		fmt.Printf("[ERROR] Failed to get secret %s from AWS: %v\n", secretName, err)
		return nil, fmt.Errorf("failed to get secret %s: %w", secretName, err)
	}
	fmt.Printf("[DEBUG] Successfully retrieved secret %s from AWS\n", secretName)

	if result.SecretString == nil {
		fmt.Printf("[ERROR] Secret %s has no string value\n", secretName)
		return nil, fmt.Errorf("secret %s has no string value", secretName)
	}

	fmt.Printf("[DEBUG] Parsing secret %s as JSON...\n", secretName)
	// First unmarshal into a generic map to handle mixed types
	var genericMap map[string]interface{}
	if err := json.Unmarshal([]byte(*result.SecretString), &genericMap); err != nil {
		fmt.Printf("[ERROR] Failed to parse secret %s as JSON: %v\n", secretName, err)
		fmt.Printf("[DEBUG] Secret content: %s\n", *result.SecretString)
		return nil, fmt.Errorf("failed to parse secret %s as JSON: %w", secretName, err)
	}
	fmt.Printf("[DEBUG] Successfully parsed secret %s, found %d keys\n", secretName, len(genericMap))

	// Convert all values to strings
	secretMap := make(map[string]string)
	for key, value := range genericMap {
		switch v := value.(type) {
		case string:
			secretMap[key] = v
		case float64:
			secretMap[key] = fmt.Sprintf("%.0f", v)
		case int:
			secretMap[key] = fmt.Sprintf("%d", v)
		case bool:
			secretMap[key] = fmt.Sprintf("%t", v)
		default:
			secretMap[key] = fmt.Sprintf("%v", v)
		}
	}

	fmt.Printf("[DEBUG] Secret %s converted to string map with keys: %v\n", secretName, getMapKeys(secretMap))
	return secretMap, nil
}

// lookupInSecret safely looks up a key in a secret map
func (d defaultLoadLookuperService) lookupInSecret(secretMap map[string]string, key string) (string, bool) {
	value, exists := secretMap[key]
	return value, exists
}

// getMapKeys returns the keys of a map for debugging purposes
func getMapKeys(m map[string]string) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}

// ConfigureSecretsManager configures the DefaultLoadLookuper to use AWS Secrets Manager
func ConfigureSecretsManager(useSecrets bool, region, rdsSecretName, appSecretName string) {
	UseSecretsManager = useSecrets
	AWSRegion = region
	RDSSecretName = rdsSecretName
	AppSecretName = appSecretName

	// Reset state when configuration changes
	secretsLoaded = false
	secretsClient = nil
	rdsSecret = nil
	appConfigSecret = nil
}

// Logger interface for the internal logger type
type InternalLogger interface {
	Info(msg string, fields ...zapcore.Field)
	Warn(msg string, fields ...zapcore.Field)
}

// AutoConfigureSecretsManager automatically configures secrets based on environment name
func AutoConfigureSecretsManager(envName string, logger InternalLogger) {
	useSecretsManager := shouldUseSecretsManager(envName)

	if useSecretsManager {
		region, rdsSecret, appSecret := getSecretsConfig(envName)
		logger.Info("Configuring AWS Secrets Manager",
			zap.String("environment", envName),
			zap.String("region", region),
			zap.String("rds_secret", rdsSecret),
			zap.String("app_secret", appSecret))
		ConfigureSecretsManager(true, region, rdsSecret, appSecret)
	} else {
		logger.Info("Using local environment variables", zap.String("environment", envName))
		ConfigureSecretsManager(false, "", "", "")
	}
}

// shouldUseSecretsManager determines if secrets manager should be used based on environment
func shouldUseSecretsManager(envName string) bool {
	switch envName {
	case "local", "development":
		return false
	case "dev", "staging", "stage", "prod", "production":
		return true
	default:
		return true // safe default
	}
}

// getSecretsConfig returns AWS configuration for the given environment
func getSecretsConfig(envName string) (region, rdsSecret, appSecret string) {
	// Get AWS region from environment variable or use default
	region = getEnvWithDefault("AWS_REGION", "us-east-2")

	// Get secret names from environment variables or use defaults (no environment suffix)
	rdsSecret = getEnvWithDefault("POSTGRES_SECRET_NAME", "fusion-rds")
	appSecret = getEnvWithDefault("APP_CONFIG_SECRET_NAME", "fusion-sync-jobs")

	return
}

// getEnvWithDefault gets environment variable or returns default value
func getEnvWithDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
