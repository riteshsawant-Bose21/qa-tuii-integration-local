package validation

import (
	"fmt"
	"reflect"
	"strings"
)

// FieldRequirement defines the requirement level for a field
type FieldRequirement int

const (
	// Required - Missing this field will cause an error and block processing
	Required FieldRequirement = iota
	// Optional - Missing this field will cause a low-severity warning
	Optional
)

// FieldDefinition defines a field and its validation requirements
type FieldDefinition struct {
	Name         string            `json:"name"`
	JSONPath     string            `json:"json_path"` // dot notation path in JSON, e.g., "power_handling.unit"
	Requirement  FieldRequirement  `json:"requirement"`
	Description  string            `json:"description"`
	ExpectedType string            `json:"expected_type"` // "string", "number", "object", "array", "boolean"
	Constraints  map[string]string `json:"constraints"`   // e.g., "min_length": "1", "max_value": "1000"
}

// ValidationResult represents the result of field validation
type ValidationResult struct {
	IsValid          bool                   `json:"is_valid"`
	RequiredErrors   []FieldValidationError `json:"required_errors"`   // Missing required fields
	OptionalWarnings []FieldValidationError `json:"optional_warnings"` // Missing optional fields
	TotalIssues      int                    `json:"total_issues"`
}

// FieldValidationError represents a specific field validation error
type FieldValidationError struct {
	FieldName    string           `json:"field_name"`
	JSONPath     string           `json:"json_path"`
	Requirement  FieldRequirement `json:"requirement"`
	Issue        string           `json:"issue"` // "missing", "wrong_type", "invalid_value", etc.
	ExpectedType string           `json:"expected_type"`
	ActualType   string           `json:"actual_type"`
	ActualValue  interface{}      `json:"actual_value"`
	Description  string           `json:"description"`
	Suggestion   string           `json:"suggestion"`
}

// FieldValidator provides comprehensive field validation
type FieldValidator struct {
	ProductTypeDefinitions map[string][]FieldDefinition `json:"product_type_definitions"`
	PriceDefinitions       []FieldDefinition            `json:"price_definitions"`
}

// NewFieldValidator creates a new field validator with predefined rules
func NewFieldValidator() *FieldValidator {
	return &FieldValidator{
		ProductTypeDefinitions: getProductFieldDefinitions(),
		PriceDefinitions:       getPriceFieldDefinitions(),
	}
}

// ValidateProductFields validates all fields for a specific product type
func (fv *FieldValidator) ValidateProductFields(productData map[string]interface{}, productType string, productID int) *ValidationResult {
	result := &ValidationResult{
		IsValid:          true,
		RequiredErrors:   []FieldValidationError{},
		OptionalWarnings: []FieldValidationError{},
	}

	// Get field definitions for this product type
	definitions, exists := fv.ProductTypeDefinitions[productType]
	if !exists {
		// Use generic product definitions if specific type not found
		definitions = fv.ProductTypeDefinitions["generic"]
	}

	validFields := 0

	for _, fieldDef := range definitions {
		validationError := fv.validateSingleField(productData, fieldDef, productID)
		if validationError == nil {
			validFields++
			continue
		}

		// Categorize the error by requirement level
		switch fieldDef.Requirement {
		case Required:
			result.RequiredErrors = append(result.RequiredErrors, *validationError)
			result.IsValid = false
		case Optional:
			result.OptionalWarnings = append(result.OptionalWarnings, *validationError)
		}
	}

	result.TotalIssues = len(result.RequiredErrors) + len(result.OptionalWarnings)

	return result
}

