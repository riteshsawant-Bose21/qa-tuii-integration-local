package project

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/DATA-DOG/go-sqlmock"
	"github.com/aarondl/null/v8"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

const (
	databaseErrorMsg = "database error"
)

var (
	errDatabaseMsg = errors.New(databaseErrorMsg)
)

const (
	testProjectID1     = "project-1"
	testUserID1        = "user-1"
	projectNotFoundMsg = "project not found"
)

const (
	updatedProjectName = "Updated Project"
)

type mockDBService struct {
	mock.Mock
}

// mockDBWithTransactions implements model.DBWithTransactions for testing using sqlmock
type mockDBWithTransactions struct {
	*sql.DB
	mock sqlmock.Sqlmock
}

func newMockDBWithTransactions() (*mockDBWithTransactions, sqlmock.Sqlmock, error) {
	db, mock, err := sqlmock.New()
	if err != nil {
		return nil, nil, err
	}
	return &mockDBWithTransactions{DB: db, mock: mock}, mock, nil
}

// No need to override the database methods - sql.DB with sqlmock handles everything

func (m *mockDBService) GetDB(ctx context.Context) model.DBWithTransactions {
	args := m.Called(ctx)
	return args.Get(0).(model.DBWithTransactions)
}
func (m *mockDBService) InsertProjectUser(ctx context.Context, projectID, userID string, tx model.DBTxExecutor, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userID, tx, logger)
	return args.Error(0)
}

// Satisfy DatabaseService interface for tests
func (m *mockDBService) Insert(ctx context.Context, project *types.ProjectCreateRequest, accountID string, tx model.DBTxExecutor, logger *zap.Logger) (string, error) {
	args := m.Called(ctx, project, accountID, tx, logger)
	return args.String(0), args.Error(1)
}

func (m *mockDBService) SelectAll(ctx context.Context, params *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse, logger *zap.Logger) ([]types.Project, error) {
	args := m.Called(ctx, params, userAuth, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]types.Project), args.Error(1)
}

func (m *mockDBService) Update(ctx context.Context, projectRow *models.Project, project *types.ProjectUpdateRequest, logger *zap.Logger) error {
	args := m.Called(ctx, projectRow, project, logger)
	return args.Error(0)
}

func (m *mockDBService) Delete(ctx context.Context, projectRow *models.Project, logger *zap.Logger) error {
	args := m.Called(ctx, projectRow, logger)
	return args.Error(0)
}

func (m *mockDBService) AssignUser(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userID, logger)
	return args.Error(0)
}

func (m *mockDBService) RemoveUser(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	result := m.Called(ctx, projectID, userID, logger)
	return result.Error(0)
}

func (m *mockDBService) IsUserAssigned(ctx context.Context, projectID, userID string, logger *zap.Logger) (bool, error) {
	args := m.Called(ctx, projectID, userID, logger)
	return args.Bool(0), args.Error(1)
}

func (m *mockDBService) ProjectExists(ctx context.Context, projectID string, logger *zap.Logger) (bool, error) {
	args := m.Called(ctx, projectID, logger)
	return args.Bool(0), args.Error(1)
}

func (m *mockDBService) UserExists(ctx context.Context, userID string, logger *zap.Logger) (bool, error) {
	args := m.Called(ctx, userID, logger)
	return args.Bool(0), args.Error(1)
}

func (m *mockDBService) GetUserIDByEmail(ctx context.Context, email string, logger *zap.Logger) (string, error) {
	args := m.Called(ctx, email, logger)
	return args.String(0), args.Error(1)
}

func (m *mockDBService) GetProjectByID(ctx context.Context, projectID string, logger *zap.Logger) (*models.Project, error) {
	args := m.Called(ctx, projectID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Project), args.Error(1)
}

func (m *mockDBService) SelectByID(ctx context.Context, projectID string, userID string, logger *zap.Logger) (*types.Project, error) {
	args := m.Called(ctx, projectID, userID, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.Project), args.Error(1)
}

func (m *mockDBService) StarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userID, logger)
	return args.Error(0)
}

func (m *mockDBService) UnstarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userID, logger)
	return args.Error(0)
}

func (m *mockDBService) ArchiveProject(ctx context.Context, projectID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, logger)
	return args.Error(0)
}

func (m *mockDBService) UnarchiveProject(ctx context.Context, projectID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, logger)
	return args.Error(0)
}

func (m *mockDBService) LockProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userID, logger)
	return args.Error(0)
}

func (m *mockDBService) UnlockProject(ctx context.Context, projectID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, logger)
	return args.Error(0)
}

func (m *mockDBService) GetProjectLockUserID(ctx context.Context, projectID string) (bool, string, error) {
	args := m.Called(ctx, projectID)
	return args.Bool(0), args.String(1), args.Error(2)
}

func (m *mockDBService) GetUserEmailByID(ctx context.Context, userID string) (string, error) {
	args := m.Called(ctx, userID)
	return args.String(0), args.Error(1)
}

type mockPresigner struct {
	mock.Mock
}

func (m *mockPresigner) PresignGet(ctx context.Context, key string, ttl time.Duration, logger *zap.Logger) (string, error) {
	args := m.Called(ctx, key, ttl, logger)
	return args.String(0), args.Error(1)
}

func (m *mockPresigner) PresignPut(ctx context.Context, key string, ttl time.Duration, logger *zap.Logger) (string, error) {
	args := m.Called(ctx, key, ttl, logger)
	return args.String(0), args.Error(1)
}

