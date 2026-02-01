package handler

import (
	"strings"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/validation"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
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
// @Security BearerAuth
// @Param body body types.ProjectCreateRequest true "Project details"
// @Success 201 {object} types.ProjectCreateResponse "Successfully created project"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload or user not found or project Id already exists"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects [post]
func (h *ProjectHandler) CreateProject(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")

	if !exists {
		response.InternalError(ctx)
		return
	}

	logger := loggerFromContext.(*zap.Logger)

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	var p types.ProjectCreateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	// Validate request
	if err := validation.ValidateProjectCreateRequest(&p); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	res, err := h.project.CreateProject(ctx, &p, *user, logger)

	if err != nil {
		if err.Error() == types.ErrMsgProjectAlreadyExists {
			response.BadRequest(ctx, err.Error())
			return
		}
		// Internal server errors
		response.InternalError(ctx)
		return
	}

	response.Created(ctx, res)
}

// GetProjects retrieves all projects.
// @Summary Get all projects
// @Description Get all projects in the system
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param is_archived query bool false "Filter projects by archived status"
// @Param sort_by query string false "Field to sort projects by (e.g., created_at, updated_at)"
// @Param sort_order query string false "Sort order (ascending or descending)" Enums(asc, desc)
// @Success 200 {object} types.GetAllProjectsResponse "Successfully retrieved all projects"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid query parameters"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects [get]
func (h *ProjectHandler) GetAllProjects(ctx *gin.Context) {

	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	params := types.GetAllProjectsParams{}

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}

	user, ok := userAuth.(*types.UserAuthorizationResponse)
	if !ok || user == nil {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}

	if err := ctx.ShouldBindQuery(&params); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	// Validate query parameters
	if err := validation.ValidateGetAllProjectsParams(&params); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	if params.SortBy == "" {
		params.SortBy = "updated_at"
	}

	if params.SortOrder == "" {
		params.SortOrder = "desc"
	}

	res, err := h.project.GetAllProjects(ctx, &params, *user, logger)
	if err != nil {
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, res)
}

// UpdateProject updates an existing project.
// @Summary Update project
// @Description Update an existing project by its ID
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectUpdateRequest true "Updated project details"
// @Success 200 {object} types.ProjectUpdateResponse "Successfully updated project"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 403 {object} types.ErrorResponse "Forbidden - User not assigned to project, project archived, or locked by another user"
// @Failure 404 {object} types.ErrorResponse "Project or user not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects/{projectId} [patch]
func (h *ProjectHandler) UpdateProject(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	projectID := ctx.Param("projectId")

	userAuth, exists := ctx.Get("user_auth")

	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}

	user := userAuth.(*types.UserAuthorizationResponse)

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		response.NotFound(ctx, types.ErrMsgProjectNotFound)
		return
	}

	var p types.ProjectUpdateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	// Validate request
	if err := validation.ValidateProjectUpdateRequest(&p); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	p.ID = projectID

	// Use authenticated update method which includes all validations
	res, err := h.project.UpdateProject(ctx, &p, *user, logger)
	if err != nil {
		// Check if it's a "not found" error
		if err.Error() == types.ErrMsgProjectNotFound || err.Error() == types.ErrMsgSqlNoRows {
			response.NotFound(ctx, err.Error())
			return
		}

		if err.Error() == types.ErrMsgUserNotFound {
			response.Unauthorized(ctx, err.Error())
			return
		}

		// Check if it's authorization errors
		if err.Error() == types.ErrMsgUserNotAssignedToProject ||
			err.Error() == types.ErrMsgProjectArchived ||
			err.Error() == types.ErrMsgForbidden ||
			strings.Contains(err.Error(), types.ErrMsgProjectLockedByUser) ||
			strings.Contains(err.Error(), types.ErrMsgFailedToGetUserByEmail) {
			response.Forbidden(ctx, err.Error())
			return
		}
		// All other errors are internal server errors - temporarily log for debugging
		response.InternalError(ctx)
		return
	}
	response.OK(ctx, res)
}

