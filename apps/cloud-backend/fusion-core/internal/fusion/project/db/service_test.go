package db

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	testProjectID          = "123e4567-e89b-12d3-a456-426614174000"
	testProjectName        = "Test Project"
	testProjectDesc        = "Test Description"
	testProjectVenue       = "Test Venue"
	testProjectEnvType     = types.EnvironmentTypeIndoor
	testProjectPhase       = types.ProjectPhaseProposal
	testProjectApp         = "Test App"
	testProjectAccountID   = "123"
	testSelectProjectsStmt = "SELECT .*"
)

func setupTestDB(t *testing.T) (*sql.DB, sqlmock.Sqlmock, *Service) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)

	logger, err := log.NewProduction()
	require.NoError(t, err)

	service := NewService(db, logger)
	return db, mock, service
}

func TestNewService(t *testing.T) {
	t.Run("successfully creates new service", func(t *testing.T) {
		db, _, _ := sqlmock.New()
		logger, err := log.NewProduction()
		require.NoError(t, err)
		service := NewService(db, logger)
		assert.NotNil(t, service)
	})

	t.Run("panics when db is nil", func(t *testing.T) {
		logger, err := log.NewProduction()
		require.NoError(t, err)
		assert.Panics(t, func() {
			NewService(nil, logger)
		})
	})

	t.Run("panics when logger is nil", func(t *testing.T) {
		db, _, _ := sqlmock.New()
		assert.Panics(t, func() {
			NewService(db, nil)
		})
	})
}

