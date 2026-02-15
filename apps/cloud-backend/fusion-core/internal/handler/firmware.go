package handler

import (
	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"go.uber.org/zap"

	"github.com/gin-gonic/gin"
)

type FirmwareUpdateHandler struct {
	firmware fusion.Firmware
}

// NewUserHandler creates a new user handler with the provided user service.
func NewFirmwareUpdateHandler(firmware fusion.Firmware) *FirmwareUpdateHandler {
	return &FirmwareUpdateHandler{
		firmware: firmware,
	}
}

// initiateRelease inserts release details to firmware_releases table and returns a presigned URL to upload the artifacts to s3
// @Summary Initiate Firmware Release
// @Description Insert release details to firmware_releases table and return a presigned URL to upload the artifacts to s3
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param request body types.InitiateFirmwareReleasePayload true "Firmware release details"
// @Success 200 {object} types.FormwareReleaseInitiateResposne "Returns releaseId and presignedUrl"
// @Failure 400 {object} response.ErrorResponse
// @Failure 500 {object} response.ErrorResponse
// @Router /firmware/initiateRelease [post]
func (h *FirmwareUpdateHandler) InitiateRelease(ctx *gin.Context) {
	var payload types.InitiateFirmwareReleasePayload
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	if err := ctx.ShouldBindJSON(&payload); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}
	ID, presignURL, err := h.firmware.InitiateRelease(ctx, &payload, logger)
	if err != nil {
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, types.FormwareReleaseInitiateResposne{ReleaseID: ID, PresignedURL: presignURL})

}
