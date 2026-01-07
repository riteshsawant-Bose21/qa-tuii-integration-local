package db

import (
	"context"
	"database/sql"
	"errors"
	"testing"
	"time"

	"fusion-core/internal/api/types"
	"fusion-core/internal/fusion/model/models"

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
	testUserID1            = "user-123"
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

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		returnRows := sqlmock.NewRows([]string{"is_archived", "is_deleted", "locked_by_user_id"}).
			AddRow(false, false, nil)
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnRows(returnRows)

		id, err := service.Insert(ctx, project, testProjectAccountID, tx)
		assert.NoError(t, err)
		assert.Equal(t, testProjectID, id)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully inserts project with provided ID", func(t *testing.T) {
		projectID := "generated-uuid-123"
		project := &types.ProjectCreateRequest{
			ID:              projectID, // ID should be provided by business layer
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

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)

		returnRows := sqlmock.NewRows([]string{"is_archived", "is_deleted", "locked_by_user_id"}).
			AddRow(false, false, nil)
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnRows(returnRows)

		id, err := service.Insert(ctx, project, testProjectAccountID, tx)
		assert.NoError(t, err)
		assert.Equal(t, projectID, id)

		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("panics when project is nil", func(t *testing.T) {
		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)
		assert.Panics(t, func() {
			_, _ = service.Insert(ctx, nil, testProjectAccountID, tx)
		})
	})

	t.Run("rolls back transaction on project insert failure", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			ID:              testProjectID,
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

		mock.ExpectBegin()
		tx, err := db.BeginTx(ctx, nil)
		require.NoError(t, err)
		mock.ExpectQuery(`INSERT INTO "project"`).
			WillReturnError(assert.AnError)

		id, err := service.Insert(ctx, project, testProjectAccountID, tx)
		assert.Error(t, err)
		assert.Empty(t, id)
		assert.Contains(t, err.Error(), "failed to insert project")

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
			IsArchived: false,
			SortBy:     "created_at",
			SortOrder:  "asc",
		}

		userAuth := types.UserAuthorizationResponse{
			User: types.UserInfo{
				ID:    testProjectAccountID,
				Email: "test@example.com",
			},
			Account: types.AccountInfo{
				ID:   "test-account-id",
				Name: "Test Account",
			},
			Role: types.RoleInfo{
				RoleName: "User",
			},
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
		mock.ExpectQuery(`SELECT p\.id, p\.name, p\.description, p\.venue, p\.environment_type, p\.project_phase, p\.application, p\.budget_amount, p\.currency, p\.is_archived, p\.is_deleted, p\.locked_by_user_id, p\.created_at, p\.updated_at, pu\.is_starred, u\.email as locked_by_user_email FROM project p INNER JOIN project_user pu ON p\.id = pu\.project_id LEFT JOIN app_user u ON p\.locked_by_user_id = u\.id WHERE pu\.user_id = \$1 AND p\.is_archived = \$2 AND p\.is_deleted = \$3 ORDER BY p\.created_at ASC`).WillReturnRows(projectRows)

		projects, err := service.SelectAll(ctx, queryParams, userAuth)
		assert.NoError(t, err)
		assert.Len(t, projects, 1)
		assert.Equal(t, testProjectID, projects[0].ID)
		assert.False(t, projects[0].IsStarred) // Should be false from the mock data
	})

	t.Run("successfully retrieves starred projects", func(t *testing.T) {
		queryParams := &types.GetAllProjectsParams{
			IsArchived: false,
			SortBy:     "created_at",
			SortOrder:  "asc",
		}

		userAuth := types.UserAuthorizationResponse{
			User: types.UserInfo{
				ID:    testProjectAccountID,
				Email: "test@example.com",
			},
			Account: types.AccountInfo{
				ID:   "test-account-id",
				Name: "Test Account",
			},
			Role: types.RoleInfo{
				RoleName: "User",
			},
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
		mock.ExpectQuery(`SELECT p\.id, p\.name, p\.description, p\.venue, p\.environment_type, p\.project_phase, p\.application, p\.budget_amount, p\.currency, p\.is_archived, p\.is_deleted, p\.locked_by_user_id, p\.created_at, p\.updated_at, pu\.is_starred, u\.email as locked_by_user_email FROM project p INNER JOIN project_user pu ON p\.id = pu\.project_id LEFT JOIN app_user u ON p\.locked_by_user_id = u\.id WHERE pu\.user_id = \$1 AND p\.is_archived = \$2 AND p\.is_deleted = \$3 ORDER BY p\.created_at ASC`).WillReturnRows(projectRows)

		projects, err := service.SelectAll(ctx, queryParams, userAuth)
		assert.NoError(t, err)
		assert.Len(t, projects, 1)
		assert.Equal(t, testProjectID, projects[0].ID)
		assert.True(t, projects[0].IsStarred) // Should be true from the mock data
	})

	t.Run("handles empty result set correctly", func(t *testing.T) {
		queryParams := &types.GetAllProjectsParams{
			SortBy:     "created_at",
			SortOrder:  "ASC",
			IsArchived: false,
		}

		userAuth := types.UserAuthorizationResponse{
			User: types.UserInfo{
				ID:    testUserID1,
				Email: "test@example.com",
			},
			Account: types.AccountInfo{
				ID:   testProjectAccountID,
				Name: "Test Account",
			},
		}

		// Mock empty result set
		emptyRows := sqlmock.NewRows([]string{
			"id", "name", "description",
			"venue", "environment_type", "project_phase", "application", "budget_amount",
			"currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at", "is_starred", "locked_by_user_email",
		})
		mock.ExpectQuery(`SELECT p\.id, p\.name, p\.description, p\.venue, p\.environment_type, p\.project_phase, p\.application, p\.budget_amount, p\.currency, p\.is_archived, p\.is_deleted, p\.locked_by_user_id, p\.created_at, p\.updated_at, pu\.is_starred, u\.email as locked_by_user_email FROM project p INNER JOIN project_user pu ON p\.id = pu\.project_id LEFT JOIN app_user u ON p\.locked_by_user_id = u\.id WHERE pu\.user_id = \$1 AND p\.is_archived = \$2 AND p\.is_deleted = \$3 ORDER BY p\.created_at ASC`).WillReturnRows(emptyRows)

		projects, err := service.SelectAll(ctx, queryParams, userAuth)
		assert.NoError(t, err)
		assert.Len(t, projects, 0)
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

func TestService_ArchiveUnarchiveProject(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer func() { _ = db.Close() }()

	ctx := context.Background()

	t.Run("successfully archives a project", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, nil, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.ArchiveProject(ctx, testProjectID)
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("successfully unarchives a project", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", true, false, nil, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.UnarchiveProject(ctx, testProjectID)
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when archive fails", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, nil, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnError(errors.New("update failed"))

		err := service.ArchiveProject(ctx, testProjectID)
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("returns error when unarchive fails", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", true, false, nil, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnError(errors.New("update failed"))

		err := service.UnarchiveProject(ctx, testProjectID)
		assert.Error(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})
}

func TestService_UserStarLockFunctions(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer func() { _ = db.Close() }()

	ctx := context.Background()
	testUserID := "user-123"
	testEmail := "user@example.com"

	t.Run("assign user success", func(t *testing.T) {
		mock.ExpectQuery(`INSERT INTO "project_user"`).
			WillReturnRows(sqlmock.NewRows([]string{"id", "is_starred"}).
				AddRow(1, false))
		err := service.AssignUser(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("assign user duplicate key ignored", func(t *testing.T) {
		mock.ExpectQuery(`INSERT INTO "project_user"`).
			WillReturnError(errors.New("duplicate key value violates unique constraint"))
		err := service.AssignUser(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("remove user success", func(t *testing.T) {
		mock.ExpectExec(`DELETE FROM "project_user"`).
			WillReturnResult(sqlmock.NewResult(0, 1))
		err := service.RemoveUser(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
		assert.NoError(t, mock.ExpectationsWereMet())
	})

	t.Run("is user assigned true", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "project_user"`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))
		exists, err := service.IsUserAssigned(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
		assert.True(t, exists)
	})

	t.Run("is user assigned false", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "project_user"`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
		exists, err := service.IsUserAssigned(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
		assert.False(t, exists)
	})

	t.Run("project exists true", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "project"`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))
		exists, err := service.ProjectExists(ctx, testProjectID)
		assert.NoError(t, err)
		assert.True(t, exists)
	})

	t.Run("project exists false", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "project"`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
		exists, err := service.ProjectExists(ctx, testNonExistentID)
		assert.NoError(t, err)
		assert.False(t, exists)
	})

	t.Run("user exists true", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "app_user"`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))
		exists, err := service.UserExists(ctx, testUserID)
		assert.NoError(t, err)
		assert.True(t, exists)
	})

	t.Run("user exists false", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "app_user"`).
			WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))
		exists, err := service.UserExists(ctx, testUserID)
		assert.NoError(t, err)
		assert.False(t, exists)
	})

	t.Run("get user id by email success", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "app_user"\.\* FROM "app_user" WHERE \("app_user"\."email" = \$1\) LIMIT 1`).
			WithArgs(testEmail).
			WillReturnRows(sqlmock.NewRows([]string{"id", "email", "full_name", "password_hash", "role_id", "account_id", "created_at", "updated_at"}).
				AddRow(testUserID, testEmail, nil, nil, 1, 1, time.Now(), time.Now()))
		id, err := service.GetUserIDByEmail(ctx, testEmail)
		assert.NoError(t, err)
		assert.Equal(t, testUserID, id)
	})

	t.Run("get user id by email not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "app_user"\.\* FROM "app_user" WHERE \("app_user"\."email" = \$1\) LIMIT 1`).
			WithArgs(testEmail).
			WillReturnError(sql.ErrNoRows)
		id, err := service.GetUserIDByEmail(ctx, testEmail)
		assert.Error(t, err)
		assert.Empty(t, id)
	})

	t.Run("star project success", func(t *testing.T) {
		// Get project_user record
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "project_id", "user_id", "is_starred", "created_at", "updated_at"}).
				AddRow(1, testProjectID, testUserID, false, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project_user"`).
			WillReturnResult(sqlmock.NewResult(0, 1))
		err := service.StarProject(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
	})

	t.Run("unstar project success", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "project_id", "user_id", "is_starred", "created_at", "updated_at"}).
				AddRow(1, testProjectID, testUserID, true, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project_user"`).
			WillReturnResult(sqlmock.NewResult(0, 1))
		err := service.UnstarProject(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
	})

	t.Run("lock project success", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, nil, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnResult(sqlmock.NewResult(0, 1))
		err := service.LockProject(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
	})

	t.Run("unlock project success", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, testUserID, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnResult(sqlmock.NewResult(0, 1))
		err := service.UnlockProject(ctx, testProjectID)
		assert.NoError(t, err)
	})

	t.Run("get project lock user id locked", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, testUserID, time.Now(), time.Now()))
		locked, uid, err := service.GetProjectLockUserID(ctx, testProjectID)
		assert.NoError(t, err)
		assert.True(t, locked)
		assert.Equal(t, testUserID, uid)
	})

	t.Run("get project lock user id unlocked", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, nil, time.Now(), time.Now()))
		locked, uid, err := service.GetProjectLockUserID(ctx, testProjectID)
		assert.NoError(t, err)
		assert.False(t, locked)
		assert.Empty(t, uid)
	})

	t.Run("get user email by id success", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "app_user"\.\* FROM "app_user" WHERE \("app_user"\."id" = \$1\) LIMIT 1`).
			WithArgs(testUserID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "email", "full_name", "password_hash", "role_id", "account_id", "created_at", "updated_at"}).
				AddRow(testUserID, testEmail, nil, nil, 1, 1, time.Now(), time.Now()))
		email, err := service.GetUserEmailByID(ctx, testUserID)
		assert.NoError(t, err)
		assert.Equal(t, testEmail, email)
	})

	// Additional edge and error branch coverage

	t.Run("assign user other error returns error", func(t *testing.T) {
		mock.ExpectQuery(`INSERT INTO "project_user"`).
			WillReturnError(errors.New("some other db error"))
		err := service.AssignUser(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("remove user failure", func(t *testing.T) {
		mock.ExpectExec(`DELETE FROM "project_user"`).
			WillReturnError(errors.New("delete failed"))
		err := service.RemoveUser(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("is user assigned query error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "project_user"`).
			WillReturnError(errors.New("count error"))
		exists, err := service.IsUserAssigned(ctx, testProjectID, testUserID)
		assert.Error(t, err)
		assert.False(t, exists)
	})

	t.Run("project exists query error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "project"`).
			WillReturnError(errors.New("count error"))
		exists, err := service.ProjectExists(ctx, testProjectID)
		assert.Error(t, err)
		assert.False(t, exists)
	})

	t.Run("user exists query error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT COUNT\(\*\) FROM "app_user"`).
			WillReturnError(errors.New("count error"))
		exists, err := service.UserExists(ctx, testUserID)
		assert.Error(t, err)
		assert.False(t, exists)
	})
	t.Run("get user id by email generic error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "app_user"\.\* FROM "app_user" WHERE \("app_user"\."email" = \$1\) LIMIT 1`).
			WithArgs(testEmail).
			WillReturnError(errors.New("query failed"))
		id, err := service.GetUserIDByEmail(ctx, testEmail)
		assert.Error(t, err)
		assert.Empty(t, id)
	})
	t.Run("star project already starred no update", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "project_id", "user_id", "is_starred", "created_at", "updated_at"}).
				AddRow(2, testProjectID, testUserID, true, time.Now(), time.Now()))
		err := service.StarProject(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
	})

	t.Run("star project query error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnError(errors.New("select failed"))
		err := service.StarProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("star project update error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "project_id", "user_id", "is_starred", "created_at", "updated_at"}).
				AddRow(3, testProjectID, testUserID, false, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project_user"`).
			WillReturnError(errors.New("update failed"))
		err := service.StarProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("unstar project already unstarred no update", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "project_id", "user_id", "is_starred", "created_at", "updated_at"}).
				AddRow(4, testProjectID, testUserID, false, time.Now(), time.Now()))
		err := service.UnstarProject(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
	})

	t.Run("unstar project query error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnError(errors.New("select failed"))
		err := service.UnstarProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("unstar project update error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project_user"\.\* FROM "project_user" WHERE \("project_user"\."project_id" = \$1\) AND \("project_user"\."user_id" = \$2\) LIMIT 1`).
			WithArgs(testProjectID, testUserID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "project_id", "user_id", "is_starred", "created_at", "updated_at"}).
				AddRow(5, testProjectID, testUserID, true, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project_user"`).
			WillReturnError(errors.New("update failed"))
		err := service.UnstarProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("archive project already archived no update", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", true, false, nil, time.Now(), time.Now()))
		err := service.ArchiveProject(ctx, testProjectID)
		assert.NoError(t, err)
	})

	t.Run("archive project not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(sql.ErrNoRows)
		err := service.ArchiveProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("archive project fetch error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(errors.New("fetch failed"))
		err := service.ArchiveProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("unarchive project already unarchived no update", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, nil, time.Now(), time.Now()))
		err := service.UnarchiveProject(ctx, testProjectID)
		assert.NoError(t, err)
	})

	t.Run("unarchive project not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(sql.ErrNoRows)
		err := service.UnarchiveProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("unarchive project fetch error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(errors.New("fetch failed"))
		err := service.UnarchiveProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("lock project already locked same user", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, testUserID, time.Now(), time.Now()))
		err := service.LockProject(ctx, testProjectID, testUserID)
		assert.NoError(t, err)
	})

	t.Run("lock project locked by different user returns error", func(t *testing.T) {
		otherUser := "other-user"
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, otherUser, time.Now(), time.Now()))
		err := service.LockProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("lock project not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(sql.ErrNoRows)
		err := service.LockProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("lock project fetch error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(errors.New("fetch failed"))
		err := service.LockProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("lock project update error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, nil, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnError(errors.New("update failed"))
		err := service.LockProject(ctx, testProjectID, testUserID)
		assert.Error(t, err)
	})

	t.Run("unlock project not locked returns nil", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, nil, time.Now(), time.Now()))
		err := service.UnlockProject(ctx, testProjectID)
		assert.NoError(t, err)
	})

	t.Run("unlock project locked by different user returns error", func(t *testing.T) {
		otherUser := "other-user"
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, otherUser, time.Now(), time.Now()))
		err := service.UnlockProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("unlock project not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(sql.ErrNoRows)
		err := service.UnlockProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("unlock project fetch error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(errors.New("fetch failed"))
		err := service.UnlockProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("unlock project update error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnRows(sqlmock.NewRows([]string{"id", "primary_owner_user_id", "name", "description", "venue", "environment_type", "project_phase", "application", "budget_amount", "currency", "is_archived", "is_deleted", "locked_by_user_id", "created_at", "updated_at"}).
				AddRow(testProjectID, testProjectAccountID, testProjectName, testProjectDesc, testProjectVenue, string(testProjectEnvType), string(testProjectPhase), testProjectApp, 1000.0, "USD", false, false, testUserID, time.Now(), time.Now()))
		mock.ExpectExec(`UPDATE "project"`).
			WillReturnError(errors.New("update failed"))
		err := service.UnlockProject(ctx, testProjectID)
		assert.Error(t, err)
	})

	t.Run("get project lock user id not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(sql.ErrNoRows)
		locked, uid, err := service.GetProjectLockUserID(ctx, testProjectID)
		assert.Error(t, err)
		assert.False(t, locked)
		assert.Empty(t, uid)
	})

	t.Run("get project lock user id fetch error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "project"\.\* FROM "project" WHERE \("project"\."id" = \$1\) LIMIT 1`).
			WithArgs(testProjectID).
			WillReturnError(errors.New("fetch failed"))
		locked, uid, err := service.GetProjectLockUserID(ctx, testProjectID)
		assert.Error(t, err)
		assert.False(t, locked)
		assert.Empty(t, uid)
	})

	t.Run("get user email by id not found", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "app_user"\.\* FROM "app_user" WHERE \("app_user"\."id" = \$1\) LIMIT 1`).
			WithArgs(testUserID).
			WillReturnError(sql.ErrNoRows)
		email, err := service.GetUserEmailByID(ctx, testUserID)
		assert.Error(t, err)
		assert.Empty(t, email)
	})

	t.Run("get user email by id fetch error", func(t *testing.T) {
		mock.ExpectQuery(`SELECT "app_user"\.\* FROM "app_user" WHERE \("app_user"\."id" = \$1\) LIMIT 1`).
			WithArgs(testUserID).
			WillReturnError(errors.New("fetch failed"))
		email, err := service.GetUserEmailByID(ctx, testUserID)
		assert.Error(t, err)
		assert.Empty(t, email)
	})
}
