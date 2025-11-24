package db

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/DATA-DOG/go-sqlmock"
	"github.com/aarondl/null/v8"
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
	testUpdateProjectStmt  = "UPDATE \"project\""
	testNonExistentID      = "non-existent"
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
	defer func() {
		if err := db.Close(); err != nil {
			t.Logf("failed to close db: %v", err)
		}
	}()

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

	t.Run("successfully inserts project with provided ID", func(t *testing.T) {
		projectID := "generated-uuid-123"
		project := &types.ProjectCreateRequest{
			ID:              projectID, // ID should be provided by business layer
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
		assert.Equal(t, projectID, id)

		// Verify all expectations were met
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("panics when project is nil", func(t *testing.T) {
		assert.Panics(t, func() {
			_, _ = service.Insert(ctx, nil)
		})
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
	defer func() {
		if err := db.Close(); err != nil {
			t.Logf("failed to close db: %v", err)
		}
	}()

	ctx := context.Background()

	t.Run("successfully retrieves all projects", func(t *testing.T) {
		queryParams := &types.GetAllProjectsParams{
			UserID:     testProjectAccountID,
			IsArchived: false,
			SortBy:     "created_at",
			SortOrder:  "asc",
		}

		// Mock the new raw SQL query with joined data (without primary_owner_user_id)
		projectRows := sqlmock.NewRows([]string{
			"id", "name", "description",
			"venue", "environment_type", "project_phase", "application", "budget_amount",
			"currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at", "is_starred", "locked_by_user_email",
		}).AddRow(
			testProjectID, testProjectName, testProjectDesc,
			testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0,
			"USD", false, false, nil, time.Now(), time.Now(), false, nil,
		)
		mock.ExpectQuery(`SELECT p\.id, p\.name, p\.description, p\.venue, p\.environment_type, p\.project_phase, p\.application, p\.budget_amount, p\.currency, p\.is_archived, p\.is_deleted, p\.locked_by_user_id, p\.created_at, p\.updated_at, pu\.is_starred, u\.email as locked_by_user_email FROM project p INNER JOIN project_user pu ON p\.id = pu\.project_id LEFT JOIN "user" u ON p\.locked_by_user_id = u\.id WHERE pu\.user_id = \$1 AND p\.is_archived = \$2 AND p\.is_deleted = \$3 ORDER BY p\.created_at ASC`).WillReturnRows(projectRows)

		projects, err := service.SelectAll(ctx, queryParams)
		assert.NoError(t, err)
		assert.Len(t, projects, 1)
		assert.Equal(t, testProjectID, projects[0].ID)
		assert.False(t, projects[0].IsStarred) // Should be false from the mock data
	})

	t.Run("successfully retrieves starred projects", func(t *testing.T) {
		queryParams := &types.GetAllProjectsParams{
			UserID:     testProjectAccountID,
			IsArchived: false,
			SortBy:     "created_at",
			SortOrder:  "asc",
		}

		// Mock the new raw SQL query with joined data and is_starred = true (without primary_owner_user_id)
		projectRows := sqlmock.NewRows([]string{
			"id", "name", "description",
			"venue", "environment_type", "project_phase", "application", "budget_amount",
			"currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at", "is_starred", "locked_by_user_email",
		}).AddRow(
			testProjectID, testProjectName, testProjectDesc,
			testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0,
			"USD", false, false, nil, time.Now(), time.Now(), true, nil, // is_starred = true
		)
		mock.ExpectQuery(`SELECT p\.id, p\.name, p\.description, p\.venue, p\.environment_type, p\.project_phase, p\.application, p\.budget_amount, p\.currency, p\.is_archived, p\.is_deleted, p\.locked_by_user_id, p\.created_at, p\.updated_at, pu\.is_starred, u\.email as locked_by_user_email FROM project p INNER JOIN project_user pu ON p\.id = pu\.project_id LEFT JOIN "user" u ON p\.locked_by_user_id = u\.id WHERE pu\.user_id = \$1 AND p\.is_archived = \$2 AND p\.is_deleted = \$3 ORDER BY p\.created_at ASC`).WillReturnRows(projectRows)

		projects, err := service.SelectAll(ctx, queryParams)
		assert.NoError(t, err)
		assert.Len(t, projects, 1)
		assert.Equal(t, testProjectID, projects[0].ID)
		assert.True(t, projects[0].IsStarred) // Should be true from the mock data
	})
}

func TestServiceGetProjectByID(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer func() {
		if err := db.Close(); err != nil {
			t.Logf("failed to close db: %v", err)
		}
	}()

	ctx := context.Background()

	t.Run("successfully retrieves project by ID", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{
			"id", "primary_owner_user_id", "name", "description",
			"venue", "environment_type", "project_phase", "application", "budget_amount",
			"currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at",
		}).AddRow(
			testProjectID, testProjectAccountID, testProjectName, testProjectDesc,
			testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0,
			"USD", false, false, nil, time.Now(), time.Now(),
		)

		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).WillReturnRows(rows)

		project, err := service.GetProjectByID(ctx, testProjectID)
		assert.NoError(t, err)
		assert.NotNil(t, project)
		assert.Equal(t, testProjectID, project.ID)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).WillReturnError(sql.ErrNoRows)

		project, err := service.GetProjectByID(ctx, testNonExistentID)
		assert.Error(t, err)
		assert.Nil(t, project)
		assert.Contains(t, err.Error(), "project not found")
	})

	t.Run("returns error on database error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).WillReturnError(assert.AnError)

		project, err := service.GetProjectByID(ctx, testProjectID)
		assert.Error(t, err)
		assert.Nil(t, project)
		assert.Contains(t, err.Error(), "failed to get project")
	})
}

