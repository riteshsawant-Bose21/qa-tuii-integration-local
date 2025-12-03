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
// @Param userID path string true "User ID"
// @Success 200 {object} types.UserSettings "Successfully retrieved user settings"
// @Failure 404 {object} object{error=string} "User settings not found / Invalid user ID format"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/settings/{userID} [get]
func (h *UserSettingsHandler) GetUserSettings(ctx *gin.Context) {
	id := ctx.Param("userID")
	if _, err := uuid.Parse(id); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	settings, err := h.userSettings.GetUserSettings(ctx, id)
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
// @Param settings body types.UserSettings true "User settings data"
// @Success 200 {object} object{message=string,userID=string} "Successfully updated user settings"
// @Failure 400 {object} object{error=string} "Invalid request body"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/settings [put]
func (h *UserSettingsHandler) UpdateUserSettings(ctx *gin.Context) {
	var settings types.UserSettings

	if err := ctx.ShouldBindJSON(&settings); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
		return
	}

	if err := h.userSettings.UpdateUserSettings(ctx, &settings); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to update user settings: %v", err)})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User settings updated successfully", "userID": settings.UserID})
}
