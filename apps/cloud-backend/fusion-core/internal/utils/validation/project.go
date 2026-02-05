package validation

import (
	"errors"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/go-playground/validator/v10"
)

// ValidateProjectCreateRequest validates a project create request
func ValidateProjectCreateRequest(req *types.ProjectCreateRequest) error {
	if req == nil {
		return errors.New("request cannot be nil")
	}

	// Set default project phase if empty
	if req.ProjectPhase == "" {
		req.ProjectPhase = types.ProjectPhaseProposal
	}

	// Validate name is not whitespace-only
	if strings.TrimSpace(req.Name) == "" {
		return errors.New("project name cannot be empty or whitespace-only")
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
