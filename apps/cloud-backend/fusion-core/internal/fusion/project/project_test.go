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

func (m *mockDBService) SelectAll(ctx context.Context, params *types.GetAllProjectsParams) ([]*types.Project, error) {
	args := m.Called(ctx, params)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*types.Project), args.Error(1)
}

func (m *mockDBService) Update(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*models.Project, error) {
	args := m.Called(ctx, id, project)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Project), args.Error(1)
}

func (m *mockDBService) Delete(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
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
	mockProjects := []*types.Project{
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
		mockProjects   []*types.Project
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
			for _, p := range tt.mockProjects {
				mockPresigner.On("PresignGet",
					mock.Anything,
					fmt.Sprintf("projects/%s/%s.zip", p.ID, p.ID),
					time.Minute*5,
				).Return(tt.mockPresignURL, tt.mockPresignErr).Maybe()
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
			expectedErr:    fmt.Errorf("failed to update project: %v", errDatabaseMsg),
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}
			mockDB.On("Update", mock.Anything, tt.id, tt.project).Return(tt.mockProjectRow, tt.mockErr)

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			response, err := service.UpdateProject(context.Background(), tt.id, tt.project)
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
	tests := []struct {
		name        string
		id          string
		mockErr     error
		expectedErr error
	}{
		{
			name:        "successful deletion",
			id:          "1",
			mockErr:     nil,
			expectedErr: nil,
		},
		{
			name:        "database error",
			id:          "1",
			mockErr:     errDatabaseMsg,
			expectedErr: errDatabaseMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockDB.On("Delete", mock.Anything, tt.id).Return(tt.mockErr)

			service := &Service{
				dbService: mockDB,
			}

			err := service.DeleteProject(context.Background(), tt.id)
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
			name:                userNotFoundMsg,
			projectID:           testProjectID1,
			userID:              testUserID1,
			projectExists:       true,
			projectExistsErr:    nil,
			userExists:          false,
			userExistsErr:       nil,
			userAlreadyAssigned: false,
			userAssignedErr:     nil,
			assignErr:           nil,
			expectedErr:         userNotFoundMsg,
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

			mockDB.On("ProjectExists", mock.Anything, tt.projectID).Return(tt.projectExists, tt.projectExistsErr)
			if tt.projectExists {
				mockDB.On("UserExists", mock.Anything, tt.userID).Return(tt.userExists, tt.userExistsErr)
				if tt.userExists {
					mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(tt.userAlreadyAssigned, tt.userAssignedErr)
					if !tt.userAlreadyAssigned {
						mockDB.On("AssignUser", mock.Anything, tt.projectID, tt.userID).Return(tt.assignErr)
					}
				}
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

			mockDB.On("ProjectExists", mock.Anything, tt.projectID).Return(tt.projectExists, tt.projectExistsErr)
			if tt.projectExists {
				mockDB.On("UserExists", mock.Anything, tt.userID).Return(tt.userExists, tt.userExistsErr)
				if tt.userExists {
					mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(tt.userAssigned, tt.userAssignedErr)
					if tt.userAssigned {
						mockDB.On("RemoveUser", mock.Anything, tt.projectID, tt.userID).Return(tt.removeErr)
					}
				}
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
				// Setup mocks for successful user assignment
				mockDB.On("ProjectExists", mock.Anything, tt.projectID).Return(true, nil)
				mockDB.On("UserExists", mock.Anything, tt.mockUserID).Return(true, nil)
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
				// Setup mocks for successful user removal
				mockDB.On("ProjectExists", mock.Anything, tt.projectID).Return(true, nil)
				mockDB.On("UserExists", mock.Anything, tt.mockUserID).Return(true, nil)
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
		{
			name:             userNotFoundMsg,
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    true,
			projectExistsErr: nil,
			userExists:       false,
			userExistsErr:    nil,
			starErr:          nil,
			expectedErr:      userNotFoundMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			mockDB.On("ProjectExists", mock.Anything, tt.projectID).Return(tt.projectExists, tt.projectExistsErr)
			if tt.projectExists {
				mockDB.On("UserExists", mock.Anything, tt.userID).Return(tt.userExists, tt.userExistsErr)
				if tt.userExists {
					mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(true, nil)
					mockDB.On("StarProject", mock.Anything, tt.projectID, tt.userID).Return(tt.starErr)
				}
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
		{
			name:             userNotFoundMsg,
			projectID:        testProjectID1,
			userID:           testUserID1,
			projectExists:    true,
			projectExistsErr: nil,
			userExists:       false,
			userExistsErr:    nil,
			unstarErr:        nil,
			expectedErr:      userNotFoundMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockDB := &mockDBService{}
			mockPresigner := &mockPresigner{}

			mockDB.On("ProjectExists", mock.Anything, tt.projectID).Return(tt.projectExists, tt.projectExistsErr)
			if tt.projectExists {
				mockDB.On("UserExists", mock.Anything, tt.userID).Return(tt.userExists, tt.userExistsErr)
				if tt.userExists {
					mockDB.On("IsUserAssigned", mock.Anything, tt.projectID, tt.userID).Return(true, nil)
					mockDB.On("UnstarProject", mock.Anything, tt.projectID, tt.userID).Return(tt.unstarErr)
				}
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
			tt.mockSetup(mockDB)

			service := &Service{
				dbService: mockDB,
				presigner: mockPresigner,
			}

			err := service.ArchiveProject(context.Background(), tt.projectID)

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
				m.On("UnarchiveProject", mock.Anything, testProjectID1).Return(nil)
			},
		},
		{
			name:      "project not found",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
				m.On("UnarchiveProject", mock.Anything, testProjectID1).Return(errors.New(projectNotFoundMsg))
			},
			expectedErr: projectNotFoundMsg,
		},
		{
			name:      "database error",
			projectID: testProjectID1,
			mockSetup: func(m *mockDBService) {
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

			err := service.UnarchiveProject(context.Background(), tt.projectID)

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
