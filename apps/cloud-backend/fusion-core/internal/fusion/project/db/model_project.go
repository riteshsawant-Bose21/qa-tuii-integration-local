package db

import (
	"errors"
	"strconv"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

var (
	ProjectTable string = model.TableNames.Project
)

var (
	ProjectColumnID          string = model.ProjectColumns.ID
	ProjectColumnName        string = model.ProjectColumns.Name
	ProjectColumnDescription string = model.ProjectColumns.Description
	ProjectColumnCreatedAt   string = model.ProjectColumns.CreatedAt
	ProjectColumnUpdatedAt   string = model.ProjectColumns.UpdatedAt
)

// newProject returns a new Project node from the provided Project row
func newProject(row *customModel.GetProjectModel) (*types.Project, error) {
	if row == nil {
		return nil, errors.New("dbProject cannot be nil")
	}
	description := ""
	if row.Project.Description.Valid {
		description = row.Project.Description.String
	}
	venue := ""
	if row.Project.Venue.Valid {
		venue = row.Project.Venue.String
	}
	venueType := ""
	if row.EnvironmentType.Valid {
		venueType = row.EnvironmentType.String
	}
	application := ""
	if row.Application.Valid {
		application = row.Application.String
	}

	budget := types.Budget{
		Currency: row.Currency.String,
		Amount:   row.BudgetAmount,
	}

	return &types.Project{
		ID:              row.ID,
		AccountID:       strconv.Itoa(row.PrimaryOwnerAccountID),
		Name:            row.Name.String,
		Description:     description,
		Venue:           venue,
		EnvironmentType: venueType,
		Application:     application,
		Budget:          budget,
	}, nil
}
