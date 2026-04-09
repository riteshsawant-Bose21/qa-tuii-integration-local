// Package project provides project management functionality.
package project

import (
	"context"
	"fmt"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	constants "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	errorutils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"go.uber.org/zap"
)

const (
	projectFilePathFormat = "projects/%s/%s/%s.zip"
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
		logger.Error("invalid operation for generating project file URL", zap.String("operation", operation))
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
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}

	projectRow, err := s.dbService.GetProjectByID(ctx, projectID, logger)
	if err != nil {
		return nil, err
	}

	if projectRow == nil {
		return nil, fmt.Errorf("%w", errorutils.ErrProjectNotFound)
	}

	if opts.CheckDeleted && projectRow.IsDeleted {
		return nil, fmt.Errorf("%w", errorutils.ErrProjectNotFound)
	}

	if opts.CheckArchived && projectRow.IsArchived {
		return nil, fmt.Errorf("%w", errorutils.ErrProjectArchived)
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
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
	if err != nil {
		logger.Error("failed to check user assignment", zap.String("projectID", projectID), zap.String("userID", userID), zap.Error(err))
		return err
	}
	if !isAssigned {
		return fmt.Errorf("%w", errorutils.ErrUserNotAssignedToProject)
	}
	return nil
}

// validateProjectNotLockedByOtherUser checks if project is not locked by another user
func (s *Service) validateProjectNotLockedByOtherUser(ctx context.Context, projectRow *models.Project, userID string, logger *zap.Logger) error {
	if projectRow == nil {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectRowNil))
		return fmt.Errorf("%w", errorutils.ErrProjectRowNil)
	}
	if userID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if projectRow.LockedByUserID.Valid && projectRow.LockedByUserID.String != userID {
		lockedByEmail, err := s.dbService.GetUserEmailByID(ctx, projectRow.LockedByUserID.String)
		if err != nil {
			logger.Error("failed to get user by email", zap.Error(err))
			return err
		}
		return fmt.Errorf("project is locked by %s: %w", lockedByEmail, errorutils.ErrProjectLockedByOtherUser)
	}
	return nil
}

// validatePrimaryOwner checks if user org account is the primary owner of the project
func (s *Service) validatePrimaryOwner(projectRow *models.Project, accountID string) error {
	if projectRow == nil {
		return fmt.Errorf("%w", errorutils.ErrProjectRowNil)
	}
	if accountID == "" {
		return fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}

	if projectRow.PrimaryOwnerAccountID != accountID {
		return fmt.Errorf("%w", errorutils.ErrForbidden)
	}
	return nil
}

// CreateProject adds a new project to the database.
func (s *Service) CreateProject(ctx context.Context, project *types.ProjectCreateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectCreateResponse, error) {
	if project == nil {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectCannotBeNil))
		return nil, fmt.Errorf("%w", errorutils.ErrProjectCannotBeNil)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return nil, fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}

	projectRow, err := s.dbService.GetProjectByID(ctx, project.ID, logger)

	if err == nil && projectRow != nil {
		return nil, fmt.Errorf("%w", errorutils.ErrProjectAlreadyExists)
	}

	db := s.dbService.GetDB(ctx)

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}

	id, err := s.dbService.Insert(ctx, project, userAuth.Account.ID, tx, logger)
	if err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			return nil, fmt.Errorf("rollback failed %v: %w", rollbackErr, err)
		}
		return nil, err
	}

	// Assign user to project
	if err := s.dbService.InsertProjectUser(ctx, id, userAuth.User.ID, tx, logger); err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			return nil, fmt.Errorf("rollback failed %v: %w", rollbackErr, err)
		}
		return nil, err
	}

	if err := tx.Commit(); err != nil {
		logger.Error("failed to commit transaction", zap.Error(err))
		return nil, err
	}

	response := &types.ProjectCreateResponse{
		ID: id,
	}

	if project.IsProjectFileCreated {
		presignURL, err := s.generateProjectFileURL(ctx, id, types.ProjectFileTypeProjectFile, constants.S3PresignedUrlTTL, "put", logger)
		if err != nil {
			return nil, err
		}
		response.ProjectUploadURL = &presignURL
	}

	if project.IsProjectThumbnailCreated {
		presignURL, err := s.generateProjectFileURL(ctx, id, types.ProjectFileTypeProjectThumbnail, constants.S3PresignedUrlTTL, "put", logger)
		if err != nil {
			return nil, err
		}
		response.ThumbnailUploadURL = &presignURL
	}

	return response, nil
}

