package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockProjectService is a mock implementation of ProjectSVC
type MockProjectService struct {
	mock.Mock
}

func (m *MockProjectService) CreateProject(ctx context.Context, project *fusion.ProjectCreateRequest) error {
	args := m.Called(ctx, project)
	return args.Error(0)
}

func (m *MockProjectService) GetAllProjects(ctx context.Context, queryParams *fusion.GetAllProjectsParams) ([]*fusion.Project, error) {
	args := m.Called(ctx, queryParams)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*fusion.Project), args.Error(1)
}

func (m *MockProjectService) UpdateProject(ctx context.Context, id string, project *fusion.ProjectUpdateRequest) error {
	args := m.Called(ctx, id, project)
	return args.Error(0)
}

func (m *MockProjectService) DeleteProject(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

func setupTest() (*gin.Engine, *MockProjectService) {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	mockSvc := new(MockProjectService)
	handler := NewProjectHandler(mockSvc)

	r.POST("/projects", handler.CreateProject)
	r.GET("/projects", handler.GetAllProjects)
	r.PATCH("/projects/:id", handler.UpdateProject)
	r.DELETE("/projects/:id", handler.DeleteProject)

	return r, mockSvc
}

func TestCreateProject(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully creates project", func(t *testing.T) {
		project := &fusion.ProjectCreateRequest{
			Name:        "Test Project",
			Description: "Test Description",
			AccountID:   "123",
		}

		mockSvc.On("CreateProject", mock.Anything, project).Return(nil)

		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, "/projects", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/projects", bytes.NewBufferString("invalid json"))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns error when service fails", func(t *testing.T) {
		project := &fusion.ProjectCreateRequest{
			Name:        "Test Project",
			Description: "Test Description",
			AccountID:   "123",
		}

		mockSvc.On("CreateProject", mock.Anything, project).Return(errors.New("service error"))

		body, _ := json.Marshal(project)
		req := httptest.NewRequest(http.MethodPost, "/projects", bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}

func TestGetAllProjects(t *testing.T) {
	r, mockSvc := setupTest()

	t.Run("successfully retrieves projects", func(t *testing.T) {
		projects := []*fusion.Project{
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

		params := &fusion.GetAllProjectsParams{
			SortBy:    "updated_at",
			SortOrder: "desc",
		}

		mockSvc.On("GetAllProjects", mock.Anything, params).Return(projects, nil)

		req := httptest.NewRequest(http.MethodGet, "/projects", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response []*fusion.Project
		json.Unmarshal(w.Body.Bytes(), &response)
		assert.Len(t, response, 2)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error with invalid sort parameters", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/projects?sort_by=invalid", nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns error when service fails", func(t *testing.T) {
		params := &fusion.GetAllProjectsParams{
			SortBy:    "updated_at",
			SortOrder: "desc",
		}

		mockSvc.On("GetAllProjects", mock.Anything, params).Return(nil, errors.New("service error"))

		req := httptest.NewRequest(http.MethodGet, "/projects", nil)
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
		updateReq := &fusion.ProjectUpdateRequest{
			Name:        "Updated Project",
			Description: "Updated Description",
		}

		mockSvc.On("UpdateProject", mock.Anything, projectID, updateReq).Return(nil)

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, "/projects/"+projectID, bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error on invalid JSON", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPatch, "/projects/123", bytes.NewBufferString("invalid json"))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		projectID := "non-existent"
		updateReq := &fusion.ProjectUpdateRequest{
			Name: "Updated Project",
		}

		mockSvc.On("UpdateProject", mock.Anything, projectID, updateReq).Return(errors.New("project not found"))

		body, _ := json.Marshal(updateReq)
		req := httptest.NewRequest(http.MethodPatch, "/projects/"+projectID, bytes.NewBuffer(body))
		req.Header.Set("Content-Type", "application/json")
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

		req := httptest.NewRequest(http.MethodDelete, "/projects/"+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNoContent, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns not found when project doesn't exist", func(t *testing.T) {
		projectID := "non-existent"
		mockSvc.On("DeleteProject", mock.Anything, projectID).Return(errors.New("project not found"))

		req := httptest.NewRequest(http.MethodDelete, "/projects/"+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)
		mockSvc.AssertExpectations(t)
	})

	t.Run("returns error when service fails", func(t *testing.T) {
		projectID := "123"
		mockSvc.On("DeleteProject", mock.Anything, projectID).Return(errors.New("service error"))

		req := httptest.NewRequest(http.MethodDelete, "/projects/"+projectID, nil)
		w := httptest.NewRecorder()

		r.ServeHTTP(w, req)

		assert.Equal(t, http.StatusInternalServerError, w.Code)
		mockSvc.AssertExpectations(t)
	})
}
