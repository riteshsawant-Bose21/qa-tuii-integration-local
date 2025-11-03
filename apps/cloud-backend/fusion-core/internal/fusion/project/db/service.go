package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/aarondl/null/v8"
	"github.com/aarondl/sqlboiler/v4/boil"
	"github.com/aarondl/sqlboiler/v4/queries/qm"
	"github.com/google/uuid"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	model "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/validation"
)

const (
	validationFailedMsg = "validation failed: %w"
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
	// Initialize the database connection here and return an instance of Service.
	return &Service{
		db: db,
	}
}

// Insert inserts a new project into the database.
func (s *Service) Insert(ctx context.Context, project *types.ProjectCreateRequest) error {
	// Validate input data
	if err := validation.ValidateProjectCreateRequest(project); err != nil {
		return fmt.Errorf(validationFailedMsg, err)
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
		EnvironmentType:       null.NewString(string(project.EnvironmentType), string(project.EnvironmentType) != ""),
		ProjectPhase:          null.NewString(string(project.ProjectPhase), string(project.ProjectPhase) != ""),
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
func (s *Service) SelectAll(ctx context.Context, queryParams *types.GetAllProjectsParams) ([]*types.Project, error) {
	// Validate query parameters
	if err := validation.ValidateGetAllProjectsParams(queryParams); err != nil {
		return nil, fmt.Errorf(validationFailedMsg, err)
	}

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

	rows, err := model.Projects(
		qm.Where("is_archived = ?", queryParams.IsArchived),
		qm.And("is_deleted = ?", false),
		qm.OrderBy(fmt.Sprintf("%s %s", sortBy, order)),
	).All(ctx, s.db)

	if err != nil {
		return nil, fmt.Errorf("can't get rows: %v", err)
	}

	projects := make([]*types.Project, 0, len(rows))
	for _, row := range rows {
		project, err := newProject(row)
		if err != nil {
			return nil, fmt.Errorf("can't parse row: %v", err)
		}
		projects = append(projects, project)
	}

	return projects, nil
}

// Update updates an existing project in the database.
func (s *Service) Update(ctx context.Context, id string, project *types.ProjectUpdateRequest) error {
	if id == "" {
		return errors.New("id cannot be empty")
	}

	// Validate input data
	if err := validation.ValidateProjectUpdateRequest(project); err != nil {
		return fmt.Errorf(validationFailedMsg, err)
	}

	row, err := model.Projects(model.ProjectWhere.ID.EQ(id)).One(ctx, s.db)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return fmt.Errorf("project not found: %v", id)
		}
		return fmt.Errorf("failed to get project by id: %v", err)
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
	return nil
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
