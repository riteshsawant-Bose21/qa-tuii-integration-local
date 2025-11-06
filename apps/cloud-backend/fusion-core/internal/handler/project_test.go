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
	projectsEndpoint   = "/projects"
	projectsPathPrefix = "/projects/"
	contentTypeHeader  = "Content-Type"
	applicationJSON    = "application/json"
	serviceFailureTest = "returns error when service fails"
	serviceErrorMsg    = "service error"
	testProjectName    = "Test Project"
	testProjectDesc    = "Test Description"
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

func (m *MockProjectService) UpdateProject(ctx context.Context, id string, project *types.ProjectUpdateRequest) (*types.ProjectUpdateResponse, error) {
	args := m.Called(ctx, id, project)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.ProjectUpdateResponse), args.Error(1)
}

func (m *MockProjectService) DeleteProject(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
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

	return r, mockSvc
}

func TestCreateProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully creates project", func(t *testing.T) {
		project := &types.ProjectCreateRequest{
			Name:        testProjectName,
			Description: testProjectDesc,
			UserID:      "123",
		}

		expectedResponse := &types.ProjectCreateResponse{
			ID: "123e4567-e89b-12d3-a456-426614174000",
		}

		mockSvc.On("CreateProject", mock.Anything, project).Return(expectedResponse, nil)

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
			Name:        testProjectName,
			Description: testProjectDesc,
			UserID:      "123",
		}

		mockSvc.On("CreateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectCreateRequest) bool {
			return req.Name == testProjectName && req.Description == testProjectDesc && req.UserID == "123"
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

		req := httptest.NewRequest(http.MethodGet, projectsEndpoint, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		json.Unmarshal(w.Body.Bytes(), &response)
		assert.Len(t, response.Data, 2)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error with invalid sort parameters", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?sort_by=invalid", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run(serviceFailureTest, func(t *testing.T) {
		// Setup fresh router and mock for this test
		r, mockSvc := setupTest()

		mockSvc.On("GetAllProjects", mock.Anything, mock.MatchedBy(func(params *types.GetAllProjectsParams) bool {
			return params.SortBy == "updated_at" && params.SortOrder == "desc"
		})).Return((*types.GetAllProjectsResponse)(nil), errors.New(serviceErrorMsg))

		req := httptest.NewRequest(http.MethodGet, projectsEndpoint, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUpdateProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully updates project", func(t *testing.T) {
		projectID := "123"
		updateReq := &types.ProjectUpdateRequest{
			Name:        "Updated Project",
			Description: "Updated Description",
		}

		expectedResponse := &types.ProjectUpdateResponse{}

		mockSvc.On("UpdateProject", mock.Anything, projectID, updateReq).Return(expectedResponse, nil)

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+"123", bytes.NewBufferString("invalid json"))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		projectID := "non-existent"
		updateReq := &types.ProjectUpdateRequest{
			Name: "Updated Project",
		}

		mockSvc.On("UpdateProject", mock.Anything, projectID, updateReq).Return(nil, errors.New("project not found"))

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestDeleteProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully deletes project", func(t *testing.T) {
		projectID := "123"
		mockSvc.On("DeleteProject", mock.Anything, projectID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		projectID := "non-existent"
		mockSvc.On("DeleteProject", mock.Anything, projectID).Return(errors.New("project not found"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run(serviceFailureTest, func(t *testing.T) {
		// Setup fresh router and mock for this test
		r, mockSvc := setupTest()

		projectID := "123"
		mockSvc.On("DeleteProject", mock.Anything, projectID).Return(errors.New(serviceErrorMsg))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestAssignUserToProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully assigns user to project", func(t *testing.T) {
		projectID := "123"
		userEmail := "test@example.com"

		expectedResponse := &types.UserAssignmentResponse{
			Message: "User successfully assigned to the project",
		}

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "non-existent"
		userEmail := "test@example.com"

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("project not found"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when user doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userEmail := "nonexistent@example.com"

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("user not found"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns conflict when user already assigned", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userEmail := "test@example.com"

		mockSvc.On("AssignUserToProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("user is already assigned to the project"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusConflict, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestRemoveUserFromProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully removes user from project", func(t *testing.T) {
		projectID := "123"
		userEmail := "test@example.com"

		expectedResponse := &types.UserAssignmentResponse{
			Message: "User successfully removed from the project",
		}

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "non-existent"
		userEmail := "test@example.com"

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("project not found"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when user doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userEmail := "nonexistent@example.com"

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("user not found"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when user not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userEmail := "test@example.com"

		mockSvc.On("RemoveUserFromProjectByEmail", mock.Anything, projectID, userEmail).Return((*types.UserAssignmentResponse)(nil), errors.New("user not assigned to the project"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/users/"+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})
}
