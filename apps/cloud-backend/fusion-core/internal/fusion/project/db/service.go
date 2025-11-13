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
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	customModel "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	boilerTypes "github.com/aarondl/sqlboiler/v4/types"

	ericDecimal "github.com/ericlagergren/decimal"
)

// ProjectDBExecutor can perform SQL queries.
type ProjectDBExecutor interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
	BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error)
}

// ContextExecutor can perform SQL queries with context
type ProjectDBContextExecutor interface {
	ProjectDBExecutor

	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
}

// Service is a service for managing projects in the database.
type Service struct {
	db     ProjectDBContextExecutor
	logger *log.Logger
}

// NewService creates a new database service.
func NewService(db ProjectDBContextExecutor, logger *log.Logger) *Service {
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
func (s *Service) Insert(ctx context.Context, project *types.ProjectCreateRequest) (string, error) {
	if project == nil {
		return "", errors.New(types.ErrMsgProjectCannotBeNil)
	}

	// Generate ID if not provided
	if project.ID == "" {
		project.ID = uuid.New().String()
	}

	// Begin transaction
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		s.logger.Error(types.ErrMsgFailedToBeginTransaction,
			zap.Error(err),
			zap.String("project_id", project.ID),
			zap.String("user_id", project.UserID))
		return "", errors.New(types.ErrMsgFailedToBeginTransaction)
	}

	// Create project record
	now := time.Now()
	projectRecord := &model.Project{
		ID:                 project.ID,
		PrimaryOwnerUserID: null.NewString(project.UserID, project.UserID != ""),
		Name:               null.NewString(project.Name, project.Name != ""),
		Description:        null.NewString(project.Description, project.Description != ""),
		Venue:              null.NewString(project.Venue, project.Venue != ""),
		EnvironmentType:    null.NewString(string(project.EnvironmentType), string(project.EnvironmentType) != ""),
		ProjectPhase:       null.NewString(string(project.ProjectPhase), string(project.ProjectPhase) != ""),
		Application:        null.NewString(project.Application, project.Application != ""),
		BudgetAmount:       boilerTypes.NewNullDecimal(ericDecimal.New(project.Budget.Amount, 0)),
		Currency:           null.NewString(project.Budget.Currency, project.Budget.Currency != ""),
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	// Insert project
	if err := projectRecord.Insert(ctx, tx, boil.Infer()); err != nil {
		tx.Rollback()
		s.logger.Error(types.ErrMsgFailedToInsertProject,
			zap.Error(err),
			zap.String("project_id", project.ID),
			zap.String("user_id", project.UserID))
		return "", errors.New(types.ErrMsgFailedToInsertProject)
	}

	// Create project user association
	projectUser := &model.ProjectUser{
		ProjectID: project.ID,
		UserID:    project.UserID,
		CreatedAt: now,
		UpdatedAt: now,
	}

	// Insert project user association
	if err := projectUser.Insert(ctx, tx, boil.Infer()); err != nil {
		tx.Rollback()
		s.logger.Error(types.ErrMsgFailedToInsertProjectUser,
			zap.Error(err),
			zap.String("project_id", project.ID),
			zap.String("user_id", project.UserID))
		return "", errors.New(types.ErrMsgFailedToInsertProjectUser)
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		s.logger.Error(types.ErrMsgFailedToCommitTransaction,
			zap.Error(err),
			zap.String("project_id", project.ID),
			zap.String("user_id", project.UserID))
		return "", errors.New(types.ErrMsgFailedToCommitTransaction)
	}

	return project.ID, nil
}

// SelectAll retrieves all projects from the database.
func (s *Service) SelectAll(ctx context.Context, queryParams *types.GetAllProjectsParams) ([]*types.Project, error) {
	// Set default sort order and field if not provided
	order := "ASC"
	if queryParams.SortOrder != "" {
		upperOrder := strings.ToUpper(queryParams.SortOrder)
		if upperOrder == "DESC" {
			order = "DESC"
		} else if upperOrder == "ASC" {
			order = "ASC"
		} else {
			s.logger.Error("Invalid sort order provided, using default ASC",
				zap.String("invalid_order", queryParams.SortOrder))
			order = "ASC"
		}
	}

	// Set default sort field if not provided and validate
	sortBy := "created_at"
	if queryParams.SortBy != "" {
		// Validate the sort field to prevent SQL injection
		validSortFields := map[string]bool{
			"created_at": true,
			"updated_at": true,
		}
		if validSortFields[queryParams.SortBy] {
			sortBy = queryParams.SortBy
		} else {
			s.logger.Error("Invalid sort field provided, using default",
				zap.String("invalid_field", queryParams.SortBy),
				zap.String("default_field", sortBy))
		}
	}

	// Use raw SQL query to get project data, is_starred, and locked user email in one query
	// Explicitly list all columns to match our scanning order
	query := fmt.Sprintf(`
		SELECT p.id, p.name, p.description, p.venue, 
		       p.environment_type, p.project_phase, p.application, p.budget_amount, 
		       p.currency, p.is_archived, p.is_deleted, p.locked_by_user_id, 
		       p.created_at, p.updated_at, pu.is_starred, u.email as locked_by_user_email
		FROM project p
		INNER JOIN project_user pu ON p.id = pu.project_id
		LEFT JOIN "user" u ON p.locked_by_user_id = u.id
		WHERE pu.user_id = $1 AND p.is_archived = $2 AND p.is_deleted = $3
		ORDER BY p.%s %s
	`, sortBy, order)
	rows, err := s.db.QueryContext(ctx, query, queryParams.UserID, queryParams.IsArchived, false)
	if err != nil {
		s.logger.Error(types.ErrMsgFailedToGetProjects,
			zap.Error(err),
			zap.String("user_id", queryParams.UserID),
			zap.Bool("is_archived", queryParams.IsArchived),
			zap.String("sort_by", sortBy),
			zap.String("sort_order", order))
		return nil, errors.New(types.ErrMsgFailedToGetProjects)
	}
	defer rows.Close()

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

	projectsArray := make([]*types.Project, 0, len(projects))
	for _, projectWithMetadata := range projects {
		project, err := newProject(&projectWithMetadata)
		if err != nil {
			s.logger.Error(types.ErrMsgFailedToParseRow,
				zap.Error(err),
				zap.String("project_id", projectWithMetadata.Project.ID))
			return nil, errors.New(types.ErrMsgFailedToParseRow)
		}
		projectsArray = append(projectsArray, project)
	}

	return projectsArray, nil
}

// Update updates an existing project in the database.
func (s *Service) Update(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*model.Project, error) {
	if id == "" {
		return nil, errors.New(types.ErrMsgIdCannotBeEmpty)
	}

	row, err := model.Projects(model.ProjectWhere.ID.EQ(id)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, errors.New(types.ErrMsgProjectNotFound)
		}
		return nil, errors.New(types.ErrMsgProjectNotFound)
	}

	if row.IsArchived {
		return nil, errors.New(types.ErrMsgProjectArchived)
	}

	if project.AccountID != "" {
		row.PrimaryOwnerUserID = null.NewString(project.AccountID, project.AccountID != "")
	}

	if project.Name != "" {
		row.Name = null.NewString(project.Name, project.Name != "")
	}

	if project.Description != "" {
		row.Description = null.NewString(project.Description, project.Description != "")
	}

	if project.Venue != "" {
		row.Venue = null.NewString(project.Venue, project.Venue != "")
	}

	if project.EnvironmentType != "" {
		row.EnvironmentType = null.NewString(string(project.EnvironmentType), string(project.EnvironmentType) != "")
	}

	if project.ProjectPhase != "" {
		row.ProjectPhase = null.NewString(string(project.ProjectPhase), string(project.ProjectPhase) != "")
	}

	if project.Application != "" {
		row.Application = null.NewString(project.Application, project.Application != "")
	}

	if project.Budget.Currency != "" {
		row.Currency = null.NewString(project.Budget.Currency, project.Budget.Currency != "")
	}

	if project.Budget.Amount != 0 {
		row.BudgetAmount = boilerTypes.NewNullDecimal(ericDecimal.New(project.Budget.Amount, 0))
	}

	row.UpdatedAt = time.Now()

	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		s.logger.Error(types.ErrMsgFailedToUpdateProject,
			zap.Error(err),
			zap.String("project_id", id))
		return nil, errors.New(types.ErrMsgFailedToUpdateProject)
	}
	return row, nil
}

