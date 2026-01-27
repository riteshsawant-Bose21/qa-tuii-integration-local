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
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

type MockProjectService struct {
	mock.Mock
}

func (m *MockProjectService) CreateProject(ctx context.Context, project *types.ProjectCreateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectCreateResponse, error) {
	args := m.Called(ctx, project, userAuth, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.ProjectCreateResponse), args.Error(1)
}

func (m *MockProjectService) GetAllProjects(ctx context.Context, queryParams *types.GetAllProjectsParams, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.GetAllProjectsResponse, error) {
	args := m.Called(ctx, queryParams, userAuth, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.GetAllProjectsResponse), args.Error(1)
}

const (
	projectsEndpoint   = "/projects"
	projectsPathPrefix = "/projects/"
	contentTypeHeader  = "Content-Type"
	applicationJSON    = "application/json"
	serviceErrorMsg    = "service error"
	serviceFailureTest = "returns error when service fails"
	testProjectName    = "Test Project"
	testProjectDesc    = "Test Description"
	testProjectID      = "123e4567-e89b-12d3-a456-426614174000"
	testUserID         = "223e4567-e89b-12d3-a456-426614174000"
	testUserEmail      = "test@example.com"
	testUpdatedProject = "Updated Project"
	usersPath          = "/users/"
	starPath           = "/star/"
	archivePath        = "/archive"

	projectNotFoundMessage = "project not found"
	internalErrorMsg       = "internal error"
)

func (m *MockProjectService) UpdateProject(ctx context.Context, project *types.ProjectUpdateRequest, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.ProjectUpdateResponse, error) {
	args := m.Called(ctx, project, userAuth, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.ProjectUpdateResponse), args.Error(1)
}

func (m *MockProjectService) DeleteProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userAuth, logger)
	return args.Error(0)
}

func (m *MockProjectService) AssignUserToProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error) {
	args := m.Called(ctx, projectID, userEmail, userAuth, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.UserAssignmentResponse), args.Error(1)
}

func (m *MockProjectService) RemoveUserFromProject(ctx context.Context, projectID, userEmail string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) (*types.UserAssignmentResponse, error) {
	args := m.Called(ctx, projectID, userEmail, userAuth, logger)
	result := args.Get(0)
	if result == nil {
		return nil, args.Error(1)
	}
	return result.(*types.UserAssignmentResponse), args.Error(1)
}

func (m *MockProjectService) StarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userID, logger)
	return args.Error(0)
}

func (m *MockProjectService) UnstarProject(ctx context.Context, projectID, userID string, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userID, logger)
	return args.Error(0)
}

func (m *MockProjectService) ArchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userAuth, logger)
	return args.Error(0)
}

func (m *MockProjectService) UnarchiveProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userAuth, logger)
	return args.Error(0)
}

func (m *MockProjectService) LockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userAuth, logger)
	return args.Error(0)
}

func (m *MockProjectService) UnlockProject(ctx context.Context, projectID string, userAuth types.UserAuthorizationResponse, logger *zap.Logger) error {
	args := m.Called(ctx, projectID, userAuth, logger)
	return args.Error(0)
}

func (m *MockProjectService) GetProjectLockUserID(ctx context.Context, projectID string) (bool, string, error) {
	args := m.Called(ctx, projectID)
	return args.Bool(0), args.String(1), args.Error(2)
}

func (m *MockProjectService) GetUserEmailByID(ctx context.Context, userID string) (string, error) {
	args := m.Called(ctx, testUserID)
	return args.String(0), args.Error(1)
}

func (m *MockProjectService) ProjectExists(ctx context.Context, projectID string, logger *zap.Logger) (bool, error) {
	args := m.Called(ctx, projectID, logger)
	return args.Bool(0), args.Error(1)
}

