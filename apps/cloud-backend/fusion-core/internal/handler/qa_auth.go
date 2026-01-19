package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/auth"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
	httputils "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/http"
)

// QAAuthHandler handles QA authentication requests
type QAAuthHandler struct {
	qaTokenService *auth.QATokenService
	enabled        bool
}

// NewQAAuthHandler creates a new QA authentication handler
func NewQAAuthHandler(qaTokenService *auth.QATokenService, enabled bool) *QAAuthHandler {
	return &QAAuthHandler{
		qaTokenService: qaTokenService,
		enabled:        enabled,
	}
}

// GetTokens retrieves Auth0 tokens for QA testing.
// @Summary Get Auth0 tokens for QA testing
// @Description Get access and ID tokens for a user using Resource Owner Password flow (QA environment only)
// @Tags qa-auth
// @Accept json
// @Produce json
// @Param request body types.QATokenRequest true "Token Request"
// @Success 200 {object} types.QATokenSuccessResponse "Tokens generated successfully"
// @Failure 400 {object} types.ErrorResponse2 "Bad request - invalid input"
// @Failure 403 {object} types.ErrorResponse2 "QA auth endpoint is disabled"
// @Failure 500 {object} types.ErrorResponse2 "Internal server error"
// @Router /qa/auth/tokens [post]
func (h *QAAuthHandler) GetTokens(c *gin.Context) {
	// Check if QA auth is enabled
	if !h.enabled {
		c.JSON(http.StatusForbidden, types.ErrorResponse2{
			Message: "QA authentication endpoint is disabled",
			Code:    constants.CodeForbidden,
		})
		return
	}

	// Parse request body
	var req types.QATokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httputils.RespondWithBadRequest(c, "Invalid request body: "+err.Error())
		return
	}

	// Validate username
	if req.Username == "" {
		httputils.RespondWithBadRequest(c, "Username is required")
		return
	}

	// Get tokens from Auth0
	tokens, err := h.qaTokenService.GetTokensForUser(c.Request.Context(), req.Username)
	if err != nil {
		c.JSON(http.StatusInternalServerError, types.ErrorResponse2{
			Message: "Failed to generate tokens: " + err.Error(),
			Code:    constants.CodeInternalServerError,
		})
		return
	}

	// Return successful response
	c.JSON(http.StatusOK, types.QATokenSuccessResponse{
		Message: "Tokens generated successfully",
		Data:    tokens,
	})
}
