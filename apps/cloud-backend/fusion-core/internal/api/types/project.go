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
	Amount   float64 `json:"amount" validate:"min=0"`
	Currency string  `json:"currency" validate:"required,currency,len=3"`
}

// Request body for creating or updating a project.
type ProjectCreateRequest struct {
	ID                   string          `json:"id" validate:"omitempty,uuid"`
	Application          string          `json:"application" validate:"required,min=1,max=255"`
	AccountID            string          `json:"account_id" validate:"required,min=1"`
	Name                 string          `json:"name" validate:"required,min=1,max=255"`
	Description          string          `json:"description" validate:"omitempty,max=1000"`
	Venue                string          `json:"venue" validate:"omitempty,max=255"`
	EnvironmentType      EnvironmentType `json:"environment_type" validate:"required,environment_type"`
	ProjectPhase         ProjectPhase    `json:"project_phase" validate:"required,project_phase"`
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
	IsArchived         bool            `json:"is_archived"`
	IsStarred          bool            `json:"is_starred"`
	LockProject        bool            `json:"lock_project"`
}

// Project object for Get.
type Project struct {
	ID              string          `json:"id"`
	Application     string          `json:"application"`
	AccountID       string          `json:"account_id"`
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
