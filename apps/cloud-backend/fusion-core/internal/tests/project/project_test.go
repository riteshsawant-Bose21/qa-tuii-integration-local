// Package project provides integration tests for project endpoints.
package project

import (
	"encoding/json"
	"net/http"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/tests/testutils"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// ProjectIntegrationTestSuite defines the test suite for project integration tests.
type ProjectIntegrationTestSuite struct {
	testutils.BaseIntegrationSuite
	testProjects []testutils.TestProject
}

// SetupSuite runs once before all tests in the suite.
func (suite *ProjectIntegrationTestSuite) SetupSuite() {
	suite.BaseIntegrationSuite.SetupSuite()
	suite.initTestProjects()
	suite.setupRouter()
}

// initTestProjects initializes test projects for the suite.
func (suite *ProjectIntegrationTestSuite) initTestProjects() {
	suite.testProjects = []testutils.TestProject{
		{
			ID:              uuid.New().String(),
			Name:            "Integration Test Conference Room",
			Description:     "Integration test project for conference room audio system",
			Application:     "Corporate Conference Room",
			Venue:           "Integration Test Building - Conference Room 1",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   50000,
				Currency: "USD",
			},
			IsProjectFileCreated:      true,
			IsProjectThumbnailCreated: true,
		},
		{
			ID:              uuid.New().String(),
			Name:            "Integration Test Auditorium",
			Description:     "Integration test project for auditorium sound system",
			Application:     "Educational Facility",
			Venue:           "Integration Test University - Main Auditorium",
			ProjectPhase:    types.ProjectPhaseDevelopment,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   75000,
				Currency: "USD",
			},
			IsProjectFileCreated:      true,
			IsProjectThumbnailCreated: true,
		},
	}
}

// setupRouter configures the Gin router with project routes.
func (suite *ProjectIntegrationTestSuite) setupRouter() {
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(middleware.RequestLoggerMiddleware(suite.Loggers.AuditLogger))
	router.Use(middleware.ApplicationLoggerMiddleware(suite.Loggers.AppLogger))
	router.Use(middleware.ExtractUserFromHeaders())

	projectHandler := handler.NewProjectHandler(suite.ProjectSVC)

	api := router.Group("/api/v1")
	projects := api.Group("/projects")
	{
		projects.POST("", projectHandler.CreateProject)
		projects.GET("", projectHandler.GetAllProjects)
		projects.PATCH("/:projectId", projectHandler.UpdateProject)
		projects.DELETE("/:projectId", projectHandler.DeleteProject)
		projects.PUT("/:projectId/users/:userEmail", projectHandler.AssignUserToProject)
		projects.DELETE("/:projectId/users/:userEmail", projectHandler.RemoveUserFromProject)
		projects.POST("/:projectId/star/:userId", projectHandler.UpdateProjectStar)
		projects.POST("/:projectId/archive", projectHandler.UpdateProjectArchive)
		projects.POST("/:projectId/lock", projectHandler.UpdateProjectLock)
	}

	suite.GinRouter = router
}

