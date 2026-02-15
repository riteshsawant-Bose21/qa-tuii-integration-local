package handler

import (
	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"go.uber.org/zap"

	"strconv"

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
// @Failure 400 {object} types.ErrorResponse
// @Failure 500 {object} types.ErrorResponse
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

// MakeReleaseAvailable updates the status of a release to available and creates a deployment
// @Summary Make Release Available
// @Description Updates the status of a release to available and creates a deployment
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param releaseID path string true "Release ID"
// @Success 204 "Success"
// @Failure 400 {object} types.ErrorResponse
// @Failure 500 {object} types.ErrorResponse
// @Router /firmware/{releaseID}/makeReleaseAvailable [post]
func (h *FirmwareUpdateHandler) MakeReleaseAvailable(ctx *gin.Context) {
	releaseID := ctx.Param("releaseID")
	if releaseID == "" {
		response.BadRequest(ctx, "releaseID is required")
		return
	}

	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	err := h.firmware.MakeReleaseAvailable(ctx, releaseID, logger)
	if err != nil {
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// ListReleases lists all firmware releases with pagination and filtering
// @Summary List Firmware Releases
// @Description List all firmware releases with pagination and filtering
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param page query int false "Page number"
// @Param limit query int false "Items per page"
// @Param platform query string false "Platform filter"
// @Success 200 {object} types.FirmwareReleaseListResponse
// @Failure 500 {object} types.ErrorResponse
// @Router /firmware [get]
func (h *FirmwareUpdateHandler) ListReleases(ctx *gin.Context) {
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "10"))
	platform := ctx.Query("platform")

	resp, err := h.firmware.ListReleases(ctx, platform, page, limit)
	if err != nil {
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, resp)
}
