package types

// SuccessResponse represents a successful API response with generic data
type SuccessResponse struct {
	Message string `json:"message" example:"Operation completed successfully"`
	Data    any    `json:"data,omitempty"`
}

// UserSuccessResponse represents a successful API response with user data
type UserSuccessResponse struct {
	Message string `json:"message" example:"User retrieved successfully"`
	Data    *User  `json:"data"`
}

// AuthStatusSuccessResponse represents a successful auth status response
type AuthStatusSuccessResponse struct {
	Message string                 `json:"message" example:"Authentication status retrieved successfully"`
	Data    map[string]interface{} `json:"data"`
}

// ErrorResponse represents an error API response
type ErrorResponse2 struct {
	Message string `json:"message" example:"Invalid request parameters"`
	Code    string `json:"code" example:"VALIDATION_ERROR"`
}

// UnauthorizedResponse represents a 401 unauthorized response
type UnauthorizedResponse struct {
	Error   string `json:"error" example:"Unauthorized"`
	Message string `json:"message" example:"User email not found in token"`
}

// NotFoundResponse represents a 404 not found response
type NotFoundResponse struct {
	Error   string `json:"error" example:"Not Found"`
	Message string `json:"message" example:"User not found in the system"`
}

// InternalServerErrorResponse represents a 500 internal server error response
type InternalServerErrorResponse struct {
	Error   string `json:"error" example:"Internal Server Error"`
	Message string `json:"message" example:"Internal server error"`
}

// BadRequestResponse represents a 400 bad request response
type BadRequestResponse struct {
	Error   string `json:"error" example:"Bad Request"`
	Message string `json:"message" example:"Invalid JSON payload"`
}

// ProjectSyncResponse represents a successful project sync response
type ProjectSyncResponse struct {
	Message string `json:"message" example:"Project sync initiated"`
}
