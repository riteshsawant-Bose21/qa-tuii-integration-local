package handler

import (
	"context"
	"errors"
	"net/http"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	errorspkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/http"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// ProductHandler handles HTTP requests related to products.
type ProductHandler struct {
	product fusion.Product
}

// NewProductHandler creates a new ProductHandler Service.
func NewProductHandler(productSvc fusion.Product) *ProductHandler {
	return &ProductHandler{product: productSvc}
}

// GetAllProducts retrieves all products.
//
//	@Summary		Get all products
//	@Description	Get all available products including speakers, amplifiers, DSPs, controllers, and endpoints
//	@Tags			products
//	@Accept			json
//	@Produce		json
//	@Success		200	{object}	types.ProductResponse	"Successful response with all products"
//	@Failure		500	{object}	types.ErrorResponse "Internal server error"
//	@Router			/products [get]
func (a *ProductHandler) GetAllProducts(c *gin.Context) {
	loggerFromContext, exists := c.Get("logger")
	if !exists {
		response.InternalError(c)
		return
	}
	logger := loggerFromContext.(*zap.Logger)
	logger = logger.With(zap.String("handler", "GetAllProducts"))
	products, err := a.product.GetAllProducts(c.Request.Context(), logger)
	if err != nil {
		response.SendJSON(c, http.StatusInternalServerError, types.ErrorResponse{ErrorMessage: err.Error()})
		return
	}
	response.OK(c, products)
}

// GetProductByID retrieves a product by its ID.
//
//	@Summary		Get product by ID
//	@Description	Get a specific product by its unique identifier
//	@Tags			products
//	@Accept			json
//	@Produce		json
//	@Param			id	path		string	true	"Product ID"
//	@Success		200	{object}	types.SingleProductResponse	"Successful response with product details"
//	@Failure		400 {object} 	types.ErrorResponse "Bad request - Product ID is required"
//	@Failure		404	{object}	types.ErrorResponse "Product not found"
//	@Failure		500	{object}	types.ErrorResponse "Internal server error"
//	@Router			/products/{id} [get]
func (a *ProductHandler) GetProductByID(c *gin.Context) {
	loggerFromContext, exists := c.Get("logger")
	if !exists {
		response.InternalError(c)
		return
	}
	logger := loggerFromContext.(*zap.Logger)
	logger = logger.With(zap.String("handler", "GetProductByID"))
	id := c.Param("id")
	if id == "" {
		response.BadRequest(c, "Product ID is required")
		return
	}

	product, err := a.product.GetProductByID(context.TODO(), id, logger)
	if err != nil {
		if errors.Is(err, errorspkg.ErrProductNotFound) {
			response.NotFound(c, "Product not found")
			return
		}
		response.InternalError(c)
		return
	}
	response.OK(c, product)
}

// GetProductPrices retrieves prices for a product by its ID, optionally filtered by currency/country.
//
//	@Summary		Get product prices by ID
//	@Description	Get prices for a specific product by its unique identifier, optionally filtered by currency
//	@Tags			products
//	@Accept			json
//	@Produce		json
//	@Param			id			path		string	true	"Product ID"
//	@Param			currency	query		string	false	"Currency code (e.g., USD, EUR) to filter prices"
//	@Param			variant		query		string	false	"Product variant to filter prices"
//	@Success		200			{object}	types.PriceResponse	"Successful response with product prices"
//	@Failure		400			{object}	types.ErrorResponse "Bad request - Product ID is required"
//	@Failure		404			{object}	types.ErrorResponse "Product not found"
//	@Failure		500			{object}	types.ErrorResponse "Internal server error"
//	@Router			/products/{id}/prices [get]
func (a *ProductHandler) GetProductPrices(c *gin.Context) {
	loggerFromContext, exists := c.Get("logger")
	if !exists {
		response.InternalError(c)
		return
	}
	logger := loggerFromContext.(*zap.Logger)
	logger = logger.With(zap.String("handler", "GetProductPrices"))

	id := c.Param("id")
	if id == "" {
		response.BadRequest(c, "Product ID is required")
		return
	}

	currency := c.Query("currency") // Optional currency parameter
	variant := c.Query("variant")   // Optional variant parameter

	// Convert currency to uppercase for standardization (USD, EUR, GBP, etc.)
	if currency != "" {
		currency = strings.ToUpper(currency)
	}

	prices, err := a.product.GetProductPrices(context.TODO(), id, currency, variant, logger)
	if err != nil {
		if errors.Is(err, errorspkg.ErrProductNotFound) || errors.Is(err, errorspkg.ErrNoPricesFound) {
			response.NotFound(c, "No prices found for product")
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, prices)
}