// Delete removes a project by its ID.
func (s *Service) Delete(ctx context.Context, id string) error {
	if strings.TrimSpace(id) == "" {
		return errors.New(types.ErrMsgProjectIdCannotBeEmpty)
	}
	return nil
}

// AssignUser assigns a user to a project.
func (s *Service) AssignUser(ctx context.Context, projectID, userID string) error {

	projectUser := &model.ProjectUser{
		ProjectID: projectID,
		UserID:    userID,
		IsStarred: false,
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
	exists, err := model.Users(
		model.UserWhere.ID.EQ(userID),
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
	user, err := model.Users(
		model.UserWhere.Email.EQ(email),
	).One(ctx, s.db)

	if err != nil {
		return errors.New(types.ErrMsgProjectNotFound)
	}

	row.IsDeleted = true
	row.UpdatedAt = time.Now()
	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		s.logger.Error(types.ErrMsgFailedToDeleteProject,
			zap.Error(err),
			zap.String("project_id", id))
		return errors.New(types.ErrMsgFailedToDeleteProject)
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

// AssignUser assigns a user to a project.
func (s *Service) AssignUser(ctx context.Context, projectID, userID string) error {

	projectUser := &model.ProjectUser{
		ProjectID: projectID,
		UserID:    userID,
		IsStarred: false,
	}

	if err := projectUser.Insert(ctx, s.db, boil.Infer()); err != nil {
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
	exists, err := model.Users(
		model.UserWhere.ID.EQ(userID),
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
	user, err := model.Users(
		model.UserWhere.Email.EQ(email),
	).One(ctx, s.db)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			s.logger.Error(types.ErrMsgUserNotFound,
				zap.String("email", email))
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
func (s *Service) StarProject(ctx context.Context, projectID, userID string) error {
	// Check if user is assigned to the project
	isAssigned, err := s.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		s.logger.Error(types.ErrMsgFailedUserAssignmentCheck,
			zap.Error(err),
			zap.String("project_id", projectID),
			zap.String("user_id", userID))
		return errors.New(types.ErrMsgFailedUserAssignmentCheck)
	}
	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	// Get the project user record
	projectUser, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
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
func (s *Service) UnstarProject(ctx context.Context, projectID, userID string) error {
	// Check if user is assigned to the project
	isAssigned, err := s.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return errors.New(types.ErrMsgFailedUserAssignmentCheck)
	}
	if !isAssigned {
		return errors.New(types.ErrMsgUserNotAssignedToProject)
	}

	// Get the project user record
	projectUser, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
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
		return errors.New(types.ErrMsgProjectNotLockedByUser)
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
func (s *Service) UnlockProject(ctx context.Context, projectID, userID string) error {
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

	// Check if project is locked
	if !project.LockedByUserID.Valid {
		return nil
	}

	// Check if project is locked by the requesting user
	if project.LockedByUserID.String != userID {
		return errors.New(types.ErrMsgProjectNotLockedByUser)
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

// GetProjectLockInfo returns project lock information including the email of the user who locked it.
func (s *Service) GetProjectLockInfo(ctx context.Context, projectID string) (isLocked bool, lockedByEmail string, err error) {
	// Get the project record with user information
	project, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
		qm.Load(model.ProjectRels.LockedByUser),
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

	// Get the user who locked the project
	lockedUser, err := model.Users(
		model.UserWhere.ID.EQ(project.LockedByUserID.String),
	).One(ctx, s.db)

	if err != nil {
		return true, "", errors.New(types.ErrMsgFailedToGetLockedUserInfo)
	}

	return true, lockedUser.Email, nil
}
