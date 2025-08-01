package model

type Project struct {
	ID          int64  `json:"id"`
	Name        string `json:"name" validate:"required"`
	Description string `json:"description,omitempty"`
	OwnerID     int64  `json:"owner_id" validate:"required"`
	MetaData    string `json:"metadata,omitempty"` // JSON string for additional project data
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}

type ProjectRequest struct {
	Name        string `json:"name" validate:"required"`
	Description string `json:"description,omitempty"`
	MetaData    string `json:"metadata,omitempty"` // JSON string for additional project data
}

type ProjectResponse struct {
	ID          int64  `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description,omitempty"`
	OwnerID     int64  `json:"owner_id"`
	MetaData    string `json:"metadata,omitempty"` // JSON string for additional project data
	CreatedAt   string `json:"created_at"`
	UpdatedAt   string `json:"updated_at"`
}