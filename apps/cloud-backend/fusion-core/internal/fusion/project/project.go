package project

import (
	"context"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
)

const (
	projectFilePathFormat = "projects/%s/%s/%s.zip"
)

// validateProjectExistence is a helper function to validate that a project exists
func (s *Service) validateProjectExistence(ctx context.Context, projectID string) error {
	projectExists, err := s.dbService.ProjectExists(ctx, projectID)
	if err != nil {
		return err
	}
	if !projectExists {
		return fmt.Errorf("project not found")
	}
	return nil
}

// validateProjectAndUserExistence is a helper function to validate that both project and user exist
func (s *Service) validateProjectAndUserExistence(ctx context.Context, projectID, userID string) error {
	// Check if project exists
	if err := s.validateProjectExistence(ctx, projectID); err != nil {
		return err
	}

	// Check if user exists
	userExists, err := s.dbService.UserExists(ctx, userID)
	if err != nil {
		return err
	}
	if !userExists {
		return fmt.Errorf("user not found")
	}

	return nil
}

// generateProjectFileURL generates a presigned URL for project file operations
func (s *Service) generateProjectFileURL(ctx context.Context, userID, projectID string, ttl time.Duration, operation string) (string, error) {
	key := fmt.Sprintf(projectFilePathFormat, userID, projectID, projectID)

	switch operation {
	case "get":
		return s.presigner.PresignGet(ctx, key, ttl)
	case "put":
		return s.presigner.PresignPut(ctx, key, ttl)
	default:
		return "", fmt.Errorf("unsupported operation: %s", operation)
	}
}

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
		presignURL, err := s.generateProjectFileURL(ctx, project.UserID, id, time.Minute*15, "put")
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

	// Generate presigned URLs for all projects
	for _, project := range projects {
		presignURL, err := s.generateProjectFileURL(ctx, queryParams.UserID, project.ID, time.Minute*5, "get")
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

	return &types.GetAllProjectsResponse{
		Data:       projectList,
		TotalCount: len(projectList),
		Page:       1,
		TotalPages: 1,
	}, nil
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*types.ProjectUpdateResponse, error) {
	projectRow, err := s.dbService.Update(ctx, id, project)
	if err != nil {
		return nil, fmt.Errorf("failed to update project: %v", err)
	}

	response := &types.ProjectUpdateResponse{}

	if project.IsProjectFileDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.PrimaryOwnerUserID.String, projectRow.ID, time.Minute*15, "put")
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ProjectUploadURL = presignURL
	}

	return response, nil
}

func (s *Service) Delete(ctx context.Context, id string) error {
	return s.dbService.Delete(ctx, id)
}

// AssignUserToProject assigns a user to a project.
func (s *Service) AssignUserToProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error) {
	// Validate project and user existence
	if err := s.validateProjectAndUserExistence(ctx, projectID, userID); err != nil {
		return nil, err
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
	// Validate project and user existence
	if err := s.validateProjectAndUserExistence(ctx, projectID, userID); err != nil {
		return nil, err
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

// StarProject stars a project for a user.
func (s *Service) StarProject(ctx context.Context, projectID, userID string) error {
	// Validate project and user existence
	if err := s.validateProjectAndUserExistence(ctx, projectID, userID); err != nil {
		return err
	}

	// Star the project
	if err := s.dbService.StarProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// UnstarProject unstars a project for a user.
func (s *Service) UnstarProject(ctx context.Context, projectID, userID string) error {
	// Validate project and user existence
	if err := s.validateProjectAndUserExistence(ctx, projectID, userID); err != nil {
		return err
	}

	// Unstar the project
	if err := s.dbService.UnstarProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// ArchiveProject archives a project.
func (s *Service) ArchiveProject(ctx context.Context, projectID string) error {
	// Validate project existence
	if err := s.validateProjectExistence(ctx, projectID); err != nil {
		return err
	}

	// Archive the project
	if err := s.dbService.ArchiveProject(ctx, projectID); err != nil {
		return err
	}

	return nil
}

// UnarchiveProject unarchives a project.
func (s *Service) UnarchiveProject(ctx context.Context, projectID string) error {
	// Validate project existence
	if err := s.validateProjectExistence(ctx, projectID); err != nil {
		return err
	}

	// Unarchive the project
	if err := s.dbService.UnarchiveProject(ctx, projectID); err != nil {
		return err
	}

	return nil
}

// ProjectExists checks if a project exists.
func (s *Service) ProjectExists(ctx context.Context, projectID string) (bool, error) {
	return s.dbService.ProjectExists(ctx, projectID)
}

// IsUserAssigned checks if a user is assigned to a project.
func (s *Service) IsUserAssigned(ctx context.Context, projectID, userID string) (bool, error) {
	return s.dbService.IsUserAssigned(ctx, projectID, userID)
}
