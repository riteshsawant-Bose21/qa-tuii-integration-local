// Package api provides HTTP routing and endpoint definitions for the REST API.
package api

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// registerRoutes sets up the API routes.
// Authentication and authorization are handled by the lambda-authorizer. The extract user middleware is used to pull user
// info from headers set by the authorizer and make it available to handlers via context.
func (a *API) registerRoutes() {
	v1 := a.engine.Group(constants.APIV1Path)

	// Swagger documentation route
	a.engine.GET(constants.EndpointDocs, ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Product routes (no authentication required)
	productHandler := handler.NewProductHandler(a.product)
	products := v1.Group(constants.EndpointProducts)
	products.Use(middleware.ExtractUserFromHeaders())
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET(constants.EndpointProductByID, productHandler.GetProductByID)
		products.GET(constants.EndpointProductPrices, productHandler.GetProductPrices)
	}

	// Project routes (auth handled by lambda-authorizer)
	projectHandler := handler.NewProjectHandler(a.project)
	projects := v1.Group(constants.EndpointProjects)
	{
		// Extract user context from headers set by API Gateway/Lambda authorizer
		projects.Use(middleware.ExtractUserFromHeaders())

		projects.POST("", projectHandler.CreateProject)
		projects.GET("", projectHandler.GetAllProjects)
		projects.PATCH(constants.EndpointProjectByID, projectHandler.UpdateProject)
		projects.DELETE(constants.EndpointProjectByID, projectHandler.DeleteProject)
		projects.PUT(constants.EndpointProjectAssignUser, projectHandler.AssignUserToProject)
		projects.DELETE(constants.EndpointProjectRemoveUser, projectHandler.RemoveUserFromProject)
		projects.POST(constants.EndpointProjectStar, projectHandler.UpdateProjectStar)
		projects.POST(constants.EndpointProjectArchive, projectHandler.UpdateProjectArchive)
		projects.POST(constants.EndpointProjectLock, projectHandler.UpdateProjectLock)
	}

	// User routes (auth handled by lambda-authorizer)
	userHandler := handler.NewUserHandler(a.user)
	users := v1.Group(constants.EndpointUsers)

	// Extract user context from headers set by API Gateway/Lambda authorizer
	users.Use(middleware.ExtractUserFromHeaders())

	{
		users.GET(constants.EndpointAuthorization, userHandler.GetUserAuthorization)
		users.POST("", userHandler.CreateUser)
		users.GET(constants.EndpointUserByEmail, userHandler.GetUserByEmail)
		users.PATCH(constants.EndpointUserByID, userHandler.UpdateUser)
	}

	// user profile management routes (/user/profile/*)
	userProfile := users.Group(constants.EndpointUserProfile)
	userProfile.Use(middleware.ExtractUserFromHeaders())
	{
		userProfile.GET("", userHandler.GetUserProfileDetails)
		userProfile.POST("", userHandler.CreateUserProfile)
		userProfile.PUT(constants.EndpointUserProfileByID, userHandler.UpdateUserProfile)
	}

	// user settings management routes (/user/settings/*)
	userSettings := users.Group(constants.EndpointUserSettings)
	userSettings.Use(middleware.ExtractUserFromHeaders())
	{
		userSettings.GET("", userHandler.GetUserSettings)
		userSettings.POST("", userHandler.CreateUserSettings)
		userSettings.PUT(constants.EndpointUserSettingsByID, userHandler.UpdateUserSettings)
	}

	// Auth endpoints
	auth := v1.Group(constants.EndpointAuth)

	// Auth automation route (no authentication required)
	if a.auth != nil {
		authHandler := handler.NewAuthHandler(a.auth)
		auth.GET(constants.EndpointAuthTokens, authHandler.GetAuthTokensByResourceOwnerPassword)
	}

	// Role Management routes for organization admins (auth handled by lambda-authorizer)
	roleManagementHandler := handler.NewRoleManagementHandler(a.user, a.roleManagementService)
	organization := v1.Group(constants.EndpointOrganization)

	organization.Use(middleware.ExtractUserFromHeaders())
	{
		organization.GET(constants.EndpointRoleManagement, roleManagementHandler.GetOrganizationRoleManagement)
		organization.POST(constants.EndpointRoles, roleManagementHandler.CreateRole)
		organization.PUT(constants.EndpointUserRole, roleManagementHandler.UpdateUserRole)
		organization.PUT(constants.EndpointRolePermissions, roleManagementHandler.UpdateRolePermissions)
		organization.GET(constants.EndpointOrganizationUsers, roleManagementHandler.GetOrganizationUsers)
	}

	// Device routes with authentication and access control
	deviceHandler := handler.NewDeviceHandler(a.device)
	devices := v1.Group(constants.EndpointDevices)

	{
		devices.Use(middleware.ExtractUserFromHeaders())
		devices.POST("", deviceHandler.CreateDevice)
		devices.POST(constants.EndpointDeviceBulkCreate, deviceHandler.BulkCreateDevices)
		devices.PATCH(constants.EndpointDeviceByID, deviceHandler.UpdateDevice)
		devices.DELETE(constants.EndpointDeviceReset, deviceHandler.ResetDevice)
		devices.POST(constants.EndpointDeviceClaim, deviceHandler.ClaimDevice)
		devices.POST(constants.EndpointDeviceRotateCert, deviceHandler.RotateCertificate)
		devices.POST(constants.EndpointDeviceCommand, deviceHandler.Command)
		devices.GET(constants.EndpointCommandStatus, deviceHandler.GetCommandStatus)
	}
}