// ValidatePriceFields validates all fields for price data
func (fv *FieldValidator) ValidatePriceFields(priceData map[string]interface{}) *ValidationResult {
	result := &ValidationResult{
		IsValid:          true,
		RequiredErrors:   []FieldValidationError{},
		OptionalWarnings: []FieldValidationError{},
	}

	validFields := 0

	for _, fieldDef := range fv.PriceDefinitions {
		validationError := fv.validateSingleField(priceData, fieldDef, 0)
		if validationError == nil {
			validFields++
			continue
		}

		// Categorize the error by requirement level
		switch fieldDef.Requirement {
		case Required:
			result.RequiredErrors = append(result.RequiredErrors, *validationError)
			result.IsValid = false
		case Optional:
			result.OptionalWarnings = append(result.OptionalWarnings, *validationError)
		}
	}

	result.TotalIssues = len(result.RequiredErrors) + len(result.OptionalWarnings)

	return result
}

// validateSingleField validates a single field based on its definition
func (fv *FieldValidator) validateSingleField(data map[string]interface{}, fieldDef FieldDefinition, contextID int) *FieldValidationError {
	// Navigate to the field using JSON path
	value, exists := fv.getValueByPath(data, fieldDef.JSONPath)

	if !exists {
		return &FieldValidationError{
			FieldName:    fieldDef.Name,
			JSONPath:     fieldDef.JSONPath,
			Requirement:  fieldDef.Requirement,
			Issue:        "missing",
			ExpectedType: fieldDef.ExpectedType,
			ActualType:   "undefined",
			ActualValue:  nil,
			Description:  fieldDef.Description,
			Suggestion:   fmt.Sprintf("Add field '%s' to the data structure", fieldDef.JSONPath),
		}
	}

	// Validate type
	actualType := fv.getTypeName(value)
	if fieldDef.ExpectedType != "any" && !fv.isTypeCompatible(actualType, fieldDef.ExpectedType) {
		return &FieldValidationError{
			FieldName:    fieldDef.Name,
			JSONPath:     fieldDef.JSONPath,
			Requirement:  fieldDef.Requirement,
			Issue:        "wrong_type",
			ExpectedType: fieldDef.ExpectedType,
			ActualType:   actualType,
			ActualValue:  value,
			Description:  fieldDef.Description,
			Suggestion:   fmt.Sprintf("Field '%s' should be of type '%s' but got '%s'", fieldDef.JSONPath, fieldDef.ExpectedType, actualType),
		}
	}

	// Validate constraints
	if constraintError := fv.validateConstraints(value, fieldDef.Constraints, fieldDef); constraintError != nil {
		constraintError.FieldName = fieldDef.Name
		constraintError.JSONPath = fieldDef.JSONPath
		constraintError.Requirement = fieldDef.Requirement
		constraintError.Description = fieldDef.Description
		return constraintError
	}

	return nil
}

// getValueByPath navigates through nested data using dot notation
func (fv *FieldValidator) getValueByPath(data map[string]interface{}, path string) (interface{}, bool) {
	if path == "" {
		return data, true
	}

	parts := strings.Split(path, ".")
	current := data

	for i, part := range parts {
		if current == nil {
			return nil, false
		}

		if i == len(parts)-1 {
			// Last part - return the value
			value, exists := current[part]
			return value, exists
		}

		// Intermediate part - must be a map
		next, exists := current[part]
		if !exists {
			return nil, false
		}

		nextMap, ok := next.(map[string]interface{})
		if !ok {
			return nil, false
		}

		current = nextMap
	}

	return current, true
}

// getTypeName returns a human-readable type name
func (fv *FieldValidator) getTypeName(value interface{}) string {
	if value == nil {
		return "null"
	}

	switch value.(type) {
	case string:
		return "string"
	case float64, int, int64, float32:
		return "number"
	case bool:
		return "boolean"
	case []interface{}:
		return "array"
	case map[string]interface{}:
		return "object"
	default:
		return reflect.TypeOf(value).String()
	}
}

// isTypeCompatible checks if actual type is compatible with expected type
func (fv *FieldValidator) isTypeCompatible(actual, expected string) bool {
	if expected == "any" {
		return true
	}

	if actual == expected {
		return true
	}

	// Handle number compatibility
	if expected == "number" && (actual == "float64" || actual == "int" || actual == "int64" || actual == "float32") {
		return true
	}

	return false
}

