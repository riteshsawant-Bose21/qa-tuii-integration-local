package handler

import (
	"encoding/json"
	"fmt"
	"net/http"

	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/middleware"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"

	"github.com/go-chi/chi/v5"
)

type SpaceHandler struct {
	svc *service.Space
}

func NewSpace(spaceService *service.Space) *SpaceHandler {
	return &SpaceHandler{svc: spaceService}
}

func (s *SpaceHandler) RegisterRoutes(r chi.Router) {
	r.Post("/", s.CreateSpace)
	r.Get("/", s.GetAllSpace)
	r.Put("/", s.UpdateSpace)
	r.Delete("/{id}", s.DeleteSpace)
}

// CreateSpace godoc
// @Summary      Create a new space
// @Description  Create a new space for the authenticated user
// @Tags         space
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        space  body      model.SpaceRequest  true  "Space details"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /spaces [post]
func (s *SpaceHandler) CreateSpace(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	var space *model.SpaceRequest
	if err := json.NewDecoder(r.Body).Decode(&space); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}
	spc, err := s.svc.CreateSpace(space)
	if err != nil {
		fmt.Println("Error response returned", err)
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgGetSpaceFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgGetSpace, spc)
}

// GetAllSpace godoc
// @Summary      Get All Space
// @Description  Get All Space
// @Tags         space
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      404  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /spaces [get]
func (s *SpaceHandler) GetAllSpace(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	spc, err := s.svc.GetAllSpace()
	if err != nil {
		fmt.Println("Error response returned", err)
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgSpaceListFetchFailed, spc)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgSpaceListFetched, spc)
}

// UpdateSpace godoc
// @Summary      Update a space
// @Description  Update an existing space for the authenticated user
// @Tags         space
// @Security     BearerAuth
// @Accept       json
// @Produce      json
// @Param        space  body      model.SpaceRequest  true  "Space details"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      404  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /spaces [put]
func (s *SpaceHandler) UpdateSpace(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	var space *model.SpaceRequest
	if err := json.NewDecoder(r.Body).Decode(&space); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}

	isUpdated, err := s.svc.UpdateSpace(space)
	if err != nil {
		fmt.Println("Error response returned", err)
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgSpaceUpdateFailed, nil)
		return
	}

	if isUpdated {
		utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgSpaceUpdated, nil)
		return
	}
}

// DeleteSpace godoc
// @Summary      Delete a space
// @Description  Delete a space by its ID for the authenticated user
// @Tags         space
// @Security     BearerAuth
// @Produce      json
// @Param        id  path      string  true  "Space ID"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      404  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /spaces/{id} [delete]
func (s *SpaceHandler) DeleteSpace(w http.ResponseWriter, r *http.Request) {
	_, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	id := chi.URLParam(r, "id")
	err := s.svc.DeleteSpace(id)
	if err != nil {
		fmt.Println("Error response returned", err)
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgSpaceDeleteFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgSpaceDeleted, nil)
}
