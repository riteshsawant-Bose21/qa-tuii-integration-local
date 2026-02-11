// Package validation provides data validation utilities and schemas.
package validation

import (
	"errors"
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
)

var validate *validator.Validate

func init() {
	validate = validator.New()

	// Register custom validators and check errors
	if err := validate.RegisterValidation("environment_type", validateEnvironmentType); err != nil {
		panic(err)
	}
	if err := validate.RegisterValidation("project_phase", validateProjectPhase); err != nil {
		panic(err)
	}
	if err := validate.RegisterValidation("currency", validateCurrency); err != nil {
		panic(err)
	}
	if err := validate.RegisterValidation("sort_order", validateSortOrder); err != nil {
		panic(err)
	}
	if err := validate.RegisterValidation("project_sort_field", validateProjectSortField); err != nil {
		panic(err)
	}
	if err := validate.RegisterValidation("uuid", ValidateUUID); err != nil {
		panic(err)
	}
}

// Custom validation functions

func validateCurrency(fl validator.FieldLevel) bool {
	return isValidCurrency(fl.Field().String())
}

func isValidCurrency(currency string) bool {
	// Basic validation for 3-letter ISO 4217 currency codes
	if len(currency) != 3 {
		return false
	}

	// Check if all characters are uppercase letters
	for _, char := range currency {
		if char < 'A' || char > 'Z' {
			return false
		}
	}

	// If not in common list, still allow it if it matches the format
	return true
}

func validateSortOrder(fl validator.FieldLevel) bool {
	return isValidSortOrder(fl.Field().String())
}

func isValidSortOrder(order string) bool {
	validOrders := []string{"asc", "desc", "ASC", "DESC"}
	for _, valid := range validOrders {
		if order == valid {
			return true
		}
	}
	return false
}

// ValidateUUID checks if a string is a valid UUID format.
func ValidateUUID(fl validator.FieldLevel) bool {
	_, err := uuid.Parse(fl.Field().String())
	return err == nil
}

// IsValidUUID checks if a string is a valid UUID format.
func IsValidUUID(id string) bool {
	_, err := uuid.Parse(id)
	return err == nil
}

// FormatValidationError formats validator errors into user-friendly messages
func formatValidationError(err error) error {
	var validationErrors validator.ValidationErrors
	if errors.As(err, &validationErrors) {
		var messages []string
		for _, ve := range validationErrors {
			message := fmt.Sprintf("Field '%s' validation failed", ve.Field())

			switch ve.Tag() {
			case "required":
				message = fmt.Sprintf("Field '%s' is required", ve.Field())
			case "min":
				message = fmt.Sprintf("Field '%s' must be at least %s characters long", ve.Field(), ve.Param())
			case "max":
				message = fmt.Sprintf("Field '%s' must be at most %s characters long", ve.Field(), ve.Param())
			case "email":
				message = fmt.Sprintf("Field '%s' must be a valid email address", ve.Field())
			case "uuid":
				message = fmt.Sprintf("Field '%s' must be a valid UUID", ve.Field())
			case "environment_type":
				message = fmt.Sprintf("Field '%s' must be one of: indoor, outdoor, hybrid", ve.Field())
			case "project_phase":
				message = fmt.Sprintf("Field '%s' must be one of: Proposal, Development, Commissioned", ve.Field())
			case "currency":
				message = fmt.Sprintf("Field '%s' must be a valid 3-letter ISO 4217 currency code", ve.Field())
			case "sort_order":
				message = fmt.Sprintf("Field '%s' must be 'asc' or 'desc'", ve.Field())
			case "project_sort_field":
				message = fmt.Sprintf("Field '%s' must be a valid sortable field", ve.Field())
			}

			messages = append(messages, message)
		}
		return errors.New(strings.Join(messages, "; "))
	}
	return err
}
