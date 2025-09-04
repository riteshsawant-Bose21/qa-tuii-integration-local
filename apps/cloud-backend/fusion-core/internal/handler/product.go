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
func (a *ProductHandler) GetAllProducts(c *gin.Context) {
	products, err := a.product.GetAllProducts(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, products)
}

// GetProductByID retrieves a product by its ID.
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
