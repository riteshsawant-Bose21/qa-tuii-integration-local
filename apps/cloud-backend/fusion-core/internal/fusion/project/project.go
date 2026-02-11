// Package project provides project management functionality.
package project

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	errorutils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"go.uber.org/zap"
)

const (
	projectFilePathFormat  = "projects/%s/%s/%s.zip"
	errorWithDetailsFormat = "%s: %v"
)

// generateProjectFileURL generates a presigned URL for project file operations
func (s *Service) generateProjectFileURL(ctx context.Context, projectID string, fileType types.ProjectFileType, ttl time.Duration, operation string, logger *zap.Logger) (string, error) {
	// If no presigner is configured (e.g., in tests), return empty string
	if s.presigner == nil {
		return "", nil
	}

	key := fmt.Sprintf(projectFilePathFormat, projectID, fileType, projectID)

	switch operation {
	case "get":
		return s.presigner.PresignGet(ctx, key, ttl, logger)
	case "put":
		return s.presigner.PresignPut(ctx, key, ttl, logger)
	default:
		return "", fmt.Errorf("unsupported operation: %s", operation)
	}
}

// ValidationOptions defines what validations to perform
type ValidationOptions struct {
	CheckDeleted              bool
	CheckArchived             bool
	CheckUserAssigned         bool
	CheckPrimaryOwner         bool
	CheckNotLockedByOtherUser bool
	UserID                    string
	AccountID                 string
}

// validateProject performs common project validations
func (s *Service) validateProject(ctx context.Context, projectID string, opts ValidationOptions, logger *zap.Logger) (*models.Project, error) {

	projectRow, err := s.dbService.GetProjectByID(ctx, projectID, logger)
	if err != nil {
		return nil, err
	}

	if opts.CheckDeleted && projectRow.IsDeleted {
		return nil, errors.New(errorutils.ErrMsgProjectNotFound)
	}

	if opts.CheckArchived && projectRow.IsArchived {
		return nil, errors.New(errorutils.ErrMsgProjectArchived)
	}

	if opts.CheckUserAssigned {
		if err := s.validateUserAssignment(ctx, projectID, opts.UserID, logger); err != nil {
			return nil, err
		}
	}

	if opts.CheckPrimaryOwner {
		if err := s.validatePrimaryOwner(projectRow, opts.AccountID); err != nil {
			return nil, err
		}
	}

	if opts.CheckNotLockedByOtherUser {
		if err := s.validateProjectNotLockedByOtherUser(ctx, projectRow, opts.UserID, logger); err != nil {
			return nil, err
		}
	}

	return projectRow, nil
}

// validateUserAssignment checks if user is assigned to project
func (s *Service) validateUserAssignment(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
	if err != nil {
		return fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedUserAssignmentCheck, err)
	}
	if !isAssigned {
		return errors.New(errorutils.ErrMsgUserNotAssignedToProject)
	}
	return nil
}

// validateProjectNotLockedByOtherUser checks if project is not locked by another user
func (s *Service) validateProjectNotLockedByOtherUser(ctx context.Context, projectRow *models.Project, userID string, logger *zap.Logger) error {
	if projectRow.LockedByUserID.Valid && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			logger.Error("failed to get user by email", zap.Error(err))
			return fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToGetUserByEmail, err)
		}
		return fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}
	return nil
}

// validatePrimaryOwner checks if user org account is the primary owner of the project
func (s *Service) validatePrimaryOwner(projectRow *models.Project, accountID string) error {

	if projectRow.PrimaryOwnerAccountID != accountID {
		return errors.New(errorutils.ErrMsgForbidden)
	}
	return nil
}

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *types.ProjectCreateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectCreateResponse, error) {

	projectRow, err := s.dbService.GetProjectByID(ctx, project.ID, logger)

	if err == nil && projectRow != nil {
		return nil, errors.New(errorutils.ErrMsgProjectAlreadyExists)
	}

	db := s.dbService.GetDB(ctx)

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %v", err)
	}

	id, err := s.dbService.Insert(ctx, project, userAuth.Account.ID, tx, logger)
	if err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToInsertProject, err)
		}

		return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToInsertProject, err)
	}

	// Assign user to project
	if err := s.dbService.InsertProjectUser(ctx, id, userAuth.User.ID, tx, logger); err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToInsertProject, err)
		}
		return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToInsertProject, err)
	}

	if err := tx.Commit(); err != nil {
		return nil, errors.New(errorutils.ErrMsgFailedToInsertProject)
	}

	response := &types.ProjectCreateResponse{
		ID: id,
	}

	if project.IsProjectFileCreated {
		presignURL, err := s.generateProjectFileURL(ctx, id, types.ProjectFileTypeProjectFile, time.Minute*15, "put", logger)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ProjectUploadURL = &presignURL
	}

	if project.IsProjectThumbnailCreated {
		presignURL, err := s.generateProjectFileURL(ctx, id, types.ProjectFileTypeProjectThumbnail, time.Minute*15, "put", logger)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ThumbnailUploadURL = &presignURL
	}

	return response, nil
}

