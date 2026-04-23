package types

type SourceSpecifications struct {
	PrimaryConnection    string   `json:"primary_connection"`
	SupportedConnections []string `json:"supported_connections"`
	PagingType           *string  `json:"paging_type"`
}

type SourceItemResponse struct {
	SourceID           string                `json:"source_id"`
	Assets             []map[string][]string `json:"assets"`
	ModelName          string                `json:"model_name"`
	ModelFamily        string                `json:"model_family"`
	Description        *string               `json:"description"`
	Specifications     SourceSpecifications  `json:"specifications"`
	IsFusionCompatible bool                  `json:"is_fusion_compatible"`
}
