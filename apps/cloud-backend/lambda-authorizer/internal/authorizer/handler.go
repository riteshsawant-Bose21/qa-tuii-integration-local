package authorizer

import (
	"database/sql"
	"fmt"
	"os"

	// Import postgres driver to ensure it's registered before sql.Open is called
	_ "github.com/lib/pq"

	"github.com/BoseProfessional/lambda-authorizer/internal/auth"
	"github.com/BoseProfessional/lambda-authorizer/internal/config"
	"github.com/BoseProfessional/lambda-authorizer/internal/logger"
	"github.com/BoseProfessional/lambda-authorizer/internal/permissions"
)

var (
	validator         auth.AuthValidator
	permissionChecker permissions.PermissionChecker
	initErr           error
)

func init() {
	// Use init logger (no request ID yet)
	initLogger := logger.NewLogger("INIT", "")
	initLogger.Info("Initializing Lambda authorizer")

	cfg := config.Config{
		Auth0Domain:  os.Getenv("AUTH0_DOMAIN"),
		DatabaseHost: os.Getenv("DB_HOST"),
		DatabasePort: os.Getenv("DB_PORT"),
		DatabaseUser: os.Getenv("DB_USER"),
		DatabasePass: os.Getenv("DB_PASSWORD"),
		DatabaseName: os.Getenv("DB_NAME"),
		DatabaseSSL:  os.Getenv("DB_SSLMODE"),
	}

	initLogger.WithFields("Configuration loaded", logger.LogLevelInfo, map[string]interface{}{
		"auth0_domain": cfg.Auth0Domain,
		"db_host":      cfg.DatabaseHost,
		"db_port":      cfg.DatabasePort,
		"db_name":      cfg.DatabaseName,
	})

	// Initialize Auth0 validator
	validator = auth.NewAuth0Validator(cfg.Auth0Domain)
	initLogger.LogInitialization("Auth0 validator", true, nil)

	// Build DSN with proper formatting
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		cfg.DatabaseHost,
		cfg.DatabasePort,
		cfg.DatabaseUser,
		cfg.DatabasePass,
		cfg.DatabaseName,
		cfg.DatabaseSSL,
	)

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		initLogger.LogInitialization("Database connection", false, err)
		initErr = err
		return
	}

	if err := db.Ping(); err != nil {
		initLogger.LogInitialization("Database ping", false, err)
		initErr = err
		return
	}

	initLogger.LogInitialization("Database connection", true, nil)
	permissionChecker = permissions.NewSQLPermissionChecker(db)
	initLogger.LogInitialization("Permission checker", true, nil)
	initLogger.Info("Lambda authorizer initialization complete")
}