// GetAllProjects retrieves all projects.
func (s *Service) GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.GetAllProjectsResponse, error) {
	projects, err := s.dbService.SelectAll(ctx, queryParams, userAuth, logger)
	if err != nil {
		return nil, err
	}

	// Generate presigned URLs for all projects
	for i := range projects {
		presignURL, err := s.generateProjectFileURL(ctx, projects[i].ID, types.ProjectFileTypeProjectFile, time.Minute*5, "get", logger)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL for project %s: %v", projects[i].ID, err)
		}

		if presignURL != "" {
			projects[i].ProjectFileURL = &presignURL
		}

		thumbnailURL, err := s.generateProjectFileURL(ctx, projects[i].ID, types.ProjectFileTypeProjectThumbnail, time.Minute*5, "get", logger)
		if err != nil {
			return nil, fmt.Errorf("failed to generate thumbnail URL for project %s: %v", projects[i].ID, err)
		}
		if thumbnailURL != "" {
			projects[i].ThumbnailURL = &thumbnailURL
		}
	}

	return &types.GetAllProjectsResponse{
		Data:       projects,
		TotalCount: len(projects),
		Page:       1,
		TotalPages: 1,
	}, nil
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, project *types.ProjectUpdateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectUpdateResponse, error) {

	opts := ValidationOptions{
		CheckDeleted:  true,
		CheckArchived: true,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID

	} else {
		opts.CheckUserAssigned = true
		opts.UserID = userAuth.User.ID
		opts.CheckNotLockedByOtherUser = true
	}

	projectRow, err := s.validateProject(ctx, project.ID, opts, logger)
	if err != nil {
		return nil, err
	}

	err = s.dbService.Update(ctx, projectRow, project, logger)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToUpdateProject, err)
	}

	response := &types.ProjectUpdateResponse{}

	if project.IsProjectFileDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.ID, types.ProjectFileTypeProjectFile, time.Minute*15, "put", logger)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ProjectUploadURL = &presignURL
	}

	if project.IsProjectThumbnailDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.ID, types.ProjectFileTypeProjectThumbnail, time.Minute*15, "put", logger)
		if err != nil {
			return nil, fmt.Errorf("failed to generate presign URL: %v", err)
		}
		response.ThumbnailUploadURL = &presignURL
	}

	return response, nil
}

// DeleteProject removes a project by its ID.
// Note: This method should be called with userID for validation when invoked from handlers
func (s *Service) DeleteProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {

	opts := ValidationOptions{
		CheckDeleted:  true,
		CheckArchived: true,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID
	} else {
		opts.CheckUserAssigned = true
		opts.UserID = userAuth.User.ID
		opts.CheckNotLockedByOtherUser = true
	}

	projectRow, err := s.validateProject(ctx, projectID, opts, logger)

	if err != nil {
		return err
	}

	if projectRow.IsDeleted {
		return nil // Idempotent behavior
	}

	return s.dbService.Delete(ctx, projectRow, logger)
}

// AssignUserToProject assigns a user to a project.
func (s *Service) AssignUserToProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error) {

	opts := ValidationOptions{
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID
	} else {
		opts.CheckUserAssigned = true
		opts.UserID = userAuth.User.ID
	}

	_, err := s.validateProject(ctx, projectID, opts, logger)

	if err != nil {
		return nil, err
	}

	// Get user ID by email
	userID, err := s.dbService.GetUserIDByEmail(ctx, userEmail, logger)
	if err != nil {
		return nil, err // This will return "user not found" from the database service
	}

	// Check if user is already assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedUserAssignmentCheck, err)
	}

	if isAssigned {
		return &types.UserAssignmentResponse{
			Message: "User successfully assigned to the project",
		}, nil
	}

	// Assign the user to the project
	if err := s.dbService.AssignUser(ctx, projectID, userID, logger); err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToAssignUser, err)
	}

	return &types.UserAssignmentResponse{
		Message: "User successfully assigned to the project",
	}, nil
}

// RemoveUserFromProject removes a user from a project.
func (s *Service) RemoveUserFromProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error) {

	opts := ValidationOptions{
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID
	} else {
		opts.CheckUserAssigned = true
		opts.UserID = userAuth.User.ID
	}

	_, err := s.validateProject(ctx, projectID, opts, logger)
	if err != nil {
		return nil, err
	}

	// Get user ID by email
	userID, err := s.dbService.GetUserIDByEmail(ctx, userEmail, logger)
	if err != nil {
		return nil, err // This will return "user not found" from the database service
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
	if err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedUserAssignmentCheck, err)
	}
	if !isAssigned {
		return &types.UserAssignmentResponse{
			Message: "User successfully removed from the project",
		}, nil
	}

	// Remove the user from the project
	if err := s.dbService.RemoveUser(ctx, projectID, userID, logger); err != nil {
		return nil, fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToRemoveUser, err)
	}

	return &types.UserAssignmentResponse{
		Message: "User successfully removed from the project",
	}, nil
}

