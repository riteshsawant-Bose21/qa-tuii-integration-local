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
	projectFilePathFormat  = "projects/%s/%s.zip"
	errorWithDetailsFormat = "%s: %v"
)

// validateProjectExistence is a helper function to validate that a project exists
func (s *Service) validateProjectExistence(ctx context.Context, projectID string) error {
	projectExists, err := s.dbService.ProjectExists(ctx, projectID)
	if err != nil {
		return err
	}
	if !projectExists {
		return errors.New(types.ErrMsgProjectNotFound)
	}
	return nil
}

// validateUserExistence is a helper function to validate that a user exists
func (s *Service) validateUserExistence(ctx context.Context, userID string) error {
	userExists, err := s.dbService.UserExists(ctx, userID)
	if err != nil {
		return err
	}
	if !userExists {
		return errors.New(types.ErrMsgUserNotFound)
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
	if err := s.validateUserExistence(ctx, userID); err != nil {
		return err
	}

	return nil
}

// validateUserAssignedToProject validates that a user is assigned to a project
func (s *Service) validateUserAssignedToProject(ctx context.Context, projectID, userID string) error {
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}
	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}
	return nil
}

// validateProjectAndUserAndAssignment validates project existence, user existence, and user assignment
func (s *Service) validateProjectAndUserAndAssignment(ctx context.Context, projectID, userID string) error {
	// Validate project and user existence
	if err := s.validateProjectAndUserExistence(ctx, projectID, userID); err != nil {
		return err
	}

	// Validate user assignment to project
	if err := s.validateUserAssignedToProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// validateProjectUpdateAuthorization validates user can update/delete project (existence, assignment, and not locked by other)
func (s *Service) validateProjectUpdateAuthorization(ctx context.Context, projectID, userID string) error {
	// Validate project, user existence and assignment
	if err := s.validateProjectAndUserAndAssignment(ctx, projectID, userID); err != nil {
		return err
	}

	// Check if project is locked by another user
	if err := s.ValidateProjectNotLockedByOther(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// ValidateProjectNotLockedByOther validates that a project is not locked by another user.
// Returns an error with the locking user's email if the project is locked by someone else.
func (s *Service) ValidateProjectNotLockedByOther(ctx context.Context, projectID, userID string) error {
	isLocked, lockedByUserID, err := s.dbService.GetProjectLockUserID(ctx, projectID)
	if err != nil {
		return err
	}

	if !isLocked {
		return nil // Project is not locked, operation can proceed
	}

	// Check if the project is locked by the same user trying to perform the operation
	if lockedByUserID == userID {
		return nil // Project is locked by the same user, operation can proceed
	}

	// Get the email of the user who locked the project
	lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, lockedByUserID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
	}

	// Project is locked by a different user
	return fmt.Errorf("project is locked by user: %s", lockedByEmail)
}

func (s *Service) GetValidProjectForUpdate(ctx context.Context, projectID, userID string) (*models.Project, error) {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return nil, err
	}

	if projectRow.IsArchived {
		return nil, errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return nil, errors.New(types.ErrMsgProjectNotFound)
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return nil, fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return nil, errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	return projectRow, nil
}

// generateProjectFileURL generates a presigned URL for project file operations
func (s *Service) generateProjectFileURL(ctx context.Context, projectID string, ttl time.Duration, operation string) (string, error) {
	key := fmt.Sprintf(projectFilePathFormat, projectID, projectID)

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
	// Validate user existence
	if err := s.validateUserExistence(ctx, project.UserID); err != nil {
		return nil, err
	}

	// Generate ID
	project.ID = uuid.New().String()

	id, err := s.dbService.Insert(ctx, project)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToInsertProject, err)
	}

	response := &types.ProjectCreateResponse{
		ID: id,
	}

	if project.IsProjectFileCreated {
		presignURL, err := s.generateProjectFileURL(ctx, id, time.Minute*15, "put")
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
		presignURL, err := s.generateProjectFileURL(ctx, project.ID, time.Minute*5, "get")
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
func (s *Service) UpdateProject(ctx context.Context, projectID, userID string, project *types.ProjectUpdateRequest) (*types.ProjectUpdateResponse, error) {

	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return nil, err
	}

	if projectRow.IsArchived {
		return nil, errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return nil, errors.New(types.ErrMsgProjectNotFound)
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return nil, fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return nil, errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	err = s.dbService.Update(ctx, projectRow, project)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToUpdateProject, err)
	}

	response := &types.ProjectUpdateResponse{}

	if project.IsProjectFileDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.ID, time.Minute*15, "put")
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
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return err
	}

	if projectRow.IsDeleted {
		return nil // Idempotent behavior
	}

	if projectRow.IsArchived {
		return errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	return s.dbService.Delete(ctx, projectRow)
}

