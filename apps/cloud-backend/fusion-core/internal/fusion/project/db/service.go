package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"go.uber.org/zap"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	boilerTypes "github.com/aarondl/sqlboiler/v4/types"

	ericDecimal "github.com/ericlagergren/decimal"
)

// Service is a service for managing projects in the database.
type Service struct {
	db     customModel.DBWithTransactions
	logger *log.Logger
}

// NewService creates a new database service.
func NewService(db customModel.DBWithTransactions, logger *log.Logger) *Service {
	if db == nil {
		panic("db cannot be nil")
	}
	if logger == nil {
		panic("logger cannot be nil")
	}
	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db:     db,
		logger: logger,
	}
}

// isDuplicateKeyError checks if the error is a duplicate key constraint violation
func isDuplicateKeyError(err error) bool {
	if err == nil {
		return false
	}
	// PostgreSQL duplicate key error codes
	errorStr := err.Error()
	return strings.Contains(errorStr, "duplicate key") ||
		strings.Contains(errorStr, "UNIQUE constraint") ||
		strings.Contains(errorStr, "violates unique constraint")
}

// GetDB returns the database instance for transaction management.
func (s *Service) GetDB(ctx context.Context) customModel.DBWithTransactions {
	return s.db
}

// GetProjectByID retrieves a project by its ID.
func (s *Service) GetProjectByID(ctx context.Context, projectID string) (*model.Project, error) {
	if projectID == "" {
		return nil, errors.New("project ID cannot be empty")
	}

	row, err := model.Projects(model.ProjectWhere.ID.EQ(projectID)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New(types.ErrMsgProjectNotFound)
		}
		s.logger.Error("Failed to fetch project",
			zap.Error(err),
			zap.String("project_id", projectID))
		return nil, fmt.Errorf("%s: %v", types.ErrMsgFailedToGetProject, err)
	}

	return row, nil
}

// Insert inserts a new project into the database.
func (s *Service) Insert(ctx context.Context, project *types.ProjectCreateRequest, accountID string, tx customModel.DBTxExecutor) (string, error) {

	// Create project record
	now := time.Now()
	projectRecord := &model.Project{
		ID:                    project.ID,
		PrimaryOwnerAccountID: null.NewString(accountID, accountID != ""),
		Name:                  null.NewString(project.Name, project.Name != ""),
		Description:           null.NewString(project.Description, project.Description != ""),
		Venue:                 null.NewString(project.Venue, project.Venue != ""),
		EnvironmentType:       null.NewString(string(project.EnvironmentType), string(project.EnvironmentType) != ""),
		ProjectPhase:          null.NewString(string(project.ProjectPhase), string(project.ProjectPhase) != ""),
		Application:           null.NewString(project.Application, project.Application != ""),
		CreatedAt:             now,
		UpdatedAt:             now,
	}

	// Only set budget fields if Budget is provided (non-zero values)
	if project.Budget.Currency != "" && project.Budget.Amount > 0 {
		projectRecord.BudgetAmount = boilerTypes.NewNullDecimal(ericDecimal.New(project.Budget.Amount, 0))
		projectRecord.Currency = null.NewString(project.Budget.Currency, project.Budget.Currency != "")
	}

	// Insert project
	if err := projectRecord.Insert(ctx, tx, boil.Infer()); err != nil {
		s.logger.Error(types.ErrMsgFailedToInsertProject,
			zap.Error(err),
			zap.String("project_id", project.ID),
			zap.String("account_id", accountID))
		return "", errors.New(types.ErrMsgFailedToInsertProject)
	}

	return project.ID, nil
}

// InsertProjectUser inserts a new project user association into the database.
func (s *Service) InsertProjectUser(ctx context.Context, projectID, userID string, tx customModel.DBTxExecutor) error {

	now := time.Now()
	// Create project user association
	projectUser := &model.ProjectUser{
		ProjectID: projectID,
		UserID:    userID,
		CreatedAt: now,
		UpdatedAt: now,
	}

	// Insert project user association
	if err := projectUser.Insert(ctx, tx, boil.Infer()); err != nil {
		s.logger.Error(types.ErrMsgFailedToInsertProjectUser,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedToInsertProjectUser)
	}

	return nil
}

