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
	UserProfileRead   = "user.profile.read"
	UserProfileCreate = "user.profile.create"
	UserProfileUpdate = "user.profile.update"

	// User settings permissions
	UserSettingsRead   = "user.settings.read"
	UserSettingsCreate = "user.settings.create"
	UserSettingsUpdate = "user.settings.update"

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
	acc.RegisterPermission("GET", "/api/v1/projects/:id", ProjectRead, PermissionRead, "View specific project")

	// Project CREATE endpoint - require write permission
	acc.RegisterPermission("POST", "/api/v1/projects", ProjectCreate, PermissionWrite, "Create new project")

	// Project UPDATE endpoint - require write permission
	acc.RegisterPermission("PATCH", "/api/v1/projects/:id", ProjectUpdate, PermissionWrite, "Update project")

	// Project DELETE endpoint - require admin permission
	acc.RegisterPermission("DELETE", "/api/v1/projects/:id", ProjectDelete, PermissionAdmin, "Delete project")

	// Project SYNC endpoint - require write permission
	acc.RegisterPermission("POST", "/api/v1/projects/:id/sync", ProjectSync, PermissionWrite, "Sync project")
}

// SetupUserProfilePermissions configures access control permissions for user profile endpoints
func SetupUserProfilePermissions(acc *AccessControlConfig) {
	// User Profile endpoints
	acc.RegisterPermission("GET", "/api/v1/user/profile", UserProfileRead, PermissionRead, "View user profile")
	acc.RegisterPermission("POST", "/api/v1/user/profile", UserProfileCreate, PermissionWrite, "Create user profile")
	acc.RegisterPermission("PUT", "/api/v1/user/profile", UserProfileUpdate, PermissionWrite, "Update user profile")
}

// SetupUserSettingsPermissions configures access control permissions for user settings endpoints
func SetupUserSettingsPermissions(acc *AccessControlConfig) {
	// User Settings endpoints
	acc.RegisterPermission("GET", "/api/v1/user/settings", UserSettingsRead, PermissionRead, "View user settings")
	acc.RegisterPermission("POST", "/api/v1/user/settings", UserSettingsCreate, PermissionWrite, "Create user settings")
	acc.RegisterPermission("PUT", "/api/v1/user/settings", UserSettingsUpdate, PermissionWrite, "Update user settings")
}

// SetupCommonPermissions configures common permission patterns
func SetupCommonPermissions(acc *AccessControlConfig) {
	SetupProjectPermissions(acc)
	SetupUserProfilePermissions(acc)
	SetupUserSettingsPermissions(acc)

	// Add more permission setups here as needed
	// SetupUserPermissions(acc)
	// SetupProductPermissions(acc)
}
