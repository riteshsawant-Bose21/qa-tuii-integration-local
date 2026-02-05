package constants

const (
	// Base API Path
	APIV1Path = "/api/v1"

	// Swagger Docs
	EndpointDocs = "/docs/*any"

	// Products
	EndpointProducts      = "/products"
	EndpointProductByID   = "/:id"
	EndpointProductPrices = "/:id/prices"

	// Projects
	EndpointProjects          = "/projects"
	EndpointProjectByID       = "/:projectId"
	EndpointProjectAssignUser = "/:projectId/users/:userEmail"
	EndpointProjectRemoveUser = "/:projectId/users/:userEmail"
	EndpointProjectStar       = "/:projectId/star/:userId"
	EndpointProjectArchive    = "/:projectId/archive"
	EndpointProjectLock       = "/:projectId/lock"

	// Users
	EndpointUsers         = "/users"
	EndpointUserByEmail   = "/:email"
	EndpointUserByID      = "/:userID"
	EndpointAuthorization = "/authorization"

	// User Profile
	EndpointUserProfile     = "/profile"
	EndpointUserProfileByID = "/:profileID"

	// User Settings
	EndpointUserSettings     = "/settings"
	EndpointUserSettingsByID = "/:settingsID"

	// Auth
	EndpointAuth       = "/auth"
	EndpointAuthTokens = "/automation/tokens"

	// Organization
	EndpointOrganization      = "/organization"
	EndpointRoleManagement    = "/role-management"
	EndpointRoles             = "/roles"
	EndpointUserRole          = "/users/:userID/role"
	EndpointRolePermissions   = "/roles/:roleID/permissions"
	EndpointOrganizationUsers = "/users"
)
