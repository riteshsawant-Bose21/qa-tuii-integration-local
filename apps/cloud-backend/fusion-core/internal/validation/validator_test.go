package validation

import (
	"testing"

	"fusion-core/internal/api/types"
	"github.com/stretchr/testify/assert"
)

const (
	testProjectName    = "Test Project"
	testApplication    = "Test App"
	updatedProjectName = "Updated Project"
)

func TestValidateProjectCreateRequest(t *testing.T) {
	tests := []struct {
		name          string
		request       *types.ProjectCreateRequest
		expectedErr   bool
		checkPhase    bool
		expectedPhase types.ProjectPhase
	}{
		{
			name: "valid request with project phase",
			request: &types.ProjectCreateRequest{
				ID:              "123e4567-e89b-42d3-a456-426614174001",
				Name:            testProjectName,
				Application:     testApplication,
				EnvironmentType: types.EnvironmentTypeIndoor,
				ProjectPhase:    types.ProjectPhaseDevelopment,
				Budget: types.Budget{
					Amount:   1000.0,
					Currency: "USD",
				},
			},
			expectedErr:   false,
			checkPhase:    true,
			expectedPhase: types.ProjectPhaseDevelopment,
		},
		{
			name: "valid request with empty project phase - should default to Proposal",
			request: &types.ProjectCreateRequest{
				ID:              "123e4567-e89b-42d3-a456-426614174002",
				Name:            testProjectName,
				Application:     testApplication,
				EnvironmentType: types.EnvironmentTypeIndoor,
				ProjectPhase:    "", // Empty phase should default to Proposal
				Budget: types.Budget{
					Amount:   1000.0,
					Currency: "USD",
				},
			},
			expectedErr:   false,
			checkPhase:    true,
			expectedPhase: types.ProjectPhaseProposal,
		},
		{
			name: "valid request without project phase - should default to Proposal",
			request: &types.ProjectCreateRequest{
				ID:              "123e4567-e89b-42d3-a456-426614174003",
				Name:            testProjectName,
				Application:     testApplication,
				EnvironmentType: types.EnvironmentTypeIndoor,
				// ProjectPhase field omitted
				Budget: types.Budget{
					Amount:   1000.0,
					Currency: "USD",
				},
			},
			expectedErr:   false,
			checkPhase:    true,
			expectedPhase: types.ProjectPhaseProposal,
		},
		{
			name:        "nil request",
			request:     nil,
			expectedErr: true,
			checkPhase:  false,
		},
		{
			name: "invalid request - missing name",
			request: &types.ProjectCreateRequest{
				ID:              "123e4567-e89b-42d3-a456-426614174004",
				Name:            "", // Missing name
				Application:     testApplication,
				EnvironmentType: types.EnvironmentTypeIndoor,
				ProjectPhase:    types.ProjectPhaseProposal,
				Budget: types.Budget{
					Amount:   1000.0,
					Currency: "USD",
				},
			},
			expectedErr: true,
			checkPhase:  false,
		},

		{
			name: "invalid request - negative budget",
			request: &types.ProjectCreateRequest{
				ID:              "123e4567-e89b-42d3-a456-426614174005",
				Name:            testProjectName,
				Application:     testApplication,
				EnvironmentType: types.EnvironmentTypeIndoor,
				ProjectPhase:    types.ProjectPhaseProposal,
				Budget: types.Budget{
					Amount:   -100.0, // Negative budget
					Currency: "USD",
				},
			},
			expectedErr: true,
			checkPhase:  false,
		},
		{
			name: "invalid request - missing ID",
			request: &types.ProjectCreateRequest{
				// ID field missing - should fail validation
				Name:            testProjectName,
				Application:     testApplication,
				EnvironmentType: types.EnvironmentTypeIndoor,
				ProjectPhase:    types.ProjectPhaseProposal,
				Budget: types.Budget{
					Amount:   1000.0,
					Currency: "USD",
				},
			},
			expectedErr: true,
			checkPhase:  false,
		},
		{
			name: "invalid request - invalid UUID format",
			request: &types.ProjectCreateRequest{
				ID:              "not-a-valid-uuid", // Invalid UUID format
				Name:            testProjectName,
				Application:     testApplication,
				EnvironmentType: types.EnvironmentTypeIndoor,
				ProjectPhase:    types.ProjectPhaseProposal,
				Budget: types.Budget{
					Amount:   1000.0,
					Currency: "USD",
				},
			},
			expectedErr: true,
			checkPhase:  false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateProjectCreateRequest(tt.request)

			if tt.expectedErr {
				assert.Error(t, err, "Expected validation to fail but it passed")
			} else {
				assert.NoError(t, err, "Expected validation to pass but it failed: %v", err)

				if tt.checkPhase {
					assert.Equal(t, tt.expectedPhase, tt.request.ProjectPhase,
						"Project phase should be set to %s", tt.expectedPhase)
				}
			}
		})
	}
}

