package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	"github.com/google/uuid"

	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

type Service struct {
	db *sql.DB
}

func NewService(db *sql.DB) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

func (s *Service) Insert(ctx context.Context, project *fusion.Project) error {
	if project == nil {
		return errors.New("project cannot be nil")
	}

	if project.ID == "" {
		project.ID = uuid.New().String()
	}

	budgetJSON, err := json.Marshal(project.Budget)
	if err != nil {
		return fmt.Errorf("failed to marshal budget: %v", err)
	}
	metaDataJSON, err := json.Marshal(project.MetaData)
	if err != nil {
		return fmt.Errorf("failed to marshal meta_data: %v", err)
	}

	row := &model.Project{
		ID:             project.ID,
		OrganizationID: project.OrganizationID,
		Name:           project.Name,
		Description:    null.NewString(project.Description, project.Description != ""),
		Venue:          null.NewString(project.Venue, project.Venue != ""),
		VenueType:      null.NewString(project.VenueType, project.VenueType != ""),
		Application:    null.NewString(project.Application, project.Application != ""),
		Budget:         null.JSONFrom(budgetJSON),
		MetaData:       null.JSONFrom(metaDataJSON),
		ProjectFileURL: null.NewString(project.ProjectFileURL, project.ProjectFileURL != ""),
	}

	err = row.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to insert project: %v", err)
	}
	return nil
}

func (s *Service) GetByID(ctx context.Context, id string) (*fusion.Project, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}
	row, err := model.Projects(model.ProjectWhere.ID.EQ(id)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, fmt.Errorf("project not found: %v", id)
		}
		return nil, fmt.Errorf("failed to get project by id: %v", err)
	}
	project, err := newProject(row)
	if err != nil {
		return nil, fmt.Errorf("failed to convert project: %v", err)
	}
	return project, nil
}

func (s *Service) GetAll(ctx context.Context) ([]*fusion.Project, error) {
	// Retrieve all projects from the database.

	var q []qm.QueryMod

	// Get the rows by running the query.
	rows, err := model.Projects(q...).All(ctx, s.db)
	if err != nil {
		return nil, fmt.Errorf("can't get rows: %v", err)
	}

	projects := make([]*fusion.Project, 0, len(rows))
	for _, row := range rows {
		project, err := newProject(row)
		if err != nil {
			return nil, fmt.Errorf("can't parse row: %v", err)
		}
		projects = append(projects, project)
	}

	return projects, nil
}

func (s *Service) Update(ctx context.Context, id string, project *fusion.Project) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	if project == nil {
		return errors.New("project cannot be nil")
	}

	row, err := model.Projects(model.ProjectWhere.ID.EQ(id)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return fmt.Errorf("project not found: %v", id)
		}
		return fmt.Errorf("failed to get project by id: %v", err)
	}

	budgetJSON, err := json.Marshal(project.Budget)
	if err != nil {
		return fmt.Errorf("failed to marshal budget: %v", err)
	}
	metaDataJSON, err := json.Marshal(project.MetaData)
	if err != nil {
		return fmt.Errorf("failed to marshal meta_data: %v", err)
	}

	row.OrganizationID = project.OrganizationID
	row.Name = project.Name
	row.Description = null.NewString(project.Description, project.Description != "")
	row.Venue = null.NewString(project.Venue, project.Venue != "")
	row.VenueType = null.NewString(project.VenueType, project.VenueType != "")
	row.Application = null.NewString(project.Application, project.Application != "")
	row.Budget = null.JSONFrom(budgetJSON)
	row.MetaData = null.JSONFrom(metaDataJSON)
	row.ProjectFileURL = null.NewString(project.ProjectFileURL, project.ProjectFileURL != "")

	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to update project: %v", err)
	}
	return nil
}

func (s *Service) Delete(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	row, err := model.Projects(model.ProjectWhere.ID.EQ(id)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return fmt.Errorf("project not found: %v", id)
		}
		return fmt.Errorf("failed to get project by id: %v", err)
	}
	_, err = row.Delete(ctx, s.db)
	if err != nil {
		return fmt.Errorf("failed to delete project: %v", err)
	}
	return nil
}

func (s *Service) SyncProject(ctx context.Context, projectID string, metaData map[string]interface{}, zipFileURL string) error {
	if projectID == "" {
		return errors.New("projectID cannot be empty")
	}
	row, err := model.Projects(model.ProjectWhere.ID.EQ(projectID)).One(ctx, s.db)
	if err != nil {
		return fmt.Errorf("failed to get project: %v", err)
	}

	// Placeholder: Upload zipFileURL to AWS S3 and get the file URL
	// TODO: Implement actual S3 upload logic here
	// For now, use the provided zipFileURL as the S3 URL

	row.ProjectFileURL = null.NewString(zipFileURL, zipFileURL != "")
	metaDataJSON, err := json.Marshal(metaData)
	if err != nil {
		return fmt.Errorf("failed to marshal meta_data: %v", err)
	}
	row.MetaData = null.JSONFrom(metaDataJSON)
	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to update ProjectFileURL: %v", err)
	}
	return nil
}
