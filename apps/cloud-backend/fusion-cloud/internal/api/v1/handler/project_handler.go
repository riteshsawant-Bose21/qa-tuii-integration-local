package handler

import (
	"encoding/json"
	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/middleware"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"
	"net/http"

	"github.com/go-chi/chi/v5"
)

type ProjectHandler struct {
	service *service.ProjectService
}

func NewProjectHandler(svc *service.ProjectService) *ProjectHandler {
	return &ProjectHandler{service: svc}
}

func (h *ProjectHandler) RegisterRoutes(r chi.Router) {
	r.Post("/", h.CreateProject)
	r.Get("/", h.ListProjects)
	r.Get("/{id}", h.GetProject)
	r.Put("/{id}", h.UpdateProject)
	r.Delete("/{id}", h.DeleteProject)
}

// CreateProject godoc
// @Summary      Create a new project
// @Description  Create a new project for the authenticated user
// @Tags         project
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        project  body      model.ProjectRequest  true  "Project details"
// @Success      201  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      409  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /projects [post]
func (h *ProjectHandler) CreateProject(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	var project model.ProjectRequest
	if err := json.NewDecoder(r.Body).Decode(&project); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}
	id, err := h.service.CreateProject(&project, claims.UserID)
	if err != nil {
		// Handle specific errors
		if ve, ok := err.(*utils.ValidationError); ok {
			utils.Respond(w, http.StatusBadRequest, constants.StatusError, ve.Message, ve.Errors)
			return
		}

		// Handle project already exists error
		if err == utils.ErrProjectAlreadyExists {
			utils.Respond(w, http.StatusConflict, constants.StatusError, constants.MsgProjectAlreadyExists, nil)
			return
		}

		// For other errors, log and respond with a generic error
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgProjectCreationFailed, nil)
		return
	}

	// Prepare response data
	response := map[string]any{
		"id":   id,
		"name": project.Name,
	}

	utils.Respond(w, http.StatusCreated, constants.StatusSuccess, constants.MsgProjectCreated, response)
}

// ListProjects godoc
// @Summary      List all projects
// @Description  Fetch all projects for the authenticated user
// @Tags         project
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /projects [get]
func (h *ProjectHandler) ListProjects(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	projects, err := h.service.ListProjectsByOwner(claims.UserID)
	if err != nil {
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgProjectListFetchFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgProjectListFetched, projects)
}

// GetProject godoc
// @Summary      Get a project by ID
// @Description  Fetch a project by its ID for the authenticated user
// @Tags         project
// @Security     BearerAuth
// @Produce      json
// @Param        id  path      string  true  "Project ID"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      404  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /projects/{id} [get]
func (h *ProjectHandler) GetProject(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	projectID := chi.URLParam(r, "id")
	if projectID == "" {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgProjectIDRequired, nil)
		return
	}

	project, err := h.service.GetProjectByID(claims.UserID, projectID)
	if err != nil {
		if err == utils.ErrProjectNotFound {
			utils.Respond(w, http.StatusNotFound, constants.StatusError, constants.MsgProjectNotFound, nil)
			return
		}

		// For other errors, log and respond with a generic error
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgProjectFetchFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgProjectFetched, project)
}

// UpdateProject godoc
// @Summary      Update a project
// @Description  Update an existing project for the authenticated user
// @Tags         project
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        id  path      string  true  "Project ID"
// @Param        project  body      model.ProjectRequest  true  "Project details"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      404  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /projects/{id} [put]
func (h *ProjectHandler) UpdateProject(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	projectID := chi.URLParam(r, "id")
	if projectID == "" {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgProjectIDRequired, nil)
		return
	}

	var project model.ProjectRequest
	if err := json.NewDecoder(r.Body).Decode(&project); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}

	err := h.service.UpdateProject(claims.UserID, projectID, &project)
	if err != nil {
		if ve, ok := err.(*utils.ValidationError); ok {
			utils.Respond(w, http.StatusBadRequest, constants.StatusError, ve.Message, ve.Errors)
			return
		}

		if err == utils.ErrProjectNotFound {
			utils.Respond(w, http.StatusNotFound, constants.StatusError, constants.MsgProjectNotFound, nil)
			return
		}

		// For other errors, log and respond with a generic error
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgProjectUpdateFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgProjectUpdated, nil)
}

// DeleteProject godoc
// @Summary      Delete a project
// @Description  Delete a project by its ID for the authenticated user
// @Tags         project
// @Security     BearerAuth
// @Produce      json
// @Param        id  path      string  true  "Project ID"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      404  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /projects/{id} [delete]
func (h *ProjectHandler) DeleteProject(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	projectID := chi.URLParam(r, "id")
	if projectID == "" {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgProjectIDRequired, nil)
		return
	}

	err := h.service.DeleteProject(claims.UserID, projectID)
	if err != nil {
		if err == utils.ErrProjectNotFound {
			utils.Respond(w, http.StatusNotFound, constants.StatusError, constants.MsgProjectNotFound, nil)
			return
		}

		// For other errors, log and respond with a generic error
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgProjectDeletionFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgProjectDeleted, nil)
}
