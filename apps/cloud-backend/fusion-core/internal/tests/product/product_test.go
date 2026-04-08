// Package product provides integration tests for product endpoints.
package product

import (
	"encoding/json"
	"net/http"
	"strconv"
	"testing"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/tests/testutils"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// ProductIntegrationTestSuite defines the test suite for product integration tests.
type ProductIntegrationTestSuite struct {
	testutils.BaseIntegrationSuite
}

// SetupSuite runs once before all tests in the suite.
func (suite *ProductIntegrationTestSuite) SetupSuite() {
	suite.BaseIntegrationSuite.SetupSuite()
	suite.setupRouter()
}

// setupRouter configures the Gin router with product routes.
func (suite *ProductIntegrationTestSuite) setupRouter() {
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(testutils.CreateSimpleLoggerMiddleware(suite.ZapLogger))

	productHandler := handler.NewProductHandler(suite.ProductSVC)

	api := router.Group("/api/v1")
	products := api.Group("/products")
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET("/:id", productHandler.GetProductByID)
		products.GET("/:id/prices", productHandler.GetProductPrices)
	}

	suite.GinRouter = router
}

// TestGetAllProducts tests the GET /api/v1/products endpoint.
func (suite *ProductIntegrationTestSuite) TestGetAllProducts() {
	resp, err := suite.MakeRequest("GET", "/api/v1/products", nil)
	require.NoError(suite.T(), err)

	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var productResponse types.ProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &productResponse)
	require.NoError(suite.T(), err)

	assert.Equal(suite.T(), "v1", productResponse.Version)

	testProducts := testutils.GetDefaultTestProducts()

	// Check for speaker product
	speakerFound := false
	for _, speaker := range productResponse.Speaker {
		if speaker.ProductID == testProducts[0].ProductID {
			speakerFound = true
			assert.Equal(suite.T(), testProducts[0].ModelName, speaker.ModelName)
			assert.Equal(suite.T(), testProducts[0].ModelFamily, speaker.ModelFamily)
			assert.Equal(suite.T(), testProducts[0].Description, speaker.Description)
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
			break
		}
	}
	assert.True(suite.T(), amplifierFound, "Expected amplifier product not found in response")
}

// TestGetProductByID tests the GET /api/v1/products/{id} endpoint.
func (suite *ProductIntegrationTestSuite) TestGetProductByID() {
	testProducts := testutils.GetDefaultTestProducts()

	// Test getting speaker product by ID
	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.MakeRequest("GET", "/api/v1/products/"+speakerID, nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var speakerResponse types.SingleProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &speakerResponse)
	require.NoError(suite.T(), err)

	assert.Equal(suite.T(), "v1", speakerResponse.Version)
	assert.NotNil(suite.T(), speakerResponse.Speaker)
	assert.Nil(suite.T(), speakerResponse.Amplifier)
	assert.Equal(suite.T(), testProducts[0].ProductID, speakerResponse.Speaker.ProductID)
	assert.Equal(suite.T(), testProducts[0].ModelName, speakerResponse.Speaker.ModelName)

	// Test getting amplifier product by ID
	amplifierID := strconv.Itoa(testProducts[1].ProductID)
	resp, err = suite.MakeRequest("GET", "/api/v1/products/"+amplifierID, nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var amplifierResponse types.SingleProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &amplifierResponse)
	require.NoError(suite.T(), err)

	assert.Equal(suite.T(), "v1", amplifierResponse.Version)
	assert.NotNil(suite.T(), amplifierResponse.Amplifier)
	assert.Nil(suite.T(), amplifierResponse.Speaker)
	assert.Equal(suite.T(), testProducts[1].ProductID, amplifierResponse.Amplifier.ProductID)
	assert.Equal(suite.T(), testProducts[1].ModelName, amplifierResponse.Amplifier.ModelName)
}

// TestGetProductByID_NotFound tests the GET /api/v1/products/{id} endpoint with non-existent ID.
func (suite *ProductIntegrationTestSuite) TestGetProductByID_NotFound() {
	resp, err := suite.MakeRequest("GET", "/api/v1/products/99999", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusNotFound, resp.Code)

	var errorResponse map[string]interface{}
	err = json.Unmarshal(resp.Body.Bytes(), &errorResponse)
	require.NoError(suite.T(), err)
	assert.Contains(suite.T(), errorResponse["error"], "Product not found")
}

