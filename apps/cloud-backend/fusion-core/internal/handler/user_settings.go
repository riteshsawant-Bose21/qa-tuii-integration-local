package handler

import (
	"fmt"
	"net/http"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UserSettingsHandler struct {
	userSettings fusion.UserSettings
}

func NewUserSettingsHandler(userSettingsSvc fusion.UserSettings) *UserSettingsHandler {
	return &UserSettingsHandler{
		userSettings: userSettingsSvc,
	}
}

// GetUserSettings retrieves user settings by user ID.
// @Summary Get user settings by user ID
// @Description Get settings for a specific user
// @Tags user/settings
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} types.UserSettings "Successfully retrieved user settings"
// @Failure 404 {object} object{error=string} "User settings not found / Invalid user ID format"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/settings [get]
func (h *UserSettingsHandler) GetUserSettings(ctx *gin.Context) {

	userAuth, _ := ctx.Get("user_auth")
	auth := userAuth.(*types.UserAuthorizationResponse)
	userID := auth.User.ID

	if _, err := uuid.Parse(userID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	settings, err := h.userSettings.GetUserSettings(ctx, userID)
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
// @Success 201 {object} object{message=string,id=string} "Successfully created user settings"
// @Failure 400 {object} object{error=string} "Invalid request body"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/settings [post]
func (h *UserSettingsHandler) CreateUserSettings(ctx *gin.Context) {
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

	if err := h.userSettings.CreateUserSettings(ctx, &settings); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create user settings: %v", err)})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "User settings created successfully", "id": settings.ID})
}

// UpdateUserSettings updates an existing user settings.
// @Summary Update an existing user settings
// @Description Update an existing user settings with the provided details
// @Tags user/settings
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param settings body types.UserSettings true "User settings data"
// @Success 200 {object} object{message=string,userID=string} "Successfully updated user settings"
// @Failure 400 {object} object{error=string} "Invalid request body"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/settings [put]
func (h *UserSettingsHandler) UpdateUserSettings(ctx *gin.Context) {
	var settings types.UserSettings

	if err := ctx.ShouldBindJSON(&settings); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid JSON format: %v", err)})
		return
	}

	if settings.ID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "id is required for updating settings"})
		return
	}

	if _, err := uuid.Parse(settings.ID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID format: must be a valid UUID"})
		return
	}

	if settings.UserID == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "user_id is required for updating settings"})
		return
	}

	if _, err := uuid.Parse(settings.UserID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user_id format: must be a valid UUID"})
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

	authenticatedUserID := auth.User.ID

	// This prevents users from updating other user's settings
	if settings.UserID != authenticatedUserID {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized: You are not allowed to update this user's settings"})
		return
	}

	if err := h.userSettings.UpdateUserSettings(ctx, &settings); err != nil {
		if err.Error() == "user settings not found" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "User settings not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to update user settings: %v", err)})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User settings updated successfully"})
}
