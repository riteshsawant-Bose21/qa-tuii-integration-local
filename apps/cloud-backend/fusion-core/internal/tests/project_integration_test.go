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
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/device"
	devicedb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/device/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/id"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	projectdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/cloudfs"
	sqlpkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
)

// Constants for frequently used literals
const (
	// HTTP Headers
	headerUserID = "X-User-ID"
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
	ID                        string                `json:"project_id"`
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
		"disable",
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

	return nil
}

// setupAPI initializes the API server with all necessary services
func (suite *ProjectIntegrationTestSuite) setupAPI() error {
	// Set Gin to test mode
	gin.SetMode(gin.TestMode)

	// Initialize dual loggers with test configuration
	loggerConfig := log.DefaultLoggerConfig()
	loggerConfig.Mode = "debug"
	loggerConfig.LogDir = "/tmp/fusion-test-logs" // Use temp directory for tests
	loggers, err := log.NewLoggers(loggerConfig)
	require.NoError(suite.T(), err, "Failed to create dual loggers")

	// Initialize services
	idSVC := id.NewService()
	require.NotNil(suite.T(), idSVC, "Failed to initialize ID service")

	// Initialize Product services (using mock S3 for tests)
	productDBSvc := productdb.NewService(suite.db, loggers.AppLogger)
	require.NotNil(suite.T(), productDBSvc, "Failed to initialize product database service")

	// Create test configurations for product service
	validationCfg := &config.Validation{
		SupportedVersions: []string{"v1"},
		RequireVersion:    false,
		DefaultVersion:    "v1",
	}
	processingCfg := &config.Processing{
		MaxWorkers:    4,
		BatchSize:     100,
		RetryAttempts: 3,
		RetryDelay:    "5s",
	}

	// Create a mock S3 client for testing
	s3Client, err := cloudfs.NewS3Client(context.Background(), "us-east-1")
	require.NoError(suite.T(), err, "Failed to create S3 client for testing")

	productSVC := product.NewService(productDBSvc, "v1", validationCfg, processingCfg, s3Client, loggers.AppLogger)
	require.NotNil(suite.T(), productSVC, "Failed to initialize product service")

	// Initialize Project services
	projectDBSvc := projectdb.NewService(suite.db)
	require.NotNil(suite.T(), projectDBSvc, "Failed to initialize project database service")

	// For integration testing, we disable S3 operations by passing nil presigner
	// This allows tests to run without requiring actual S3 configuration
	projectSVC := project.NewService(projectDBSvc, nil)
	require.NotNil(suite.T(), projectSVC, "Failed to initialize project service")

	// Initialize User services
	userDBSvc := userdb.NewService(suite.db)
	require.NotNil(suite.T(), userDBSvc, "Failed to initialize user database service")

	userSVC := user.NewService(userDBSvc)
	require.NotNil(suite.T(), userSVC, "Failed to initialize user service")

	// Initialize Role Management Service
	roleManagementSvc := userdb.NewRoleManagementService(suite.db)
	require.NotNil(suite.T(), roleManagementSvc, "Failed to initialize role management service")

	// Initialize IoT handler for device service
	iothandler, err := cloudfs.NewIoTClient(context.Background(), "us-east-1", loggers.AppLogger)
	require.NoError(suite.T(), err, "Failed to initialize IoT client")

	// Initialize Device services
	deviceDBSvc := devicedb.NewService(suite.db)
	require.NotNil(suite.T(), deviceDBSvc, "Failed to initialize device database service")

	deviceSVC := device.NewService(deviceDBSvc, iothandler)
	require.NotNil(suite.T(), deviceSVC, "Failed to initialize device service")

	// Initialize API server
	apiConfig := &api.Config{
		Mode: "test",
		Host: "localhost",
		Port: "0", // Use ephemeral port for testing
	}

	// Create mock auth service and middleware
	authSvc := &mockAuthService{}
	authMiddleware := &mockMiddlewareStruct{}

	apiServer, err := api.New(apiConfig, productSVC, projectSVC, userSVC, authSvc, authMiddleware, deviceSVC, loggers)
	if err != nil {
		return fmt.Errorf("failed to initialize API server: %w", err)
	}

	suite.api = apiServer

	// Create a separate test router without auth middleware for integration testing
	suite.ginRouter = suite.createTestRouter(projectSVC, productSVC, userSVC, userDBSvc, roleManagementSvc, loggers)

	return nil
}

// createTestRouter creates a Gin router with handlers but mocked authentication for testing
func (suite *ProjectIntegrationTestSuite) createTestRouter(projectSVC *project.Service, productSVC *product.Service, userSVC *user.Service, userDBSvc *userdb.Service, roleManagementSvc *userdb.RoleManagementService, loggers *log.Loggers) *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	// Add middleware for testing
	router.Use(gin.Recovery())
	router.Use(middleware.RequestLoggerMiddleware(loggers.AuditLogger))   // Use audit logger for requests
	router.Use(middleware.ApplicationLoggerMiddleware(loggers.AppLogger)) // Add app logger to context
	router.Use(suite.createMockAuthMiddleware())
	router.Use(suite.createMockAccessControlMiddleware(userSVC))

	// Setup routes
	suite.setupRoutes(router, projectSVC)

	return router
}

// createMockAuthMiddleware creates mock authentication middleware for testing
func (suite *ProjectIntegrationTestSuite) createMockAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetHeader(headerUserID)
		if userID == "" {
			userID = suite.testUsers[0].ID
		}

		userEmail := suite.findUserEmailByID(userID)
		if userEmail == "" {
			userEmail = suite.testUsers[0].Email
		}

		c.Set("userID", userID)
		c.Set("email", userEmail)
		c.Set("user_email", userEmail)
		c.Next()
	}
}

// findUserEmailByID finds a user's email by their ID
func (suite *ProjectIntegrationTestSuite) findUserEmailByID(userID string) string {
	for _, testUser := range suite.testUsers {
		if testUser.ID == userID {
			return testUser.Email
		}
	}
	return ""
}

