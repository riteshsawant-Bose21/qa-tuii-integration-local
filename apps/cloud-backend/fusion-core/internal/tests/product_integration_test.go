package tests

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/id"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	productdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	projectdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user"
	userdb "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/user/db"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	sqlpkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/storage/sql"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"
	"go.uber.org/zap"
)

// ProductIntegrationTestSuite defines the test suite structure for product integration tests
type ProductIntegrationTestSuite struct {
	suite.Suite
	ctx               context.Context
	postgresContainer *postgres.PostgresContainer
	db                *sql.DB
	ginRouter         *gin.Engine
	api               *api.API
}

// testProduct represents the expected product data for testing
type testProduct struct {
	ProductID        int    `json:"productid"`
	ProductType      string `json:"product_type"`
	ModelName        string `json:"model_name"`
	ModelFamily      string `json:"model_family"`
	Description      string `json:"description"`
	ShortDesc        string `json:"short_description"`
	ExpectedPrice    float64
	ExpectedCurrency string
	ExpectedVariant  string
}

// SetupSuite runs once before all tests in the suite
func (suite *ProductIntegrationTestSuite) SetupSuite() {
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

	// Setup API server
	err = suite.setupAPI()
	require.NoError(suite.T(), err)
}

// TearDownSuite runs once after all tests in the suite
func (suite *ProductIntegrationTestSuite) TearDownSuite() {
	if suite.postgresContainer != nil {
		err := suite.postgresContainer.Terminate(suite.ctx)
		require.NoError(suite.T(), err)
	}
}

// runMigrations runs the database schema migration and populates with test data
func (suite *ProductIntegrationTestSuite) runMigrations() error {
	// Read and execute schema migration
	schemaSQL, err := os.ReadFile("../../migration/fusion_cloud.sql")
	if err != nil {
		return fmt.Errorf("failed to read schema migration: %w", err)
	}

	_, err = suite.db.Exec(string(schemaSQL))
	if err != nil {
		return fmt.Errorf("failed to execute schema migration: %w", err)
	}

	// Read and execute test data migration (includes test products)
	testDataSQL, err := os.ReadFile("../../migration/test_data.sql")
	if err != nil {
		return fmt.Errorf("failed to read test data migration: %w", err)
	}

	_, err = suite.db.Exec(string(testDataSQL))
	if err != nil {
		return fmt.Errorf("failed to execute test data migration: %w", err)
	}

	// Add additional test data for price sync jobs (to fix version handling in price endpoints)
	priceSyncJobSQL := `
		INSERT INTO product_sync_job (sync_operation, status, sync_type, s3_bucket, s3_key, file_size_bytes, total_items, successful_items, failed_items, version, started_at, completed_at)
		VALUES ('full_sync', 'completed', 'price', 'fusion-product-import', 'imports/2024/01/price_catalog.json', 262144, 50, 50, 0, 'v1', '2024-01-11 10:00:00', '2024-01-11 10:01:00');
	`
	_, err = suite.db.Exec(priceSyncJobSQL)
	if err != nil {
		return fmt.Errorf("failed to insert price sync job test data: %w", err)
	}

	return nil
}

// setupAPI initializes the API server with all necessary services
func (suite *ProductIntegrationTestSuite) setupAPI() error {
	// Set Gin to test mode
	gin.SetMode(gin.TestMode)

	// Create loggers for tests
	zapLogger, err := zap.NewDevelopment()
	require.NoError(suite.T(), err, "Failed to create zap logger")

	// Initialize services
	idSVC := id.NewService()
	require.NotNil(suite.T(), idSVC, "Failed to initialize ID service")

	// Initialize Product services
	productDBSvc := productdb.NewService(suite.db, zapLogger)
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

	productSVC := product.NewService(productDBSvc, "v1", validationCfg, processingCfg, zapLogger)
	require.NotNil(suite.T(), productSVC, "Failed to initialize product service")

	// Initialize Project services (required for API but not used in product tests)
	projectDBSvc := projectdb.NewService(suite.db)
	require.NotNil(suite.T(), projectDBSvc, "Failed to initialize project database service")

	projectSVC := project.NewService(projectDBSvc, nil)
	require.NotNil(suite.T(), projectSVC, "Failed to initialize project service")

	// Initialize User services (required for API but not used in product tests)
	userDBSvc := userdb.NewService(suite.db)
	require.NotNil(suite.T(), userDBSvc, "Failed to initialize user database service")

	userSVC := user.NewService(userDBSvc)
	require.NotNil(suite.T(), userSVC, "Failed to initialize user service")

	// Initialize dual loggers with test configuration
	loggerConfig := log.DefaultLoggerConfig()
	loggerConfig.Mode = "debug"
	loggerConfig.LogDir = "/tmp/fusion-test-logs" // Use temp directory for tests
	loggers, err := log.NewLoggers(loggerConfig)
	require.NoError(suite.T(), err, "Failed to create dual loggers")

	// Initialize API server (for completeness, though we use test router)
	apiConfig := &api.Config{
		Mode:        "test",
		Host:        "localhost",
		Port:        "0",                     // Use ephemeral port for testing
		Auth0Domain: "test-domain.auth0.com", // Mock Auth0 domain for testing
	}

	apiServer, err := api.New(apiConfig, productSVC, projectSVC, userSVC, loggers)
	if err != nil {
		return fmt.Errorf("failed to initialize API server: %w", err)
	}
	suite.api = apiServer

	// Create a test router without auth middleware for product testing
	suite.ginRouter = suite.createTestRouter(productSVC)

	return nil
}

