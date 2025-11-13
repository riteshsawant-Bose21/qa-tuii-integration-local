package db

import (
	"errors"

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
	environmentType := types.EnvironmentType("")
	if row.Project.EnvironmentType.Valid {
		environmentType = types.EnvironmentType(row.Project.EnvironmentType.String)
	}
	projectPhase := types.ProjectPhase("")
	if row.Project.ProjectPhase.Valid {
		projectPhase = types.ProjectPhase(row.Project.ProjectPhase.String)
	}
	application := ""
	if row.Project.Application.Valid {
		application = row.Project.Application.String
	}

	var budgetAmount int64
	if !row.Project.BudgetAmount.IsZero() {
		budgetAmount, _ = row.Project.BudgetAmount.Int64()
	}

	budget := types.Budget{
		Currency: row.Project.Currency.String,
		Amount:   budgetAmount,
	}

	lockedByUser := ""
	if row.Project.LockedByUserID.Valid && row.LockedByUserEmail != "" {
		lockedByUser = row.LockedByUserEmail
	}

	return &types.Project{
		ID:              row.Project.ID,
		Name:            row.Project.Name.String,
		Description:     description,
		Venue:           venue,
		EnvironmentType: environmentType,
		ProjectPhase:    projectPhase,
		Application:     application,
		Budget:          budget,
		IsArchived:      row.Project.IsArchived,
		IsStarred:       row.IsStarred,
		LockedByUser:    lockedByUser,
		CreatedAt:       row.Project.CreatedAt,
		UpdatedAt:       row.Project.UpdatedAt,
	}, nil
}
