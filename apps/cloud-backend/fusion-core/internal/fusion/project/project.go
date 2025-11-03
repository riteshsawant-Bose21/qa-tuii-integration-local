package project

import (
	"context"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *types.ProjectCreateRequest) error {
	err := s.dbService.Insert(ctx, project)
	if err != nil {
		return fmt.Errorf("failed to insert project: %v", err)
	}
	return nil
}

// GetAllProjects retrieves all projects.
func (s *Service) GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams) ([]*types.Project, error) {
	projects, err := s.dbService.SelectAll(ctx, queryParams)

	if err != nil {
		return nil, err
	}

	for _, project := range projects {

		presignURL, err := s.presigner.PresignGet(
			ctx,
			fmt.Sprintf("projects/%s/%s/", project.AccountID, project.ID), time.Minute*5,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL for project %s: %v", project.ID, err)
		}
		project.ProjectFileURL = presignURL
	}

	return projects, nil
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, id string, project *types.ProjectUpdateRequest) error {
	return s.dbService.Update(ctx, id, project)
}

func (s *Service) Delete(ctx context.Context, id string) error {
	return s.dbService.Delete(ctx, id)
}
