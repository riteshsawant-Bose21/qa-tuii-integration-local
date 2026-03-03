package types

import (
	"time"

	"github.com/aarondl/null/v8"
)

// LogFirmwareUpdateRequest represents a firmware update log entry from a device
type LogFirmwareUpdateRequest struct {
	DeviceID       string    `json:"device_id" binding:"required"`
	ReleaseVersion string    `json:"release_version" binding:"required"`
	Status         string    `json:"status" binding:"required,oneof=INSTALL_SUCCESS INSTALL_FAILED"`
	EventTime      time.Time `json:"event_time" binding:"required"`
}

type InitiateFirmwareReleasePayload struct {
	Checksum string                  `json:"checksum" binding:"required"`
	MetaData FirmwareReleaseMetaData `json:"metaData" binding:"required"`
}

type FirmwareReleaseMetaData struct {
	Platform             string `json:"platform" binding:"required"`
	FirmwareVersion      string `json:"firmwareVersion" binding:"required"`
	ReleaseNotes         string `json:"releaseNotes" binding:"required"`
	MinDesktopAppVersion string `json:"minDesktopAppVersion" binding:"required"`
	HwCompatibility      string `json:"hwCompatibility" binding:"required"`
	ApiVersion           string `json:"apiVersion" binding:"required"`
}

type FormwareReleaseInitiateResposne struct {
	ReleaseID    string `json:"releaseId"`
	PresignedURL string `json:"presignedUrl"`
}

type NotifyBundleUploadPayload struct {
	Version              string      `json:"version" binding:"required"`
	Checksum             string      `json:"checksum" binding:"required"`
	ReleaseNotes         string      `json:"release_notes"`
	MinPrevVersion       string      `json:"min_prev_version" binding:"required"`
	MinDesktopAppVersion string      `json:"min_desktop_app_version" binding:"required"`
	ManifestData         interface{} `json:"manifest_data" binding:"required"`
}

type BundleResponse struct {
	ID string `json:"id"`
}

type BundleDetails struct {
	ID                   string    `json:"id"`
	Version              string    `json:"version"`
	ReleaseNotes         string    `json:"release_notes,omitempty"`
	MinPrevVersion       string    `json:"min_prev_version"`
	MinDesktopAppVersion string    `json:"min_desktop_app_version"`
	IsApproved           bool      `json:"is_approved"`
	CreatedAt            time.Time `json:"created_at"`
	UpdatedAt            time.Time `json:"updated_at"`
}

type BundleListResponse struct {
	Bundles []BundleDetails `json:"bundles"`
	Total   int64           `json:"total"`
	Page    int             `json:"page"`
	Limit   int             `json:"limit"`
}

type FirmwareReleaseDetails struct {
	ID                   string    `json:"id"`
	Platform             string    `json:"platform"`
	FirmwareVersion      string    `json:"firmware_version"`
	Status               string    `json:"status"`
	ReleaseNotes         string    `json:"release_notes"`
	MinDesktopAppVersion string    `json:"min_desktop_app_version"`
	HwCompatibility      string    `json:"hw_compatibility"`
	ApiVersion           string    `json:"api_version"`
	Created              time.Time `json:"created"`
	Updated              time.Time `json:"updated"`
}

type FirmwareReleaseListResponse struct {
	Releases []FirmwareReleaseDetails `json:"releases"`
	Total    int64                    `json:"total"`
	Page     int                      `json:"page"`
	Limit    int                      `json:"limit"`
}

type DeviceUpdateCheckPayload struct {
	DeviceID               string `json:"device_id" binding:"required"`
	Platform               string `json:"platform" binding:"required"`
	CurrentFirmwareVersion string `json:"current_firmware_version" binding:"required"`
	HardwareRevision       string `json:"hardware_revision"`
}

type CheckUpdateRequest struct {
	Channel string                     `json:"channel" binding:"required"`
	Devices []DeviceUpdateCheckPayload `json:"devices" binding:"required"`
}

type DeviceUpdateResult struct {
	UpdateAvailable bool   `json:"update_available"`
	LatestVersion   string `json:"latest_version,omitempty"`
	ReleaseNotes    string `json:"release_notes,omitempty"`
}

type CheckUpdateResponse struct {
	Results map[string]DeviceUpdateResult `json:"results"`
}

type DownloadArtifactResponse struct {
	DownloadURL string `json:"download_url"`
	Checksum    string `json:"checksum"`
}

type DeployReleasePayload struct {
	Channel string `json:"channel" binding:"required"`
}

type CheckForUpdateRequest struct {
	CurrentFirmwareVersion   string `json:"current_firmware_version" validate:"required,semver"`
	CurrentDesktopAppVersion string `json:"current_desktop_app_version" validate:"required,semver"`
}

type CheckForUpdateResponse struct {
	UpdateAvailable      bool        `json:"update_available"`
	AppUpdateRequired    bool        `json:"app_update_required"`
	BundleID             null.String `json:"bundle_id,omitempty"`
	Version              null.String `json:"version,omitempty"`
	ReleaseNotes         null.String `json:"release_notes,omitempty"`
	MinPrevVersion       null.String `json:"min_required_prev_version,omitempty"`
	MinDesktopAppVersion string      `json:"min_desktop_app_version,omitempty"`
	ManifestData         null.JSON   `json:"manifest_data,omitempty"`
	CreatedAt            null.Time   `json:"created_at,omitempty"`
}

// FirmwareRelease represents a firmware release with its associated artifacts.
// Deprecated: use Bundle instead
type FirmwareRelease struct {
	ReleaseID            string `json:"release_id"`
	Platform             string `json:"platform"`
	FirmwareVersion      string `json:"firmware_version"`
	Status               string `json:"status"`
	ReleaseNotes         string `json:"release_notes"`
	MinDesktopAppVersion string `json:"min_desktop_app_version"`
	HwCompatibility      string `json:"hw_compatibility"`
	ApiVersion           string `json:"api_version"`
	Created              time.Time
	Updated              time.Time
}
