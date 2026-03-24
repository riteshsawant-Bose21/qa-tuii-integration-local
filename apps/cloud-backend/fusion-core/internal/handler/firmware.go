package handler

import (
	"errors"
	"fmt"
	"strconv"

	response "github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/response"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/api/types"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/log"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/errorutil"
	"github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/utils/validation"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

type FirmwareUpdateHandler struct {
	firmware fusion.Firmware
}

// NewFirmwareUpdateHandler creates a new firmware update handler with the provided firmware service.
func NewFirmwareUpdateHandler(firmware fusion.Firmware) *FirmwareUpdateHandler {
	return &FirmwareUpdateHandler{
		firmware: firmware,
	}
}

// NotifyBundleUpload registers a new firmware bundle that has been uploaded to S3
// @Summary Notify Firmware Bundle Upload
// @Description Creates a new firmware bundle entry containing the manifest details. This is intended to be called by CI/CD pipelines after successfully uploading a bundle to S3. If there are no minimum version checks required, you MUST specify "0.0.0" for both min_prev_version and min_desktop_app_version.
// @Tags Firmware Update - CI/CD API
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body types.NotifyBundleUploadPayload true "Firmware bundle metadata including version, checksum, and manifest"
// @Success 200 {object} types.BundleResponse "Returns the created bundle details"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload or version already exists"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles [post]
func (h *FirmwareUpdateHandler) NotifyBundleUpload(c *gin.Context) {
	var payload types.NotifyBundleUploadPayload
	logger := log.GetLogger(c)

	if err := c.ShouldBindJSON(&payload); err != nil {
		logger.Error("Failed to bind NotifyBundleUpload payload", zap.Error(err))
		response.BadRequest(c, fmt.Sprintf("Invalid request payload: %s", err.Error()))
		return
	}

	if err := validation.ValidateFirmwareVersionFormat(payload.MinPrevVersion); err != nil {
		response.BadRequest(c, fmt.Sprintf("invalid min_required_prev_version: %s", err.Error()))
		return
	}
	if err := validation.ValidateFirmwareVersionFormat(payload.MinDesktopAppVersion); err != nil {
		response.BadRequest(c, fmt.Sprintf("invalid min_desktop_app_version: %s", err.Error()))
		return
	}
	if err := validation.ValidateFirmwareVersionFormat(payload.Version); err != nil {
		response.BadRequest(c, fmt.Sprintf("invalid version: %s", err.Error()))
		return
	}

	bundleResp, err := h.firmware.NotifyBundleUpload(c, &payload, logger)
	if err != nil {
		logger.Error("Failed to notify bundle upload", zap.Error(err))
		if errors.Is(err, errorutil.ErrVersionExists) {
			response.BadRequest(c, err.Error())
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, bundleResp)
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
// @Param approval_status query string false "Filter by approval status (PENDING, APPROVED, REVOKED)"
// @Success 200 {object} types.BundleListResponse "List of firmware bundles with pagination metadata"
// @Failure 400 {object} types.ErrorResponse "Invalid query parameters"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles [get]
func (h *FirmwareUpdateHandler) ListBundles(c *gin.Context) {
	logger := log.GetLogger(c)

	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "10")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		logger.Error("Failed to parse page parameter", zap.Error(err))
		response.BadRequest(c, "invalid page parameter")
		return
	}

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit < 1 || limit > 100 {
		logger.Error("Failed to parse limit parameter", zap.Error(err))
		response.BadRequest(c, "invalid limit parameter (must be 1-100)")
		return
	}

	var approvalStatus *string
	statusQuery, exists := c.GetQuery("approval_status")
	if exists {
		switch statusQuery {
		case types.BundleStatusPending, types.BundleStatusApproved, types.BundleStatusRevoked:
			approvalStatus = &statusQuery
		default:
			logger.Error("Invalid approval_status parameter", zap.String("status", statusQuery))
			response.BadRequest(c, "invalid approval_status parameter (must be PENDING, APPROVED, or REVOKED)")
			return
		}
	}

	resp, err := h.firmware.ListBundles(c, approvalStatus, page, limit)
	if err != nil {
		logger.Error("Failed to list bundles", zap.Error(err))
		response.InternalError(c)
		return
	}

	response.OK(c, resp)
}

// ApproveBundle approves a firmware bundle
// @Summary Approve Firmware Bundle
// @Description Approves a firmware bundle, making it available for deployment
// @Tags Firmware Update - Management API
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param action query string true "Action to perform" Enums(approve, revoke)
// @Success 204 "Bundle successfully approved or revoked"
// @Failure 400 {object} types.ErrorResponse "Invalid bundleID or request payload or bundle not approved"
// @Failure 404 {object} types.ErrorResponse "Bundle not found"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles/{bundleID}/approve [put]
func (h *FirmwareUpdateHandler) ApproveBundle(c *gin.Context) {
	approveStr := c.Query("action")
	logger := log.GetLogger(c)
	var approvalStatus string

	if approveStr == "" || (approveStr != "approve" && approveStr != "revoke") {
		logger.Error("Missing or invalid action query parameter")
		response.BadRequest(c, "missing or invalid action query parameter")
		return
	}

	if approveStr == "approve" {
		approvalStatus = types.BundleStatusApproved
	} else {
		approvalStatus = types.BundleStatusRevoked
	}

	bundleID := c.Param("bundleID")
	if !validation.IsValidUUID(bundleID) {
		logger.Error("Invalid bundleID", zap.String("bundleID", bundleID))
		response.BadRequest(c, "invalid bundleID")
		return
	}

	userAuth, exists := c.Get("user_auth")
	if !exists {
		logger.Error("User not found")
		response.Unauthorized(c, errorutil.MsgUnauthorized)
		return
	}
	user := userAuth.(*types.UserAuthorizationResponse)
	approvedBy := user.User.ID

	err := h.firmware.ApproveBundle(c, bundleID, approvedBy, approvalStatus, logger)
	if err != nil {
		logger.Error("Failed to approve bundle", zap.String("bundleID", bundleID), zap.Error(err))
		if errors.Is(err, errorutil.ErrBundleNotFound) {
			response.NotFound(c, "Bundle not found")
			return
		} else if errors.Is(err, errorutil.ErrBundleNotApproved) {
			response.BadRequest(c, "Bundle not approved")
			return
		}
		response.InternalError(c)
		return
	}

	response.NoContent(c)
}

// CheckForUpdate checks for available firmware updates for a device
// @Summary Check for Firmware Updates
// @Description Checks for the latest available firmware bundle. Steps performed:
// @Description 1. Query for latest approved bundle where: bundle.version > current_firmware_version AND bundle.min_prev_version <= current_firmware_version AND bundle.min_desktop_app_version <= current_desktop_app_version AND (channel matches prerelease OR prerelease IS NULL for stable)
// @Description 2. If found and current_firmware_version >= bundle.min_prev_version: return update_available=true with bundle details
// @Description 3. If not found or firmware too old: query for latest bundle where bundle is compatible with current firmware (ignoring desktop app version)
// @Description 4. If found and current_desktop_app_version < bundle.min_desktop_app_version: return update_available=true, app_update_required=true
// @Description 5. Otherwise: return update_available=false
// @Description
// @Description **Response Scenarios:**
// @Description
// @Description **Scenario 1 - Update Available:**
// @Description ```json
// @Description {"update_available": true, "app_update_required": false, "bundle_id": "uuid", "version": "2.5.6", "release_notes": "...", "min_required_prev_version": "2.0.0", "min_desktop_app_version": "1.4.0", "manifest_data": {}, "created_at": "..."}
// @Description ```
// @Description
// @Description **Scenario 2 - App Update Required:**
// @Description ```json
// @Description {"update_available": true, "app_update_required": true, "min_desktop_app_version": "2.0.0"}
// @Description ```
// @Description
// @Description **Scenario 3 - No Update Available:**
// @Description ```json
// @Description {"update_available": false, "app_update_required": false}
// @Description ```
// @Tags Firmware Update - Client API
// @Produce json
// @Param current_firmware_version query string true "Current firmware version (semver format)"
// @Param current_desktop_app_version query string true "Current desktop application version (semver format)"
// @Param channel query string false "Release channel: 'beta', 'alpha', etc. Omit for stable releases (prerelease IS NULL)"
// @Success 200 {object} types.CheckForUpdateResponse "Response varies by scenario - see description above"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/updates/check [get]
func (h *FirmwareUpdateHandler) CheckForUpdate(c *gin.Context) {
	var payload types.FirmwareUpdateRequest
	logger := log.GetLogger(c)

	if err := c.ShouldBindQuery(&payload); err != nil {
		logger.Error("Failed to bind CheckForUpdate query params", zap.Error(err))
		response.BadRequest(c, fmt.Sprintf("Invalid request parameters: %s", err.Error()))
		return
	}

	// Validate version formats
	if err := validation.ValidateFirmwareVersionFormat(payload.CurrentFirmwareVersion); err != nil {
		response.BadRequest(c, fmt.Sprintf("invalid current_firmware_version format: %s", err.Error()))
		return
	}
	if err := validation.ValidateFirmwareVersionFormat(payload.CurrentDesktopAppVersion); err != nil {
		response.BadRequest(c, fmt.Sprintf("invalid current_desktop_app_version format: %s", err.Error()))
		return
	}

	updateResp, err := h.firmware.CheckForUpdate(c, &payload, logger)
	if err != nil {
		logger.Error("Failed to check for update", zap.Error(err))
		response.InternalError(c)
		return
	}

	response.OK(c, updateResp)
}

// GetBundleDownloadURL generates a presigned download URL for a firmware bundle
// @Summary Get Firmware Bundle Download URL
// @Description Generates a presigned S3 URL for downloading a specific firmware bundle artifact. The URL is valid for 2 hours and includes the file checksum for integrity verification. Only approved bundles can be downloaded.
// @Tags Firmware Update - Client API
// @Accept json
// @Produce json
// @Param bundleID path string true "Unique identifier of the firmware bundle (UUID format)"
// @Success 200 {object} types.DownloadArtifactResponse "Presigned download URL and file checksum"
// @Failure 400 {object} types.ErrorResponse "Missing or invalid bundleID"
// @Failure 403 {object} types.ErrorResponse "Bundle not approved for download"
// @Failure 404 {object} types.ErrorResponse "Firmware bundle not found, or bundle artifact not found in storage"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/bundles/{bundleID}/request-download-url [get]
func (h *FirmwareUpdateHandler) GetBundleDownloadURL(c *gin.Context) {

	bundleID := c.Param("bundleID")
	if !validation.IsValidUUID(bundleID) {
		response.BadRequest(c, "invalid bundleID")
		return
	}

	logger := log.GetLogger(c)

	res, err := h.firmware.GetBundleDownloadURL(c, bundleID, logger)
	if err != nil {
		if errors.Is(err, errorutil.ErrBundleNotFound) {
			response.NotFound(c, "bundle not found")
			return
		}
		if errors.Is(err, errorutil.ErrBundleArtifactNotFound) {
			response.NotFound(c, "bundle artifact not found in storage")
			return
		}
		if errors.Is(err, errorutil.ErrBundleNotApprovedForDownload) {
			response.Forbidden(c, "bundle not approved for download")
			return
		}
		response.InternalError(c)
		return
	}

	response.OK(c, res)
}

// LogBundleUpdateStatus records the status of a firmware bundle update
// @Summary Log Bundle Update Status
// @Description Records the success or failure of a firmware bundle update installation.
// @Tags Firmware Update - Client API
// @Accept json
// @Produce json
// @Param request body types.LogBundleUpdateStatusPayload true "Bundle update status details"
// @Success 204 "Update status logged successfully"
// @Failure 400 {object} types.ErrorResponse "Invalid request payload"
// @Failure 500 {object} types.ErrorResponse "Internal server error"
// @Router /firmware/updates/status [post]
func (h *FirmwareUpdateHandler) LogBundleUpdateStatus(c *gin.Context) {
	logger := log.GetLogger(c)

	var payload types.LogBundleUpdateStatusPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		logger.Error("Failed to bind LogBundleUpdateStatus payload", zap.Error(err))
		response.BadRequest(c, fmt.Sprintf("Invalid request payload: %s", err.Error()))
		return
	}

	err := h.firmware.InsertBundleUpdateStatus(c.Request.Context(), &payload, logger)
	if err != nil {
		logger.Error("Failed to log bundle update status", zap.Error(err))
		response.InternalError(c)
		return
	}

	response.NoContent(c)
}
