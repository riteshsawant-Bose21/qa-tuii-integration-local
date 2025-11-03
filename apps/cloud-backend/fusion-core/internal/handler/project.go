package handler

import (
	"net/http"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project"
	"github.com/gin-gonic/gin"
)

type ProjectHandler struct {
	project fusion.Project
}

func NewProjectHandler(project fusion.Project) *ProjectHandler {
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
// @Param body body types.ProjectCreateRequest true "Project details"
// @Success 201 {object} types.ProjectCreateResponse "Successfully created project"
// @Failure 400 {object} map[string]string "Bad request - Invalid payload"
// @Failure 401 {object} map[string]string "Unauthorized to perform this action"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [post]
func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	var p types.ProjectCreateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := h.project.Insert(ctx, &p); err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusCreated, p)
}

// GetProjects retrieves all projects.
// @Summary Get all projects
// @Description Get all projects in the system
// @Tags projects
// @Accept json
// @Produce json
// @Param is_archived query bool false "Filter projects by archived status"
// @Param sort_by query string false "Field to sort projects by (e.g., created_at, updated_at)"
// @Param sort_order query string false "Sort order (ascending or descending)" Enums(asc, desc)
// @Success 200 {object} types.GetAllProjectsResponse "Successfully retrieved all projects"
// @Failure 400 {object} map[string]string "Bad request - Invalid query parameters"
// @Failure 401 {object} map[string]string "Unauthorized do perform this action"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [get]
func (h *ProjectHandler) GetAllProjects(ctx *gin.Context) {

	params := types.GetAllProjectsParams{}
	if err := ctx.ShouldBindQuery(&params); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if params.SortBy == "" {
		params.SortBy = "updated_at"
	} else if params.SortBy != "created_at" && params.SortBy != "updated_at" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid sort_by parameter"})
		return
	}

	if params.SortOrder == "" {
		params.SortOrder = "desc"
	} else if params.SortOrder != "asc" && params.SortOrder != "desc" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid sort_order parameter"})
		return
	}

	response, err := h.project.GetAllProjects(ctx, &params)
	if err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, response)
}

// UpdateProject updates an existing project.
// @Summary Update project
// @Description Update an existing project by its ID
// @Tags projects
// @Accept json
// @Produce json
// @Param id path string true "Project ID"
// @Param body body types.ProjectUpdateRequest true "Updated project details"
// @Success 200 {object} types.ProjectUpdateResponse "Successfully created project"
// @Failure 400 {object} map[string]string "Bad request - Invalid payload"
// @Failure 401 {object} map[string]string "Unauthorized to perform this action"
// @Failure 404 {object} map[string]string "Project not found"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects/{id} [patch]
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	id := ctx.Param("id")
	var p types.ProjectUpdateRequest
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
// @Failure 401 {object} map[string]string "Unauthorized to perform this action"
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
