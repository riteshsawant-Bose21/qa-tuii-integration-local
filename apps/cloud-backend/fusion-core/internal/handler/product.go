package handler

import (
	"context"
	"errors"
	"net/http"
	"strings"

	_ "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	errorspkg "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/errors"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"
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
//	@Failure		500	{object}	map[string]string																								"Internal server error"
//	@Router			/products [get]
func (a *ProductHandler) GetAllProducts(c *gin.Context) {
	products, err := a.product.GetAllProducts(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, products)
}

// GetProductByID retrieves a product by its ID.
// @Summary Get product by ID
// @Description Get a specific product by its unique identifier
// @Tags products
// @Accept json
// @Produce json
// @Param id path string true "Product ID"
// @Success 200 {object} types.ProductResponse "Successful response with product details"
// @Failure 400 {object} map[string]string "Bad request - Product ID is required"
// @Failure 404 {object} map[string]string "Product not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /products/{id} [get]
func (a *ProductHandler) GetProductByID(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Product ID is required"})
		return
	}

	product, err := a.product.GetProductByID(context.TODO(), id)
	if err != nil {
		if errors.Is(err, errorspkg.ErrProductNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	c.JSON(http.StatusOK, product)
}

// GetProductPrices retrieves prices for a product by its ID, optionally filtered by currency/country.
//
//	@Summary		Get product prices by ID
//	@Description	Get prices for a specific product by its unique identifier, optionally filtered by currency
//	@Tags			products
//	@Accept			json
//	@Produce		json
//	@Param			id			path		string																										true	"Product ID"
//	@Param			currency	query		string																										false	"Currency code (e.g., USD, EUR) to filter prices"
//	@Success		200			{object}	types.PriceResponse	"Successful response with product prices"
//	@Failure		400			{object}	map[string]string																							"Bad request - Product ID is required"
//	@Failure		404			{object}	map[string]string																							"Product not found"
//	@Failure		500			{object}	map[string]string																							"Internal server error"
//	@Router			/products/{id}/prices [get]
func (a *ProductHandler) GetProductPrices(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Product ID is required"})
		return
	}

	currency := c.Query("currency") // Optional currency parameter
	variant := c.Query("variant")   // Optional variant parameter

	// Convert currency to uppercase for standardization (USD, EUR, GBP, etc.)
	if currency != "" {
		currency = strings.ToUpper(currency)
	}

	prices, err := a.product.GetProductPrices(context.TODO(), id, currency, variant)
	if err != nil {
		if errors.Is(err, errorspkg.ErrProductNotFound) || errors.Is(err, errorspkg.ErrNoPricesFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "No prices found for product"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}

	c.JSON(http.StatusOK, prices)
}