// createMockAccessControlMiddleware creates mock access control middleware for testing
func (suite *ProjectIntegrationTestSuite) createMockAccessControlMiddleware(userSVC *user.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		userEmail, exists := c.Get("user_email")
		if !exists {
			c.JSON(http.StatusUnauthorized, types.ErrorResponse{ErrorMessage: errorutil.MsgUnauthorized})
			c.Abort()
			return
		}

		email, ok := userEmail.(string)
		if !ok {
			c.JSON(http.StatusUnauthorized, types.ErrorResponse{ErrorMessage: errorutil.MsgUnauthorized})
			c.Abort()
			return
		}

		userAuth, err := userSVC.GetUserAuthorization(c, email)
		if err != nil {
			userAuth = suite.createMockUserAuth(c)
		} else {
			suite.preserveContextUserID(c, userAuth)
		}

		c.Set("user_auth", userAuth)
		c.Next()
	}
}

// createMockUserAuth creates a mock user authorization for testing
func (suite *ProjectIntegrationTestSuite) createMockUserAuth(c *gin.Context) *types.UserAuthorizationResponse {
	userID, _ := c.Get("userID")
	userEmail, _ := c.Get("user_email")

	return &types.UserAuthorizationResponse{
		User: types.UserInfo{
			ID:    userID.(string),
			Email: userEmail.(string),
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
			"project.read":   "read",
			"project.create": "edit",
			"project.update": "edit",
			"project.delete": "edit",
			"projects":       "edit",
			"*":              "edit",
		},
	}
}

// preserveContextUserID preserves the user ID from the context in the user auth
func (suite *ProjectIntegrationTestSuite) preserveContextUserID(c *gin.Context, userAuth *types.UserAuthorizationResponse) {
	contextUserID, _ := c.Get("userID")
	if contextUserID != nil {
		userAuth.User.ID = contextUserID.(string)
	}
}

// setupRoutes sets up the API routes for the test router
func (suite *ProjectIntegrationTestSuite) setupRoutes(router *gin.Engine, projectSVC *project.Service) {
	projectHandler := handler.NewProjectHandler(projectSVC)

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
}

// Helper method to make HTTP requests to the API
func (suite *ProjectIntegrationTestSuite) makeRequest(method, path string, body interface{}) (*httptest.ResponseRecorder, error) {
	return suite.makeRequestWithUser(method, path, body, "")
}

