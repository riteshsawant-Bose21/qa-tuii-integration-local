package types

type SourceItemResponse struct {
	SourceID                string   `json:"product_id"`
	Name                    string   `json:"name"`
	AssetPath               string   `json:"asset_path"`
	SourceType              string   `json:"type"`
	ConnectionType          string   `json:"connection_type"`
	Price                   float64  `json:"price"`
	PagingSourceType        *string  `json:"paging_source_type"`
	SupportedConnectionTypes []string `json:"supported_connection_types"`
}
