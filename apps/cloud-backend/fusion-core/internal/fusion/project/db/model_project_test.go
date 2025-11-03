package db

import (
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/null/v8"
	"github.com/stretchr/testify/assert"
)

func TestNewProject(t *testing.T) {
	t.Run("successfully creates project from valid row", func(t *testing.T) {
		row := &model.Project{
			ID:                    "test-id",
			PrimaryOwnerAccountID: 123,
			Name:                  null.NewString("Test Project", true),
			Description:           null.NewString("Test Description", true),
			Venue:                 null.NewString("Test Venue", true),
			EnvironmentType:       null.NewString("Indoor", true),
			Application:           null.NewString("Test App", true),
			BudgetAmount:          1000.0,
			Currency:              null.NewString("USD", true),
		}

		project, err := newProject(row)
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, row.ID, project.ID)
		assert.Equal(t, "123", project.AccountID)
		assert.Equal(t, row.Name.String, project.Name)
		assert.Equal(t, row.Description.String, project.Description)
		assert.Equal(t, row.Venue.String, project.Venue)
		assert.Equal(t, types.EnvironmentType(row.EnvironmentType.String), project.EnvironmentType)
		assert.Equal(t, row.Application.String, project.Application)
		assert.Equal(t, row.BudgetAmount, project.Budget.Amount)
		assert.Equal(t, row.Currency.String, project.Budget.Currency)
	})

	t.Run("successfully creates project with null fields", func(t *testing.T) {
		row := &model.Project{
			ID:                    "test-id",
			PrimaryOwnerAccountID: 123,
			Name:                  null.NewString("Test Project", true),
			Description:           null.NewString("", false),
			Venue:                 null.NewString("", false),
			EnvironmentType:       null.NewString("", false),
			Application:           null.NewString("", false),
			BudgetAmount:          1000.0,
			Currency:              null.NewString("", false),
		}

		project, err := newProject(row)
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
