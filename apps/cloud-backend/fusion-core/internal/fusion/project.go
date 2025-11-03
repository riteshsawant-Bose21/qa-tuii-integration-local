package fusion

import "time"

type Budget struct {
	Amount   float64 `json:"amount"`
	Currency string  `json:"currency"`
}

// Request body for creating or updating a project.
type ProjectCreateRequest struct {
	ID                   string `json:"id"`
	Application          string `json:"application"`
	AccountID            string `json:"account_id"`
	Name                 string `json:"name"`
	Description          string `json:"description"`
	Venue                string `json:"venue"`
	EnvironmentType      string `json:"environment_type"`
	ProjectPhase         string `json:"project_phase"`
	Budget               Budget `json:"budget"`
	IsProjectFileCreated bool   `json:"is_project_file_created"`
}

// Request body for creating or updating a project.
type ProjectUpdateRequest struct {
	ID                 string `json:"id"`
	Application        string `json:"application"`
	AccountID          string `json:"account_id"`
	Name               string `json:"name"`
	Description        string `json:"description"`
	Venue              string `json:"venue"`
	EnvironmentType    string `json:"environment_type"`
	ProjectPhase       string `json:"project_phase"`
	Budget             Budget `json:"budget"`
	IsProjectFileDirty bool   `json:"is_project_file_dirty"`
	IsArchived         bool   `json:"is_archived"`
	IsStarred          bool   `json:"is_starred"`
	LockProject        bool   `json:"lock_project"`
}

// Project object for Get.
type Project struct {
	ID              string    `json:"id"`
	Application     string    `json:"application"`
	AccountID       string    `json:"account_id"`
	Name            string    `json:"name"`
	Description     string    `json:"description"`
	Venue           string    `json:"venue"`
	EnvironmentType string    `json:"environment_type"`
	ProjectPhase    string    `json:"project_phase"`
	IsArchived      bool      `json:"is_archived"`
	IsStarred       bool      `json:"is_starred"`
	LockedByUser    string    `json:"locked_by_user"`
	Budget          Budget    `json:"budget"`
	ProjectFileURL  string    `json:"project_file_url"`
	ThumbnailURL    string    `json:"thumbnail_url"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// Parameters for retrieving all projects.
type GetAllProjectsParams struct {
	IsArchived bool   `form:"is_archived"`
	SortBy     string `form:"sort_by"`
	SortOrder  string `form:"sort_order"`
}
