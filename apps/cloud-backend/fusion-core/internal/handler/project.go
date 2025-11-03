package handler

import (
	"net/http"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/validation"
	"github.com/gin-gonic/gin"
)

const ()

// ProjectHandler handles HTTP requests for project management.
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
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload or user not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects [post]
func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	var p types.ProjectCreateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}
	if err := h.project.CreateProject(ctx, &p); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
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
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid query parameters"
// @Failure 500 {object} types.InternalServerError "Internal server error"
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

	projects, err := h.project.GetAllProjects(ctx, &params)
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
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectUpdateRequest true "Updated project details"
// @Success 200 {object} types.ProjectUpdateResponse "Successfully updated project"
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project, project archived, or locked by another user"
// @Failure 404 {object} types.NotFoundError "Project or user not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId} [patch]
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	id := ctx.Param("id")
	var p types.ProjectUpdateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}

	// TODO: Remove when auth is implemented
	if !validation.IsValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	var p types.ProjectUpdateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	// Validate request
	if err := validation.ValidateProjectUpdateRequest(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	// Use authenticated update method which includes all validations
	response, err := h.project.UpdateProject(ctx, projectID, userID, &p)
	if err != nil {
		// Check if it's a "not found" error
		if err.Error() == types.ErrMsgProjectNotFound || err.Error() == types.ErrMsgSqlNoRows {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: err.Error()})
			return
		}

		if err.Error() == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusUnauthorized, types.ErrorResponse{Message: err.Error()})
		}

		// Check if it's authorization errors
		if err.Error() == types.ErrMsgUserNotAssignedToProject ||
			err.Error() == types.ErrMsgProjectArchived ||
			strings.Contains(err.Error(), types.ErrMsgProjectLockedByUser) {
			ctx.JSON(http.StatusForbidden, types.ErrorResponse{Message: err.Error()})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}
	ctx.JSON(http.StatusOK, response)
}

// DeleteProject deletes a project by ID.
// @Summary Delete project
// @Description Delete a project by its unique identifier
// @Tags projects
// @Accept json
// @Produce json
// @Param projectId path string true "Project ID"
// @Success 204 "Successfully deleted project"
// @Failure 400 {object} types.BadRequestError "Bad request - Missing user ID"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project, project archived, or locked by another user"
// @Failure 404 {object} types.NotFoundError "Project or user not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId} [delete]
func (h *ProjectHandler) DeleteProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Query("user_id")

	if userID == "" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserIdRequired})
		return
	}

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !validation.IsValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	if err := h.project.DeleteProject(ctx, projectID, userID); err != nil {
		// Check if it's a "not found" error
		if err.Error() == types.ErrMsgProjectNotFound || err.Error() == types.ErrMsgSqlNoRows {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: err.Error()})
			return
		}

		// Check if it's authorization errors
		if err.Error() == types.ErrMsgUserNotAssignedToProject ||
			err.Error() == types.ErrMsgUserNotFound ||
			err.Error() == types.ErrMsgProjectArchived ||
			strings.Contains(err.Error(), types.ErrMsgProjectLockedByUser) {
			ctx.JSON(http.StatusForbidden, types.ErrorResponse{Message: err.Error()})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}
	ctx.JSON(204, nil)
}
