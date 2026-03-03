package middleware

import (
	"fmt"
	"strconv"

	commonresponse "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/gin-gonic/gin"
)

// ExtractUserFromHeaders extracts user context from headers and stores it in the Gin context
// This middleware should be applied to routes that require authentication
func ExtractUserFromHeaders() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		userID := ctx.GetHeader("X-User-ID")
		accountID := ctx.GetHeader("X-Account-ID")
		userEmail := ctx.GetHeader("X-User-Email")
		userRole := ctx.GetHeader("X-User-Role")
		accountName := ctx.GetHeader("X-Account-Name")
		accountType := ctx.GetHeader("X-Account-Type")
		roleID := ctx.GetHeader("X-Role-ID")

		// Validate required headers
		if userID == "" || accountID == "" || userEmail == "" || roleID == "" {
			commonresponse.Unauthorized(ctx, "Missing user identity headers")
			ctx.Abort()
			return
		}

		// Parse role ID
		intRoleID, err := strconv.Atoi(roleID)
		if err != nil {
			commonresponse.BadRequest(ctx, "Invalid role ID format")
			ctx.Abort()
			return
		}

		// Build UserAuthorizationResponse
		user := &types.UserAuthorizationResponse{
			User: types.UserInfo{
				ID:    userID,
				Email: userEmail,
			},
			Account: types.AccountInfo{
				ID:          accountID,
				Name:        accountName,
				Type:        accountType,
				Description: "",
			},
			Role: types.RoleInfo{
				ID:       intRoleID,
				RoleName: userRole,
			},
		}

		// Store in context for handlers to use
		ctx.Set("user_auth", user)
		ctx.Next()
	}
}

// Helper function to extract user auth from context
func GetUserAuth(ctx *gin.Context) (*types.UserAuthorizationResponse, error) {
	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		return nil, fmt.Errorf("user authentication not found in context")
	}

	user, ok := userAuth.(*types.UserAuthorizationResponse)
	if !ok {
		return nil, fmt.Errorf("invalid user authentication data")
	}

	return user, nil
}
