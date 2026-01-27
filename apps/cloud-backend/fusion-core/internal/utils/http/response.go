package http

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/constants"
)

// SendJSON sends a standard JSON response
func SendJSON(c *gin.Context, code int, data any) {
	c.JSON(code, data)
}

// OK sends a 200 OK response
func OK(c *gin.Context, data any) {
	SendJSON(c, http.StatusOK, data)
}

// Created sends a 201 Created response
func Created(c *gin.Context, data any) {
	SendJSON(c, http.StatusCreated, data)
}

// NoContent sends a 204 No Content response
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// BadRequest sends a 400 Bad Request response
func BadRequest(c *gin.Context, message string) {
	SendJSON(c, http.StatusBadRequest, types.ErrorResponse{Message: message})
}

// Unauthorized sends a 401 Unauthorized response
func Unauthorized(c *gin.Context, message string) {
	SendJSON(c, http.StatusUnauthorized, types.ErrorResponse{Message: message})
}

// Forbidden sends a 403 Forbidden response
func Forbidden(c *gin.Context, message string) {
	SendJSON(c, http.StatusForbidden, types.ErrorResponse{Message: message})
}

// NotFound sends a 404 Not Found response
func NotFound(c *gin.Context, message string) {
	SendJSON(c, http.StatusNotFound, types.ErrorResponse{Message: message})
}

// InternalError sends a 500 Internal Server Error response
func InternalError(c *gin.Context) {
	SendJSON(c, http.StatusInternalServerError, types.ErrorResponse{Message: constants.MsgInternalServerError})
}

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
// func RespondWithAuthStatusSuccess(c *gin.Context, message string, data map[string]interface{}) {
// 	c.JSON(http.StatusOK, types.AuthStatusSuccessResponse{
// 		Message: message,
// 		Data:    data,
// 	})
// }

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
