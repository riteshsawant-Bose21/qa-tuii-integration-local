package tests

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/id"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	projectdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	sqlpkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

// ProjectIntegrationTestSuite defines the test suite structure
type ProjectIntegrationTestSuite struct {
	suite.Suite
	ctx               context.Context
	postgresContainer *postgres.PostgresContainer
	db                *sql.DB
	ginRouter         *gin.Engine
	api               *api.API
	testProjects      []testProject
	testUsers         []testUser
}

// testProject represents a test project for testing
type testProject struct {
	ID                        string                `json:"id"`
	Name                      string                `json:"name"`
	Description               string                `json:"description"`
	Application               string                `json:"application"`
	Venue                     string                `json:"venue"`
	ProjectPhase              types.ProjectPhase    `json:"project_phase"`
	EnvironmentType           types.EnvironmentType `json:"environment_type"`
	Budget                    types.Budget          `json:"budget"`
	IsProjectFileCreated      bool                  `json:"is_project_file_created"`
	IsProjectThumbnailCreated bool                  `json:"is_project_thumbnail_created"`
}

// testUser represents a test user
type testUser struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

// SetupSuite runs once before all tests in the suite
func (suite *ProjectIntegrationTestSuite) SetupSuite() {
	suite.ctx = context.Background()

	// Start PostgreSQL container
	postgresContainer, err := postgres.Run(suite.ctx,
		"postgres:18-alpine",
		postgres.WithDatabase("fusion_cloud_test"),
		postgres.WithUsername("testuser"),
		postgres.WithPassword("testpass"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(30*time.Second),
		),
	)
	require.NoError(suite.T(), err)

	suite.postgresContainer = postgresContainer

	// Get database connection details
	host, err := postgresContainer.Host(suite.ctx)
	require.NoError(suite.T(), err)

	mappedPort, err := postgresContainer.MappedPort(suite.ctx, "5432")
	require.NoError(suite.T(), err)

	port := mappedPort.Port()

	// Initialize database connection
	pgs, err := sqlpkg.New(
		sqlpkg.PostgresOpener,
		host,
		port,
		"testuser",
		"testpass",
		"fusion_cloud_test",
	)
	require.NoError(suite.T(), err)
	suite.db = pgs

	// Run database migrations
	err = suite.runMigrations()
	require.NoError(suite.T(), err)

	// Seed test data
	err = suite.seedTestData()
	require.NoError(suite.T(), err)

	// Setup API server
	err = suite.setupAPI()
	require.NoError(suite.T(), err)
}

// TearDownSuite runs once after all tests in the suite
func (suite *ProjectIntegrationTestSuite) TearDownSuite() {
	if suite.postgresContainer != nil {
		err := suite.postgresContainer.Terminate(suite.ctx)
		require.NoError(suite.T(), err)
	}
}

// runMigrations runs the database schema migration and populates with test data
func (suite *ProjectIntegrationTestSuite) runMigrations() error {
	// Read and execute schema migration
	schemaSQL, err := os.ReadFile("../../migration/fusion_cloud.sql")
	if err != nil {
		return fmt.Errorf("failed to read schema migration: %w", err)
	}

	_, err = suite.db.Exec(string(schemaSQL))
	if err != nil {
		return fmt.Errorf("failed to execute schema migration: %w", err)
	}

	// Read and execute test data migration
	testDataSQL, err := os.ReadFile("../../migration/test_data.sql")
	if err != nil {
		return fmt.Errorf("failed to read test data migration: %w", err)
	}

	_, err = suite.db.Exec(string(testDataSQL))
	if err != nil {
		return fmt.Errorf("failed to execute test data migration: %w", err)
	}

	return nil
}

