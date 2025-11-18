package api

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// registerRoutes sets up the API routes.
func (a *API) registerRoutes() {
	v1 := a.engine.Group("/api/v1")

	// Initialize Access Control Middleware
	accessControl := middleware.NewAccessControlMiddleware(a.user)

	// Setup permissions for all endpoints
	middleware.SetupCommonPermissions(accessControl)

	// Swagger documentation route
	a.engine.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Product routes (no authentication required)
	productHandler := handler.NewProductHandler(a.product)
	products := v1.Group("/products")
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET("/:id", productHandler.GetProductByID)
	}

	// Project routes with authentication and access control
	projectHandler := handler.NewProjectHandler(a.project)
	projects := v1.Group("/projects")
	{
		// Apply Auth0 middleware first to establish authentication
		if a.auth0Validator != nil {
			projects.Use(middleware.Auth0Middleware(a.auth0Validator))
		}

		// Then apply access control middleware
		projects.Use(accessControl.GlobalAccessControlMiddleware())

		projects.POST("", projectHandler.CreateProject)
		projects.GET("/:id", projectHandler.GetProjectByID)
		projects.GET("", projectHandler.GetAllProjects) // Optional: List all projects
		projects.PATCH("/:id", projectHandler.UpdateProject)
		projects.DELETE("/:id", projectHandler.DeleteProject)

		projects.POST("/:id/sync", projectHandler.SyncProject) // New route for syncing a project
	}

	// User routes with Auth0 authentication
	userHandler := handler.NewUserHandler(a.user)
	user := v1.Group("/user")

	// Apply Auth0 middleware to protected user routes
	if a.auth0Validator != nil {
		user.Use(middleware.Auth0Middleware(a.auth0Validator))
	}

	{
		user.GET("/me/authorization", userHandler.GetUserAuthorization)
		user.GET("/me/profile", userHandler.GetUserProfile)
	}

	// Additional user management routes
	users := v1.Group("/users")
	if a.auth0Validator != nil {
		users.Use(middleware.Auth0Middleware(a.auth0Validator))
	}
	{
		users.POST("", userHandler.CreateUser)
		users.GET("/:email", userHandler.GetUserByEmail)
		users.PATCH("/:userID", userHandler.UpdateUser)
	}

	// Auth status endpoint
	auth := v1.Group("/auth")
	if a.auth0Validator != nil {
		auth.Use(middleware.Auth0Middleware(a.auth0Validator))
	}
	{
		auth.GET("/status", userHandler.CheckAuthStatus)
	}

	// Role Management routes for organization admins
	roleManagementHandler := handler.NewRoleManagementHandler(a.user, a.roleManagementService)
	organization := v1.Group("/organization")

	// Apply Auth0 middleware to protected organization routes
	if a.auth0Validator != nil {
		organization.Use(middleware.Auth0Middleware(a.auth0Validator))
	}

	{
		organization.GET("/role-management", roleManagementHandler.GetOrganizationRoleManagement)
		organization.POST("/roles", roleManagementHandler.CreateRole)
		organization.PUT("/users/:userID/role", roleManagementHandler.UpdateUserRole)
		organization.PUT("/roles/:roleID/permissions", roleManagementHandler.UpdateRolePermissions)
		organization.GET("/users", roleManagementHandler.GetOrganizationUsers)
	}
}
