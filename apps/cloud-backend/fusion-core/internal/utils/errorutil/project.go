package errorutil

// API Error Message Constants
// Single source of truth for all error messages returned by the project API
const (
	// Generic errors
	ErrMsgInternalServerError = "Internal server error"
	ErrMsgInvalidInput        = "Invalid input data"
	ErrMsgUnauthorized        = "Unauthorized"
	ErrMsgForbidden           = "Forbidden"

	// Project entity errors
	ErrMsgProjectNotFound      = "project not found"
	ErrMsgProjectArchived      = "project is archived"
	ErrMsgProjectNotArchived   = "project is not archived"
	ErrMsgProjectAlreadyExists = "project with the given ID already exists"

	// Project locking errors
	ErrMsgProjectAlreadyLocked   = "project is already locked"
	ErrMsgProjectNotLocked       = "project is not locked"
	ErrMsgProjectNotLockedByUser = "project is not locked by this user"
	ErrMsgProjectLockedByUser    = "project is locked by user"

	// Project starring errors
	ErrMsgProjectAlreadyStarred = "project is already starred"
	ErrMsgProjectNotStarred     = "project is not starred"

	// User entity errors
	ErrMsgUserNotFound = "user not found"

	// User assignment errors
	ErrMsgUserNotAssignedToProject = "user not assigned to project"
	ErrMsgUserAlreadyAssigned      = "user is already assigned to the project"

	// Operation errors (internal - for logging/debugging)
	ErrMsgFailedUserAssignmentCheck     = "failed to check user assignment"
	ErrMsgFailedToGetProject            = "failed to get project"
	ErrMsgFailedToInsertProject         = "failed to insert project"
	ErrMsgFailedToUpdateProject         = "failed to update project"
	ErrMsgFailedToDeleteProject         = "failed to delete project"
	ErrMsgFailedToAssignUser            = "failed to assign user to project"
	ErrMsgFailedToRemoveUser            = "failed to remove user from project"
	ErrMsgFailedToGetUserByEmail        = "failed to get user by email"
	ErrMsgFailedToStarProject           = "failed to star project"
	ErrMsgFailedToUnstarProject         = "failed to unstar project"
	ErrMsgFailedToArchiveProject        = "failed to archive project"
	ErrMsgFailedToUnarchiveProject      = "failed to unarchive project"
	ErrMsgFailedToLockProject           = "failed to lock project"
	ErrMsgFailedToUnlockProject         = "failed to unlock project"
	ErrMsgFailedToCheckProjectExistence = "failed to check project existence"
	ErrMsgFailedToCheckUserExistence    = "failed to check user existence"
	ErrMsgFailedToGetLockedUserInfo     = "failed to get locked user information"
	ErrMsgFailedToBeginTransaction      = "failed to begin transaction"
	ErrMsgFailedToCommitTransaction     = "failed to commit transaction"
	ErrMsgFailedToGetProjects           = "failed to get projects"
	ErrMsgFailedToParseRow              = "failed to parse row"
	ErrMsgFailedToInsertProjectUser     = "failed to insert project user"
	ErrMsgFailedToGetProjectUser        = "failed to get project user"

	// Validation errors
	ErrMsgProjectCannotBeNil     = "project cannot be nil"
	ErrMsgIdCannotBeEmpty        = "id cannot be empty"
	ErrMsgProjectIdCannotBeEmpty = "project id cannot be empty"
	ErrMsgUserIdRequired         = "user_id is required"

	// SQL errors
	ErrMsgSqlNoRows = "sql: no rows in result set"
)