// GetAllProjects retrieves all projects.
func (s *Service) GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.GetAllProjectsResponse, error) {
	if queryParams == nil {
		logger.Error("invalid argument", zap.Error(errorutils.ErrQueryParamsNil))
		return nil, fmt.Errorf("%w", errorutils.ErrQueryParamsNil)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return nil, fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}
	projects, err := s.dbService.SelectAll(ctx, queryParams, userAuth, logger)
	if err != nil {
		return nil, err
	}

	// Generate presigned URLs for all projects
	for i := range projects {
		presignURL, err := s.generateProjectFileURL(ctx, projects[i].ID, types.ProjectFileTypeProjectFile, constants.S3PresignedUrlTTL, "get", logger)
		if err != nil {
			return nil, err
		}

		if presignURL != "" {
			projects[i].ProjectFileURL = &presignURL
		}

		thumbnailURL, err := s.generateProjectFileURL(ctx, projects[i].ID, types.ProjectFileTypeProjectThumbnail, constants.S3PresignedUrlTTL, "get", logger)
		if err != nil {
			return nil, err
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

// GetProjectById retrieves a project by its ID with metadata.
func (s *Service) GetProjectById(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.Project, error) {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return nil, fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}
	// SelectByID handles user assignment validation via JOIN and returns full project with metadata
	var project *types.Project
	var err error

	switch userAuth.Role.RoleName {
	case constants.SuperAdminRoleName:
		project, err = s.dbService.SelectByID(ctx, projectID, userAuth, logger)
	case constants.AdminRoleName:
		project, err = s.dbService.GetProjectByIDForAccount(ctx, projectID, userAuth, logger)
	default:
		project, err = s.dbService.GetProjectByIDForUser(ctx, projectID, userAuth, logger)
	}

	if err != nil {
		return nil, err
	}

	// Generate presigned URLs for project files
	presignURL, err := s.generateProjectFileURL(ctx, project.ID, types.ProjectFileTypeProjectFile, time.Minute*5, "get", logger)
	if err != nil {
		return nil, err
	}
	if presignURL != "" {
		project.ProjectFileURL = &presignURL
	}

	thumbnailURL, err := s.generateProjectFileURL(ctx, project.ID, types.ProjectFileTypeProjectThumbnail, time.Minute*5, "get", logger)
	if err != nil {
		return nil, err
	}
	if thumbnailURL != "" {
		project.ThumbnailURL = &thumbnailURL
	}

	return project, nil
}

// UpdateProject modifies an existing project.
func (s *Service) UpdateProject(ctx context.Context, project *types.ProjectUpdateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectUpdateResponse, error) {
	if project == nil {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectUpdateReqNil))
		return nil, fmt.Errorf("%w", errorutils.ErrProjectUpdateReqNil)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return nil, fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}

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
		return nil, err
	}

	response := &types.ProjectUpdateResponse{}

	if project.IsProjectFileDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.ID, types.ProjectFileTypeProjectFile, constants.S3PresignedUrlTTL, "put", logger)
		if err != nil {
			return nil, err
		}
		response.ProjectUploadURL = &presignURL
	}

	if project.IsProjectThumbnailDirty {
		presignURL, err := s.generateProjectFileURL(ctx, projectRow.ID, types.ProjectFileTypeProjectThumbnail, constants.S3PresignedUrlTTL, "put", logger)
		if err != nil {
			return nil, err
		}
		response.ThumbnailUploadURL = &presignURL
	}

	return response, nil
}