func TestCreateProject(t *testing.T) {
	tests := []struct {
		name            string
		project         *types.ProjectCreateRequest
		mockID          string
		mockErr         error
		expectedID      string
		expectedErr     error
		expectResponse  bool
		presignFileURL  string
		presignThumbURL string
		presignFileErr  error
		presignThumbErr error
	}{
		{
			name: "successful creation",
			project: &types.ProjectCreateRequest{
				Name: "Test Project",
			},
			mockID:         "123e4567-e89b-12d3-a456-426614174000",
			mockErr:        nil,
			expectedID:     "123e4567-e89b-12d3-a456-426614174000",
			expectedErr:    nil,
			expectResponse: true,
		},
		{
			name: "database error",
			project: &types.ProjectCreateRequest{
				Name: "Test Project",
			},
			mockID:         "",
			mockErr:        errDatabaseMsg,
			expectedID:     "",
			expectedErr:    fmt.Errorf("failed to insert project: %v", errDatabaseMsg),
			expectResponse: false,
		},
		{
			name: "creation with file & thumbnail URLs",
			project: &types.ProjectCreateRequest{
				Name:                      "Project With Files",
				IsProjectFileCreated:      true,
				IsProjectThumbnailCreated: true,
			},
			mockID:          "123e4567-e89b-12d3-a456-426614174001",
			mockErr:         nil,
			expectedID:      "123e4567-e89b-12d3-a456-426614174001",
			expectedErr:     nil,
			expectResponse:  true,
			presignFileURL:  "https://put-file-url",
			presignThumbURL: "https://put-thumb-url",
			presignFileErr:  nil,
			presignThumbErr: nil,
		},
		{
			name: "creation presign file error",
			project: &types.ProjectCreateRequest{
				Name:                 "Project With File Error",
				IsProjectFileCreated: true,
			},
			mockID:         "123e4567-e89b-12d3-a456-426614174002",
			mockErr:        nil,
			expectedID:     "",
			expectedErr:    fmt.Errorf("failed to generate presign URL: %v", errors.New("put error")),
			expectResponse: false,
			presignFileURL: "",
			presignFileErr: errors.New("put error"),
		},
		{
			name: "transaction rollback on user assignment failure",
			project: &types.ProjectCreateRequest{
				Name: "Project With User Assignment Error",
			},
			mockID:         "123e4567-e89b-12d3-a456-426614174003",
			mockErr:        nil,
			expectedID:     "",
			expectedErr:    fmt.Errorf("failed to insert project: %v", errors.New("user assignment failed")),
			expectResponse: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Create a mock database connection with transaction support
			dbWithTx, sqlMock, err := newMockDBWithTransactions()
			if err != nil {
				t.Fatalf("Failed to create mock DB: %v", err)
			}
			defer func() {
				if err := dbWithTx.Close(); err != nil {
					t.Logf("Failed to close test database: %v", err)
				}
			}()

			// Set up sqlmock expectations for transaction flow
			if tt.mockErr == nil {
				// Expect successful transaction
				sqlMock.ExpectBegin()
				sqlMock.ExpectCommit()
			} else {
				// Expect transaction that will be rolled back
				sqlMock.ExpectBegin()
				sqlMock.ExpectRollback()
			}

			// Mock the GetDB call to return our mock database
			mockDB.On("GetDB", mock.Anything).Return(dbWithTx)

			// Mock GetProjectByID call - should return nil (not found) for new projects
			mockDB.On("GetProjectByID", mock.Anything, tt.project.ID, mock.AnythingOfType("*zap.Logger")).Return(nil, errors.New("not found"))

			// Mock Insert call with accountID parameter
			mockDB.On("Insert", mock.Anything, tt.project, "test-account-id", mock.Anything, mock.AnythingOfType("*zap.Logger")).Return(tt.mockID, tt.mockErr)
			// Always expect InsertProjectUser to be called if Insert succeeds
			if tt.mockErr == nil {
				// Special case for user assignment failure test
				if tt.name == "transaction rollback on user assignment failure" {
					mockDB.On("InsertProjectUser", mock.Anything, tt.mockID, "test-user-id", mock.Anything, mock.AnythingOfType("*zap.Logger")).Return(errors.New("user assignment failed"))
				} else {
					mockDB.On("InsertProjectUser", mock.Anything, tt.mockID, "test-user-id", mock.Anything, mock.AnythingOfType("*zap.Logger")).Return(nil)
					// Presign expectations when flags set
					if tt.project.IsProjectFileCreated {
						mockPresigner.On("PresignPut", mock.Anything, fmt.Sprintf("projects/%s/projectFile/%s.zip", tt.mockID, tt.mockID), time.Minute*15, mock.Anything).Return(tt.presignFileURL, tt.presignFileErr)
					}
					if tt.project.IsProjectThumbnailCreated {
						mockPresigner.On("PresignPut", mock.Anything, fmt.Sprintf("projects/%s/projectThumbnail/%s.zip", tt.mockID, tt.mockID), time.Minute*15, mock.Anything).Return(tt.presignThumbURL, tt.presignThumbErr)
					}
				}
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Create test user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    "test-user-id",
					Email: "test@example.com",
				},
				Account: types.AccountInfo{
					ID:   "test-account-id",
					Name: "Test Account",
				},
			}

			logger, _ := zap.NewProduction()
			response, err := service.CreateProject(context.Background(), tt.project, userAuth, logger)
			if tt.expectedErr != nil {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr.Error())
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				if tt.expectResponse {
					assert.NotNil(t, response)
					assert.Equal(t, tt.expectedID, response.ID)
					if tt.project.IsProjectFileCreated {
						assert.Equal(t, tt.presignFileURL, *response.ProjectUploadURL)
					}
					if tt.project.IsProjectThumbnailCreated {
						assert.Equal(t, tt.presignThumbURL, *response.ThumbnailUploadURL)
					}
				}
			}
			mockDB.AssertExpectations(t)
		})
	}
}

func TestGetAllProjects(t *testing.T) {
	mockProjects := []types.Project{
		{
			ID:   "1",
			Name: "Project 1",
		},
		{
			ID:   "2",
			Name: "Project 2",
		},
	}

	tests := []struct {
		name           string
		params         *types.GetAllProjectsParams
		mockProjects   []types.Project
		mockDBErr      error
		mockPresignURL string
		mockPresignErr error
		expectedErr    error
	}{
		{
			name:           "successful retrieval",
			params:         &types.GetAllProjectsParams{},
			mockProjects:   mockProjects,
			mockDBErr:      nil,
			mockPresignURL: "https://presigned-url",
			mockPresignErr: nil,
			expectedErr:    nil,
		},
		{
			name:           "database error",
			params:         &types.GetAllProjectsParams{},
			mockProjects:   nil,
			mockDBErr:      errDatabaseMsg,
			mockPresignURL: "",
			mockPresignErr: nil,
			expectedErr:    errDatabaseMsg,
		},
		{
			name:           "presign error",
			params:         &types.GetAllProjectsParams{},
			mockProjects:   mockProjects,
			mockDBErr:      nil,
			mockPresignURL: "",
			mockPresignErr: fmt.Errorf("presign error"),
			expectedErr:    fmt.Errorf("failed to generate presign URL for project 1: presign error"),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    "test-user-id",
					Email: "test@example.com",
				},
				Account: types.AccountInfo{
					ID:   "test-account-id",
					Name: "Test Account",
				},
			}
			mockDB.On("SelectAll", mock.Anything, tt.params, userAuth, mock.AnythingOfType("*zap.Logger")).Return(tt.mockProjects, tt.mockDBErr)
			if tt.mockDBErr == nil {
				for _, p := range tt.mockProjects {
					// Mock project file URL generation
					mockPresigner.On("PresignGet",
						mock.Anything,
						fmt.Sprintf("projects/%s/projectFile/%s.zip", p.ID, p.ID),
						time.Minute*5,
						mock.Anything,
					).Return(tt.mockPresignURL, tt.mockPresignErr).Maybe()

					// Mock thumbnail URL generation
					mockPresigner.On("PresignGet",
						mock.Anything,
						fmt.Sprintf("projects/%s/projectThumbnail/%s.zip", p.ID, p.ID),
						time.Minute*5,
						mock.Anything,
					).Return(tt.mockPresignURL, tt.mockPresignErr).Maybe()
				}
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			logger, _ := zap.NewProduction()
			response, err := service.GetAllProjects(context.Background(), tt.params, userAuth, logger)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, response)
				assert.Equal(t, len(tt.mockProjects), len(response.Data))
				assert.Equal(t, len(tt.mockProjects), response.TotalCount)
				assert.Equal(t, 1, response.Page)
				assert.Equal(t, 1, response.TotalPages)
				for i, p := range response.Data {
					if p.ProjectFileURL != nil {
						assert.Equal(t, tt.mockPresignURL, *p.ProjectFileURL)
					}
					if p.ThumbnailURL != nil {
						assert.Equal(t, tt.mockPresignURL, *p.ThumbnailURL)
					}
					assert.Equal(t, tt.mockProjects[i].ID, p.ID)
				}
			}

			mockDB.AssertExpectations(t)
			mockPresigner.AssertExpectations(t)
		})
	}
}

