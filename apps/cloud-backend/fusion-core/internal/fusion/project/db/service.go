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

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	boilerTypes "github.com/aarondl/sqlboiler/v4/types"

	ericDecimal "github.com/ericlagergren/decimal"
)

const (
	failedUserAssignmentCheckMsg = "failed to check user assignment: %v"
	projectNotFoundErrMsg        = "project not found"
	failedToGetProjectErrMsg     = "failed to get project: %v"
	projectAlreadyLockedErrMsg   = "project is already locked"
	projectNotLockedErrMsg       = "project is not locked"
	projectNotLockedByUserErrMsg = "project is not locked by this user"
)

// Executor can perform SQL queries.
type DBExecutor interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
	BeginTx(ctx context.Context, opts *sql.TxOptions) (*sql.Tx, error)
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
	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

// Insert inserts a new project into the database.
func (s *Service) Insert(ctx context.Context, project *types.ProjectCreateRequest) (string, error) {
	if project == nil {
		return "", errors.New("project cannot be nil")
	}

	// Generate ID if not provided
	if project.ID == "" {
		project.ID = uuid.New().String()
	}

	// Begin transaction
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return "", fmt.Errorf("failed to begin transaction: %v", err)
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
		return "", fmt.Errorf("failed to insert project: %v", err)
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
		return "", fmt.Errorf("failed to insert project user: %v", err)
	}

	// Commit transaction
	if err := tx.Commit(); err != nil {
		return "", fmt.Errorf("failed to commit transaction: %v", err)
	}

	return project.ID, nil
}

// SelectAll retrieves all projects from the database.
func (s *Service) SelectAll(ctx context.Context, queryParams *types.GetAllProjectsParams) ([]*types.Project, error) {
	// Set default sort order and field if not provided
	order := "ASC"
	if queryParams.SortOrder != "" {
		if strings.ToUpper(queryParams.SortOrder) == "DESC" {
			order = "DESC"
		}
	}

	// Set default sort field if not provided
	sortBy := "created_at"
	if queryParams.SortBy != "" {
		sortBy = queryParams.SortBy
	}

	// SELECT projects.*
	// FROM projects
	// INNER JOIN project_user pu ON projects.id = pu.project_id
	// WHERE pu.user_id = ?
	//   AND projects.is_archived = ?
	//   AND projects.is_deleted = ?
	// ORDER BY projects.created_at ASC
	projectRows, err := model.Projects(
		qm.InnerJoin("project_user pu ON project.id = pu.project_id"),
		qm.Where("pu.user_id = ?", queryParams.UserID),
		qm.Where("is_archived = ?", queryParams.IsArchived),
		qm.Where("is_deleted = ?", false),
		qm.OrderBy(fmt.Sprintf("%s %s", sortBy, order)),
	).All(ctx, s.db)

	if err != nil {
		return nil, fmt.Errorf("failed to get projects: %v", err)
	}

	projects := make([]*types.Project, 0, len(projectRows))
	for _, row := range projectRows {
		project, err := newProject(row)
		if err != nil {
			return nil, fmt.Errorf("can't parse row: %v", err)
		}
		projects = append(projects, project)
	}

	return projects, nil
}

// Update updates an existing project in the database.
func (s *Service) Update(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*model.Project, error) {
	if id == "" {
		return nil, errors.New("id cannot be empty")
	}

	row, err := model.Projects(model.ProjectWhere.ID.EQ(id)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, fmt.Errorf("project not found: %v", id)
		}
		return nil, fmt.Errorf("failed to get project by id: %v", err)
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
		return nil, fmt.Errorf("failed to update project: %v", err)
	}
	return row, nil
}

func (s *Service) Delete(ctx context.Context, id string) error {
	if strings.TrimSpace(id) == "" {
		return errors.New("project id cannot be empty")
	}
	row, err := model.Projects(model.ProjectWhere.ID.EQ(id)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return fmt.Errorf("project not found: %v", id)
		}
		return fmt.Errorf("failed to get project by id: %v", err)
	}

	row.IsDeleted = true
	row.UpdatedAt = time.Now()
	_, err = row.Update(ctx, s.db, boil.Infer())
	if err != nil {
		return fmt.Errorf("failed to delete project: %v", err)
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
		return fmt.Errorf("failed to assign user to project: %v", err)
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
		return fmt.Errorf("failed to remove user from project: %v", err)
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
		return false, fmt.Errorf(failedUserAssignmentCheckMsg, err)
	}
	return exists, nil
}

// ProjectExists checks if a project exists.
func (s *Service) ProjectExists(ctx context.Context, projectID string) (bool, error) {
	exists, err := model.Projects(
		model.ProjectWhere.ID.EQ(projectID),
	).Exists(ctx, s.db)

	if err != nil {
		return false, fmt.Errorf("failed to check project existence: %v", err)
	}
	return exists, nil
}

