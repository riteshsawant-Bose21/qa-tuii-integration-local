package auth

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
)

// RespondWithUnauthorized sends an unauthorized response
func RespondWithUnauthorized(c *gin.Context) {
	c.JSON(http.StatusUnauthorized, types.AuthErrorResponse{
		Message: constants.MsgUnauthorized,
		Code:    constants.CodeUnauthorized,
	})
}

// RespondWithForbidden sends a forbidden response
func RespondWithForbidden(c *gin.Context) {
	c.JSON(http.StatusForbidden, types.AuthErrorResponse{
		Message: constants.MsgAccessDenied,
		Code:    constants.CodeAccessDenied,
	})
}

// RespondWithInvalidToken sends an invalid token response
func RespondWithInvalidToken(c *gin.Context) {
	c.JSON(http.StatusUnauthorized, types.AuthErrorResponse{
		Message: constants.MsgInvalidToken,
		Code:    constants.CodeUnauthorized,
	})
}

// RespondWithTokenExpired sends a token expired response
func RespondWithTokenExpired(c *gin.Context) {
	c.JSON(http.StatusUnauthorized, types.AuthErrorResponse{
		Message: constants.MsgTokenExpired,
		Code:    constants.CodeUnauthorized,
	})
}

// RespondWithInsufficientPermissions sends an insufficient permissions response
func RespondWithInsufficientPermissions(c *gin.Context) {
	c.JSON(http.StatusForbidden, types.AuthErrorResponse{
		Message: constants.MsgInsufficientPermissions,
		Code:    constants.CodeAccessDenied,
	})
}