func TestUpdateProject(t *testing.T) {
	mockProjectRow := &models.Project{
		ID:                    "1",
		PrimaryOwnerAccountID: "123",
		Name:                  null.NewString(updatedProjectName, true),
		IsArchived:            false,
		IsDeleted:             false,
	}

	tests := []struct {
		name           string
		id             string
		project        *types.ProjectUpdateRequest
		mockProjectRow *models.Project
		mockErr        error
		expectedErr    error
	}{
		{
			name: "successful update",
			id:   "1",
			project: &types.ProjectUpdateRequest{
				Name: updatedProjectName,
			},
			mockProjectRow: mockProjectRow,
			mockErr:        nil,
			expectedErr:    nil,
		},
		{
			name: "database error",
			id:   "1",
			project: &types.ProjectUpdateRequest{
				Name: updatedProjectName,
			},
			mockProjectRow: nil,
			mockErr:        errDatabaseMsg,
			expectedErr:    errDatabaseMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			if tt.mockProjectRow != nil {
				// Mock GetProjectByID call - successful case
				mockDB.On("GetProjectByID", mock.Anything, tt.id, mock.AnythingOfType("*zap.Logger")).Return(tt.mockProjectRow, nil)
				// Mock IsUserAssigned call
				mockDB.On("IsUserAssigned", mock.Anything, tt.id, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
				// Mock Update call
				mockDB.On("Update", mock.Anything, tt.mockProjectRow, tt.project, mock.AnythingOfType("*zap.Logger")).Return(tt.mockErr)
			} else {
				// Mock GetProjectByID call - error case
				mockDB.On("GetProjectByID", mock.Anything, tt.id, mock.AnythingOfType("*zap.Logger")).Return(nil, tt.mockErr)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Set the project ID on the request
			tt.project.ID = tt.id

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			logger, _ := zap.NewProduction()
			response, err := service.UpdateProject(context.Background(), tt.project, userAuth, logger)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, response)
			}
			mockDB.AssertExpectations(t)
		})
	}
}

func TestUpdateProjectPresignURLs(t *testing.T) {
	mockProjectRow := &models.Project{ID: "u1", IsArchived: false, IsDeleted: false}
	tests := []struct {
		name            string
		req             *types.ProjectUpdateRequest
		presignFileURL  string
		presignThumbURL string
		presignFileErr  error
		presignThumbErr error
		expectedErr     string
	}{
		{name: "dirty flags success", req: &types.ProjectUpdateRequest{IsProjectFileDirty: true, IsProjectThumbnailDirty: true}, presignFileURL: "https://upd-file", presignThumbURL: "https://upd-thumb"},
		{name: "file presign error", req: &types.ProjectUpdateRequest{IsProjectFileDirty: true}, presignFileErr: errors.New("put error"), expectedErr: "failed to generate presign URL"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}
			mockDB.On("GetProjectByID", mock.Anything, mockProjectRow.ID, mock.AnythingOfType("*zap.Logger")).Return(mockProjectRow, nil)
			mockDB.On("IsUserAssigned", mock.Anything, mockProjectRow.ID, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
			mockDB.On("Update", mock.Anything, mockProjectRow, tt.req, mock.AnythingOfType("*zap.Logger")).Return(nil)
			if tt.req.IsProjectFileDirty {
				mockPresigner.On("PresignPut", mock.Anything, fmt.Sprintf("projects/%s/%s/%s.zip", mockProjectRow.ID, types.ProjectFileTypeProjectFile, mockProjectRow.ID), time.Minute*15, mock.Anything).Return(tt.presignFileURL, tt.presignFileErr)
			}
			if tt.req.IsProjectThumbnailDirty && tt.presignFileErr == nil { // only proceed if previous not failing so function reaches here
				mockPresigner.On("PresignPut", mock.Anything, fmt.Sprintf("projects/%s/%s/%s.zip", mockProjectRow.ID, types.ProjectFileTypeProjectThumbnail, mockProjectRow.ID), time.Minute*15, mock.Anything).Return(tt.presignThumbURL, tt.presignThumbErr)
			}
			service := &Service{dbService: mockDB, presigner: mockPresigner}

			// Set the project ID on the request
			tt.req.ID = mockProjectRow.ID

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			logger, _ := zap.NewProduction()
			resp, err := service.UpdateProject(context.Background(), tt.req, userAuth, logger)
			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
				assert.Nil(t, resp)
			} else {
				assert.NoError(t, err)
				if tt.req.IsProjectFileDirty {
					assert.Equal(t, tt.presignFileURL, *resp.ProjectUploadURL)
				}
				if tt.req.IsProjectThumbnailDirty {
					assert.Equal(t, tt.presignThumbURL, *resp.ThumbnailUploadURL)
				}
			}
			mockDB.AssertExpectations(t)
			mockPresigner.AssertExpectations(t)
		})
	}
}

