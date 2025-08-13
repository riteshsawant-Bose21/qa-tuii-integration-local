package server

// Response represents a UDP server response
type UDPResponse struct {
	Status  string `json:"status"`
	Message string `json:"message,omitempty"`
}
