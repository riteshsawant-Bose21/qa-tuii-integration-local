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
	projectFilePathFormat  = "projects/%s/%s/%s.zip"
	errorWithDetailsFormat = "%s: %v"
)

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

// generateProjectFileURL generates a presigned URL for project file operations
func (s *Service) generateProjectFileURL(ctx context.Context, projectID string, fileType types.ProjectFileType, ttl time.Duration, operation string) (string, error) {
	key := fmt.Sprintf(projectFilePathFormat, projectID, fileType, projectID)

	switch operation {
	case "get":
		return s.presigner.PresignGet(ctx, key, ttl)
	case "put":
		return s.presigner.PresignPut(ctx, key, ttl)
	default:
		return "", fmt.Errorf("unsupported operation: %s", operation)
	}
}

// ValidationOptions defines what validations to perform
type ValidationOptions struct {
	CheckDeleted              bool
	CheckArchived             bool
	CheckUserAssigned         bool
	CheckNotLockedByOtherUser bool
	UserID                    string
}

// validateProject performs common project validations
func (s *Service) validateProject(ctx context.Context, projectID string, opts ValidationOptions) (*models.Project, error) {
	projectRow, err := s.dbService.GetProjectByID(ctx, projectID)
	if err != nil {
		return nil, err
	}

	if opts.CheckDeleted && projectRow.IsDeleted {
		return nil, errors.New(types.ErrMsgProjectNotFound)
	}

	if opts.CheckArchived && projectRow.IsArchived {
		return nil, errors.New(types.ErrMsgProjectArchived)
	}

	if opts.CheckUserAssigned {
		if err := s.validateUserAssignment(ctx, projectID, opts.UserID); err != nil {
			return nil, err
		}
	}

	if opts.CheckNotLockedByOtherUser {
		if err := s.validateProjectNotLockedByOtherUser(ctx, projectRow, opts.UserID); err != nil {
			return nil, err
		}
	}

	return projectRow, nil
}

// validateUserAssignment checks if user is assigned to project
func (s *Service) validateUserAssignment(ctx context.Context, projectID, userID string) error {
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedUserAssignmentCheck, err)
	}
	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}
	return nil
}

