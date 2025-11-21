package validation

import (
	"errors"
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

var validate *validator.Validate

func init() {
	validate = validator.New()

	// Register custom validators
	validate.RegisterValidation("environment_type", validateEnvironmentType)
	validate.RegisterValidation("project_phase", validateProjectPhase)
	validate.RegisterValidation("currency", validateCurrency)
	validate.RegisterValidation("sort_order", validateSortOrder)
	validate.RegisterValidation("project_sort_field", validateProjectSortField)
	validate.RegisterValidation("uuid", ValidateUUID)
}

// ValidateProjectCreateRequest validates a project create request
func ValidateProjectCreateRequest(req *types.ProjectCreateRequest) error {
	if req == nil {
		return errors.New("request cannot be nil")
	}

	// Set default project phase if empty
	if req.ProjectPhase == "" {
		req.ProjectPhase = types.ProjectPhaseProposal
	}

	// Add struct tags validation
	if err := validate.Struct(req); err != nil {
		return formatValidationError(err)
	}

	// Additional budget validation (check for negative amount)
	if req.Budget.Amount < 0 {
		return errors.New("budget amount must be non-negative")
	}

	return nil
}

// ValidateProjectUpdateRequest validates a project update request
func ValidateProjectUpdateRequest(req *types.ProjectUpdateRequest) error {
	if req == nil {
		return errors.New("request cannot be nil")
	}

	// Add struct tags validation
	if err := validate.Struct(req); err != nil {
		return formatValidationError(err)
	}

	// Additional budget validation (check for negative amount) - only if budget is provided
	if req.Budget.Currency != "" && req.Budget.Amount < 0 {
		return errors.New("budget amount must be non-negative")
	}

	// Validate name if provided
	if req.Name != "" && strings.TrimSpace(req.Name) == "" {
		return errors.New("project name cannot be empty if provided")
	}

	return nil
}

// ValidateGetAllProjectsParams validates query parameters for getting all projects
func ValidateGetAllProjectsParams(params *types.GetAllProjectsParams) error {
	if params == nil {
		return errors.New("parameters cannot be nil")
	}

	// Validate sort_by field
	if params.SortBy != "" && !isValidProjectSortField(params.SortBy) {
		return errors.New("invalid sort_by field: must be one of 'created_at', 'updated_at'")
	}

	// Validate sort_order
	if params.SortOrder != "" && !isValidSortOrder(params.SortOrder) {
		return errors.New("invalid sort_order: must be 'asc' or 'desc'")
	}

	return nil
}

// ValidateProjectArchiveRequest validates a project archive/unarchive request
func ValidateProjectArchiveRequest(req *types.ProjectArchiveRequest) error {
	if req == nil {
		return errors.New("request cannot be nil")
	}

	// No additional validation needed for boolean field
	return nil
}

// ValidateProjectLockRequest validates a project lock/unlock request
func ValidateProjectLockRequest(req *types.ProjectLockRequest) error {
	if req == nil {
		return errors.New("request cannot be nil")
	}

	// No additional validation needed for boolean field
	return nil
}

// ValidateProjectStarRequest validates a project star/unstar request
func ValidateProjectStarRequest(req *types.ProjectStarRequest) error {
	if req == nil {
		return errors.New("request cannot be nil")
	}

	// No additional validation needed for boolean field
	return nil
}

// Custom validation functions

func validateEnvironmentType(fl validator.FieldLevel) bool {
	return isValidEnvironmentType(fl.Field().String())
}

func isValidEnvironmentType(envType string) bool {
	validTypes := []string{"indoor", "outdoor", "hybrid"}
	for _, valid := range validTypes {
		if envType == valid {
			return true
		}
	}
	return false
}

func validateProjectPhase(fl validator.FieldLevel) bool {
	return isValidProjectPhase(fl.Field().String())
}

func isValidProjectPhase(phase string) bool {
	validPhases := []string{"Proposal", "Development", "Commissioned"}
	for _, valid := range validPhases {
		if phase == valid {
			return true
		}
	}
	return false
}

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

func validateProjectSortField(fl validator.FieldLevel) bool {
	return isValidProjectSortField(fl.Field().String())
}

func isValidProjectSortField(field string) bool {
	validFields := []string{"created_at", "updated_at"}
	for _, valid := range validFields {
		if field == valid {
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

// formatValidationError formats validator errors into user-friendly messages
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
