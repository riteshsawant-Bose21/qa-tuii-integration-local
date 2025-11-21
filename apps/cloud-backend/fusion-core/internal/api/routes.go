package api

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

// registerRoutes sets up the API routes.
func (a *API) registerRoutes() {
	v1 := a.engine.Group("/api/v1")

	// Swagger documentation route
	a.engine.GET("/docs/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Product routes
	productHandler := handler.NewProductHandler(a.product)
	products := v1.Group("/products")
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET("/:id", productHandler.GetProductByID)
		products.GET("/:id/prices", productHandler.GetProductPrices)
	}

	// TODO: Project routes temporarily disabled due to model conflicts
	// Project routes (only if project service is available)
	// if a.project != nil {
	// 	projectHandler := handler.NewProjectHandler(a.project)
	// 	projects := v1.Group("/projects")
	// 	{
	// 		projects.POST("", projectHandler.CreateProject)
	// 		projects.GET("/:id", projectHandler.GetProjectByID)
	// 		projects.GET("", projectHandler.GetAllProjects) // Optional: List all projects
	// 		projects.PATCH("/:id", projectHandler.UpdateProject)
	// 		projects.DELETE("/:id", projectHandler.DeleteProject)

	// 		projects.POST("/:id/sync", projectHandler.SyncProject) // New route for syncing a project
	// 	}
	// }
}
