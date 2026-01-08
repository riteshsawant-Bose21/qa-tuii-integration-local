package http

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
)

// RespondWithSuccess sends a success response with generic data
func RespondWithSuccess(c *gin.Context, message string, data any) {
	c.JSON(http.StatusOK, types.SuccessResponse{
		Message: message,
		Data:    data,
	})
}

// RespondWithUserSuccess sends a success response with user data
func RespondWithUserSuccess(c *gin.Context, message string, data *types.User) {
	c.JSON(http.StatusOK, types.UserSuccessResponse{
		Message: message,
		Data:    data,
	})
}

// RespondWithAuthStatusSuccess sends a success response with auth status
func RespondWithAuthStatusSuccess(c *gin.Context, message string, data map[string]interface{}) {
	c.JSON(http.StatusOK, types.AuthStatusSuccessResponse{
		Message: message,
		Data:    data,
	})
}

// RespondWithBadRequest sends a bad request response
func RespondWithBadRequest(c *gin.Context, message string) {
	c.JSON(http.StatusBadRequest, types.ErrorResponse2{
		Message: message,
		Code:    constants.CodeBadRequest,
	})
}

// RespondWithInternalServerError sends an internal server error response
func RespondWithInternalServerError(c *gin.Context) {
	c.JSON(http.StatusInternalServerError, types.ErrorResponse2{
		Message: constants.MsgInternalServerError,
		Code:    constants.CodeInternalServerError,
	})
}

// RespondWithNotFound sends a not found response
func RespondWithNotFound(c *gin.Context, message string) {
	c.JSON(http.StatusNotFound, types.ErrorResponse2{
		Message: message,
		Code:    "NOT_FOUND",
	})
}

// RespondWithUserCreated sends a created response with user data
func RespondWithUserCreated(c *gin.Context, message string, data *types.User) {
	c.JSON(http.StatusCreated, types.UserSuccessResponse{
		Message: message,
		Data:    data,
	})
}
