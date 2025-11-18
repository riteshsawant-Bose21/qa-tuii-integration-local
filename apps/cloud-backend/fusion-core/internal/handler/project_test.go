package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

const (
	projectsEndpoint       = "/projects"
	projectsPathPrefix     = "/projects/"
	contentTypeHeader      = "Content-Type"
	applicationJSON        = "application/json"
	serviceFailureTest     = "returns error when service fails"
	serviceErrorMsg        = "service error"
	testProjectName        = "Test Project"
	testProjectDesc        = "Test Description"
	testProjectID          = "123e4567-e89b-12d3-a456-426614174000"
	testUserID             = "223e4567-e89b-12d3-a456-426614174000"
	testUserEmail          = "test@example.com"
	testUpdatedProject     = "Updated Project"
	userQueryParam         = "?user_id="
	usersPath              = "/users/"
	starPath               = "/star/"
	archivePath            = "/archive"
	projectNotFoundMessage = "project not found"
	internalErrorMsg       = "internal error"
)

// MockProjectService is a mock implementation of ProjectSVC
type MockProjectService struct {
	mock.Mock
}

func (m *MockProjectService) CreateProject(ctx context.Context, project *types.ProjectCreateRequest) (*types.ProjectCreateResponse, error) {
	args := m.Called(ctx, project)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.ProjectCreateResponse), args.Error(1)
}

func (m *MockProjectService) GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams) (*types.GetAllProjectsResponse, error) {
	args := m.Called(ctx, queryParams)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.GetAllProjectsResponse), args.Error(1)
}

func (m *MockProjectService) UpdateProject(ctx context.Context, id string, userID string, project *types.ProjectUpdateRequest) (*types.ProjectUpdateResponse, error) {
	args := m.Called(ctx, id, userID, project)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.ProjectUpdateResponse), args.Error(1)
}

func (m *MockProjectService) DeleteProject(ctx context.Context, id string, userID string) error {
	args := m.Called(ctx, id, userID)
	return args.Error(0)
}

func (m *MockProjectService) AssignUserToProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error) {
	args := m.Called(ctx, projectID, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserAssignmentResponse), args.Error(1)
}

func (m *MockProjectService) RemoveUserFromProject(ctx context.Context, projectID, userID string) (*types.UserAssignmentResponse, error) {
	args := m.Called(ctx, projectID, userID)
	result := args.Get(0)
	if result == nil {
		return nil, args.Error(1)
	}
	return result.(*types.UserAssignmentResponse), args.Error(1)
}

func (m *MockProjectService) AssignUserToProjectByEmail(ctx context.Context, projectID, userEmail string) (*types.UserAssignmentResponse, error) {
	args := m.Called(ctx, projectID, userEmail)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserAssignmentResponse), args.Error(1)
}

func (m *MockProjectService) RemoveUserFromProjectByEmail(ctx context.Context, projectID, userEmail string) (*types.UserAssignmentResponse, error) {
	args := m.Called(ctx, projectID, userEmail)
	result := args.Get(0)
	if result == nil {
		return nil, args.Error(1)
	}
	return result.(*types.UserAssignmentResponse), args.Error(1)
}

func (m *MockProjectService) StarProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) UnstarProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) ArchiveProject(ctx context.Context, projectID string, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) UnarchiveProject(ctx context.Context, projectID string, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) ProjectExists(ctx context.Context, projectID string) (bool, error) {
	args := m.Called(ctx, projectID)
	return args.Bool(0), args.Error(1)
}

func (m *MockProjectService) IsUserAssigned(ctx context.Context, projectID, userID string) (bool, error) {
	args := m.Called(ctx, projectID, userID)
	return args.Bool(0), args.Error(1)
}

func (m *MockProjectService) LockProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) UnlockProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) ValidateProjectNotLockedByOther(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) GetProjectLockUserID(ctx context.Context, projectID string) (bool, string, error) {
	args := m.Called(ctx, projectID)
	return args.Bool(0), args.String(1), args.Error(2)
}

func (m *MockProjectService) GetUserEmailByID(ctx context.Context, userID string) (string, error) {
	args := m.Called(ctx, userID)
	return args.String(0), args.Error(1)
}

func (m *MockProjectService) GetProjectLockInfo(ctx context.Context, projectID string) (bool, string, error) {
	args := m.Called(ctx, projectID)
	return args.Bool(0), args.String(1), args.Error(2)
}

