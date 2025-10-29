package project

import (
	"context"
	"fmt"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *types.Project) error {
	err := s.dbService.Insert(ctx, project)
	if err != nil {
		return fmt.Errorf("failed to insert project: %v", err)
	}
	return nil
}

// GetProjectByID retrieves a project by its ID.
func (s *Service) GetProjectByID(ctx context.Context, id string) (*types.Project, error) {
	return s.dbService.SelectByID(ctx, id)
}

// GetAllProjects retrieves all projects.
func (s *Service) GetAllProjects(ctx context.Context) ([]*types.Project, error) {
	return s.dbService.SelectAll(ctx)
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, id string, project *types.Project) error {
	return s.dbService.Update(ctx, id, project)
}

func (s *Service) Delete(ctx context.Context, id string) error {
	return s.dbService.Delete(ctx, id)
}

func (s *Service) SyncProject(ctx context.Context, projectID string, metaData map[string]interface{}, zipFileURL string) error {
	return s.dbService.SyncProject(ctx, projectID, metaData, zipFileURL)
}
