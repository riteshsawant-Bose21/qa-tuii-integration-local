package db

import (
	"errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
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
func newProject(row *model.Project) (*types.Project, error) {
	if row == nil {
		return nil, errors.New("dbProject cannot be nil")
	}
	description := ""
	if row.Description.Valid {
		description = row.Description.String
	}
	venue := ""
	if row.Venue.Valid {
		venue = row.Venue.String
	}
	environmentType := types.EnvironmentType("")
	if row.EnvironmentType.Valid {
		environmentType = types.EnvironmentType(row.EnvironmentType.String)
	}
	projectPhase := types.ProjectPhase("")
	if row.ProjectPhase.Valid {
		projectPhase = types.ProjectPhase(row.ProjectPhase.String)
	}
	application := ""
	if row.Application.Valid {
		application = row.Application.String
	}

	var budgetAmount int64
	if !row.BudgetAmount.IsZero() {
		budgetAmount, _ = row.BudgetAmount.Int64()
	}

	budget := types.Budget{
		Currency: row.Currency.String,
		Amount:   budgetAmount,
	}

	lockedByUser := ""
	if row.LockedByUserID.Valid {
		lockedByUser = row.LockedByUserID.String
	}

	return &types.Project{
		ID:              row.ID,
		Name:            row.Name.String,
		Description:     description,
		Venue:           venue,
		EnvironmentType: environmentType,
		ProjectPhase:    projectPhase,
		Application:     application,
		Budget:          budget,
		IsArchived:      row.IsArchived,
		LockedByUser:    lockedByUser,
		CreatedAt:       row.CreatedAt,
		UpdatedAt:       row.UpdatedAt,
	}, nil
}
