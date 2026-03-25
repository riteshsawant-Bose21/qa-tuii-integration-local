package commonresponse

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
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

// MultiStatus sends a 207 Multi-Status response
func MultiStatus(c *gin.Context, data any) {
	SendJSON(c, http.StatusMultiStatus, data)
}

// Accepted sends a 202 Accepted response
func Accepted(ctx *gin.Context) {
	ctx.Status(http.StatusAccepted)
}

// NoContent sends a 204 No Content response
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// BadRequest sends a 400 Bad Request response
func BadRequest(c *gin.Context, message string) {
	SendJSON(c, http.StatusBadRequest, types.ErrorResponse{ErrorMessage: message})
}

// Unauthorized sends a 401 Unauthorized response
func Unauthorized(c *gin.Context, message string) {
	SendJSON(c, http.StatusUnauthorized, types.ErrorResponse{ErrorMessage: message})
}

// Forbidden sends a 403 Forbidden response
func Forbidden(c *gin.Context, message string) {
	SendJSON(c, http.StatusForbidden, types.ErrorResponse{ErrorMessage: message})
}

// NotFound sends a 404 Not Found response
func NotFound(c *gin.Context, message string) {
	SendJSON(c, http.StatusNotFound, types.ErrorResponse{ErrorMessage: message})
}

// InternalError sends a 500 Internal Server Error response
func InternalError(c *gin.Context) {
	SendJSON(c, http.StatusInternalServerError, types.ErrorResponse{ErrorMessage: errorutil.MsgInternalServerError})
}
