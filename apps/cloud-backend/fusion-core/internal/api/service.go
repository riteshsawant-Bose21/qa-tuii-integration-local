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
	userprofile "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/profile"
	usersettings "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/settings"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"github.com/gin-gonic/gin"
)

// API is a service for the main API.
type API struct {
	engine                *gin.Engine
	server                *http.Server
	product               fusion.Product
	project               fusion.Project
	user                  fusion.User
	roleManagementService *userdb.RoleManagementService
	userProfileSvc        *userprofile.Service
	userSettingsSvc       *usersettings.Service
	authMiddleware        middleware.AuthMiddleware
}

type Config struct {
	Mode        string // "debug" or "release"
	Host        string
	Port        string
	Auth0Domain string
}

// New returns a new API from the given services.
func New(cfg *Config,
	// productSvc fusion.Product,
	// projectSvc fusion.Project,
	userSvc fusion.User,
	userDBSvc *userdb.Service,
	roleManagementSvc *userdb.RoleManagementService,
	userProfileSvc *userprofile.Service,
	userSettingsSvc *usersettings.Service,
) (*API, error) {

	if cfg.Mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Initialize engine with proper configuration
	engine := gin.New()

	// Add middleware
	engine.Use(gin.Recovery())
	// engine.Use(ginLogger(logger)) // Custom logging middleware
	engine.Use(corsMiddleware()) // CORS if needed

	// if productSvc == nil {
	// 	return nil, errors.New("missing product service")
	// }

	// if projectSvc == nil {
	// 	return nil, errors.New("missing project service")
	// }

	if userSvc == nil {
		return nil, errors.New("missing user service")
	}

	if userProfileSvc == nil {
		return nil, errors.New("missing user profile service")
	}

	if userSettingsSvc == nil {
		return nil, errors.New("missing user settings service")
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
		engine: engine,
		// product:               productSvc,
		// project:               projectSvc,
		user:                  userSvc,
		roleManagementService: roleManagementSvc,
		userProfileSvc:        userProfileSvc,
		userSettingsSvc:       userSettingsSvc,
		authMiddleware:        authMiddleware,
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
	// s.logger.Info("Starting HTTP server", zap.String("addr", s.server.Addr))

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
		return err
	}
}

// shutdown gracefully shuts down the server.
func (s *API) shutdown() error {
	// s.logger.Info("Shutting down HTTP server...")
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	return s.server.Shutdown(ctx)
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
