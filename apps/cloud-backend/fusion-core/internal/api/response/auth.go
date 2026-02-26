// Package commonresponse provides common HTTP response utilities and structures.
package commonresponse

import (
	"github.com/gin-gonic/gin"

	errorutil "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
)

// RespondWithInvalidToken sends an invalid token response
func RespondWithInvalidToken(c *gin.Context) {
	Unauthorized(c, errorutil.MsgInvalidToken)
}

// RespondWithTokenExpired sends a token expired response
func RespondWithTokenExpired(c *gin.Context) {
	Unauthorized(c, errorutil.MsgTokenExpired)
}
