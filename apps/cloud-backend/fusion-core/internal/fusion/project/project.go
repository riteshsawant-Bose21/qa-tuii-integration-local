package project

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
)

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *fusion.ProjectCreateRequest) error {
	err := s.dbService.Insert(ctx, project)
	if err != nil {
		return err
	}
	if !userExists {
		return errors.New(types.ErrMsgUserNotFound)
	}
	return nil
}

// GetAllProjects retrieves all projects.
func (s *Service) GetAllProjects(ctx context.Context, queryParams *fusion.GetAllProjectsParams) ([]*fusion.Project, error) {
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
func (s *Service) UpdateProject(ctx context.Context, id string, project *fusion.ProjectUpdateRequest) error {
	return s.dbService.Update(ctx, id, project)
}

// DeleteProject removes a project by its ID.
// Note: This method should be called with userID for validation when invoked from handlers
func (s *Service) DeleteProject(ctx context.Context, projectID, userID string) error {

	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              false,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: true,
	}

	projectRow, err := s.validateProject(ctx, projectID, opts)

	if err != nil {
		return err
	}

	if projectRow.IsDeleted {
		return nil // Idempotent behavior
	}

	return s.dbService.Delete(ctx, projectRow)
}