// AssignUserToProject assigns a user to a project.
func (s *Service) AssignUserToProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error) {

	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return nil, err
	}

	if projectRow.IsArchived {
		return nil, errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return nil, errors.New(types.ErrMsgProjectNotFound)
	}

	// Check if user is already assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if isAssigned {
		return &types.UserAssignmentResponse{
			Message: "User successfully assigned to the project",
		}, nil
	}

	// Assign the user to the project
	if err := s.dbService.AssignUser(ctx, projectID, userID); err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToAssignUser, err)
	}

	return &types.UserAssignmentResponse{
		Message: "User successfully assigned to the project",
	}, nil
}

// RemoveUserFromProject removes a user from a project.
func (s *Service) RemoveUserFromProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error) {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return nil, err
	}

	if projectRow.IsArchived {
		return nil, errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return nil, errors.New(types.ErrMsgProjectNotFound)
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return nil, fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}
	if !isAssigned {
		return &types.UserAssignmentResponse{
			Message: "User successfully removed from the project",
		}, nil
	}

	// Remove the user from the project
	if err := s.dbService.RemoveUser(ctx, projectID, userID); err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToRemoveUser, err)
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
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return err
	}

	if projectRow.IsArchived {
		return errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return errors.New(types.ErrMsgProjectNotFound)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	// Star the project
	if err := s.dbService.StarProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// UnstarProject unstars a project for a user.
func (s *Service) UnstarProject(ctx context.Context, projectID, userID string) error {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return err
	}

	if projectRow.IsArchived {
		return errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return errors.New(types.ErrMsgProjectNotFound)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	// Unstar the project
	if err := s.dbService.UnstarProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// ArchiveProject archives a project.
func (s *Service) ArchiveProject(ctx context.Context, projectID, userID string) error {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return err
	}

	if projectRow.IsDeleted {
		return errors.New(types.ErrMsgProjectNotFound)
	}

	if projectRow.IsArchived {
		return nil // Idempotent behavior
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}

	// Archive the project
	if err := s.dbService.ArchiveProject(ctx, projectID); err != nil {
		return err
	}

	return nil
}

// UnarchiveProject unarchives a project.
func (s *Service) UnarchiveProject(ctx context.Context, projectID, userID string) error {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return err
	}

	if projectRow.IsDeleted {
		return errors.New(types.ErrMsgProjectNotFound)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	if !projectRow.IsArchived {
		return nil // Idempotent behavior
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return fmt.Errorf("project is locked by user: %s", lockedByEmail)
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

// LockProject locks a project for a user.
func (s *Service) LockProject(ctx context.Context, projectID, userID string) error {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return err
	}

	if projectRow.IsArchived {
		return errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return errors.New(types.ErrMsgProjectNotFound)
	}

	if projectRow.LockedByUserID.String != "" {
		if projectRow.LockedByUserID.String != userID {
			lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
			if err != nil {
				return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
			}
			return fmt.Errorf("project is locked by user: %s", lockedByEmail)

		} else {
			return nil // Project is already locked by the same user, idempotent behavior
		}
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	// Lock the project
	if err := s.dbService.LockProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// UnlockProject unlocks a project for a user.
func (s *Service) UnlockProject(ctx context.Context, projectID, userID string) error {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)

	if err != nil {
		return err
	}

	if projectRow.IsArchived {
		return errors.New(types.ErrMsgProjectArchived)
	}

	if projectRow.IsDeleted {
		return errors.New(types.ErrMsgProjectNotFound)
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}

	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	// Unlock the project
	if err := s.dbService.UnlockProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// GetProjectLockUserID returns whether the project is locked and the user ID who locked it.
func (s *Service) GetProjectLockUserID(ctx context.Context, projectID string) (isLocked bool, lockedByUserID string, err error) {
	return s.dbService.GetProjectLockUserID(ctx, projectID)
}

// GetUserEmailByID returns the email address for a given user ID.
func (s *Service) GetUserEmailByID(ctx context.Context, userID string) (string, error) {
	return s.dbService.GetUserEmailByID(ctx, userID)
}

// GetProjectLockInfo returns project lock information.
func (s *Service) GetProjectLockInfo(ctx context.Context, projectID string) (isLocked bool, lockedByEmail string, err error) {
	isLocked, lockedByUserID, err := s.dbService.GetProjectLockUserID(ctx, projectID)
	if err != nil {
		return false, "", err
	}

	if !isLocked {
		return false, "", nil
	}

	// Get the email of the user who locked the project
	lockedByEmail, err = s.dbService.GetUserEmailByID(ctx, lockedByUserID)
	if err != nil {
		return true, "", err
	}

	return true, lockedByEmail, nil
}
