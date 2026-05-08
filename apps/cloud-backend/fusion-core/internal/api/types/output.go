package types

type OutputSpecifications struct {
	PrimaryConnection    string   `json:"primary_connection"`
	SupportedConnections []string `json:"supported_connections"`
}

type OutputItemResponse struct {
	OutputID       int                  `json:"id"`
	Name           string               `json:"name"`
	Type           string               `json:"type"`
	Images         string               `json:"images"`
	Specifications OutputSpecifications `json:"specifications"`
}
