package types

// SuccessResponse represents a successful API response
type SuccessResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// ErrorResponse represents an error API response
type ErrorResponse2 struct {
	Message string `json:"message"`
	Code    string `json:"code"`
}

// ListResponse represents a paginated list response
type ListResponse struct {
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
	Total   int         `json:"total,omitempty"`
	Page    int         `json:"page,omitempty"`
	Limit   int         `json:"limit,omitempty"`
}
