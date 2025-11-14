package handler

import (
	"net/http"
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/validation"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

// isValidUUID checks if a string is a valid UUID format.
// Returns true if valid, false otherwise.
func isValidUUID(str string) bool {
	_, err := uuid.Parse(str)
	return err == nil
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
		// Check if it's a user not found or validation error
		if err.Error() == types.ErrMsgUserNotFound || err.Error() == types.ErrMsgProjectCannotBeNil {
			ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
			return
		}
		// All other errors are internal server errors
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
// @Param user_id query string true "User ID"
// @Param is_archived query bool false "Filter projects by archived status"
// @Param sort_by query string false "Field to sort projects by (e.g., created_at, updated_at)"
// @Param sort_order query string false "Sort order (ascending or descending)" Enums(asc, desc)
// @Success 200 {object} types.GetAllProjectsResponse "Successfully retrieved all projects"
// @Failure 400 {object} types.BadRequestError "Bad request - Invalid query parameters or user ID"
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

	if !isValidUUID(userID) {
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
	userID := ctx.Query("user_id")

	if userID == "" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserIdRequired})
		return
	}

	// Validate UUIDs
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
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
	response, err := h.project.UpdateProjectWithAuth(ctx, projectID, userID, &p)
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
// @Failure 401 {object} types.UnauthorizedError "Unauthorized - User not found"
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
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	// Use authenticated delete method which includes all validations
	if err := h.project.DeleteProjectWithAuth(ctx, projectID, userID); err != nil {
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
	ctx.JSON(204, nil)
}

// SyncProjectRequest represents the request body for project synchronization.
type SyncProjectRequest struct {
	MetaData   map[string]interface{} `json:"meta_data" example:"{\"version\": \"1.0\", \"updated_by\": \"user123\"}" validate:"required"`
	ZipFileURL string                 `json:"zip_file_url" example:"https://example.com/project.zip" validate:"required,url"`
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
	if !isValidUUID(projectID) {
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
	if !isValidUUID(projectID) {
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

// StarProject stars a project for a user.
// @Summary Star a project
// @Description Star a project for a specific user
// @Tags projects
// @Param projectId path string true "Project ID"
// @Param userId path string true "User ID"
// @Success 204 "Successfully starred project"
// @Failure 404 {object} types.NotFoundError "Project or User not found, or user not assigned to the project"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/star/{userId} [put]
func (h *ProjectHandler) StarProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Param("userId")

	// Validate UUIDs
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	err := h.project.StarProject(ctx, projectID, userID)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		if errorMsg == types.ErrMsgUserNotAssignedToProject {
			ctx.JSON(http.StatusUnauthorized, types.ErrorResponse{Message: errorMsg})
			return
		}
		// All other errors are internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}

	ctx.JSON(http.StatusNoContent, nil)
}

// UnstarProject unstars a project for a user.
// @Summary Unstar a project
// @Description Unstar a project for a specific user
// @Tags projects
// @Param projectId path string true "Project ID"
// @Param userId path string true "User ID"
// @Success 204 "Successfully unstarred project"
// @Failure 401 {object} types.UnauthorizedError "User not assigned to the project"
// @Failure 404 {object} types.NotFoundError "Project or User not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/star/{userId} [delete]
func (h *ProjectHandler) UnstarProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Param("userId")

	// Validate UUIDs
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	err := h.project.UnstarProject(ctx, projectID, userID)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types in priority order
		if errorMsg == types.ErrMsgUserNotAssignedToProject {
			ctx.JSON(http.StatusUnauthorized, types.ErrorResponse{Message: errorMsg})
			return
		}
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

// ArchiveProject godoc
// @Summary Archive a project
// @Description Archive a project by project ID
// @Tags projects
// @Param projectId path string true "Project ID"
// @Success 204 "Project archived successfully"
// @Failure 400 {object} types.BadRequestError "Bad request - Missing user ID"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project or project locked by another user"
// @Failure 404 {object} types.NotFoundError "Project or user not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/archive [put]
func (h *ProjectHandler) ArchiveProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Query("user_id")

	if userID == "" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserIdRequired})
		return
	}

	// Validate UUIDs
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	// Use authenticated archive method which includes all validations
	err := h.project.ArchiveProjectWithAuth(ctx, projectID, userID)
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

// UnarchiveProject godoc
// @Summary Unarchive a project
// @Description Unarchive a project by project ID
// @Tags projects
// @Param projectId path string true "Project ID"
// @Success 204 "Project unarchived successfully"
// @Failure 400 {object} types.BadRequestError "Bad request - Missing user ID"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project or project locked by another user"
// @Failure 404 {object} types.NotFoundError "Project or user not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/archive [delete]
func (h *ProjectHandler) UnarchiveProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Query("user_id")

	if userID == "" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserIdRequired})
		return
	}

	// Validate UUIDs
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	// Use authenticated unarchive method which includes all validations
	err := h.project.UnarchiveProjectWithAuth(ctx, projectID, userID)
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

// LockProject locks a project for a user.
// @Summary Lock a project
// @Description Lock a project for a specific user
// @Tags projects
// @Param projectId path string true "Project ID"
// @Success 204 "Successfully locked project"
// @Failure 400 {object} types.BadRequestError "Bad request - Missing user ID"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project or project already locked by another user"
// @Failure 404 {object} types.NotFoundError "Project or User not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/lock [put]
func (h *ProjectHandler) LockProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Query("user_id")

	if userID == "" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserIdRequired})
		return
	}

	// Validate UUIDs
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	err := h.project.LockProject(ctx, projectID, userID)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		// Check if it's authorization errors
		if errorMsg == types.ErrMsgUserNotAssignedToProject ||
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

// UnlockProject unlocks a project for a user.
// @Summary Unlock a project
// @Description Unlock a project for a specific user (only if they locked it)
// @Tags projects
// @Param projectId path string true "Project ID"
// @Success 204 "Successfully unlocked project"
// @Failure 400 {object} types.BadRequestError "Bad request - Missing user ID"
// @Failure 403 {object} types.ForbiddenError "Forbidden - User not assigned to project or project not locked by this user"
// @Failure 404 {object} types.NotFoundError "Project or User not found"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /projects/{projectId}/lock [delete]
func (h *ProjectHandler) UnlockProject(ctx *gin.Context) {
	projectID := ctx.Param("projectId")
	userID := ctx.Query("user_id")

	if userID == "" {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: types.ErrMsgUserIdRequired})
		return
	}

	// Validate UUIDs
	if !isValidUUID(projectID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgProjectNotFound})
		return
	}
	if !isValidUUID(userID) {
		ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: types.ErrMsgUserNotFound})
		return
	}

	err := h.project.UnlockProject(ctx, projectID, userID)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			ctx.JSON(http.StatusNotFound, types.ErrorResponse{Message: errorMsg})
			return
		}
		// Check if it's authorization errors
		if errorMsg == types.ErrMsgUserNotAssignedToProject ||
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