func TestValidateProjectUpdateRequest(t *testing.T) {
	tests := []struct {
		name        string
		request     *types.ProjectUpdateRequest
		expectedErr bool
	}{
		{
			name: "valid update request",
			request: &types.ProjectUpdateRequest{
				Name:         updatedProjectName,
				ProjectPhase: types.ProjectPhaseDevelopment,
				Budget: types.Budget{
					Amount:   2000.0,
					Currency: "EUR",
				},
			},
			expectedErr: false,
		},
		{
			name: "valid update request with empty project phase",
			request: &types.ProjectUpdateRequest{
				Name:         updatedProjectName,
				ProjectPhase: "", // Empty is allowed for updates
				Budget: types.Budget{
					Amount:   2000.0,
					Currency: "EUR",
				},
			},
			expectedErr: false,
		},
		{
			name:        "nil request",
			request:     nil,
			expectedErr: true,
		},
		{
			name: "invalid update request - negative budget",
			request: &types.ProjectUpdateRequest{
				Name:         updatedProjectName,
				ProjectPhase: types.ProjectPhaseDevelopment,
				Budget: types.Budget{
					Amount:   -500.0,
					Currency: "USD",
				},
			},
			expectedErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateProjectUpdateRequest(tt.request)

			if tt.expectedErr {
				assert.Error(t, err, "Expected validation to fail but it passed")
			} else {
				assert.NoError(t, err, "Expected validation to pass but it failed: %v", err)
			}
		})
	}
}

const (
	phaseTestProjectName = "Test Project"
	phaseTestApplication = "Test App"
	phaseTestAccountID   = "123"
)

// TestProjectPhaseDefaulting specifically tests the project phase defaulting feature
func TestProjectPhaseDefaulting(t *testing.T) {
	t.Run("project phase defaults to Proposal when empty", func(t *testing.T) {
		request := &types.ProjectCreateRequest{
			ID:              "123e4567-e89b-42d3-a456-426614174006",
			Name:            phaseTestProjectName,
			Application:     phaseTestApplication,
			EnvironmentType: types.EnvironmentTypeIndoor,
			ProjectPhase:    "", // Explicitly empty
			Budget: types.Budget{
				Amount:   1000.0,
				Currency: "USD",
			},
		} // Before validation, project phase is empty
		assert.Empty(t, request.ProjectPhase)

		// Run validation
		err := ValidateProjectCreateRequest(request)

		// Validation should succeed
		assert.NoError(t, err)

		// Project phase should now be set to Proposal
		assert.Equal(t, types.ProjectPhaseProposal, request.ProjectPhase)
	})

	t.Run("project phase is not changed when already set", func(t *testing.T) {
		request := &types.ProjectCreateRequest{
			ID:              "123e4567-e89b-42d3-a456-426614174007",
			Name:            phaseTestProjectName,
			Application:     phaseTestApplication,
			EnvironmentType: types.EnvironmentTypeIndoor,
			ProjectPhase:    types.ProjectPhaseDevelopment, // Already set
			Budget: types.Budget{
				Amount:   1000.0,
				Currency: "USD",
			},
		} // Run validation
		err := ValidateProjectCreateRequest(request)

		// Validation should succeed
		assert.NoError(t, err)

		// Project phase should remain unchanged
		assert.Equal(t, types.ProjectPhaseDevelopment, request.ProjectPhase)
	})

	t.Run("project phase defaults when field is uninitialized", func(t *testing.T) {
		request := &types.ProjectCreateRequest{
			ID:              "123e4567-e89b-42d3-a456-426614174008",
			Name:            phaseTestProjectName,
			Application:     phaseTestApplication,
			EnvironmentType: types.EnvironmentTypeIndoor,
			// ProjectPhase field not set at all - should be zero value (empty string)
			Budget: types.Budget{
				Amount:   1000.0,
				Currency: "USD",
			},
		}

		// Before validation, project phase should be zero value (empty)
		assert.Empty(t, request.ProjectPhase)

		// Run validation
		err := ValidateProjectCreateRequest(request)

		// Validation should succeed
		assert.NoError(t, err)

		// Project phase should now be set to Proposal
		assert.Equal(t, types.ProjectPhaseProposal, request.ProjectPhase)
	})
}

