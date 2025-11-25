package validation

import (
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/stretchr/testify/assert"
)

const (
	testProjectName    = "Test Project"
	testApplication    = "Test App"
	testAccountID      = "123"
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
				Name:            testProjectName,
				UserID:          testAccountID,
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
				Name:            testProjectName,
				UserID:          testAccountID,
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
				Name:            testProjectName,
				UserID:          testAccountID,
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
				Name:            "", // Missing name
				UserID:          testAccountID,
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
			name: "invalid request - missing account ID",
			request: &types.ProjectCreateRequest{
				Name:            testProjectName,
				UserID:          "", // Missing account ID
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
				Name:            testProjectName,
				UserID:          testAccountID,
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
			Name:            phaseTestProjectName,
			UserID:          phaseTestAccountID,
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
			Name:            phaseTestProjectName,
			UserID:          phaseTestAccountID,
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
			Name:            phaseTestProjectName,
			UserID:          phaseTestAccountID,
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
