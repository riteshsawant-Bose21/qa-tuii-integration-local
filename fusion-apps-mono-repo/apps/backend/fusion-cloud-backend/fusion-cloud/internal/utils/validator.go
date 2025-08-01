package utils

import (
	"reflect"
	"strings"

	"github.com/go-playground/locales/en"
	ut "github.com/go-playground/universal-translator"
	"github.com/go-playground/validator/v10"
	en_translations "github.com/go-playground/validator/v10/translations/en"
)

// Validate is the global validator instance.
var Validate *validator.Validate

// Trans is the global translator instance for default language (e.g., English).
var Trans ut.Translator

func init() {
	Validate = validator.New()

	// Register custom field name tag function (optional but recommended)
	// This makes error messages use the JSON field name if available.
	Validate.RegisterTagNameFunc(func(fld reflect.StructField) string {
		name := strings.SplitN(fld.Tag.Get("json"), ",", 2)[0]
		if name == "-" {
			return ""
		}
		return name
	})

	// Setup translator for English
	enLocale := en.New()
	uni := ut.New(enLocale, enLocale)  // uni = universal translator
	Trans, _ = uni.GetTranslator("en") // Get the English translator

	// Register default English translations for common validation tags
	// This provides good default messages before any custom ones.
	_ = en_translations.RegisterDefaultTranslations(Validate, Trans)

	// --- Register CUSTOM translations for specific validation tags ---
	// Custom message for 'required' tag
	_ = Validate.RegisterTranslation("required", Trans, func(ut ut.Translator) error {
		return ut.Add("required", "{0} is required and cannot be empty", true) // {0} is the field name
	}, func(ut ut.Translator, fe validator.FieldError) string {
		t, _ := ut.T("required", fe.Field())
		return t
	})

	// Custom message for 'email' tag
	_ = Validate.RegisterTranslation("email", Trans, func(ut ut.Translator) error {
		return ut.Add("email", "{0} must be a valid email address", true)
	}, func(ut ut.Translator, fe validator.FieldError) string {
		t, _ := ut.T("email", fe.Field())
		return t
	})

	// Custom message for 'min' tag (for string/slice length)
	_ = Validate.RegisterTranslation("min", Trans, func(ut ut.Translator) error {
		return ut.Add("min", "{0} must be at least {1} characters long", true) // {1} is the param value
	}, func(ut ut.Translator, fe validator.FieldError) string {
		t, _ := ut.T("min", fe.Field(), fe.Param())
		return t
	})

	// Custom message for 'gt' (greater than) tag (for numbers)
	_ = Validate.RegisterTranslation("gt", Trans, func(ut ut.Translator) error {
		return ut.Add("gt", "{0} must be greater than {1}", true)
	}, func(ut ut.Translator, fe validator.FieldError) string {
		t, _ := ut.T("gt", fe.Field(), fe.Param())
		return t
	})

	// Add more custom translations as needed for other tags (e.g., 'max', 'len', 'numeric', etc.)
}

// ValidationError represents a custom error specifically for validation failures.
type ValidationError struct {
	Message string            `json:"message"`
	Errors  map[string]string `json:"errors"` // FieldName -> ErrorMessage
}

func (e *ValidationError) Error() string {
	return e.Message
}

// NewValidationError creates a new ValidationError from a validator.ValidationErrors.
// It uses the translator to get localized error messages.
func NewValidationError(message string, err error) *ValidationError {
	validationErrors, ok := err.(validator.ValidationErrors)
	if !ok {
		return &ValidationError{Message: message, Errors: map[string]string{"_general": err.Error()}}
	}

	errs := make(map[string]string)
	for _, fieldErr := range validationErrors {
		// Use the translator to get the error message
		errs[fieldErr.Field()] = fieldErr.Translate(Trans)
	}
	return &ValidationError{Message: message, Errors: errs}
}