// createTestRouter creates a Gin router with handlers but mocked authentication for testing
func (suite *ProductIntegrationTestSuite) createTestRouter(productSVC *product.Service) *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	// Add middleware for testing
	router.Use(gin.Recovery())

	// Add logger middleware to provide logger in gin context
	router.Use(func(c *gin.Context) {
		logger, _ := zap.NewDevelopment()
		c.Set("logger", logger)
		c.Next()
	})

	// Setup routes
	suite.setupRoutes(router, productSVC)

	return router
}

// setupRoutes sets up the product routes for testing
func (suite *ProductIntegrationTestSuite) setupRoutes(router *gin.Engine, productSVC *product.Service) {
	productHandler := handler.NewProductHandler(productSVC)

	api := router.Group("/api/v1")
	products := api.Group("/products")
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET("/:id", productHandler.GetProductByID)
		products.GET("/:id/prices", productHandler.GetProductPrices)
	}
}

// Helper method to make HTTP requests to the API
func (suite *ProductIntegrationTestSuite) makeRequest(method, path string, body interface{}) (*httptest.ResponseRecorder, error) {
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

	rec := httptest.NewRecorder()
	suite.ginRouter.ServeHTTP(rec, req)

	return rec, nil
}

// getTestProducts returns the test products that should be available in the test database
func (suite *ProductIntegrationTestSuite) getTestProducts() []testProduct {
	return []testProduct{
		{
			ProductID:        1001,
			ProductType:      "speaker",
			ModelName:        "DM2SE",
			ModelFamily:      "DesignMax",
			Description:      "Surface-mount loudspeaker",
			ExpectedPrice:    299.99,
			ExpectedCurrency: "USD",
			ExpectedVariant:  "black",
		},
		{
			ProductID:        1002,
			ProductType:      "amplifier",
			ModelName:        "PWR4X100",
			ModelFamily:      "PowerSeries",
			Description:      "4-channel digital amplifier",
			ExpectedPrice:    1299.99,
			ExpectedCurrency: "USD",
			ExpectedVariant:  "standard",
		},
	}
}

// TestGetAllProducts tests the GET /api/v1/products endpoint
func (suite *ProductIntegrationTestSuite) TestGetAllProducts() {
	// Make request to get all products
	resp, err := suite.makeRequest("GET", "/api/v1/products", nil)
	require.NoError(suite.T(), err)

	// Check status code
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	// Parse response
	var productResponse types.ProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &productResponse)
	require.NoError(suite.T(), err)

	// Verify response structure
	assert.Equal(suite.T(), "v1", productResponse.Version)

	// Verify we have the expected test products
	testProducts := suite.getTestProducts()

	// Check for speaker product
	speakerFound := false
	for _, speaker := range productResponse.Speaker {
		if speaker.ProductID == testProducts[0].ProductID {
			speakerFound = true
			assert.Equal(suite.T(), testProducts[0].ModelName, speaker.ModelName)
			assert.Equal(suite.T(), testProducts[0].ModelFamily, speaker.ModelFamily)
			assert.Equal(suite.T(), testProducts[0].Description, speaker.Description)
			// IsFusionCompatible might be false in test data
			assert.False(suite.T(), speaker.IsFusionCompatible)
			break
		}
	}
	assert.True(suite.T(), speakerFound, "Expected speaker product not found in response")

	// Check for amplifier product
	amplifierFound := false
	for _, amplifier := range productResponse.Amplifier {
		if amplifier.ProductID == testProducts[1].ProductID {
			amplifierFound = true
			assert.Equal(suite.T(), testProducts[1].ModelName, amplifier.ModelName)
			assert.Equal(suite.T(), testProducts[1].ModelFamily, amplifier.ModelFamily)
			assert.Equal(suite.T(), testProducts[1].Description, amplifier.Description)
			// IsFusionCompatible might be false in test data
			assert.False(suite.T(), amplifier.IsFusionCompatible)
			break
		}
	}
	assert.True(suite.T(), amplifierFound, "Expected amplifier product not found in response")
}

