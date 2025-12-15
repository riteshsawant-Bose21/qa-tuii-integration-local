package handler

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

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
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 404 {object} map[string]string "User not found in the system"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /user/me/authorization [get]
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
// @Failure 401 {object} map[string]string "Unauthorized - User email not found in token"
// @Failure 404 {object} map[string]string "User not found in the system"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /user/me/profile [get]
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
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 500 {object} map[string]string "Internal server error"
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
// @Failure 404 {object} map[string]string "User not found"
// @Failure 500 {object} map[string]string "Internal server error"
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
// @Failure 400 {object} map[string]string "Bad request - Invalid JSON payload"
// @Failure 404 {object} map[string]string "User not found"
// @Failure 500 {object} map[string]string "Internal server error"
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

// CheckAuthStatus checks if the current user is authenticated.
// @Summary Check authentication status
// @Description Check if the current user is properly authenticated and return basic status
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} map[string]interface{} "User is authenticated"
// @Failure 401 {object} map[string]string "User is not authenticated"
// @Router /auth/status [get]
func (h *UserHandler) CheckAuthStatus(ctx *gin.Context) {
	// Get user email from JWT token (set by Auth0 middleware)
	email, exists := ctx.Get("user_email")
	if !exists {
		authutils.RespondWithUnauthorized(ctx)
		return
	}

	emailStr, ok := email.(string)
	if !ok {
		authutils.RespondWithInvalidToken(ctx)
		return
	}

	authStatus := map[string]interface{}{
		"authenticated": true,
		"email":         emailStr,
	}
	httputils.RespondWithAuthStatusSuccess(ctx, "User is authenticated", authStatus)
}

// === User settings Handlers ===

// GetUserSettings retrieves user settings by user ID.
// @Summary Get user settings by user ID
// @Description Get settings for a specific user
// @Tags user/settings
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} types.UserSettings "Successfully retrieved user settings"
// @Failure 404 {object} types.StatusNotFound "User settings not found / Invalid user ID format"
// @Failure 500 {object} types.StatusInternalServerError "Internal server error"
// @Router /user/settings [get]
func (h *UserHandler) GetUserSettings(ctx *gin.Context) {

	userAuth, _ := ctx.Get("user_auth")
	auth := userAuth.(*types.UserAuthorizationResponse)
	userID := auth.User.ID

	if _, err := uuid.Parse(userID); err != nil {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user ID format"})
		return
	}

	settings, err := h.user.GetUserSettings(ctx, userID)
	if err != nil {
		if err.Error() == "user settings not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "User settings not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, settings)
}

// CreateUserSettings creates a new user settings.
// @Summary Create a new user settings
// @Description Create a new user settings with the provided details
// @Tags user/settings
// @Accept json
// @Produce json
// @Param settings body types.UserSettings true "User settings data"
// @Success 201 {object} types.CreateUserSettings_statusOk "Successfully created user settings"
// @Failure 400 {object} types.StatusBadRequest "Invalid request body"
// @Failure 500 {object} types.StatusInternalServerError "Internal server error"
// @Router /user/settings [post]
func (h *UserHandler) CreateUserSettings(ctx *gin.Context) {
	var settings types.UserSettings

	if err := ctx.ShouldBindJSON(&settings); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
		return
	}

	if settings.UserID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required for creating settings"})
		return
	}

	if _, err := uuid.Parse(settings.UserID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id format: must be a valid UUID"})
		return
	}

	userSettingsID, err := h.user.CreateUserSettings(ctx, &settings)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create user settings: %v", err)})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"id": userSettingsID})
}

