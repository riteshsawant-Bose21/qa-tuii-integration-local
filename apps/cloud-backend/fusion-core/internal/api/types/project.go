package types

import "time"

// EnvironmentType represents the type of environment for a project
type EnvironmentType string

const (
	EnvironmentTypeIndoor  EnvironmentType = "indoor"
	EnvironmentTypeOutdoor EnvironmentType = "outdoor"
	EnvironmentTypeHybrid  EnvironmentType = "hybrid"
)

type ProjectFileType string

const (
	ProjectFileTypeProjectFile      ProjectFileType = "projectFile"
	ProjectFileTypeProjectThumbnail ProjectFileType = "projectThumbnail"
)

// ProjectPhase represents the phase of a project
type ProjectPhase string

const (
	ProjectPhaseProposal     ProjectPhase = "Proposal"
	ProjectPhaseDevelopment  ProjectPhase = "Development"
	ProjectPhaseCommissioned ProjectPhase = "Commissioned"
)

type Budget struct {
	Amount   int64  `json:"amount" example:"50000"`
	Currency string `json:"currency" validate:"required,currency,len=3" example:"USD"`
}

type ProjectAuth struct {
	UserID    string `swaggerignore:"true"`
	Role      string `swaggerignore:"true"`
	AccountID string `swaggerignore:"true"`
}

// Request body for creating or updating a project.
type ProjectCreateRequest struct {
	ID                        string          `json:"projectId" validate:"required,uuid4" example:"50000001-0000-4000-8000-000000000008"`
	Application               string          `json:"application" validate:"required,min=1,max=255" example:"Audio System Design"`
	Name                      string          `json:"name" validate:"required,min=1,max=255" example:"Conference Room Audio Setup"`
	Description               string          `json:"description" validate:"omitempty,max=1000" example:"Professional audio system for corporate conference room"`
	Venue                     string          `json:"venue" validate:"omitempty,max=255" example:"Building A - Conference Room 101"`
	EnvironmentType           EnvironmentType `json:"environment_type" validate:"required,environment_type" example:"indoor"`
	ProjectPhase              ProjectPhase    `json:"project_phase" validate:"omitempty,project_phase" example:"Proposal"`
	Budget                    Budget          `json:"budget"`
	IsProjectFileCreated      bool            `json:"is_project_file_created" example:"false"`
	IsProjectThumbnailCreated bool            `json:"is_project_thumbnail_created" example:"false"`
}

// Request body for creating or updating a project.
type ProjectUpdateRequest struct {
	ID                      string          `swaggerignore:"true"`
	Application             string          `json:"application" validate:"omitempty,min=1,max=255" example:"Audio System Design"`
	Name                    string          `json:"name" validate:"omitempty,min=1,max=255" example:"Updated Conference Room Audio Setup"`
	Description             string          `json:"description" validate:"omitempty,max=1000" example:"Updated professional audio system for corporate conference room"`
	Venue                   string          `json:"venue" validate:"omitempty,max=255" example:"Building B - Conference Room 205"`
	EnvironmentType         EnvironmentType `json:"environment_type" validate:"omitempty,environment_type" example:"indoor"`
	ProjectPhase            ProjectPhase    `json:"project_phase" validate:"omitempty,project_phase" example:"Development"`
	Budget                  Budget          `json:"budget" validate:"omitempty"`
	IsProjectFileDirty      bool            `json:"is_project_file_dirty" example:"true"`
	IsProjectThumbnailDirty bool            `json:"is_project_thumbnail_dirty" example:"true"`
}