// TestGetProductByID tests the GET /api/v1/products/{id} endpoint
func (suite *ProductIntegrationTestSuite) TestGetProductByID() {
	testProducts := suite.getTestProducts()

	// Test getting speaker product by ID
	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.makeRequest("GET", "/api/v1/products/"+speakerID, nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var speakerResponse types.SingleProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &speakerResponse)
	require.NoError(suite.T(), err)

	// Verify speaker response
	assert.Equal(suite.T(), "v1", speakerResponse.Version)
	assert.NotNil(suite.T(), speakerResponse.Speaker)
	assert.Nil(suite.T(), speakerResponse.Amplifier)
	assert.Equal(suite.T(), testProducts[0].ProductID, speakerResponse.Speaker.ProductID)
	assert.Equal(suite.T(), testProducts[0].ModelName, speakerResponse.Speaker.ModelName)

	// Test getting amplifier product by ID
	amplifierID := strconv.Itoa(testProducts[1].ProductID)
	resp, err = suite.makeRequest("GET", "/api/v1/products/"+amplifierID, nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var amplifierResponse types.SingleProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &amplifierResponse)
	require.NoError(suite.T(), err)

	// Verify amplifier response
	assert.Equal(suite.T(), "v1", amplifierResponse.Version)
	assert.NotNil(suite.T(), amplifierResponse.Amplifier)
	assert.Nil(suite.T(), amplifierResponse.Speaker)
	assert.Equal(suite.T(), testProducts[1].ProductID, amplifierResponse.Amplifier.ProductID)
	assert.Equal(suite.T(), testProducts[1].ModelName, amplifierResponse.Amplifier.ModelName)
}

// TestGetProductByID_NotFound tests the GET /api/v1/products/{id} endpoint with non-existent ID
func (suite *ProductIntegrationTestSuite) TestGetProductByID_NotFound() {
	// Test with non-existent product ID
	resp, err := suite.makeRequest("GET", "/api/v1/products/99999", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusNotFound, resp.Code)

	var errorResponse map[string]interface{}
	err = json.Unmarshal(resp.Body.Bytes(), &errorResponse)
	require.NoError(suite.T(), err)
	assert.Contains(suite.T(), errorResponse["error"], "Product not found")
}

// TestGetProductByID_BadRequest tests the GET /api/v1/products/{id} endpoint with invalid ID
func (suite *ProductIntegrationTestSuite) TestGetProductByID_BadRequest() {
	// Test with invalid ID format (non-numeric)
	// The handler will try to convert "invalid" to an integer, which should cause an error
	resp, err := suite.makeRequest("GET", "/api/v1/products/invalid", nil)
	require.NoError(suite.T(), err)
	// The conversion error typically results in a 500 internal server error in this implementation
	assert.Equal(suite.T(), http.StatusInternalServerError, resp.Code)
}

