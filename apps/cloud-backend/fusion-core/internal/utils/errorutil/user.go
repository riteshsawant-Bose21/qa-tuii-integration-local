package errorutil

// Authentication Error Messages
const (
	MsgAuthorizationHeaderRequired = "Authorization header is required"
	MsgInvalidAuthHeaderFormat     = "Invalid authorization header format"
	MsgInvalidOrExpiredToken       = "Invalid or expired token" //nolint:gosec // G101: False positive - this is just an error message, not credentials
	MsgTokenExpired                = "Token has expired"
	MsgMalformedToken              = "Malformed token"
	MsgInvalidTokenSignature       = "Invalid token signature"
	MsgUnsupportedTokenFormat      = "Received JWE token but JWT expected"
	MsgInvalidTokenClaims          = "Invalid token claims"          //nolint:gosec
	MsgUserEmailNotFoundInToken    = "User email not found in token" //nolint:gosec
)

// User Management Messages
const (
	MsgUserNotFound            = "User account not found in the system. Please contact your administrator to set up your account."
	MsgUserNotFoundSimple      = "User account not found in the system"
	MsgFailedToRetrieveUser    = "Failed to retrieve user"
	MsgEmailParameterRequired  = "Email parameter is required"
	MsgUserIDParameterRequired = "User ID parameter is required"
	MsgFailedToUpdateUser      = "Failed to update user"
)

// Role Management Messages
const (
	MsgUserRoleUpdatedSuccessfully        = "User role updated successfully"
	MsgRolePermissionsUpdatedSuccessfully = "Role permissions updated successfully"
	MsgFailedToCheckAdminPermissions      = "Failed to check admin permissions"
	MsgFailedToGetRoleManagementData      = "Failed to get role management data"
	MsgFailedToCreateRole                 = "Failed to create role"
	MsgFailedToUpdateUserRole             = "Failed to update user role"
	MsgFailedToUpdateRolePermissions      = "Failed to update role permissions"
	MsgFailedToGetOrganizationUsers       = "Failed to get organization users"
	MsgRoleIDRequired                     = "Role ID is required"
	MsgInvalidRoleID                      = "Invalid role ID"
)

// Permission Messages
const (
	MsgInsufficientPermissions                        = "Insufficient permissions"
	MsgInsufficientPermissionsForRoleManagement       = "Insufficient permissions for role management"
	MsgInsufficientPermissionsToCreateRoles           = "Insufficient permissions to create roles"
	MsgInsufficientPermissionsToUpdateUserRoles       = "Insufficient permissions to update user roles"
	MsgInsufficientPermissionsToUpdateRolePermissions = "Insufficient permissions to update role permissions"
	MsgInsufficientPermissionsToViewOrgUsers          = "Insufficient permissions to view organization users"
)
