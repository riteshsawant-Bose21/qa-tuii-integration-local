package api

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/auth"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"go.uber.org/zap"

	"github.com/gin-gonic/gin"
)

// API is a service for the main API.
type API struct {
	engine                *gin.Engine
	server                *http.Server
	product               fusion.Product
	project               fusion.Project
	user                  fusion.User
	auth                  fusion.Auth
	roleManagementService *userdb.RoleManagementService
	authMiddleware        middleware.AuthMiddleware
	appLog                *zap.Logger
}

type Config struct {
	Mode        string // "debug" or "release"
	Host        string
	Port        string
	Auth0Domain string
}

// New returns a new API from the given services.
func New(cfg *Config,
	productSvc fusion.Product,
	project fusion.Project,
	userSvc fusion.User,
	authSvc fusion.Auth,
	loggers *log.Loggers,
) (*API, error) {

	if cfg.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize engine with proper configuration
	engine := gin.New()

	// Add middleware in proper order
	engine.Use(gin.Recovery())
	engine.Use(corsMiddleware())                                          // CORS if needed
	engine.Use(middleware.RequestLoggerMiddleware(loggers.AuditLogger))   // Use audit logger for requests
	engine.Use(middleware.ApplicationLoggerMiddleware(loggers.AppLogger)) // Add app logger to context

	if productSvc == nil {
		return nil, errors.New("missing product service")
	}

	if project == nil {
		return nil, errors.New("missing project service")
	}

	if userSvc == nil {
		return nil, errors.New("missing user service")
	}

	if authSvc == nil {
		return nil, errors.New("missing auth service")
	}

	// Initialize Auth0 validator and middleware
	if cfg.Auth0Domain == "" {
		return nil, errors.New("Auth0Domain is required for authentication")
	}
	auth0Config := auth.Auth0Config{
		Domain: cfg.Auth0Domain,
	}

	auth0Validator := auth.NewAuth0Validator(auth0Config)
	authMiddleware := middleware.NewAuth0Middleware(auth0Validator)

	api := &API{
		engine:         engine,
		product:        productSvc,
		project:        project,
		user:           userSvc,
		auth:           authSvc,
		authMiddleware: authMiddleware,
		appLog:         loggers.AppLogger,
	}

	api.registerRoutes()
	// Configure HTTP server
	api.server = &http.Server{
		Addr:         fmt.Sprintf("%s:%s", cfg.Host, cfg.Port),
		Handler:      engine,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	return api, nil
}

func (s *API) Start(ctx context.Context) error {
	s.appLog.Info("Starting HTTP server", zap.String("addr", s.server.Addr))

	// Start server in goroutine
	errChan := make(chan error, 1)
	go func() {
		if err := s.server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			errChan <- err
		}
	}()

	// Wait for context cancellation or server error
	select {
	case <-ctx.Done():
		return s.shutdown()
	case err := <-errChan:
		s.appLog.Error("HTTP server error", zap.Error(err))
		return err
	}
}

// shutdown gracefully shuts down the server.
func (s *API) shutdown() error {
	s.appLog.Info("Shutting down HTTP server...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	err := s.server.Shutdown(ctx)
	s.appLog.Sync() // Ensure logs are flushed before shutdown
	return err
}

// Engine returns the underlying Gin engine for testing purposes
func (s *API) Engine() *gin.Engine {
	return s.engine
}

// AuditLogger returns the audit logger for external use
func (s *API) AuditLogger() *zap.Logger {
	return s.appLog
}

// AppLogger returns the application logger for external use
func (s *API) AppLogger() *zap.Logger {
	return s.appLog
}

// corsMiddleware adds CORS headers
func corsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