func TestDeleteProject(t *testing.T) {
	mockProjectRow := &models.Project{
		ID:         "1",
		IsArchived: false,
		IsDeleted:  false,
	}

	tests := []struct {
		name           string
		id             string
		mockProjectRow *models.Project
		mockErr        error
		expectedErr    error
	}{
		{
			name:           "successful deletion",
			id:             "1",
			mockProjectRow: mockProjectRow,
			mockErr:        nil,
			expectedErr:    nil,
		},
		{
			name:           "database error",
			id:             "1",
			mockProjectRow: nil,
			mockErr:        errDatabaseMsg,
			expectedErr:    errDatabaseMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}

			if tt.mockProjectRow != nil {
				// Mock GetProjectByID call - successful case
				mockDB.On("GetProjectByID", mock.Anything, tt.id, mock.AnythingOfType("*zap.Logger")).Return(tt.mockProjectRow, nil)
				// Mock IsUserAssigned call
				mockDB.On("IsUserAssigned", mock.Anything, tt.id, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
				// Mock Delete call
				mockDB.On("Delete", mock.Anything, tt.mockProjectRow, mock.AnythingOfType("*zap.Logger")).Return(tt.mockErr)
			} else {
				// Mock GetProjectByID call - error case
				mockDB.On("GetProjectByID", mock.Anything, tt.id, mock.AnythingOfType("*zap.Logger")).Return(nil, tt.mockErr)
			}

			service := &Service{
				dbService: mockDB,
			}

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			logger, _ := zap.NewProduction()
			err := service.DeleteProject(context.Background(), tt.id, userAuth, logger)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
			} else {
				assert.NoError(t, err)
			}
			mockDB.AssertExpectations(t)
		})
	}
}

