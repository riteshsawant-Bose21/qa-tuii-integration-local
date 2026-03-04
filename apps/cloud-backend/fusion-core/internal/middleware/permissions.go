package middleware

import (
	"fmt"

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

	// Firmware permissions
	FirmwareBundleRead    = "firmware.bundle.read"
	FirmwareBundleCreate  = "firmware.bundle.create"
	FirmwareBundleApprove = "firmware.bundle.approve"
	FirmwareUpdateCheck   = "firmware.update.check"
	FirmwareDownload      = "firmware.download"
	FirmwareUpdateLog     = "firmware.update.log"

	// Admin permissions
	AdminFull = "admin"
	AdminUser = "user.manage"

	// Wildcard permissions
	AllPermissions = "*"
)

// SetupProjectPermissions configures access control permissions for project endpoints
func SetupProjectPermissions(acc *AccessControlConfig) {
	// Project GET endpoints - require read permission
	acc.RegisterPermission("GET", fmt.Sprintf("%s%s", constants.APIV1Path, constants.EndpointProjects), ProjectRead, PermissionRead, "View all projects")

	// Project CREATE endpoint - require write permission
	acc.RegisterPermission("POST", fmt.Sprintf("%s%s", constants.APIV1Path, constants.EndpointProjects), ProjectCreate, PermissionWrite, "Create new project")

	// Project UPDATE endpoint - require write permission
	acc.RegisterPermission("PATCH", fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointProjects, constants.EndpointProjectByID), ProjectUpdate, PermissionWrite, "Update project")

	// Project DELETE endpoint - require admin permission
	acc.RegisterPermission("DELETE", fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointProjects, constants.EndpointProjectByID), ProjectDelete, PermissionWrite, "Delete project")

	// Project user assignment endpoints - require write permission
	acc.RegisterPermission("PUT", fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointProjects, constants.EndpointProjectAssignUser), ProjectUpdate, PermissionWrite, "Assign user to project")
	acc.RegisterPermission("DELETE", fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointProjects, constants.EndpointProjectRemoveUser), ProjectUpdate, PermissionWrite, "Remove user from project")

	// Project star endpoint - require write permission
	acc.RegisterPermission("POST", fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointProjects, constants.EndpointProjectStar), ProjectUpdate, PermissionRead, "Star or unstar project")

	// Project archive endpoint - require write permission
	acc.RegisterPermission("POST", fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointProjects, constants.EndpointProjectArchive), ProjectUpdate, PermissionWrite, "Archive or unarchive project")

	// Project lock endpoint - require write permission
	acc.RegisterPermission("POST", fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointProjects, constants.EndpointProjectLock), ProjectUpdate, PermissionWrite, "Lock or unlock project")
}

// SetupUserProfilePermissions configures access control permissions for user profile endpoints
func SetupUserProfilePermissions(acc *AccessControlConfig) {
	// User Profile endpoints
	basePath := fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointUsers, constants.EndpointUserProfile)
	acc.RegisterPermission("GET", basePath, UserProfileRead, PermissionRead, "View user profile")
	acc.RegisterPermission("POST", basePath, UserProfileCreate, PermissionWrite, "Create user profile")
	acc.RegisterPermission("PUT", fmt.Sprintf("%s%s", basePath, constants.EndpointUserProfileByID), UserProfileUpdate, PermissionWrite, "Update user profile")
}

// SetupUserSettingsPermissions configures access control permissions for user settings endpoints
func SetupUserSettingsPermissions(acc *AccessControlConfig) {
	// User Settings endpoints
	basePath := fmt.Sprintf("%s%s%s", constants.APIV1Path, constants.EndpointUsers, constants.EndpointUserSettings)
	acc.RegisterPermission("GET", basePath, UserSettingsRead, PermissionRead, "View user settings")
	acc.RegisterPermission("POST", basePath, UserSettingsCreate, PermissionWrite, "Create user settings")
	acc.RegisterPermission("PUT", fmt.Sprintf("%s%s", basePath, constants.EndpointUserSettingsByID), UserSettingsUpdate, PermissionWrite, "Update user settings")
}

// SetupFirmwarePermissions configures access control permissions for firmware update endpoints
func SetupFirmwarePermissions(acc *AccessControlConfig) {
	// Firmware bundle endpoints
	basePath := fmt.Sprintf("%s%s", constants.APIV1Path, constants.EndpointFirmware)

	// List bundles - require read permission
	acc.RegisterPermission("GET", fmt.Sprintf("%s%s", basePath, constants.EndpointFirmwareList), FirmwareBundleRead, PermissionRead, "View firmware bundles")

	// Approve bundle - require admin/approve permission
	acc.RegisterPermission("POST", fmt.Sprintf("%s%s", basePath, constants.EndpointApproveBundle), FirmwareBundleApprove, PermissionWrite, "Approve firmware bundle")

	// Check for updates - require read permission
	acc.RegisterPermission("GET", fmt.Sprintf("%s%s", basePath, constants.EndpointFirmwareUpdateCheck), FirmwareUpdateCheck, PermissionRead, "Check for firmware updates")

	// Download bundle - require read permission
	acc.RegisterPermission("GET", fmt.Sprintf("%s%s", basePath, constants.EndpointBundleDownload), FirmwareDownload, PermissionRead, "Download firmware bundle")

	// Log bundle update status - require write permission
	acc.RegisterPermission("POST", fmt.Sprintf("%s%s", basePath, constants.EndpointLogBundleUpdateStatus), FirmwareUpdateLog, PermissionWrite, "Log firmware update status")
}

// SetupCommonPermissions configures common permission patterns
func SetupCommonPermissions(acc *AccessControlConfig) {
	SetupProjectPermissions(acc)
	SetupUserProfilePermissions(acc)
	SetupUserSettingsPermissions(acc)
	SetupFirmwarePermissions(acc)

	// Add more permission setups here as needed
	// SetupUserPermissions(acc)
	// SetupProductPermissions(acc)
}
