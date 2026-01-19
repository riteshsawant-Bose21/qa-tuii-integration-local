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

// QATokenRequest represents a request for QA authentication tokens
type QATokenRequest struct {
	Username string `json:"username" binding:"required" example:"test-user@company.com"`
}

// QATokenResponse represents the response containing Auth0 tokens
type QATokenResponse struct {
	AccessToken string `json:"access_token" example:"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."`
	IDToken     string `json:"id_token" example:"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."`
	TokenType   string `json:"token_type" example:"Bearer"`
	ExpiresIn   int    `json:"expires_in" example:"86400"`
}

// QATokenSuccessResponse represents a successful QA token response
type QATokenSuccessResponse struct {
	Message string           `json:"message" example:"Tokens generated successfully"`
	Data    *QATokenResponse `json:"data"`
}
