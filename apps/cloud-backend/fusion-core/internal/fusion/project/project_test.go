package project

import (
	"context"
	"errors"
	"fmt"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/model/models"
	"github.com/aarondl/null/v8"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

const (
	databaseErrorMsg = "database error"
)

var (
	errDatabaseMsg = errors.New(databaseErrorMsg)
)

const (
	testProjectID1         = "project-1"
	testUserID1            = "user-1"
	projectNotFoundMsg     = "project not found"
	userNotFoundMsg        = "user not found"
	userAlreadyAssignedMsg = "user is already assigned to the project"
	userNotAssignedMsg     = "user not assigned to the project"
)

const (
	updatedProjectName = "Updated Project"
)

type mockDBService struct {
	mock.Mock
}

func (m *mockDBService) Insert(ctx context.Context, project *types.ProjectCreateRequest) (string, error) {
	args := m.Called(ctx, project)
	return args.String(0), args.Error(1)
}

func (m *mockDBService) SelectAll(ctx context.Context, params *types.GetAllProjectsParams) ([]types.Project, error) {
	args := m.Called(ctx, params)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]types.Project), args.Error(1)
}

func (m *mockDBService) Update(ctx context.Context, projectRow *models.Project, project *types.ProjectUpdateRequest) error {
	args := m.Called(ctx, projectRow, project)
	return args.Error(0)
}

func (m *mockDBService) Delete(ctx context.Context, projectRow *models.Project) error {
	args := m.Called(ctx, projectRow)
	return args.Error(0)
}

func (m *mockDBService) AssignUser(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *mockDBService) RemoveUser(ctx context.Context, projectID, userID string) error {
	result := m.Called(ctx, projectID, userID)
	return result.Error(0)
}

func (m *mockDBService) IsUserAssigned(ctx context.Context, projectID, userID string) (bool, error) {
	args := m.Called(ctx, projectID, userID)
	return args.Bool(0), args.Error(1)
}

func (m *mockDBService) ProjectExists(ctx context.Context, projectID string) (bool, error) {
	args := m.Called(ctx, projectID)
	return args.Bool(0), args.Error(1)
}

func (m *mockDBService) UserExists(ctx context.Context, userID string) (bool, error) {
	args := m.Called(ctx, userID)
	return args.Bool(0), args.Error(1)
}

func (m *mockDBService) GetUserIDByEmail(ctx context.Context, email string) (string, error) {
	args := m.Called(ctx, email)
	return args.String(0), args.Error(1)
}

func (m *mockDBService) GetProjectByID(ctx context.Context, projectID string) (*models.Project, error) {
	args := m.Called(ctx, projectID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Project), args.Error(1)
}

func (m *mockDBService) StarProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *mockDBService) UnstarProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *mockDBService) ArchiveProject(ctx context.Context, projectID string) error {
	args := m.Called(ctx, projectID)
	return args.Error(0)
}

func (m *mockDBService) UnarchiveProject(ctx context.Context, projectID string) error {
	args := m.Called(ctx, projectID)
	return args.Error(0)
}

func (m *mockDBService) LockProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *mockDBService) UnlockProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
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

func (m *mockPresigner) PresignGet(ctx context.Context, key string, ttl time.Duration) (string, error) {
	args := m.Called(ctx, key, ttl)
	return args.String(0), args.Error(1)
}

func (m *mockPresigner) PresignPut(ctx context.Context, key string, ttl time.Duration) (string, error) {
	return "", errors.New("not implemented")
}

