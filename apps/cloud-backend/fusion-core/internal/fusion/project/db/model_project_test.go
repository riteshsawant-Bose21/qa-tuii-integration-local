package db

import (
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/null/v8"
	boilerTypes "github.com/aarondl/sqlboiler/v4/types"
	"github.com/ericlagergren/decimal"
	"github.com/stretchr/testify/assert"
)

func TestNewProject(t *testing.T) {
	const testID = "test-id"
	const testProjectName = "Test Project"
	const lockedUserEmail = "locked@example.com"
	const lockedUserID = "locked-user-id"

	t.Run("successfully creates project from valid row", func(t *testing.T) {
		projectModel := &customModel.GetProjectModel{
			Project: model.Project{
				ID:                 testID,
				PrimaryOwnerAccountID: null.NewInt(123, true),
				Name:               null.NewString(testProjectName, true),
				Description:        null.NewString("Test Description", true),
				Venue:              null.NewString("Test Venue", true),
				EnvironmentType:    null.NewString("Indoor", true),
				Application:        null.NewString("Test App", true),
				BudgetAmount:       boilerTypes.NewNullDecimal(decimal.New(1000, 0)),
				Currency:           null.NewString("USD", true),
				LockedByUserID:     null.NewString(lockedUserID, true),
			},
			IsStarred:         true,
			LockedByUserEmail: lockedUserEmail,
		}

		project, err := newProject(projectModel)
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, projectModel.Project.ID, project.ID)
		assert.Equal(t, projectModel.Project.Name.String, project.Name)
		assert.Equal(t, projectModel.Project.Description.String, project.Description)
		assert.Equal(t, projectModel.Project.Venue.String, project.Venue)
		assert.Equal(t, types.EnvironmentType(projectModel.Project.EnvironmentType.String), project.EnvironmentType)
		assert.Equal(t, projectModel.Project.Application.String, project.Application)
		expectedBudget, _ := projectModel.Project.BudgetAmount.Int64()
		assert.Equal(t, expectedBudget, project.Budget.Amount)
		assert.Equal(t, projectModel.Project.Currency.String, project.Budget.Currency)
		assert.Equal(t, projectModel.IsStarred, project.IsStarred)
		assert.Equal(t, projectModel.LockedByUserEmail, project.LockedByUser)
	})

	t.Run("successfully creates project with null fields", func(t *testing.T) {
		projectModel := &customModel.GetProjectModel{
			Project: model.Project{
				ID:                 testID,
				PrimaryOwnerAccountID: null.NewInt(123, true),
				Name:               null.NewString(testProjectName, true),
				Description:        null.NewString("", false),
				Venue:              null.NewString("", false),
				EnvironmentType:    null.NewString("", false),
				Application:        null.NewString("", false),
				BudgetAmount:       boilerTypes.NewNullDecimal(decimal.New(1000, 0)),
				Currency:           null.NewString("", false),
			},
			IsStarred:         false,
			LockedByUserEmail: "",
		}

		project, err := newProject(projectModel)
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, "", project.Description)
		assert.Equal(t, "", project.Venue)
		assert.Equal(t, types.EnvironmentType(""), project.EnvironmentType)
		assert.Equal(t, "", project.Application)
		assert.Equal(t, "", project.Budget.Currency)
	})

	t.Run("returns error when row is nil", func(t *testing.T) {
		project, err := newProject(nil)
		assert.Error(t, err)
		assert.Nil(t, project)
	})

	t.Run("returns empty locked_by_user when no locked user email is provided", func(t *testing.T) {
		projectModel := &customModel.GetProjectModel{
			Project: model.Project{
				ID:             testID,
				Name:           null.NewString(testProjectName, true),
				LockedByUserID: null.NewString(lockedUserID, true),
			},
			IsStarred:         false,
			LockedByUserEmail: "", // No email provided
		}

		project, err := newProject(projectModel)
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, "", project.LockedByUser)
	})

	t.Run("returns locked_by_user email when provided", func(t *testing.T) {
		projectModel := &customModel.GetProjectModel{
			Project: model.Project{
				ID:             testID,
				Name:           null.NewString(testProjectName, true),
				LockedByUserID: null.NewString(lockedUserID, true),
			},
			IsStarred:         false,
			LockedByUserEmail: lockedUserEmail,
		}

		project, err := newProject(projectModel)
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, lockedUserEmail, project.LockedByUser)
	})

	t.Run("correctly maps IsStarred value", func(t *testing.T) {
		// Test with starred project
		starredProject := &customModel.GetProjectModel{
			Project: model.Project{
				ID:   testID,
				Name: null.NewString(testProjectName, true),
			},
			IsStarred:         true,
			LockedByUserEmail: "",
		}

		project, err := newProject(starredProject)
		assert.NoError(t, err)
		assert.True(t, project.IsStarred)

		// Test with unstarred project
		unstarredProject := &customModel.GetProjectModel{
			Project: model.Project{
				ID:   testID,
				Name: null.NewString(testProjectName, true),
			},
			IsStarred:         false,
			LockedByUserEmail: "",
		}

		project, err = newProject(unstarredProject)
		assert.NoError(t, err)
		assert.False(t, project.IsStarred)
	})
}

func TestProjectTableAndColumns(t *testing.T) {
	t.Run("project table name is set correctly", func(t *testing.T) {
		assert.Equal(t, model.TableNames.Project, ProjectTable)
	})

	t.Run("project column names are set correctly", func(t *testing.T) {
		assert.Equal(t, model.ProjectColumns.ID, ProjectColumnID)
		assert.Equal(t, model.ProjectColumns.Name, ProjectColumnName)
		assert.Equal(t, model.ProjectColumns.Description, ProjectColumnDescription)
		assert.Equal(t, model.ProjectColumns.CreatedAt, ProjectColumnCreatedAt)
		assert.Equal(t, model.ProjectColumns.UpdatedAt, ProjectColumnUpdatedAt)
	})
}
