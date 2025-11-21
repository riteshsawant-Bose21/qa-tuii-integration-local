package validation

// getProductFieldDefinitions returns field definitions using struct tags approach
func getProductFieldDefinitions() map[string][]FieldDefinition {
	return GetProductFieldDefinitionsFromStructs()
}

// getPriceFieldDefinitions returns price field definitions using struct tags
func getPriceFieldDefinitions() []FieldDefinition {
	return GetPriceFieldDefinitionsFromStruct()
}

// GetProductTypeFromCategory maps product category to validation type
func GetProductTypeFromCategory(category string) string {
	categoryMap := map[string]string{
		// Plural forms (from JSON categories)
		"speakers":                  "speaker",
		"amplifiers":                "amplifier",
		"digital_signal_processors": "digital_signal_processor",
		"controllers":               "controller",
		"i_o_endpoints":             "i_o_endpoint",
		"additional_accessories":    "additional_accessories",

		// Singular forms (from processing code)
		"speaker":     "speaker",
		"amplifier":   "amplifier",
		"dsp":         "digital_signal_processor",
		"controller":  "controller",
		"io_endpoint": "i_o_endpoint",
		"accessory":   "additional_accessories",
	}

	if validationType, exists := categoryMap[category]; exists {
		return validationType
	}

	return "generic"
}
