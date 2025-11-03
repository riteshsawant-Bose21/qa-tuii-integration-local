package db

import (
	"context"
	"database/sql"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/DATA-DOG/go-sqlmock"
	"github.com/aarondl/null/v8"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	testProjectID          = "test-id"
	testProjectName        = "Test Project"
	testProjectDesc        = "Test Description"
	testProjectVenue       = "Test Venue"
	testProjectEnvType     = "Indoor"
	testProjectApp         = "Test App"
	testProjectAccountID   = "123"
	testSelectProjectsStmt = "SELECT .*"
)

func setupTestDB(t *testing.T) (*sql.DB, sqlmock.Sqlmock, *Service) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)

	service := NewService(db)
	return db, mock, service
}

func TestNewService(t *testing.T) {
	t.Run("successfully creates new service", func(t *testing.T) {
		db, _, _ := sqlmock.New()
		service := NewService(db)
		assert.NotNil(t, service)
	})

	t.Run("panics when db is nil", func(t *testing.T) {
		assert.Panics(t, func() {
			NewService(nil)
		})
	})
}

func TestServiceInsert(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	t.Run("successfully inserts project", func(t *testing.T) {
		project := &fusion.ProjectCreateRequest{
			ID:              testProjectID,
			AccountID:       testProjectAccountID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Venue:           testProjectVenue,
			EnvironmentType: testProjectEnvType,
			Application:     testProjectApp,
			Budget: fusion.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		mock.ExpectExec("INSERT INTO \"projects\"").
			WithArgs(
				project.ID,
				123,
				null.NewString(project.Name, true),
				null.NewString(project.Description, true),
				null.NewString(project.Venue, true),
				null.NewString(project.EnvironmentType, true),
				null.NewString(project.Application, true),
				project.Budget.Amount,
				null.NewString(project.Budget.Currency, true),
				sqlmock.AnyArg(),
				sqlmock.AnyArg(),
				false,
				false,
			).WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.Insert(ctx, project)
		assert.NoError(t, err)
	})

	t.Run("returns error when project is nil", func(t *testing.T) {
		err := service.Insert(ctx, nil)
		assert.Error(t, err)
	})

	t.Run("returns error when account ID is invalid", func(t *testing.T) {
		project := &fusion.ProjectCreateRequest{
			AccountID: "invalid",
		}
		err := service.Insert(ctx, project)
		assert.Error(t, err)
	})
}

func TestServiceSelectAll(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	t.Run("successfully retrieves all projects", func(t *testing.T) {
		queryParams := &fusion.GetAllProjectsParams{
			IsArchived: false,
			SortBy:     "created_at",
			SortOrder:  "asc",
		}

		rows := sqlmock.NewRows([]string{
			"id", "primary_owner_account_id", "name", "description",
			"venue", "environment_type", "application", "budget_amount",
			"currency", "created_at", "updated_at", "is_archived", "is_deleted",
		}).AddRow(
			testProjectID, 123, testProjectName, testProjectDesc,
			testProjectVenue, testProjectEnvType, testProjectApp, 1000.0,
			"USD", time.Now(), time.Now(), false, false,
		)

		mock.ExpectQuery(testSelectProjectsStmt).WillReturnRows(rows)

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
		updateReq := &fusion.ProjectUpdateRequest{
			AccountID:   testProjectAccountID,
			Name:        "Updated Project",
			Description: "Updated Description",
			Venue:       "Updated Venue",
			IsArchived:  true,
			Budget: fusion.Budget{
				Amount:   2000,
				Currency: "EUR",
			},
		}

		rows := sqlmock.NewRows([]string{
			"id", "primary_owner_account_id", "name", "description",
			"venue", "environment_type", "application", "budget_amount",
			"currency", "created_at", "updated_at", "is_archived", "is_deleted",
		}).AddRow(
			testProjectID, 123, testProjectName, testProjectDesc,
			testProjectVenue, testProjectEnvType, testProjectApp, 1000.0,
			"USD", time.Now(), time.Now(), false, false,
		)

		mock.ExpectQuery(testSelectProjectsStmt).WillReturnRows(rows)
		mock.ExpectExec("UPDATE \"projects\"").WillReturnResult(sqlmock.NewResult(1, 1))

		err := service.Update(ctx, testProjectID, updateReq)
		assert.NoError(t, err)
	})

	t.Run("returns error when project not found", func(t *testing.T) {
		mock.ExpectQuery(testSelectProjectsStmt).WillReturnError(sql.ErrNoRows)

		err := service.Update(ctx, "non-existent", &fusion.ProjectUpdateRequest{})
		assert.Error(t, err)
	})
}

func TestServiceDelete(t *testing.T) {
	db, mock, service := setupTestDB(t)
	defer db.Close()

	ctx := context.Background()

	t.Run("successfully deletes project", func(t *testing.T) {
		rows := sqlmock.NewRows([]string{
			"id", "primary_owner_account_id", "name", "description",
			"venue", "environment_type", "application", "budget_amount",
			"currency", "created_at", "updated_at", "is_archived", "is_deleted",
		}).AddRow(
			testProjectID, 123, testProjectName, testProjectDesc,
			testProjectVenue, testProjectEnvType, testProjectApp, 1000.0,
			"USD", time.Now(), time.Now(), false, false,
		)

		mock.ExpectQuery(testSelectProjectsStmt).WillReturnRows(rows)
		mock.ExpectExec("UPDATE \"projects\"").WillReturnResult(sqlmock.NewResult(1, 1))

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
