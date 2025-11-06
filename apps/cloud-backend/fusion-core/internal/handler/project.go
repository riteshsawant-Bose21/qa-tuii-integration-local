package handler

import (
	"net/http"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/validation"
	"github.com/gin-gonic/gin"
)

const (
	projectNotFoundMsg     = "project not found"
	userNotFoundMsg        = "user not found"
	internalServerErr      = "Internal server error"
	sqlNoRowsErr           = "sql: no rows in result set"
	userAlreadyAssignedMsg = "user is already assigned to the project"
	userNotAssignedMsg     = "user not assigned to the project"
)

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
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload"
// @Failure 401 {object} types.UnauthorizedError "Unauthorized to perform this action"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects [post]
func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	var p types.ProjectCreateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	response, err := h.project.CreateProject(ctx, &p)

	if err != nil {
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: err.Error()})
		return
	}

	ctx.JSON(http.StatusCreated, response)
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
// @Failure 401 {object} types.UnauthorizedError "Unauthorized do perform this action"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects [get]
func (h *ProjectHandler) GetAllProjects(ctx *gin.Context) {

	params := types.GetAllProjectsParams{}
	if err := ctx.ShouldBindQuery(&params); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	if params.SortBy == "" {
		params.SortBy = "updated_at"
	} else if params.SortBy != "created_at" && params.SortBy != "updated_at" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: "Invalid sort_by parameter"})
		return
	}

	if params.SortOrder == "" {
		params.SortOrder = "desc"
	} else if params.SortOrder != "asc" && params.SortOrder != "desc" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: "Invalid sort_order parameter"})
		return
	}

	response, err := h.project.GetAllProjects(ctx, &params)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: err.Error()})
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
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectUpdateRequest true "Updated project details"
// @Success 200 {object} types.ProjectUpdateResponse "Successfully created project"
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload"
// @Failure 401 {object} types.UnauthorizedError "Unauthorized to perform this action"
// @Failure 404 {object} types.NotFoundError "Project not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId} [patch]
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	id := ctx.Param("projectId")
	var p types.ProjectUpdateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	response, err := h.project.UpdateProject(ctx, id, &p)
	if err != nil {
		// Check if it's a "not found" error
		if err.Error() == projectNotFoundMsg || err.Error() == sqlNoRowsErr {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: internalServerErr})
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
// @Failure 401 {object} types.UnauthorizedError "Unauthorized to perform this action"
// @Failure 404 {object} types.NotFoundError "Project not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId} [delete]
func (h *ProjectHandler) DeleteProject(ctx *gin.Context) {
	id := ctx.Param("projectId")
	if err := h.project.DeleteProject(ctx, id); err != nil {
		// Check if it's a "not found" error
		if err.Error() == projectNotFoundMsg || err.Error() == sqlNoRowsErr {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: "Project not found"})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: internalServerErr})
		return
	}
	ctx.JSON(204, nil)
}

// AssignUserToProject assigns a user to a project.
// @Summary Assign a user to a project
// @Description Assign a user to a project by project ID and user email
// @Tags projects
// @Accept json
// @Produce json
// @Param projectId path string true "Project ID"
// @Param userEmail path string true "User Email"
// @Success 204 "User successfully assigned to the project"
// @Failure 404 {object} types.NotFoundError "Project or User not found"
// @Failure 409 {object} types.ConflictError "User is already assigned to the project"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/users/{userEmail} [put]
func (h *ProjectHandler) AssignUserToProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userEmail := ctx.Param("userEmail")

	_, err := h.project.AssignUserToProjectByEmail(ctx, projectID, userEmail)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == projectNotFoundMsg || errorMsg == userNotFoundMsg {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		if errorMsg == userAlreadyAssignedMsg {
			ctx.JSON(http.StatusConflict, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: internalServerErr})
		return
	}

	ctx.JSON(http.StatusNoContent, nil)
}

// RemoveUserFromProject removes a user from a project.
// @Summary Remove a user from a project
// @Description Remove a user from a project by project ID and user email
// @Tags projects
// @Accept json
// @Produce json
// @Param projectId path string true "Project ID"
// @Param userEmail path string true "User Email"
// @Success 204 "User successfully removed from the project"
// @Failure 404 {object} types.NotFoundError "Project or User not found, or user not assigned to the project"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/users/{userEmail} [delete]
func (h *ProjectHandler) RemoveUserFromProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userEmail := ctx.Param("userEmail")

	_, err := h.project.RemoveUserFromProjectByEmail(ctx, projectID, userEmail)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == projectNotFoundMsg || errorMsg == userNotFoundMsg || errorMsg == userNotAssignedMsg {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: internalServerErr})
		return
	}

	ctx.JSON(http.StatusNoContent, nil)
}