func setupTest() (*gin.Engine, *MockProjectService) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	mockSvc := new(MockProjectService)
	handler := NewProjectHandler(mockSvc)

	r.POST(projectsEndpoint, handler.CreateProject)
	r.GET(projectsEndpoint, handler.GetAllProjects)
	r.PATCH(projectsEndpoint+"/:projectId", handler.UpdateProject)
	r.DELETE(projectsEndpoint+"/:projectId", handler.DeleteProject)
	r.PUT(projectsEndpoint+"/:projectId/users/:userEmail", handler.AssignUserToProject)
	r.DELETE(projectsEndpoint+"/:projectId/users/:userEmail", handler.RemoveUserFromProject)
	r.PUT(projectsEndpoint+"/:projectId/star/:userId", handler.StarProject)
	r.DELETE(projectsEndpoint+"/:projectId/star/:userId", handler.UnstarProject)
	r.PUT(projectsEndpoint+"/:projectId/archive", handler.ArchiveProject)
	r.DELETE(projectsEndpoint+"/:projectId/archive", handler.UnarchiveProject)

	return r, mockSvc
}

func TestCreateProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully creates project", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			Name:            testProjectName,
			Description:     testProjectDesc,
			UserID:          "123",
			Application:     "test-app",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		expectedResponse := &types.ProjectCreateResponse{
			ID: "123e4567-e89b-12d3-a456-426614174000",
		}

		// Mock should expect the request after validation, which sets default project phase
		expectedProject := *project
		expectedProject.ProjectPhase = types.ProjectPhaseProposal // validation sets this default
		mockSvc.On("CreateProject", mock.Anything, &expectedProject).Return(expectedResponse, nil)

		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBufferString("invalid json"))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run(serviceFailureTest, func(t *testing.T) {
		// Setup fresh router and mock for this test
		r, mockSvc := setupTest()

		project := &types.ProjectCreateRequest{
			Name:            testProjectName,
			Description:     testProjectDesc,
			UserID:          "123",
			Application:     "test-app",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		mockSvc.On("CreateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectCreateRequest) bool {
			return req.Name == testProjectName && req.Description == testProjectDesc && req.UserID == "123" && req.Application == "test-app" && req.ProjectPhase == types.ProjectPhaseProposal
		})).Return((*types.ProjectCreateResponse)(nil), errors.New(serviceErrorMsg))

		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestGetAllProjects(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully retrieves projects", func(t *testing.T) {
		projects := []types.Project{
			{
				ID:          "1",
				Name:        "Test Project 1",
				Description: "Test Description 1",
			},
			{
				ID:          "2",
				Name:        "Test Project 2",
				Description: "Test Description 2",
			},
		}

		params := &types.GetAllProjectsParams{
			UserID:    testProjectID, // This will be set by the handler from query params
			SortBy:    "updated_at",
			SortOrder: "desc",
		}

		expectedResponse := &types.GetAllProjectsResponse{
			Data:       projects,
			TotalCount: len(projects),
			Page:       1,
			TotalPages: 1,
		}

		mockSvc.On("GetAllProjects", mock.Anything, params).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?user_id=123e4567-e89b-12d3-a456-426614174000", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		json.Unmarshal(w.Body.Bytes(), &response)
		assert.Len(t, response.Data, 2)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error with invalid sort parameters", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?sort_by=invalid&user_id=123e4567-e89b-12d3-a456-426614174000", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run(serviceFailureTest, func(t *testing.T) {
		// Setup fresh router and mock for this test
		r, mockSvc := setupTest()

		mockSvc.On("GetAllProjects", mock.Anything, mock.MatchedBy(func(params *types.GetAllProjectsParams) bool {
			return params.UserID == testProjectID && params.SortBy == "updated_at" && params.SortOrder == "desc"
		})).Return((*types.GetAllProjectsResponse)(nil), errors.New(serviceErrorMsg))

		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?user_id=123e4567-e89b-12d3-a456-426614174000", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUpdateProject(t *testing.T) {
	t.Run("successfully updates project", func(t *testing.T) {
		r, mockSvc := setupTest()
		projectID := testProjectID
		userID := testUserID
		updateReq := &types.ProjectUpdateRequest{
			Name:        "Updated Project",
			Description: "Updated Description",
		}

		expectedResponse := &types.ProjectUpdateResponse{}

		// Use authenticated method which includes all validations
		mockSvc.On("UpdateProject", mock.Anything, projectID, userID, updateReq).Return(expectedResponse, nil)

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID+userQueryParam+userID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		r, mockSvc := setupTest()

		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+testProjectID+userQueryParam+testUserID, bytes.NewBufferString("invalid json"))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error when user_id is missing", func(t *testing.T) {
		r, mockSvc := setupTest()

		updateReq := &types.ProjectUpdateRequest{
			Name: "Updated Project",
		}

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+"123", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userID := testUserID
		updateReq := &types.ProjectUpdateRequest{
			Name: testUpdatedProject,
		}

		// Mock project doesn't exist
		mockSvc.On("UpdateProject", mock.Anything, projectID, userID, updateReq).Return((*types.ProjectUpdateResponse)(nil), errors.New(types.ErrMsgProjectNotFound))

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID+userQueryParam+userID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID
		updateReq := &types.ProjectUpdateRequest{
			Name: testUpdatedProject,
		}

		// Mock project exists but user is not assigned
		mockSvc.On("UpdateProject", mock.Anything, projectID, userID, updateReq).Return((*types.ProjectUpdateResponse)(nil), errors.New(types.ErrMsgUserNotAssignedToProject))

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID+userQueryParam+userID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestDeleteProject(t *testing.T) {
	t.Run("successfully deletes project", func(t *testing.T) {
		r, mockSvc := setupTest()
		projectID := testProjectID
		userID := testUserID
		// Use authenticated method which includes all validations
		mockSvc.On("DeleteProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request when user_id is missing", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userID := testUserID
		mockSvc.On("DeleteProject", mock.Anything, projectID, userID).Return(errors.New(types.ErrMsgProjectNotFound))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when user is not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := "423e4567-e89b-12d3-a456-426614174000"
		mockSvc.On("DeleteProject", mock.Anything, projectID, userID).Return(errors.New(types.ErrMsgUserNotAssignedToProject))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error when service fails", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID
		mockSvc.On("DeleteProject", mock.Anything, projectID, userID).Return(errors.New("database error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run(serviceFailureTest, func(t *testing.T) {
		// Setup fresh router and mock for this test
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID
		// Use authenticated method which includes all validations
		mockSvc.On("DeleteProject", mock.Anything, projectID, userID).Return(errors.New(serviceErrorMsg))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestAssignUserToProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully assigns user to project", func(t *testing.T) {
		projectID := testProjectID
		userEmail := testUserEmail

		expectedResponse := &types.UserAssignmentResponse{
			Message: "User successfully assigned to the project",
		}

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userEmail := testUserEmail

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New(projectNotFoundMessage))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when user doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userEmail := "nonexistent@example.com"

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("user not found"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully handles user already assigned (idempotent)", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userEmail := testUserEmail

		expectedResponse := &types.UserAssignmentResponse{
			Message: "User successfully assigned to the project",
		}

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestRemoveUserFromProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully removes user from project", func(t *testing.T) {
		projectID := testProjectID
		userEmail := testUserEmail

		expectedResponse := &types.UserAssignmentResponse{
			Message: "User successfully removed from the project",
		}

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userEmail := testUserEmail

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New(projectNotFoundMessage))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when user doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userEmail := "nonexistent@example.com"

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("user not found"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when user not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userEmail := testUserEmail

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New(types.ErrMsgUserNotAssignedToProject))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestStarProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully stars project", func(t *testing.T) {
		projectID := testProjectID
		userID := testUserID

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userID := testUserID

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(errors.New(projectNotFoundMessage))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully handles project already starred (idempotent)", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(errors.New(internalErrorMsg))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUnstarProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully unstars project", func(t *testing.T) {
		projectID := testProjectID
		userID := testUserID

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userID := testUserID

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(errors.New("project not found"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully handles project not starred (idempotent)", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(errors.New("internal error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+starPath+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestArchiveProject(t *testing.T) {
	t.Run("successfully archives project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		// Use authenticated method which includes all validations
		mockSvc.On("ArchiveProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userID := testUserID

		// Mock project doesn't exist
		mockSvc.On("ArchiveProject", mock.Anything, projectID, userID).Return(errors.New(types.ErrMsgProjectNotFound))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully handles project already archived (idempotent)", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		// Use authenticated method which includes all validations
		mockSvc.On("ArchiveProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		// Use authenticated method which includes all validations
		mockSvc.On("ArchiveProject", mock.Anything, projectID, userID).Return(errors.New("internal error"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUnarchiveProject(t *testing.T) {
	t.Run("successfully unarchives project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		// Mock the unarchive operation with authentication
		mockSvc.On("UnarchiveProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		userID := testUserID

		// Mock project not found error
		mockSvc.On("UnarchiveProject", mock.Anything, projectID, userID).Return(errors.New(types.ErrMsgProjectNotFound))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully handles project not archived (idempotent)", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		// Mock the unarchive operation with authentication
		mockSvc.On("UnarchiveProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		userID := testUserID

		// Use authenticated method which includes all validations
		mockSvc.On("UnarchiveProject", mock.Anything, projectID, userID).Return(errors.New("internal error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+archivePath+userQueryParam+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}
