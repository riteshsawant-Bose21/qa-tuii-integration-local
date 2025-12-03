package types

// SuccessResponse represents a successful API response with generic data
type SuccessResponse struct {
	Message string `json:"message"`
	Data    any    `json:"data,omitempty"`
}

// UserSuccessResponse represents a successful API response with user data
type UserSuccessResponse struct {
	Message string `json:"message"`
	Data    *User  `json:"data"`
}

// ProjectSuccessResponse represents a successful API response with project data
type ProjectSuccessResponse struct {
	Message string   `json:"message"`
	Data    *Project `json:"data"`
}

// ProjectsSuccessResponse represents a successful API response with multiple projects
type ProjectsSuccessResponse struct {
	Message string     `json:"message"`
	Data    []*Project `json:"data"`
}

// AuthStatusSuccessResponse represents a successful auth status response
type AuthStatusSuccessResponse struct {
	Message string                 `json:"message"`
	Data    map[string]interface{} `json:"data"`
}

// ErrorResponse represents an error API response
type ErrorResponse struct {
	Message string `json:"message"`
	Code    string `json:"code"`
}
