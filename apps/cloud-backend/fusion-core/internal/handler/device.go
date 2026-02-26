package handler

import (
	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// DeviceHandler handles HTTP requests for device management.
type DeviceHandler struct {
	device fusion.Device
}

// NewDeviceHandler creates a new device handler instance.
func NewDeviceHandler(device fusion.Device) *DeviceHandler {
	return &DeviceHandler{device: device}
}

// ---------------------------------------------------------------------------
// Helper Functions
// ---------------------------------------------------------------------------

// getLoggerAndUser extracts the logger and user auth from the context.
// Returns nil values and sends appropriate response if extraction fails.
func (h *DeviceHandler) getLoggerAndUser(ctx *gin.Context) (*zap.Logger, *types.UserAuthorizationResponse, bool) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return nil, nil, false
	}
	logger := loggerFromContext.(*zap.Logger)

	userAuth, exists := ctx.Get("user_auth")
	if !exists {
		response.Unauthorized(ctx, errorutil.MsgUnauthorized)
		return nil, nil, false
	}
	user := userAuth.(*types.UserAuthorizationResponse)

	return logger, user, true
}

// handleDeviceError maps service errors to appropriate HTTP responses.
func (h *DeviceHandler) handleDeviceError(ctx *gin.Context, err error, logger *zap.Logger, operation string) {
	errMsg := err.Error()

	switch errMsg {
	case errorutil.ErrMsgDeviceNotFound, errorutil.ErrMsgProjectNotFound:
		response.NotFound(ctx, errMsg)
	case errorutil.MsgUnauthorized:
		response.Unauthorized(ctx, errMsg)
	case errorutil.ErrMsgDeviceAlreadyExists:
		response.BadRequest(ctx, errMsg)
	default:
		logger.Error("Device operation failed", zap.String("operation", operation), zap.Error(err))
		response.InternalError(ctx)
	}
}

// ---------------------------------------------------------------------------
// HTTP Handlers
// ---------------------------------------------------------------------------

// CreateDevice creates a new device.
// @Summary Create a new device
// @Description Create a new device in the system
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param body body types.DeviceCreateRequest true "Device details"
// @Success 201 {object} types.DeviceCreateResponse "Successfully created device"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload or device already exists"
// @Failure 401 {object} types.ErrorResponse "Unauthorized - User not authorized"
// @Failure 404 {object} types.ErrorResponse "Project not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices [post]
func (h *DeviceHandler) CreateDevice(ctx *gin.Context) {
	logger, user, ok := h.getLoggerAndUser(ctx)
	if !ok {
		return
	}

	var req types.DeviceCreateRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error("Invalid request payload", zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	res, err := h.device.CreateDevice(ctx, &req, *user, logger)
	if err != nil {
		h.handleDeviceError(ctx, err, logger, "create")
		return
	}

	response.Created(ctx, res)
}

// UpdateDevice updates an existing device.
// @Summary Update a device
// @Description Update device details (non-static fields only)
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param device_id path string true "Device ID"
// @Param body body types.DeviceUpdateRequest true "Device update details"
// @Success 204 "Successfully updated device"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 401 {object} types.ErrorResponse "Unauthorized - User not authorized to update this device"
// @Failure 404 {object} types.ErrorResponse "Device or project not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices/{device_id} [patch]
func (h *DeviceHandler) UpdateDevice(ctx *gin.Context) {
	logger, user, ok := h.getLoggerAndUser(ctx)
	if !ok {
		return
	}

	deviceID := ctx.Param("device_id")
	if deviceID == "" {
		response.BadRequest(ctx, "device_id is required")
		return
	}

	var req types.DeviceUpdateRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error("Invalid request payload", zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	if err := h.device.UpdateDevice(ctx, deviceID, &req, *user, logger); err != nil {
		h.handleDeviceError(ctx, err, logger, "update")
		return
	}

	response.NoContent(ctx)
}

// ResetDevice resets a device.
// @Summary Reset a device
// @Description Reset a device to factory settings
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param device_id path string true "Device ID"
// @Success 204 "Successfully reset device"
// @Failure 401 {object} types.ErrorResponse "Unauthorized - User not authorized to reset this device"
// @Failure 404 {object} types.ErrorResponse "Device not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices/{device_id}/reset [delete]
func (h *DeviceHandler) ResetDevice(ctx *gin.Context) {
	logger, user, ok := h.getLoggerAndUser(ctx)
	if !ok {
		return
	}

	deviceID := ctx.Param("device_id")
	if deviceID == "" {
		response.BadRequest(ctx, "device_id is required")
		return
	}

	if err := h.device.ResetDevice(ctx, deviceID, *user, logger); err != nil {
		h.handleDeviceError(ctx, err, logger, "reset")
		return
	}

	response.NoContent(ctx)
}