// DeleteProject removes a project by its ID.
// Note: This method should be called with userID for validation when invoked from handlers
func (s *Service) DeleteProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}

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

	if err := s.dbService.Delete(ctx, projectRow, logger); err != nil {
		return err
	}
	return nil
}

// AssignUserToProject assigns a user to a project.
func (s *Service) AssignUserToProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error) {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userEmail == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserEmailEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrUserEmailEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return nil, fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}

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
		return nil, err
	}

	// Check if user is already assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
	if err != nil {
		return nil, err
	}

	if isAssigned {
		return &types.UserAssignmentResponse{
			Message: "User successfully assigned to the project",
		}, nil
	}

	// Assign the user to the project
	if err := s.dbService.AssignUser(ctx, projectID, userID, logger); err != nil {
		return nil, err
	}

	return &types.UserAssignmentResponse{
		Message: "User successfully assigned to the project",
	}, nil
}

// RemoveUserFromProject removes a user from a project.
func (s *Service) RemoveUserFromProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error) {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userEmail == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserEmailEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrUserEmailEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return nil, fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return nil, fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}

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
		return nil, err
	}

	// Check if user is assigned to the project
	isAssigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
	if err != nil {
		return nil, err
	}
	if !isAssigned {
		return &types.UserAssignmentResponse{
			Message: "User successfully removed from the project",
		}, nil
	}

	// Remove the user from the project
	if err := s.dbService.RemoveUser(ctx, projectID, userID, logger); err != nil {
		return nil, err
	}

	return &types.UserAssignmentResponse{
		Message: "User successfully removed from the project",
	}, nil
}

// StarProject stars a project for a user.
func (s *Service) StarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}

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
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
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
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}

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
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}
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
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return false, fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	exists, err := s.dbService.ProjectExists(ctx, projectID, logger)
	if err != nil {
		return false, err
	}
	return exists, nil
}

// IsUserAssigned checks if a user is assigned to a project.
func (s *Service) IsUserAssigned(ctx context.Context, projectID, userID string, logger *zap.Logger) (bool, error) {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return false, fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return false, fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	assigned, err := s.dbService.IsUserAssigned(ctx, projectID, userID, logger)
	if err != nil {
		return false, err
	}
	return assigned, nil
}

// LockProject locks a project for a user.
func (s *Service) LockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}

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
			return err
		}
		return fmt.Errorf("project is locked by %s: %w", lockedByEmail, errorutils.ErrProjectLockedByOtherUser)
	}

	// Lock the project
	if err := s.dbService.LockProject(ctx, projectID, userAuth.User.ID, logger); err != nil {
		return err
	}

	return nil
}

// UnlockProject unlocks a project for a user.
func (s *Service) UnlockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	if projectID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrProjectIDCannotBeEmpty))
		return fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	if userAuth.User.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrUserIDRequired))
		return fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	if userAuth.Account.ID == "" {
		logger.Error("invalid argument", zap.Error(errorutils.ErrAccountIDEmpty))
		return fmt.Errorf("%w", errorutils.ErrAccountIDEmpty)
	}
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
	if projectID == "" {
		return false, "", fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
	isLocked, lockedByUserID, err = s.dbService.GetProjectLockUserID(ctx, projectID)
	if err != nil {
		return false, "", err
	}
	return isLocked, lockedByUserID, nil
}

// GetUserEmailByID returns the email address for a given user ID.
func (s *Service) GetUserEmailByID(ctx context.Context, userID string) (string, error) {
	if userID == "" {
		return "", fmt.Errorf("%w", errorutils.ErrUserIDRequired)
	}
	email, err := s.dbService.GetUserEmailByID(ctx, userID)
	if err != nil {
		return "", err
	}
	return email, nil
}

// GetProjectLockInfo returns project lock information.
func (s *Service) GetProjectLockInfo(ctx context.Context, projectID string) (isLocked bool, lockedByEmail string, err error) {
	if projectID == "" {
		return false, "", fmt.Errorf("%w", errorutils.ErrProjectIDCannotBeEmpty)
	}
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
