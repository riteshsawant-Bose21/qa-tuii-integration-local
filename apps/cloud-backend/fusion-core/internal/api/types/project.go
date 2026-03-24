package types

import "time"

// EnvironmentType represents the type of environment for a project
type EnvironmentType string

const (
	// EnvironmentTypeIndoor represents an indoor environment
	EnvironmentTypeIndoor EnvironmentType = "indoor"
	// EnvironmentTypeOutdoor represents an outdoor environment
	EnvironmentTypeOutdoor EnvironmentType = "outdoor"
	// EnvironmentTypeHybrid represents a hybrid environment
	EnvironmentTypeHybrid EnvironmentType = "hybrid"
)

// ProjectFileType represents the type of file associated with a project
type ProjectFileType string

const (
	// ProjectFileTypeProjectFile represents a project file
	ProjectFileTypeProjectFile ProjectFileType = "projectFile"
	// ProjectFileTypeProjectThumbnail represents a project thumbnail file
	ProjectFileTypeProjectThumbnail ProjectFileType = "projectThumbnail"
)

// ProjectPhase represents the phase of a project
type ProjectPhase string

const (
	// ProjectPhaseProposal represents the proposal phase
	ProjectPhaseProposal ProjectPhase = "Proposal"
	// ProjectPhaseDevelopment represents the development phase
	ProjectPhaseDevelopment ProjectPhase = "Development"
	// ProjectPhaseCommissioned represents the commissioned phase
	ProjectPhaseCommissioned ProjectPhase = "Commissioned"
)

// Budget represents project budget information
type Budget struct {
	Amount   int64  `json:"amount" example:"50000"`
	Currency string `json:"currency" validate:"required,currency,len=3" example:"USD"`
}

// ProjectAuth represents project authorization context
type ProjectAuth struct {
	UserID    string `swaggerignore:"true"`
	Role      string `swaggerignore:"true"`
	AccountID string `swaggerignore:"true"`
}

// ProjectCreateRequest represents the request body for creating or updating a project.
type ProjectCreateRequest struct {
	ID                        string          `json:"project_id" validate:"required,uuid4" example:"50000001-0000-4000-8000-000000000008"`
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

// ProjectUpdateRequest represents the request body for creating or updating a project.
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

// GetAllProjectsParams represents the parameters for retrieving all projects.
type GetAllProjectsParams struct {
	IsArchived bool   `form:"is_archived" example:"false"`
	SortBy     string `form:"sort_by" validate:"omitempty,project_sort_field" example:"created_at"`
	SortOrder  string `form:"sort_order" validate:"omitempty,sort_order" example:"asc"`
}

type GetProjectByIDResponse struct {
	Project Project `json:"project"`
}

// GetAllProjectsResponse represents the response for retrieving all projects with pagination.
type GetAllProjectsResponse struct {
	Data       []Project `json:"data"`
	TotalCount int       `json:"total_count" example:"25"`
	Page       int       `json:"page" example:"1"`
	TotalPages int       `json:"total_pages" example:"3"`
}

// ProjectArchiveRequest represents the request body for archiving or unarchiving a project.
type ProjectArchiveRequest struct {
	Archive bool `json:"is_archived" example:"true" validate:"required"`
}

// ProjectLockRequest represents the request body for locking or unlocking a project.
type ProjectLockRequest struct {
	IsLocked bool `json:"is_locked" example:"true" validate:"required"`
}

// ProjectStarRequest represents the request body for starring or unstarring a project.
type ProjectStarRequest struct {
	IsStarred bool `json:"is_starred" example:"true" validate:"required"`
}

// ProjectCreateResponse represents the response for creating a project.
type ProjectCreateResponse struct {
	ID                 string  `json:"id" example:"123e4567-e89b-12d3-a456-426614174000"`
	ProjectUploadURL   *string `json:"project_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
	ThumbnailUploadURL *string `json:"thumbnail_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
}

// ProjectUpdateResponse represents the response for updating a project.
type ProjectUpdateResponse struct {
	ProjectUploadURL   *string `json:"project_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
	ThumbnailUploadURL *string `json:"thumbnail_upload_url" example:"https://storage.example.com/upload/projects/123e4567"`
}

// UserAssignmentResponse represents the response for user assignment operations.
type UserAssignmentResponse struct {
	Message string `json:"message" example:"User successfully assigned to project"`
}
