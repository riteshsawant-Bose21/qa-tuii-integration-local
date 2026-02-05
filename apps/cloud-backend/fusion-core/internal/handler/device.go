package handler

import (
	"fmt"
	"net/http"

	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// DeviceHandler handles HTTP requests for device management.
type DeviceHandler struct {
	device fusion.Device
}

func NewDeviceHandler(device fusion.Device) *DeviceHandler {
	return &DeviceHandler{
		device: device,
	}
}

// CreateDevice creates a new device.
// @Summary Create a new device
// @Description Create a new device in the system
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param body body types.DeviceCreateRequest true "Device details"
// @Success 201 {object} types.DeviceCreateResponse "Successfully created device"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload or user not found or device Id already exists"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices [post]
func (h *DeviceHandler) CreateDevice(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")

	if !exists {
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}

	logger := loggerFromContext.(*zap.Logger)

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		fmt.Println(userAuth)
		ctx.JSON(http.StatusUnauthorized, types.ErrorResponse{Message: types.ErrMsgUnauthorized})
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	var p types.DeviceCreateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
		return
	}

	response, err := h.device.CreateDevice(ctx, &p, *user, logger)

	if err != nil {
		if err.Error() == types.ErrMsgDeviceAlreadyExists {
			ctx.JSON(http.StatusBadRequest, types.ErrorResponse{Message: err.Error()})
			return
		}
		// Internal server errors
		ctx.JSON(http.StatusInternalServerError, types.ErrorResponse{Message: types.ErrMsgInternalServerError})
		return
	}

	ctx.JSON(http.StatusCreated, response)
}
