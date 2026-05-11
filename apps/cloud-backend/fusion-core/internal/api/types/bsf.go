package types

// ComponentCategory represents the type of component being processed.
// For example, "speaker" for speakers and subwoofers. This is used to determinethe appropriate BSF structure and processing logic during BSF generation.
// currently only "speaker" is supported, but this can be extended in the future to support other hardware component types like "Slider", "pullback", etc.
type ComponentCategory string

const (
	// ComponentCategorySpeaker is the component category for speakers and subwoofers.
	ComponentCategorySpeaker ComponentCategory = "speaker"
)

// ValidCategories lists all supported component categories.
var ValidCategories = map[ComponentCategory]struct{}{
	ComponentCategorySpeaker: {},
}

// BSFGenerateRequest holds the parsed multipart form data for BSF generation.
type BSFGenerateRequest struct {
	ProductName string            `json:"product_name"`
	Family      string            `json:"family"`
	Description string            `json:"description"`
	SKU         string            `json:"sku"`
	IsSubwoofer bool              `json:"is_subwoofer"`
	Category    ComponentCategory `json:"category"`
	SPMData     []byte            `json:"-"`
}

// BSFGenerateResponse is the response returned after BSF generation and upload.
type BSFGenerateResponse struct {
	BSFURL string `json:"bsf_url"`
}
