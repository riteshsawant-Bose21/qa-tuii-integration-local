package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strconv"
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

// Executor can perform SQL queries.
type DBExecutor interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
}

// ContextExecutor can perform SQL queries with context
type DBContextExecutor interface {
	DBExecutor

	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
}

// Service is a service for managing projects in the database.
type Service struct {
	db DBContextExecutor
}

// NewService creates a new database service.
func NewService(db DBContextExecutor) *Service {
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
func (s *Service) Insert(ctx context.Context, project *fusion.ProjectCreateRequest) error {
	if project == nil {
		return errors.New("project cannot be nil")
	}

	if project.ID == "" {
		project.ID = uuid.New().String()
	}

	// TODO: need to determine if accountId should be string or int
	accountID, err := strconv.Atoi(project.AccountID)
	if err != nil {
		return fmt.Errorf("failed to convert account ID to int: %v", err)
	}

	row := &model.Project{
		ID:                    project.ID,
		PrimaryOwnerAccountID: accountID,
		Name:                  null.NewString(project.Name, project.Name != ""),
		Description:           null.NewString(project.Description, project.Description != ""),
		Venue:                 null.NewString(project.Venue, project.Venue != ""),
		EnvironmentType:       null.NewString(project.EnvironmentType, project.EnvironmentType != ""),
		Application:           null.NewString(project.Application, project.Application != ""),
		BudgetAmount:          project.Budget.Amount,
		Currency:              null.NewString(project.Budget.Currency, project.Budget.Currency != ""),
		CreatedAt:             time.Now(),
		UpdatedAt:             time.Now(),
	}

	err = row.Insert(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to insert project: %v", err)
	}
	return nil
}

// SelectAll retrieves all projects from the database.
func (s *Service) SelectAll(ctx context.Context, queryParams *fusion.GetAllProjectsParams) ([]*fusion.Project, error) {
	// Retrieve all archived/unarchived projects from the database.
	// Get the rows by running the query.
	order := "ASC"
	if queryParams.SortOrder == "desc" || queryParams.SortOrder == "DESC" {
		order = "DESC"
	}

	rows, err := model.Projects(
		qm.Where("is_archived = ?", queryParams.IsArchived),
		qm.And("is_deleted = ?", false),
		qm.OrderBy(fmt.Sprintf("%s %s", queryParams.SortBy, order)),
	).All(ctx, s.db)

	if err != nil {
		s.logger.Error(types.ErrMsgFailedToGetProjects,
			zap.Error(err),
			zap.String("user_id", queryParams.UserID),
			zap.Bool("is_archived", queryParams.IsArchived),
			zap.String("sort_by", queryParams.SortBy),
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
func (s *Service) Update(ctx context.Context, id string, project *fusion.ProjectUpdateRequest) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}
	if project == nil {
		return errors.New("project cannot be nil")
	}

	if project.AccountID != "" {
		projectRow.PrimaryOwnerAccountID = null.NewInt(1, true) // TODO: Replace with actual account ID if available
	}

	row.PrimaryOwnerAccountID, err = strconv.Atoi(project.AccountID)
	if err != nil {
		return fmt.Errorf("failed to convert account ID to int: %v", err)
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
		row.EnvironmentType = null.NewString(project.EnvironmentType, project.EnvironmentType != "")
	}

	if project.Application != "" {
		row.Application = null.NewString(project.Application, project.Application != "")
	}

	if project.Budget.Currency != "" {
		row.Currency = null.NewString(project.Budget.Currency, project.Budget.Currency != "")
	}

	if project.Budget.Amount != 0 {
		row.BudgetAmount = project.Budget.Amount
	}

	if project.IsArchived {
		row.IsArchived = project.IsArchived
	}

	// TODO: Need to implement once user logic is finalized
	// if project.IsStarred {
	//
	// }

	// TODO: Need to implement once user logic and locking is finalized
	// if project.LockProject {
	//
	// }

	row.UpdatedAt = time.Now()

	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to update project: %v", err)
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

	if project.Budget.Amount >= 0 {
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

	row.IsDeleted = true
	row.UpdatedAt = time.Now()
	_, err = row.Update(ctx, s.db, boil.Infer())
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
