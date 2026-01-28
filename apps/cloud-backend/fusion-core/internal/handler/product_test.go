package handler

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/config"
	errorspkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"go.uber.org/zap"
)

// MockProductService is a mock implementation of the Product interface
type MockProductService struct {
	mock.Mock
}

func (m *MockProductService) GetAllProducts(ctx context.Context, logger *zap.Logger) (*types.ProductResponse, error) {
	args := m.Called(ctx, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.ProductResponse), args.Error(1)
}

func (m *MockProductService) GetProductByID(ctx context.Context, id string, logger *zap.Logger) (*types.SingleProductResponse, error) {
	args := m.Called(ctx, id, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.SingleProductResponse), args.Error(1)
}

func (m *MockProductService) GetProductPrices(ctx context.Context, id string, currency string, variant string, logger *zap.Logger) (*types.PriceResponse, error) {
	args := m.Called(ctx, id, currency, variant, logger)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.PriceResponse), args.Error(1)
}

// Mock implementation for other Product interface methods
func (m *MockProductService) CreateJob(ctx context.Context, job *types.DBSyncJob) (string, error) {
	args := m.Called(ctx, job)
	return args.String(0), args.Error(1)
}

func (m *MockProductService) UpdateJobStatus(ctx context.Context, jobID string, status string, startedAt *time.Time, errorMsg *string) error {
	args := m.Called(ctx, jobID, status, startedAt, errorMsg)
	return args.Error(0)
}

func (m *MockProductService) UpdateStatusAndResults(ctx context.Context, jobID string, status string, totalItems, successful, failed int, validationWarnings []string, errorMsg *string) error {
	args := m.Called(ctx, jobID, status, totalItems, successful, failed, validationWarnings, errorMsg)
	return args.Error(0)
}

func (m *MockProductService) GetScheduledJobs(ctx context.Context) ([]types.SyncJobResult, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]types.SyncJobResult), args.Error(1)
}

func (m *MockProductService) GetJobResults(ctx context.Context, jobID string) (*types.SyncJobResult, error) {
	args := m.Called(ctx, jobID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.SyncJobResult), args.Error(1)
}

func (m *MockProductService) GetSyncHistory(ctx context.Context, limit int) ([]types.SyncJobResult, error) {
	args := m.Called(ctx, limit)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]types.SyncJobResult), args.Error(1)
}

func (m *MockProductService) Execute(ctx context.Context, request *types.SyncRequest) (*types.SyncResult, error) {
	args := m.Called(ctx, request)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.SyncResult), args.Error(1)
}

func (m *MockProductService) SyncProducts(ctx context.Context, jsonData []byte, jobID string, validationEnabled bool) (*types.SyncResult, error) {
	args := m.Called(ctx, jsonData, jobID, validationEnabled)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.SyncResult), args.Error(1)
}

func (m *MockProductService) SyncPrices(ctx context.Context, jsonData []byte, validation *config.Validation) (*types.SyncResult, error) {
	args := m.Called(ctx, jsonData, validation)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*types.SyncResult), args.Error(1)
}

const (
	testProductID       = "test-product-123"
	testCurrency        = "USD"
	testVariant         = "standard"
	productServiceError = "service error"
	internalServerMsg   = "Internal server error"
	productNotFoundMsg  = "Product not found"
	productIDRequired   = "Product ID is required"
	noPricesFoundMsg    = "No prices found for product"
)

// Helper function to create a test gin context with URL parameters
func createTestContext(method, url string, params map[string]string) (*gin.Context, *httptest.ResponseRecorder) {
	gin.SetMode(gin.TestMode)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)

	req, _ := http.NewRequest(method, url, nil)
	c.Request = req

	// Set URL parameters
	for key, value := range params {
		c.Params = append(c.Params, gin.Param{Key: key, Value: value})
	}

	// Add a logger to the context as expected by the handlers
	logger, _ := zap.NewDevelopment()
	c.Set("logger", logger)

	return c, w
}

func TestNewProductHandler(t *testing.T) {
	mockService := &MockProductService{}
	handler := NewProductHandler(mockService)

	assert.NotNil(t, handler)
	assert.Equal(t, mockService, handler.product)
}

