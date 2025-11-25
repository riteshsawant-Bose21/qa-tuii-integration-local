package http

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
)

// RespondWithSuccess sends a success response
func RespondWithSuccess(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, types.SuccessResponse{
		Message: message,
		Data:    data,
	})
}

// RespondWithError sends an error response
func RespondWithError(c *gin.Context, statusCode int, message, code string) {
	c.JSON(statusCode, types.ErrorResponse{
		Message: message,
		Code:    code,
	})
}

// RespondWithBadRequest sends a bad request response
func RespondWithBadRequest(c *gin.Context, message string) {
	c.JSON(http.StatusBadRequest, types.ErrorResponse{
		Message: message,
		Code:    constants.CodeBadRequest,
	})
}

// RespondWithInternalServerError sends an internal server error response
func RespondWithInternalServerError(c *gin.Context) {
	c.JSON(http.StatusInternalServerError, types.ErrorResponse{
		Message: constants.MsgInternalServerError,
		Code:    constants.CodeInternalServerError,
	})
}

// RespondWithNotFound sends a not found response
func RespondWithNotFound(c *gin.Context, message string) {
	c.JSON(http.StatusNotFound, types.ErrorResponse{
		Message: message,
		Code:    "NOT_FOUND",
	})
}

// RespondWithCreated sends a created response
func RespondWithCreated(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusCreated, types.SuccessResponse{
		Message: message,
		Data:    data,
	})
}