// TestCreateProject tests the POST /api/v1/projects endpoint.
func (suite *ProjectIntegrationTestSuite) TestCreateProject() {
	suite.T().Run("should create project successfully as super admin", func(t *testing.T) {
		project := suite.testProjects[0]
		project.ID = uuid.New().String()

		// Super Admin (admin@bose.com) creates project
		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects", project, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.ID)
	})

	suite.T().Run("should create project as end user admin", func(t *testing.T) {
		project := suite.testProjects[0]
		project.ID = uuid.New().String()

		// End User Admin (test@domain.com) creates project
		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects", project, "60000001-0000-4000-8000-000000000006")
		require.NoError(t, err)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.ID)
	})

	suite.T().Run("should create project as reseller designer", func(t *testing.T) {
		project := suite.testProjects[1]
		project.ID = uuid.New().String()

		// Reseller Designer (mike.designer@audiotech.com) creates project
		allUsers := testutils.GetDefaultTestUsers()
		designerUser := allUsers[2] // mike.designer@audiotech.com
		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects", project, designerUser.ID)
		require.NoError(t, err)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.ID)
	})

	suite.T().Run("should fail with invalid project data", func(t *testing.T) {
		invalidProject := testutils.TestProject{
			ID:   uuid.New().String(),
			Name: "", // Missing required name
		}

		w, err := suite.MakeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should fail when auth headers missing", func(t *testing.T) {
		project := suite.testProjects[0]
		project.ID = uuid.New().String()

		// Send request without required auth headers
		w, err := suite.MakeRequestWithHeaders("POST", "/api/v1/projects", project, map[string]string{})
		require.NoError(t, err)

		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	suite.T().Run("should rollback transaction on validation failure", func(t *testing.T) {
		// Count projects before the failed attempt
		w, err := suite.MakeRequest("GET", "/api/v1/projects", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var beforeResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &beforeResponse)
		require.NoError(t, err)
		initialProjectCount := beforeResponse.TotalCount

		// Try to create project with invalid data
		projectWithInvalidData := types.ProjectCreateRequest{
			ID:              uuid.New().String(),
			Name:            "",
			Description:     "This should fail validation",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
		}

		w, err = suite.MakeRequest("POST", "/api/v1/projects", projectWithInvalidData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Verify project count unchanged
		w, err = suite.MakeRequest("GET", "/api/v1/projects", nil)
		require.NoError(t, err)

		var afterResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &afterResponse)
		require.NoError(t, err)

		assert.Equal(t, initialProjectCount, afterResponse.TotalCount)
	})
}

// TestGetAllProjects tests the GET /api/v1/projects endpoint.
func (suite *ProjectIntegrationTestSuite) TestGetAllProjects() {
	// Create a test project as super admin
	project := suite.testProjects[0]
	project.ID = uuid.New().String()
	w, err := suite.MakeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	suite.T().Run("should get all projects as super admin", func(t *testing.T) {
		w, err := suite.MakeRequestWithUser("GET", "/api/v1/projects", nil, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.GreaterOrEqual(t, len(response.Data), 1)
		assert.Greater(t, response.TotalCount, 0)
	})

	suite.T().Run("should get projects as end user admin", func(t *testing.T) {
		// End User Admin (test@domain.com) - should see only their account's projects
		w, err := suite.MakeRequestWithUser("GET", "/api/v1/projects", nil, "60000001-0000-4000-8000-000000000006")
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
	})

	suite.T().Run("should get projects as operator user", func(t *testing.T) {
		// Operator (prof.operator@university.edu) - should see only projects they are assigned to
		w, err := suite.MakeRequestWithUser("GET", "/api/v1/projects", nil, "60000001-0000-4000-8000-000000000007")
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
	})

	suite.T().Run("should get projects as service user", func(t *testing.T) {
		// Service user (service@bose.com) from Bose Corporation
		allUsers := testutils.GetDefaultTestUsers()
		serviceUser := allUsers[1] // service@bose.com
		w, err := suite.MakeRequestWithUser("GET", "/api/v1/projects", nil, serviceUser.ID)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
	})

	suite.T().Run("should filter archived projects", func(t *testing.T) {
		w, err := suite.MakeRequest("GET", "/api/v1/projects?is_archived=true", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		for _, project := range response.Data {
			assert.True(t, project.IsArchived)
		}
	})
}

// TestUpdateProject tests the PATCH /api/v1/projects/{projectId} endpoint.
func (suite *ProjectIntegrationTestSuite) TestUpdateProject() {
	// Create a project as super admin for this test
	project := suite.testProjects[0]
	project.ID = uuid.New().String()
	w, err := suite.MakeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should update project successfully as super admin", func(t *testing.T) {
		require.NotEmpty(t, projectID)

		updateData := types.ProjectUpdateRequest{
			Name:               "Updated Test Conference Room",
			Description:        "Updated description for integration test",
			Application:        "Updated Corporate Conference Room",
			IsProjectFileDirty: true,
		}

		w, err := suite.MakeRequestWithUser("PATCH", "/api/v1/projects/"+projectID, updateData, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})

	suite.T().Run("should fail with invalid project ID", func(t *testing.T) {
		updateData := types.ProjectUpdateRequest{
			Name: "Updated Name",
		}

		w, err := suite.MakeRequest("PATCH", "/api/v1/projects/invalid-uuid", updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should fail for non-existent project", func(t *testing.T) {
		updateData := types.ProjectUpdateRequest{
			Name: "Updated Name",
		}

		nonExistentID := uuid.New().String()
		w, err := suite.MakeRequest("PATCH", "/api/v1/projects/"+nonExistentID, updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should fail when auth headers missing", func(t *testing.T) {
		updateData := types.ProjectUpdateRequest{
			Name: "Updated Name",
		}

		w, err := suite.MakeRequestWithHeaders("PATCH", "/api/v1/projects/"+projectID, updateData, map[string]string{})
		require.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// TestDeleteProject tests the DELETE /api/v1/projects/{projectId} endpoint.
func (suite *ProjectIntegrationTestSuite) TestDeleteProject() {
	// Create a project for deletion as super admin
	project := suite.testProjects[1]
	project.ID = uuid.New().String()
	w, err := suite.MakeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign user to project
	userEmail := suite.TestUsers[0].Email
	w, err = suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should fail when auth headers missing", func(t *testing.T) {
		w, err := suite.MakeRequestWithHeaders("DELETE", "/api/v1/projects/"+projectID, nil, map[string]string{})
		require.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})

	suite.T().Run("should delete project successfully as super admin", func(t *testing.T) {
		w, err := suite.MakeRequestWithUser("DELETE", "/api/v1/projects/"+projectID, nil, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail for invalid project ID", func(t *testing.T) {
		w, err := suite.MakeRequest("DELETE", "/api/v1/projects/invalid-uuid", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

// TestAssignUserToProject tests the PUT /api/v1/projects/{projectId}/users/{userEmail} endpoint.
func (suite *ProjectIntegrationTestSuite) TestAssignUserToProject() {
	// Create a project as super admin
	project := suite.testProjects[0]
	project.ID = uuid.New().String()
	w, err := suite.MakeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should assign end user admin to project", func(t *testing.T) {
		// Assign test@domain.com (End User Admin)
		userEmail := suite.TestUsers[1].Email
		w, err := suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should assign operator to project", func(t *testing.T) {
		// Assign prof.operator@university.edu (Operator)
		userEmail := suite.TestUsers[2].Email
		w, err := suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should assign designer from different account", func(t *testing.T) {
		// Assign mike.designer@audiotech.com (Reseller Designer from AudioTech)
		allUsers := testutils.GetDefaultTestUsers()
		designerEmail := allUsers[2].Email // mike.designer@audiotech.com
		w, err := suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+designerEmail, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail for invalid project ID", func(t *testing.T) {
		userEmail := suite.TestUsers[0].Email
		w, err := suite.MakeRequest("PUT", "/api/v1/projects/invalid-uuid/users/"+userEmail, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

// TestUpdateProjectStar tests the POST /api/v1/projects/{projectId}/star/{userId} endpoint.
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectStar() {
	// Create a project as super admin
	project := suite.testProjects[0]
	project.ID = uuid.New().String()
	w, err := suite.MakeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign super admin user
	userID := suite.TestUsers[0].ID
	userEmail := suite.TestUsers[0].Email
	w, err = suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	// Assign end user admin
	endUserAdminID := suite.TestUsers[1].ID
	endUserAdminEmail := suite.TestUsers[1].Email
	w, err = suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+endUserAdminEmail, nil)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should star project as super admin", func(t *testing.T) {
		starRequest := types.ProjectStarRequest{
			IsStarred: true,
		}

		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest, userID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unstar project as super admin", func(t *testing.T) {
		starRequest := types.ProjectStarRequest{
			IsStarred: false,
		}

		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest, userID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should star project as end user admin", func(t *testing.T) {
		starRequest := types.ProjectStarRequest{
			IsStarred: true,
		}

		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/star/"+endUserAdminID, starRequest, endUserAdminID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// TestUpdateProjectArchive tests the POST /api/v1/projects/{projectId}/archive endpoint.
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectArchive() {
	// Create a project as super admin
	project := suite.testProjects[0]
	project.ID = uuid.New().String()
	w, err := suite.MakeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign super admin user
	userEmail := suite.TestUsers[0].Email
	w, err = suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should archive project as super admin", func(t *testing.T) {
		archiveRequest := types.ProjectArchiveRequest{
			Archive: true,
		}

		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unarchive project as super admin", func(t *testing.T) {
		archiveRequest := types.ProjectArchiveRequest{
			Archive: false,
		}

		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail when auth headers missing", func(t *testing.T) {
		archiveRequest := types.ProjectArchiveRequest{
			Archive: true,
		}

		w, err := suite.MakeRequestWithHeaders("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest, map[string]string{})
		require.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// TestUpdateProjectLock tests the POST /api/v1/projects/{projectId}/lock endpoint.
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectLock() {
	// Create a project as super admin
	project := suite.testProjects[0]
	project.ID = uuid.New().String()
	w, err := suite.MakeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign super admin user
	userEmail := suite.TestUsers[0].Email
	w, err = suite.MakeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should lock project as super admin", func(t *testing.T) {
		lockRequest := types.ProjectLockRequest{
			IsLocked: true,
		}

		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unlock project as super admin", func(t *testing.T) {
		lockRequest := types.ProjectLockRequest{
			IsLocked: false,
		}

		w, err := suite.MakeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest, "60000001-0000-4000-8000-000000000001")
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail when auth headers missing", func(t *testing.T) {
		lockRequest := types.ProjectLockRequest{
			IsLocked: true,
		}

		w, err := suite.MakeRequestWithHeaders("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest, map[string]string{})
		require.NoError(t, err)
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

// TestProjectIntegrationSuite runs the complete test suite.
func TestProjectIntegrationSuite(t *testing.T) {
	suite.Run(t, new(ProjectIntegrationTestSuite))
}
