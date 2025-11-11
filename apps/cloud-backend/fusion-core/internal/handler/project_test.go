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

func (m *MockProjectService) StarProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) UnstarProject(ctx context.Context, projectID, userID string) error {
	args := m.Called(ctx, projectID, userID)
	return args.Error(0)
}

func (m *MockProjectService) ArchiveProject(ctx context.Context, projectID string) error {
	args := m.Called(ctx, projectID)
	return args.Error(0)
}

func (m *MockProjectService) UnarchiveProject(ctx context.Context, projectID string) error {
	args := m.Called(ctx, projectID)
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
	t.Run("successfully updates project", func(t *testing.T) {
		r, mockSvc := setupTest()
		projectID := "123"
		userID := "user-123"
		updateReq := &types.ProjectUpdateRequest{
			Name:        "Updated Project",
			Description: "Updated Description",
		}

		expectedResponse := &types.ProjectUpdateResponse{}

		// Mock the authorization checks
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(true, nil)
		mockSvc.On("IsUserAssigned", mock.Anything, projectID, userID).Return(true, nil)
		mockSvc.On("UpdateProject", mock.Anything, projectID, updateReq).Return(expectedResponse, nil)

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID+"?user_id="+userID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		r, mockSvc := setupTest()

		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+"123?user_id=user-123", bytes.NewBufferString("invalid json"))
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

		projectID := "non-existent"
		userID := "user-123"
		updateReq := &types.ProjectUpdateRequest{
			Name: "Updated Project",
		}

		// Mock project doesn't exist
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(false, nil)

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID+"?user_id="+userID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user-123"
		updateReq := &types.ProjectUpdateRequest{
			Name: "Updated Project",
		}

		// Mock project exists but user is not assigned
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(true, nil)
		mockSvc.On("IsUserAssigned", mock.Anything, projectID, userID).Return(false, nil)

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID+"?user_id="+userID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestDeleteProject(t *testing.T) {
	t.Run("successfully deletes project", func(t *testing.T) {
		r, mockSvc := setupTest()
		projectID := "123"
		userID := "user-123"
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(true, nil)
		mockSvc.On("IsUserAssigned", mock.Anything, projectID, userID).Return(true, nil)
		mockSvc.On("DeleteProject", mock.Anything, projectID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"?user_id="+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request when user_id is missing", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "non-existent"
		userID := "user-123"
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(false, nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"?user_id="+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user is not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "unauthorized-user"
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(true, nil)
		mockSvc.On("IsUserAssigned", mock.Anything, projectID, userID).Return(false, nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"?user_id="+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error when ProjectExists check fails", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user-123"
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(false, errors.New("database error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"?user_id="+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error when IsUserAssigned check fails", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user-123"
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(true, nil)
		mockSvc.On("IsUserAssigned", mock.Anything, projectID, userID).Return(false, errors.New("database error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"?user_id="+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run(serviceFailureTest, func(t *testing.T) {
		// Setup fresh router and mock for this test
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user-123"
		mockSvc.On("ProjectExists", mock.Anything, projectID).Return(true, nil)
		mockSvc.On("IsUserAssigned", mock.Anything, projectID, userID).Return(true, nil)
		mockSvc.On("DeleteProject", mock.Anything, projectID).Return(errors.New(serviceErrorMsg))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"?user_id="+userID, nil)
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

func TestStarProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully stars project", func(t *testing.T) {
		projectID := "123"
		userID := "user123"

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "non-existent"
		userID := "user123"

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(errors.New("project not found"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns conflict when project already starred", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user123"

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(errors.New("project is already starred"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusConflict, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user123"

		mockSvc.On("StarProject", mock.Anything, projectID, userID).Return(errors.New("internal error"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUnstarProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully unstars project", func(t *testing.T) {
		projectID := "123"
		userID := "user123"

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "non-existent"
		userID := "user123"

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(errors.New("project not found"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project not starred", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user123"

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(errors.New("project is not starred"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "123"
		userID := "user123"

		mockSvc.On("UnstarProject", mock.Anything, projectID, userID).Return(errors.New("internal error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/star/"+userID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestArchiveProject(t *testing.T) {
	t.Run("successfully archives project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "test-project-id"

		mockSvc.On("ArchiveProject", mock.Anything, projectID).Return(nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "non-existent"

		mockSvc.On("ArchiveProject", mock.Anything, projectID).Return(errors.New("project not found"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project already archived", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "already-archived"

		mockSvc.On("ArchiveProject", mock.Anything, projectID).Return(errors.New("project is already archived"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "test-project-id"

		mockSvc.On("ArchiveProject", mock.Anything, projectID).Return(errors.New("internal error"))

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUnarchiveProject(t *testing.T) {
	t.Run("successfully unarchives project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "test-project-id"

		mockSvc.On("UnarchiveProject", mock.Anything, projectID).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "non-existent"

		mockSvc.On("UnarchiveProject", mock.Anything, projectID).Return(errors.New("project not found"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project not archived", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "not-archived"

		mockSvc.On("UnarchiveProject", mock.Anything, projectID).Return(errors.New("project is not archived"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "test-project-id"

		mockSvc.On("UnarchiveProject", mock.Anything, projectID).Return(errors.New("internal error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+"/archive", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}