// validateConstraints validates field constraints
func (fv *FieldValidator) validateConstraints(value interface{}, constraints map[string]string, fieldDef FieldDefinition) *FieldValidationError {
	for constraint, expectedValue := range constraints {
		switch constraint {
		case "min_length":
			if str, ok := value.(string); ok {
				if minLen := parseInt(expectedValue); minLen > 0 && len(str) < minLen {
					return &FieldValidationError{
						Issue:        "constraint_violation",
						ExpectedType: fieldDef.ExpectedType,
						ActualType:   fv.getTypeName(value),
						ActualValue:  value,
						Suggestion:   fmt.Sprintf("Field must have at least %s characters", expectedValue),
					}
				}
			}
		case "max_length":
			if str, ok := value.(string); ok {
				if maxLen := parseInt(expectedValue); maxLen > 0 && len(str) > maxLen {
					return &FieldValidationError{
						Issue:        "constraint_violation",
						ExpectedType: fieldDef.ExpectedType,
						ActualType:   fv.getTypeName(value),
						ActualValue:  value,
						Suggestion:   fmt.Sprintf("Field must have at most %s characters", expectedValue),
					}
				}
			}
		case "not_empty":
			if expectedValue == "true" {
				if str, ok := value.(string); ok && strings.TrimSpace(str) == "" {
					return &FieldValidationError{
						Issue:        "constraint_violation",
						ExpectedType: fieldDef.ExpectedType,
						ActualType:   fv.getTypeName(value),
						ActualValue:  value,
						Suggestion:   "Field cannot be empty",
					}
				}
			}
		case "positive":
			if expectedValue == "true" {
				if num, ok := value.(float64); ok && num <= 0 {
					return &FieldValidationError{
						Issue:        "constraint_violation",
						ExpectedType: fieldDef.ExpectedType,
						ActualType:   fv.getTypeName(value),
						ActualValue:  value,
						Suggestion:   "Field must be a positive number",
					}
				}
			}
		}
	}

	return nil
}

// parseInt safely parses a string to int
func parseInt(s string) int {
	if len(s) == 0 {
		return 0
	}

	result := 0
	for _, char := range s {
		if char >= '0' && char <= '9' {
			result = result*10 + int(char-'0')
		} else {
			return 0
		}
	}
	return result
}

// FormatValidationReport formats the validation result as a human-readable report
func (fv *FieldValidator) FormatValidationReport(result *ValidationResult, entityType string, entityID int) string {
	var report strings.Builder

	report.WriteString(fmt.Sprintf("=== Validation Report for %s ID: %d ===\n", entityType, entityID))
	report.WriteString(fmt.Sprintf("Overall Status: %s\n", map[bool]string{true: "VALID", false: "INVALID"}[result.IsValid]))
	report.WriteString(fmt.Sprintf("Total Issues: %d\n\n", result.TotalIssues))

	if len(result.RequiredErrors) > 0 {
		report.WriteString("REQUIRED FIELD ERRORS (Will Block Processing):\n")
		for _, err := range result.RequiredErrors {
			report.WriteString(fmt.Sprintf("  - %s (%s): %s\n", err.FieldName, err.JSONPath, err.Suggestion))
		}
		report.WriteString("\n")
	}

	if len(result.OptionalWarnings) > 0 {
		report.WriteString("OPTIONAL FIELD WARNINGS (Recommendations):\n")
		for _, err := range result.OptionalWarnings {
			report.WriteString(fmt.Sprintf("  - %s (%s): %s\n", err.FieldName, err.JSONPath, err.Suggestion))
		}
		report.WriteString("\n")
	}

	if result.IsValid {
		report.WriteString("All required fields are present and valid!\n")
	} else {
		report.WriteString("Some required fields are missing or invalid.\n")
	}

	return report.String()
}
