package handler

import (
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	authutils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/auth"
	httputils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/http"
)

type UserHandler struct {
	user fusion.User
}

func NewUserHandler(userSvc fusion.User) *UserHandler {
	return &UserHandler{
		user: userSvc,
	}
}

// GetUserAuthorization retrieves the authorization details for the current user.
// @Summary Get user authorization details
// @Description Get authorization details including user info, account, role, and permissions for the current authenticated user
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} types.UserAuthorizationResponse "Successfully retrieved user authorization details"
// @Failure 401 {object} types.UnauthorizedResponse "Unauthorized - User email not found in token"
// @Failure 404 {object} types.NotFoundResponse "User not found in the system"
// @Failure 500 {object} types.InternalServerErrorResponse "Internal server error"
// @Router /users/authorization [get]
func (h *UserHandler) GetUserAuthorization(ctx *gin.Context) {
	// Get user email from JWT token (set by Auth0 middleware)
	email, exists := ctx.Get("user_email")
	if !exists {
		email, exists = ctx.Get("email")
	}
	if !exists {
		authutils.RespondWithUnauthorized(ctx)
		return
	}

	emailStr, ok := email.(string)
	if !ok {
		authutils.RespondWithInvalidToken(ctx)
		return
	}

	// Get authorization details from service using email
	authDetails, err := h.user.GetUserAuthorization(ctx, emailStr)
	if err != nil {
		// Check if it's a "user not found" error
		if strings.Contains(err.Error(), "user not found") {
			httputils.RespondWithNotFound(ctx, "User account not found in the system. Please contact your administrator to set up your account.")
			return
		}
		// All other errors are internal server errors
		httputils.RespondWithInternalServerError(ctx)
		return
	}

	httputils.RespondWithSuccess(ctx, "Successfully retrieved user authorization details", authDetails)
}

// GetUserProfile retrieves the current user's profile information.
// @Summary Get user profile
// @Description Get the current authenticated user's profile information
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} types.User "Successfully retrieved user profile"
// @Failure 401 {object} types.UnauthorizedResponse "Unauthorized - User email not found in token"
// @Failure 404 {object} types.NotFoundResponse "User not found in the system"
// @Failure 500 {object} types.InternalServerErrorResponse "Internal server error"
// @Router /users/profile [get]
func (h *UserHandler) GetUserProfile(ctx *gin.Context) {
	// Get user email from JWT token (set by Auth0 middleware)
	email, exists := ctx.Get("user_email")
	if !exists {
		email, exists = ctx.Get("email")
	}
	if !exists {
		authutils.RespondWithUnauthorized(ctx)
		return
	}

	emailStr, ok := email.(string)
	if !ok {
		authutils.RespondWithInvalidToken(ctx)
		return
	}

	// Get user details from service
	user, err := h.user.GetUserByEmail(ctx, emailStr)
	if err != nil {
		// Check if it's a "user not found" error
		if strings.Contains(err.Error(), "user not found") {
			httputils.RespondWithNotFound(ctx, "User account not found in the system. Please contact your administrator to set up your account.")
			return
		}
		// All other errors are internal server errors
		httputils.RespondWithInternalServerError(ctx)
		return
	}

	httputils.RespondWithUserSuccess(ctx, "Successfully retrieved user profile", user)
}

// CreateUser creates a new user in the system.
// @Summary Create a new user
// @Description Create a new user with the specified details
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param user body types.CreateUserRequest true "User creation details"
// @Success 201 {object} types.User "Successfully created user"
// @Failure 400 {object} types.BadRequestResponse "Bad request - Invalid JSON payload"
// @Failure 500 {object} types.InternalServerErrorResponse "Internal server error"
// @Router /users [post]
func (h *UserHandler) CreateUser(ctx *gin.Context) {
	var req types.CreateUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		httputils.RespondWithBadRequest(ctx, "Invalid request body: "+err.Error())
		return
	}

	user, err := h.user.CreateUser(ctx, &req)
	if err != nil {
		httputils.RespondWithInternalServerError(ctx)
		return
	}

	httputils.RespondWithUserCreated(ctx, "User created successfully", user)
}

// GetUserByEmail retrieves a user by their email address.
// @Summary Get user by email
// @Description Get a specific user by their email address
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param email path string true "User email address"
// @Success 200 {object} types.User "Successfully retrieved user"
// @Failure 404 {object} types.NotFoundResponse "User not found"
// @Failure 500 {object} types.InternalServerErrorResponse "Internal server error"
// @Router /users/{email} [get]
func (h *UserHandler) GetUserByEmail(ctx *gin.Context) {
	email := ctx.Param("email")
	if email == "" {
		httputils.RespondWithBadRequest(ctx, "Email parameter is required")
		return
	}

	user, err := h.user.GetUserByEmail(ctx, email)
	if err != nil {
		// Check if it's a "not found" error
		if strings.Contains(err.Error(), "user not found") {
			httputils.RespondWithNotFound(ctx, "User account not found in the system")
			return
		}
		// All other errors are internal server errors
		httputils.RespondWithInternalServerError(ctx)
		return
	}

	httputils.RespondWithUserSuccess(ctx, "Successfully retrieved user", user)
}

// UpdateUser updates an existing user's information.
// @Summary Update user
// @Description Update an existing user's information by their ID
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param userID path string true "User ID"
// @Param user body types.UpdateUserRequest true "Updated user details"
// @Success 200 {object} types.User "Successfully updated user"
// @Failure 400 {object} types.BadRequestResponse "Bad request - Invalid JSON payload"
// @Failure 404 {object} types.NotFoundResponse "User not found"
// @Failure 500 {object} types.InternalServerErrorResponse "Internal server error"
// @Router /users/{userID} [patch]
func (h *UserHandler) UpdateUser(ctx *gin.Context) {
	userID := ctx.Param("userID")
	if userID == "" {
		httputils.RespondWithBadRequest(ctx, "User ID parameter is required")
		return
	}

	var req types.UpdateUserRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		httputils.RespondWithBadRequest(ctx, "Invalid request body: "+err.Error())
		return
	}

	user, err := h.user.UpdateUser(ctx, userID, &req)
	if err != nil {
		// Check if it's a "not found" error
		if strings.Contains(err.Error(), "user not found") {
			httputils.RespondWithNotFound(ctx, "User account not found in the system")
			return
		}
		// All other errors are internal server errors
		httputils.RespondWithInternalServerError(ctx)
		return
	}

	httputils.RespondWithUserSuccess(ctx, "User updated successfully", user)
}