func TestGetAllProducts(t *testing.T) {
	tests := []struct {
		name             string
		setupMock        func(*MockProductService)
		expectedStatus   int
		expectedError    string
		validateResponse func(*testing.T, *types.ProductResponse)
	}{
		{
			name: "successful retrieval of all products",
			setupMock: func(m *MockProductService) {
				expectedResponse := &types.ProductResponse{
					Version: "1.0",
					Speaker: []types.ProductItemResponse{
						{
							ProductID:          1,
							ModelName:          "Test Speaker",
							Description:        "A test speaker",
							IsFusionCompatible: true,
						},
					},
					Amplifier: []types.ProductItemResponse{
						{
							ProductID:          2,
							ModelName:          "Test Amplifier",
							Description:        "A test amplifier",
							IsFusionCompatible: true,
						},
					},
				}
				m.On("GetAllProducts", mock.Anything, mock.Anything).Return(expectedResponse, nil)
			},
			expectedStatus: http.StatusOK,
			validateResponse: func(t *testing.T, resp *types.ProductResponse) {
				assert.Equal(t, "1.0", resp.Version)
				assert.Len(t, resp.Speaker, 1)
				assert.Equal(t, "Test Speaker", resp.Speaker[0].ModelName)
				assert.Len(t, resp.Amplifier, 1)
				assert.Equal(t, "Test Amplifier", resp.Amplifier[0].ModelName)
			},
		},
		{
			name: "empty products response",
			setupMock: func(m *MockProductService) {
				expectedResponse := &types.ProductResponse{
					Version: "1.0",
				}
				m.On("GetAllProducts", mock.Anything, mock.Anything).Return(expectedResponse, nil)
			},
			expectedStatus: http.StatusOK,
			validateResponse: func(t *testing.T, resp *types.ProductResponse) {
				assert.Equal(t, "1.0", resp.Version)
				assert.Empty(t, resp.Speaker)
				assert.Empty(t, resp.Amplifier)
				assert.Empty(t, resp.Controller)
				assert.Empty(t, resp.DSP)
				assert.Empty(t, resp.Accessory)
				assert.Empty(t, resp.IOEndpoint)
			},
		},
		{
			name: "service returns error",
			setupMock: func(m *MockProductService) {
				m.On("GetAllProducts", mock.Anything, mock.Anything).Return(nil, errors.New(productServiceError))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedError:  productServiceError,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockProductService{}
			tt.setupMock(mockService)

			handler := NewProductHandler(mockService)
			c, w := createTestContext("GET", "/products", nil)

			handler.GetAllProducts(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedError != "" {
				var errorResp map[string]string
				err := json.Unmarshal(w.Body.Bytes(), &errorResp)
				assert.NoError(t, err)
				assert.Equal(t, tt.expectedError, errorResp["error"])
			} else if tt.validateResponse != nil {
				var response types.ProductResponse
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				tt.validateResponse(t, &response)
			}

			mockService.AssertExpectations(t)
		})
	}
}

func TestGetProductByID(t *testing.T) {
	tests := []struct {
		name             string
		productID        string
		setupMock        func(*MockProductService)
		expectedStatus   int
		expectedError    string
		validateResponse func(*testing.T, *types.SingleProductResponse)
	}{
		{
			name:      "successful retrieval of product by ID",
			productID: testProductID,
			setupMock: func(m *MockProductService) {
				expectedResponse := &types.SingleProductResponse{
					Version: "1.0",
					Speaker: &types.ProductItemResponse{
						ProductID:          123,
						ModelName:          "Test Speaker Model",
						ModelFamily:        "Premium",
						Description:        "High-quality test speaker",
						IsFusionCompatible: true,
					},
				}
				m.On("GetProductByID", mock.Anything, testProductID, mock.Anything).Return(expectedResponse, nil)
			},
			expectedStatus: http.StatusOK,
			validateResponse: func(t *testing.T, resp *types.SingleProductResponse) {
				assert.Equal(t, "1.0", resp.Version)
				assert.NotNil(t, resp.Speaker)
				assert.Equal(t, 123, resp.Speaker.ProductID)
				assert.Equal(t, "Test Speaker Model", resp.Speaker.ModelName)
				assert.Equal(t, "Premium", resp.Speaker.ModelFamily)
				assert.True(t, resp.Speaker.IsFusionCompatible)
			},
		},
		{
			name:      "successful retrieval of DSP product",
			productID: "dsp-456",
			setupMock: func(m *MockProductService) {
				expectedResponse := &types.SingleProductResponse{
					Version: "1.0",
					DSP: &types.ProductItemResponse{
						ProductID:          456,
						ModelName:          "Test DSP",
						Description:        "Digital Signal Processor",
						IsFusionCompatible: true,
					},
				}
				m.On("GetProductByID", mock.Anything, "dsp-456", mock.Anything).Return(expectedResponse, nil)
			},
			expectedStatus: http.StatusOK,
			validateResponse: func(t *testing.T, resp *types.SingleProductResponse) {
				assert.Equal(t, "1.0", resp.Version)
				assert.NotNil(t, resp.DSP)
				assert.Equal(t, 456, resp.DSP.ProductID)
				assert.Equal(t, "Test DSP", resp.DSP.ModelName)
			},
		},
		{
			name:           "empty product ID",
			productID:      "",
			setupMock:      func(m *MockProductService) {}, // No mock setup needed as handler returns early
			expectedStatus: http.StatusBadRequest,
			expectedError:  productIDRequired,
		},
		{
			name:      "product not found",
			productID: "non-existent-id",
			setupMock: func(m *MockProductService) {
				m.On("GetProductByID", mock.Anything, "non-existent-id", mock.Anything).Return(nil, errorspkg.ErrProductNotFound)
			},
			expectedStatus: http.StatusNotFound,
			expectedError:  productNotFoundMsg,
		},
		{
			name:      "service returns generic error",
			productID: testProductID,
			setupMock: func(m *MockProductService) {
				m.On("GetProductByID", mock.Anything, testProductID, mock.Anything).Return(nil, errors.New(productServiceError))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedError:  internalServerMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockProductService{}
			tt.setupMock(mockService)

			handler := NewProductHandler(mockService)

			params := map[string]string{}
			if tt.productID != "" {
				params["id"] = tt.productID
			}
			c, w := createTestContext("GET", "/products/"+tt.productID, params)

			handler.GetProductByID(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedError != "" {
				var errorResp map[string]string
				err := json.Unmarshal(w.Body.Bytes(), &errorResp)
				assert.NoError(t, err)
				assert.Equal(t, tt.expectedError, errorResp["error"])
			} else if tt.validateResponse != nil {
				var response types.SingleProductResponse
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				tt.validateResponse(t, &response)
			}

			mockService.AssertExpectations(t)
		})
	}
}

func TestGetProductPrices(t *testing.T) {
	tests := []struct {
		name             string
		productID        string
		currency         string
		variant          string
		setupMock        func(*MockProductService)
		expectedStatus   int
		expectedError    string
		validateResponse func(*testing.T, *types.PriceResponse)
	}{
		{
			name:      "successful retrieval of product prices with all parameters",
			productID: testProductID,
			currency:  testCurrency,
			variant:   testVariant,
			setupMock: func(m *MockProductService) {
				expectedResponse := &types.PriceResponse{
					Version:   "1.0",
					ProductID: 123,
					Prices: []types.PriceDetail{
						{
							Variant:  testVariant,
							Currency: testCurrency,
							Price:    999.99,
						},
					},
				}
				m.On("GetProductPrices", mock.Anything, testProductID, testCurrency, testVariant, mock.Anything).Return(expectedResponse, nil)
			},
			expectedStatus: http.StatusOK,
			validateResponse: func(t *testing.T, resp *types.PriceResponse) {
				assert.Equal(t, "1.0", resp.Version)
				assert.Equal(t, 123, resp.ProductID)
				assert.Len(t, resp.Prices, 1)
				assert.Equal(t, testVariant, resp.Prices[0].Variant)
				assert.Equal(t, testCurrency, resp.Prices[0].Currency)
				assert.Equal(t, 999.99, resp.Prices[0].Price)
			},
		},
		{
			name:      "successful retrieval without currency and variant filters",
			productID: testProductID,
			setupMock: func(m *MockProductService) {
				expectedResponse := &types.PriceResponse{
					Version:   "1.0",
					ProductID: 123,
					Prices: []types.PriceDetail{
						{
							Currency: "USD",
							Price:    999.99,
						},
						{
							Currency: "EUR",
							Price:    849.99,
						},
						{
							Currency: "GBP",
							Price:    799.99,
						},
					},
				}
				m.On("GetProductPrices", mock.Anything, testProductID, "", "", mock.Anything).Return(expectedResponse, nil)
			},
			expectedStatus: http.StatusOK,
			validateResponse: func(t *testing.T, resp *types.PriceResponse) {
				assert.Equal(t, "1.0", resp.Version)
				assert.Equal(t, 123, resp.ProductID)
				assert.Len(t, resp.Prices, 3)
				currencies := make([]string, len(resp.Prices))
				for i, price := range resp.Prices {
					currencies[i] = price.Currency
				}
				assert.Contains(t, currencies, "USD")
				assert.Contains(t, currencies, "EUR")
				assert.Contains(t, currencies, "GBP")
			},
		},
		{
			name:      "currency parameter is normalized to uppercase",
			productID: testProductID,
			currency:  "eur", // lowercase input
			setupMock: func(m *MockProductService) {
				expectedResponse := &types.PriceResponse{
					Version:   "1.0",
					ProductID: 123,
					Prices: []types.PriceDetail{
						{
							Currency: "EUR",
							Price:    849.99,
						},
					},
				}
				// Expect the service to be called with uppercase currency
				m.On("GetProductPrices", mock.Anything, testProductID, "EUR", "", mock.Anything).Return(expectedResponse, nil)
			},
			expectedStatus: http.StatusOK,
			validateResponse: func(t *testing.T, resp *types.PriceResponse) {
				assert.Equal(t, "EUR", resp.Prices[0].Currency)
			},
		},
		{
			name:           "empty product ID",
			productID:      "",
			setupMock:      func(m *MockProductService) {}, // No mock setup needed
			expectedStatus: http.StatusBadRequest,
			expectedError:  productIDRequired,
		},
		{
			name:      "product not found",
			productID: "non-existent-id",
			setupMock: func(m *MockProductService) {
				m.On("GetProductPrices", mock.Anything, "non-existent-id", "", "", mock.Anything).Return(nil, errorspkg.ErrProductNotFound)
			},
			expectedStatus: http.StatusNotFound,
			expectedError:  noPricesFoundMsg,
		},
		{
			name:      "no prices found for product",
			productID: testProductID,
			setupMock: func(m *MockProductService) {
				m.On("GetProductPrices", mock.Anything, testProductID, "", "", mock.Anything).Return(nil, errorspkg.ErrNoPricesFound)
			},
			expectedStatus: http.StatusNotFound,
			expectedError:  noPricesFoundMsg,
		},
		{
			name:      "service returns generic error",
			productID: testProductID,
			setupMock: func(m *MockProductService) {
				m.On("GetProductPrices", mock.Anything, testProductID, "", "", mock.Anything).Return(nil, errors.New(productServiceError))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedError:  internalServerMsg,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			mockService := &MockProductService{}
			tt.setupMock(mockService)

			handler := NewProductHandler(mockService)

			// Build URL with query parameters
			url := "/products/" + tt.productID + "/prices"
			if tt.currency != "" || tt.variant != "" {
				url += "?"
				if tt.currency != "" {
					url += "currency=" + tt.currency
				}
				if tt.variant != "" {
					if tt.currency != "" {
						url += "&"
					}
					url += "variant=" + tt.variant
				}
			}

			params := map[string]string{}
			if tt.productID != "" {
				params["id"] = tt.productID
			}
			c, w := createTestContext("GET", url, params)

			// Set query parameters manually since createTestContext doesn't handle them
			if tt.currency != "" {
				c.Request.URL.RawQuery = "currency=" + tt.currency
				if tt.variant != "" {
					c.Request.URL.RawQuery += "&variant=" + tt.variant
				}
			} else if tt.variant != "" {
				c.Request.URL.RawQuery = "variant=" + tt.variant
			}

			handler.GetProductPrices(c)

			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedError != "" {
				var errorResp map[string]string
				err := json.Unmarshal(w.Body.Bytes(), &errorResp)
				assert.NoError(t, err)
				assert.Equal(t, tt.expectedError, errorResp["error"])
			} else if tt.validateResponse != nil {
				var response types.PriceResponse
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)
				tt.validateResponse(t, &response)
			}

			mockService.AssertExpectations(t)
		})
	}
}

// TestGetProductPrices_EdgeCases tests edge cases and boundary conditions
func TestGetProductPrices_EdgeCases(t *testing.T) {
	t.Run("special characters in product ID", func(t *testing.T) {
		mockService := &MockProductService{}
		productID := "product-with-special-chars_123"

		expectedResponse := &types.PriceResponse{
			Version:   "1.0",
			ProductID: 123,
			Prices:    []types.PriceDetail{{Currency: "USD", Price: 100.0}},
		}

		mockService.On("GetProductPrices", mock.Anything, productID, "", "", mock.Anything).Return(expectedResponse, nil)

		handler := NewProductHandler(mockService)
		params := map[string]string{"id": productID}
		c, w := createTestContext("GET", "/products/"+productID+"/prices", params)

		handler.GetProductPrices(c)

		assert.Equal(t, http.StatusOK, w.Code)
		mockService.AssertExpectations(t)
	})

	t.Run("very long currency code", func(t *testing.T) {
		mockService := &MockProductService{}
		productID := testProductID
		longCurrency := "VERYLONGCURRENCYCODE"

		expectedResponse := &types.PriceResponse{
			Version:   "1.0",
			ProductID: 123,
			Prices:    []types.PriceDetail{{Currency: longCurrency, Price: 100.0}},
		}

		mockService.On("GetProductPrices", mock.Anything, productID, longCurrency, "", mock.Anything).Return(expectedResponse, nil)

		handler := NewProductHandler(mockService)
		params := map[string]string{"id": productID}
		c, w := createTestContext("GET", "/products/"+productID+"/prices?currency="+longCurrency, params)
		c.Request.URL.RawQuery = "currency=" + longCurrency

		handler.GetProductPrices(c)

		assert.Equal(t, http.StatusOK, w.Code)
		mockService.AssertExpectations(t)
	})
}

// TestProductHandler_Integration tests multiple methods together
func TestProductHandler_Integration(t *testing.T) {
	t.Run("workflow: get all products, then get specific product, then get its prices", func(t *testing.T) {
		mockService := &MockProductService{}
		handler := NewProductHandler(mockService)

		// Step 1: Get all products
		allProductsResp := &types.ProductResponse{
			Version: "1.0",
			Speaker: []types.ProductItemResponse{{ProductID: 123, ModelName: "Speaker 1"}},
		}
		mockService.On("GetAllProducts", mock.Anything, mock.Anything).Return(allProductsResp, nil)

		c1, w1 := createTestContext("GET", "/products", nil)
		handler.GetAllProducts(c1)
		assert.Equal(t, http.StatusOK, w1.Code)

		// Step 2: Get specific product
		singleProductResp := &types.SingleProductResponse{
			Version: "1.0",
			Speaker: &types.ProductItemResponse{ProductID: 123, ModelName: "Speaker 1"},
		}
		mockService.On("GetProductByID", mock.Anything, "123", mock.Anything).Return(singleProductResp, nil)

		c2, w2 := createTestContext("GET", "/products/123", map[string]string{"id": "123"})
		handler.GetProductByID(c2)
		assert.Equal(t, http.StatusOK, w2.Code)

		// Step 3: Get product prices
		priceResp := &types.PriceResponse{
			Version:   "1.0",
			ProductID: 123,
			Prices:    []types.PriceDetail{{Currency: "USD", Price: 999.99}},
		}
		mockService.On("GetProductPrices", mock.Anything, "123", "", "", mock.Anything).Return(priceResp, nil)

		c3, w3 := createTestContext("GET", "/products/123/prices", map[string]string{"id": "123"})
		handler.GetProductPrices(c3)
		assert.Equal(t, http.StatusOK, w3.Code)

		mockService.AssertExpectations(t)
	})
}