// SelectAll retrieves all projects from the database.
func (s *Service) SelectAll(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse) ([]types.Project, error) {

	order := strings.ToUpper(queryParams.SortOrder)

	query := ""
	var rows *sql.Rows
	var err error
	if userAuth.Role.RoleName == "Admin" {
		query = fmt.Sprintf(`
			SELECT p.id, p.name, p.description, p.venue, 
		       p.environment_type, p.project_phase, p.application, p.budget_amount, 
		       p.currency, p.is_archived, p.is_deleted, p.locked_by_user_id, 
		       p.created_at, p.updated_at, pu.is_starred, u.email as locked_by_user_email
			FROM project p
			INNER JOIN project_user pu ON p.id = pu.project_id
			LEFT JOIN app_user u ON p.locked_by_user_id = u.id
			WHERE p.primary_owner_account_id = $1 AND p.is_archived = $2 AND p.is_deleted = $3
			ORDER BY p.%s %s`, queryParams.SortBy, order)
		rows, err = s.db.QueryContext(ctx, query, userAuth.Account.ID, queryParams.IsArchived, false)

	} else {
		query = fmt.Sprintf(`
			SELECT p.id, p.name, p.description, p.venue, 
				p.environment_type, p.project_phase, p.application, p.budget_amount, 
				p.currency, p.is_archived, p.is_deleted, p.locked_by_user_id, 
				p.created_at, p.updated_at, pu.is_starred, u.email as locked_by_user_email
			FROM project p
			INNER JOIN project_user pu ON p.id = pu.project_id
			LEFT JOIN app_user u ON p.locked_by_user_id = u.id
			WHERE pu.user_id = $1 AND p.is_archived = $2 AND p.is_deleted = $3
			ORDER BY p.%s %s
		`, queryParams.SortBy, order)

		rows, err = s.db.QueryContext(ctx, query, userAuth.User.ID, queryParams.IsArchived, false)
	}

	if err != nil {
		s.logger.Error(types.ErrMsgFailedToGetProjects,
			zap.Error(err),
			zap.String("user_id", userAuth.User.ID),
			zap.Bool("is_archived", queryParams.IsArchived),
			zap.String("sort_by", queryParams.SortBy),
			zap.String("sort_order", order))
		return nil, errors.New(types.ErrMsgFailedToGetProjects)
	}

	defer func() {
		if err := rows.Close(); err != nil {
			if s.logger != nil {
				s.logger.Error("failed to close rows", zap.Error(err))
			}
		}
	}()

	projects := make([]customModel.GetProjectModel, 0)

	for rows.Next() {
		var projectRow model.Project
		var isStarred bool
		var lockedByUserEmail sql.NullString

		err := rows.Scan(
			&projectRow.ID,
			&projectRow.Name,
			&projectRow.Description,
			&projectRow.Venue,
			&projectRow.EnvironmentType,
			&projectRow.ProjectPhase,
			&projectRow.Application,
			&projectRow.BudgetAmount,
			&projectRow.Currency,
			&projectRow.IsArchived,
			&projectRow.IsDeleted,
			&projectRow.LockedByUserID,
			&projectRow.CreatedAt,
			&projectRow.UpdatedAt,
			&isStarred,
			&lockedByUserEmail,
		)

		if err != nil {
			s.logger.Error(types.ErrMsgFailedToParseRow,
				zap.Error(err))
			return nil, errors.New(types.ErrMsgFailedToParseRow)
		}

		projects = append(projects, customModel.GetProjectModel{
			Project:           projectRow,
			IsStarred:         isStarred,
			LockedByUserEmail: lockedByUserEmail.String,
		})
	}

	projectsArray := make([]types.Project, 0, len(projects))
	for _, projectWithMetadata := range projects {
		project, err := newProject(&projectWithMetadata)
		if err != nil {
			s.logger.Error(types.ErrMsgFailedToParseRow,
				zap.Error(err),
				zap.String("project_id", projectWithMetadata.Project.ID))
			return nil, errors.New(types.ErrMsgFailedToParseRow)
		}
		projectsArray = append(projectsArray, *project)
	}

	return projectsArray, nil
}

// Update updates an existing project in the database.
func (s *Service) Update(ctx context.Context, projectRow *model.Project, project *types.ProjectUpdateRequest) error {

	if projectRow.IsArchived {
		return errors.New(types.ErrMsgProjectArchived)
	}

	if project.Name != "" {
		projectRow.Name = null.NewString(project.Name, project.Name != "")
	}

	if project.Description != "" {
		projectRow.Description = null.NewString(project.Description, project.Description != "")
	}

	if project.Venue != "" {
		projectRow.Venue = null.NewString(project.Venue, project.Venue != "")
	}

	if project.EnvironmentType != "" {
		projectRow.EnvironmentType = null.NewString(string(project.EnvironmentType), string(project.EnvironmentType) != "")
	}

	if project.ProjectPhase != "" {
		projectRow.ProjectPhase = null.NewString(string(project.ProjectPhase), string(project.ProjectPhase) != "")
	}

	if project.Application != "" {
		projectRow.Application = null.NewString(project.Application, project.Application != "")
	}

	if project.Budget.Currency != "" {
		projectRow.Currency = null.NewString(project.Budget.Currency, project.Budget.Currency != "")
	}

	if project.Budget.Amount > 0 {
		projectRow.BudgetAmount = boilerTypes.NewNullDecimal(ericDecimal.New(project.Budget.Amount, 0))
	}

	projectRow.UpdatedAt = time.Now()

	_, err := projectRow.Update(ctx, s.db, boil.Infer())
	if err != nil {
		s.logger.Error(types.ErrMsgFailedToUpdateProject,
			zap.Error(err),
			zap.String("project_id", projectRow.ID))
		return fmt.Errorf("%s: %v", types.ErrMsgFailedToUpdateProject, err)
	}

	return nil
}