func TestValidateGetAllProjectsParams(t *testing.T) {
	t.Run("valid params", func(t *testing.T) {
		params := &types.GetAllProjectsParams{
			SortBy:     "created_at",
			SortOrder:  "asc",
			IsArchived: false,
		}

		err := ValidateGetAllProjectsParams(params)
		assert.NoError(t, err)
	})

	t.Run("invalid sort_by", func(t *testing.T) {
		params := &types.GetAllProjectsParams{
			SortBy:    "name",
			SortOrder: "asc",
		}

		err := ValidateGetAllProjectsParams(params)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "invalid sort_by field")
	})

	t.Run("invalid sort_order", func(t *testing.T) {
		params := &types.GetAllProjectsParams{
			SortBy:    "created_at",
			SortOrder: "up",
		}

		err := ValidateGetAllProjectsParams(params)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "invalid sort_order")
	})

	t.Run("nil params", func(t *testing.T) {
		err := ValidateGetAllProjectsParams(nil)
		assert.Error(t, err)
	})
}

func TestArchiveLockStarValidators(t *testing.T) {
	t.Run("archive validator nil", func(t *testing.T) {
		err := ValidateProjectArchiveRequest(nil)
		assert.Error(t, err)
	})

	t.Run("archive validator valid", func(t *testing.T) {
		req := &types.ProjectArchiveRequest{Archive: true}
		assert.NoError(t, ValidateProjectArchiveRequest(req))
	})

	t.Run("lock validator nil", func(t *testing.T) {
		err := ValidateProjectLockRequest(nil)
		assert.Error(t, err)
	})

	t.Run("lock validator valid", func(t *testing.T) {
		req := &types.ProjectLockRequest{IsLocked: true}
		assert.NoError(t, ValidateProjectLockRequest(req))
	})

	t.Run("star validator nil", func(t *testing.T) {
		err := ValidateProjectStarRequest(nil)
		assert.Error(t, err)
	})

	t.Run("star validator valid", func(t *testing.T) {
		req := &types.ProjectStarRequest{IsStarred: true}
		assert.NoError(t, ValidateProjectStarRequest(req))
	})
}

func TestIsValidUUID(t *testing.T) {
	valid := "123e4567-e89b-12d3-a456-426614174000"
	invalid := "not-a-uuid"

	assert.True(t, IsValidUUID(valid))
	assert.False(t, IsValidUUID(invalid))
}

func TestFormatValidationErrorMappings(t *testing.T) {
	// Create a struct with many validator tags to trigger different messages
	type vStruct struct {
		Email       string `validate:"required,email"`
		ID          string `validate:"required,uuid"`
		Name        string `validate:"required,min=3"`
		SortOrder   string `validate:"required,sort_order"`
		SortField   string `validate:"required,project_sort_field"`
		Currency    string `validate:"required,currency,len=3"`
		Environment string `validate:"required,environment_type"`
		Phase       string `validate:"required,project_phase"`
	}

	v := vStruct{
		Email:       "bad-email",
		ID:          "not-uuid",
		Name:        "ab",
		SortOrder:   "UP",
		SortField:   "name",
		Currency:    "usd",
		Environment: "inside",
		Phase:       "Unknown",
	}

	err := validate.Struct(v)
	// ensure we got a validation error
	assert.Error(t, err)

	formatted := formatValidationError(err)
	assert.Error(t, formatted)

	msg := formatted.Error()
	// Check that mapped messages appear for several tags
	assert.Contains(t, msg, "must be a valid email")
	assert.Contains(t, msg, "must be a valid UUID")
	assert.Contains(t, msg, "must be at least")
	assert.Contains(t, msg, "must be 'asc' or 'desc'")
	assert.Contains(t, msg, "must be a valid sortable field")
	assert.Contains(t, msg, "must be a valid 3-letter ISO 4217 currency code")
	assert.Contains(t, msg, "must be one of: indoor, outdoor, hybrid")
	assert.Contains(t, msg, "must be one of: Proposal, Development, Commissioned")
}

