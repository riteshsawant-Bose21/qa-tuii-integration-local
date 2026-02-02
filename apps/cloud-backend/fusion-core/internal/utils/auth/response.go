package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errors"
)

// RespondWithUnauthorized sends an unauthorized response
func RespondWithUnauthorized(c *gin.Context) {
	response.SendJSON(c, http.StatusUnauthorized, types.AuthErrorResponse{
		Message: errors.MsgUnauthorized,
		Code:    constants.CodeUnauthorized,
	})
}

// RespondWithForbidden sends a forbidden response
func RespondWithForbidden(c *gin.Context) {
	response.SendJSON(c, http.StatusForbidden, types.AuthErrorResponse{
		Message: errors.MsgAccessDenied,
		Code:    constants.CodeAccessDenied,
	})
}

// RespondWithInvalidToken sends an invalid token response
func RespondWithInvalidToken(c *gin.Context) {
	response.SendJSON(c, http.StatusUnauthorized, types.AuthErrorResponse{
		Message: errors.MsgInvalidToken,
		Code:    constants.CodeUnauthorized,
	})
}

// RespondWithTokenExpired sends a token expired response
func RespondWithTokenExpired(c *gin.Context) {
	response.SendJSON(c, http.StatusUnauthorized, types.AuthErrorResponse{
		Message: errors.MsgTokenExpired,
		Code:    constants.CodeUnauthorized,
	})
}

// RespondWithInsufficientPermissions sends an insufficient permissions response
func RespondWithInsufficientPermissions(c *gin.Context) {
	response.SendJSON(c, http.StatusForbidden, types.AuthErrorResponse{
		Message: errors.MsgInsufficientPermissions,
		Code:    constants.CodeAccessDenied,
	})
}
