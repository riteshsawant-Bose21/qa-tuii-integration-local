package api

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
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
		products.GET("/:id/prices", productHandler.GetProductPrices)
	}

	// Project routes with authentication and access control
	projectHandler := handler.NewProjectHandler(a.project)
	projects := v1.Group("/projects")
	{
		// Apply auth middleware first to establish authentication
		projects.Use(a.authMiddleware.Middleware())

		// Then apply access control middleware
		projects.Use(accessControl.GlobalAccessControlMiddleware())

		projects.POST("", projectHandler.CreateProject)
		projects.GET("", projectHandler.GetAllProjects)
		projects.PATCH("/:projectId", projectHandler.UpdateProject)
		projects.DELETE("/:projectId", projectHandler.DeleteProject)
		projects.PUT("/:projectId/users/:userEmail", projectHandler.AssignUserToProject)
		projects.DELETE("/:projectId/users/:userEmail", projectHandler.RemoveUserFromProject)
		projects.POST("/:projectId/star/:userId", projectHandler.UpdateProjectStar)
		projects.POST("/:projectId/archive", projectHandler.UpdateProjectArchive)
		projects.POST("/:projectId/lock", projectHandler.UpdateProjectLock)
	}

	// User routes with authentication
	userHandler := handler.NewUserHandler(a.user)
	user := v1.Group("/users")

	// Apply auth middleware to protected user routes
	user.Use(a.authMiddleware.Middleware())

	{
		user.GET("/authorization", userHandler.GetUserAuthorization)
		// user.GET("/profile", userHandler.GetUserProfile)
	}

	// user profile management routes (/user/profile/*)
	userProfile := user.Group("/profile")
	{
		userProfile.Use(accessControl.GlobalAccessControlMiddleware())

		userProfile.GET("", userHandler.GetUserProfileDetails)
		userProfile.POST("", userHandler.CreateUserProfile)
		userProfile.PUT("/:profileID", userHandler.UpdateUserProfile)
	}

	// user settings management routes (/user/settings/*)
	userSettings := user.Group("/settings")
	{
		userSettings.Use(accessControl.GlobalAccessControlMiddleware())

		userSettings.GET("", userHandler.GetUserSettings)
		userSettings.POST("", userHandler.CreateUserSettings)
		userSettings.PUT("/:settingsID", userHandler.UpdateUserSettings)
	}

	// Additional user management routes
	users := v1.Group("/users")
	users.Use(a.authMiddleware.Middleware())
	{
		users.POST("", userHandler.CreateUser)
		users.GET("/:email", userHandler.GetUserByEmail)
		users.PATCH("/:userID", userHandler.UpdateUser)
	}

	// Auth endpoints
	auth := v1.Group("/auth")
	
	// Auth automation route (no authentication required)
	if a.auth != nil {
		authHandler := handler.NewAuthHandler(a.auth)
		auth.GET("/automation/tokens", authHandler.GetAuthTokensByResourceOwnerPassword)
	}

	// Role Management routes for organization admins
	roleManagementHandler := handler.NewRoleManagementHandler(a.user, a.roleManagementService)
	organization := v1.Group("/organization")

	// Apply auth middleware to protected organization routes
	organization.Use(a.authMiddleware.Middleware())

	{
		organization.GET("/role-management", roleManagementHandler.GetOrganizationRoleManagement)
		organization.POST("/roles", roleManagementHandler.CreateRole)
		organization.PUT("/users/:userID/role", roleManagementHandler.UpdateUserRole)
		organization.PUT("/roles/:roleID/permissions", roleManagementHandler.UpdateRolePermissions)
		organization.GET("/users", roleManagementHandler.GetOrganizationUsers)
	}

}
