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

type UserHandler struct {
	service *service.UserService
}

func NewUserHandler(svc *service.UserService) *UserHandler {
	return &UserHandler{service: svc}
}

func (h *UserHandler) RegisterRoutes(r chi.Router) {
	r.Get("/me", h.Me)
	r.Post("/metadata", h.Metadata) // Allow POST for compatibility with Swagger docs
}

// Me godoc
// @Summary      Get current user profile
// @Description  Fetch the profile of the currently authenticated user
// @Tags         user
// @Security     BearerAuth
// @Produce      json
// @Success      200  {object}  model.UserResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /users/me [get]
func (h *UserHandler) Me(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	// Fetch user from DB using ID/email from token
	user, err := h.service.GetUserProfile(claims.UserID)
	if err != nil {
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgUserInfoFetchFailed, nil)
		return
	}

	// Build response (excluding password)
	var meta interface{}
	if err := json.Unmarshal([]byte(user.MetaData), &meta); err != nil {
		meta = user.MetaData // fallback to string if not valid JSON
	}
	userResp := &model.UserResponse{
		ID:        user.ID,
		Email:     user.Email,
		MetaData:  meta,
		CreatedAt: user.CreatedAt,
		UpdatedAt: user.UpdatedAt,
	}

	response := map[string]interface{}{
		"user": userResp,
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgUserInfoFetched, response)
}

// Me godoc
// @Summary      Post current user profile metadata
// @Description  Update the metadata of the currently authenticated user
// @Tags         user
// @Security     BearerAuth
// @Accept       json
// @Param        metadata  body      model.UserMetaData  true  "User metadata"
// @Success      200  {object}  model.UserResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /users/metadata [post]
func (h *UserHandler) Metadata(w http.ResponseWriter, r *http.Request) {
	claims, ok := middleware.GetUserFromContext(r.Context())
	if !ok {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgUserContextNotFound, nil)
		return
	}

	var meta *model.UserMetaData
	if err := json.NewDecoder(r.Body).Decode(&meta); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}

	// Update user metadata and get updated user
	updatedUser, err := h.service.AddUserMetadata(claims.UserID, meta)
	if err != nil {
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgUserMetadataInsertFailed, nil)
		return
	}

	// Prepare user response
	var metaObj interface{}
	if err := json.Unmarshal([]byte(updatedUser.MetaData), &metaObj); err != nil {
		metaObj = updatedUser.MetaData
	}
	userResp := &model.UserResponse{
		ID:        updatedUser.ID,
		Email:     updatedUser.Email,
		MetaData:  metaObj,
		CreatedAt: updatedUser.CreatedAt,
		UpdatedAt: updatedUser.UpdatedAt,
	}

	response := map[string]interface{}{
		"user": userResp,
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgUserMetadataInserted, response)
}