// TestGetProductPrices tests the GET /api/v1/products/{id}/prices endpoint
func (suite *ProductIntegrationTestSuite) TestGetProductPrices() {
	testProducts := suite.getTestProducts()

	// Test getting prices for speaker product
	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.makeRequest("GET", "/api/v1/products/"+speakerID+"/prices", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var priceResponse types.PriceResponse
	err = json.Unmarshal(resp.Body.Bytes(), &priceResponse)
	require.NoError(suite.T(), err)

	// Verify price response structure
	assert.Equal(suite.T(), "v1", priceResponse.Version)
	assert.Equal(suite.T(), testProducts[0].ProductID, priceResponse.ProductID)
	assert.NotEmpty(suite.T(), priceResponse.Prices)

	// Verify price details
	priceFound := false
	for _, price := range priceResponse.Prices {
		if price.Currency == testProducts[0].ExpectedCurrency {
			priceFound = true
			assert.Equal(suite.T(), testProducts[0].ExpectedPrice, price.Price)
			assert.Equal(suite.T(), testProducts[0].ExpectedVariant, price.Variant)
			break
		}
	}
	assert.True(suite.T(), priceFound, "Expected price not found in response")
}

// TestGetProductPrices_WithCurrencyFilter tests the GET /api/v1/products/{id}/prices endpoint with currency filter
func (suite *ProductIntegrationTestSuite) TestGetProductPrices_WithCurrencyFilter() {
	testProducts := suite.getTestProducts()

	// Test getting prices with USD currency filter
	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.makeRequest("GET", "/api/v1/products/"+speakerID+"/prices?currency=usd", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var priceResponse types.PriceResponse
	err = json.Unmarshal(resp.Body.Bytes(), &priceResponse)
	require.NoError(suite.T(), err)

	// Verify all returned prices are in USD
	for _, price := range priceResponse.Prices {
		assert.Equal(suite.T(), "USD", price.Currency)
	}

	// Test with non-existent currency (should return empty prices)
	resp, err = suite.makeRequest("GET", "/api/v1/products/"+speakerID+"/prices?currency=EUR", nil)
	require.NoError(suite.T(), err)
	// Should return 404 for no prices found
	assert.Equal(suite.T(), http.StatusNotFound, resp.Code)
}

// TestGetProductPrices_WithVariantFilter tests the GET /api/v1/products/{id}/prices endpoint with variant filter
func (suite *ProductIntegrationTestSuite) TestGetProductPrices_WithVariantFilter() {
	testProducts := suite.getTestProducts()

	// Test getting prices with specific variant filter
	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.makeRequest("GET", "/api/v1/products/"+speakerID+"/prices?variant=black", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var priceResponse types.PriceResponse
	err = json.Unmarshal(resp.Body.Bytes(), &priceResponse)
	require.NoError(suite.T(), err)

	// Verify all returned prices are for the black variant
	for _, price := range priceResponse.Prices {
		assert.Equal(suite.T(), "black", price.Variant)
	}
}

// TestGetProductPrices_NotFound tests the GET /api/v1/products/{id}/prices endpoint with non-existent product
func (suite *ProductIntegrationTestSuite) TestGetProductPrices_NotFound() {
	// Test with non-existent product ID
	resp, err := suite.makeRequest("GET", "/api/v1/products/99999/prices", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusNotFound, resp.Code)

	var errorResponse map[string]interface{}
	err = json.Unmarshal(resp.Body.Bytes(), &errorResponse)
	require.NoError(suite.T(), err)
	assert.Contains(suite.T(), errorResponse["error"], "No prices found for product")
}

// TestProductEndpointsWithRealDatabase tests the integration with the actual database operations
func (suite *ProductIntegrationTestSuite) TestProductEndpointsWithRealDatabase() {
	// Verify that test data is properly seeded
	var productCount int
	err := suite.db.QueryRow("SELECT COUNT(*) FROM product").Scan(&productCount)
	require.NoError(suite.T(), err)
	assert.GreaterOrEqual(suite.T(), productCount, 2, "Expected at least 2 test products in database")

	var priceCount int
	err = suite.db.QueryRow("SELECT COUNT(*) FROM product_price").Scan(&priceCount)
	require.NoError(suite.T(), err)
	assert.GreaterOrEqual(suite.T(), priceCount, 2, "Expected at least 2 test prices in database")

	// Test that the API correctly reads from the database
	resp, err := suite.makeRequest("GET", "/api/v1/products", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var productResponse types.ProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &productResponse)
	require.NoError(suite.T(), err)

	// Count total products returned by API
	totalProducts := len(productResponse.Speaker) + len(productResponse.Amplifier) +
		len(productResponse.DSP) + len(productResponse.Controller) +
		len(productResponse.Accessory) + len(productResponse.IOEndpoint)

	assert.GreaterOrEqual(suite.T(), totalProducts, 2, "Expected at least 2 products from API response")
}

// TestProductIntegrationSuite runs the complete test suite
func TestProductIntegrationSuite(t *testing.T) {
	suite.Run(t, new(ProductIntegrationTestSuite))
}
