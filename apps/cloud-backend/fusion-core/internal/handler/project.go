package handler

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	"github.com/gin-gonic/gin"
)

type ProjectHandler struct {
	project project.Project
}

func NewProjectHandler(project project.Project) *ProjectHandler {
	return &ProjectHandler{
		project: project,
	}
}

// CreateProject creates a new project.
// @Summary Create a new project
// @Description Create a new project in the system
// @Tags projects
// @Accept json
// @Produce json
// @Param project body fusion.Project true "Project details"
// @Success 201 {object} fusion.Project "Successfully created project"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [post]
func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	var p fusion.Project
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.Insert(ctx, &p); err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(201, p)
}

// GetProject retrieves a project by ID.
// @Summary Get project by ID
// @Description Get a specific project by its unique identifier
// @Tags projects
// @Accept json
// @Produce json
// @Param id path string true "Project ID"
// @Success 200 {object} fusion.Project "Successfully retrieved project"
// @Failure 404 {object} map[string]string "Project not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects/{id} [get]
func (h *ProjectHandler) GetProject(ctx *gin.Context) {
	id := ctx.Param("id")
	project, err := h.project.GetByID(ctx, id)
	if err != nil {
		// Check if it's a "not found" error
		if err.Error() == "project not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(404, gin.H{"error": "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(500, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(200, project)
}

// GetProjects retrieves all projects.
// @Summary Get all projects
// @Description Get all projects in the system
// @Tags projects
// @Accept json
// @Produce json
// @Success 200 {array} fusion.Project "Successfully retrieved all projects"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [get]
func (h *ProjectHandler) GetProjects(ctx *gin.Context) {
	projects, err := h.project.GetAll(ctx)
	if err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(200, projects)
}

// UpdateProject updates an existing project.
// @Summary Update project
// @Description Update an existing project by its ID
// @Tags projects
// @Accept json
// @Produce json
// @Param id path string true "Project ID"
// @Param project body fusion.Project true "Updated project details"
// @Success 200 {object} fusion.Project "Successfully updated project"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 404 {object} map[string]string "Project not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects/{id} [patch]
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	id := ctx.Param("id")
	var p fusion.Project
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.Update(ctx, id, &p); err != nil {
		// Check if it's a "not found" error
		if err.Error() == "project not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(404, gin.H{"error": "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(500, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(200, p)
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
	if err := h.project.Delete(ctx, id); err != nil {
		// Check if it's a "not found" error
		if err.Error() == "project not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(404, gin.H{"error": "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(500, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(204, nil)
}

// SyncProjectRequest represents the request body for project synchronization.
type SyncProjectRequest struct {
	MetaData   map[string]interface{} `json:"meta_data" example:"{\"version\": \"1.0\", \"updated_by\": \"user123\"}" validate:"required"`
	ZipFileURL string                 `json:"zip_file_url" example:"https://example.com/project.zip" validate:"required,url"`
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
	var req SyncProjectRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.SyncProject(ctx, id, req.MetaData, req.ZipFileURL); err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(200, gin.H{"message": "Project sync initiated"})
}
