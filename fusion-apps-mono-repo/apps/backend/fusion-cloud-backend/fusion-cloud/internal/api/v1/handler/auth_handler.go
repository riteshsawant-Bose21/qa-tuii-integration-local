package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"github.com/go-chi/chi/v5"

	"fusion-cloud/internal/constants"
	"fusion-cloud/internal/model"
	"fusion-cloud/internal/service"
	"fusion-cloud/internal/utils"
)

type AuthHandler struct {
	service *service.AuthService
}

func NewAuthHandler(svc *service.AuthService) *AuthHandler {
	return &AuthHandler{service: svc}
}

func (h *AuthHandler) RegisterRoutes(r chi.Router) {
	r.Post("/register", h.RegisterUser)
	r.Post("/login", h.LoginUser)
	r.Post("/refresh-token", h.RefreshToken)
}

// RegisterUser godoc
// @Summary      Register a new user
// @Description  Register a new user with email and password
// @Tags         auth
// @Accept       json
// @Produce      json
// @Param        user  body      model.UserRegistration  true  "User registration details"
// @Success      201  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      409  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /auth/register [post]
func (h *AuthHandler) RegisterUser(w http.ResponseWriter, r *http.Request) {
	var user model.UserRegistration
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}

	id, err := h.service.RegisterUser(&user)
	if err != nil {

		// Detect and format validation error
		if ve, ok := err.(*utils.ValidationError); ok {
			utils.Respond(w, http.StatusBadRequest, constants.StatusError, ve.Message, ve.Errors)
			return
		}

		// Handle specific errors (e.g., user already exists)
		if err == utils.ErrUserAlreadyExists {
			utils.Respond(w, http.StatusConflict, constants.StatusError, constants.MsgUserAlreadyExists, nil)
			return
		}

		// For other errors, log and respond with a generic error
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgUserRegistrationFailed, nil)
		return
	}

	// Prepare response data
	response := map[string]any{
		"id":    id,
		"email": user.Email,
	}

	// Write success response
	utils.Respond(w, http.StatusCreated, constants.StatusSuccess, constants.MsgUserRegistered, response)
}

// LoginUser godoc
// @Summary      Login a user
// @Description  Login a user with email and password
// @Tags         auth
// @Accept       json
// @Produce      json
// @Param        user  body      model.UserLogin  true  "User login details"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /auth/login [post]
func (h *AuthHandler) LoginUser(w http.ResponseWriter, r *http.Request) {
	var login model.UserLogin
	if err := json.NewDecoder(r.Body).Decode(&login); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}

	authResp, err := h.service.LoginUser(&login)
	if err != nil {

		// Detect and format validation error
		if ve, ok := err.(*utils.ValidationError); ok {
			utils.Respond(w, http.StatusBadRequest, constants.StatusError, ve.Message, ve.Errors)
			return
		}
		// Handle specific errors (e.g., user not found or password mismatch)
		if errors.Is(err, utils.ErrUserNotFound) || errors.Is(err, utils.ErrInvalidCredentials) {
			utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgInvalidCredentials, nil)
			return
		}
		// For other errors, log and respond with a generic error
		utils.Respond(w, http.StatusInternalServerError, constants.StatusError, constants.MsgUserLoginFailed, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgUserLoggedIn, authResp)
}

// RefreshToken godoc
// @Summary      Refresh user token
// @Description  Refresh the user's authentication token using a valid refresh token
// @Tags         auth
// @Accept       json
// @Produce      json
// @Param        refreshToken  body      model.RefreshTokenRequest  true  "Refresh token request"
// @Success      200  {object}  utils.APIResponse
// @Failure      400  {object}  utils.APIResponse
// @Failure      401  {object}  utils.APIResponse
// @Failure      500  {object}  utils.APIResponse
// @Router       /auth/refresh-token [post]
func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var req model.RefreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.Respond(w, http.StatusBadRequest, constants.StatusError, constants.MsgInvalidRequestPayload, nil)
		return
	}

	authResp, err := h.service.RefreshToken(req.RefreshToken)
	if err != nil {
		utils.Respond(w, http.StatusUnauthorized, constants.StatusError, constants.MsgInvalidOrExpiredToken, nil)
		return
	}

	utils.Respond(w, http.StatusOK, constants.StatusSuccess, constants.MsgTokenRefreshed, authResp)
}
