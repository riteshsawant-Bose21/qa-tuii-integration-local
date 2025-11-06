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

const (
	projectFilePathFormat = "projects/%s/%s/%s.zip"
)

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *types.ProjectCreateRequest) (*types.ProjectCreateResponse, error) {
	id, err := s.dbService.Insert(ctx, project)

	if err != nil {
		return nil, fmt.Errorf("failed to insert project: %v", err)
	}

	response := &types.ProjectCreateResponse{
		ID: id,
	}

	if project.IsProjectFileCreated {
		// Generate presigned URL for project file upload
		presignURL, err := s.presigner.PresignPut(
			ctx,
			fmt.Sprintf(projectFilePathFormat, project.UserID, id, id),
			time.Minute*15,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ProjectUploadURL = presignURL
	}

	return response, nil
}

// GetAllProjects retrieves all projects.
func (s *Service) GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams) (*types.GetAllProjectsResponse, error) {
	projects, err := s.dbService.SelectAll(ctx, queryParams)

	if err != nil {
		return nil, err
	}

	for _, project := range projects {

		presignURL, err := s.presigner.PresignGet(
			ctx,
			fmt.Sprintf(projectFilePathFormat, queryParams.UserID, project.ID, project.ID), time.Minute*5,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL for project %s: %v", project.ID, err)
		}
		project.ProjectFileURL = presignURL
	}

	// Convert []*types.Project to []types.Project for the response
	projectList := make([]types.Project, len(projects))
	for i, project := range projects {
		projectList[i] = *project
	}

	// Create response with pagination info (for now using basic values)
	response := &types.GetAllProjectsResponse{
		Data:       projectList,
		TotalCount: len(projectList),
		Page:       1,
		TotalPages: 1,
	}

	return response, nil
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*types.ProjectUpdateResponse, error) {
	projectRow, err := s.dbService.Update(ctx, id, project)
	if err != nil {
		return nil, fmt.Errorf("failed to update project: %v", err)
	}

	response := &types.ProjectUpdateResponse{}

	if project.IsProjectFileDirty {
		presignURL, err := s.presigner.PresignPut(
			ctx,
			fmt.Sprintf(projectFilePathFormat, projectRow.PrimaryOwnerUserID.String, projectRow.ID, projectRow.ID),
			time.Minute*15,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ProjectUploadURL = presignURL
	}
	return response, nil
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

// AssignUserToProject assigns a user to a project.
func (s *Service) AssignUserToProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error) {
	// Check if project exists
	projectExists, err := s.dbService.ProjectExists(ctx, projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to check if project exists: %v", err)
	}
	if !projectExists {
		return nil, fmt.Errorf("project not found")
	}

	// Check if user exists
	userExists, err := s.dbService.UserExists(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check if user exists: %v", err)
	}
	if !userExists {
		return nil, fmt.Errorf("user not found")
	}

	// Check if user is already assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check user assignment: %v", err)
	}
	if isAssigned {
		return nil, fmt.Errorf("user is already assigned to the project")
	}

	// Assign the user to the project
	if err := s.dbService.AssignUser(ctx, projectID, userID); err != nil {
		return nil, fmt.Errorf("failed to assign user to project: %v", err)
	}

	return &types.UserAssignmentResponse{
		Message: "User successfully assigned to the project",
	}, nil
}

// RemoveUserFromProject removes a user from a project.
func (s *Service) RemoveUserFromProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error) {
	// Check if project exists
	projectExists, err := s.dbService.ProjectExists(ctx, projectID)
	if err != nil {
		return nil, fmt.Errorf("failed to check if project exists: %v", err)
	}
	if !projectExists {
		return nil, fmt.Errorf("project not found")
	}

	// Check if user exists
	userExists, err := s.dbService.UserExists(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check if user exists: %v", err)
	}
	if !userExists {
		return nil, fmt.Errorf("user not found")
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check user assignment: %v", err)
	}
	if !isAssigned {
		return nil, fmt.Errorf("user not assigned to the project")
	}

	// Remove the user from the project
	if err := s.dbService.RemoveUser(ctx, projectID, userID); err != nil {
		return nil, fmt.Errorf("failed to remove user from project: %v", err)
	}

	return &types.UserAssignmentResponse{
		Message: "User successfully removed from the project",
	}, nil
}

// AssignUserToProjectByEmail assigns a user to a project by email.
func (s *Service) AssignUserToProjectByEmail(ctx context.Context, projectID, userEmail string) (*types.UserAssignmentResponse, error) {
	// Get user ID by email
	userID, err := s.dbService.GetUserIDByEmail(ctx, userEmail)
	if err != nil {
		return nil, err // This will return "user not found" from the database service
	}

	// Use the existing AssignUserToProject method
	return s.AssignUserToProject(ctx, projectID, userID)
}

// RemoveUserFromProjectByEmail removes a user from a project by email.
func (s *Service) RemoveUserFromProjectByEmail(ctx context.Context, projectID, userEmail string) (*types.UserAssignmentResponse, error) {
	// Get user ID by email
	userID, err := s.dbService.GetUserIDByEmail(ctx, userEmail)
	if err != nil {
		return nil, err // This will return "user not found" from the database service
	}

	// Use the existing RemoveUserFromProject method
	return s.RemoveUserFromProject(ctx, projectID, userID)
}