func TestCreateProject(t *testing.T) {
	tests := []struct {
		name           string
		project        *types.ProjectCreateRequest
		mockID         string
		mockErr        error
		expectedID     string
		expectedErr    error
		expectResponse bool
	}{
		{
			name: "successful creation",
			project: &types.ProjectCreateRequest{
				Name:   "Test Project",
				UserID: "user-123",
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
				Name:   "Test Project",
				UserID: "user-123",
			},
			mockID:         "",
			mockErr:        errDatabaseMsg,
			expectedID:     "",
			expectedErr:    fmt.Errorf("failed to insert project: %v", errDatabaseMsg),
			expectResponse: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			// Mock user existence validation
			mockDB.On("UserExists", mock.Anything, tt.project.UserID).Return(true, nil)
			mockDB.On("Insert", mock.Anything, tt.project).Return(tt.mockID, tt.mockErr)

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.CreateProject(context.Background(), tt.project)
			if tt.expectedErr != nil {
				assert.EqualError(t, err, tt.expectedErr.Error())
				assert.Nil(t, response)
			} else {
				assert.NoError(t, err)
				if tt.expectResponse {
					assert.NotNil(t, response)
					assert.Equal(t, tt.expectedID, response.ID)
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

			mockDB.On("SelectAll", mock.Anything, tt.params).Return(tt.mockProjects, tt.mockDBErr)
			if tt.mockDBErr == nil {
				for _, p := range tt.mockProjects {
					// Mock project file URL generation
					mockPresigner.On("PresignGet",
						mock.Anything,
						fmt.Sprintf("projects/%s/projectFile/%s.zip", p.ID, p.ID),
						time.Minute*5,
					).Return(tt.mockPresignURL, tt.mockPresignErr).Maybe()

					// Mock thumbnail URL generation
					mockPresigner.On("PresignGet",
						mock.Anything,
						fmt.Sprintf("projects/%s/projectThumbnail/%s.zip", p.ID, p.ID),
						time.Minute*5,
					).Return(tt.mockPresignURL, tt.mockPresignErr).Maybe()
				}
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.GetAllProjects(context.Background(), tt.params)
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
					assert.Equal(t, tt.mockPresignURL, p.ProjectFileURL)
					assert.Equal(t, tt.mockPresignURL, p.ThumbnailURL)
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
		ID:                 "1",
		PrimaryOwnerUserID: null.NewString("123", true),
		Name:               null.NewString(updatedProjectName, true),
		IsArchived:         false,
		IsDeleted:          false,
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
				mockDB.On("GetProjectByID", mock.Anything, tt.id).Return(tt.mockProjectRow, nil)
				// Mock IsUserAssigned call
				mockDB.On("IsUserAssigned", mock.Anything, tt.id, testUserID1).Return(true, nil)
				// Mock Update call
				mockDB.On("Update", mock.Anything, tt.mockProjectRow, tt.project).Return(tt.mockErr)
			} else {
				// Mock GetProjectByID call - error case
				mockDB.On("GetProjectByID", mock.Anything, tt.id).Return(nil, tt.mockErr)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.UpdateProject(context.Background(), tt.id, testUserID1, tt.project)
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
				mockDB.On("GetProjectByID", mock.Anything, tt.id).Return(tt.mockProjectRow, nil)
				// Mock IsUserAssigned call
				mockDB.On("IsUserAssigned", mock.Anything, tt.id, testUserID1).Return(true, nil)
				// Mock Delete call
				mockDB.On("Delete", mock.Anything, tt.mockProjectRow).Return(tt.mockErr)
			} else {
				// Mock GetProjectByID call - error case
				mockDB.On("GetProjectByID", mock.Anything, tt.id).Return(nil, tt.mockErr)
			}

			service := &Service{
				dbService: mockDB,
			}

			err := service.DeleteProject(context.Background(), tt.id, testUserID1)
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
			userID:              testUserID1,
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
			userID:              testUserID1,
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
			userID:              testUserID1,
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
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(tt.userAlreadyAssigned, tt.userAssignedErr)
				if !tt.userAlreadyAssigned && tt.assignErr == nil {
					mockDB.On("AssignUser", mock.Anything, tt.projectID, tt.userID).Return(tt.assignErr)
				}
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.AssignUserToProject(context.Background(), tt.projectID, tt.userID)

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
			userAssigned:     true,
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

			// Setup mock based on expected flow
			if tt.projectExists && tt.projectExistsErr == nil {
				// Project exists, create mock project
				mockProject := &models.Project{
					ID:         tt.projectID,
					IsArchived: false,
					IsDeleted:  false,
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(tt.userAssigned, tt.userAssignedErr)
				if tt.userAssigned && tt.removeErr == nil {
					mockDB.On("RemoveUser", mock.Anything, tt.projectID, tt.userID).Return(tt.removeErr)
				}
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.RemoveUserFromProject(context.Background(), tt.projectID, tt.userID)

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

			mockDB.On("GetUserIDByEmail", mock.Anything, tt.userEmail).Return(tt.mockUserID, tt.mockErr)

			if tt.mockErr == nil {
				// Setup mocks for successful user assignment - this calls AssignUserToProject internally
				mockProject := &models.Project{
					ID:         tt.projectID,
					IsArchived: false,
					IsDeleted:  false,
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.mockUserID).Return(false, nil)
				mockDB.On("AssignUser", mock.Anything, tt.projectID, tt.mockUserID).Return(nil)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.AssignUserToProjectByEmail(context.Background(), tt.projectID, tt.userEmail)

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

			mockDB.On("GetUserIDByEmail", mock.Anything, tt.userEmail).Return(tt.mockUserID, tt.mockErr)

			if tt.mockErr == nil {
				// Setup mocks for successful user removal - this calls RemoveUserFromProject internally
				mockProject := &models.Project{
					ID:         tt.projectID,
					IsArchived: false,
					IsDeleted:  false,
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.mockUserID).Return(true, nil)
				mockDB.On("RemoveUser", mock.Anything, tt.projectID, tt.mockUserID).Return(nil)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.RemoveUserFromProjectByEmail(context.Background(), tt.projectID, tt.userEmail)

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
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(true, nil)
				mockDB.On("StarProject", mock.Anything, tt.projectID, tt.userID).Return(tt.starErr)
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			err := service.StarProject(context.Background(), tt.projectID, tt.userID)

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
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(mockProject, nil)
				mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(true, nil)
				mockDB.On("UnstarProject", mock.Anything, tt.projectID, tt.userID).Return(tt.unstarErr)
			} else {
				// Project doesn't exist or error case
				var err error
				if tt.projectExistsErr != nil {
					err = tt.projectExistsErr
				} else {
					err = errors.New(projectNotFoundMsg)
				}
				mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(nil, err)
			}

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			err := service.UnstarProject(context.Background(), tt.projectID, tt.userID)

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
				m.On("ArchiveProject", mock.Anything, testProjectID1).Return(nil)
			},
		},
		{
			name:      "project not found",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				m.On("ArchiveProject", mock.Anything, testProjectID1).Return(errors.New(projectNotFoundMsg))
			},
			expectedErr: projectNotFoundMsg,
		},
		{
			name:      "database error",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				m.On("ArchiveProject", mock.Anything, testProjectID1).Return(errDatabaseMsg)
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
			mockDB.On("GetProjectByID", mock.Anything, tt.projectID).Return(project, nil)

			// Mock user assignment validation
			mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, testUserID1).Return(true, nil)

			tt.mockSetup(mockDB)

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			err := service.ArchiveProject(context.Background(), tt.projectID, testUserID1)

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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1).Return(true, nil)
				m.On("UnarchiveProject", mock.Anything, testProjectID1).Return(nil)
			},
		},
		{
			name:      "project not found",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				// Override to return error from GetProjectByID for project not found
				m.ExpectedCalls = nil // Clear default mocks
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return((*models.Project)(nil), errors.New(projectNotFoundMsg))
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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1).Return(true, nil)
				m.On("UnarchiveProject", mock.Anything, testProjectID1).Return(errDatabaseMsg)
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

			err := service.UnarchiveProject(context.Background(), tt.projectID, testUserID1)

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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1).Return(true, nil)
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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return((*models.Project)(nil), errors.New(projectNotFoundMsg))
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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1).Return(false, nil)
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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
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
				m.On("GetProjectByID", mock.Anything, testProjectID1).Return(project, nil)
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

			project, err := service.validateProject(context.Background(), tt.projectID, tt.opts)

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
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1).Return(true, nil)
			},
		},
		{
			name:      "user not assigned",
			projectID: testProjectID1,
			userID:    testUserID1,
			mockSetup: func(m *mockDBService) {
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1).Return(false, nil)
			},
			expectedErr: "user not assigned to project",
		},
		{
			name:      "database error",
			projectID: testProjectID1,
			userID:    testUserID1,
			mockSetup: func(m *mockDBService) {
				m.On("IsUserAssigned", mock.Anything, testProjectID1, testUserID1).Return(false, errDatabaseMsg)
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

			err := service.validateUserAssignment(context.Background(), tt.projectID, tt.userID)

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
			mockSetup: func(m *mockDBService) {
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
			mockSetup: func(m *mockDBService) {
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

			err := service.validateProjectNotLockedByOtherUser(context.Background(), tt.project, tt.userID)

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
