package constants

// Status values
const (
	StatusSuccess = "success"
	StatusError   = "error"
)

// Common messages
const (
	MsgInvalidRequestPayload  = "Invalid request payload"
	MsgValidationFailed       = "Validation failed"
	MsgUserAlreadyExists      = "User already exists"
	MsgUserRegistrationFailed = "Failed to register user"
	MsgUserRegistered         = "User registered successfully"
	MsgInvalidCredentials     = "Invalid credentials"
	MsgUserLoginFailed        = "Failed to log in user"
	MsgUserNotFound           = "User not found"
	MsgUserLoggedIn           = "User logged in successfully"
	MsgInvalidOrExpiredToken  = "Invalid or expired token"
	MsgTokenRefreshed         = "Token refreshed successfully"

	MsgUserInfoFetched            = "User info fetched successfully"
	MsgUserInfoFetchFailed        = "Failed to fetch user info"
	MsgUserMetadataFetchFailed    = "Failed to fetch user metadata"
	MsgUserMetadataInserted       = "User metadata inserted successfully"
	MsgUserMetadataInsertFailed   = "Failed to insert user metadata"
	MsgUserContextNotFound        = "User context not found in request" // Used when user claims are not found in context
	MsgMissingOrInvalidAuthHeader = "Missing or invalid Authorization header"

	MsgProjectAlreadyExists   = "Project with this name already exists"
	MsgProjectNotFound        = "Project not found"
	MsgProjectCreated         = "Project created successfully"
	MsgProjectCreationFailed  = "Failed to create project"
	MsgProjectUpdated         = "Project updated successfully"
	MsgProjectUpdateFailed    = "Failed to update project"
	MsgProjectDeleted         = "Project deleted successfully"
	MsgProjectDeletionFailed  = "Failed to delete project"
	MsgProjectListFetched     = "Project list fetched successfully"
	MsgProjectListFetchFailed = "Failed to fetch project list"
	MsgProjectIDRequired      = "Project ID is required to fetch project details"
	MsgProjectFetchFailed     = "Failed to fetch project details"
	MsgProjectFetched         = "Project details fetched successfully"

	MsgProductListFetchFailed = "Failed to fetch product list"
	MsgProductListFetched     = "Product list fetched successfully"

	MsgOrganizationListFetchFailed = "Failed to fetch organization list"
	MsgOrganizationListFetched     = "Organization list fetched successfully"
	MsgFileNotFound                = "File not found"

	MsgSpaceListFetchFailed = "Failed to fetch space list"
	MsgSpaceListFetched     = "Space list fetched successfully"
	MsgSpaceDeleteFailed    = "Failed to delete space"
	MsgSpaceDeleted         = "Space deleted successfully"
	MsgSpaceUpdateFailed    = "Failed to update space"
	MsgSpaceUpdated         = "Space updated successfully"

	MsgDeviceClaimFailed   = "Failed to claim device"
	MsgDeviceClaimed       = "Device claimed successfully"
	MsgGetDeviceFailed     = "Failed to Get device"
	MsgGetDevice           = "Get Device successfully"
	MsgDeviceHistoryFailed = "Failed to get device history"
	MsgDeviceHistory       = "Device History successfully"

	MsgGetSpaceFailed = "Failed to get space"
	MsgGetSpace       = "Space claimed successfully"

	MsgFileInvalidFileUpload = "Invalid file upload"
	MsgFailedToSaveFile      = "Failed to save file"
	MsgFileUploaded          = "File uploaded"
)
