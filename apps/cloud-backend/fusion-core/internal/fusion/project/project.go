package project

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
)

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *fusion.Project) error {
	err := s.dbService.Insert(ctx, project)
	if err != nil {
		return fmt.Errorf("failed to insert project: %v", err)
	}
	return nil
}

// GetProjectByID retrieves a project by its ID.
func (s *Service) GetProjectByID(ctx context.Context, id string) (*fusion.Project, error) {
	return s.dbService.SelectByID(ctx, id)
}

// GetAllProjects retrieves all projects.
func (s *Service) GetAllProjects(ctx context.Context) ([]*fusion.Project, error) {
	return s.dbService.SelectAll(ctx)
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, id string, project *fusion.Project) error {
	return s.dbService.Update(ctx, id, project)
}

// DeleteProject removes a project by its ID.
func (s *Service) DeleteProject(ctx context.Context, id string) error {
	return s.dbService.Delete(ctx, id)
}

// SyncProject synchronizes project data across different systems.
func (s *Service) SyncProject(ctx context.Context, projectID string, metaData map[string]interface{}, zipFileURL string) error {
	return s.dbService.SyncProject(ctx, projectID, metaData, zipFileURL)
}
