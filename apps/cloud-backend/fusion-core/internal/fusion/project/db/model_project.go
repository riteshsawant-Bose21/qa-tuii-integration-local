package db

import (
	"encoding/json"
	"errors"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

var (
	ProjectTable string = model.TableNames.Projects
)

var (
	ProjectColumnID          string = model.ProjectColumns.ID
	ProjectColumnName        string = model.ProjectColumns.Name
	ProjectColumnDescription string = model.ProjectColumns.Description
	ProjectColumnCreatedAt   string = model.ProjectColumns.CreatedAt
	ProjectColumnUpdatedAt   string = model.ProjectColumns.UpdatedAt
)

var (
	projectPrimaryKeyColumns = []string{ProjectColumnID}
)

// newProject returns a new Project node from the provided Project row
func newProject(row *model.Project) (*fusion.Project, error) {
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
	venueType := ""
	if row.VenueType.Valid {
		venueType = row.VenueType.String
	}
	application := ""
	if row.Application.Valid {
		application = row.Application.String
	}
	projectFileURL := ""
	if row.ProjectFileURL.Valid {
		projectFileURL = row.ProjectFileURL.String
	}

	var budget fusion.Budget
	if row.Budget.Valid {
		_ = json.Unmarshal(row.Budget.JSON, &budget)
	}

	var metaData map[string]interface{}
	if row.MetaData.Valid {
		_ = json.Unmarshal(row.MetaData.JSON, &metaData)
	}

	return &fusion.Project{
		ID:             row.ID,
		OrganizationID: row.OrganizationID,
		Name:           row.Name,
		Description:    description,
		Venue:          venue,
		VenueType:      venueType,
		Application:    application,
		Budget:         budget,
		MetaData:       metaData,
		ProjectFileURL: projectFileURL,
	}, nil
}
