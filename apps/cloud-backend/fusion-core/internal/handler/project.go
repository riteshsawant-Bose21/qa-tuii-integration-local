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

type ProjectSVC interface {
	CreateProject(ctx context.Context, project *fusion.ProjectCreateRequest) error
	GetAllProjects(ctx context.Context, queryParams *fusion.GetAllProjectsParams) ([]*fusion.Project, error)
	UpdateProject(ctx context.Context, id string, project *fusion.ProjectUpdateRequest) error
	DeleteProject(ctx context.Context, id string) error
}

func NewProjectHandler(projectSvc ProjectSVC) *ProjectHandler {
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
// @Param project body types.Project true "Project details"
// @Success 201 {object} types.Project "Successfully created project"
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [post]
func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	var p fusion.ProjectCreateRequest
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
// @Success 200 {array} types.Project "Successfully retrieved all projects"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /projects [get]
func (h *ProjectHandler) GetAllProjects(ctx *gin.Context) {

	params := fusion.GetAllProjectsParams{}
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

	projects, err := h.project.GetAllProjects(ctx, &params)
	if err != nil {
		ctx.JSON(500, gin.H{"error": err.Error()})
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
	var p fusion.ProjectUpdateRequest
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