// Delete removes a project by its ID.
func (s *Service) Delete(ctx context.Context, projectRow *model.Project) error {

	projectRow.IsDeleted = true
	projectRow.UpdatedAt = time.Now()
	_, err := projectRow.Update(ctx, s.db, boil.Infer())
	if err != nil {
		s.logger.Error(types.ErrMsgFailedToDeleteProject,
			zap.Error(err),
			zap.String("project_id", projectRow.ID))
		return errors.New(types.ErrMsgFailedToDeleteProject)
	}

	return nil
}

// AssignUser assigns a user to a project.
func (s *Service) AssignUser(ctx context.Context, projectID, userID string) error {

	now := time.Now()
	projectUser := &model.ProjectUser{
		ProjectID: projectID,
		UserID:    userID,
		IsStarred: false,
		CreatedAt: now,
		UpdatedAt: now,
	}

	if err := projectUser.Insert(ctx, s.db, boil.Infer()); err != nil {
		// Check if this is a duplicate key error (user already assigned)
		if isDuplicateKeyError(err) {
			// User already assigned, return success (idempotent behavior)
			s.logger.Info("User already assigned to project",
				zap.String("project_id", projectID),
				zap.String("user_id", userID))
			return nil
		}
		s.logger.Error(types.ErrMsgFailedToAssignUser,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedToAssignUser)
	}
	return nil
}

// RemoveUser removes a user from a project.
func (s *Service) RemoveUser(ctx context.Context, projectID, userID string) error {
	_, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).DeleteAll(ctx, s.db)

	if err != nil {
		s.logger.Error(types.ErrMsgFailedToRemoveUser,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedToRemoveUser)
	}
	return nil
}

// IsUserAssigned checks if a user is assigned to a project.
func (s *Service) IsUserAssigned(ctx context.Context, projectID, userID string) (bool, error) {
	exists, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).Exists(ctx, s.db)

	if err != nil {
		s.logger.Error(types.ErrMsgFailedUserAssignmentCheck,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return false, errors.New(types.ErrMsgFailedUserAssignmentCheck)
	}
	return exists, nil
}

// ProjectExists checks if a project exists.
func (s *Service) ProjectExists(ctx context.Context, projectID string) (bool, error) {
	exists, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
		model.ProjectWhere.IsDeleted.EQ(false),
	).Exists(ctx, s.db)

	if err != nil {
		s.logger.Error(types.ErrMsgFailedToCheckProjectExistence,
			zap.Error(err),
			zap.String("project_id", projectID))
		return false, errors.New(types.ErrMsgFailedToCheckProjectExistence)
	}
	return exists, nil
}

// UserExists checks if a user exists.
func (s *Service) UserExists(ctx context.Context, userID string) (bool, error) {
	exists, err := model.AppUsers(
		model.AppUserWhere.ID.EQ(userID),
	).Exists(ctx, s.db)

	if err != nil {
		s.logger.Error(types.ErrMsgFailedToCheckUserExistence,
			zap.Error(err),
			zap.String("user_id", userID))
		return false, errors.New(types.ErrMsgFailedToCheckUserExistence)
	}
	return exists, nil
}

// GetUserIDByEmail gets user ID by email address.
func (s *Service) GetUserIDByEmail(ctx context.Context, email string) (string, error) {
	user, err := model.AppUsers(
		model.AppUserWhere.Email.EQ(email),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", errors.New(types.ErrMsgUserNotFound)
		}
		s.logger.Error(types.ErrMsgFailedToGetUserByEmail,
			zap.Error(err),
			zap.String("email", email))
		return "", errors.New(types.ErrMsgFailedToGetUserByEmail)
	}
	return user.ID, nil
}

