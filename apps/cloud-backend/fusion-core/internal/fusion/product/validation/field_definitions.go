// Package validation provides data validation functionality for product data.
package validation

// getProductFieldDefinitions returns field definitions using struct tags approach
func getProductFieldDefinitions() map[string][]FieldDefinition {
	return GetProductFieldDefinitionsFromStructs()
}

// getPriceFieldDefinitions returns price field definitions using struct tags
func getPriceFieldDefinitions() []FieldDefinition {
	return GetPriceFieldDefinitionsFromStruct()
}
