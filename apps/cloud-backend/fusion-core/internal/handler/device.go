package handler

import (
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
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
		response.InternalError(ctx)
		return
	}

	logger := loggerFromContext.(*zap.Logger)

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, errorutil.MsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	var p types.DeviceCreateRequest
	if err := ctx.ShouldBindJSON(&p); err != nil {
		logger.Error("Failed to bind JSON", zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	res, err := h.device.CreateDevice(ctx, &p, *user, logger)

	if err != nil {
		logger.Error("Failed to create device", zap.Error(err))
		if err.Error() == errorutil.ErrMsgDeviceAlreadyExists {
			response.BadRequest(ctx, err.Error())
			return
		}
		// Internal server errors
		response.InternalError(ctx)
		return
	}

	response.Created(ctx, res)
}

