package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	httputils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/http"
)

// AuthHandler handles authentication requests
type AuthHandler struct {
	authService fusion.Auth
}

// NewAuthHandler creates a new authentication handler
func NewAuthHandler(authService fusion.Auth) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

// GetAuthTokensByResourceOwnerPassword retrieves Auth0 tokens for automation testing.
// @Summary Get Auth0 tokens for automation testing
// @Description Get access and ID tokens for a user using Resource Owner Password flow (QA/Staging environment only)
// @Tags auth
// @Accept json
// @Produce json
// @Param username query string true "Username for token generation"
// @Success 200 {object} types.AuthTokenSuccessResponse "Tokens generated successfully"
// @Failure 400 {object} types.ErrorResponse2 "Bad request - username is required"
// @Failure 403 {object} types.ErrorResponse2 "auth automation endpoint is disabled"
// @Failure 500 {object} types.ErrorResponse2 "Internal server error"
// @Router /auth/automation/tokens [get]
func (h *AuthHandler) GetAuthTokensByResourceOwnerPassword(c *gin.Context) {
	// Get username from query parameter
	username := c.Query("username")
	if username == "" {
		httputils.RespondWithBadRequest(c, "Username query parameter is required")
		return
	}

	// Get tokens from auth service
	tokens, err := h.authService.GetAuthTokensByResourceOwnerPassword(c.Request.Context(), username)
	if err != nil {
		// Check if it's a "disabled" error and return 403, otherwise 500
		if err.Error() == "Resource Owner Password flow is disabled" {
			c.JSON(http.StatusForbidden, types.ErrorResponse2{
				Message: "Resource Owner Password flow is disabled",
				Code:    constants.CodeForbidden,
			})
			return
		}

		c.JSON(http.StatusInternalServerError, types.ErrorResponse2{
			Message: "Failed to generate tokens: " + err.Error(),
			Code:    constants.CodeInternalServerError,
		})
		return
	}

	// Return successful response
	c.JSON(http.StatusOK, types.AuthTokenSuccessResponse{
		Message: "Tokens generated successfully",
		Data:    tokens,
	})
}
