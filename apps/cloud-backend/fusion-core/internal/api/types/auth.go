package types

// AuthErrorResponse represents an authentication error response
type AuthErrorResponse struct {
	Message string `json:"message"`
	Code    string `json:"code"`
}

// AuthSuccessResponse represents a successful authentication response
type AuthSuccessResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// TokenValidationResponse represents token validation result
type TokenValidationResponse struct {
	Valid   bool   `json:"valid"`
	UserID  string `json:"user_id,omitempty"`
	Email   string `json:"email,omitempty"`
	Message string `json:"message,omitempty"`
}

// AuthContext represents the authenticated user context
type AuthContext struct {
	UserID   string   `json:"user_id"`
	Email    string   `json:"email"`
	Username string   `json:"username,omitempty"`
	Roles    []string `json:"roles,omitempty"`
}