// UserExists checks if a user exists.
func (s *Service) UserExists(ctx context.Context, userID string) (bool, error) {
	exists, err := model.Users(
		model.UserWhere.ID.EQ(userID),
	).Exists(ctx, s.db)

	if err != nil {
		return false, fmt.Errorf("failed to check user existence: %v", err)
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
			return "", fmt.Errorf("user not found")
		}
		return "", fmt.Errorf("failed to get user by email: %v", err)
	}
	return user.ID, nil
}

// StarProject stars a project for a user.
func (s *Service) StarProject(ctx context.Context, projectID, userID string) error {
	// Check if user is assigned to the project
	isAssigned, err := s.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(failedUserAssignmentCheckMsg, err)
	}
	if !isAssigned {
		return fmt.Errorf("user not assigned to project")
	}

	// Get the project user record
	projectUser, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
		return fmt.Errorf("failed to get project user: %v", err)
	}

	// Check if already starred
	if projectUser.IsStarred {
		return fmt.Errorf("project is already starred")
	}

	// Star the project
	projectUser.IsStarred = true
	projectUser.UpdatedAt = time.Now()

	// Update the record
	if _, err := projectUser.Update(ctx, s.db, boil.Infer()); err != nil {
		return fmt.Errorf("failed to star project: %v", err)
	}

	return nil
}

// UnstarProject unstars a project for a user.
func (s *Service) UnstarProject(ctx context.Context, projectID, userID string) error {
	// Check if user is assigned to the project
	isAssigned, err := s.IsUserAssigned(ctx, projectID, userID)
	if err != nil {
		return fmt.Errorf(failedUserAssignmentCheckMsg, err)
	}
	if !isAssigned {
		return fmt.Errorf("user not assigned to project")
	}

	// Get the project user record
	projectUser, err := model.ProjectUsers(
		model.ProjectUserWhere.ProjectID.EQ(projectID),
		model.ProjectUserWhere.UserID.EQ(userID),
	).One(ctx, s.db)

	if err != nil {
		return fmt.Errorf("failed to get project user: %v", err)
	}

	// Check if not starred
	if !projectUser.IsStarred {
		return fmt.Errorf("project is not starred")
	}

	// Unstar the project
	projectUser.IsStarred = false
	projectUser.UpdatedAt = time.Now()

	// Update the record
	if _, err := projectUser.Update(ctx, s.db, boil.Infer()); err != nil {
		return fmt.Errorf("failed to unstar project: %v", err)
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
			return fmt.Errorf("project not found")
		}
		return fmt.Errorf("failed to get project: %v", err)
	}

	// Check if already archived
	if project.IsArchived {
		return fmt.Errorf("project is already archived")
	}

	// Archive the project
	project.IsArchived = true
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return fmt.Errorf("failed to archive project: %v", err)
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
			return fmt.Errorf("project not found")
		}
		return fmt.Errorf("failed to get project: %v", err)
	}

	// Check if not archived
	if !project.IsArchived {
		return fmt.Errorf("project is not archived")
	}

	// Unarchive the project
	project.IsArchived = false
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return fmt.Errorf("failed to unarchive project: %v", err)
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
			return errors.New(projectNotFoundErrMsg)
		}
		return fmt.Errorf(failedToGetProjectErrMsg, err)
	}

	// Check if project is already locked
	if project.LockedByUserID.Valid {
		return errors.New(projectAlreadyLockedErrMsg)
	}

	// Lock the project
	project.LockedByUserID = null.NewString(userID, true)
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return fmt.Errorf("failed to lock project: %v", err)
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
			return errors.New(projectNotFoundErrMsg)
		}
		return fmt.Errorf(failedToGetProjectErrMsg, err)
	}

	// Check if project is locked
	if !project.LockedByUserID.Valid {
		return errors.New(projectNotLockedErrMsg)
	}

	// Check if project is locked by the requesting user
	if project.LockedByUserID.String != userID {
		return errors.New(projectNotLockedByUserErrMsg)
	}

	// Unlock the project
	project.LockedByUserID = null.String{}
	project.UpdatedAt = time.Now()

	// Update the record
	if _, err := project.Update(ctx, s.db, boil.Infer()); err != nil {
		return fmt.Errorf("failed to unlock project: %v", err)
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
			return false, "", fmt.Errorf(projectNotFoundErrMsg)
		}
		return false, "", fmt.Errorf(failedToGetProjectErrMsg, err)
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
		return true, "", fmt.Errorf("failed to get locked user information: %v", err)
	}

	return true, lockedUser.Email, nil
}
