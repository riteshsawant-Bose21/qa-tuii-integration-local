package errorutil

import "errors"

// ErrProjectNotFound is the sentinel error for a missing project.
var ErrProjectNotFound = errors.New(ErrMsgProjectNotFound)

// ErrProjectAlreadyExists is the sentinel error for a duplicate project.
var ErrProjectAlreadyExists = errors.New(ErrMsgProjectAlreadyExists)

// ErrProjectArchived is the sentinel error for an archived project.
var ErrProjectArchived = errors.New(ErrMsgProjectArchived)

// ErrProjectNotArchived is the sentinel error for a non-archived project.
var ErrProjectNotArchived = errors.New(ErrMsgProjectNotArchived)

// ErrProjectAlreadyLocked is the sentinel error for a project that is already locked.
var ErrProjectAlreadyLocked = errors.New(ErrMsgProjectAlreadyLocked)

// ErrProjectNotLocked is the sentinel error for a project that is not locked.
var ErrProjectNotLocked = errors.New(ErrMsgProjectNotLocked)

// ErrProjectNotLockedByUser is the sentinel error when a project is not locked by the requesting user.
var ErrProjectNotLockedByUser = errors.New(ErrMsgProjectNotLockedByUser)

// ErrProjectLockedByOtherUser is the sentinel error when a project is locked by a different user.
var ErrProjectLockedByOtherUser = errors.New(ErrMsgProjectLockedByUser)

// ErrUserNotFound is the sentinel error for a missing user.
var ErrUserNotFound = errors.New(ErrMsgUserNotFound)

// ErrUserNotAssignedToProject is the sentinel error when a user is not assigned to a project.
var ErrUserNotAssignedToProject = errors.New(ErrMsgUserNotAssignedToProject)

// ErrUserAlreadyAssigned is the sentinel error when a user is already assigned to a project.
var ErrUserAlreadyAssigned = errors.New(ErrMsgUserAlreadyAssigned)

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
	ErrMsgUserAuthEmpty          = "user authorization cannot be empty"
	ErrMsgProjectCannotBeNil     = "project cannot be nil"
	ErrMsgProjectUpdateReqNil    = "project update request cannot be nil"
	ErrMsgProjectRowNil          = "project row cannot be nil"
	ErrMsgTransactionNil         = "transaction cannot be nil"
	ErrMsgIDCannotBeEmpty        = "id cannot be empty"
	ErrMsgProjectIDCannotBeEmpty = "project id cannot be empty"
	ErrMsgUserIDRequired         = "user_id is required"
	ErrMsgUserEmailEmpty         = "user email cannot be empty"
	ErrMsgQueryParamsNil         = "query params cannot be nil"

	// SQL errors
	ErrMsgSQLNoRows = "sql: no rows in result set"
)