// UpdateUserSettings updates an existing user settings.
// @Summary Update an existing user settings
// @Description Update an existing user settings with the provided details
// @Tags user/settings
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param profileID path string true "Profile ID"
// @Param settings body types.UpdateUserSettingsRequest true "User settings data"
// @Success 200 {object} types.UpdateUserSettings_statusOk "Successfully updated user settings"
// @Failure 400 {object} types.UpdateUserSettings_statusBadRequest "Invalid request body"
// @Failure 404 {object} types.StatusNotFound "User settings not found"
// @Failure 500 {object} types.StatusInternalServerError_UpdateUserSettings "Internal server error"
// @Router /user/settings/:settingsID [put]
func (h *UserHandler) UpdateUserSettings(ctx *gin.Context) {
	var settings types.UpdateUserSettingsRequest
	settingsID := ctx.Param("settingsID")

	if err := ctx.ShouldBindJSON(&settings); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	if _, err := uuid.Parse(settingsID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID format: must be a valid UUID"})
		return
	}

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	auth, ok := userAuth.(*types.UserAuthorizationResponse)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authentication context"})
		return
	}

	authUserID := auth.User.ID

	if err := h.user.UpdateUserSettings(ctx, &settings, settingsID, authUserID); err != nil {
		if err.Error() == "user settings not found" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "User settings not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to update user settings: %v", err)})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User settings updated successfully"})
}

// === user Profile Handlers ===

// GetUserProfileDetails retrieves user profile by user ID.
// @Summary Get user profile by user ID
// @Description Get profile for a specific user
// @Tags user/profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} types.UserProfile "Successfully retrieved user profile"
// @Failure 404 {object} types.GetUserProfile_statusNotFound "User profile not found / Invalid user ID format"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /user/profile [get]
func (h *UserHandler) GetUserProfileDetails(ctx *gin.Context) {

	userAuth, _ := ctx.Get("user_auth")
	auth := userAuth.(*types.UserAuthorizationResponse)
	userID := auth.User.ID

	if _, err := uuid.Parse(userID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	userProfile, err := h.user.GetUserProfile(ctx, userID)
	if err != nil {
		if err.Error() == "user profile not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "User profile not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, userProfile)
}

// CreateUserProfile creates a new user profile.
// @Summary Create a new user profile
// @Description Create a new user profile with the provided details
// @Tags user/profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param profile body types.UserProfile true "User profile data"
// @Success 201 {object} types.CreateUserProfile_statusOk "Successfully created user profile"
// @Failure 400 {object} types.StatusBadRequest "Invalid request body"
// @Failure 500 {object} types.CreateUserProfile_internalServerError "Internal server error"
// @Router /user/profile [post]
func (h *UserHandler) CreateUserProfile(ctx *gin.Context) {
	var profile types.UserProfile

	if err := ctx.ShouldBindJSON(&profile); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
		return
	}

	if profile.UserID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required for creating profile"})
		return
	}

	if _, err := uuid.Parse(profile.UserID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id format: must be a valid UUID"})
		return
	}

	if profile.Email == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "email is required for creating profile"})
		return
	}

	profileID, err := h.user.CreateUserProfile(ctx, &profile)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create user profile: %v", err)})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"id": profileID})
}

// UpdateUserProfile updates an existing user profile.
// @Summary Update an existing user profile
// @Description Update an existing user profile with the provided details
// @Tags user/profile
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param profileID path string true "Profile ID"
// @Param profile body types.UserProfileUpdateRequest true "User profile data"
// @Success 200 {object} types.UpdateUserProfile_statusOk "Successfully updated user profile"
// @Failure 400 {object} types.StatusBadRequest "Invalid request body"
// @Failure 500 {object} types.UpdateUserProfile_internalServerError "Internal server error"
// @Router /user/profile/:profileID [put]
func (h *UserHandler) UpdateUserProfile(ctx *gin.Context) {
	var profile types.UserProfileUpdateRequest

	profileID := ctx.Param("profileID")

	if err := ctx.ShouldBindJSON(&profile); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	if _, err := uuid.Parse(profileID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID format: must be a valid UUID"})
		return
	}

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Authentication required"})
		return
	}

	auth, ok := userAuth.(*types.UserAuthorizationResponse)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authentication context"})
		return
	}

	if err := h.user.UpdateUserProfile(ctx, &profile, profileID, auth.User.ID); err != nil {
		if err.Error() == "user profile not found" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "User profile not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to update user profile: %v", err)})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User profile updated successfully"})
}