// StarProject stars a project for a user.
// Note: Assumes business layer has validated user assignment to project
func (s *Service) StarProject(ctx context.Context, projectID, userID string) error {
	// Get the project user record
	projectUser, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
		s.logger.Error(types.ErrMsgFailedToGetProjectUser,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedToGetProjectUser)
	}

	// Check if already starred
	if projectUser.IsStarred {
		return nil
	}

	// Star the project
	projectUser.IsStarred = true
	projectUser.UpdatedAt = time.Now()

	// Update the record
	if _, err := projectUser.Update(ctx, s.db, boil.Infer()); err != nil {
		s.logger.Error(types.ErrMsgFailedToStarProject,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedToStarProject)
	}

	return nil
}

// UnstarProject unstars a project for a user.
// Note: Assumes business layer has validated user assignment to project
func (s *Service) UnstarProject(ctx context.Context, projectID, userID string) error {
	// Get the project user record
	projectUser, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
		s.logger.Error(types.ErrMsgFailedToGetProjectUser,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedToGetProjectUser)
	}

	// Check if not starred
	if !projectUser.IsStarred {
		return nil
	}

	// Unstar the project
	projectUser.IsStarred = false
	projectUser.UpdatedAt = time.Now()

	// Update the record
	if _, err := projectUser.Update(ctx, s.db, boil.Infer()); err != nil {
		s.logger.Error(types.ErrMsgFailedToUnstarProject,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedToUnstarProject)
	}

	return nil
}

// ArchiveProject archives a project.
func (s *Service) ArchiveProject(ctx context.Context, projectID string) error {
	// Get the project record
	project, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return errors.New(types.ErrMsgProjectNotFound)
		}
		return errors.New(types.ErrMsgFailedToGetProject)
	}

	// Check if already archived
	if project.IsArchived {
		return nil
	}

	// Archive the project
	project.IsArchived = true
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return errors.New(types.ErrMsgFailedToArchiveProject)
	}

	return nil
}

// UnarchiveProject unarchives a project.
func (s *Service) UnarchiveProject(ctx context.Context, projectID string) error {
	// Get the project record
	project, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return errors.New(types.ErrMsgProjectNotFound)
		}
		return errors.New(types.ErrMsgFailedToGetProject)
	}

	// Check if not archived
	if !project.IsArchived {
		return nil
	}

	// Unarchive the project
	project.IsArchived = false
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return errors.New(types.ErrMsgFailedToUnarchiveProject)
	}

	return nil
}

// LockProject locks a project for a specific user.
func (s *Service) LockProject(ctx context.Context, projectID, userID string) error {
	// Get the project record
	project, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return errors.New(types.ErrMsgProjectNotFound)
		}
		return errors.New(types.ErrMsgFailedToGetProject)
	}

	// Check if project is already locked
	if project.LockedByUserID.Valid {
		if project.LockedByUserID.String == userID {
			return nil // Already locked by the same user
		}
		return errors.New(types.ErrMsgProjectLockedByUser + " " + project.LockedByUserID.String)
	}

	// Lock the project
	project.LockedByUserID = null.NewString(userID, true)
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return errors.New(types.ErrMsgFailedToLockProject)
	}

	return nil
}

// UnlockProject unlocks a project for a specific user.
func (s *Service) UnlockProject(ctx context.Context, projectID string) error {
	// Get the project record
	project, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return errors.New(types.ErrMsgProjectNotFound)
		}
		return errors.New(types.ErrMsgFailedToGetProject)
	}

	// Check if project is already unlocked
	if !project.LockedByUserID.Valid {
		return nil
	}

	// Unlock the project
	project.LockedByUserID = null.String{}
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return errors.New(types.ErrMsgFailedToUnlockProject)
	}

	return nil
}

// GetProjectLockUserID returns whether the project is locked and the user ID who locked it.
func (s *Service) GetProjectLockUserID(ctx context.Context, projectID string) (isLocked bool, lockedByUserID string, err error) {
	// Get the project record
	project, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return false, "", errors.New(types.ErrMsgProjectNotFound)
		}
		return false, "", errors.New(types.ErrMsgFailedToGetProject)
	}

	// Check if project is locked
	if !project.LockedByUserID.Valid {
		return false, "", nil
	}

	return true, project.LockedByUserID.String, nil
}

// GetUserEmailByID returns the email address for a given user ID.
func (s *Service) GetUserEmailByID(ctx context.Context, userID string) (string, error) {
	// Get the user who locked the project
	user, err := model.AppUsers(
		model.AppUserWhere.ID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", errors.New(types.ErrMsgUserNotFound)
		}
		return "", errors.New(types.ErrMsgFailedToGetLockedUserInfo)
	}

	return user.Email, nil
}
