package handler

import (
	"net/http"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"
)

// ProjectHandler handles HTTP requests for project management.
type ProjectHandler struct {
	project fusion.Project
}

func NewProjectHandler(projectSvc fusion.Project) *ProjectHandler {
	return &ProjectHandler{
		project: projectSvc,
	}
}

// CreateProject creates a new project.
// @Summary Create a new project
// @Description Create a new project in the system
// @Tags projects
// @Accept json
// @Produce json
// @Param project body types.Project true "Project details"
// @Success 201 {object} types.Project "Successfully created project"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [post]
func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	var p types.Project
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.CreateProject(ctx, &p); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusCreated, p)
}

// GetProject retrieves a project by ID.
// @Summary Get project by ID
// @Description Get a specific project by its unique identifier
// @Tags projects
// @Accept json
// @Produce json
// @Param id path string true "Project ID"
// @Success 200 {object} types.Project "Successfully retrieved project"
// @Failure 404 {object} map[string]string "Project not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects/{id} [get]
func (h *ProjectHandler) GetProjectByID(ctx *gin.Context) {
	id := ctx.Param("id")
	project, err := h.project.GetProjectByID(ctx, id)
	if err != nil {
		// Check if it's a "not found" error
		if err.Error() == "project not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, project)
}

// GetProjects retrieves all projects.
// @Summary Get all projects
// @Description Get all projects in the system
// @Tags projects
// @Accept json
// @Produce json
// @Success 200 {array} types.Project "Successfully retrieved all projects"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [get]
func (h *ProjectHandler) GetAllProjects(ctx *gin.Context) {
	projects, err := h.project.GetAllProjects(ctx)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, projects)
}

// UpdateProject updates an existing project.
// @Summary Update project
// @Description Update an existing project by its ID
// @Tags projects
// @Accept json
// @Produce json
// @Param id path string true "Project ID"
// @Param project body types.Project true "Updated project details"
// @Success 200 {object} types.Project "Successfully updated project"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 404 {object} map[string]string "Project not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects/{id} [patch]
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	id := ctx.Param("id")
	var p types.Project
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.UpdateProject(ctx, id, &p); err != nil {
		// Check if it's a "not found" error
		if err.Error() == "project not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, p)
}

// DeleteProject deletes a project by ID.
// @Summary Delete project
// @Description Delete a project by its unique identifier
// @Tags projects
// @Accept json
// @Produce json
// @Param id path string true "Project ID"
// @Success 204 "Successfully deleted project"
// @Failure 404 {object} map[string]string "Project not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects/{id} [delete]
func (h *ProjectHandler) DeleteProject(ctx *gin.Context) {
	id := ctx.Param("id")
	if err := h.project.DeleteProject(ctx, id); err != nil {
		// Check if it's a "not found" error
		if err.Error() == "project not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(http.StatusNoContent, nil)
}

// SyncProject triggers synchronization for a project by ID.
// @Summary Sync project
// @Description Synchronize project data with external source using metadata and ZIP file URL
// @Tags projects
// @Accept json
// @Produce json
// @Param id path string true "Project ID"
// @Param syncRequest body SyncProjectRequest true "Sync request containing metadata and ZIP file URL"
// @Success 200 {object} map[string]string "Successfully initiated project sync"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 404 {object} map[string]string "Project not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects/{id}/sync [post]
func (h *ProjectHandler) SyncProject(ctx *gin.Context) {
	id := ctx.Param("id")
	var req types.SyncProjectRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.SyncProject(ctx, id, req.MetaData, req.ZipFileURL); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Project sync initiated"})
}
