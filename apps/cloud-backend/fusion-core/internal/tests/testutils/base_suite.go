// Package testutils provides shared test infrastructure for integration tests.
package testutils

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"sync"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	cloudIot "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/iot"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/storage/cloudfs"
	sqlpkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/cloud/storage/sql"
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
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
	"go.uber.org/zap"
)

// Test configuration constants.
const (
	testAWSRegion = "us-east-1"
)

// BaseIntegrationSuite provides shared infrastructure for all integration test suites.
// Embed this in your module-specific test suite to get PostgreSQL container,
// database connection, and service initialization automatically.
type BaseIntegrationSuite struct {
	suite.Suite
	Ctx               context.Context
	PostgresContainer *postgres.PostgresContainer
	DB                *sql.DB
	GinRouter         *gin.Engine
	API               *api.API
	RouterMutex       sync.Mutex

	// Services available to all tests
	ProductSVC *product.Service
	ProjectSVC *project.Service
	UserSVC    *user.Service
	DeviceSVC  *device.Service
	Loggers    *log.Loggers
	ZapLogger  *zap.Logger

	// Test data
	TestUsers []TestUser
}

// SetupSuite initializes the PostgreSQL container, database, and all services.
// Call this from your module's SetupSuite method.
func (suite *BaseIntegrationSuite) SetupSuite() {
	suite.Ctx = context.Background()
	gin.SetMode(gin.TestMode)

	// Start PostgreSQL container
	postgresContainer, err := postgres.Run(suite.Ctx,
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
	suite.PostgresContainer = postgresContainer

	// Get database connection details
	host, err := postgresContainer.Host(suite.Ctx)
	require.NoError(suite.T(), err)

	mappedPort, err := postgresContainer.MappedPort(suite.Ctx, "5432")
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
	suite.DB = pgs

	// Run database migrations
	err = suite.runMigrations()
	require.NoError(suite.T(), err)

	// Initialize test data
	suite.initTestData()

	// Setup services
	err = suite.setupServices()
	require.NoError(suite.T(), err)
}

// TearDownSuite cleans up resources after all tests complete.
func (suite *BaseIntegrationSuite) TearDownSuite() {
	if suite.PostgresContainer != nil {
		err := suite.PostgresContainer.Terminate(suite.Ctx)
		require.NoError(suite.T(), err)
	}
}

// runMigrations executes database schema and test data SQL files.
func (suite *BaseIntegrationSuite) runMigrations() error {
	// Read and execute schema migration
	schemaSQL, err := os.ReadFile("../../../migration/fusion_cloud.sql")
	if err != nil {
		return fmt.Errorf("failed to read schema migration: %w", err)
	}

	_, err = suite.DB.Exec(string(schemaSQL))
	if err != nil {
		return fmt.Errorf("failed to execute schema migration: %w", err)
	}

	// Read and execute test data migration
	testDataSQL, err := os.ReadFile("../../../migration/test_data.sql")
	if err != nil {
		return fmt.Errorf("failed to read test data migration: %w", err)
	}

	_, err = suite.DB.Exec(string(testDataSQL))
	if err != nil {
		return fmt.Errorf("failed to execute test data migration: %w", err)
	}

	// Add additional test data for price sync jobs
	priceSyncJobSQL := `
		INSERT INTO product_sync_job (sync_operation, status, sync_type, s3_bucket, s3_key, file_size_bytes, total_items, successful_items, failed_items, version, started_at, completed_at)
		VALUES ('full_sync', 'completed', 'price', 'fusion-product-import', 'imports/2024/01/price_catalog.json', 262144, 50, 50, 0, 'v1', '2024-01-11 10:00:00', '2024-01-11 10:01:00')
		ON CONFLICT DO NOTHING;
	`
	_, err = suite.DB.Exec(priceSyncJobSQL)
	if err != nil {
		return fmt.Errorf("failed to insert price sync job test data: %w", err)
	}

	return nil
}

// initTestData initializes test users and other common test data.
func (suite *BaseIntegrationSuite) initTestData() {
	suite.TestUsers = []TestUser{
		{ID: "60000001-0000-4000-8000-000000000001", Email: "admin@bose.com"},
		{ID: "60000001-0000-4000-8000-000000000006", Email: "test@domain.com"},
		{ID: "60000001-0000-4000-8000-000000000007", Email: "prof.operator@university.edu"},
		{ID: "60000001-0000-4000-8000-000000000008", Email: "emily.service@eventproductions.com"},
	}
}

// setupServices initializes all application services for testing.
func (suite *BaseIntegrationSuite) setupServices() error {
	// Create loggers for tests
	zapLogger, err := zap.NewDevelopment()
	require.NoError(suite.T(), err, "Failed to create zap logger")
	suite.ZapLogger = zapLogger

	// Initialize dual loggers with test configuration
	loggerConfig := log.DefaultLoggerConfig()
	loggerConfig.Mode = "debug"
	loggerConfig.LogDir = "/tmp/fusion-test-logs"
	loggers, err := log.NewLoggers(loggerConfig)
	require.NoError(suite.T(), err, "Failed to create dual loggers")
	suite.Loggers = loggers

	// Initialize ID service
	idSVC := id.NewService()
	require.NotNil(suite.T(), idSVC, "Failed to initialize ID service")

	// Initialize Product services
	productDBSvc := productdb.NewService(suite.DB, loggers.AppLogger)
	require.NotNil(suite.T(), productDBSvc, "Failed to initialize product database service")

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

	s3Client, err := cloudfs.NewS3Client(context.Background(), testAWSRegion)
	require.NoError(suite.T(), err, "Failed to create S3 client for testing")

	suite.ProductSVC = product.NewService(productDBSvc, "v1", validationCfg, processingCfg, s3Client, loggers.AppLogger)
	require.NotNil(suite.T(), suite.ProductSVC, "Failed to initialize product service")

	// Initialize Project services
	projectDBSvc := projectdb.NewService(suite.DB)
	require.NotNil(suite.T(), projectDBSvc, "Failed to initialize project database service")

	suite.ProjectSVC = project.NewService(projectDBSvc, nil)
	require.NotNil(suite.T(), suite.ProjectSVC, "Failed to initialize project service")

	// Initialize User services
	userDBSvc := userdb.NewService(suite.DB)
	require.NotNil(suite.T(), userDBSvc, "Failed to initialize user database service")

	suite.UserSVC = user.NewService(userDBSvc)
	require.NotNil(suite.T(), suite.UserSVC, "Failed to initialize user service")

	// Initialize test cloud configuration
	cloudCfg := config.CloudConfig{
		PriceS3Bucket:   "test-price-bucket",
		ProductS3Bucket: "test-product-bucket",
		ProjectS3Bucket: "test-project-bucket",
		Region:          testAWSRegion,
		IoTEndpoint:     "test-iot-endpoint.iot." + testAWSRegion + ".amazonaws.com",
		IoTCommandTopic: "test/commands",
	}

	// Initialize IoT handler for device service
	iotHandler, err := cloudIot.NewIoTClient(context.Background(), testAWSRegion, cloudCfg.IoTEndpoint, loggers.AppLogger)
	require.NoError(suite.T(), err, "Failed to initialize IoT client")

	// Initialize Device services
	deviceDBSvc := devicedb.NewService(suite.DB)
	require.NotNil(suite.T(), deviceDBSvc, "Failed to initialize device database service")

	suite.DeviceSVC = device.NewService(deviceDBSvc, projectDBSvc, iotHandler, cloudCfg)
	require.NotNil(suite.T(), suite.DeviceSVC, "Failed to initialize device service")

	// Initialize API server
	apiConfig := &api.Config{
		Mode: "test",
		Host: "localhost",
		Port: "0",
	}

	authSvc := &MockAuthService{}
	authMiddleware := &MockMiddleware{}

	apiServer, err := api.New(apiConfig, suite.ProductSVC, suite.ProjectSVC, suite.UserSVC, authSvc, authMiddleware, suite.DeviceSVC, loggers)
	if err != nil {
		return fmt.Errorf("failed to initialize API server: %w", err)
	}
	suite.API = apiServer

	return nil
}

// MakeRequest makes an HTTP request to the test router without user context.
func (suite *BaseIntegrationSuite) MakeRequest(method, path string, body interface{}) (*httptest.ResponseRecorder, error) {
	return suite.MakeRequestWithUser(method, path, body, "")
}

// MakeRequestWithUser makes an HTTP request with the specified user ID.
func (suite *BaseIntegrationSuite) MakeRequestWithUser(method, path string, body interface{}, userID string) (*httptest.ResponseRecorder, error) {
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

	// Set user context headers
	if userID != "" {
		req.Header.Set("X-User-ID", userID)
	} else if len(suite.TestUsers) > 0 {
		req.Header.Set("X-User-ID", suite.TestUsers[0].ID)
	}

	w := httptest.NewRecorder()

	suite.RouterMutex.Lock()
	suite.GinRouter.ServeHTTP(w, req)
	suite.RouterMutex.Unlock()

	return w, nil
}

// MakeRequestWithHeaders makes an HTTP request with custom headers.
func (suite *BaseIntegrationSuite) MakeRequestWithHeaders(method, path string, body interface{}, headers map[string]string) (*httptest.ResponseRecorder, error) {
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

	for key, value := range headers {
		req.Header.Set(key, value)
	}

	w := httptest.NewRecorder()

	suite.RouterMutex.Lock()
	suite.GinRouter.ServeHTTP(w, req)
	suite.RouterMutex.Unlock()

	return w, nil
}

// FindUserEmailByID returns the email for a given user ID.
func (suite *BaseIntegrationSuite) FindUserEmailByID(userID string) string {
	for _, testUser := range suite.TestUsers {
		if testUser.ID == userID {
			return testUser.Email
		}
	}
	return ""
}

// GetDefaultUserID returns the first test user's ID.
func (suite *BaseIntegrationSuite) GetDefaultUserID() string {
	if len(suite.TestUsers) > 0 {
		return suite.TestUsers[0].ID
	}
	return ""
}

// GetDefaultUserEmail returns the first test user's email.
func (suite *BaseIntegrationSuite) GetDefaultUserEmail() string {
	if len(suite.TestUsers) > 0 {
		return suite.TestUsers[0].Email
	}
	return ""
}
