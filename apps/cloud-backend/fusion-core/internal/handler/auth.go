package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
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
// @Success 200 {object} types.AuthTokenResponse "Tokens generated successfully"
// @Failure 400 {object} types.ErrorResponse "Bad request - username is required"
// @Failure 403 {object} types.ErrorResponse "auth automation endpoint is disabled"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /auth/automation/tokens [get]
func (h *AuthHandler) GetAuthTokensByResourceOwnerPassword(c *gin.Context) {
	// Get username from query parameter
	username := c.Query("username")
	if username == "" {
		response.BadRequest(c, "Username query parameter is required")
		return
	}

	// Get tokens from auth service
	tokens, err := h.authService.GetAuthTokensByResourceOwnerPassword(c.Request.Context(), username)
	if err != nil {
		// Check if it's a "disabled" error and return 403, otherwise 500
		if err.Error() == "Resource Owner Password flow is disabled" {
			response.Forbidden(c, "Resource Owner Password flow is disabled")
			return
		}

		response.SendJSON(c, http.StatusInternalServerError, types.ErrorResponse{
			ErrorMessage: "Failed to generate tokens: " + err.Error(),
		})
		return
	}

	// Return successful response
	response.OK(c, tokens)
}
