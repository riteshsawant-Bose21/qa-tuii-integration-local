package handler

import (
	"context"
	"net/http"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/product"
	"github.com/gin-gonic/gin"
)

// ProductHandler handles HTTP requests related to products.
type ProductHandler struct {
	product product.Product
}

// NewProductHandler creates a new ProductHandler Service.
func NewProductHandler(productSvc product.Product) *ProductHandler {
	return &ProductHandler{product: productSvc}
}

// GetAllProducts retrieves all products.
// @Summary Get all products
// @Description Get all available products including speakers, amplifiers and digital signal processors
// @Tags products
// @Accept json
// @Produce json
// @Success 200 {object} fusion.ProductResponse "Successful response with all products"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /products [get]
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
// @Success 200 {object} fusion.ProductResponse "Successful response with product details"
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
		if product == nil {
			c.JSON(http.StatusNotFound, gin.H{"error": "Product not found"})
			return
		}
	}
	c.JSON(http.StatusOK, product)
}