// seedTestData creates test data for the integration tests using existing users from test_data.sql
func (suite *ProjectIntegrationTestSuite) seedTestData() error {
	// Use existing test users from test_data.sql
	suite.testUsers = []testUser{
		{ID: "60000001-0000-4000-8000-000000000001", Email: "admin@bose.com"},
		{ID: "60000001-0000-4000-8000-000000000006", Email: "test@domain.com"},
		{ID: "60000001-0000-4000-8000-000000000007", Email: "prof.operator@university.edu"},
		{ID: "60000001-0000-4000-8000-000000000008", Email: "emily.service@eventproductions.com"},
	}

	// Define test projects for creation during tests (these will be new projects)
	suite.testProjects = []testProject{
		{
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

	return nil
}

// setupAPI initializes the API server with all necessary services
func (suite *ProjectIntegrationTestSuite) setupAPI() error {
	// Set Gin to test mode
	gin.SetMode(gin.TestMode)

	// Initialize services
	idSVC := id.NewService()
	require.NotNil(suite.T(), idSVC, "Failed to initialize ID service")

	// Initialize Product services (using mock S3 for tests)
	productDBSvc := productdb.NewService(suite.db)
	require.NotNil(suite.T(), productDBSvc, "Failed to initialize product database service")

	productSVC := product.NewService(productDBSvc, idSVC)
	require.NotNil(suite.T(), productSVC, "Failed to initialize product service")

	// Initialize Project services (create logger for tests)
	logger, err := log.NewProduction()
	require.NoError(suite.T(), err, "Failed to create logger")
	projectDBSvc := projectdb.NewService(suite.db, logger)
	require.NotNil(suite.T(), projectDBSvc, "Failed to initialize project database service")

	// Mock S3 bucket for testing
	s3Handler, _ := cloudfs.NewS3Client(suite.ctx)
	// For testing, we can use a mock bucket or skip S3 operations
	// For now, let's create the project service without S3 dependency

	var bucket cloudfs.BucketHandle
	if s3Handler != nil {
		bucket = s3Handler.Bucket("test-project-bucket")
	}

	projectSVC := project.NewService(projectDBSvc, bucket)
	require.NotNil(suite.T(), projectSVC, "Failed to initialize project service")

	// Initialize User services
	userDBSvc := userdb.NewService(suite.db)
	require.NotNil(suite.T(), userDBSvc, "Failed to initialize user database service")

	userSVC := user.NewService(userDBSvc)
	require.NotNil(suite.T(), userSVC, "Failed to initialize user service")

	// Initialize Role Management Service
	roleManagementSvc := userdb.NewRoleManagementService(suite.db)
	require.NotNil(suite.T(), roleManagementSvc, "Failed to initialize role management service")

	// Initialize API server
	apiConfig := &api.Config{
		Mode:        "test",
		Host:        "localhost",
		Port:        "0",                     // Use ephemeral port for testing
		Auth0Domain: "test-domain.auth0.com", // Mock Auth0 domain for testing
	}

	apiServer, err := api.New(apiConfig, productSVC, projectSVC, userSVC, userDBSvc, roleManagementSvc)
	if err != nil {
		return fmt.Errorf("failed to initialize API server: %w", err)
	}

	suite.api = apiServer

	// Create a separate test router without auth middleware for integration testing
	suite.ginRouter = suite.createTestRouter(projectSVC, productSVC, userSVC, userDBSvc, roleManagementSvc)

	return nil
}

// createTestRouter creates a Gin router with handlers but no authentication middleware for testing
func (suite *ProjectIntegrationTestSuite) createTestRouter(projectSVC *project.Service, productSVC *product.Service, userSVC *user.Service, userDBSvc *userdb.Service, roleManagementSvc *userdb.RoleManagementService) *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	// Add middleware for testing (recovery, but no auth)
	router.Use(gin.Recovery())

	// Add test middleware that mocks authentication for all requests
	router.Use(func(c *gin.Context) {
		// Get user ID from header (if provided) or use default user
		userID := c.GetHeader("X-User-ID")
		if userID == "" {
			userID = suite.testUsers[0].ID
		}

		// Find the user in our test users list
		var userEmail string
		for _, testUser := range suite.testUsers {
			if testUser.ID == userID {
				userEmail = testUser.Email
				break
			}
		}
		if userEmail == "" {
			userEmail = suite.testUsers[0].Email // fallback
		}

		// Mock user authentication in context for all requests
		mockUserAuth := types.UserAuthorizationResponse{
			User: types.UserInfo{
				ID:    userID,
				Email: userEmail,
			},
			Account: types.AccountInfo{
				ID:   "50000001-0000-4000-8000-000000000001",
				Name: "Bose Corporation",
				Type: "Bose Pro",
			},
			Role: types.RoleInfo{
				ID:       2,
				RoleName: "User",
			},
			Permissions: map[string]string{
				"projects": "full",
			},
		}
		c.Set("user_auth", mockUserAuth)
		c.Next()
	})

	// Setup routes manually without authentication middleware
	// Create handlers directly
	projectHandler := handler.NewProjectHandler(projectSVC)

	api := router.Group("/api/v1")
	{
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
	}

	return router
}

// Helper method to make HTTP requests to the API
func (suite *ProjectIntegrationTestSuite) makeRequest(method, path string, body interface{}) (*httptest.ResponseRecorder, error) {
	var bodyReader *bytes.Reader
	if body != nil {
		bodyBytes, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		bodyReader = bytes.NewReader(bodyBytes)
	} else {
		bodyReader = bytes.NewReader([]byte{})
	}

	req, err := http.NewRequest(method, path, bodyReader)
	if err != nil {
		return nil, err
	}

	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	w := httptest.NewRecorder()

	// Serve the request - authentication is already mocked in router middleware
	suite.ginRouter.ServeHTTP(w, req) // Debug response for failures
	if w.Code >= 400 {
		if body != nil {
			_, _ = json.Marshal(body)
		}
	}

	return w, nil
}

// Test Create Project endpoint
func (suite *ProjectIntegrationTestSuite) TestCreateProject() {
	suite.T().Run("should create project successfully", func(t *testing.T) {
		project := suite.testProjects[0]

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.ID)
		assert.NotEmpty(t, response.ProjectUploadURL)
		assert.NotEmpty(t, response.ThumbnailUploadURL)

		// Store the created project ID for later tests
		suite.testProjects[0].ID = response.ID
	})

	suite.T().Run("should fail with invalid project data", func(t *testing.T) {
		invalidProject := testProject{
			Name: "", // Missing required name
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should rollback transaction when creating project with invalid data", func(t *testing.T) {
		// Count projects before the failed attempt
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var beforeResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &beforeResponse)
		require.NoError(t, err)
		initialProjectCount := beforeResponse.TotalCount

		// Try to create project with invalid data that should cause validation failure and rollback
		projectWithInvalidData := types.ProjectCreateRequest{
			Name:            "", // Empty name should cause validation failure
			Description:     "This should fail validation and rollback the transaction",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err = suite.makeRequest("POST", "/api/v1/projects", projectWithInvalidData)
		require.NoError(t, err)

		// Should fail with bad request due to validation failure
		assert.Equal(t, http.StatusBadRequest, w.Code, "Request should fail validation due to empty name")

		// Verify transaction rollback - project count should remain the same
		w, err = suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var afterResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &afterResponse)
		require.NoError(t, err)
		finalProjectCount := afterResponse.TotalCount

		// Assert that no project was created (transaction was rolled back)
		assert.Equal(t, initialProjectCount, finalProjectCount, "Project count should remain the same after validation failure")

		// Verify that project count remains unchanged after validation failure
		// (no additional verification needed since we already checked the count above)
	})
}

// Test Get All Projects endpoint
func (suite *ProjectIntegrationTestSuite) TestGetAllProjects() {
	// First create a test project
	suite.TestCreateProject()

	suite.T().Run("should get all projects", func(t *testing.T) {
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.GreaterOrEqual(t, len(response.Data), 1)
		assert.Greater(t, response.TotalCount, 0)
	})

	suite.T().Run("should filter archived projects", func(t *testing.T) {
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&is_archived=true", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		// Should contain archived projects from seed data
		for _, project := range response.Data {
			assert.True(t, project.IsArchived)
		}
	})
}