// Project object for Get.
type Project struct {
	ID              string          `json:"id" example:"123e4567-e89b-12d3-a456-426614174000"`
	Application     string          `json:"application" example:"Audio System Design"`
	Name            string          `json:"name" example:"Conference Room Audio Setup"`
	Description     string          `json:"description" example:"Professional audio system for corporate conference room"`
	Venue           string          `json:"venue" example:"Building A - Conference Room 101"`
	EnvironmentType EnvironmentType `json:"environment_type" example:"indoor"`
	ProjectPhase    ProjectPhase    `json:"project_phase" example:"Development"`
	IsArchived      bool            `json:"is_archived" example:"false"`
	IsStarred       bool            `json:"is_starred" example:"true"`
	LockedByUser    string          `json:"locked_by_user" example:"user456"`
	Budget          Budget          `json:"budget"`
	ProjectFileURL  *string         `json:"project_file_url" example:"https://storage.example.com/projects/123e4567/project.json"`
	ThumbnailURL    *string         `json:"thumbnail_url" example:"https://storage.example.com/projects/123e4567/thumbnail.jpg"`
	CreatedAt       time.Time       `json:"created_at" example:"2023-10-15T14:30:00Z"`
	UpdatedAt       time.Time       `json:"updated_at" example:"2023-10-20T16:45:00Z"`
}

// Parameters for retrieving all projects.
type GetAllProjectsParams struct {
	IsArchived bool   `form:"is_archived" example:"false"`
	SortBy     string `form:"sort_by" validate:"omitempty,project_sort_field" example:"created_at"`
	SortOrder  string `form:"sort_order" validate:"omitempty,sort_order" example:"asc"`
}

// Response for retrieving all projects with pagination.
type GetAllProjectsResponse struct {
	Data       []Project `json:"data"`
	TotalCount int       `json:"total_count" example:"25"`
	Page       int       `json:"page" example:"1"`
	TotalPages int       `json:"total_pages" example:"3"`
}

// Request body for archiving or unarchiving a project.
type ProjectArchiveRequest struct {
	Archive bool `json:"is_archived" example:"true" validate:"required"`
}

// Request body for locking or unlocking a project.
type ProjectLockRequest struct {
	IsLocked bool `json:"is_locked" example:"true" validate:"required"`
}

// Request body for starring or unstarring a project.
type ProjectStarRequest struct {
	IsStarred bool `json:"is_starred" example:"true" validate:"required"`
}

// Response for creating a project.
type ProjectCreateResponse struct {
	ID                 string  `json:"id" example:"123e4567-e89b-12d3-a456-426614174000"`
	ProjectUploadURL   *string `json:"project_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
	ThumbnailUploadURL *string `json:"thumbnail_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
}

// Response for updating a project.
type ProjectUpdateResponse struct {
	ProjectUploadURL   *string `json:"project_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
	ThumbnailUploadURL *string `json:"thumbnail_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
}

// Response for user assignment operations.
type UserAssignmentResponse struct {
	Message string `json:"message" example:"User successfully assigned to project"`
}

// API Error Message Constants
// Single source of truth for all error messages returned by the project API
const (
	// Generic errors
	ErrMsgInternalServerError = "Internal server error"
	ErrMsgInvalidInput        = "Invalid input data"
	ErrMsgUnauthorized        = "Unauthorized"
	ErrMsgForbidden           = "Forbidden"

	// Project entity errors
	ErrMsgProjectNotFound    = "project not found"
	ErrMsgProjectArchived    = "project is archived"
	ErrMsgProjectNotArchived = "project is not archived"

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

// ErrorResponse represents the standard error response structure.
type ErrorResponse struct {
	Message string `json:"message" example:"Error message"`
}

// BadRequestError represents a 400 Bad Request error.
type BadRequestError struct {
	Message string `json:"message" example:"Bad Request"`
}

// UnauthorizedError represents a 401 Unauthorized error.
type UnauthorizedError struct {
	Message string `json:"message" example:"Unauthorized"`
}

// NotFoundError represents a 404 Not Found error.
type NotFoundError struct {
	Message string `json:"message" example:"Not Found"`
}

// ConflictError represents a 409 Conflict error.
type ConflictError struct {
	Message string `json:"message" example:"Conflict"`
}

// ForbiddenError represents a 403 Forbidden error.
type ForbiddenError struct {
	Message string `json:"message" example:"Forbidden"`
}

// InternalServerError represents a 500 Internal Server Error.
type InternalServerError struct {
	Message string `json:"message" example:"Internal Server Error"`
}
