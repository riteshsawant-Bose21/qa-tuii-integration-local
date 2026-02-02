package middleware

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
)

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
	acc.RegisterPermission("GET", constants.APIV1Path+constants.EndpointProjects, ProjectRead, PermissionRead, "View all projects")

	// Project CREATE endpoint - require write permission
	acc.RegisterPermission("POST", constants.APIV1Path+constants.EndpointProjects, ProjectCreate, PermissionWrite, "Create new project")

	// Project UPDATE endpoint - require write permission
	acc.RegisterPermission("PATCH", constants.APIV1Path+constants.EndpointProjects+constants.EndpointProjectByID, ProjectUpdate, PermissionWrite, "Update project")

	// Project DELETE endpoint - require admin permission
	acc.RegisterPermission("DELETE", constants.APIV1Path+constants.EndpointProjects+constants.EndpointProjectByID, ProjectDelete, PermissionWrite, "Delete project")

	// Project user assignment endpoints - require write permission
	acc.RegisterPermission("PUT", constants.APIV1Path+constants.EndpointProjects+constants.EndpointProjectAssignUser, ProjectUpdate, PermissionWrite, "Assign user to project")
	acc.RegisterPermission("DELETE", constants.APIV1Path+constants.EndpointProjects+constants.EndpointProjectRemoveUser, ProjectUpdate, PermissionWrite, "Remove user from project")

	// Project star endpoint - require write permission
	acc.RegisterPermission("POST", constants.APIV1Path+constants.EndpointProjects+constants.EndpointProjectStar, ProjectUpdate, PermissionRead, "Star or unstar project")

	// Project archive endpoint - require write permission
	acc.RegisterPermission("POST", constants.APIV1Path+constants.EndpointProjects+constants.EndpointProjectArchive, ProjectUpdate, PermissionWrite, "Archive or unarchive project")

	// Project lock endpoint - require write permission
	acc.RegisterPermission("POST", constants.APIV1Path+constants.EndpointProjects+constants.EndpointProjectLock, ProjectUpdate, PermissionWrite, "Lock or unlock project")
}

// SetupUserProfilePermissions configures access control permissions for user profile endpoints
func SetupUserProfilePermissions(acc *AccessControlConfig) {
	// User Profile endpoints
	basePath := constants.APIV1Path + constants.EndpointUsers + constants.EndpointUserProfile
	acc.RegisterPermission("GET", basePath, UserProfileRead, PermissionRead, "View user profile")
	acc.RegisterPermission("POST", basePath, UserProfileCreate, PermissionWrite, "Create user profile")
	acc.RegisterPermission("PUT", basePath+constants.EndpointUserProfileByID, UserProfileUpdate, PermissionWrite, "Update user profile")
}

// SetupUserSettingsPermissions configures access control permissions for user settings endpoints
func SetupUserSettingsPermissions(acc *AccessControlConfig) {
	// User Settings endpoints
	basePath := constants.APIV1Path + constants.EndpointUsers + constants.EndpointUserSettings
	acc.RegisterPermission("GET", basePath, UserSettingsRead, PermissionRead, "View user settings")
	acc.RegisterPermission("POST", basePath, UserSettingsCreate, PermissionWrite, "Create user settings")
	acc.RegisterPermission("PUT", basePath+constants.EndpointUserSettingsByID, UserSettingsUpdate, PermissionWrite, "Update user settings")
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