func TestServiceInsert(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	t.Run("successfully inserts project", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			ID:              testProjectID,
			UserID:          testProjectAccountID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Venue:           testProjectVenue,
			EnvironmentType: testProjectEnvType,
			ProjectPhase:    testProjectPhase,
			Application:     testProjectApp,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		// Mock transaction operations
		mock.ExpectBegin()

		// Mock project insert with RETURNING clause
		returnRows := sqlmock.NewRows([]string{"is_archived", "is_deleted", "locked_by_user_id"}).
			AddRow(false, false, nil)
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnRows(returnRows)

		// Mock project user insert with RETURNING clause
		userReturnRows := sqlmock.NewRows([]string{"id", "is_starred"}).
			AddRow(1, false)
		mock.ExpectQuery(`INSERT INTO "project_user"`).
			WillReturnRows(userReturnRows)
		// Mock commit
		mock.ExpectCommit()

		id, err := service.Insert(ctx, project)
		assert.NoError(t, err)
		assert.Equal(t, testProjectID, id)

		// Verify all expectations were met
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully inserts project with generated ID", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			// ID is empty, should be generated
			UserID:          testProjectAccountID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Venue:           testProjectVenue,
			EnvironmentType: testProjectEnvType,
			ProjectPhase:    testProjectPhase,
			Application:     testProjectApp,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		// Mock transaction operations
		mock.ExpectBegin()
		// Mock project insert with RETURNING clause
		returnRows := sqlmock.NewRows([]string{"is_archived", "is_deleted", "locked_by_user_id"}).
			AddRow(false, false, nil)
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnRows(returnRows)
		userReturnRows := sqlmock.NewRows([]string{"id", "is_starred"}).
			AddRow(1, false)
		mock.ExpectQuery(`INSERT INTO "project_user"`).
			WillReturnRows(userReturnRows)
		mock.ExpectCommit()

		id, err := service.Insert(ctx, project)
		assert.NoError(t, err)
		assert.NotEmpty(t, id)
		assert.NotEqual(t, "", id)

		// Verify all expectations were met
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when project is nil", func(t *testing.T) {
		id, err := service.Insert(ctx, nil)
		assert.Error(t, err)
		assert.Empty(t, id)
		assert.Contains(t, err.Error(), "project cannot be nil")
	})

	t.Run("rolls back transaction on project insert failure", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			ID:              testProjectID,
			UserID:          testProjectAccountID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Venue:           testProjectVenue,
			EnvironmentType: testProjectEnvType,
			ProjectPhase:    testProjectPhase,
			Application:     testProjectApp,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		// Mock transaction operations
		mock.ExpectBegin()
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnError(assert.AnError)
		mock.ExpectRollback()

		id, err := service.Insert(ctx, project)
		assert.Error(t, err)
		assert.Empty(t, id)
		assert.Contains(t, err.Error(), "failed to insert project")

		// Verify all expectations were met
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("rolls back transaction on project user insert failure", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			ID:              testProjectID,
			UserID:          testProjectAccountID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Venue:           testProjectVenue,
			EnvironmentType: testProjectEnvType,
			ProjectPhase:    testProjectPhase,
			Application:     testProjectApp,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		// Mock transaction operations
		mock.ExpectBegin()
		returnRows := sqlmock.NewRows([]string{"is_archived", "is_deleted", "locked_by_user_id"}).
			AddRow(false, false, nil)
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnRows(returnRows)
		mock.ExpectQuery(`INSERT INTO "project_user"`).
			WillReturnError(assert.AnError)
		mock.ExpectRollback()

		id, err := service.Insert(ctx, project)
		assert.Error(t, err)
		assert.Empty(t, id)
		assert.Contains(t, err.Error(), "failed to insert project user")

		// Verify all expectations were met
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when begin transaction fails", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			ID:              testProjectID,
			UserID:          testProjectAccountID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Venue:           testProjectVenue,
			EnvironmentType: testProjectEnvType,
			ProjectPhase:    testProjectPhase,
			Application:     testProjectApp,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		mock.ExpectBegin().WillReturnError(assert.AnError)

		id, err := service.Insert(ctx, project)
		assert.Error(t, err)
		assert.Empty(t, id)
		assert.Contains(t, err.Error(), "failed to begin transaction")

		// Verify all expectations were met
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when commit fails", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			ID:              testProjectID,
			UserID:          testProjectAccountID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Venue:           testProjectVenue,
			EnvironmentType: testProjectEnvType,
			ProjectPhase:    testProjectPhase,
			Application:     testProjectApp,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		// Mock transaction operations
		mock.ExpectBegin()
		returnRows := sqlmock.NewRows([]string{"is_archived", "is_deleted", "locked_by_user_id"}).
			AddRow(false, false, nil)
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnRows(returnRows)
		userReturnRows := sqlmock.NewRows([]string{"id", "is_starred"}).
			AddRow(1, false)
		mock.ExpectQuery(`INSERT INTO "project_user"`).
			WillReturnRows(userReturnRows)
		mock.ExpectCommit().WillReturnError(assert.AnError)

		id, err := service.Insert(ctx, project)
		assert.Error(t, err)
		assert.Empty(t, id)
		assert.Contains(t, err.Error(), "failed to commit transaction")

		// Verify all expectations were met
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestServiceSelectAll(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	t.Run("successfully retrieves all projects", func(t *testing.T) {
		queryParams := &types.GetAllProjectsParams{
			UserID:     testProjectAccountID,
			IsArchived: false,
			SortBy:     "created_at",
			SortOrder:  "asc",
		}

		// Mock the actual JOIN query that SQLBoiler generates
		projectRows := sqlmock.NewRows([]string{
			"id", "primary_owner_user_id", "name", "description",
			"venue", "environment_type", "project_phase", "application", "budget_amount",
			"currency", "created_at", "updated_at", "is_archived", "is_deleted", "locked_by_user_id",
		}).AddRow(
			testProjectID, testProjectAccountID, testProjectName, testProjectDesc,
			testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0,
			"USD", time.Now(), time.Now(), false, false, nil,
		)
		mock.ExpectQuery("SELECT \"project\".\\* FROM \"project\" INNER JOIN project_user pu ON project.id = pu.project_id WHERE \\(pu.user_id = \\$1\\) AND \\(is_archived = \\$2\\) AND \\(is_deleted = \\$3\\) ORDER BY created_at ASC").WillReturnRows(projectRows)

		projects, err := service.SelectAll(ctx, queryParams)
		assert.NoError(t, err)
		assert.Len(t, projects, 1)
		assert.Equal(t, testProjectID, projects[0].ID)
	})
}

func TestServiceUpdate(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	t.Run("successfully updates project", func(t *testing.T) {
		updateReq := &types.ProjectUpdateRequest{
			AccountID:       testProjectAccountID,
			Name:            "Updated Project",
			Description:     "Updated Description",
			Venue:           "Updated Venue",
			EnvironmentType: types.EnvironmentTypeOutdoor,
			ProjectPhase:    types.ProjectPhaseDevelopment,
			Budget: types.Budget{
				Amount:   2000,
				Currency: "EUR",
			},
		}

		rows := sqlmock.NewRows([]string{
			"id", "primary_owner_account_id", "name", "description",
			"venue", "environment_type", "project_phase", "application", "budget_amount",
			"currency", "created_at", "updated_at", "is_archived", "is_deleted",
		}).AddRow(
			testProjectID, 123, testProjectName, testProjectDesc,
			testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0,
			"USD", time.Now(), time.Now(), false, false,
		)

		mock.ExpectQuery(testSelectProjectsStmt).WillReturnRows(rows)
		mock.ExpectExec("UPDATE \"project\"").WillReturnResult(sqlmock.NewResult(1, 1))

		project, err := service.Update(ctx, testProjectID, updateReq)
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, testProjectID, project.ID)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mock.ExpectQuery(testSelectProjectsStmt).WillReturnError(sql.ErrNoRows)

		project, err := service.Update(ctx, "non-existent", &types.ProjectUpdateRequest{})
		assert.Error(t, err)
		assert.Nil(t, project)
	})
}

func TestServiceDelete(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	t.Run("successfully deletes project", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{
			"id", "primary_owner_account_id", "name", "description",
			"venue", "environment_type", "project_phase", "application", "budget_amount",
			"currency", "created_at", "updated_at", "is_archived", "is_deleted",
		}).AddRow(
			testProjectID, 123, testProjectName, testProjectDesc,
			testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0,
			"USD", time.Now(), time.Now(), false, false,
		)

		mock.ExpectQuery(testSelectProjectsStmt).WillReturnRows(rows)
		mock.ExpectExec("UPDATE \"project\"").WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.Delete(ctx, testProjectID)
		assert.NoError(t, err)
	})

	t.Run("returns error when project ID is empty", func(t *testing.T) {
		err := service.Delete(ctx, "")
		assert.Error(t, err)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mock.ExpectQuery(testSelectProjectsStmt).WillReturnError(sql.ErrNoRows)

		err := service.Delete(ctx, "non-existent")
		assert.Error(t, err)
	})
}
