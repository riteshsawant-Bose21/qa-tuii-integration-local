package handler

import (
	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/middleware"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// Error message constants for device handler.
const (
	errMsgInvalidRequestPayload = "Invalid request payload"
	errMsgDeviceIDRequired      = "device_id is required"
	errMsgCommandIDRequired     = "command_id is required"
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

	// Get user auth from context (populated by ExtractUserFromHeaders middleware)
	user, errAuth := middleware.GetUserAuth(ctx)
	if errAuth != nil {
		response.Unauthorized(ctx, errAuth.Error())
		return nil, nil, false
	}

	return logger, user, true
}

// handleDeviceError maps service errors to appropriate HTTP responses.
func (h *DeviceHandler) handleDeviceError(ctx *gin.Context, err error, logger *zap.Logger, operation string) {
	errMsg := err.Error()

	switch errMsg {
	case errorutil.ErrMsgDeviceNotFound, errorutil.ErrMsgProjectNotFound, errorutil.ErrMsgCommandNotFound:
		response.NotFound(ctx, errMsg)
	case errorutil.MsgUnauthorized:
		response.Unauthorized(ctx, errMsg)
	case errorutil.ErrMsgDeviceAlreadyExists, errorutil.ErrMsgDeviceAlreadyClaimed, errorutil.ErrMsgDeviceNotClaimed, errorutil.ErrMsgDeviceUniqueConstraint, errorutil.ErrMsgInvalidCSR:
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
		logger.Error(errMsgInvalidRequestPayload, zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	if req.SerialNumber == "" {
		response.BadRequest(ctx, "serial_number is required")
		return
	}

	res, err := h.device.CreateDevice(ctx, &req, *user, logger)
	if err != nil {
		h.handleDeviceError(ctx, err, logger, "create")
		return
	}

	response.Created(ctx, res)
}

// BulkCreateDevices creates multiple devices in a single request.
// @Summary Bulk create devices
// @Description Create multiple devices in a single request. Each device is processed independently; partial failures are reported per-device.
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param body body types.BulkDeviceCreateRequest true "List of devices to create"
// @Success 207 {object} types.BulkDeviceCreateResponse "Multi-status - results for each device"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 401 {object} types.ErrorResponse "Unauthorized - User not authorized"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices/bulk [post]
func (h *DeviceHandler) BulkCreateDevices(ctx *gin.Context) {
	logger, user, ok := h.getLoggerAndUser(ctx)
	if !ok {
		return
	}

	var req types.BulkDeviceCreateRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error(errMsgInvalidRequestPayload, zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	res, err := h.device.BulkCreateDevices(ctx, &req, *user, logger)
	if err != nil {
		h.handleDeviceError(ctx, err, logger, "bulk-create")
		return
	}

	response.MultiStatus(ctx, res)
}

// UpdateDevice updates an existing device.
// @Summary Update a device
// @Description Update device details (non-static fields only)
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param device_id path string true "Serial number of the device"
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
		response.BadRequest(ctx, errMsgDeviceIDRequired)
		return
	}

	var req types.DeviceUpdateRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error(errMsgInvalidRequestPayload, zap.Error(err))
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
// @Param device_id path string true "Serial number of the device"
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
		response.BadRequest(ctx, errMsgDeviceIDRequired)
		return
	}

	if err := h.device.ResetDevice(ctx, deviceID, *user, logger); err != nil {
		h.handleDeviceError(ctx, err, logger, "reset")
		return
	}

	response.NoContent(ctx)
}

// ClaimDevice claims an unclaimed device.
// @Summary Claim a device
// @Description Claim an unclaimed device for a user and project
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param device_id path string true "Serial number of the device"
// @Param body body types.DeviceClaimRequest true "Claim details"
// @Success 201 {object} types.DeviceClaimResponse "Successfully claimed device"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload or device already claimed"
// @Failure 401 {object} types.ErrorResponse "Unauthorized - User not authorized"
// @Failure 404 {object} types.ErrorResponse "Device or project not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices/{device_id}/claim [post]
func (h *DeviceHandler) ClaimDevice(ctx *gin.Context) {
	logger, user, ok := h.getLoggerAndUser(ctx)
	if !ok {
		return
	}

	deviceID := ctx.Param("device_id")
	if deviceID == "" {
		response.BadRequest(ctx, errMsgDeviceIDRequired)
		return
	}

	var req types.DeviceClaimRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error(errMsgInvalidRequestPayload, zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	res, err := h.device.ClaimDevice(ctx, deviceID, &req, *user, logger)
	if err != nil {
		h.handleDeviceError(ctx, err, logger, "claim")
		return
	}

	response.Created(ctx, res)
}

// RotateCertificate rotates the certificate for a device.
// @Summary Rotate device certificate
// @Description Creates a new certificate, attaches it to the device, and marks the old certificate as inactive
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param device_id path string true "Serial number of the device"
// @Param body body types.DeviceRotateCertRequest true "Certificate rotation details"
// @Success 200 {object} types.DeviceRotateCertResponse "Successfully rotated certificate"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 401 {object} types.ErrorResponse "Unauthorized - User not authorized"
// @Failure 404 {object} types.ErrorResponse "Device not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices/{device_id}/rotate-cert [post]
func (h *DeviceHandler) RotateCertificate(ctx *gin.Context) {
	logger, user, ok := h.getLoggerAndUser(ctx)
	if !ok {
		return
	}

	deviceID := ctx.Param("device_id")
	if deviceID == "" {
		response.BadRequest(ctx, errMsgDeviceIDRequired)
		return
	}

	var req types.DeviceRotateCertRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error(errMsgInvalidRequestPayload, zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	res, err := h.device.RotateCertificate(ctx, deviceID, &req, *user, logger)
	if err != nil {
		h.handleDeviceError(ctx, err, logger, "rotate-cert")
		return
	}

	response.OK(ctx, res)
}

// Command sends a command to the device cluster
// @Summary Send command to device cluster
// @Description Send a command to the device cluster
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param body body types.CommandRequest true "Command details"
// @Success 200 {object} types.CommandResponse "Successfully sent command"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid payload"
// @Failure 401 {object} types.ErrorResponse "Unauthorized - User not authorized"
// @Failure 404 {object} types.ErrorResponse "Project not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices/commands [post]
func (h *DeviceHandler) Command(ctx *gin.Context) {
	logger, user, ok := h.getLoggerAndUser(ctx)
	if !ok {
		return
	}

	var req types.CommandRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		logger.Error(errMsgInvalidRequestPayload, zap.Error(err))
		response.BadRequest(ctx, err.Error())
		return
	}

	commandID, err := h.device.Command(ctx, &req, *user, logger)
	if err != nil {
		h.handleDeviceError(ctx, err, logger, "command")
		return
	}

	commandResponse := types.CommandResponse{
		CommandID: commandID,
	}

	response.OK(ctx, commandResponse)
}

// GetCommandStatus retrieves the status of a command.
// @Summary Get command status
// @Description Get the status of a command by its ID
// @Tags devices
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param command_id path string true "Command ID"
// @Success 200 {object} types.CommandStatusResponse "Successfully retrieved command status"
// @Failure 400 {object} types.ErrorResponse "Bad request - Invalid command ID"
// @Failure 404 {object} types.ErrorResponse "Command not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /devices/commands/{command_id}/status [get]
func (h *DeviceHandler) GetCommandStatus(ctx *gin.Context) {
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	commandID := ctx.Param("command_id")
	if commandID == "" {
		response.BadRequest(ctx, errMsgCommandIDRequired)
		return
	}

	res, err := h.device.GetCommandStatus(ctx, commandID, logger)
	if err != nil {
		h.handleDeviceError(ctx, err, logger, "get-command-status")
		return
	}

	response.OK(ctx, res)
}
