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
func (a *API) registerRoutes() {
	v1 := a.engine.Group(constants.APIV1Path)

	// Initialize Access Control Middleware
	accessControl := middleware.NewAccessControlMiddleware(a.user)

	// Setup permissions for all endpoints
	middleware.SetupCommonPermissions(accessControl)

	// Swagger documentation route
	a.engine.GET(constants.EndpointDocs, ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Product routes (no authentication required)
	productHandler := handler.NewProductHandler(a.product)
	products := v1.Group(constants.EndpointProducts)
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET(constants.EndpointProductByID, productHandler.GetProductByID)
		products.GET(constants.EndpointProductPrices, productHandler.GetProductPrices)
	}

	// Project routes with authentication and access control
	projectHandler := handler.NewProjectHandler(a.project)
	projects := v1.Group(constants.EndpointProjects)
	{
		// Apply auth middleware first to establish authentication
		projects.Use(a.authMiddleware.Middleware())

		// Then apply access control middleware
		projects.Use(accessControl.GlobalAccessControlMiddleware())

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

	// User routes with authentication
	userHandler := handler.NewUserHandler(a.user)
	users := v1.Group(constants.EndpointUsers)

	// Apply auth middleware to protected user routes
	users.Use(a.authMiddleware.Middleware())

	{
		users.GET(constants.EndpointAuthorization, userHandler.GetUserAuthorization)
		users.POST("", userHandler.CreateUser)
		users.GET(constants.EndpointUserByEmail, userHandler.GetUserByEmail)
		users.PATCH(constants.EndpointUserByID, userHandler.UpdateUser)
	}

	// user profile management routes (/user/profile/*)
	userProfile := users.Group(constants.EndpointUserProfile)
	{
		userProfile.Use(accessControl.GlobalAccessControlMiddleware())

		userProfile.GET("", userHandler.GetUserProfileDetails)
		userProfile.POST("", userHandler.CreateUserProfile)
		userProfile.PUT(constants.EndpointUserProfileByID, userHandler.UpdateUserProfile)
	}

	// user settings management routes (/user/settings/*)
	userSettings := users.Group(constants.EndpointUserSettings)
	{
		userSettings.Use(accessControl.GlobalAccessControlMiddleware())

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

	// Role Management routes for organization admins
	roleManagementHandler := handler.NewRoleManagementHandler(a.user, a.roleManagementService)
	organization := v1.Group(constants.EndpointOrganization)

	// Apply auth middleware to protected organization routes
	organization.Use(a.authMiddleware.Middleware())

	{
		organization.GET(constants.EndpointRoleManagement, roleManagementHandler.GetOrganizationRoleManagement)
		organization.POST(constants.EndpointRoles, roleManagementHandler.CreateRole)
		organization.PUT(constants.EndpointUserRole, roleManagementHandler.UpdateUserRole)
		organization.PUT(constants.EndpointRolePermissions, roleManagementHandler.UpdateRolePermissions)
		organization.GET(constants.EndpointOrganizationUsers, roleManagementHandler.GetOrganizationUsers)
	}

	firmwareUpdate := v1.Group(constants.EndpointFirmware)
	firmwareHandler := handler.NewFirmwareUpdateHandler(a.firmware)

	{
		// Internal APIs - TODO: Add Authentication
		firmwareUpdate.POST(constants.EndpointFirmwareBundles, firmwareHandler.NotifyBundleUpload)
		firmwareUpdate.POST(constants.EndpointFirmwareInitiateRelease, firmwareHandler.InitiateRelease)
		firmwareUpdate.POST(constants.EndpointFirmwareMakeAvailable, firmwareHandler.MakeReleaseAvailable)
	}

	firmwareUpdate.Use(a.authMiddleware.Middleware())
	{
		firmwareUpdate.GET(constants.EndpointFirmwareList, firmwareHandler.ListReleases)
		firmwareUpdate.POST(constants.EndpointFirmwareDeploy, firmwareHandler.DeployRelease)
		firmwareUpdate.POST(constants.EndpointFirmwareUpdateCheck, firmwareHandler.CheckUpdates)
		firmwareUpdate.GET(constants.EndpointFirmwareDownload, firmwareHandler.DownloadArtifact)
		firmwareUpdate.POST(constants.EndpointFirmwareUpdateLog, firmwareHandler.LogFirmwareUpdate)
	}

}
