package api

import "github.com/BoseProfessional/fusion-monorepo/apps/backend/fusion-cloud-backend/internal/handler"

func (a *API) registerRoutes() {
	v1 := a.engine.Group("/api/v1")

	// Product routes
	productHandler := handler.NewProductHandler(a.product)
	products := v1.Group("/products")
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET("/:id", productHandler.GetProductByID)
	}
}