func TestHelperValidators(t *testing.T) {
	// currency
	assert.True(t, isValidCurrency("USD"))
	assert.False(t, isValidCurrency("UsD"))
	assert.False(t, isValidCurrency("US"))

	// sort order
	assert.True(t, isValidSortOrder("asc"))
	assert.True(t, isValidSortOrder("ASC"))
	assert.False(t, isValidSortOrder("up"))

	// project sort field
	assert.True(t, isValidProjectSortField("created_at"))
	assert.False(t, isValidProjectSortField("name"))
}

func TestValidateEnvironmentType(t *testing.T) {
	assert.True(t, isValidEnvironmentType("indoor"))
	assert.True(t, isValidEnvironmentType("outdoor"))
	assert.True(t, isValidEnvironmentType("hybrid"))
	assert.False(t, isValidEnvironmentType("space"))
}

func TestValidateProjectPhase(t *testing.T) {
	assert.True(t, isValidProjectPhase("Proposal"))
	assert.True(t, isValidProjectPhase("Development"))
	assert.True(t, isValidProjectPhase("Commissioned"))
	assert.False(t, isValidProjectPhase("Unknown"))
}

func TestValidateCurrency(t *testing.T) {
	assert.True(t, isValidCurrency("USD"))
	assert.False(t, isValidCurrency("usd"))
	assert.False(t, isValidCurrency("US"))
}

func TestValidateSortOrder(t *testing.T) {
	assert.True(t, isValidSortOrder("asc"))
	assert.True(t, isValidSortOrder("desc"))
	assert.False(t, isValidSortOrder("ascending"))
}

func TestValidateProjectSortField(t *testing.T) {
	assert.True(t, isValidProjectSortField("created_at"))
	assert.True(t, isValidProjectSortField("updated_at"))
	assert.False(t, isValidProjectSortField("name"))
}

func TestValidateProjectCreateRequest_EdgeCases(t *testing.T) {
	t.Run("whitespace-only name should fail", func(t *testing.T) {
		req := &types.ProjectCreateRequest{
			ID:              "123e4567-e89b-42d3-a456-426614174009",
			Name:            "   ", // Only whitespace
			Application:     testApplication,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}
		err := ValidateProjectCreateRequest(req)
		assert.Error(t, err)
	})

	t.Run("zero budget amount should pass", func(t *testing.T) {
		req := &types.ProjectCreateRequest{
			ID:              "123e4567-e89b-42d3-a456-426614174010",
			Name:            testProjectName,
			Application:     testApplication,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   0, // Zero should be valid
				Currency: "USD",
			},
		}
		err := ValidateProjectCreateRequest(req)
		assert.NoError(t, err)
	})

	t.Run("maximum valid currency length", func(t *testing.T) {
		req := &types.ProjectCreateRequest{
			ID:              "123e4567-e89b-42d3-a456-426614174011",
			Name:            testProjectName,
			Application:     testApplication,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "EUR", // Valid 3-letter currency
			},
		}
		err := ValidateProjectCreateRequest(req)
		assert.NoError(t, err)
	})
}

func TestValidateProjectUpdateRequest_EdgeCases(t *testing.T) {
	t.Run("partial update with valid name only", func(t *testing.T) {
		req := &types.ProjectUpdateRequest{
			Name: "New Valid Name",
			// Other fields empty
		}
		err := ValidateProjectUpdateRequest(req)
		assert.NoError(t, err)
	})

	t.Run("budget with currency but zero amount should pass", func(t *testing.T) {
		req := &types.ProjectUpdateRequest{
			Name: "Valid Name",
			Budget: types.Budget{
				Amount:   0, // Zero with currency should be valid
				Currency: "USD",
			},
		}
		err := ValidateProjectUpdateRequest(req)
		assert.NoError(t, err)
	})
}