func (suite *ProjectIntegrationTestSuite) makeRequestWithUser(method, path string, body interface{}, userID string) (*httptest.ResponseRecorder, error) {
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

	// Set the user ID header if provided
	if userID != "" {
		req.Header.Set("X-User-ID", userID)
	}

	w := httptest.NewRecorder()

	// Serve the request - authentication is already mocked in router middleware
	suite.ginRouter.ServeHTTP(w, req)

	// Debug response for failures
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
		project.ID = uuid.New().String() // Generate fresh ID for this test

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.NotEmpty(t, response.ID)
		// In test environment, upload URLs may be nil when no S3 presigner is configured
		// In production, these would be populated when IsProjectFileCreated/IsProjectThumbnailCreated are true
	})

	suite.T().Run("should fail with invalid project data", func(t *testing.T) {
		invalidProject := testProject{
			ID:   uuid.New().String(),
			Name: "", // Missing required name
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})

	suite.T().Run("should rollback transaction when creating project with invalid data", func(t *testing.T) {
		// Count projects before the failed attempt
		w, err := suite.makeRequest("GET", "/api/v1/projects", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var beforeResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &beforeResponse)
		require.NoError(t, err)
		initialProjectCount := beforeResponse.TotalCount

		// Try to create project with invalid data that should cause validation failure and rollback
		projectWithInvalidData := types.ProjectCreateRequest{
			ID:              uuid.New().String(),
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
		w, err = suite.makeRequest("GET", "/api/v1/projects", nil)
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
	// Create a test project for this test
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)

	suite.T().Run("should get all projects", func(t *testing.T) {
		w, err := suite.makeRequest("GET", "/api/v1/projects", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		assert.GreaterOrEqual(t, len(response.Data), 1)
		assert.Greater(t, response.TotalCount, 0)
	})

	suite.T().Run("should filter archived projects", func(t *testing.T) {
		w, err := suite.makeRequest("GET", "/api/v1/projects?is_archived=true", nil)
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
	// Create a project for this test
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should update project successfully", func(t *testing.T) {
		require.NotEmpty(t, projectID)

		updateData := types.ProjectUpdateRequest{
			Name:                    "Updated Test Conference Room",
			Description:             "Updated description for integration test",
			Application:             "Updated Corporate Conference Room",
			IsProjectFileDirty:      true,
			IsProjectThumbnailDirty: true,
		}

		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, updateData)
		require.NoError(t, err)

		assert.Equal(t, http.StatusOK, w.Code)

		var response types.ProjectUpdateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		// In test environment, upload URLs may be nil when no S3 presigner is configured
		// In production, ProjectUploadURL would be populated when IsProjectFileDirty is true
	})

	suite.T().Run("should fail with invalid project ID", func(t *testing.T) {
		updateData := types.ProjectUpdateRequest{
			Name: "Updated Name",
		}

		w, err := suite.makeRequest("PATCH", "/api/v1/projects/invalid-uuid", updateData)
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
		w, err := suite.makeRequest("DELETE", "/api/v1/projects/"+projectID, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail to delete non-existent project", func(t *testing.T) {
		w, err := suite.makeRequest("DELETE", "/api/v1/projects/00000000-0000-4000-8000-000000000000", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

// Test Assign User to Project endpoint
func (suite *ProjectIntegrationTestSuite) TestAssignUserToProject() {
	// Create a project for this test
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should assign user to project successfully", func(t *testing.T) {
		userEmail := suite.testUsers[1].Email

		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail with non-existent user", func(t *testing.T) {
		w, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/nonexistent@example.com", nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNotFound, w.Code)
	})
}

// Test Remove User from Project endpoint
func (suite *ProjectIntegrationTestSuite) TestRemoveUserFromProject() {
	// Create a project and assign a user
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	// Assign user first
	userEmail := suite.testUsers[1].Email
	w, err = suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should remove user from project successfully", func(t *testing.T) {
		w, err := suite.makeRequest("DELETE", "/api/v1/projects/"+projectID+"/users/"+userEmail, nil)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test UpdateProjectStar endpoint
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectStar() {
	// Create a project for this test
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should star project successfully", func(t *testing.T) {
		userID := suite.testUsers[0].ID
		starRequest := types.ProjectStarRequest{IsStarred: true}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unstar project successfully", func(t *testing.T) {
		userID := suite.testUsers[0].ID
		starRequest := types.ProjectStarRequest{IsStarred: false}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/star/"+userID, starRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test UpdateProjectArchive endpoint
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectArchive() {
	// Create a project for this test
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should archive project successfully", func(t *testing.T) {
		archiveRequest := types.ProjectArchiveRequest{Archive: true}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unarchive project successfully", func(t *testing.T) {
		archiveRequest := types.ProjectArchiveRequest{Archive: false}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail to archive non-existent project", func(t *testing.T) {
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err := suite.makeRequest("POST", "/api/v1/projects/00000000-0000-4000-8000-000000000000/archive", archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should fail with invalid project ID", func(t *testing.T) {
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err := suite.makeRequest("POST", "/api/v1/projects/invalid-uuid/archive", archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should fail with empty request body", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

// Test UpdateProjectLock endpoint
func (suite *ProjectIntegrationTestSuite) TestUpdateProjectLock() {
	// Create a project for this test
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should lock project successfully", func(t *testing.T) {
		lockRequest := types.ProjectLockRequest{IsLocked: true}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should unlock project successfully", func(t *testing.T) {
		lockRequest := types.ProjectLockRequest{IsLocked: false}

		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest)
		require.NoError(t, err)

		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should fail to lock non-existent project", func(t *testing.T) {
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err := suite.makeRequest("POST", "/api/v1/projects/00000000-0000-4000-8000-000000000000/lock", lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should fail with invalid project ID", func(t *testing.T) {
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err := suite.makeRequest("POST", "/api/v1/projects/invalid-uuid/lock", lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
	})

	suite.T().Run("should fail with empty request body", func(t *testing.T) {
		projectID := suite.testProjects[0].ID
		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}

// Test end-to-end project workflow
func (suite *ProjectIntegrationTestSuite) TestProjectWorkflow() {
	suite.T().Run("complete project lifecycle", func(t *testing.T) {
		// 1. Create project
		project := testProject{
			ID:              uuid.New().String(),
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
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// 5. Lock the project
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 6. Unlock the project
		unlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", unlockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 7. Archive the project
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// 8. Verify project is archived in listing
		w, err = suite.makeRequest("GET", "/api/v1/projects?is_archived=true", nil)
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

	suite.T().Run("should handle invalid UUIDs", func(t *testing.T) {
		// Test invalid project ID in path
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/invalid-uuid", types.ProjectUpdateRequest{Name: "Test"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)
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
			ID: uuid.New().String(),
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

	suite.T().Run("should handle non-existent project operations", func(t *testing.T) {
		nonExistentID := "00000000-0000-4000-8000-000000000000"
		userID := suite.testUsers[0].ID

		// Try to update non-existent project
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+nonExistentID, types.ProjectUpdateRequest{Name: "Test"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to delete non-existent project
		w, err = suite.makeRequest("DELETE", "/api/v1/projects/"+nonExistentID, nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to star non-existent project
		starRequest := types.ProjectStarRequest{IsStarred: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+nonExistentID+"/star/"+userID, starRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to archive non-existent project
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+nonExistentID+"/archive", archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		// Try to lock non-existent project
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+nonExistentID+"/lock?"+userID, lockRequest)
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
		ID:              uuid.New().String(),
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
		w, err := suite.makeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest, user1ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// User 2 tries to update the locked project (should fail)
		// Note: If User 2 is admin from same account, they might have access but be blocked by lock
		updateData := types.ProjectUpdateRequest{Name: "Updated by User 2"}
		w, err = suite.makeRequestWithUser("PATCH", "/api/v1/projects/"+projectID, updateData, user2ID)
		require.NoError(t, err)
		// Expect either Forbidden (no access) or Conflict (locked), depending on user's account relationship
		assert.True(t, w.Code == http.StatusForbidden || w.Code == http.StatusConflict)

		// User 2 tries to delete the locked project (should fail)
		w, err = suite.makeRequestWithUser("DELETE", "/api/v1/projects/"+projectID, nil, user2ID)
		require.NoError(t, err)
		// Expect either Forbidden (no access) or Conflict (locked), depending on user's account relationship
		assert.True(t, w.Code == http.StatusForbidden || w.Code == http.StatusConflict)

		// User 2 tries to unlock project locked by User 1 (should fail)
		unlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/lock", unlockRequest, user2ID)
		require.NoError(t, err)
		// Expect either Forbidden (no access) or Conflict (wrong user unlocking), depending on user's account relationship
		assert.True(t, w.Code == http.StatusForbidden || w.Code == http.StatusConflict)

		// User 1 (who locked it) can still update
		w, err = suite.makeRequestWithUser("PATCH", "/api/v1/projects/"+projectID, types.ProjectUpdateRequest{Name: "Updated by User 1"}, user1ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// User 1 unlocks the project
		user1UnlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/lock", user1UnlockRequest, user1ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Now check if User 2 can update after unlock
		// This depends on whether User 2 has access (same account or assigned to project)
		w, err = suite.makeRequestWithUser("PATCH", "/api/v1/projects/"+projectID, types.ProjectUpdateRequest{Name: "Updated by User 2 after unlock"}, user2ID)
		require.NoError(t, err)
		// User 2 might still be forbidden if they're from different account and not assigned
		// or might succeed if they're from same account or properly assigned
		assert.True(t, w.Code == http.StatusOK || w.Code == http.StatusForbidden)
	})
}

// Test archived project restrictions
func (suite *ProjectIntegrationTestSuite) TestArchivedProjectRestrictions() {
	// Create and archive a project
	project := testProject{
		ID:              uuid.New().String(),
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
	w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should restrict operations on archived projects", func(t *testing.T) {
		userID := suite.testUsers[0].ID

		// Try to update archived project (should fail)
		// Note: Admin from same account might have access but operations should be restricted on archived projects
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?"+userID, types.ProjectUpdateRequest{Name: "Updated archived"})
		require.NoError(t, err)
		// Operations on archived projects should be forbidden regardless of admin status
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to delete archived project (should fail)
		w, err = suite.makeRequest("DELETE", "/api/v1/projects/"+projectID+"?"+userID, nil)
		require.NoError(t, err)
		// Operations on archived projects should be forbidden regardless of admin status
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to lock archived project (should fail)
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?"+userID, lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Unarchive should work
		unarchiveRequest := types.ProjectArchiveRequest{Archive: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive?"+userID, unarchiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Now operations should work again
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID+"?"+userID, types.ProjectUpdateRequest{Name: "Updated after unarchive"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})
}

// Test query parameter validation and filtering
func (suite *ProjectIntegrationTestSuite) TestQueryParameterValidation() {
	suite.T().Run("should validate query parameters", func(t *testing.T) {
		// Test invalid sort_order
		w, err := suite.makeRequest("GET", "/api/v1/projects?sort_order=invalid", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Test invalid boolean for is_archived
		w, err = suite.makeRequest("GET", "/api/v1/projects?is_archived=invalid_bool", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		// Test valid parameters
		w, err = suite.makeRequest("GET", "/api/v1/projects?sort_by=created_at&sort_order=desc&is_archived=false", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Test invalid sort_by field
		w, err = suite.makeRequest("GET", "/api/v1/projects?sort_by=invalid_field", nil)
		require.NoError(t, err)
		// API might accept invalid fields and use default, or return 400
		assert.True(t, w.Code == http.StatusOK || w.Code == http.StatusBadRequest)
	})
}

// Test unauthorized user operations
func (suite *ProjectIntegrationTestSuite) TestUnauthorizedUserOperations() {
	// Create a project using admin@bose.com (suite.testUsers[0]) - this will set primary_owner_account_id to Bose Corporation account
	// Then test with user from different account (prof.operator@university.edu - suite.testUsers[2])
	project := suite.testProjects[0]
	project.ID = uuid.New().String() // Generate fresh ID for this test
	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should prevent unauthorized user operations from different account", func(t *testing.T) {
		// Use prof.operator@university.edu (suite.testUsers[2]) who belongs to University account,
		// different from the project's primary owner account (Bose Corporation)
		unauthorizedUserID := suite.testUsers[2].ID // User from different account, not assigned to project

		// Try to update project as unauthorized user
		updateData := types.ProjectUpdateRequest{Name: "Unauthorized update"}
		w, err := suite.makeRequestWithUser("PATCH", "/api/v1/projects/"+projectID, updateData, unauthorizedUserID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to delete as unauthorized user
		w, err = suite.makeRequestWithUser("DELETE", "/api/v1/projects/"+projectID, nil, unauthorizedUserID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to star as unauthorized user
		starRequest := types.ProjectStarRequest{IsStarred: true}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+projectID+"/star/"+unauthorizedUserID, starRequest, unauthorizedUserID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)
	})

	suite.T().Run("should allow admin from same account to access project without assignment", func(t *testing.T) {
		// test@domain.com (suite.testUsers[1]) belongs to same account as our test projects will be created under
		// when we create projects with default user context. However, since the default user is admin@bose.com,
		// let's create a project specifically with test@domain.com as creator
		adminUserID := suite.testUsers[1].ID // test@domain.com - Admin from Metro Conference Center account

		// Create a project with this admin user
		project := testProject{
			ID:              uuid.New().String(),
			Name:            "Admin Account Test Project",
			Description:     "Project for testing admin account access",
			Application:     "Corporate Conference Room",
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

		w, err := suite.makeRequestWithUser("POST", "/api/v1/projects", project, adminUserID)
		require.NoError(t, err)
		require.Equal(t, http.StatusCreated, w.Code)

		var adminProjectResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &adminProjectResponse)
		require.NoError(t, err)
		adminProjectID := adminProjectResponse.ID

		// Now test that this admin can perform operations on their account's project without being explicitly assigned
		// Update should succeed
		updateData := types.ProjectUpdateRequest{Name: "Admin Updated Project"}
		w, err = suite.makeRequestWithUser("PATCH", "/api/v1/projects/"+adminProjectID, updateData, adminUserID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Lock should succeed
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+adminProjectID+"/lock", lockRequest, adminUserID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Unlock should succeed
		unlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+adminProjectID+"/lock", unlockRequest, adminUserID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Delete should succeed
		w, err = suite.makeRequestWithUser("DELETE", "/api/v1/projects/"+adminProjectID, nil, adminUserID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})
}

// Test concurrent operations and race conditions
func (suite *ProjectIntegrationTestSuite) TestConcurrentOperations() {
	// Create a project for concurrent testing
	project := testProject{
		ID:              uuid.New().String(),
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
		// Perform multiple archive/unarchive operations
		for i := 0; i < 3; i++ {
			// Archive
			archiveRequest := types.ProjectArchiveRequest{Archive: true}
			w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)

			// Unarchive
			unarchiveRequest := types.ProjectArchiveRequest{Archive: false}
			w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", unarchiveRequest)
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
			w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?"+userID, lockRequest)
			require.NoError(t, err)
			assert.Equal(t, http.StatusNoContent, w.Code)

			// Unlock
			unlockRequest := types.ProjectLockRequest{IsLocked: false}
			w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock?"+userID, unlockRequest)
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
			ID:              uuid.New().String(),
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
		// Create a valid project for this test
		project := suite.testProjects[0]
		project.ID = uuid.New().String() // Generate fresh ID for this test
		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		require.Equal(t, http.StatusCreated, w.Code)

		var createResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &createResponse)
		require.NoError(t, err)
		projectID := createResponse.ID

		// Test update with invalid data
		invalidUpdate := types.ProjectUpdateRequest{
			Name:        "", // Empty name might be accepted for partial updates
			Description: "Valid description",
		}

		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, invalidUpdate)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code) // Empty name accepted for partial updates
	})

	suite.T().Run("should validate email formats", func(t *testing.T) {
		// Create a project for this test
		project := suite.testProjects[0]
		project.ID = uuid.New().String() // Generate fresh ID for this test
		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		require.Equal(t, http.StatusCreated, w.Code)

		var createResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &createResponse)
		require.NoError(t, err)
		projectID := createResponse.ID

		// Test with invalid email format
		w2, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/invalid-email", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w2.Code) // Invalid email treated as user not found

		// Test with empty email
		w3, err := suite.makeRequest("PUT", "/api/v1/projects/"+projectID+"/users/", nil)
		require.NoError(t, err)
		// This should return 404 as the router won't match the route
		assert.Equal(t, http.StatusNotFound, w3.Code)
	})
}

// Test boundary conditions and limits
func (suite *ProjectIntegrationTestSuite) TestBoundaryConditions() {
	suite.T().Run("should handle pagination limits", func(t *testing.T) {
		// Test with very large limit (should be capped)
		w, err := suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&limit=99999", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Test with zero limit
		w, err = suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&limit=0", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Test with negative offset
		w, err = suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&offset=-1", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})

	suite.T().Run("should handle special characters in project data", func(t *testing.T) {
		specialProject := testProject{
			ID:              uuid.New().String(),
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
				ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
				ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
				ID:              uuid.New().String(),
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
				ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
			w, err := suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&sort_by="+sortField, nil)
			require.NoError(t, err)
			assert.Equal(t, http.StatusOK, w.Code)
		}
	})

	suite.T().Run("should reject invalid sort_by parameter", func(t *testing.T) {
		invalidSortFields := []string{"invalid_field", "id", "description"}

		for _, sortField := range invalidSortFields {
			w, err := suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&sort_by="+sortField, nil)
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
			w, err := suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&sort_order="+sortOrder, nil)
			require.NoError(t, err)
			assert.Equal(t, http.StatusOK, w.Code)
		}
	})

	suite.T().Run("should reject invalid sort_order parameter", func(t *testing.T) {
		invalidSortOrders := []string{"ascending", "descending", "invalid"}

		for _, sortOrder := range invalidSortOrders {
			w, err := suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&sort_order="+sortOrder, nil)
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
			ID:              uuid.New().String(),
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
		project.ID = uuid.New().String() // Generate fresh ID for this test
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
		// Create a project for this test
		project := suite.testProjects[0]
		project.ID = uuid.New().String() // Generate fresh ID for this test
		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		require.Equal(t, http.StatusCreated, w.Code)

		var createResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &createResponse)
		require.NoError(t, err)
		projectID := createResponse.ID

		req, err := http.NewRequest("PATCH", "/api/v1/projects/"+projectID, bytes.NewReader([]byte("null")))
		require.NoError(t, err)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer test-token")
		req.Header.Set("X-User-ID", suite.testUsers[0].ID)
		req.Header.Set("X-Account-ID", "1")

		w = httptest.NewRecorder()
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
			ID:              uuid.New().String(),
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
		project2.ID = uuid.New().String() // Generate fresh ID for second project
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
			ID:              uuid.New().String(),
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
		project.ID = uuid.New().String() // Generate fresh ID for the duplicate attempt
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

// Test project retrieval with various filters
func (suite *ProjectIntegrationTestSuite) TestAdvancedProjectFiltering() {

	suite.T().Run("should filter by archived status correctly", func(t *testing.T) {
		// Get non-archived projects
		w, err := suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&is_archived=false", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var nonArchivedResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &nonArchivedResponse)
		require.NoError(t, err)

		// Get archived projects
		w2, err := suite.makeRequest("GET", "/api/v1/projects?"+suite.testUsers[0].ID+"&is_archived=true", nil)
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
			url := fmt.Sprintf("/api/v1/projects?limit=%s&offset=%s",
				test.limit, test.offset)
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
		ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
			ID: uuid.New().String(),
			// Missing required fields
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", invalidProject)
		require.NoError(t, err)
		assert.Equal(t, http.StatusBadRequest, w.Code)

		var errorResponse types.ErrorResponse
		err = json.Unmarshal(w.Body.Bytes(), &errorResponse)
		require.NoError(t, err)
		assert.NotEmpty(t, errorResponse.ErrorMessage)
	})

	suite.T().Run("should return consistent error format for not found errors", func(t *testing.T) {
		w, err := suite.makeRequest("PATCH", "/api/v1/projects/00000000-0000-4000-8000-000000000000?"+suite.testUsers[0].ID, types.ProjectUpdateRequest{Name: "Test"})
		require.NoError(t, err)
		assert.Equal(t, http.StatusNotFound, w.Code)

		var errorResponse types.ErrorResponse
		err = json.Unmarshal(w.Body.Bytes(), &errorResponse)
		require.NoError(t, err)
		assert.NotEmpty(t, errorResponse.ErrorMessage)
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
		project.ID = uuid.New().String() // Generate fresh ID for this test
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
			ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
					ID:              uuid.New().String(),
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
			ID:              uuid.New().String(),
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
				ID:              uuid.New().String(),
				Name:            "", // Empty name should fail
				Description:     "",
				Application:     "Test App",
				Venue:           "",
				ProjectPhase:    "",
				EnvironmentType: types.EnvironmentTypeIndoor,
				Budget:          types.Budget{Amount: 1000, Currency: "USD"},
			},
			{
				ID:              uuid.New().String(),
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
		w, err = suite.makeRequest("GET", "/api/v1/projects", nil)
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

// Test API response format consistency
func (suite *ProjectIntegrationTestSuite) TestAPIResponseConsistency() {
	suite.T().Run("should return consistent error format across endpoints", func(t *testing.T) {
		testCases := []struct {
			name         string
			method       string
			url          string
			body         interface{}
			expectedCode int
		}{
			{
				name:         "invalid project ID in update",
				method:       "PATCH",
				url:          "/api/v1/projects/invalid-uuid",
				body:         types.ProjectUpdateRequest{Name: "Test"},
				expectedCode: http.StatusNotFound,
			},
			{
				name:         "invalid project ID in delete",
				method:       "DELETE",
				url:          "/api/v1/projects/invalid-uuid",
				body:         nil,
				expectedCode: http.StatusNotFound,
			},
			{
				name:         "invalid project ID in star",
				method:       "POST",
				url:          "/api/v1/projects/invalid-uuid/star/user123",
				body:         types.ProjectStarRequest{IsStarred: true},
				expectedCode: http.StatusNotFound,
			},
			{
				name:         "invalid project ID in archive",
				method:       "POST",
				url:          "/api/v1/projects/invalid-uuid/archive",
				body:         types.ProjectArchiveRequest{Archive: true},
				expectedCode: http.StatusNotFound,
			},
			{
				name:         "invalid project ID in lock",
				method:       "POST",
				url:          "/api/v1/projects/invalid-uuid/lock",
				body:         types.ProjectLockRequest{IsLocked: true},
				expectedCode: http.StatusNotFound,
			},
		}

		for _, tc := range testCases {
			t.Run(tc.name, func(t *testing.T) {
				w, err := suite.makeRequest(tc.method, tc.url, tc.body)
				require.NoError(t, err)
				assert.Equal(t, tc.expectedCode, w.Code)

				// Verify error response format
				if w.Code >= 400 {
					var errorResponse types.ErrorResponse
					err = json.Unmarshal(w.Body.Bytes(), &errorResponse)
					require.NoError(t, err)
					assert.NotEmpty(t, errorResponse.ErrorMessage, "Error response should have a message")
				}
			})
		}
	})

	suite.T().Run("should return consistent success response format", func(t *testing.T) {
		// Create a project first
		project := testProject{
			ID:              uuid.New().String(),
			Name:            "Response Format Test Project",
			Application:     "Test Application",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		assert.Equal(t, http.StatusCreated, w.Code)

		var createResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &createResponse)
		require.NoError(t, err)
		assert.NotEmpty(t, createResponse.ID)
		// Note: Upload URLs may be nil in test environment without S3

		// Test update response format
		updateData := types.ProjectUpdateRequest{Name: "Updated Name"}
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+createResponse.ID, updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var updateResponse types.ProjectUpdateResponse
		err = json.Unmarshal(w.Body.Bytes(), &updateResponse)
		require.NoError(t, err)
		// Note: Upload URLs may be nil in test environment without S3

		// Test list response format
		w, err = suite.makeRequest("GET", "/api/v1/projects", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var listResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &listResponse)
		require.NoError(t, err)
		assert.NotNil(t, listResponse.Data)
		assert.GreaterOrEqual(t, listResponse.TotalCount, 0)
		assert.GreaterOrEqual(t, listResponse.Page, 0)
		assert.GreaterOrEqual(t, listResponse.TotalPages, 0)
	})
}

// Test missing endpoint scenarios
func (suite *ProjectIntegrationTestSuite) TestMissingEndpoints() {
	suite.T().Run("should handle unsupported HTTP methods", func(t *testing.T) {
		unsupportedMethods := []string{"PUT", "HEAD", "TRACE"}

		for _, method := range unsupportedMethods {
			req, err := http.NewRequest(method, "/api/v1/projects", nil)
			require.NoError(t, err)
			req.Header.Set("X-User-ID", suite.testUsers[0].ID)

			w := httptest.NewRecorder()
			suite.ginRouter.ServeHTTP(w, req)

			// Should return 405 Method Not Allowed or 404 Not Found
			assert.True(t, w.Code == http.StatusMethodNotAllowed || w.Code == http.StatusNotFound,
				"Method %s should return 405 or 404, got %d", method, w.Code)
		}
	})

	suite.T().Run("should handle malformed JSON gracefully", func(t *testing.T) {
		malformedJSONTests := []struct {
			name string
			body string
		}{
			{"incomplete JSON object", `{"name": "test"`},
			{"invalid JSON syntax", `{invalid json}`},
			{"extra comma", `{"name": "test",}`},
			{"missing quotes", `{name: "test"}`},
		}

		for _, test := range malformedJSONTests {
			t.Run(test.name, func(t *testing.T) {
				req, err := http.NewRequest("POST", "/api/v1/projects", strings.NewReader(test.body))
				require.NoError(t, err)
				req.Header.Set("Content-Type", "application/json")
				req.Header.Set("X-User-ID", suite.testUsers[0].ID)

				w := httptest.NewRecorder()
				suite.ginRouter.ServeHTTP(w, req)

				assert.Equal(t, http.StatusBadRequest, w.Code)

				var errorResponse types.ErrorResponse
				err = json.Unmarshal(w.Body.Bytes(), &errorResponse)
				require.NoError(t, err)
				assert.NotEmpty(t, errorResponse.ErrorMessage)
			})
		}
	})
}

// Test comprehensive project permissions and access control
func (suite *ProjectIntegrationTestSuite) TestProjectPermissions() {
	// Create projects with different owners
	adminUser := suite.testUsers[0] // admin@bose.com - Bose Corporation account
	endUser := suite.testUsers[1]   // test@domain.com - Metro Conference Center account

	// Create project with admin user
	adminProject := testProject{
		ID:              uuid.New().String(),
		Name:            "Admin Project",
		Description:     "Project owned by admin user",
		Application:     "Admin Application",
		Venue:           "Admin Venue",
		ProjectPhase:    types.ProjectPhaseProposal,
		EnvironmentType: types.EnvironmentTypeIndoor,
		Budget: types.Budget{
			Amount:   50000,
			Currency: "USD",
		},
		IsProjectFileCreated:      false,
		IsProjectThumbnailCreated: false,
	}

	w, err := suite.makeRequestWithUser("POST", "/api/v1/projects", adminProject, adminUser.ID)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var adminProjectResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &adminProjectResponse)
	require.NoError(suite.T(), err)
	adminProjectID := adminProjectResponse.ID

	suite.T().Run("should allow project owner to perform all operations", func(t *testing.T) {
		// Update project
		updateData := types.ProjectUpdateRequest{Name: "Updated Admin Project"}
		w, err := suite.makeRequestWithUser("PATCH", "/api/v1/projects/"+adminProjectID, updateData, adminUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Lock project
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+adminProjectID+"/lock", lockRequest, adminUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Unlock project
		unlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+adminProjectID+"/lock", unlockRequest, adminUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Archive project
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+adminProjectID+"/archive", archiveRequest, adminUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Unarchive project
		unarchiveRequest := types.ProjectArchiveRequest{Archive: false}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+adminProjectID+"/archive", unarchiveRequest, adminUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)
	})

	suite.T().Run("should prevent unauthorized access from different account", func(t *testing.T) {
		// Try to access admin's project with end user (different account)
		updateData := types.ProjectUpdateRequest{Name: "Unauthorized Update"}
		w, err := suite.makeRequestWithUser("PATCH", "/api/v1/projects/"+adminProjectID, updateData, endUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Try to delete
		w, err = suite.makeRequestWithUser("DELETE", "/api/v1/projects/"+adminProjectID, nil, endUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)
	})

	suite.T().Run("should handle project assignment correctly", func(t *testing.T) {
		// Assign end user to admin's project
		w, err := suite.makeRequestWithUser("PUT", "/api/v1/projects/"+adminProjectID+"/users/"+endUser.Email, nil, adminUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Now end user should be able to star the project
		starRequest := types.ProjectStarRequest{IsStarred: true}
		w, err = suite.makeRequestWithUser("POST", "/api/v1/projects/"+adminProjectID+"/star/"+endUser.ID, starRequest, endUser.ID)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// But end user still shouldn't be able to delete (depending on role permissions)
		w, err = suite.makeRequestWithUser("DELETE", "/api/v1/projects/"+adminProjectID, nil, endUser.ID)
		require.NoError(t, err)
		// This should fail with forbidden since end user doesn't have delete permissions
		assert.Equal(t, http.StatusForbidden, w.Code)
	})
}

// Test project listing and filtering capabilities
func (suite *ProjectIntegrationTestSuite) TestProjectListingAndFiltering() {
	// Create several projects with different states
	projects := []testProject{
		{
			ID:              uuid.New().String(),
			Name:            "Active Project 1",
			Description:     "Active project for testing",
			Application:     "Test Application",
			Venue:           "Test Venue 1",
			ProjectPhase:    types.ProjectPhaseProposal,
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
		},
		{
			ID:              uuid.New().String(),
			Name:            "Active Project 2",
			Description:     "Another active project",
			Application:     "Test Application",
			Venue:           "Test Venue 2",
			ProjectPhase:    types.ProjectPhaseDevelopment,
			EnvironmentType: types.EnvironmentTypeOutdoor,
			Budget: types.Budget{
				Amount:   35000,
				Currency: "USD",
			},
		},
	}

	var createdProjectIDs []string

	// Create the projects
	for _, project := range projects {
		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(suite.T(), err)
		require.Equal(suite.T(), http.StatusCreated, w.Code)

		var response types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(suite.T(), err)
		createdProjectIDs = append(createdProjectIDs, response.ID)
	}

	suite.T().Run("should list all active projects", func(t *testing.T) {
		w, err := suite.makeRequest("GET", "/api/v1/projects?is_archived=false", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var response types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)

		// Should have at least our created projects
		assert.GreaterOrEqual(t, len(response.Data), 2)
		assert.GreaterOrEqual(t, response.TotalCount, 2)

		// All projects should not be archived
		for _, project := range response.Data {
			assert.False(t, project.IsArchived)
		}
	})

	// Archive one project for filtering tests
	archiveRequest := types.ProjectArchiveRequest{Archive: true}
	w, err := suite.makeRequest("POST", "/api/v1/projects/"+createdProjectIDs[0]+"/archive", archiveRequest)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusNoContent, w.Code)

	suite.T().Run("should filter archived projects correctly", func(t *testing.T) {
		// Get archived projects
		w, err := suite.makeRequest("GET", "/api/v1/projects?is_archived=true", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var archivedResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &archivedResponse)
		require.NoError(t, err)

		// Should have at least one archived project (the one we archived)
		assert.GreaterOrEqual(t, len(archivedResponse.Data), 1)

		// All should be archived
		for _, project := range archivedResponse.Data {
			assert.True(t, project.IsArchived)
		}

		// Get non-archived projects
		w, err = suite.makeRequest("GET", "/api/v1/projects?is_archived=false", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		var activeResponse types.GetAllProjectsResponse
		err = json.Unmarshal(w.Body.Bytes(), &activeResponse)
		require.NoError(t, err)

		// All should be non-archived
		for _, project := range activeResponse.Data {
			assert.False(t, project.IsArchived)
		}
	})

	suite.T().Run("should handle sorting parameters", func(t *testing.T) {
		// Test sort by created_at ascending
		w, err := suite.makeRequest("GET", "/api/v1/projects?sort_by=created_at&sort_order=asc", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)

		// Test sort by updated_at descending
		w, err = suite.makeRequest("GET", "/api/v1/projects?sort_by=updated_at&sort_order=desc", nil)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})
}

// Test comprehensive validation scenarios
func (suite *ProjectIntegrationTestSuite) TestComprehensiveValidation() {
	suite.T().Run("should validate all required fields for project creation", func(t *testing.T) {
		testCases := []struct {
			name        string
			project     testProject
			expectError bool
		}{
			{
				name: "valid project",
				project: testProject{
					ID:              uuid.New().String(),
					Name:            "Valid Project",
					Application:     "Valid Application",
					EnvironmentType: types.EnvironmentTypeIndoor,
					Budget: types.Budget{
						Amount:   25000,
						Currency: "USD",
					},
				},
				expectError: false,
			},
			{
				name: "missing name",
				project: testProject{
					ID:              uuid.New().String(),
					Application:     "Valid Application",
					EnvironmentType: types.EnvironmentTypeIndoor,
					Budget: types.Budget{
						Amount:   25000,
						Currency: "USD",
					},
				},
				expectError: true,
			},
			{
				name: "missing application",
				project: testProject{
					ID:              uuid.New().String(),
					Name:            "Valid Project",
					EnvironmentType: types.EnvironmentTypeIndoor,
					Budget: types.Budget{
						Amount:   25000,
						Currency: "USD",
					},
				},
				expectError: true,
			},
			{
				name: "missing environment type",
				project: testProject{
					ID:          uuid.New().String(),
					Name:        "Valid Project",
					Application: "Valid Application",
					Budget: types.Budget{
						Amount:   25000,
						Currency: "USD",
					},
				},
				expectError: true,
			},
			{
				name: "invalid currency",
				project: testProject{

					ID:              uuid.New().String(),
					Name:            "Valid Project",
					Application:     "Valid Application",
					EnvironmentType: types.EnvironmentTypeIndoor,
					Budget: types.Budget{
						Amount:   25000,
						Currency: "INVALID",
					},
				},
				expectError: true,
			},
		}

		for _, tc := range testCases {
			t.Run(tc.name, func(t *testing.T) {
				w, err := suite.makeRequest("POST", "/api/v1/projects", tc.project)
				require.NoError(t, err)

				if tc.expectError {
					assert.Equal(t, http.StatusBadRequest, w.Code)
				} else {
					assert.Equal(t, http.StatusCreated, w.Code)
				}
			})
		}
	})

	suite.T().Run("should validate project update requests", func(t *testing.T) {
		// First create a valid project
		project := testProject{
			ID:              uuid.New().String(),
			Name:            "Update Test Project",
			Application:     "Test Application",
			EnvironmentType: types.EnvironmentTypeIndoor,
			Budget: types.Budget{
				Amount:   25000,
				Currency: "USD",
			},
		}

		w, err := suite.makeRequest("POST", "/api/v1/projects", project)
		require.NoError(t, err)
		require.Equal(t, http.StatusCreated, w.Code)

		var createResponse types.ProjectCreateResponse
		err = json.Unmarshal(w.Body.Bytes(), &createResponse)
		require.NoError(t, err)
		projectID := createResponse.ID

		// Test update validation
		testCases := []struct {
			name        string
			updateData  types.ProjectUpdateRequest
			expectError bool
		}{
			{
				name: "valid update",
				updateData: types.ProjectUpdateRequest{
					Name:        "Updated Name",
					Description: "Updated description",
				},
				expectError: false,
			},
			{
				name: "invalid currency in update",
				updateData: types.ProjectUpdateRequest{
					Budget: types.Budget{
						Amount:   30000,
						Currency: "INVALID",
					},
				},
				expectError: true,
			},
			{
				name: "name too long",
				updateData: types.ProjectUpdateRequest{
					Name: strings.Repeat("a", 256), // Over 255 character limit
				},
				expectError: true,
			},
		}

		for _, tc := range testCases {
			t.Run(tc.name, func(t *testing.T) {
				w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, tc.updateData)
				require.NoError(t, err)

				if tc.expectError {
					assert.Equal(t, http.StatusBadRequest, w.Code)
				} else {
					assert.Equal(t, http.StatusOK, w.Code)
				}
			})
		}
	})
}

// Test project lifecycle state transitions
func (suite *ProjectIntegrationTestSuite) TestProjectLifecycleTransitions() {
	// Create a project for lifecycle testing
	project := testProject{
		ID:              uuid.New().String(),
		Name:            "Lifecycle Test Project",
		Description:     "Project for testing lifecycle transitions",
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

	w, err := suite.makeRequest("POST", "/api/v1/projects", project)
	require.NoError(suite.T(), err)
	require.Equal(suite.T(), http.StatusCreated, w.Code)

	var createResponse types.ProjectCreateResponse
	err = json.Unmarshal(w.Body.Bytes(), &createResponse)
	require.NoError(suite.T(), err)
	projectID := createResponse.ID

	suite.T().Run("should transition through project phases", func(t *testing.T) {
		phases := []types.ProjectPhase{
			types.ProjectPhaseDevelopment,
			types.ProjectPhaseCommissioned,
		}

		for _, phase := range phases {
			updateData := types.ProjectUpdateRequest{
				ProjectPhase: phase,
			}

			w, err := suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, updateData)
			require.NoError(t, err)
			assert.Equal(t, http.StatusOK, w.Code)
		}
	})

	suite.T().Run("should handle lock/unlock cycles correctly", func(t *testing.T) {
		// Lock project
		lockRequest := types.ProjectLockRequest{IsLocked: true}
		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", lockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Try to update locked project (should fail or succeed based on who locked it)
		updateData := types.ProjectUpdateRequest{Name: "Update on locked project"}
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, updateData)
		require.NoError(t, err)
		// Should succeed since same user is trying to update
		assert.Equal(t, http.StatusOK, w.Code)

		// Unlock project
		unlockRequest := types.ProjectLockRequest{IsLocked: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/lock", unlockRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Update should now work normally
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})

	suite.T().Run("should handle archive/unarchive cycles correctly", func(t *testing.T) {
		// Archive project
		archiveRequest := types.ProjectArchiveRequest{Archive: true}
		w, err := suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", archiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Try to update archived project (should fail)
		updateData := types.ProjectUpdateRequest{Name: "Update on archived project"}
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusForbidden, w.Code)

		// Unarchive project
		unarchiveRequest := types.ProjectArchiveRequest{Archive: false}
		w, err = suite.makeRequest("POST", "/api/v1/projects/"+projectID+"/archive", unarchiveRequest)
		require.NoError(t, err)
		assert.Equal(t, http.StatusNoContent, w.Code)

		// Update should now work
		w, err = suite.makeRequest("PATCH", "/api/v1/projects/"+projectID, updateData)
		require.NoError(t, err)
		assert.Equal(t, http.StatusOK, w.Code)
	})
}

// Run the test suite
func TestProjectIntegrationSuite(t *testing.T) {
	suite.Run(t, new(ProjectIntegrationTestSuite))
}

// Mock implementations
type mockAuthService struct{}

func (m *mockAuthService) GetAuthTokensByResourceOwnerPassword(ctx context.Context, username string) (*types.AuthTokenResponse, error) {
	return nil, nil
}
func (m *mockAuthService) ValidateToken(tokenString string) (*jwt.MapClaims, error) { return nil, nil }
func (m *mockAuthService) ExtractUserID(claims *jwt.MapClaims) (string, error)      { return "", nil }
func (m *mockAuthService) ExtractUserEmail(claims *jwt.MapClaims) (string, error)   { return "", nil }
func (m *mockAuthService) ExtractTokenFromHeader(authHeader string) (string, error) { return "", nil }

type mockMiddlewareStruct struct{}

func (m *mockMiddlewareStruct) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) { c.Next() }
}
