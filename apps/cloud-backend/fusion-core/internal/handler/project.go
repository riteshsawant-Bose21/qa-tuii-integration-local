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

	// Validate request
	if err := validation.ValidateProjectCreateRequest(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	response, err := h.project.CreateProject(ctx, &p)

	if err != nil {
		// Internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
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
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects [get]
func (h *ProjectHandler) GetAllProjects(ctx *gin.Context) {

	params := types.GetAllProjectsParams{}
	if err := ctx.ShouldBindQuery(&params); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	// Validate query parameters
	if err := validation.ValidateGetAllProjectsParams(&params); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	userID := ctx.Query("user_id")

	if userID == "" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserIdRequired})
		return
	}

	if !validation.IsValidUUID(userID) {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	if params.SortBy == "" {
		params.SortBy = "updated_at"
	}

	if params.SortOrder == "" {
		params.SortOrder = "desc"
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
// @Success 200 {object} types.ProjectUpdateResponse "Successfully updated project"
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project, project archived, or locked by another user"
// @Failure 404 {object} types.NotFoundError "Project or user not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId} [patch]
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")

	// TODO: Remove when auth is implemented
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
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/users/{userEmail} [put]
func (h *ProjectHandler) AssignUserToProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userEmail := strings.TrimSpace(ctx.Param("userEmail"))

	// Validate projectID UUID
	if !validation.IsValidUUID(projectID) {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: "Invalid project ID format"})
		return
	}

	_, err := h.project.AssignUserToProjectByEmail(ctx, projectID, userEmail)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
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
	userEmail := strings.TrimSpace(ctx.Param("userEmail"))

	// Validate projectID UUID
	if !validation.IsValidUUID(projectID) {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: "Invalid project ID format"})
		return
	}

	_, err := h.project.RemoveUserFromProjectByEmail(ctx, projectID, userEmail)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		if errorMsg == types.ErrMsgUserNotAssignedToProject {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}

	ctx.JSON(http.StatusNoContent, nil)
}

// UpdateProjectStar updates the star status of a project for a user.
// @Summary Update project star status
// @Description Star or unstar a project for a specific user based on request body
// @Tags projects
// @Accept json
// @Produce json
// @Param projectId path string true "Project ID"
// @Param userId path string true "User ID"
// @Param body body types.ProjectStarRequest true "Star/unstar request"
// @Success 204 "Successfully updated project star status"
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project, project archived, or locked by another user"
// @Failure 404 {object} types.NotFoundError "Project or User not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/star/{userId} [post]
func (h *ProjectHandler) UpdateProjectStar(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Param("userId")

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !validation.IsValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	var req types.ProjectStarRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	// Validate request
	if err := validation.ValidateProjectStarRequest(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	var err error
	if req.IsStarred {
		err = h.project.StarProject(ctx, projectID, userID)
	} else {
		err = h.project.UnstarProject(ctx, projectID, userID)
	}

	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		if errorMsg == types.ErrMsgUserNotAssignedToProject {
			ctx.JSON(http.StatusForbidden, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}

	ctx.JSON(http.StatusNoContent, nil)
}

// UpdateProjectArchive updates the archive status of a project.
// @Summary Update project archive status
// @Description Archive or unarchive a project based on request body
// @Tags projects
// @Accept json
// @Produce json
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectArchiveRequest true "Archive/unarchive request"
// @Success 204 "Project archive status updated successfully"
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project or project locked by another user"
// @Failure 404 {object} types.NotFoundError "Project not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/archive [post]
func (h *ProjectHandler) UpdateProjectArchive(ctx *gin.Context) {
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

	var req types.ProjectArchiveRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	// Validate request
	if err := validation.ValidateProjectArchiveRequest(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	var err error
	if req.Archive {
		err = h.project.ArchiveProject(ctx, projectID, userID)
	} else {
		err = h.project.UnarchiveProject(ctx, projectID, userID)
	}

	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		// Check if it's authorization errors
		if errorMsg == types.ErrMsgUserNotAssignedToProject ||
			strings.Contains(errorMsg, types.ErrMsgProjectLockedByUser) {
			ctx.JSON(http.StatusForbidden, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}

	ctx.JSON(http.StatusNoContent, nil)
}

// UpdateProjectLock updates the lock status of a project for a user.
// @Summary Update project lock status
// @Description Lock or unlock a project for a specific user based on request body
// @Tags projects
// @Accept json
// @Produce json
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectLockRequest true "Lock/unlock request"
// @Success 204 "Successfully updated project lock status"
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid payload"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project or project already locked by another user"
// @Failure 404 {object} types.NotFoundError "Project not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/lock [post]
func (h *ProjectHandler) UpdateProjectLock(ctx *gin.Context) {
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

	var req types.ProjectLockRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	// Validate request
	if err := validation.ValidateProjectLockRequest(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	var err error
	if req.IsLocked {
		err = h.project.LockProject(ctx, projectID, userID)
	} else {
		err = h.project.UnlockProject(ctx, projectID, userID)
	}

	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		// Check if it's authorization errors
		if errorMsg == types.ErrMsgUserNotAssignedToProject || errorMsg == types.ErrMsgUserNotFound ||
			errorMsg == types.ErrMsgProjectNotLockedByUser ||
			strings.Contains(errorMsg, types.ErrMsgProjectLockedByUser) {
			ctx.JSON(http.StatusForbidden, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}

	ctx.JSON(http.StatusNoContent, nil)
}