// validateProjectNotLockedByOtherUser checks if project is not locked by another user
func (s *Service) validateProjectNotLockedByOtherUser(ctx context.Context, projectRow *models.Project, userID string) error {
	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToGetUserByEmail, err)
		}
		return fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}
	return nil
}

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *types.ProjectCreateRequest) (*types.ProjectCreateResponse, error) {
	// Validate user existence
	if err := s.validateUserExistence(ctx, project.UserID); err != nil {
		return nil, err
	}

	// Generate ID
	project.ID = uuid.New().String()

	db := s.dbService.GetDB(ctx)

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %v", err)
	}

	id, err := s.dbService.Insert(ctx, project, tx)
	if err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToInsertProject, err)
		}

		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToInsertProject, err)
	}

	// Assign user to project
	if err := s.dbService.InsertProjectUser(ctx, id, project.UserID, tx); err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToInsertProject, err)
		}
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToInsertProject, err)
	}

	if err := tx.Commit(); err != nil {
		return nil, errors.New(types.ErrMsgFailedToInsertProject)
	}

	response := &types.ProjectCreateResponse{
		ID: id,
	}

	if project.IsProjectFileCreated {
		presignURL, err := s.generateProjectFileURL(ctx, id, types.ProjectFileTypeProjectFile, time.Minute*15, "put")
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ProjectUploadURL = &presignURL
	}

	if project.IsProjectThumbnailCreated {
		presignURL, err := s.generateProjectFileURL(ctx, id, types.ProjectFileTypeProjectThumbnail, time.Minute*15, "put")
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ThumbnailUploadURL = &presignURL
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
	for i := range projects {
		presignURL, err := s.generateProjectFileURL(ctx, projects[i].ID, types.ProjectFileTypeProjectFile, time.Minute*5, "get")
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL for project %s: %v", projects[i].ID, err)
		}
		projects[i].ProjectFileURL = presignURL

		thumbnailURL, err := s.generateProjectFileURL(ctx, projects[i].ID, types.ProjectFileTypeProjectThumbnail, time.Minute*5, "get")
		if err != nil {
			return nil, fmt.Errorf("failed to generate thumbnail URL for project %s: %v", projects[i].ID, err)
		}
		projects[i].ThumbnailURL = thumbnailURL
	}

	return &types.GetAllProjectsResponse{
		Data:       projects,
		TotalCount: len(projects),
		Page:       1,
		TotalPages: 1,
	}, nil
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, projectID, userID string, project *types.ProjectUpdateRequest) (*types.ProjectUpdateResponse, error) {

	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: true,
	}

	projectRow, err := s.validateProject(ctx, projectID, opts)
	if err != nil {
		return nil, err
	}

	err = s.dbService.Update(ctx, projectRow, project)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, types.ErrMsgFailedToUpdateProject, err)
	}

	response := &types.ProjectUpdateResponse{}

	if project.IsProjectFileDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.ID, types.ProjectFileTypeProjectFile, time.Minute*15, "put")
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ProjectUploadURL = &presignURL
	}

	if project.IsProjectThumbnailDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.ID, types.ProjectFileTypeProjectThumbnail, time.Minute*15, "put")
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ThumbnailUploadURL = &presignURL
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

	opts := ValidationOptions{
		CheckUserAssigned:         false,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	_, err := s.validateProject(ctx, projectID, opts)

	if err != nil {
		return nil, err
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

	opts := ValidationOptions{
		CheckUserAssigned:         false,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	projectRow, err = s.validateProject(ctx, projectID, opts)
	if err != nil {
		return nil, err
	}

	if projectRow.LockedByUserID.String != "" && projectRow.LockedByUserID.String == userID {
		// Unlock the project
		if err := s.dbService.UnlockProject(ctx, projectID, userID); err != nil {
			return nil, err
		}
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

	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	_, err := s.validateProject(ctx, projectID, opts)

	if err != nil {
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
	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	_, err := s.validateProject(ctx, projectID, opts)
	if err != nil {
		return err
	}

	// Unstar the project
	if err := s.dbService.UnstarProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// ArchiveProject archives a project.
func (s *Service) ArchiveProject(ctx context.Context, projectID, userID string) error {
	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             false,
		CheckNotLockedByOtherUser: true,
	}

	projectRow, err := s.validateProject(ctx, projectID, opts)
	if err != nil {
		return err
	}

	if projectRow.IsArchived {
		return nil // Idempotent behavior
	}

	// Archive the project
	if err := s.dbService.ArchiveProject(ctx, projectID); err != nil {
		return err
	}

	return nil
}

// UnarchiveProject unarchives a project.
func (s *Service) UnarchiveProject(ctx context.Context, projectID, userID string) error {
	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             false,
		CheckNotLockedByOtherUser: true,
	}

	projectRow, err := s.validateProject(ctx, projectID, opts)
	if err != nil {
		return err
	}

	if !projectRow.IsArchived {
		return nil // Idempotent behavior
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

	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: true,
	}

	projectRow, err := s.validateProject(ctx, projectID, opts)
	if err != nil {
		return err
	}

	if projectRow.LockedByUserID.String != "" {
		return nil // Project is already locked by the same user, idempotent behavior
	}

	// Lock the project
	if err := s.dbService.LockProject(ctx, projectID, userID); err != nil {
		return err
	}

	return nil
}

// UnlockProject unlocks a project for a user.
func (s *Service) UnlockProject(ctx context.Context, projectID, userID string) error {
	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: true,
	}

	projectRow, err := s.validateProject(ctx, projectID, opts)
	if err != nil {
		return err
	}

	if projectRow.LockedByUserID.String == "" {
		return nil // Project is already unlocked, idempotent behavior
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