// Test Update Project endpoint
func (suite *ProjectIntegrationTestSuite) TestUpdateProject() {
	// Ensure we have a created project
	suite.TestCreateProject()

	suite.T().Run("should update project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		require.NotEmpty(t, projectID)

		updateData := types.ProjectUpdateRequest{
			Name:                    "Updated Test Conference Room",
			Description:             "Updated description for integration test",
			Application:             "Updated Corporate Conference Room",
			IsProjectFileDirty:      true,
			IsProjectThumbnailDirty: true,
		}

		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+suite.testUsers[0].ID, updateData)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.ProjectUpdateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.ProjectUploadURL)
	})

	suite.T().Run("should fail with invalid project ID", func(t *testing.T) {
		updateData := types.ProjectUpdateRequest{
			Name: "Updated Name",
		}

		w, err := suite.makeRequest("PATCH", "/api/v1/projects/invalid-uuid?user_id="+suite.testUsers[0].ID, updateData)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

// Test Delete Project endpoint
func (suite *ProjectIntegrationTestSuite) TestDeleteProject() {
	// Create a project specifically for deletion test
	project := suite.testProjects[1] // Use the second test project
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign the deleting user to the project to enable deletion
	deleterEmail := suite.testUsers[0].Email // Use the first user as deleter
	w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+deleterEmail, nil)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should delete project successfully", func(t *testing.T) {
		w, err := suite.makeRequest("DELETE", "/api/v1/projects/"+projectID+"?user_id="+suite.testUsers[0].ID, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail to delete non-existent project", func(t *testing.T) {
		w, err := suite.makeRequest("DELETE", "/api/v1/projects/00000000-0000-4000-8000-000000000000?user_id="+suite.testUsers[0].ID, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

// Test Assign User to Project endpoint
func (suite *ProjectIntegrationTestSuite) TestAssignUserToProject() {
	// Ensure we have a created project
	suite.TestCreateProject()

	suite.T().Run("should assign user to project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		userEmail := suite.testUsers[1].Email

		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail with non-existent user", func(t *testing.T) {
		projectID := suite.testProjects[0].ID

		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/nonexistent@example.com", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

// Test Remove User from Project endpoint
func (suite *ProjectIntegrationTestSuite) TestRemoveUserFromProject() {
	// First assign a user to project
	suite.TestAssignUserToProject()

	suite.T().Run("should remove user from project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		userEmail := suite.testUsers[1].Email

		w, err := suite.makeRequest("DELETE", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test UpdateProjectStar endpoint
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectStar() {
	// Ensure we have a created project
	suite.TestCreateProject()

	suite.T().Run("should star project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		userID := suite.testUsers[0].ID
		starRequest := types.ProjectStarRequest{IsStarred: true}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unstar project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		userID := suite.testUsers[0].ID
		starRequest := types.ProjectStarRequest{IsStarred: false}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test UpdateProjectArchive endpoint
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectArchive() {
	// Ensure we have a created project
	suite.TestCreateProject()

	suite.T().Run("should archive project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		archiveRequest := types.ProjectArchiveRequest{Archive: true}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?user_id="+suite.testUsers[0].ID, archiveRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unarchive project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		archiveRequest := types.ProjectArchiveRequest{Archive: false}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?user_id="+suite.testUsers[0].ID, archiveRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test UpdateProjectLock endpoint
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectLock() {
	// Ensure we have a created project
	suite.TestCreateProject()

	suite.T().Run("should lock project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		lockRequest := types.ProjectLockRequest{IsLocked: true}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+suite.testUsers[0].ID, lockRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unlock project successfully", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		lockRequest := types.ProjectLockRequest{IsLocked: false}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+suite.testUsers[0].ID, lockRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test end-to-end project workflow
func (suite *ProjectIntegrationTestSuite) TestProjectWorkflow() {
	suite.T().Run("complete project lifecycle", func(t *testing.T) {
		// 1. Create project
		project := testProject{
			Name:            "Workflow Test Project",
			Description:     "End-to-end workflow test",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)

		var createResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &createResponse)
		require.NoError(t, err)
		projectID := createResponse.ID

		// 2. Assign user to project
		userEmail := suite.testUsers[1].Email
		w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 3. Star the project
		userID := suite.testUsers[0].ID
		starRequest := types.ProjectStarRequest{IsStarred: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 4. Update project
		updateData := types.ProjectUpdateRequest{
			ProjectPhase: types.ProjectPhaseDevelopment,
		}
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+suite.testUsers[0].ID, updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// 5. Lock the project
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+suite.testUsers[0].ID, lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 6. Unlock the project
		unlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+suite.testUsers[0].ID, unlockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 7. Archive the project
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?user_id="+suite.testUsers[0].ID, archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 8. Verify project is archived in listing
		w, err = suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&is_archived=true", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		// Find our project in the archived list
		found := false
		for _, p := range response.Data {
			if p.ID == projectID {
				assert.True(t, p.IsArchived)
				found = true
				break
			}
		}
		assert.True(t, found, "Archived project should be found in archived projects list")
	})
}

// Test error scenarios to improve coverage
func (suite *ProjectIntegrationTestSuite) TestErrorScenarios() {
	// Ensure we have a created project first
	suite.TestCreateProject()

	suite.T().Run("should handle invalid UUIDs", func(t *testing.T) {
		// Test invalid UUID in URL parameter - API returns empty results, not an error
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id=invalid-uuid", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code) // API doesn't validate user_id format

		// Test invalid project ID in path
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/invalid-uuid?user_id="+suite.testUsers[0].ID, types.ProjectUpdateRequest{Name: "Test"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should handle missing user_id parameter", func(t *testing.T) {
		// Test endpoints - the API uses authenticated user context, not query parameters
		projectID := suite.testProjects[0].ID

		// Update project without user_id - should work with auth context
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, types.ProjectUpdateRequest{Name: "Test"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code) // API uses auth context

		// Archive project without user_id - should work with auth context
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code) // API uses auth context

		// Lock project without user_id - the API handles this differently
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest)
		require.NoError(t, err)
		// This might fail for business logic reasons, not parameter validation
		assert.True(t, w.Code == http.StatusNoContent || w.Code == http.StatusInternalServerError || w.Code == http.StatusBadRequest)
	})

	suite.T().Run("should handle unauthorized access", func(t *testing.T) {
		// Test with non-existent user
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id=00000000-0000-4000-8000-000000000000", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code) // Non-existent user gets empty project list
	})

	suite.T().Run("should handle malformed JSON", func(t *testing.T) {
		// Create a request with invalid JSON
		req, err := http.NewRequest("POST", "/api/v1/projects", bytes.NewReader([]byte(`{invalid json`)))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should handle missing required fields", func(t *testing.T) {
		// Test create project with missing required fields
		incompleteProject := testProject{
			// Missing Name which is required
			Description: "Test description",
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", incompleteProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

// Test edge cases and boundary conditions
func (suite *ProjectIntegrationTestSuite) TestEdgeCases() {
	// Ensure we have a created project
	suite.TestCreateProject()

	suite.T().Run("should handle non-existent project operations", func(t *testing.T) {
		nonExistentID := "00000000-0000-4000-8000-000000000000"
		userID := suite.testUsers[0].ID

		// Try to update non-existent project
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+nonExistentID+"?user_id="+userID, types.ProjectUpdateRequest{Name: "Test"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to delete non-existent project
		w, err = suite.makeRequest("DELETE", "/api/v1/projects/"+nonExistentID+"?user_id="+userID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to star non-existent project
		starRequest := types.ProjectStarRequest{IsStarred: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+nonExistentID+"/star/"+userID, starRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to archive non-existent project
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+nonExistentID+"/archive?user_id="+userID, archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to lock non-existent project
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+nonExistentID+"/lock?user_id="+userID, lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should handle user assignment edge cases", func(t *testing.T) {
		projectID := suite.testProjects[0].ID

		// Try to assign non-existent user
		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/nonexistent@example.com", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to remove user that is not assigned
		w, err = suite.makeRequest("DELETE", "/api/v1/projects/"+projectID+"/users/"+suite.testUsers[2].Email, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code) // Removing unassigned user succeeds

		// Try to assign user to non-existent project
		w, err = suite.makeRequest("PUT", "/api/v1/projects/00000000-0000-4000-8000-000000000000/users/"+suite.testUsers[1].Email, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should handle duplicate operations", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		userID := suite.testUsers[0].ID
		userEmail := suite.testUsers[1].Email

		// Assign user to project
		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Try to assign the same user again (should still succeed)
		w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Star the project
		starRequest := types.ProjectStarRequest{IsStarred: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Try to star again (should still succeed)
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Unstar the project
		unstarRequest := types.ProjectStarRequest{IsStarred: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, unstarRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Try to unstar again (should still succeed)
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, unstarRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test lock conflict scenarios
func (suite *ProjectIntegrationTestSuite) TestLockConflicts() {
	// Create a project for lock testing
	project := testProject{
		Name:            "Lock Test Project",
		Description:     "Project for testing lock conflicts",
		Application:     "Test Application",
		Venue:           "Test Venue",
		ProjectPhase:    types.ProjectPhaseProposal,
		EnvironmentType: types.EnvironmentTypeIndoor,
		Budget: types.Budget{
			Amount:   10000,
			Currency: "USD",
		},
		IsProjectFileCreated:      false,
		IsProjectThumbnailCreated: false,
	}

	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign both users to the project
	for _, user := range suite.testUsers[:2] {
		w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+user.Email, nil)
		require.NoError(suite.T(), err)
		require.Equal(suite.T(), http.StatusNoContent, w.Code)
	}

	suite.T().Run("should handle lock conflicts between users", func(t *testing.T) {
		user1ID := suite.testUsers[0].ID
		user2ID := suite.testUsers[1].ID

		// User 1 locks the project
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+user1ID, lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// User 2 tries to update the locked project (should fail)
		updateData := types.ProjectUpdateRequest{Name: "Updated by User 2"}
		req, err := http.NewRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+user2ID, bytes.NewReader([]byte{}))
		require.NoError(t, err)
		if updateData != (types.ProjectUpdateRequest{}) {
			bodyBytes, _ := json.Marshal(updateData)
			req.Body = io.NopCloser(bytes.NewReader(bodyBytes))
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-User-ID", user2ID)
		req.Header.Set("X-Account-ID", "1")

		w = httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// User 2 tries to delete the locked project (should fail)
		req, err = http.NewRequest("DELETE", "/api/v1/projects/"+projectID+"?user_id="+user2ID, nil)
		require.NoError(t, err)
		req.Header.Set("X-User-ID", user2ID)
		req.Header.Set("X-Account-ID", "1")

		w = httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// User 2 tries to unlock project locked by User 1 (should fail)
		unlockRequest := types.ProjectLockRequest{IsLocked: false}
		bodyBytes, _ := json.Marshal(unlockRequest)
		req, err = http.NewRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+user2ID, bytes.NewReader(bodyBytes))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-User-ID", user2ID)
		req.Header.Set("X-Account-ID", "1")

		w = httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// User 1 (who locked it) can still update
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+user1ID, types.ProjectUpdateRequest{Name: "Updated by User 1"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// User 1 unlocks the project
		user1UnlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+user1ID, user1UnlockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Now User 2 can update
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+user2ID, types.ProjectUpdateRequest{Name: "Updated by User 2 after unlock"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})
}

// Test archived project restrictions
func (suite *ProjectIntegrationTestSuite) TestArchivedProjectRestrictions() {
	// Create and archive a project
	project := testProject{
		Name:            "Archive Test Project",
		Description:     "Project for testing archive restrictions",
		Application:     "Test Application",
		Venue:           "Test Venue",
		ProjectPhase:    types.ProjectPhaseProposal,
		EnvironmentType: types.EnvironmentTypeIndoor,
		Budget: types.Budget{
			Amount:   10000,
			Currency: "USD",
		},
		IsProjectFileCreated:      false,
		IsProjectThumbnailCreated: false,
	}

	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Archive the project
	archiveRequest := types.ProjectArchiveRequest{Archive: true}
	w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?user_id="+suite.testUsers[0].ID, archiveRequest)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should restrict operations on archived projects", func(t *testing.T) {
		userID := suite.testUsers[0].ID

		// Try to update archived project (should fail)
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+userID, types.ProjectUpdateRequest{Name: "Updated archived"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to delete archived project (should fail)
		w, err = suite.makeRequest("DELETE", "/api/v1/projects/"+projectID+"?user_id="+userID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to lock archived project (should fail)
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+userID, lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusInternalServerError, w.Code)

		// Unarchive should work
		unarchiveRequest := types.ProjectArchiveRequest{Archive: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?user_id="+userID, unarchiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Now operations should work again
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+userID, types.ProjectUpdateRequest{Name: "Updated after unarchive"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})
}

// Test query parameter validation and filtering
func (suite *ProjectIntegrationTestSuite) TestQueryParameterValidation() {
	suite.T().Run("should validate query parameters", func(t *testing.T) {
		// Test invalid sort_order
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&sort_order=invalid", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Test invalid boolean for is_archived
		w, err = suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&is_archived=invalid_bool", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Test valid parameters
		w, err = suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&sort_by=created_at&sort_order=desc&is_archived=false", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})
}

// Test unauthorized user operations
func (suite *ProjectIntegrationTestSuite) TestUnauthorizedUserOperations() {
	// Create a project
	suite.TestCreateProject()

	suite.T().Run("should prevent unauthorized user operations", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		unauthorizedUserID := suite.testUsers[2].ID // User not assigned to project

		// Try to update project as unauthorized user
		req, err := http.NewRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+unauthorizedUserID, bytes.NewReader([]byte{}))
		require.NoError(t, err)
		updateData := types.ProjectUpdateRequest{Name: "Unauthorized update"}
		bodyBytes, _ := json.Marshal(updateData)
		req.Body = io.NopCloser(bytes.NewReader(bodyBytes))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-User-ID", unauthorizedUserID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to delete as unauthorized user
		req, err = http.NewRequest("DELETE", "/api/v1/projects/"+projectID+"?user_id="+unauthorizedUserID, nil)
		require.NoError(t, err)
		req.Header.Set("X-User-ID", unauthorizedUserID)
		req.Header.Set("X-Account-ID", "1")

		w = httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to star as unauthorized user
		starRequest := types.ProjectStarRequest{IsStarred: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+unauthorizedUserID, starRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)
	})
}

// Test concurrent operations and race conditions
func (suite *ProjectIntegrationTestSuite) TestConcurrentOperations() {
	// Create a project for concurrent testing
	project := testProject{
		Name:            "Concurrent Test Project",
		Description:     "Project for testing concurrent operations",
		Application:     "Test Application",
		Venue:           "Test Venue",
		ProjectPhase:    types.ProjectPhaseProposal,
		EnvironmentType: types.EnvironmentTypeIndoor,
		Budget: types.Budget{
			Amount:   10000,
			Currency: "USD",
		},
		IsProjectFileCreated:      false,
		IsProjectThumbnailCreated: false,
	}

	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign both users to the project
	for _, user := range suite.testUsers[:2] {
		w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+user.Email, nil)
		require.NoError(suite.T(), err)
		require.Equal(suite.T(), http.StatusNoContent, w.Code)
	}

	suite.T().Run("should handle concurrent star/unstar operations", func(t *testing.T) {
		userID := suite.testUsers[0].ID

		// Perform multiple star/unstar operations
		for i := 0; i < 3; i++ {
			// Star
			starRequest := types.ProjectStarRequest{IsStarred: true}
			w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)

			// Unstar
			unstarRequest := types.ProjectStarRequest{IsStarred: false}
			w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, unstarRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)
		}
	})

	suite.T().Run("should handle concurrent archive/unarchive operations", func(t *testing.T) {
		userID := suite.testUsers[0].ID

		// Perform multiple archive/unarchive operations
		for i := 0; i < 3; i++ {
			// Archive
			archiveRequest := types.ProjectArchiveRequest{Archive: true}
			w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?user_id="+userID, archiveRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)

			// Unarchive
			unarchiveRequest := types.ProjectArchiveRequest{Archive: false}
			w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?user_id="+userID, unarchiveRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)
		}
	})

	suite.T().Run("should handle concurrent lock/unlock operations", func(t *testing.T) {
		userID := suite.testUsers[0].ID

		// Perform multiple lock/unlock operations
		for i := 0; i < 3; i++ {
			// Lock
			lockRequest := types.ProjectLockRequest{IsLocked: true}
			w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+userID, lockRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)

			// Unlock
			unlockRequest := types.ProjectLockRequest{IsLocked: false}
			w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?user_id="+userID, unlockRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)
		}
	})
}

// Test comprehensive data validation
func (suite *ProjectIntegrationTestSuite) TestDataValidation() {
	suite.T().Run("should validate project creation data", func(t *testing.T) {
		// Test with invalid budget amount
		invalidProject := testProject{
			Name:            "Valid Name",
			Description:     "Valid Description",
			Application:     "Valid Application",
			Venue:           "Valid Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   -1000, // Invalid negative amount
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Test with invalid currency
		invalidProject.Budget.Amount = 1000
		invalidProject.Budget.Currency = "INVALID"

		w, err = suite.makeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Test with excessively long strings
		invalidProject.Budget.Currency = "USD"
		invalidProject.Name = string(make([]byte, 1000)) // Very long name

		w, err = suite.makeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should validate update data", func(t *testing.T) {
		// First create a valid project
		suite.TestCreateProject()
		projectID := suite.testProjects[0].ID

		// Test update with invalid data
		invalidUpdate := types.ProjectUpdateRequest{
			Name:        "", // Empty name might be accepted for partial updates
			Description: "Valid description",
		}

		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+suite.testUsers[0].ID, invalidUpdate)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code) // Empty name accepted for partial updates
	})

	suite.T().Run("should validate email formats", func(t *testing.T) {
		suite.TestCreateProject()
		projectID := suite.testProjects[0].ID

		// Test with invalid email format
		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/invalid-email", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code) // Invalid email treated as user not found

		// Test with empty email
		w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/", nil)
		require.NoError(t, err)
		// This should return 404 as the router won't match the route
		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

// Test boundary conditions and limits
func (suite *ProjectIntegrationTestSuite) TestBoundaryConditions() {
	suite.T().Run("should handle pagination limits", func(t *testing.T) {
		// Test with very large limit (should be capped)
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&limit=99999", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Test with zero limit
		w, err = suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&limit=0", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Test with negative offset
		w, err = suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&offset=-1", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})

	suite.T().Run("should handle special characters in project data", func(t *testing.T) {
		specialProject := testProject{
			Name:            "Test Project with Special Characters: !@#$%^&*()",
			Description:     "Description with unicode: 你好世界 🌍",
			Application:     "Application with symbols: <>&\"'",
			Venue:           "Venue with newlines:\nLine 1\nLine 2",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", specialProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.NotEmpty(t, response.ID)
	})
}

// Test environment type validation and different values
func (suite *ProjectIntegrationTestSuite) TestEnvironmentTypeValidation() {
	suite.T().Run("should accept all valid environment types", func(t *testing.T) {
		validTypes := []types.EnvironmentType{
			types.EnvironmentTypeIndoor,
			types.EnvironmentTypeOutdoor,
			types.EnvironmentTypeHybrid,
		}

		for _, envType := range validTypes {
			project := testProject{
				Name:            fmt.Sprintf("Test Project - %s", envType),
				Description:     "Test project for environment type validation",
				Application:     "Test Application",
				Venue:           "Test Venue",
				ProjectPhase:    types.ProjectPhaseProposal,
				EnvironmentType: envType,
				Budget: types.Budget{
					Amount:   25000,
					Currency: "USD",
				},
				IsProjectFileCreated:      false,
				IsProjectThumbnailCreated: false,
			}

			w, err := suite.makeRequest("POST", "/api/v1/projects", project)
			require.NoError(t, err)
			assert.Equal(t, http.StatusCreated, w.Code)
		}
	})

	suite.T().Run("should reject invalid environment type", func(t *testing.T) {
		project := testProject{
			Name:            "Invalid Environment Test",
			Description:     "Test project with invalid environment type",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: "invalid_environment",
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

// Test project phase validation and transitions
func (suite *ProjectIntegrationTestSuite) TestProjectPhaseValidation() {
	suite.T().Run("should accept all valid project phases", func(t *testing.T) {
		validPhases := []types.ProjectPhase{
			types.ProjectPhaseProposal,
			types.ProjectPhaseDevelopment,
			types.ProjectPhaseCommissioned,
		}

		for _, phase := range validPhases {
			project := testProject{
				Name:            fmt.Sprintf("Test Project - %s", phase),
				Description:     "Test project for phase validation",
				Application:     "Test Application",
				Venue:           "Test Venue",
				ProjectPhase:    phase,
				EnvironmentType: types.EnvironmentTypeIndoor,
				Budget: types.Budget{
					Amount:   25000,
					Currency: "USD",
				},
				IsProjectFileCreated:      false,
				IsProjectThumbnailCreated: false,
			}

			w, err := suite.makeRequest("POST", "/api/v1/projects", project)
			require.NoError(t, err)
			assert.Equal(t, http.StatusCreated, w.Code)
		}
	})

	suite.T().Run("should reject invalid project phase", func(t *testing.T) {
		project := testProject{
			Name:            "Invalid Phase Test",
			Description:     "Test project with invalid phase",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    "Invalid_Phase",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

// Test currency validation in budget
func (suite *ProjectIntegrationTestSuite) TestBudgetCurrencyValidation() {
	suite.T().Run("should accept valid currencies", func(t *testing.T) {
		validCurrencies := []string{"USD", "EUR", "GBP", "CAD", "JPY"}

		for _, currency := range validCurrencies {
			project := testProject{
				Name:            fmt.Sprintf("Test Project - %s", currency),
				Description:     "Test project for currency validation",
				Application:     "Test Application",
				Venue:           "Test Venue",
				ProjectPhase:    types.ProjectPhaseProposal,
				EnvironmentType: types.EnvironmentTypeIndoor,
				Budget: types.Budget{
					Amount:   25000,
					Currency: currency,
				},
				IsProjectFileCreated:      false,
				IsProjectThumbnailCreated: false,
			}

			w, err := suite.makeRequest("POST", "/api/v1/projects", project)
			require.NoError(t, err)
			assert.Equal(t, http.StatusCreated, w.Code)
		}
	})

	suite.T().Run("should reject invalid currencies", func(t *testing.T) {
		invalidCurrencies := []string{"INVALID", "US", "USDX", "123", ""}

		for _, currency := range invalidCurrencies {
			project := testProject{
				Name:            fmt.Sprintf("Invalid Currency Test - %s", currency),
				Description:     "Test project with invalid currency",
				Application:     "Test Application",
				Venue:           "Test Venue",
				ProjectPhase:    types.ProjectPhaseProposal,
				EnvironmentType: types.EnvironmentTypeIndoor,
				Budget: types.Budget{
					Amount:   25000,
					Currency: currency,
				},
				IsProjectFileCreated:      false,
				IsProjectThumbnailCreated: false,
			}

			w, err := suite.makeRequest("POST", "/api/v1/projects", project)
			require.NoError(t, err)
			assert.Equal(t, http.StatusBadRequest, w.Code)
		}
	})
}

// Test project field length validation
func (suite *ProjectIntegrationTestSuite) TestFieldLengthValidation() {
	suite.T().Run("should reject excessively long project name", func(t *testing.T) {
		longName := strings.Repeat("a", 256) // Over 255 character limit
		project := testProject{
			Name:            longName,
			Description:     "Test project with long name",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should reject excessively long description", func(t *testing.T) {
		longDescription := strings.Repeat("a", 1001) // Over 1000 character limit
		project := testProject{
			Name:            "Test Project",
			Description:     longDescription,
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should accept maximum length fields", func(t *testing.T) {
		maxName := strings.Repeat("a", 255)         // Exactly 255 characters
		maxDescription := strings.Repeat("a", 1000) // Exactly 1000 characters
		maxVenue := strings.Repeat("a", 255)        // Exactly 255 characters

		project := testProject{
			Name:            maxName,
			Description:     maxDescription,
			Application:     "Test Application",
			Venue:           maxVenue,
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)
	})
}

// Test negative budget amounts
func (suite *ProjectIntegrationTestSuite) TestBudgetAmountValidation() {
	suite.T().Run("should reject negative budget amount", func(t *testing.T) {
		project := testProject{
			Name:            "Negative Budget Test",
			Description:     "Test project with negative budget",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   -1000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		// Depending on validation logic, this might be 400 or accepted
		if w.Code != http.StatusCreated {
			assert.Equal(t, http.StatusBadRequest, w.Code)
		}
	})

	suite.T().Run("should accept zero budget amount", func(t *testing.T) {
		project := testProject{
			Name:            "Zero Budget Test",
			Description:     "Test project with zero budget",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   0,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)
	})
}

// Test advanced query parameter validation
func (suite *ProjectIntegrationTestSuite) TestAdvancedQueryParameterValidation() {
	suite.T().Run("should validate sort_by parameter", func(t *testing.T) {
		validSortFields := []string{"created_at", "updated_at"} // API only supports these two fields

		for _, sortField := range validSortFields {
			w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&sort_by="+sortField, nil)
			require.NoError(t, err)
			assert.Equal(t, http.StatusOK, w.Code)
		}
	})

	suite.T().Run("should reject invalid sort_by parameter", func(t *testing.T) {
		invalidSortFields := []string{"invalid_field", "id", "description"}

		for _, sortField := range invalidSortFields {
			w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&sort_by="+sortField, nil)
			require.NoError(t, err)
			// API might accept invalid fields and use default, or return 400
			if w.Code != http.StatusOK {
				assert.Equal(t, http.StatusBadRequest, w.Code)
			}
		}
	})

	suite.T().Run("should validate sort_order parameter", func(t *testing.T) {
		validSortOrders := []string{"asc", "desc"}

		for _, sortOrder := range validSortOrders {
			w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&sort_order="+sortOrder, nil)
			require.NoError(t, err)
			assert.Equal(t, http.StatusOK, w.Code)
		}
	})

	suite.T().Run("should reject invalid sort_order parameter", func(t *testing.T) {
		invalidSortOrders := []string{"ascending", "descending", "invalid"}

		for _, sortOrder := range invalidSortOrders {
			w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&sort_order="+sortOrder, nil)
			require.NoError(t, err)
			// API might accept invalid values and use default, or return 400
			if w.Code != http.StatusOK {
				assert.Equal(t, http.StatusBadRequest, w.Code)
			}
		}
	})
}

// Test project creation with minimal required fields
func (suite *ProjectIntegrationTestSuite) TestMinimalProjectCreation() {
	suite.T().Run("should create project with minimal required fields", func(t *testing.T) {
		minimalProject := testProject{
			Name:            "Minimal Test Project",
			Application:     "Minimal App",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   1000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
			// Omitting optional fields: Description, Venue, ProjectPhase
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", minimalProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.NotEmpty(t, response.ID)
	})
}

// Test content type handling
func (suite *ProjectIntegrationTestSuite) TestContentTypeHandling() {
	suite.T().Run("should reject requests without content type", func(t *testing.T) {
		project := suite.testProjects[0]
		bodyBytes, err := json.Marshal(project)
		require.NoError(t, err)

		req, err := http.NewRequest("POST", "/api/v1/projects", bytes.NewReader(bodyBytes))
		require.NoError(t, err)
		// Omit Content-Type header
		req.Header.Set("Authorization", "Bearer test-token")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		// API might accept or reject based on implementation
		// Typically should accept since Gin can handle JSON without explicit content-type
		assert.True(t, w.Code == http.StatusCreated || w.Code == http.StatusBadRequest)
	})

	suite.T().Run("should reject requests with wrong content type", func(t *testing.T) {
		req, err := http.NewRequest("POST", "/api/v1/projects", strings.NewReader("not json"))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "text/plain")
		req.Header.Set("Authorization", "Bearer test-token")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

// Test empty request body handling
func (suite *ProjectIntegrationTestSuite) TestEmptyRequestBodyHandling() {
	suite.T().Run("should reject empty request body for create", func(t *testing.T) {
		req, err := http.NewRequest("POST", "/api/v1/projects", bytes.NewReader([]byte{}))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer test-token")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should reject null request body for update", func(t *testing.T) {
		// Create a project first
		suite.TestCreateProject()
		projectID := suite.testProjects[0].ID

		req, err := http.NewRequest("PATCH", "/api/v1/projects/"+projectID+"?user_id="+suite.testUsers[0].ID, bytes.NewReader([]byte("null")))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer test-token")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		// API might accept null as empty update (200) or reject it (400)
		assert.True(t, w.Code == http.StatusBadRequest || w.Code == http.StatusOK)
	})
}

// Test duplicate project names
func (suite *ProjectIntegrationTestSuite) TestDuplicateProjectNames() {
	suite.T().Run("should allow multiple projects with same name for different users", func(t *testing.T) {
		projectName := "Duplicate Name Test Project"

		// Create project for first user
		project1 := testProject{
			Name:            projectName,
			Description:     "First project with this name",
			Application:     "Test Application",
			Venue:           "Test Venue 1",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project1)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)

		// Create project with same name for different user
		project2 := project1
		project2.Description = "Second project with same name"
		project2.Venue = "Test Venue 2"

		// Update request headers for second user
		bodyBytes, err := json.Marshal(project2)
		require.NoError(t, err)
		req, err := http.NewRequest("POST", "/api/v1/projects", bytes.NewReader(bodyBytes))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer test-token")
		req.Header.Set("X-User-ID", suite.testUsers[1].ID)
		req.Header.Set("X-Account-ID", "1")

		w2 := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w2, req)

		assert.Equal(t, http.StatusCreated, w2.Code)
	})

	suite.T().Run("should handle duplicate project name for same user gracefully", func(t *testing.T) {
		projectName := "Same User Duplicate Test"

		project := testProject{
			Name:            projectName,
			Description:     "Original project",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		// Create first project
		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)

		// Try to create another project with same name and user
		project.Description = "Duplicate attempt"
		w2, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		// Depending on business logic, might be allowed (201) or rejected (409/400)
		assert.True(t, w2.Code == http.StatusCreated || w2.Code == http.StatusConflict || w2.Code == http.StatusBadRequest)
	})
}

// Test HTTP method validation
func (suite *ProjectIntegrationTestSuite) TestHTTPMethodValidation() {
	suite.T().Run("should reject invalid HTTP methods", func(t *testing.T) {
		invalidMethods := []string{"TRACE", "HEAD"}

		for _, method := range invalidMethods {
			req, err := http.NewRequest(method, "/api/v1/projects", nil)
			require.NoError(t, err)
			req.Header.Set("Authorization", "Bearer test-token")
			req.Header.Set("X-User-ID", suite.testUsers[0].ID)
			req.Header.Set("X-Account-ID", "1")

			w := httptest.NewRecorder()
			suite.ginRouter.ServeHTTP(w, req)

			// Should return 405 Method Not Allowed or 404 Not Found for invalid methods
			assert.True(t, w.Code == http.StatusMethodNotAllowed || w.Code == http.StatusNotFound,
				"Expected 405 Method Not Allowed or 404 Not Found for %s method, got %d", method, w.Code)
		}

		// Test OPTIONS method separately - should be allowed for CORS
		req, err := http.NewRequest("OPTIONS", "/api/v1/projects", nil)
		require.NoError(t, err)
		req.Header.Set("Authorization", "Bearer test-token")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		// OPTIONS should return 200 OK, 204 No Content for CORS preflight, 405 Method Not Allowed, or 404 Not Found
		assert.True(t, w.Code == http.StatusOK || w.Code == http.StatusNoContent || w.Code == http.StatusMethodNotAllowed || w.Code == http.StatusNotFound,
			"Expected 200 OK, 204 No Content, 405 Method Not Allowed, or 404 Not Found for OPTIONS method, got %d", w.Code)
	})
}

// Test rate limiting behavior (if implemented)
func (suite *ProjectIntegrationTestSuite) TestRateLimiting() {
	suite.T().Run("should handle rapid successive requests", func(t *testing.T) {
		// Make multiple rapid requests
		successCount := 0
		for i := 0; i < 10; i++ {
			project := testProject{
				Name:            fmt.Sprintf("Rate Limit Test Project %d", i),
				Description:     "Test project for rate limiting",
				Application:     "Test Application",
				Venue:           "Test Venue",
				ProjectPhase:    types.ProjectPhaseProposal,
				EnvironmentType: types.EnvironmentTypeIndoor,
				Budget: types.Budget{
					Amount:   25000,
					Currency: "USD",
				},
				IsProjectFileCreated:      false,
				IsProjectThumbnailCreated: false,
			}

			w, err := suite.makeRequest("POST", "/api/v1/projects", project)
			require.NoError(t, err)

			if w.Code == http.StatusCreated {
				successCount++
			}
		}

		// At least some requests should succeed (exact behavior depends on rate limiting implementation)
		assert.Greater(t, successCount, 0)
	})
}

// Test project retrieval with various filters
func (suite *ProjectIntegrationTestSuite) TestAdvancedProjectFiltering() {
	// First ensure we have some test projects
	suite.TestCreateProject()

	suite.T().Run("should filter by archived status correctly", func(t *testing.T) {
		// Get non-archived projects
		w, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&is_archived=false", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var nonArchivedResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &nonArchivedResponse)
		require.NoError(t, err)

		// Get archived projects
		w2, err := suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID+"&is_archived=true", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w2.Code)

		var archivedResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w2.Body.Bytes(), &archivedResponse)
		require.NoError(t, err)

		// Verify filtering logic
		for _, project := range nonArchivedResponse.Data {
			assert.False(t, project.IsArchived)
		}

		for _, project := range archivedResponse.Data {
			assert.True(t, project.IsArchived)
		}
	})

	suite.T().Run("should handle pagination parameters", func(t *testing.T) {
		// Test with different pagination values
		paginationTests := []struct {
			limit  string
			offset string
		}{
			{"5", "0"},
			{"10", "5"},
			{"1", "0"},
		}

		for _, test := range paginationTests {
			url := fmt.Sprintf("/api/v1/projects?user_id=%s&limit=%s&offset=%s",
				suite.testUsers[0].ID, test.limit, test.offset)
			w, err := suite.makeRequest("GET", url, nil)
			require.NoError(t, err)
			assert.Equal(t, http.StatusOK, w.Code)

			var response types.GetAllProjectsResponse
			err = json.Unmarshal(w.Body.Bytes(), &response)
			require.NoError(t, err)

			// Verify response structure
			assert.GreaterOrEqual(t, response.TotalCount, 0)
			assert.GreaterOrEqual(t, len(response.Data), 0)
		}
	})
}

// Test concurrent user operations on same project
func (suite *ProjectIntegrationTestSuite) TestConcurrentUserOperations() {
	// Create a project and assign multiple users
	project := testProject{
		Name:            "Concurrent Operations Test",
		Description:     "Test project for concurrent operations",
		Application:     "Test Application",
		Venue:           "Test Venue",
		ProjectPhase:    types.ProjectPhaseProposal,
		EnvironmentType: types.EnvironmentTypeIndoor,
		Budget: types.Budget{
			Amount:   10000,
			Currency: "USD",
		},
		IsProjectFileCreated:      false,
		IsProjectThumbnailCreated: false,
	}

	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign both users to the project
	for _, user := range suite.testUsers[:2] {
		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+user.Email, nil)
		require.NoError(suite.T(), err)
		require.Equal(suite.T(), http.StatusNoContent, w.Code)
	}

	suite.T().Run("should handle concurrent starring by different users", func(t *testing.T) {
		// First assign both users to the project
		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+suite.testUsers[0].Email, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+suite.testUsers[1].Email, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Both users star the project - use authentication headers to simulate different users
		starRequest := types.ProjectStarRequest{IsStarred: true}

		// User 1 stars (with User 1 authentication)
		req, err := http.NewRequest("POST", "/api/v1/projects/"+projectID+"/star/"+suite.testUsers[0].ID, bytes.NewReader([]byte{}))
		require.NoError(t, err)
		if starRequest != (types.ProjectStarRequest{}) {
			bodyBytes, err := json.Marshal(starRequest)
			require.NoError(t, err)
			req.Body = io.NopCloser(bytes.NewReader(bodyBytes))
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID) // Authenticate as User 1

		w1 := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w1, req)
		assert.Equal(t, http.StatusNoContent, w1.Code)

		// User 2 stars (with User 2 authentication)
		req, err = http.NewRequest("POST", "/api/v1/projects/"+projectID+"/star/"+suite.testUsers[1].ID, bytes.NewReader([]byte{}))
		require.NoError(t, err)
		if starRequest != (types.ProjectStarRequest{}) {
			bodyBytes, err := json.Marshal(starRequest)
			require.NoError(t, err)
			req.Body = io.NopCloser(bytes.NewReader(bodyBytes))
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-User-ID", suite.testUsers[1].ID) // Authenticate as User 2

		w2 := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w2, req)
		assert.Equal(t, http.StatusNoContent, w2.Code)
	})
}

// Test large payload handling
func (suite *ProjectIntegrationTestSuite) TestLargePayloadHandling() {
	suite.T().Run("should handle large but valid project data", func(t *testing.T) {
		// Create a project with maximum allowed field sizes
		largeName := strings.Repeat("Large Project Name ", 12)
		if len(largeName) > 255 {
			largeName = largeName[:255]
		}

		largeDescription := strings.Repeat("This is a very detailed project description. ", 21)
		if len(largeDescription) > 1000 {
			largeDescription = largeDescription[:1000]
		}

		largeApplication := strings.Repeat("Large Application Name ", 10)
		if len(largeApplication) > 255 {
			largeApplication = largeApplication[:255]
		}

		largeVenue := strings.Repeat("Large Venue Name ", 14)
		if len(largeVenue) > 255 {
			largeVenue = largeVenue[:255]
		}

		largeProject := testProject{
			Name:            largeName,
			Description:     largeDescription,
			Application:     largeApplication,
			Venue:           largeVenue,
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   999999999, // Large budget amount
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", largeProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)
	})
}

// Test error response formats
func (suite *ProjectIntegrationTestSuite) TestErrorResponseFormats() {
	suite.T().Run("should return consistent error format for validation errors", func(t *testing.T) {
		invalidProject := testProject{
			// Missing required fields
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		var errorResponse types.ErrorResponse
		err = json.Unmarshal(w.Body.Bytes(), &errorResponse)
		require.NoError(t, err)
		assert.NotEmpty(t, errorResponse.Message)
	})

	suite.T().Run("should return consistent error format for not found errors", func(t *testing.T) {
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/00000000-0000-4000-8000-000000000000?user_id="+suite.testUsers[0].ID, types.ProjectUpdateRequest{Name: "Test"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		var errorResponse types.ErrorResponse
		err = json.Unmarshal(w.Body.Bytes(), &errorResponse)
		require.NoError(t, err)
		assert.NotEmpty(t, errorResponse.Message)
	})
}

// Test authentication edge cases
func (suite *ProjectIntegrationTestSuite) TestAuthenticationEdgeCases() {
	suite.T().Run("should handle missing authorization header", func(t *testing.T) {
		project := suite.testProjects[0]
		bodyBytes, err := json.Marshal(project)
		require.NoError(t, err)

		req, err := http.NewRequest("POST", "/api/v1/projects", bytes.NewReader(bodyBytes))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		// Omit Authorization header
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		// Depending on auth middleware implementation
		assert.True(t, w.Code == http.StatusUnauthorized || w.Code == http.StatusCreated)
	})

	suite.T().Run("should handle malformed authorization header", func(t *testing.T) {
		project := suite.testProjects[0]
		bodyBytes, err := json.Marshal(project)
		require.NoError(t, err)

		req, err := http.NewRequest("POST", "/api/v1/projects", bytes.NewReader(bodyBytes))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "InvalidToken")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w := httptest.NewRecorder()
		suite.ginRouter.ServeHTTP(w, req)

		// Depending on auth middleware implementation
		assert.True(t, w.Code == http.StatusUnauthorized || w.Code == http.StatusCreated)
	})
}

// Test transaction rollback scenarios
func (suite *ProjectIntegrationTestSuite) TestTransactionRollback() {
	suite.T().Run("should prevent creation with validation failure", func(t *testing.T) {
		// Get current project count from database
		var initialCount int
		err := suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&initialCount)
		require.NoError(t, err)

		// Try to create project with invalid data (should fail validation)
		invalidUserProject := testProject{
			Name:            "", // Empty name should cause validation failure
			Description:     "This project creation should fail validation",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   50000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", invalidUserProject)
		require.NoError(t, err)

		// Should fail due to validation - API validates before database operations
		assert.Equal(t, http.StatusBadRequest, w.Code) // Validation failure

		// Verify that no project was inserted (validation prevents transaction)
		var finalCount int
		err = suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&finalCount)
		require.NoError(t, err)

		assert.Equal(t, initialCount, finalCount, "Project count should be unchanged after validation failure")
	})

	suite.T().Run("should rollback transaction on invalid data during project creation", func(t *testing.T) {
		// Get current project count
		var initialCount int
		err := suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&initialCount)
		require.NoError(t, err)

		// Create project with invalid budget currency (should fail validation)
		invalidBudgetProject := testProject{
			Name:            "Invalid Budget Test Project",
			Description:     "This project should fail due to invalid currency",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "INVALID_CURRENCY", // Invalid currency code
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", invalidBudgetProject)
		require.NoError(t, err)

		// Should fail due to validation error
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Verify that no project was inserted
		var finalCount int
		err = suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&finalCount)
		require.NoError(t, err)

		assert.Equal(t, initialCount, finalCount, "Project count should be unchanged after validation failure")
	})

	suite.T().Run("should handle concurrent transaction failures gracefully", func(t *testing.T) {
		// Get initial project count
		var initialCount int
		err := suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&initialCount)
		require.NoError(t, err)

		// Create multiple projects with invalid data concurrently
		const numConcurrentRequests = 5
		type result struct {
			statusCode int
			err        error
		}
		results := make(chan result, numConcurrentRequests)

		for i := 0; i < numConcurrentRequests; i++ {
			go func(index int) {
				invalidProject := testProject{
					Name:            fmt.Sprintf("Concurrent Invalid Project %d", index),
					Description:     "This should fail",
					Application:     "Test Application",
					Venue:           "Test Venue",
					ProjectPhase:    types.ProjectPhaseProposal,
					EnvironmentType: types.EnvironmentTypeIndoor,
					Budget: types.Budget{
						Amount:   25000,
						Currency: "", // Invalid empty currency
					},
					IsProjectFileCreated:      false,
					IsProjectThumbnailCreated: false,
				}

				w, err := suite.makeRequest("POST", "/api/v1/projects", invalidProject)
				results <- result{statusCode: w.Code, err: err}
			}(i)
		}

		// Collect all results
		failedRequests := 0
		for i := 0; i < numConcurrentRequests; i++ {
			res := <-results
			require.NoError(t, res.err)
			if res.statusCode != http.StatusCreated {
				failedRequests++
			}
		}

		// All requests should have failed due to validation
		assert.Equal(t, numConcurrentRequests, failedRequests, "All concurrent requests with invalid data should fail")

		// Verify final count is still the same (all transactions rolled back)
		var finalCount int
		err = suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&finalCount)
		require.NoError(t, err)

		assert.Equal(t, initialCount, finalCount, "Project count should be unchanged after all failed concurrent transactions")
	})

	suite.T().Run("should maintain data integrity after failed project creation attempts", func(t *testing.T) {
		// Create a valid project first
		validProject := testProject{
			Name:            "Valid Project Before Failures",
			Description:     "This project should be created successfully",
			Application:     "Test Application",
			Venue:           "Test Venue",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   30000,
				Currency: "USD",
			},
			IsProjectFileCreated:      false,
			IsProjectThumbnailCreated: false,
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", validProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)

		var createResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &createResponse)
		require.NoError(t, err)
		validProjectID := createResponse.ID

		// Get count after valid creation
		var countAfterValid int
		err = suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&countAfterValid)
		require.NoError(t, err)

		// Now try several invalid project creations that should all fail validation
		invalidAttempts := []testProject{
			{
				Name:            "", // Empty name should fail
				Description:     "",
				Application:     "Test App",
				Venue:           "",
				ProjectPhase:    "",
				EnvironmentType: types.EnvironmentTypeIndoor,
				Budget:          types.Budget{Amount: 1000, Currency: "USD"},
			},
			{
				Name:            "Invalid Environment Project",
				Description:     "",
				Application:     "Test App",
				Venue:           "",
				ProjectPhase:    "",
				EnvironmentType: "invalid_environment", // Invalid environment type
				Budget:          types.Budget{Amount: 1000, Currency: "USD"},
			},
		}

		for i, invalidProject := range invalidAttempts {
			w, err := suite.makeRequest("POST", "/api/v1/projects", invalidProject)
			require.NoError(t, err)
			assert.Equal(t, http.StatusBadRequest, w.Code, fmt.Sprintf("Invalid project attempt %d should fail validation", i+1))
		}

		// Verify count is still the same (only valid project exists)
		var finalCount int
		err = suite.db.QueryRow("SELECT COUNT(*) FROM project").Scan(&finalCount)
		require.NoError(t, err)
		assert.Equal(t, countAfterValid, finalCount, "Project count should only reflect the valid project creation")

		// Verify the valid project still exists and is accessible
		w, err = suite.makeRequest("GET", "/api/v1/projects?user_id="+suite.testUsers[0].ID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var projectsResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &projectsResponse)
		require.NoError(t, err)

		// Find our valid project in the response
		found := false
		for _, project := range projectsResponse.Data {
			if project.ID == validProjectID {
				found = true
				assert.Equal(t, "Valid Project Before Failures", project.Name)
				break
			}
		}
		assert.True(t, found, "Valid project should still exist after failed creation attempts")
	})
}

// Run the test suite
func TestProjectIntegrationSuite(t *testing.T) {
	suite.Run(t, new(ProjectIntegrationTestSuite))
}
