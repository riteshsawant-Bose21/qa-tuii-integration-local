package handler

import (
	"errors"
	"strconv"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/validation"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
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

// InitiateRelease creates a new firmware release draft and generates a presigned S3 upload URL
// @Summary Initiate Firmware Release
// @Description Creates a new firmware release entry in draft status and returns a presigned S3 URL for uploading the firmware artifact. The upload URL is valid for 15 minutes.
// @Tags Firmware Update - Internal API
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body types.InitiateFirmwareReleasePayload true "Firmware release metadata including version, platform, release notes, etc."
// @Success 200 {object} types.FormwareReleaseInitiateResposne "Returns releaseId and presignedUrl for artifact upload"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload or version already exists"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/releases [post]
func (h *FirmwareUpdateHandler) InitiateRelease(ctx *gin.Context) {
	var payload types.InitiateFirmwareReleasePayload
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	if err := ctx.ShouldBindJSON(&payload); err != nil {
		logger.Error("Failed to bind InitiateRelease payload", zap.Error(err))
		response.BadRequest(ctx, "Invalid request payload: "+err.Error())
		return
	}

	ID, presignURL, err := h.firmware.InitiateRelease(ctx, &payload, logger)
	if err != nil {
		logger.Error("Failed to initiate firmware release", zap.Error(err))
		if errors.Is(err, errorutil.ErrVersionExists) {
			response.BadRequest(ctx, err.Error())
			return
		}
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, types.FormwareReleaseInitiateResposne{ReleaseID: ID, PresignedURL: presignURL})
}

// NotifyBundleUpload registers a new firmware bundle that has been uploaded to S3
// @Summary Notify Firmware Bundle Upload
// @Description Creates a new firmware bundle entry containing the manifest details. This is intended to be called by CI/CD pipelines after successfully uploading a bundle to S3.
// @Tags Firmware Update - CI/CD API
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body types.NotifyBundleUploadPayload true "Firmware bundle metadata including version, checksum, and manifest"
// @Success 200 {object} types.BundleResponse "Returns the created bundle details"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload or version already exists"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles [post]
func (h *FirmwareUpdateHandler) NotifyBundleUpload(ctx *gin.Context) {
	var payload types.NotifyBundleUploadPayload
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	if err := ctx.ShouldBindJSON(&payload); err != nil {
		logger.Error("Failed to bind NotifyBundleUpload payload", zap.Error(err))
		response.BadRequest(ctx, "Invalid request payload: "+err.Error())
		return
	}

	bundleResp, err := h.firmware.NotifyBundleUpload(ctx, &payload, logger)
	if err != nil {
		logger.Error("Failed to notify bundle upload", zap.Error(err))
		if errors.Is(err, errorutil.ErrVersionExists) {
			response.BadRequest(ctx, err.Error())
			return
		}
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, bundleResp)
}

// ListBundles retrieves firmware bundles with pagination and filtering
// @Summary List Firmware Bundles
// @Description Returns a paginated list of firmware bundles with optional filtering by approval status. Results are ordered by creation date in descending order.
// @Tags Firmware Update - Management API
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (default: 1)" default(1)
// @Param limit query int false "Items per page (default: 10, max: 100)" default(10)
// @Param is_approved query bool false "Filter by approval status (true or false)"
// @Success 200 {object} types.BundleListResponse "List of firmware bundles with pagination metadata"
// @Failure 400 {object} types.ErrorResponse "Invalid query parameters"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles [get]
func (h *FirmwareUpdateHandler) ListBundles(ctx *gin.Context) {
	page, _ := strconv.Atoi(ctx.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(ctx.DefaultQuery("limit", "10"))

	var isApproved *bool
	isApprovedQuery, exists := ctx.GetQuery("is_approved")
	if exists {
		parsed, err := strconv.ParseBool(isApprovedQuery)
		if err == nil {
			isApproved = &parsed
		}
	}

	resp, err := h.firmware.ListBundles(ctx, isApproved, page, limit)
	if err != nil {
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, resp)
}

// ApproveBundle approves a firmware bundle
// @Summary Approve Firmware Bundle
// @Description Approves a firmware bundle, making it available for deployment
// @Tags Firmware Update - Management API
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param bundleID path string true "Unique identifier of the firmware bundle"
// @Success 204 "Bundle successfully approved"
// @Failure 400 {object} types.ErrorResponse "Invalid bundleID or request payload"
// @Failure 404 {object} types.ErrorResponse "Bundle not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles/{bundleID}/approve [post]
func (h *FirmwareUpdateHandler) ApproveBundle(ctx *gin.Context) {
	bundleID := ctx.Param("bundleID")
	if bundleID == "" {
		response.BadRequest(ctx, "bundleID is required")
		return
	}

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
	approvedBy := user.User.ID

	err := h.firmware.ApproveBundle(ctx, bundleID, approvedBy, logger)
	if err != nil {
		logger.Error("Failed to approve bundle", zap.String("bundleID", bundleID), zap.Error(err))
		if errors.Is(err, errorutil.ErrBundleNotFound) {
			response.NotFound(ctx, "Bundle not found")
			return
		}
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// MakeReleaseAvailable publishes a firmware release to a deployment channel
// @Summary Make Release Available
// @Description Updates the release status to 'AVAILABLE' and creates a deployment entry for the specified channel, making the firmware available for devices to download
// @Tags Firmware Update - Internal API
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param releaseID path string true "Unique identifier of the firmware release"
// @Success 204 "Release successfully made available"
// @Failure 400 {object} types.ErrorResponse "Invalid releaseID or request payload"
// @Failure 404 {object} types.ErrorResponse "Release not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/releases/{releaseID}/mark-available [post]
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
		logger.Error("Failed to make release available", zap.String("releaseID", releaseID), zap.Error(err))
		if errors.Is(err, errorutil.ErrBundleNotFound) {
			response.NotFound(ctx, "Release not found")
			return
		}
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// ListReleases retrieves firmware releases with pagination and filtering
// @Summary List Firmware Releases
// @Description Returns a paginated list of firmware releases with optional filtering by platform and minimum version. Results are ordered by version in descending order.
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number (default: 1)" default(1)
// @Param limit query int false "Items per page (default: 10, max: 100)" default(10)
// @Param platform query string false "Filter by platform (e.g., 'amp-8x300', 'amp-4x150')"
// @Param min_version query string false "Minimum version filter - returns only versions newer than this (e.g., '1.0.1')"
// @Success 200 {object} types.FirmwareReleaseListResponse "List of firmware releases with pagination metadata"
// @Failure 400 {object} types.ErrorResponse "Invalid query parameters"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/releases [get]
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

// CheckUpdates checks if firmware updates are available for devices
// @Summary Check for Firmware Updates
// @Description Checks if newer firmware versions are available for a batch of devices based on their current versions, platform, and deployment channel. Returns update availability status and latest version information for each device.
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param request body types.CheckUpdateRequest true "List of devices with their current firmware versions and platform information"
// @Success 200 {object} types.CheckUpdateResponse "Update availability results for each device"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/updates/check [post]
func (h *FirmwareUpdateHandler) CheckUpdates(ctx *gin.Context) {
	var payload types.CheckUpdateRequest
	if err := ctx.ShouldBindJSON(&payload); err != nil {
		response.BadRequest(ctx, "Invalid request payload: "+err.Error())
		return
	}

	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	resp, err := h.firmware.CheckForUpdates(ctx, &payload)
	if err != nil {
		logger.Error("Failed to check for updates", zap.Error(err), zap.String("channel", payload.Channel))
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, resp)
}

// CheckForUpdate checks for available firmware updates for a device
// @Summary Check for Firmware Updates
// @Description Checks for the latest available and approved firmware bundle compatible with the client's current firmware and desktop application versions.
// @Tags Firmware Update - Client API
// @Accept json
// @Produce json
// @Param request body types.CheckForUpdateRequest true "Current firmware and desktop app versions"
// @Success 200 {object} types.CheckForUpdateResponse "Update availability and details"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/updates/check [post]
func (h *FirmwareUpdateHandler) CheckForUpdate(ctx *gin.Context) {
	var payload types.CheckForUpdateRequest
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	if err := ctx.ShouldBindJSON(&payload); err != nil {
		logger.Error("Failed to bind CheckForUpdate payload", zap.Error(err))
		response.BadRequest(ctx, "Invalid request payload: "+err.Error())
		return
	}

	updateResp, err := h.firmware.CheckForUpdate(ctx, &payload, logger)
	if err != nil {
		logger.Error("Failed to check for update", zap.Error(err))
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, updateResp)
}

// DownloadArtifact generates a presigned download URL for a firmware artifact
// @Summary Get Firmware Download URL
// @Description Generates a presigned S3 URL for downloading a specific firmware release artifact. The URL is valid for 15 minutes and includes the file checksum for integrity verification.
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param platform path string true "Platform identifier (e.g., 'amp-8x300')"
// @Param version path string true "Firmware version (e.g., '1.2.0')"
// @Success 200 {object} types.DownloadArtifactResponse "Presigned download URL and file checksum"
// @Failure 400 {object} types.ErrorResponse "Missing or invalid parameters"
// @Failure 404 {object} types.ErrorResponse "Firmware release not found for the specified platform and version"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/updates/{platform}/{version}/download [get]
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
		logger.Error("Failed to generate download URL", zap.String("platform", platform), zap.String("version", version), zap.Error(err))
		if errors.Is(err, errorutil.ErrBundleNotFound) {
			response.NotFound(ctx, "Firmware release not found for the specified platform and version")
			return
		}
		response.InternalError(ctx)
		return
	}

	response.OK(ctx, resp)
}

// LogFirmwareUpdate records a firmware update event from a device
// @Summary Log Firmware Update Event
// @Description Records the success or failure of a firmware update installation on a device. This endpoint is called by devices after attempting a firmware update.
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Param request body types.LogFirmwareUpdateRequest true "Firmware update log details including device ID, version, and status"
// @Success 202 "Update event logged successfully"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload or status value"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/updates/log [post]
func (h *FirmwareUpdateHandler) LogFirmwareUpdate(ctx *gin.Context) {
	var payload types.LogFirmwareUpdateRequest
	if err := ctx.ShouldBindJSON(&payload); err != nil {
		response.BadRequest(ctx, "Invalid request payload: "+err.Error())
		return
	}

	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	err := h.firmware.LogFirmwareUpdate(ctx, &payload)
	if err != nil {
		logger.Error("Failed to log firmware update",
			zap.String("device_id", payload.DeviceID),
			zap.String("version", payload.ReleaseVersion),
			zap.String("status", payload.Status),
			zap.Time("event_time", payload.EventTime),
			zap.Error(err))
		response.InternalError(ctx)
		return
	}

	response.Accepted(ctx)
}

// DeployRelease deploys a firmware release to a specific channel
// @Summary Deploy Firmware Release
// @Description Deploys an 'AVAILABLE' firmware release to a specific distribution channel (dev, testing, stable).
// @Tags Firmware Update
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param releaseID path string true "Unique identifier of the firmware release"
// @Param request body types.DeployReleasePayload true "Deployment target channel"
// @Success 204 "Release successfully deployed to channel"
// @Failure 400 {object} types.ErrorResponse "Invalid channel or releaseID"
// @Failure 404 {object} types.ErrorResponse "Release not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/releases/{releaseID}/deploy [post]
func (h *FirmwareUpdateHandler) DeployRelease(ctx *gin.Context) {
	releaseID := ctx.Param("releaseID")
	if releaseID == "" {
		response.BadRequest(ctx, "releaseID is required")
		return
	}

	var payload types.DeployReleasePayload
	loggerFromContext, exists := ctx.Get("logger")
	if !exists {
		response.InternalError(ctx)
		return
	}
	logger := loggerFromContext.(*zap.Logger)

	if err := ctx.ShouldBindJSON(&payload); err != nil {
		logger.Error("Failed to bind DeployRelease payload", zap.Error(err))
		response.BadRequest(ctx, "Invalid request payload: "+err.Error())
		return
	}

	err := h.firmware.DeployRelease(ctx, releaseID, payload.Channel, logger)
	if err != nil {
		logger.Error("Failed to deploy release", zap.String("releaseID", releaseID), zap.String("channel", payload.Channel), zap.Error(err))
		if errors.Is(err, errorutil.ErrBundleNotFound) {
			response.NotFound(ctx, "Release not found")
			return
		}
		if errors.Is(err, errorutil.ErrInvalidChannel) {
			response.BadRequest(ctx, "Invalid distribution channel")
			return
		}
		if errors.Is(err, errorutil.ErrInvalidReleaseStatus) {
			response.BadRequest(ctx, "Only AVAILABLE releases can be deployed")
			return
		}
		response.InternalError(ctx)
		return
	}

	response.NoContent(ctx)
}

// GetBundleDownloadURL generates a presigned download URL for a firmware bundle
// @Summary Get Firmware Bundle Download URL
// @Description Generates a presigned S3 URL for downloading a specific firmware bundle artifact. The URL is valid for 5 hours and includes the file checksum for integrity verification.
// @Tags Firmware Update - Client API
// @Accept json
// @Produce json
// @Param bundleId path string true "Unique identifier of the firmware bundle"
// @Success 200 {object} types.DownloadArtifactResponse "Presigned download URL and file checksum"
// @Failure 400 {object} types.ErrorResponse "Missing or invalid bundleId"
// @Failure 404 {object} types.ErrorResponse "Firmware bundle not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles/{bundleId}/download [get]
func (h *FirmwareUpdateHandler) GetBundleDownloadURL(c *gin.Context) {

	bundleID := c.Param("bundleId")
	if !validation.IsValidUUID(bundleID) {
		response.BadRequest(c, "invalid bundleId")
		return
	}

	logger, ok := c.MustGet("logger").(*zap.Logger)
	if !ok {
		response.InternalError(c)
		return
	}

	res, err := h.firmware.GetBundleDownloadURL(c.Request.Context(), bundleID, logger)
	if err != nil {
		if errors.Is(err, errorutil.ErrBundleNotFound) {
			response.NotFound(c, "bundle not found")
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, res)
}
