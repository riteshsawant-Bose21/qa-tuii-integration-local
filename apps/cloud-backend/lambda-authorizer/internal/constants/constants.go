package constants

const (
	// Methods
	MethodGet    = "GET"
	MethodPost   = "POST"
	MethodPut    = "PUT"
	MethodPatch  = "PATCH"
	MethodDelete = "DELETE"

	// Project permissions
	ProjectRead   = "project.read"
	ProjectCreate = "project.create"
	ProjectUpdate = "project.update"
	ProjectDelete = "project.delete"
	ProjectSync   = "project.sync"

	// Product permissions
	ProductRead = "product.read"

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

	// Permission levels
	PermissionRead  = "read"
	PermissionWrite = "write"
	PermissionEdit  = "edit" // alias for write
	PermissionAdmin = "admin"
	// Wildcard permissions
	AllPermissions = "*"

	// Policy effect constants
	Allow = "allow"
	Deny  = "deny"
)