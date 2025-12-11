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
// @Security BearerAuth
// @Success 200 {object} types.UserProfile "Successfully retrieved user profile"
// @Failure 404 {object} types.GetUserProfile_statusNotFound "User profile not found / Invalid user ID format"
// @Failure 500 {object} types.InternalServerError "Internal server error"
// @Router /user/profile [get]
func (h *UserProfileHandler) GetUserProfile(ctx *gin.Context) {

	userAuth, _ := ctx.Get("user_auth")
	auth := userAuth.(*types.UserAuthorizationResponse)
	userID := auth.User.ID

	if _, err := uuid.Parse(userID); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
		return
	}

	userProfile, err := h.userProfile.GetUserProfile(ctx, userID)
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
func (h *UserProfileHandler) CreateUserProfile(ctx *gin.Context) {
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

	profileID, err := h.userProfile.CreateUserProfile(ctx, &profile)
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
func (h *UserProfileHandler) UpdateUserProfile(ctx *gin.Context) {
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

	if err := h.userProfile.UpdateUserProfile(ctx, &profile, profileID, auth.User.ID); err != nil {
		if err.Error() == "user profile not found" {
			ctx.JSON(http.StatusNotFound, gin.H{"error": "User profile not found"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to update user profile: %v", err)})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "User profile updated successfully"})
}