func TestAssignUserToProject(t *testing.T) {
	tests := []struct {
		name                string
		projectID           string
		userID              string
		projectExists       bool
		projectExistsErr    error
		userExists          bool
		userExistsErr       error
		userAlreadyAssigned bool
		userAssignedErr     error
		assignErr           error
		expectedErr         string
	}{
		{
			name:                "successful assignment",
			projectID:           testProjectID1,
			userID:              "target-user-id", // Different from current user (testUserID1)
			projectExists:       true,
			projectExistsErr:    nil,
			userExists:          true,
			userExistsErr:       nil,
			userAlreadyAssigned: false,
			userAssignedErr:     nil,
			assignErr:           nil,
			expectedErr:         "",
		},
		{
			name:                projectNotFoundMsg,
			projectID:           testProjectID1,
			userID:              "target-user-id",
			projectExists:       false,
			projectExistsErr:    nil,
			userExists:          true,
			userExistsErr:       nil,
			userAlreadyAssigned: false,
			userAssignedErr:     nil,
			assignErr:           nil,
			expectedErr:         projectNotFoundMsg,
		},

		{
			name:                "user already assigned",
			projectID:           testProjectID1,
			userID:              "target-user-id",
			projectExists:       true,
			projectExistsErr:    nil,
			userExists:          true,
			userExistsErr:       nil,
			userAlreadyAssigned: true,
			userAssignedErr:     nil,
			assignErr:           nil,
			expectedErr:         "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Setup mock based on expected flow
			if tt.projectExists && tt.projectExistsErr == nil {
				// Project exists, create mock project
				mockProject := &models.Project{
					ID:         tt.projectID,
					IsArchived: false,
					IsDeleted:  false,
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.AnythingOfType("*zap.Logger")).Return(mockProject, nil)

				// Mock the current user assignment check (validation requires this)
				// For non-admin users, validateProject checks if the current user is assigned to the project
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)

				// Mock GetUserIDByEmail - the service needs this to convert email to userID
				if tt.userExists && tt.userExistsErr == nil {
					mockDB.On("GetUserIDByEmail", mock.Anything, "test@example.com", mock.AnythingOfType("*zap.Logger")).Return(tt.userID, nil)
					mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID, mock.AnythingOfType("*zap.Logger")).Return(tt.userAlreadyAssigned, tt.userAssignedErr)
					if !tt.userAlreadyAssigned && tt.assignErr == nil {
						mockDB.On("AssignUser", mock.Anything, tt.projectID, tt.userID, mock.AnythingOfType("*zap.Logger")).Return(tt.assignErr)
					}
				} else {
					// User doesn't exist or error case
					var err error
					if tt.userExistsErr != nil {
						err = tt.userExistsErr
					} else {
						err = errors.New("user not found")
					}
					mockDB.On("GetUserIDByEmail", mock.Anything, "test@example.com", mock.AnythingOfType("*zap.Logger")).Return("", err)
				}
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			// Use email instead of userID since the method signature changed
			logger, _ := zap.NewProduction()
			response, err := service.AssignUserToProject(context.Background(), tt.projectID, "test@example.com", userAuth, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, response)
				assert.Equal(t, "User successfully assigned to the project", response.Message)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestRemoveUserFromProject(t *testing.T) {
	tests := []struct {
		name             string
		projectID        string
		userID           string
		projectExists    bool
		projectExistsErr error
		userExists       bool
		userExistsErr    error
		userAssigned     bool
		userAssignedErr  error
		removeErr        error
		expectedErr      string
	}{
		{
			name:             "successful removal",
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    true,
			projectExistsErr: nil,
			userExists:       true,
			userExistsErr:    nil,
			userAssigned:     true,
			userAssignedErr:  nil,
			removeErr:        nil,
			expectedErr:      "",
		},
		{
			name:             projectNotFoundMsg,
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    false,
			projectExistsErr: nil,
			userExists:       true,
			userExistsErr:    nil,
			userAssigned:     false,
			userAssignedErr:  nil,
			removeErr:        nil,
			expectedErr:      projectNotFoundMsg,
		},
		{
			name:             "user not assigned",
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    true,
			projectExistsErr: nil,
			userExists:       true,
			userExistsErr:    nil,
			userAssigned:     false,
			userAssignedErr:  nil,
			removeErr:        nil,
			expectedErr:      "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Setup mocks based on project existence first - validateProject is called first
			if tt.projectExists && tt.projectExistsErr == nil {
				// Project exists, create mock project
				mockProject := &models.Project{
					ID:         tt.projectID,
					IsArchived: false,
					IsDeleted:  false,
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(mockProject, nil)

				// Mock the current user assignment check (validation requires this)
				// For non-admin users, validateProject checks if the current user is assigned to the project
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, testUserID1, mock.Anything).Return(true, nil)

				// Mock GetUserIDByEmail after project validation
				if tt.userExists && tt.userExistsErr == nil {
					// Use a different target user ID (just like in AssignUserToProject test)
					targetUserID := "target-user-id"
					mockDB.On("GetUserIDByEmail", mock.Anything, "test@example.com", mock.AnythingOfType("*zap.Logger")).Return(targetUserID, nil)

					// Mock target user assignment check - this is called after GetUserIDByEmail
					mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, targetUserID, mock.Anything).Return(tt.userAssigned, tt.userAssignedErr)

					// If user is assigned and no assignment check error, then RemoveUser is called
					if tt.userAssigned && tt.userAssignedErr == nil && tt.removeErr == nil {
						mockDB.On("RemoveUser", mock.Anything, tt.projectID, targetUserID, mock.Anything).Return(tt.removeErr)
					}
				} else {
					// User doesn't exist or error case - this should return early, no need for other mocks
					var err error
					if tt.userExistsErr != nil {
						err = tt.userExistsErr
					} else {
						err = errors.New("user not found")
					}
					mockDB.On("GetUserIDByEmail", mock.Anything, "test@example.com", mock.AnythingOfType("*zap.Logger")).Return("", err)
				}
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			// Use email instead of userID since the method signature changed
			logger, _ := zap.NewProduction()
			response, err := service.RemoveUserFromProject(context.Background(), tt.projectID, "test@example.com", userAuth, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, response)
				assert.Equal(t, "User successfully removed from the project", response.Message)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestAssignUserToProjectByEmail(t *testing.T) {
	tests := []struct {
		name        string
		projectID   string
		userEmail   string
		mockUserID  string
		mockErr     error
		expectedErr string
	}{
		{
			name:        "successful assignment by email",
			projectID:   testProjectID1,
			userEmail:   "target@example.com", // Use different email
			mockUserID:  "target-user-id",     // Use different user ID
			mockErr:     nil,
			expectedErr: "",
		},
		{
			name:        "user not found by email",
			projectID:   testProjectID1,
			userEmail:   "nonexistent@example.com",
			mockUserID:  "",
			mockErr:     errors.New("user not found"),
			expectedErr: "user not found",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Project validation is always called first
			mockProject := &models.Project{
				ID:         tt.projectID,
				IsArchived: false,
				IsDeleted:  false,
			}
			mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(mockProject, nil)
			// Mock the current user assignment check (validation requires this)
			mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, testUserID1, mock.Anything).Return(true, nil)

			// Mock GetUserIDByEmail after project validation
			mockDB.On("GetUserIDByEmail", mock.Anything, tt.userEmail, mock.AnythingOfType("*zap.Logger")).Return(tt.mockUserID, tt.mockErr)

			if tt.mockErr == nil {
				// Setup mocks for successful user assignment
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.mockUserID, mock.Anything).Return(false, nil)
				mockDB.On("AssignUser", mock.Anything, tt.projectID, tt.mockUserID, mock.Anything).Return(nil)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			logger, _ := zap.NewProduction()
			response, err := service.AssignUserToProject(context.Background(), tt.projectID, tt.userEmail, userAuth, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, response)
				assert.Equal(t, "User successfully assigned to the project", response.Message)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestRemoveUserFromProjectByEmail(t *testing.T) {
	tests := []struct {
		name        string
		projectID   string
		userEmail   string
		mockUserID  string
		mockErr     error
		expectedErr string
	}{
		{
			name:        "successful removal by email",
			projectID:   testProjectID1,
			userEmail:   "test@example.com",
			mockUserID:  testUserID1,
			mockErr:     nil,
			expectedErr: "",
		},
		{
			name:        "user not found by email",
			projectID:   testProjectID1,
			userEmail:   "nonexistent@example.com",
			mockUserID:  "",
			mockErr:     errors.New("user not found"),
			expectedErr: "user not found",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Project validation is always called first now
			mockProject := &models.Project{
				ID:         tt.projectID,
				IsArchived: false,
				IsDeleted:  false,
			}
			mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(mockProject, nil)
			// Mock the current user assignment check (validation requires this)
			mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, testUserID1, mock.Anything).Return(true, nil)

			// Mock GetUserIDByEmail after project validation
			mockDB.On("GetUserIDByEmail", mock.Anything, tt.userEmail, mock.AnythingOfType("*zap.Logger")).Return(tt.mockUserID, tt.mockErr)

			if tt.mockErr == nil {
				// Setup mocks for successful user removal
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.mockUserID, mock.Anything).Return(true, nil)
				mockDB.On("RemoveUser", mock.Anything, tt.projectID, tt.mockUserID, mock.Anything).Return(nil)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			logger, _ := zap.NewProduction()
			response, err := service.RemoveUserFromProject(context.Background(), tt.projectID, tt.userEmail, userAuth, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, response)
				assert.Equal(t, "User successfully removed from the project", response.Message)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestStarProject(t *testing.T) {
	tests := []struct {
		name             string
		projectID        string
		userID           string
		projectExists    bool
		projectExistsErr error
		userExists       bool
		userExistsErr    error
		starErr          error
		expectedErr      string
	}{
		{
			name:             "successful star",
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    true,
			projectExistsErr: nil,
			userExists:       true,
			userExistsErr:    nil,
			starErr:          nil,
			expectedErr:      "",
		},
		{
			name:             projectNotFoundMsg,
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    false,
			projectExistsErr: nil,
			userExists:       true,
			userExistsErr:    nil,
			starErr:          nil,
			expectedErr:      projectNotFoundMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Setup mock based on expected flow
			if tt.projectExists && tt.projectExistsErr == nil {
				// Project exists, create mock project
				mockProject := &models.Project{
					ID:         tt.projectID,
					IsArchived: false,
					IsDeleted:  false,
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID, mock.Anything).Return(true, nil)
				mockDB.On("StarProject", mock.Anything, tt.projectID, tt.userID, mock.Anything).Return(tt.starErr)
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			logger, _ := zap.NewProduction()
			err := service.StarProject(context.Background(), tt.projectID, tt.userID, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestUnstarProject(t *testing.T) {
	tests := []struct {
		name             string
		projectID        string
		userID           string
		projectExists    bool
		projectExistsErr error
		userExists       bool
		userExistsErr    error
		unstarErr        error
		expectedErr      string
	}{
		{
			name:             "successful unstar",
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    true,
			projectExistsErr: nil,
			userExists:       true,
			userExistsErr:    nil,
			unstarErr:        nil,
			expectedErr:      "",
		},
		{
			name:             projectNotFoundMsg,
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    false,
			projectExistsErr: nil,
			userExists:       true,
			userExistsErr:    nil,
			unstarErr:        nil,
			expectedErr:      projectNotFoundMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Setup mock based on expected flow
			if tt.projectExists && tt.projectExistsErr == nil {
				// Project exists, create mock project
				mockProject := &models.Project{
					ID:         tt.projectID,
					IsArchived: false,
					IsDeleted:  false,
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID, mock.Anything).Return(true, nil)
				mockDB.On("UnstarProject", mock.Anything, tt.projectID, tt.userID, mock.Anything).Return(tt.unstarErr)
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			logger, _ := zap.NewProduction()
			err := service.UnstarProject(context.Background(), tt.projectID, tt.userID, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestArchiveProject(t *testing.T) {
	tests := []struct {
		name        string
		projectID   string
		mockSetup   func(*mockDBService)
		expectedErr string
	}{
		{
			name:      "successful archive",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				m.On("ArchiveProject", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(nil)
			},
		},
		{
			name:      "project not found",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				m.On("ArchiveProject", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(errors.New(projectNotFoundMsg))
			},
			expectedErr: projectNotFoundMsg,
		},
		{
			name:      "database error",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				m.On("ArchiveProject", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(errDatabaseMsg)
			},
			expectedErr: databaseErrorMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Mock GetProjectByID for initial project validation
			project := &models.Project{
				ID:         tt.projectID,
				IsDeleted:  false,
				IsArchived: false,
			}
			mockDB.On("GetProjectByID", mock.Anything, tt.projectID, mock.Anything).Return(project, nil)

			// Mock user assignment validation
			mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, testUserID1, mock.Anything).Return(true, nil)

			tt.mockSetup(mockDB)

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			logger, _ := zap.NewProduction()
			err := service.ArchiveProject(context.Background(), tt.projectID, userAuth, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestUnarchiveProject(t *testing.T) {
	tests := []struct {
		name        string
		projectID   string
		mockSetup   func(*mockDBService)
		expectedErr string
	}{
		{
			name:      "successful unarchive",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				// Project is archived, user is assigned, should proceed to unarchive
				project := &models.Project{
					ID:         testProjectID1,
					IsDeleted:  false,
					IsArchived: true, // Project is archived, so unarchive should proceed
				}
				m.ExpectedCalls = nil // Clear default mocks
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
				m.On("UnarchiveProject", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(nil)
			},
		},
		{
			name:      "project not found",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				// Override to return error from GetProjectByID for project not found
				m.ExpectedCalls = nil // Clear default mocks
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return((*models.Project)(nil), errors.New(projectNotFoundMsg))
			},
			expectedErr: projectNotFoundMsg,
		},
		{
			name:      "database error",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				// Project is archived so unarchive will proceed and return database error
				m.ExpectedCalls = nil // Clear default mocks
				project := &models.Project{
					ID:         testProjectID1,
					IsDeleted:  false,
					IsArchived: true, // Archived, so unarchive will proceed to database call
				}
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
				m.On("UnarchiveProject", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(errDatabaseMsg)
			},
			expectedErr: databaseErrorMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			tt.mockSetup(mockDB)

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    testUserID1,
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

			logger, _ := zap.NewProduction()
			err := service.UnarchiveProject(context.Background(), tt.projectID, userAuth, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestValidateProject(t *testing.T) {
	const testUserID2 = "user-2"
	const lockedByUserEmail = "locked@example.com"

	tests := []struct {
		name        string
		projectID   string
		opts        ValidationOptions
		mockSetup   func(*mockDBService)
		expectedErr string
	}{
		{
			name:      "successful validation - all checks pass",
			projectID: testProjectID1,
			opts: ValidationOptions{
				CheckDeleted:              true,
				CheckArchived:             true,
				CheckUserAssigned:         true,
				CheckNotLockedByOtherUser: true,
				UserID:                    testUserID1,
			},
			mockSetup: func(m *mockDBService) {
				project := &models.Project{
					ID:             testProjectID1,
					IsDeleted:      false,
					IsArchived:     false,
					LockedByUserID: null.String{},
				}
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
			},
		},
		{
			name:      "project not found",
			projectID: testProjectID1,
			opts: ValidationOptions{
				CheckDeleted: true,
				UserID:       testUserID1,
			},
			mockSetup: func(m *mockDBService) {
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return((*models.Project)(nil), errors.New(projectNotFoundMsg))
			},
			expectedErr: projectNotFoundMsg,
		},
		{
			name:      "project is deleted",
			projectID: testProjectID1,
			opts: ValidationOptions{
				CheckDeleted: true,
				UserID:       testUserID1,
			},
			mockSetup: func(m *mockDBService) {
				project := &models.Project{
					ID:        testProjectID1,
					IsDeleted: true,
				}
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
			},
			expectedErr: "project not found",
		},
		{
			name:      "project is archived",
			projectID: testProjectID1,
			opts: ValidationOptions{
				CheckArchived: true,
				UserID:        testUserID1,
			},
			mockSetup: func(m *mockDBService) {
				project := &models.Project{
					ID:         testProjectID1,
					IsDeleted:  false,
					IsArchived: true,
				}
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
			},
			expectedErr: "project is archived",
		},
		{
			name:      "user not assigned to project",
			projectID: testProjectID1,
			opts: ValidationOptions{
				CheckUserAssigned: true,
				UserID:            testUserID1,
			},
			mockSetup: func(m *mockDBService) {
				project := &models.Project{
					ID:         testProjectID1,
					IsDeleted:  false,
					IsArchived: false,
				}
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(false, nil)
			},
			expectedErr: "user not assigned to project",
		},
		{
			name:      "project locked by other user",
			projectID: testProjectID1,
			opts: ValidationOptions{
				CheckNotLockedByOtherUser: true,
				UserID:                    testUserID1,
			},
			mockSetup: func(m *mockDBService) {
				project := &models.Project{
					ID:             testProjectID1,
					IsDeleted:      false,
					IsArchived:     false,
					LockedByUserID: null.NewString(testUserID2, true),
				}
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
				m.On("GetUserEmailByID", mock.Anything, testUserID2).Return(lockedByUserEmail, nil)
			},
			expectedErr: "project is locked by user",
		},
		{
			name:      "project locked by same user - should pass",
			projectID: testProjectID1,
			opts: ValidationOptions{
				CheckNotLockedByOtherUser: true,
				UserID:                    testUserID1,
			},
			mockSetup: func(m *mockDBService) {
				project := &models.Project{
					ID:             testProjectID1,
					IsDeleted:      false,
					IsArchived:     false,
					LockedByUserID: null.NewString(testUserID1, true),
				}
				m.On("GetProjectByID", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(project, nil)
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			service := &Service{
				dbService: mockDB,
			}

			tt.mockSetup(mockDB)

			logger, _ := zap.NewProduction()
			project, err := service.validateProject(context.Background(), tt.projectID, tt.opts, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
				assert.Nil(t, project)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, project)
				assert.Equal(t, tt.projectID, project.ID)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestValidateUserAssignment(t *testing.T) {
	tests := []struct {
		name        string
		projectID   string
		userID      string
		mockSetup   func(*mockDBService)
		expectedErr string
	}{
		{
			name:      "user is assigned",
			projectID: testProjectID1,
			userID:    testUserID1,
			mockSetup: func(m *mockDBService) {
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
			},
		},
		{
			name:      "user not assigned",
			projectID: testProjectID1,
			userID:    testUserID1,
			mockSetup: func(m *mockDBService) {
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(false, nil)
			},
			expectedErr: "user not assigned to project",
		},
		{
			name:      "database error",
			projectID: testProjectID1,
			userID:    testUserID1,
			mockSetup: func(m *mockDBService) {
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.AnythingOfType("*zap.Logger")).Return(false, errDatabaseMsg)
			},
			expectedErr: "failed to check user assignment",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			service := &Service{
				dbService: mockDB,
			}

			tt.mockSetup(mockDB)

			logger, _ := zap.NewProduction()
			err := service.validateUserAssignment(context.Background(), tt.projectID, tt.userID, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

func TestValidateProjectNotLockedByOtherUser(t *testing.T) {
	const testUserID2 = "user-2"
	const lockedByUserEmail = "locked@example.com"

	tests := []struct {
		name        string
		project     *models.Project
		userID      string
		mockSetup   func(*mockDBService)
		expectedErr string
	}{
		{
			name: "project not locked",
			project: &models.Project{
				ID:             testProjectID1,
				LockedByUserID: null.String{},
			},
			userID: testUserID1,
			mockSetup: func(_ *mockDBService) {
				// No mocks needed for unlocked project
			},
		},
		{
			name: "project locked by same user",
			project: &models.Project{
				ID:             testProjectID1,
				LockedByUserID: null.NewString(testUserID1, true),
			},
			userID: testUserID1,
			mockSetup: func(_ *mockDBService) {
				// No mocks needed when locked by same user
			},
		},
		{
			name: "project locked by different user",
			project: &models.Project{
				ID:             testProjectID1,
				LockedByUserID: null.NewString(testUserID2, true),
			},
			userID: testUserID1,
			mockSetup: func(m *mockDBService) {
				m.On("GetUserEmailByID", mock.Anything, testUserID2).Return(lockedByUserEmail, nil)
			},
			expectedErr: "project is locked by user",
		},
		{
			name: "error getting locked user email",
			project: &models.Project{
				ID:             testProjectID1,
				LockedByUserID: null.NewString(testUserID2, true),
			},
			userID: testUserID1,
			mockSetup: func(m *mockDBService) {
				m.On("GetUserEmailByID", mock.Anything, testUserID2).Return("", errDatabaseMsg)
			},
			expectedErr: "failed to get user by email",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			service := &Service{
				dbService: mockDB,
			}

			tt.mockSetup(mockDB)

			logger, _ := zap.NewProduction()
			err := service.validateProjectNotLockedByOtherUser(context.Background(), tt.project, tt.userID, logger)

			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}

			mockDB.AssertExpectations(t)
		})
	}
}

// Additional coverage tests
func TestGenerateProjectFileURL(t *testing.T) {
	mockPresigner := &mockPresigner{}
	service := &Service{presigner: mockPresigner}
	ctx := context.Background()
	projectID := "proj-123"
	// GET
	logger := zap.NewNop()
	mockPresigner.On("PresignGet", mock.Anything, fmt.Sprintf("projects/%s/%s/%s.zip", projectID, types.ProjectFileTypeProjectFile, projectID), time.Minute*10, mock.Anything).Return("https://get-url", nil)
	url, err := service.generateProjectFileURL(ctx, projectID, types.ProjectFileTypeProjectFile, time.Minute*10, "get", logger)
	assert.NoError(t, err)
	assert.Equal(t, "https://get-url", url)
	// PUT
	mockPresigner.On("PresignPut", mock.Anything, fmt.Sprintf("projects/%s/%s/%s.zip", projectID, types.ProjectFileTypeProjectThumbnail, projectID), time.Minute*5, mock.Anything).Return("https://put-url", nil)
	url, err = service.generateProjectFileURL(ctx, projectID, types.ProjectFileTypeProjectThumbnail, time.Minute*5, "put", logger)
	assert.NoError(t, err)
	assert.Equal(t, "https://put-url", url)
	// Unsupported
	url, err = service.generateProjectFileURL(ctx, projectID, types.ProjectFileTypeProjectThumbnail, time.Minute, "delete", logger)
	assert.Error(t, err)
	assert.Empty(t, url)
	assert.Contains(t, err.Error(), "unsupported operation")
	mockPresigner.AssertExpectations(t)
}

// TestValidateUserExistence removed - validateUserExistence method does not exist in current implementation

func TestValidateProject_UserAssignmentDBError(t *testing.T) {
	mockDB := &mockDBService{}
	service := &Service{dbService: mockDB}
	ctx := context.Background()
	project := &models.Project{ID: testProjectID1, IsDeleted: false, IsArchived: false}
	mockDB.On("GetProjectByID", mock.Anything, testProjectID1, mock.Anything).Return(project, nil)
	mockDB.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.Anything).Return(false, errDatabaseMsg)
	logger, _ := zap.NewProduction()
	_, err := service.validateProject(ctx, testProjectID1, ValidationOptions{CheckUserAssigned: true, UserID: testUserID1}, logger)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), errorutil.ErrMsgFailedUserAssignmentCheck)
	mockDB.AssertExpectations(t)
}

func TestLockProject(t *testing.T) {
	ctx := context.Background()
	tests := []struct {
		name        string
		project     *models.Project
		userID      string
		expectLock  bool
		expectedErr string
	}{
		{name: "lock success", project: &models.Project{ID: testProjectID1, IsDeleted: false, IsArchived: false}, userID: testUserID1, expectLock: true},
		{name: "already locked by same user", project: &models.Project{ID: testProjectID1, IsDeleted: false, IsArchived: false, LockedByUserID: null.NewString(testUserID1, true)}, userID: testUserID1, expectLock: false},
		{name: "locked by other user", project: &models.Project{ID: testProjectID1, IsDeleted: false, IsArchived: false, LockedByUserID: null.NewString("other-user", true)}, userID: testUserID1, expectLock: false, expectedErr: "project is locked by user"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockDB.On("GetProjectByID", mock.Anything, testProjectID1, mock.Anything).Return(tt.project, nil)
			mockDB.On("IsUserAssigned", mock.Anything, testProjectID1, tt.userID, mock.Anything).Return(true, nil)
			if tt.project.LockedByUserID.Valid && tt.project.LockedByUserID.String != tt.userID {
				mockDB.On("GetUserEmailByID", mock.Anything, tt.project.LockedByUserID.String).Return("locked@example.com", nil)
			}
			if tt.expectLock {
				mockDB.On("LockProject", mock.Anything, testProjectID1, tt.userID, mock.Anything).Return(nil)
			}
			service := &Service{dbService: mockDB}
			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    tt.userID,
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

			logger, _ := zap.NewProduction()
			err := service.LockProject(ctx, testProjectID1, userAuth, logger)
			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}
			mockDB.AssertExpectations(t)
		})
	}
}

func TestUnlockProject(t *testing.T) {
	ctx := context.Background()
	tests := []struct {
		name         string
		project      *models.Project
		userID       string
		expectUnlock bool
		expectedErr  string
	}{
		{name: "unlock success", project: &models.Project{ID: testProjectID1, IsDeleted: false, IsArchived: false, LockedByUserID: null.NewString(testUserID1, true)}, userID: testUserID1, expectUnlock: true},
		{name: "already unlocked", project: &models.Project{ID: testProjectID1, IsDeleted: false, IsArchived: false}, userID: testUserID1, expectUnlock: false},
		{name: "locked by other user", project: &models.Project{ID: testProjectID1, IsDeleted: false, IsArchived: false, LockedByUserID: null.NewString("other-user", true)}, userID: testUserID1, expectUnlock: false, expectedErr: "project is locked by user"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockDB.On("GetProjectByID", mock.Anything, testProjectID1, mock.Anything).Return(tt.project, nil)
			mockDB.On("IsUserAssigned", mock.Anything, testProjectID1, tt.userID, mock.Anything).Return(true, nil)
			if tt.project.LockedByUserID.Valid && tt.project.LockedByUserID.String != tt.userID {
				mockDB.On("GetUserEmailByID", mock.Anything, tt.project.LockedByUserID.String).Return("locked@example.com", nil)
			}
			if tt.expectUnlock {
				mockDB.On("UnlockProject", mock.Anything, testProjectID1, mock.Anything).Return(nil)
			}
			service := &Service{dbService: mockDB}
			// Create user auth data
			userAuth := types.UserAuthorizationResponse{
				User: types.UserInfo{
					ID:    tt.userID,
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

			logger, _ := zap.NewProduction()
			err := service.UnlockProject(ctx, testProjectID1, userAuth, logger)
			if tt.expectedErr != "" {
				assert.Error(t, err)
				assert.Contains(t, err.Error(), tt.expectedErr)
			} else {
				assert.NoError(t, err)
			}
			mockDB.AssertExpectations(t)
		})
	}
}

func TestGetProjectLockInfo(t *testing.T) {
	ctx := context.Background()
	mockDB := &mockDBService{}
	service := &Service{dbService: mockDB}
	// Unlocked
	mockDB.On("GetProjectLockUserID", mock.Anything, testProjectID1).Return(false, "", nil)
	locked, email, err := service.GetProjectLockInfo(ctx, testProjectID1)
	assert.NoError(t, err)
	assert.False(t, locked)
	assert.Empty(t, email)
	mockDB.ExpectedCalls = nil
	// Locked success
	mockDB.On("GetProjectLockUserID", mock.Anything, testProjectID1).Return(true, "locker", nil)
	mockDB.On("GetUserEmailByID", mock.Anything, "locker").Return("locker@example.com", nil)
	locked, email, err = service.GetProjectLockInfo(ctx, testProjectID1)
	assert.NoError(t, err)
	assert.True(t, locked)
	assert.Equal(t, "locker@example.com", email)
	mockDB.ExpectedCalls = nil
	// Locked email error
	mockDB.On("GetProjectLockUserID", mock.Anything, testProjectID1).Return(true, "locker", nil)
	mockDB.On("GetUserEmailByID", mock.Anything, "locker").Return("", errDatabaseMsg)
	locked, email, err = service.GetProjectLockInfo(ctx, testProjectID1)
	assert.Error(t, err)
	assert.True(t, locked)
	assert.Empty(t, email)
	mockDB.AssertExpectations(t)
}

func TestWrappers_ProjectExists_IsUserAssigned(t *testing.T) {
	ctx := context.Background()
	mockDB := &mockDBService{}
	service := &Service{dbService: mockDB}
	mockDB.On("ProjectExists", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(true, nil)
	exists, err := service.ProjectExists(ctx, testProjectID1, zap.NewNop())
	assert.NoError(t, err)
	assert.True(t, exists)
	mockDB.ExpectedCalls = nil
	mockDB.On("ProjectExists", mock.Anything, testProjectID1, mock.AnythingOfType("*zap.Logger")).Return(false, errDatabaseMsg)
	exists, err = service.ProjectExists(ctx, testProjectID1, zap.NewNop())
	assert.Error(t, err)
	assert.False(t, exists)
	mockDB.ExpectedCalls = nil
	mockDB.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.Anything).Return(true, nil)
	logger, _ := zap.NewProduction()
	assigned, err := service.IsUserAssigned(ctx, testProjectID1, testUserID1, logger)
	assert.NoError(t, err)
	assert.True(t, assigned)
	mockDB.ExpectedCalls = nil
	mockDB.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1, mock.Anything).Return(false, errDatabaseMsg)
	assigned, err = service.IsUserAssigned(ctx, testProjectID1, testUserID1, logger)
	assert.Error(t, err)
	assert.False(t, assigned)
	mockDB.AssertExpectations(t)
}

func TestWrappers_GetProjectLockUserID_GetUserEmailByID(t *testing.T) {
	ctx := context.Background()
	mockDB := &mockDBService{}
	service := &Service{dbService: mockDB}
	mockDB.On("GetProjectLockUserID", mock.Anything, testProjectID1).Return(true, "locker", nil)
	locked, uid, err := service.GetProjectLockUserID(ctx, testProjectID1)
	assert.NoError(t, err)
	assert.True(t, locked)
	assert.Equal(t, "locker", uid)
	mockDB.ExpectedCalls = nil
	mockDB.On("GetUserEmailByID", mock.Anything, "locker").Return("locker@example.com", nil)
	email, err := service.GetUserEmailByID(ctx, "locker")
	assert.NoError(t, err)
	assert.Equal(t, "locker@example.com", email)
	mockDB.AssertExpectations(t)
}
