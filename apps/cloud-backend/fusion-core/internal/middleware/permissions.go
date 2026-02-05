package middleware

// Common permission feature constants
const (
	// Project permissions
	ProjectRead   = "project.read"
	ProjectCreate = "project.create"
	ProjectUpdate = "project.update"
	ProjectDelete = "project.delete"
	ProjectSync   = "project.sync"

	// User management permissions
	UserRead   = "user.read"
	UserCreate = "user.create"
	UserUpdate = "user.update"
	UserDelete = "user.delete"

	// User profile permissions
	UserProfileRead   = "users.profile.read"
	UserProfileCreate = "users.profile.create"
	UserProfileUpdate = "users.profile.update"

	// User settings permissions
	UserSettingsRead   = "users.settings.read"
	UserSettingsCreate = "users.settings.create"
	UserSettingsUpdate = "users.settings.update"

	// Admin permissions
	AdminFull = "admin"
	AdminUser = "user.manage"

	// Wildcard permissions
	AllPermissions = "*"
)

// SetupProjectPermissions configures access control permissions for project endpoints
func SetupProjectPermissions(acc *AccessControlConfig) {
	// Project GET endpoints - require read permission
	acc.RegisterPermission("GET", "/api/v1/projects", ProjectRead, PermissionRead, "View all projects")

	// Project CREATE endpoint - require write permission
	acc.RegisterPermission("POST", "/api/v1/projects", ProjectCreate, PermissionWrite, "Create new project")

	// Project UPDATE endpoint - require write permission
	acc.RegisterPermission("PATCH", "/api/v1/projects/:projectId", ProjectUpdate, PermissionWrite, "Update project")

	// Project DELETE endpoint - require admin permission
	acc.RegisterPermission("DELETE", "/api/v1/projects/:projectId", ProjectDelete, PermissionWrite, "Delete project")

	// Project user assignment endpoints - require write permission
	acc.RegisterPermission("PUT", "/api/v1/projects/:projectId/users/:userEmail", ProjectUpdate, PermissionWrite, "Assign user to project")
	acc.RegisterPermission("DELETE", "/api/v1/projects/:projectId/users/:userEmail", ProjectUpdate, PermissionWrite, "Remove user from project")

	// Project star endpoint - require write permission
	acc.RegisterPermission("POST", "/api/v1/projects/:projectId/star/:userId", ProjectUpdate, PermissionRead, "Star or unstar project")

	// Project archive endpoint - require write permission
	acc.RegisterPermission("POST", "/api/v1/projects/:projectId/archive", ProjectUpdate, PermissionWrite, "Archive or unarchive project")

	// Project lock endpoint - require write permission
	acc.RegisterPermission("POST", "/api/v1/projects/:projectId/lock", ProjectUpdate, PermissionWrite, "Lock or unlock project")
}

// SetupUserProfilePermissions configures access control permissions for user profile endpoints
func SetupUserProfilePermissions(acc *AccessControlConfig) {
	// User Profile endpoints
	acc.RegisterPermission("GET", "/api/v1/users/profile", UserProfileRead, PermissionRead, "View user profile")
	acc.RegisterPermission("POST", "/api/v1/users/profile", UserProfileCreate, PermissionWrite, "Create user profile")
	acc.RegisterPermission("PUT", "/api/v1/users/profile/:profileID", UserProfileUpdate, PermissionWrite, "Update user profile")
}

// SetupUserSettingsPermissions configures access control permissions for user settings endpoints
func SetupUserSettingsPermissions(acc *AccessControlConfig) {
	// User Settings endpoints
	acc.RegisterPermission("GET", "/api/v1/users/settings", UserSettingsRead, PermissionRead, "View user settings")
	acc.RegisterPermission("POST", "/api/v1/users/settings", UserSettingsCreate, PermissionWrite, "Create user settings")
	acc.RegisterPermission("PUT", "/api/v1/users/settings/:settingsID", UserSettingsUpdate, PermissionWrite, "Update user settings")
}

func SetupDevicePermissions(acc *AccessControlConfig) {
	// Device CREATE endpoint - require write permission
	acc.RegisterPermission("POST", "/api/v1/devices", "project.create", PermissionWrite, "Create new device")
}

// SetupCommonPermissions configures common permission patterns
func SetupCommonPermissions(acc *AccessControlConfig) {
	SetupProjectPermissions(acc)
	SetupUserProfilePermissions(acc)
	SetupUserSettingsPermissions(acc)
	SetupDevicePermissions(acc)
	// Add more permission setups here as needed
	// SetupUserPermissions(acc)
	// SetupProductPermissions(acc)
}

