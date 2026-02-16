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
// @Param min_version query string false "Minimum version (returns versions newer than this)"
// @Success 200 {object} types.FirmwareReleaseListResponse
// @Failure 500 {object} types.ErrorResponse
// @Router /firmware [get]
func (h *FirmwareUpdateHandler) ListReleases(ctx *gin.Context) {
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "10"))
	platform := ctx.Query("platform")
	minVersion := ctx.Query("min_version")

	resp, err := h.firmware.ListReleases(ctx, platform, page, limit, minVersion)
	if err != nil {
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, resp)
}

// CheckUpdates checks for firmware updates for a list of devices
// @Summary Check for Firmware Updates
// @Description Checks for firmware updates for a list of devices based on their current version and platform
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param request body types.CheckUpdateRequest true "Device details for update check"
// @Success 200 {object} types.CheckUpdateResponse
// @Failure 400 {object} types.ErrorResponse
// @Failure 500 {object} types.ErrorResponse
// @Router /firmware/updates/check [post]
func (h *FirmwareUpdateHandler) CheckUpdates(ctx *gin.Context) {
	var payload types.CheckUpdateRequest
	if err := ctx.ShouldBindJSON(&payload); err != nil {
		response.BadRequest(ctx, err.Error())
		return
	}

	resp, err := h.firmware.CheckForUpdates(ctx, &payload)
	if err != nil {
		// Log error?
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, resp)
}

// DownloadArtifact provides a presigned URL to download a firmware artifact
// @Summary Get Firmware Download URL
// @Description Provides a presigned S3 URL to download a specific firmware release artifact
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param platform path string true "Platform name"
// @Param version path string true "Firmware version"
// @Success 200 {object} types.DownloadArtifactResponse
// @Failure 400 {object} types.ErrorResponse
// @Failure 404 {object} types.ErrorResponse
// @Failure 500 {object} types.ErrorResponse
// @Router /firmware/getDownloadUrl/{platform}/{version} [get]
func (h *FirmwareUpdateHandler) DownloadArtifact(ctx *gin.Context) {
	platform := ctx.Param("platform")
	version := ctx.Param("version")

	if platform == "" || version == "" {
		response.BadRequest(ctx, "platform and version are required")
		return
	}

	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	resp, err := h.firmware.GetArtifactDownloadURL(ctx, platform, version, logger)
	if err != nil {
		if err.Error() == "release not found" {
			response.NotFound(ctx, "firmware release not found")
			return
		}
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, resp)
}
