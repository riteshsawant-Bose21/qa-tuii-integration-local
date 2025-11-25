package api

import "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler"

// registerRoutes sets up the API routes.
func (a *API) registerRoutes() {
	v1 := a.engine.Group("/api/v1")

	// Product routes
	productHandler := handler.NewProductHandler(a.product)
	products := v1.Group("/products")
	{
		products.GET("", productHandler.GetAllProducts)
		products.GET("/:id", productHandler.GetProductByID)
		products.GET("/:id/prices", productHandler.GetProductPrices)
	}

	// Project routes
	projectHandler := handler.NewProjectHandler(a.project)
	projects := v1.Group("/projects")
	{
		projects.POST("", projectHandler.CreateProject)
		projects.GET("", projectHandler.GetAllProjects)
		projects.PATCH("/:projectId", projectHandler.UpdateProject)
		projects.DELETE("/:projectId", projectHandler.DeleteProject)
		projects.PUT("/:projectId/users/:userEmail", projectHandler.AssignUserToProject)
		projects.DELETE("/:projectId/users/:userEmail", projectHandler.RemoveUserFromProject)
		projects.POST("/:projectId/star/:userId", projectHandler.UpdateProjectStar)
		projects.POST("/:projectId/archive", projectHandler.UpdateProjectArchive)
		projects.POST("/:projectId/lock", projectHandler.UpdateProjectLock)
	}
}