// DeleteProject deletes a project by ID.
// @Summary Delete project
// @Description Delete a project by its unique identifier
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param projectId path string true "Project ID"
// @Success 204 "Successfully deleted project"
// @Failure 400 {object} types.ErrorResponse "Bad request - Missing user ID"
// @Failure 403 {object} types.ErrorResponse "Forbidden - User not assigned to project, project archived, or locked by another user"
// @Failure 404 {object} types.ErrorResponse "Project or user not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects/{projectId} [delete]
func (h *ProjectHandler) DeleteProject(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	projectID := ctx.Param("projectId")

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}

	user := userAuth.(*types.UserAuthorizationResponse)

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		response.NotFound(ctx, types.ErrMsgProjectNotFound)
		return
	}

	if err := h.project.DeleteProject(ctx, projectID, *user, logger); err != nil {
		// Check if it's a "not found" error
		if err.Error() == types.ErrMsgProjectNotFound || err.Error() == types.ErrMsgSqlNoRows {
			response.NotFound(ctx, err.Error())
			return
		}

		// Check if it's authorization errors
		if err.Error() == types.ErrMsgUserNotAssignedToProject ||
			err.Error() == types.ErrMsgUserNotFound ||
			err.Error() == types.ErrMsgProjectArchived ||
			err.Error() == types.ErrMsgForbidden ||
			strings.Contains(err.Error(), types.ErrMsgProjectLockedByUser) ||
			strings.Contains(err.Error(), types.ErrMsgFailedToGetUserByEmail) {
			response.Forbidden(ctx, err.Error())
			return
		}
		// All other errors are internal server errors
		response.InternalError(ctx)
		return
	}
	response.NoContent(ctx)
}