func TestServiceUpdate(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer func() {
		if err := db.Close(); err != nil {
			t.Logf("failed to close db: %v", err)
		}
	}()

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

		// Create a project model to pass to Update
		projectRow := &models.Project{
			ID:          testProjectID,
			Name:        null.NewString(testProjectName, true),
			Description: null.NewString(testProjectDesc, true),
			Venue:       null.NewString(testProjectVenue, true),
			IsArchived:  false,
			IsDeleted:   false,
			CreatedAt:   time.Now(),
			UpdatedAt:   time.Now(),
		}

		mock.ExpectExec(testUpdateProjectStmt).WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.Update(ctx, projectRow, updateReq)
		assert.NoError(t, err)
	})

	t.Run("returns error when update fails", func(t *testing.T) {
		projectRow := &models.Project{
			ID:         testNonExistentID,
			IsArchived: false,
			IsDeleted:  false,
		}

		mock.ExpectExec(testUpdateProjectStmt).WillReturnError(sql.ErrNoRows)

		err := service.Update(ctx, projectRow, &types.ProjectUpdateRequest{})
		assert.Error(t, err)
	})
}

func TestServiceDelete(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer func() {
		if err := db.Close(); err != nil {
			t.Logf("failed to close db: %v", err)
		}
	}()

	ctx := context.Background()

	t.Run("successfully deletes project", func(t *testing.T) {
		projectRow := &models.Project{
			ID:        testProjectID,
			IsDeleted: false,
			CreatedAt: time.Now(),
			UpdatedAt: time.Now(),
		}

		mock.ExpectExec(testUpdateProjectStmt).WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.Delete(ctx, projectRow)
		assert.NoError(t, err)
	})

	t.Run("returns error when delete fails", func(t *testing.T) {
		projectRow := &models.Project{
			ID:        testProjectID,
			IsDeleted: false,
		}

		mock.ExpectExec(testUpdateProjectStmt).WillReturnError(sql.ErrNoRows)

		err := service.Delete(ctx, projectRow)
		assert.Error(t, err)
	})

	t.Run("returns error when project update fails", func(t *testing.T) {
		projectRow := &models.Project{
			ID:        testNonExistentID,
			IsDeleted: false,
		}

		mock.ExpectExec(testUpdateProjectStmt).WillReturnError(assert.AnError)

		err := service.Delete(ctx, projectRow)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "failed to delete project")
	})
}
