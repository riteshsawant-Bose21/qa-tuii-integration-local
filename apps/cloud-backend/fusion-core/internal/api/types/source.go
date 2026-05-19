package types

type SourceSpecifications struct {
	PrimaryConnection    string   `json:"primary_connection"`
	SupportedConnections []string `json:"supported_connections"`
	PagingType           *string  `json:"paging_type"`
}

type SourceAsset struct {
	Black []string `json:"black,omitempty"`
	White []string `json:"white,omitempty"`
}

type SourceItemResponse struct {
	SourceID           int                  `json:"source_id"`
	Assets             []SourceAsset        `json:"assets"`
	ModelName          string               `json:"model_name"`
	ModelFamily        string               `json:"model_family"`
	Description        *string              `json:"description"`
	Specifications     SourceSpecifications `json:"specifications"`
	IsFusionCompatible bool                 `json:"is_fusion_compatible"`
}
