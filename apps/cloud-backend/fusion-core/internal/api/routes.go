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
		projects.PUT("/:projectId/star/:userId", projectHandler.StarProject)
		projects.DELETE("/:projectId/star/:userId", projectHandler.UnstarProject)
		projects.PUT("/:projectId/archive", projectHandler.ArchiveProject)
		projects.DELETE("/:projectId/archive", projectHandler.UnarchiveProject)
	}
}
