package types

import "time"

// EnvironmentType represents the type of environment for a project
type EnvironmentType string

const (
	EnvironmentTypeIndoor  EnvironmentType = "indoor"
	EnvironmentTypeOutdoor EnvironmentType = "outdoor"
	EnvironmentTypeHybrid  EnvironmentType = "hybrid"
)

// ProjectPhase represents the phase of a project
type ProjectPhase string

const (
	ProjectPhaseProposal     ProjectPhase = "Proposal"
	ProjectPhaseDevelopment  ProjectPhase = "Development"
	ProjectPhaseCommissioned ProjectPhase = "Commissioned"
)

type Budget struct {
	Amount   int64  `json:"amount"`
	Currency string `json:"currency" validate:"required,currency,len=3"`
}

// Request body for creating or updating a project.
type ProjectCreateRequest struct {
	ID                   string          `json:"id" validate:"omitempty,uuid"`
	Application          string          `json:"application" validate:"required,min=1,max=255"`
	UserID               string          `json:"user_id" validate:"required,min=1"`
	Name                 string          `json:"name" validate:"required,min=1,max=255"`
	Description          string          `json:"description" validate:"omitempty,max=1000"`
	Venue                string          `json:"venue" validate:"omitempty,max=255"`
	EnvironmentType      EnvironmentType `json:"environment_type" validate:"required,environment_type"`
	ProjectPhase         ProjectPhase    `json:"project_phase" validate:"omitempty,project_phase"`
	Budget               Budget          `json:"budget" validate:"required"`
	IsProjectFileCreated bool            `json:"is_project_file_created"`
}

// Request body for creating or updating a project.
type ProjectUpdateRequest struct {
	ID                 string          `json:"id" validate:"omitempty,uuid"`
	Application        string          `json:"application" validate:"omitempty,min=1,max=255"`
	AccountID          string          `json:"account_id" validate:"omitempty,min=1"`
	Name               string          `json:"name" validate:"omitempty,min=1,max=255"`
	Description        string          `json:"description" validate:"omitempty,max=1000"`
	Venue              string          `json:"venue" validate:"omitempty,max=255"`
	EnvironmentType    EnvironmentType `json:"environment_type" validate:"omitempty,environment_type"`
	ProjectPhase       ProjectPhase    `json:"project_phase" validate:"omitempty,project_phase"`
	Budget             Budget          `json:"budget"`
	IsProjectFileDirty bool            `json:"is_project_file_dirty"`
}

// Project object for Get.
type Project struct {
	ID              string          `json:"id"`
	Application     string          `json:"application"`
	Name            string          `json:"name"`
	Description     string          `json:"description"`
	Venue           string          `json:"venue"`
	EnvironmentType EnvironmentType `json:"environment_type"`
	ProjectPhase    ProjectPhase    `json:"project_phase"`
	IsArchived      bool            `json:"is_archived"`
	IsStarred       bool            `json:"is_starred"`
	LockedByUser    string          `json:"locked_by_user"`
	Budget          Budget          `json:"budget"`
	ProjectFileURL  string          `json:"project_file_url"`
	ThumbnailURL    string          `json:"thumbnail_url"`
	CreatedAt       time.Time       `json:"created_at"`
	UpdatedAt       time.Time       `json:"updated_at"`
}

// Parameters for retrieving all projects.
type GetAllProjectsParams struct {
	UserID     string `form:"user_id" validate:"required,min=1"`
	IsArchived bool   `form:"is_archived"`
	SortBy     string `form:"sort_by" validate:"omitempty,project_sort_field"`
	SortOrder  string `form:"sort_order" validate:"omitempty,sort_order"`
}

// Response for retrieving all projects with pagination.
type GetAllProjectsResponse struct {
	Data       []Project `json:"data"`
	TotalCount int       `json:"total_count"`
	Page       int       `json:"page"`
	TotalPages int       `json:"total_pages"`
}

// Response for creating a project.
type ProjectCreateResponse struct {
	ID               string `json:"id"`
	ProjectUploadURL string `json:"project_upload_url"`
}

// Response for updating a project.
type ProjectUpdateResponse struct {
	ProjectUploadURL string `json:"project_upload_url"`
}

// Response for user assignment operations.
type UserAssignmentResponse struct {
	Message string `json:"message"`
}

// ErrorResponse represents the standard error response structure.
type ErrorResponse struct {
	Message string `json:"message" example:"Error message"`
}

// BadRequestError represents a 400 Bad Request error.
type BadRequestError struct {
	Message string `json:"message" example:"Invalid input data"`
}

// UnauthorizedError represents a 401 Unauthorized error.
type UnauthorizedError struct {
	Message string `json:"message" example:"Unauthorized"`
}

// NotFoundError represents a 404 Not Found error.
type NotFoundError struct {
	Message string `json:"message" example:"Project not found"`
}

// ConflictError represents a 409 Conflict error.
type ConflictError struct {
	Message string `json:"message" example:"User is already assigned to the project"`
}

// ForbiddenError represents a 403 Forbidden error.
type ForbiddenError struct {
	Message string `json:"message" example:"Project is locked by another user"`
}

// InternalServerError represents a 500 Internal Server Error.
type InternalServerError struct {
	Message string `json:"message" example:"Internal Server Error"`
}

