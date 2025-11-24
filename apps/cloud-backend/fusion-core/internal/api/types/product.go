package types

var (
	ProductCategorySpeaker                string = "speaker"
	ProductCategoryAmplifier              string = "amplifier"
	ProductCategoryDigitalSignalProcessor string = "dsp"
	ProductCategoryController             string = "controller"
	ProductCategoryEndpoint               string = "io_endpoint"
	ProductCategoryAccessory              string = "accessory"
)

// Generic product item response used for all product types
type ProductItemResponse struct {
	ProductID      int         `json:"productid"`
	Assets         interface{} `json:"assets"`
	ModelName      string      `json:"model_name"`
	ModelFamily    string      `json:"model_family,omitempty"`
	Description    string      `json:"description,omitempty"`
	Specifications interface{} `json:"specifications"`
}

// API response structure
type ProductResponse struct {
	Speaker    []ProductItemResponse `json:"speaker,omitempty"`
	Amplifier  []ProductItemResponse `json:"amplifier,omitempty"`
	Controller []ProductItemResponse `json:"controller,omitempty"`
	DSP        []ProductItemResponse `json:"dsp,omitempty"`
	Accessory  []ProductItemResponse `json:"accessory,omitempty"`
	IOEndpoint []ProductItemResponse `json:"io_endpoint,omitempty"`
}

// Individual product response when fetching by ID
type SingleProductResponse struct {
	Speaker    *ProductItemResponse `json:"speaker,omitempty"`
	Amplifier  *ProductItemResponse `json:"amplifier,omitempty"`
	DSP        *ProductItemResponse `json:"dsp,omitempty"`
	Controller *ProductItemResponse `json:"controller,omitempty"`
	Accessory  *ProductItemResponse `json:"accessory,omitempty"`
	IOEndpoint *ProductItemResponse `json:"io_endpoint,omitempty"`
}

// Price API response types
type PriceResponse struct {
	ProductID int           `json:"product_id"`
	Prices    []PriceDetail `json:"prices"`
}

type PriceDetail struct {
	Variant  string  `json:"variant,omitempty"`
	Currency string  `json:"currency"`
	Price    float64 `json:"price"`
}