// TestGetProductByID_InvalidID tests the GET /api/v1/products/{id} endpoint with invalid ID.
func (suite *ProductIntegrationTestSuite) TestGetProductByID_InvalidID() {
	resp, err := suite.MakeRequest("GET", "/api/v1/products/invalid", nil)
	require.NoError(suite.T(), err)
	// Invalid ID format results in internal server error
	assert.Equal(suite.T(), http.StatusInternalServerError, resp.Code)
}

// TestGetProductPrices tests the GET /api/v1/products/{id}/prices endpoint.
func (suite *ProductIntegrationTestSuite) TestGetProductPrices() {
	testProducts := testutils.GetDefaultTestProducts()

	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.MakeRequest("GET", "/api/v1/products/"+speakerID+"/prices", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var priceResponse types.PriceResponse
	err = json.Unmarshal(resp.Body.Bytes(), &priceResponse)
	require.NoError(suite.T(), err)

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

// TestGetProductPrices_WithCurrencyFilter tests the GET /api/v1/products/{id}/prices endpoint with currency filter.
func (suite *ProductIntegrationTestSuite) TestGetProductPrices_WithCurrencyFilter() {
	testProducts := testutils.GetDefaultTestProducts()

	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.MakeRequest("GET", "/api/v1/products/"+speakerID+"/prices?currency=usd", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var priceResponse types.PriceResponse
	err = json.Unmarshal(resp.Body.Bytes(), &priceResponse)
	require.NoError(suite.T(), err)

	for _, price := range priceResponse.Prices {
		assert.Equal(suite.T(), "USD", price.Currency)
	}

	// Test with non-existent currency
	resp, err = suite.MakeRequest("GET", "/api/v1/products/"+speakerID+"/prices?currency=EUR", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusNotFound, resp.Code)
}

// TestGetProductPrices_WithVariantFilter tests the GET /api/v1/products/{id}/prices endpoint with variant filter.
func (suite *ProductIntegrationTestSuite) TestGetProductPrices_WithVariantFilter() {
	testProducts := testutils.GetDefaultTestProducts()

	speakerID := strconv.Itoa(testProducts[0].ProductID)
	resp, err := suite.MakeRequest("GET", "/api/v1/products/"+speakerID+"/prices?variant=black", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var priceResponse types.PriceResponse
	err = json.Unmarshal(resp.Body.Bytes(), &priceResponse)
	require.NoError(suite.T(), err)

	for _, price := range priceResponse.Prices {
		assert.Equal(suite.T(), "black", price.Variant)
	}
}

// TestGetProductPrices_NotFound tests the GET /api/v1/products/{id}/prices endpoint with non-existent product.
func (suite *ProductIntegrationTestSuite) TestGetProductPrices_NotFound() {
	resp, err := suite.MakeRequest("GET", "/api/v1/products/99999/prices", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusNotFound, resp.Code)

	var errorResponse map[string]interface{}
	err = json.Unmarshal(resp.Body.Bytes(), &errorResponse)
	require.NoError(suite.T(), err)
	assert.Contains(suite.T(), errorResponse["error"], "No prices found for product")
}

// TestProductEndpointsWithRealDatabase verifies data is properly seeded.
func (suite *ProductIntegrationTestSuite) TestProductEndpointsWithRealDatabase() {
	// Verify test data is seeded
	var productCount int
	err := suite.DB.QueryRow("SELECT COUNT(*) FROM product").Scan(&productCount)
	require.NoError(suite.T(), err)
	assert.GreaterOrEqual(suite.T(), productCount, 2, "Expected at least 2 test products in database")

	var priceCount int
	err = suite.DB.QueryRow("SELECT COUNT(*) FROM product_price").Scan(&priceCount)
	require.NoError(suite.T(), err)
	assert.GreaterOrEqual(suite.T(), priceCount, 2, "Expected at least 2 test prices in database")

	// Test API reads from database
	resp, err := suite.MakeRequest("GET", "/api/v1/products", nil)
	require.NoError(suite.T(), err)
	assert.Equal(suite.T(), http.StatusOK, resp.Code)

	var productResponse types.ProductResponse
	err = json.Unmarshal(resp.Body.Bytes(), &productResponse)
	require.NoError(suite.T(), err)

	totalProducts := len(productResponse.Speaker) + len(productResponse.Amplifier) +
		len(productResponse.DSP) + len(productResponse.Controller) +
		len(productResponse.Accessory) + len(productResponse.IOEndpoint)

	assert.GreaterOrEqual(suite.T(), totalProducts, 2, "Expected at least 2 products from API response")
}

// TestProductIntegrationSuite runs the complete test suite.
func TestProductIntegrationSuite(t *testing.T) {
	suite.Run(t, new(ProductIntegrationTestSuite))
}