// StarProject stars a project for a user.
func (s *Service) StarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {

	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	_, err := s.validateProject(ctx, projectID, opts, logger)

	if err != nil {
		return err
	}

	// Star the project
	if err := s.dbService.StarProject(ctx, projectID, userID, logger); err != nil {
		return err
	}

	return nil
}

// UnstarProject unstars a project for a user.
func (s *Service) UnstarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	opts := ValidationOptions{
		CheckUserAssigned:         true,
		UserID:                    userID,
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
	}

	_, err := s.validateProject(ctx, projectID, opts, logger)
	if err != nil {
		return err
	}

	// Unstar the project
	if err := s.dbService.UnstarProject(ctx, projectID, userID, logger); err != nil {
		return err
	}

	return nil
}

// ArchiveProject archives a project.
func (s *Service) ArchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {

	opts := ValidationOptions{
		CheckDeleted:  true,
		CheckArchived: false,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID
		opts.CheckNotLockedByOtherUser = false
	} else {
		opts.CheckUserAssigned = true
		opts.UserID = userAuth.User.ID
		opts.CheckNotLockedByOtherUser = true
	}

	projectRow, err := s.validateProject(ctx, projectID, opts, logger)
	if err != nil {
		return err
	}

	if projectRow.IsArchived {
		return nil // Idempotent behavior
	}

	// Archive the project
	if err := s.dbService.ArchiveProject(ctx, projectID, logger); err != nil {
		return err
	}

	return nil
}

// UnarchiveProject unarchives a project.
func (s *Service) UnarchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	opts := ValidationOptions{
		CheckDeleted:  true,
		CheckArchived: false,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID
	} else {
		opts.CheckUserAssigned = true
		opts.UserID = userAuth.User.ID
		opts.CheckNotLockedByOtherUser = true
	}

	projectRow, err := s.validateProject(ctx, projectID, opts, logger)
	if err != nil {
		return err
	}

	if !projectRow.IsArchived {
		return nil // Idempotent behavior
	}

	// Unarchive the project
	if err := s.dbService.UnarchiveProject(ctx, projectID, logger); err != nil {
		return err
	}

	return nil
}

// ProjectExists checks if a project exists.
func (s *Service) ProjectExists(ctx context.Context, projectID string, logger *zap.Logger) (bool, error) {
	return s.dbService.ProjectExists(ctx, projectID, logger)
}

// IsUserAssigned checks if a user is assigned to a project.
func (s *Service) IsUserAssigned(ctx context.Context, projectID, userID string, logger *zap.Logger) (bool, error) {
	return s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
}

// LockProject locks a project for a user.
func (s *Service) LockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {

	opts := ValidationOptions{
		CheckDeleted:              true,
		CheckArchived:             true,
		CheckNotLockedByOtherUser: false,
		UserID:                    userAuth.User.ID,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID
	} else {
		opts.CheckUserAssigned = true
	}

	projectRow, err := s.validateProject(ctx, projectID, opts, logger)
	if err != nil {
		return err
	}

	if projectRow.LockedByUserID.Valid {
		if projectRow.LockedByUserID.String == userAuth.User.ID {
			return nil // Project is already locked by the same user, idempotent behavior
		}
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			return fmt.Errorf(errorWithDetailsFormat, errorutils.ErrMsgFailedToGetUserByEmail, err)
		}
		return fmt.Errorf("project is locked by user: %s", lockedByEmail)
	}

	// Lock the project
	if err := s.dbService.LockProject(ctx, projectID, userAuth.User.ID, logger); err != nil {
		return err
	}

	return nil
}

// UnlockProject unlocks a project for a user.
func (s *Service) UnlockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	opts := ValidationOptions{
		CheckDeleted:  true,
		CheckArchived: true,
	}

	if userAuth.Role.RoleName == "Admin" {
		opts.CheckPrimaryOwner = true
		opts.AccountID = userAuth.Account.ID
		opts.CheckNotLockedByOtherUser = false
	} else {
		opts.CheckUserAssigned = true
		opts.UserID = userAuth.User.ID
		opts.CheckNotLockedByOtherUser = true
	}

	projectRow, err := s.validateProject(ctx, projectID, opts, logger)
	if err != nil {
		return err
	}

	if !projectRow.LockedByUserID.Valid {
		return nil // Project is already unlocked, idempotent behavior
	}

	// Unlock the project
	if err := s.dbService.UnlockProject(ctx, projectID, logger); err != nil {
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
