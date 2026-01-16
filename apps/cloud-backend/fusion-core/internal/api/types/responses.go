package types

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