func (m *MockProjectService) IsUserAssigned(ctx context.Context, projectID, userID string, logger *zap.Logger) (bool, error) {
	args := m.Called(ctx, projectID, testUserID, logger)
	return args.Bool(0), args.Error(1)
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

	// Inject authenticated user and logger into context for all test requests
	r.Use(func(c *gin.Context) {
		logger, _ := zap.NewProduction()
		c.Set("user_auth", &types.UserAuthorizationResponse{User: types.UserInfo{ID: testUserID, Email: testUserEmail}})
		c.Set("logger", logger)
		c.Next()
	})

	r.POST(projectsEndpoint, handler.CreateProject)
	r.GET(projectsEndpoint, handler.GetAllProjects)
	r.PATCH(projectsEndpoint+"/:projectId", handler.UpdateProject)
	r.DELETE(projectsEndpoint+"/:projectId", handler.DeleteProject)
	r.PUT(projectsEndpoint+"/:projectId/users/:userEmail", handler.AssignUserToProject)
	r.DELETE(projectsEndpoint+"/:projectId/users/:userEmail", handler.RemoveUserFromProject)
	r.POST(projectsEndpoint+"/:projectId/star/:userId", handler.UpdateProjectStar)
	r.POST(projectsEndpoint+"/:projectId/archive", handler.UpdateProjectArchive)
	r.POST(projectsEndpoint+"/:projectId/lock", handler.UpdateProjectLock)

	return r, mockSvc
}

func TestCreateProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully creates project", func(t *testing.T) {
		projectID := uuid.New().String()
		project := &types.ProjectCreateRequest{
			ID:              projectID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Application:     "test-app",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		expectedResponse := &types.ProjectCreateResponse{
			ID: projectID,
		}

		// Mock should expect the request after validation, which sets default project phase
		expectedProject := *project
		expectedProject.ProjectPhase = types.ProjectPhaseProposal // validation sets this default
		mockSvc.On("CreateProject", mock.Anything, &expectedProject, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(expectedResponse, nil)

		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		if w.Code != http.StatusCreated {
			t.Logf("Response status: %d, body: %s", w.Code, w.Body.String())
		}
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

		projectID := uuid.New().String()
		project := &types.ProjectCreateRequest{
			ID:              projectID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Application:     "test-app",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}

		mockSvc.On("CreateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectCreateRequest) bool {
			return req.Name == testProjectName && req.Description == testProjectDesc && req.Application == "test-app" && req.ProjectPhase == types.ProjectPhaseProposal
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.ProjectCreateResponse)(nil), errors.New(serviceErrorMsg))

		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns validation error on missing required fields", func(t *testing.T) {
		// Missing Application and Budget currency invalid
		r, mockSvc := setupTest()
		projectID := uuid.New().String()
		project := &types.ProjectCreateRequest{
			ID:              projectID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "US", // invalid length triggers validation error
			},
		}
		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertNotCalled(t, "CreateProject")
	})

	t.Run("returns validation error on negative budget amount", func(t *testing.T) {
		r, mockSvc := setupTest()
		projectID := uuid.New().String()
		project := &types.ProjectCreateRequest{
			ID:              projectID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Application:     "test-app",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   -1000, // negative amount should fail validation
				Currency: "USD",
			},
		}
		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		assert.Contains(t, w.Body.String(), "budget amount must be non-negative")
		mockSvc.AssertNotCalled(t, "CreateProject")
	})

	t.Run("returns error when user_auth context missing", func(t *testing.T) {
		// Create router without authentication middleware but with logger
		gin.SetMode(gin.TestMode)
		r := gin.New()
		mockSvc := new(MockProjectService)
		handler := NewProjectHandler(mockSvc)

		// Add logger but not user_auth to test user_auth validation
		r.Use(func(c *gin.Context) {
			logger, _ := zap.NewProduction()
			c.Set("logger", logger)
			c.Next()
		})

		r.POST(projectsEndpoint, handler.CreateProject)

		projectID := uuid.New().String()
		project := &types.ProjectCreateRequest{
			ID:              projectID,
			Name:            testProjectName,
			Description:     testProjectDesc,
			Application:     "test-app",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
		}
		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, projectsEndpoint, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertNotCalled(t, "CreateProject")
	})
}

