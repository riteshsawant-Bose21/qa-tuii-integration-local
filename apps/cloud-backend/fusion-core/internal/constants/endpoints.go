package constants

const (
	// APIV1Path is the base API path for version 1.
	APIV1Path = "/api/v1"

	// EndpointDocs is the endpoint for Swagger documentation.
	EndpointDocs = "/docs/*any"

	// EndpointProducts is the base endpoint for product operations.
	EndpointProducts = "/products"
	// EndpointProductByID is the endpoint for operations on a specific product.
	EndpointProductByID = "/:id"
	// EndpointProductPrices is the endpoint for product pricing operations.
	EndpointProductPrices = "/:id/prices"

	// EndpointProjects is the base endpoint for project operations.
	EndpointProjects = "/projects"
	// EndpointProjectByID is the endpoint for operations on a specific project.
	EndpointProjectByID = "/:projectId"
	// EndpointProjectAssignUser is the endpoint for user assignment operations.
	EndpointProjectAssignUser = "/:projectId/users/:userEmail"
	// EndpointProjectRemoveUser is the endpoint for removing a user from a project.
	EndpointProjectRemoveUser = "/:projectId/users/:userEmail"
	// EndpointProjectStar is the endpoint for starring/unstarring a project by a user.
	EndpointProjectStar = "/:projectId/star/:userId"
	// EndpointProjectArchive is the endpoint for archiving a project.
	EndpointProjectArchive = "/:projectId/archive"
	// EndpointProjectLock is the endpoint for locking/unlocking a project.
	EndpointProjectLock = "/:projectId/lock"

	// EndpointUsers is the base endpoint for user operations.
	EndpointUsers = "/users"
	// EndpointUserByEmail is the endpoint for operations on a user by email.
	EndpointUserByEmail = "/:email"
	// EndpointUserByID is the endpoint for operations on a user by ID.
	EndpointUserByID = "/:userID"
	// EndpointAuthorization is the endpoint for authorization operations.
	EndpointAuthorization = "/authorization"

	// EndpointUserProfile is the base endpoint for user profile operations.
	EndpointUserProfile = "/profile"
	// EndpointUserProfileByID is the endpoint for operations on a specific user profile.
	EndpointUserProfileByID = "/:profileID"

	// EndpointUserSettings is the base endpoint for user settings operations.
	EndpointUserSettings = "/settings"
	// EndpointUserSettingsByID is the endpoint for operations on specific user settings.
	EndpointUserSettingsByID = "/:settingsID"

	// EndpointAuth is the base endpoint for authentication operations.
	EndpointAuth = "/auth"
	// EndpointAuthTokens is the endpoint for automation token operations.
	EndpointAuthTokens = "/automation/tokens" //nolint:gosec // G101: False positive - this is just an endpoint path, not credentials

	// EndpointOrganization is the base endpoint for organization operations.
	EndpointOrganization = "/organization"
	// EndpointRoleManagement is the endpoint for role management operations.
	EndpointRoleManagement = "/role-management"
	// EndpointRoles is the endpoint for role operations.
	EndpointRoles = "/roles"
	// EndpointUserRole is the endpoint for user role operations.
	EndpointUserRole = "/users/:userID/role"
	// EndpointRolePermissions is the endpoint for role permissions operations.
	EndpointRolePermissions = "/roles/:roleID/permissions"
	// EndpointOrganizationUsers is the endpoint for organization user operations.
	EndpointOrganizationUsers = "/users"

	// EndpointDevices is the base endpoint for device operations.
	EndpointDevices = "/devices"
	// EndpointDeviceByID is the endpoint for operations on a specific device.
	EndpointDeviceByID = "/:device_id"
	// EndpointDeviceReset is the endpoint for resetting a device.
	EndpointDeviceReset = "/:device_id/reset"
	// EndpointDeviceClaim is the endpoint for claiming an unclaimed device.
	EndpointDeviceClaim = "/:device_id/claim"
	// EndpointDeviceRotateCert is the endpoint for rotating a device certificate.
	EndpointDeviceRotateCert = "/:device_id/rotate-cert"

	// EndpointCommands is the base endpoint for command operations.
	EndpointCommands = "/commands"
	// EndpointCommandByProjectID is the endpoint for sending a command to a project.
	EndpointCommandByProjectID = "/:project_id"
	// EndpointCommandStatus is the endpoint for getting the status of a command.
	EndpointCommandStatus = "/:command_id/status"
)
