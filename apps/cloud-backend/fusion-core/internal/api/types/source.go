package types

type SourceResponse struct {
	SourceID          int         `json:"product_id"`
	Name              string      `json:"name"`
	AssetPath         string      `json:"asset_path"`
	SourceType        string      `json:"type"`
	ConnectionType    string      `json:"connection_type"`
}