// AssignUserToProject assigns a user to a project.
// @Summary Assign a user to a project
// @Description Assign a user to a project by project ID and user email
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param projectId path string true "Project ID"
// @Param userEmail path string true "User Email"
// @Success 204 "User successfully assigned to the project"
// @Failure 404 {object} types.ErrorResponse "Project or User not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects/{projectId}/users/{userEmail} [put]
func (h *ProjectHandler) AssignUserToProject(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	projectID := ctx.Param("projectId")
	userEmail := strings.TrimSpace(ctx.Param("userEmail"))
	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	// Validate projectID UUID
	if !validation.IsValidUUID(projectID) {
		response.BadRequest(ctx, "Invalid project ID format")
		return
	}

	_, err := h.project.AssignUserToProject(ctx, projectID, userEmail, *user, logger)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound || errorMsg == types.ErrMsgProjectArchived {
			response.NotFound(ctx, errorMsg)
			return
		}
		// All other errors are internal server errors
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// RemoveUserFromProject removes a user from a project.
// @Summary Remove a user from a project
// @Description Remove a user from a project by project ID and user email
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param projectId path string true "Project ID"
// @Param userEmail path string true "User Email"
// @Success 204 "User successfully removed from the project"
// @Failure 404 {object} types.ErrorResponse "Project or User not found, or user not assigned to the project"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects/{projectId}/users/{userEmail} [delete]
func (h *ProjectHandler) RemoveUserFromProject(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	projectID := ctx.Param("projectId")
	userEmail := strings.TrimSpace(ctx.Param("userEmail"))

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	// Validate projectID UUID
	if !validation.IsValidUUID(projectID) {
		response.BadRequest(ctx, "Invalid project ID format")
		return
	}

	_, err := h.project.RemoveUserFromProject(ctx, projectID, userEmail, *user, logger)
	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			response.NotFound(ctx, errorMsg)
			return
		}
		if errorMsg == types.ErrMsgUserNotAssignedToProject {
			response.NotFound(ctx, errorMsg)
			return
		}
		// All other errors are internal server errors
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// UpdateProjectStar updates the star status of a project for a user.
// @Summary Update project star status
// @Description Star or unstar a project for a specific user based on request body
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectStarRequest true "Star/unstar request"
// @Success 204 "Successfully updated project star status"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 403 {object} types.ErrorResponse "Forbidden - User not assigned to project, project archived, or locked by another user"
// @Failure 404 {object} types.ErrorResponse "Project or User not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects/{projectId}/star/{userId} [post]
func (h *ProjectHandler) UpdateProjectStar(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	projectID := ctx.Param("projectId")

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		response.NotFound(ctx, types.ErrMsgProjectNotFound)
		return
	}

	var req types.ProjectStarRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	// Validate request
	if err := validation.ValidateProjectStarRequest(&req); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	var err error
	if req.IsStarred {
		err = h.project.StarProject(ctx, projectID, user.User.ID, logger)
	} else {
		err = h.project.UnstarProject(ctx, projectID, user.User.ID, logger)
	}

	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			response.NotFound(ctx, errorMsg)
			return
		}
		if errorMsg == types.ErrMsgUserNotAssignedToProject || errorMsg == types.ErrMsgProjectArchived {
			response.Forbidden(ctx, errorMsg)
			return
		}
		// All other errors are internal server errors
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// UpdateProjectArchive updates the archive status of a project.
// @Summary Update project archive status
// @Description Archive or unarchive a project based on request body
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectArchiveRequest true "Archive/unarchive request"
// @Success 204 "Project archive status updated successfully"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 403 {object} types.ErrorResponse "Forbidden - User not assigned to project or project locked by another user"
// @Failure 404 {object} types.ErrorResponse "Project not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects/{projectId}/archive [post]
func (h *ProjectHandler) UpdateProjectArchive(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	projectID := ctx.Param("projectId")

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		response.NotFound(ctx, types.ErrMsgProjectNotFound)
		return
	}

	var req types.ProjectArchiveRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	// Validate request
	if err := validation.ValidateProjectArchiveRequest(&req); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	var err error
	if req.Archive {
		err = h.project.ArchiveProject(ctx, projectID, *user, logger)
	} else {
		err = h.project.UnarchiveProject(ctx, projectID, *user, logger)
	}

	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound || errorMsg == types.ErrMsgUserNotFound {
			response.NotFound(ctx, errorMsg)
			return
		}
		// Check if it's authorization errors
		if errorMsg == types.ErrMsgUserNotAssignedToProject ||
			strings.Contains(errorMsg, types.ErrMsgProjectLockedByUser) ||
			strings.Contains(errorMsg, types.ErrMsgFailedToGetUserByEmail) {
			response.Forbidden(ctx, errorMsg)
			return
		}
		// All other errors are internal server errors
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// UpdateProjectLock updates the lock status of a project for a user.
// @Summary Update project lock status
// @Description Lock or unlock a project for a specific user based on request body
// @Tags projects
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param projectId path string true "Project ID"
// @Param body body types.ProjectLockRequest true "Lock/unlock request"
// @Success 204 "Successfully updated project lock status"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 403 {object} types.ErrorResponse "Forbidden - User not assigned to project or project already locked by another user"
// @Failure 404 {object} types.ErrorResponse "Project not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /projects/{projectId}/lock [post]
func (h *ProjectHandler) UpdateProjectLock(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	projectID := ctx.Param("projectId")

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, types.ErrMsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	// Validate UUIDs
	if !validation.IsValidUUID(projectID) {
		response.NotFound(ctx, types.ErrMsgProjectNotFound)
		return
	}

	var req types.ProjectLockRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	// Validate request
	if err := validation.ValidateProjectLockRequest(&req); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	var err error
	if req.IsLocked {
		err = h.project.LockProject(ctx, projectID, *user, logger)
	} else {
		err = h.project.UnlockProject(ctx, projectID, *user, logger)
	}

	if err != nil {
		errorMsg := err.Error()
		// Check for specific error types
		if errorMsg == types.ErrMsgProjectNotFound {
			response.NotFound(ctx, errorMsg)
			return
		}
		// Check if it's authorization errors
		if errorMsg == types.ErrMsgUserNotAssignedToProject || errorMsg == types.ErrMsgUserNotFound ||
			errorMsg == types.ErrMsgProjectNotLockedByUser ||
			errorMsg == types.ErrMsgFailedToGetUserByEmail ||
			errorMsg == types.ErrMsgForbidden ||
			errorMsg == types.ErrMsgProjectArchived ||
			strings.Contains(errorMsg, types.ErrMsgProjectLockedByUser) {
			response.Forbidden(ctx, errorMsg)
			return
		}
		// All other errors are internal server errors
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}
