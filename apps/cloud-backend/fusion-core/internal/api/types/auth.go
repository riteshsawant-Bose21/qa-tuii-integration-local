package types

// AuthErrorResponse represents an authentication error response
type AuthErrorResponse struct {
	Message string `json:"message" example:"Authentication failed"`
	Code    string `json:"code" example:"AUTH_FAILED"`
}

// AuthSuccessResponse represents a successful authentication response
type AuthSuccessResponse struct {
	Message string      `json:"message" example:"Authentication successful"`
	Data    interface{} `json:"data,omitempty"`
}

// TokenValidationResponse represents token validation result
type TokenValidationResponse struct {
	Valid   bool   `json:"valid" example:"true"`
	UserID  string `json:"user_id,omitempty" example:"usr_123456789"`
	Email   string `json:"email,omitempty" example:"john.doe@company.com"`
	Message string `json:"message,omitempty" example:"Token is valid"`
}

// AuthContext represents the authenticated user context
type AuthContext struct {
	UserID   string   `json:"user_id" example:"usr_123456789"`
	Email    string   `json:"email" example:"john.doe@company.com"`
	Username string   `json:"username,omitempty" example:"john.doe"`
	Roles    []string `json:"roles,omitempty"`
}