func TestGetAllProjects(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("returns unauthorized when user_auth context missing", func(t *testing.T) {
		// Create router without authentication middleware but with logger
		gin.SetMode(gin.TestMode)
		r := gin.New()
		mockSvc := new(MockProjectService)
		handler := NewProjectHandler(mockSvc)

		// Add logger but not user_auth to test user_auth validation
		r.Use(func(c *gin.Context) {
			logger, _ := zap.NewProduction()
			c.Set("logger", logger)
			c.Next()
		})

		r.GET(projectsEndpoint, handler.GetAllProjects)

		req := httptest.NewRequest(http.MethodGet, projectsEndpoint, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertNotCalled(t, "GetAllProjects")
	})

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

		mockSvc.On("GetAllProjects", mock.Anything, params, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?sort_by=updated_at&sort_order=desc", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		if err := json.Unmarshal(w.Body.Bytes(), &response); err != nil {
			t.Errorf("failed to unmarshal response: %v", err)
		}
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
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.GetAllProjectsResponse)(nil), errors.New(serviceErrorMsg))

		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?sort_by=updated_at&sort_order=desc", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request on query binding error", func(t *testing.T) {
		// is_archived expects bool
		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?is_archived=notabool", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("applies default sort parameters", func(t *testing.T) {
		// Only user_id provided; handler sets sort_by=updated_at sort_order=desc
		r, mockSvc := setupTest()
		mockSvc.On("GetAllProjects", mock.Anything, mock.MatchedBy(func(params *types.GetAllProjectsParams) bool {
			return params.SortBy == "updated_at" && params.SortOrder == "desc"
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(&types.GetAllProjectsResponse{Data: []types.Project{}, TotalCount: 0, Page: 1, TotalPages: 1}, nil)
		req := httptest.NewRequest(http.MethodGet, projectsEndpoint+"?user_id="+testProjectID, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusOK, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUpdateProject(t *testing.T) {
	t.Run("successfully updates project", func(t *testing.T) {
		r, mockSvc := setupTest()
		projectID := testProjectID
		updateReq := &types.ProjectUpdateRequest{
			Name:        "Updated Project",
			Description: "Updated Description",
		}

		expectedResponse := &types.ProjectUpdateResponse{}

		// Use authenticated method which includes all validations
		mockSvc.On("UpdateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectUpdateRequest) bool {
			return req.Name == updateReq.Name && req.Description == updateReq.Description
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(expectedResponse, nil)

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		r, mockSvc := setupTest()

		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+testProjectID, bytes.NewBufferString("invalid json"))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		updateReq := &types.ProjectUpdateRequest{
			Name: testUpdatedProject,
		}

		// Mock project doesn't exist
		mockSvc.On("UpdateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectUpdateRequest) bool { return req.ID == projectID && req.Name == updateReq.Name }), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.ProjectUpdateResponse)(nil), errors.New(types.ErrMsgProjectNotFound))

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns unauthorized when user not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		updateReq := &types.ProjectUpdateRequest{
			Name: testUpdatedProject,
		}

		// Mock project exists but user is not assigned
		mockSvc.On("UpdateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectUpdateRequest) bool { return req.ID == projectID && req.Name == updateReq.Name }), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.ProjectUpdateResponse)(nil), errors.New(types.ErrMsgUserNotAssignedToProject))

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+projectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found on invalid project UUID format", func(t *testing.T) {
		r, _ := setupTest()
		updateReq := &types.ProjectUpdateRequest{Name: testUpdatedProject}
		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+"not-a-uuid", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	t.Run("returns bad request on validation failure (empty name)", func(t *testing.T) {
		r, _ := setupTest()
		updateReq := &types.ProjectUpdateRequest{Name: "   "}
		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+testProjectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns unauthorized when user not found", func(t *testing.T) {
		r, mockSvc := setupTest()
		updateReq := &types.ProjectUpdateRequest{Name: testUpdatedProject}
		mockSvc.On("UpdateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectUpdateRequest) bool {
			return req.ID == testProjectID && req.Name == updateReq.Name
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.ProjectUpdateResponse)(nil), errors.New(types.ErrMsgUserNotFound))
		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+testProjectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusUnauthorized, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when project archived", func(t *testing.T) {
		r, mockSvc := setupTest()
		updateReq := &types.ProjectUpdateRequest{Name: testUpdatedProject}
		mockSvc.On("UpdateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectUpdateRequest) bool {
			return req.ID == testProjectID && req.Name == updateReq.Name
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.ProjectUpdateResponse)(nil), errors.New(types.ErrMsgProjectArchived))
		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+testProjectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when project locked by another user", func(t *testing.T) {
		r, mockSvc := setupTest()
		updateReq := &types.ProjectUpdateRequest{Name: testUpdatedProject}
		mockSvc.On("UpdateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectUpdateRequest) bool {
			return req.ID == testProjectID && req.Name == updateReq.Name
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.ProjectUpdateResponse)(nil), errors.New(types.ErrMsgProjectLockedByUser+" other-user"))
		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+testProjectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on unexpected service error", func(t *testing.T) {
		r, mockSvc := setupTest()
		updateReq := &types.ProjectUpdateRequest{Name: testUpdatedProject}
		mockSvc.On("UpdateProject", mock.Anything, mock.MatchedBy(func(req *types.ProjectUpdateRequest) bool {
			return req.ID == testProjectID && req.Name == updateReq.Name
		}), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.ProjectUpdateResponse)(nil), errors.New("db timeout"))
		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, projectsPathPrefix+testProjectID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestDeleteProject(t *testing.T) {
	t.Run("successfully deletes project", func(t *testing.T) {
		r, mockSvc := setupTest()
		projectID := testProjectID
		// Use authenticated method which includes all validations
		mockSvc.On("DeleteProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(nil)

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		mockSvc.On("DeleteProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectNotFound))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when user is not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		mockSvc.On("DeleteProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgUserNotAssignedToProject))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error when service fails", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		mockSvc.On("DeleteProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New("database error"))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run(serviceFailureTest, func(t *testing.T) {
		// Setup fresh router and mock for this test
		r, mockSvc := setupTest()

		projectID := testProjectID
		// Use authenticated method which includes all validations
		mockSvc.On("DeleteProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(serviceErrorMsg))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found on invalid project UUID format", func(t *testing.T) {
		r, _ := setupTest()
		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+"not-a-uuid", nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	t.Run("returns forbidden when project archived", func(t *testing.T) {
		r, mockSvc := setupTest()
		mockSvc.On("DeleteProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectArchived))
		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+testProjectID, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when locked by another user", func(t *testing.T) {
		r, mockSvc := setupTest()
		mockSvc.On("DeleteProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectLockedByUser + " other-user"))
		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+testProjectID, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when user not found", func(t *testing.T) {
		r, mockSvc := setupTest()
		mockSvc.On("DeleteProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgUserNotFound))
		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+testProjectID, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
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

		mockSvc.On("AssignUserToProject", mock.Anything, projectID, mock.AnythingOfType("string"), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(expectedResponse, nil)

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

		mockSvc.On("AssignUserToProject", mock.Anything, projectID, mock.AnythingOfType("string"), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.UserAssignmentResponse)(nil), errors.New(projectNotFoundMessage))

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

		mockSvc.On("AssignUserToProject", mock.Anything, projectID, mock.AnythingOfType("string"), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.UserAssignmentResponse)(nil), errors.New("user not found"))

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

		mockSvc.On("AssignUserToProject", mock.Anything, projectID, mock.AnythingOfType("string"), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(expectedResponse, nil)

		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request when project ID invalid format", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+"not-a-uuid"+usersPath+testUserEmail, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns internal server error on unexpected failure", func(t *testing.T) {
		// fresh router + mock to avoid earlier expectations
		r, mockSvc := setupTest()
		projectID := testProjectID
		userEmail := testUserEmail
		mockSvc.On("AssignUserToProject", mock.Anything, projectID, mock.AnythingOfType("string"), mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.UserAssignmentResponse)(nil), errors.New("db error"))
		req := httptest.NewRequest(http.MethodPut, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusInternalServerError, w.Code)
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

		mockSvc.On("RemoveUserFromProject", mock.Anything, projectID, userEmail, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(expectedResponse, nil)

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

		mockSvc.On("RemoveUserFromProject", mock.Anything, projectID, userEmail, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.UserAssignmentResponse)(nil), errors.New(projectNotFoundMessage))

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

		mockSvc.On("RemoveUserFromProject", mock.Anything, projectID, userEmail, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.UserAssignmentResponse)(nil), errors.New("user not found"))

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

		mockSvc.On("RemoveUserFromProject", mock.Anything, projectID, userEmail, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.UserAssignmentResponse)(nil), errors.New(types.ErrMsgUserNotAssignedToProject))

		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns bad request when project ID invalid format", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+"not-a-uuid"+usersPath+testUserEmail, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns internal server error on unexpected failure", func(t *testing.T) {
		// fresh router + mock to avoid earlier expectations
		r, mockSvc := setupTest()
		projectID := testProjectID
		userEmail := testUserEmail
		mockSvc.On("RemoveUserFromProject", mock.Anything, projectID, userEmail, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return((*types.UserAssignmentResponse)(nil), errors.New("db error"))
		req := httptest.NewRequest(http.MethodDelete, projectsPathPrefix+projectID+usersPath+userEmail, nil)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUpdateProjectStar(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully stars project", func(t *testing.T) {
		projectID := testProjectID
		starReq := types.ProjectStarRequest{IsStarred: true}

		mockSvc.On("StarProject", mock.Anything, projectID, testUserID, mock.AnythingOfType("*zap.Logger")).Return(nil)

		body, _ := json.Marshal(starReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+starPath+testUserID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully unstars project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		starReq := types.ProjectStarRequest{IsStarred: false}

		mockSvc.On("UnstarProject", mock.Anything, projectID, testUserID, mock.AnythingOfType("*zap.Logger")).Return(nil)

		body, _ := json.Marshal(starReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+starPath+testUserID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		starReq := types.ProjectStarRequest{IsStarred: true}

		mockSvc.On("StarProject", mock.Anything, projectID, testUserID, mock.AnythingOfType("*zap.Logger")).Return(errors.New(projectNotFoundMessage))

		body, _ := json.Marshal(starReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+starPath+testUserID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID

		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+starPath+testUserID, bytes.NewBufferString("invalid json"))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		starReq := types.ProjectStarRequest{IsStarred: true}

		mockSvc.On("StarProject", mock.Anything, projectID, testUserID, mock.AnythingOfType("*zap.Logger")).Return(errors.New(internalErrorMsg))

		body, _ := json.Marshal(starReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+starPath+testUserID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found on invalid project UUID format", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+"not-a-uuid"+starPath+testUserID, bytes.NewBuffer([]byte(`{"is_starred":true}`)))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	t.Run("returns forbidden when user not assigned to project", func(t *testing.T) {
		r, mockSvc := setupTest()
		starReq := types.ProjectStarRequest{IsStarred: true}
		mockSvc.On("StarProject", mock.Anything, testProjectID, testUserID, mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgUserNotAssignedToProject))
		body, _ := json.Marshal(starReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+starPath+testUserID, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUpdateProjectArchive(t *testing.T) {
	t.Run("successfully archives project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		archiveReq := types.ProjectArchiveRequest{Archive: true}

		// Use authenticated method which includes all validations
		mockSvc.On("ArchiveProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(nil)

		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully unarchives project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		archiveReq := types.ProjectArchiveRequest{Archive: false}

		// Use authenticated method which includes all validations
		mockSvc.On("UnarchiveProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(nil)

		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		archiveReq := types.ProjectArchiveRequest{Archive: true}

		// Mock project doesn't exist
		mockSvc.On("ArchiveProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectNotFound))

		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID

		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+archivePath, bytes.NewBufferString("invalid json"))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		archiveReq := types.ProjectArchiveRequest{Archive: true}

		// Use authenticated method which includes all validations
		mockSvc.On("ArchiveProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New("internal error"))

		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found on invalid project UUID format", func(t *testing.T) {
		r, _ := setupTest()
		archiveReq := types.ProjectArchiveRequest{Archive: true}
		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+"not-a-uuid"+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	t.Run("returns forbidden when user not assigned", func(t *testing.T) {
		r, mockSvc := setupTest()
		archiveReq := types.ProjectArchiveRequest{Archive: true}
		mockSvc.On("ArchiveProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgUserNotAssignedToProject))
		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when locked by another user", func(t *testing.T) {
		r, mockSvc := setupTest()
		archiveReq := types.ProjectArchiveRequest{Archive: true}
		mockSvc.On("ArchiveProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectLockedByUser + " other-user"))
		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when user not found", func(t *testing.T) {
		r, mockSvc := setupTest()
		archiveReq := types.ProjectArchiveRequest{Archive: true}
		mockSvc.On("ArchiveProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgUserNotFound))
		body, _ := json.Marshal(archiveReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+archivePath, bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestUpdateProjectLock(t *testing.T) {
	t.Run("successfully locks project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		lockReq := types.ProjectLockRequest{IsLocked: true}

		mockSvc.On("LockProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(nil)

		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("successfully unlocks project", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		lockReq := types.ProjectLockRequest{IsLocked: false}

		mockSvc.On("UnlockProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(nil)

		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := "323e4567-e89b-12d3-a456-426614174000"
		lockReq := types.ProjectLockRequest{IsLocked: true}

		mockSvc.On("LockProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectNotFound))

		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID

		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+"/lock", bytes.NewBufferString("invalid json"))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns internal server error on service failure", func(t *testing.T) {
		r, mockSvc := setupTest()

		projectID := testProjectID
		lockReq := types.ProjectLockRequest{IsLocked: true}

		mockSvc.On("LockProject", mock.Anything, projectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New("internal error"))

		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+projectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found on invalid project UUID format", func(t *testing.T) {
		r, _ := setupTest()
		lockReq := types.ProjectLockRequest{IsLocked: true}
		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+"not-a-uuid"+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	t.Run("returns forbidden when user not assigned", func(t *testing.T) {
		r, mockSvc := setupTest()
		lockReq := types.ProjectLockRequest{IsLocked: true}
		mockSvc.On("LockProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgUserNotAssignedToProject))
		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when user not found", func(t *testing.T) {
		r, mockSvc := setupTest()
		lockReq := types.ProjectLockRequest{IsLocked: true}
		mockSvc.On("LockProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgUserNotFound))
		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when project already locked by another user", func(t *testing.T) {
		r, mockSvc := setupTest()
		lockReq := types.ProjectLockRequest{IsLocked: true}
		mockSvc.On("LockProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectLockedByUser + " other-user"))
		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns forbidden when unlocking not locked by user", func(t *testing.T) {
		r, mockSvc := setupTest()
		lockReq := types.ProjectLockRequest{IsLocked: false}
		mockSvc.On("UnlockProject", mock.Anything, testProjectID, mock.AnythingOfType("types.UserAuthorizationResponse"), mock.AnythingOfType("*zap.Logger")).Return(errors.New(types.ErrMsgProjectNotLockedByUser))
		body, _ := json.Marshal(lockReq)
		req := httptest.NewRequest(http.MethodPost, projectsPathPrefix+testProjectID+"/lock", bytes.NewBuffer(body))
		req.Header.Set(contentTypeHeader, applicationJSON)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)
		mockSvc.AssertExpectations(t)
	})
}
