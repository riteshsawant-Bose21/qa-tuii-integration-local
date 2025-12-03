package handler

import (
	"fmt"
	"net/http"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UserProfileHandler struct {
	userProfile fusion.UserProfile
}

func NewUserProfileHandler(userProfileSvc fusion.UserProfile) *UserProfileHandler {
	return &UserProfileHandler{
		userProfile: userProfileSvc,
	}
}

// GetUserProfile retrieves user profile by user ID.
// @Summary Get user profile by user ID
// @Description Get profile for a specific user
// @Tags user/profile
// @Accept json
// @Produce json
// @Param userID path string true "User ID"
// @Success 200 {object} types.UserProfile "Successfully retrieved user profile"
// @Failure 404 {object} object{error=string} "User profile not found / Invalid user ID format"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/profile/{userID} [get]
func (h *UserProfileHandler) GetUserProfile(ctx *gin.Context) {
	id := ctx.Param("userID")
	if _, err := uuid.Parse(id); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	settings, err := h.userProfile.GetUserProfile(ctx, id)
	if err != nil {
		if err.Error() == "user profile not found" || err.Error() == "sql: no rows in result set" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "User profile not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
		return
	}
	ctx.JSON(http.StatusOK, settings)
}

// CreateUserProfile creates a new user profile.
// @Summary Create a new user profile
// @Description Create a new user profile with the provided details
// @Tags user/profile
// @Accept json
// @Produce json
// @Param profile body types.UserProfile true "User profile data"
// @Success 201 {object} object{message=string,id=string} "Successfully created user profile"
// @Failure 400 {object} object{error=string} "Invalid request body"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/profile [post]
func (h *UserProfileHandler) CreateUserProfile(ctx *gin.Context) {
	var profile types.UserProfile

	if err := ctx.ShouldBindJSON(&profile); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
		return
	}

	if err := h.userProfile.CreateUserProfile(ctx, &profile); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create user profile: %v", err)})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{"message": "User profile created successfully", "id": profile.ID})
}

// UpdateUserProfile updates an existing user profile.
// @Summary Update an existing user profile
// @Description Update an existing user profile with the provided details
// @Tags user/profile
// @Accept json
// @Produce json
// @Param profile body types.UserProfile true "User profile data"
// @Success 200 {object} object{message=string,userID=string} "Successfully updated user profile"
// @Failure 400 {object} object{error=string} "Invalid request body"
// @Failure 500 {object} object{error=string} "Internal server error"
// @Router /user/profile [put]
func (h *UserProfileHandler) UpdateUserProfile(ctx *gin.Context) {
	var profile types.UserProfile

	if err := ctx.ShouldBindJSON(&profile); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
		return
	}

	if err := h.userProfile.UpdateUserProfile(ctx, &profile); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to update user profile: %v", err)})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User profile updated successfully", "userID": profile.UserID})
}
