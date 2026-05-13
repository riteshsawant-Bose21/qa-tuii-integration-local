package types

type OutputSpecifications struct {
	SupportedConnections []string `json:"supported_connections"`
	PagingType           *string  `json:"paging_type"`
}

type OutputAsset struct {
	Black []string `json:"black,omitempty"`
	White []string `json:"white,omitempty"`
}

type OutputItemResponse struct {
	OutputID       int                  `json:"id"`
	Name           string               `json:"name"`
	Type           string               `json:"type"`
	Assets         []OutputAsset        `json:"assets"`
	Specifications OutputSpecifications `json:"specifications"`
}
