// Package constants provides shared constant values used across the application.
package constants

// Authentication Error Codes
const (
	CodeInvalidToken           = "INVALID_TOKEN"
	CodeTokenExpired           = "TOKEN_EXPIRED"
	CodeTokenMalformed         = "TOKEN_MALFORMED" //nolint:gosec // G101: False positive - this is just a constant string, not credentials
	CodeInvalidSignature       = "INVALID_SIGNATURE"
	CodeUnsupportedTokenFormat = "UNSUPPORTED_TOKEN_FORMAT"
	CodeUnauthorized           = "UNAUTHORIZED"
)

// User Management Error Codes
const (
	CodeUserNotFound = "USER_NOT_FOUND"
)

// General Error Codes
const (
	CodeAccessDenied        = "ACCESS_DENIED"
	CodeInternalServerError = "INTERNAL_SERVER_ERROR"
	CodeBadRequest          = "BAD_REQUEST"
	CodeForbidden           = "FORBIDDEN"
)

// HTTP Status Messages (used by response utilities)
const (
	StatusUnauthorized        = "Unauthorized"
	StatusForbidden           = "Forbidden"
	StatusBadRequest          = "Bad Request"
	StatusInternalServerError = "Internal Server Error"
	StatusAccessDenied        = "Access Denied"
)

const (
	SuperAdminRoleName = "Super Admin"
	AdminRoleName      = "Admin"
)
