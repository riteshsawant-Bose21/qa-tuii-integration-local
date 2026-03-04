package types

import (
	"time"
)

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
	Total   int             `json:"total"`
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
	CurrentFirmwareVersion   string `form:"current_firmware_version" binding:"required"`
	CurrentDesktopAppVersion string `form:"current_desktop_app_version" binding:"required"`
	Channel                  string `form:"channel"` // Optional: "beta", "alpha", etc. Empty or omitted = stable (prerelease is null)
}

// CheckForUpdateResponse represents a response when a firmware update is available
// @Description Full response when update is available with bundle details
type CheckForUpdateResponse struct {
	UpdateAvailable      bool                   `json:"update_available" example:"true"`
	AppUpdateRequired    bool                   `json:"app_update_required" example:"false"`
	BundleID             string                 `json:"bundle_id,omitempty" example:"72e1e23e-eb51-42c1-9ecb-bd7cf7304b60"`
	Version              string                 `json:"version,omitempty" example:"2.5.6"`
	ReleaseNotes         string                 `json:"release_notes,omitempty" example:"Bug fixes and performance improvements"`
	MinPrevVersion       string                 `json:"min_required_prev_version,omitempty" example:"2.0.0"`
	MinDesktopAppVersion string                 `json:"min_desktop_app_version,omitempty" example:"1.4.0"`
	ManifestData         map[string]interface{} `json:"manifest_data,omitempty"`
	CreatedAt            *time.Time             `json:"created_at,omitempty"`
}

// CheckForUpdateAppUpdateRequired represents a response when desktop app update is required before firmware update
// @Description Response when firmware update exists but desktop app needs to be updated first
type CheckForUpdateAppUpdateRequired struct {
	UpdateAvailable      bool   `json:"update_available" example:"true"`
	AppUpdateRequired    bool   `json:"app_update_required" example:"true"`
	MinDesktopAppVersion string `json:"min_desktop_app_version" example:"2.0.0"`
}

// CheckForUpdateNoUpdate represents a response when no update is available
// @Description Response when the system is up to date
type CheckForUpdateNoUpdate struct {
	UpdateAvailable   bool `json:"update_available" example:"false"`
	AppUpdateRequired bool `json:"app_update_required" example:"false"`
}

// CheckForUpdateResponses is a container to ensure all response types appear in Swagger Models
// @Description This type exists only for Swagger documentation. See individual response types below.
type CheckForUpdateResponses struct {
	// Scenario1UpdateAvailable is returned when a firmware update is available and compatible
	Scenario1UpdateAvailable CheckForUpdateResponse `json:"scenario_1_update_available"`
	// Scenario2AppUpdateRequired is returned when firmware update exists but desktop app needs upgrade first
	Scenario2AppUpdateRequired CheckForUpdateAppUpdateRequired `json:"scenario_2_app_update_required"`
	// Scenario3NoUpdate is returned when no update is available
	Scenario3NoUpdate CheckForUpdateNoUpdate `json:"scenario_3_no_update"`
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

// CheckForUpdateResponseStatusAppUpdateRequired CheckForUpdateResponseStatus = "APP_UPDATE_REQUIRED"
type LogBundleUpdateStatusPayload struct {
	UpdateID        string    `json:"update_id" binding:"required,uuid"`
	ProjectID       string    `json:"project_id" binding:"required,uuid"`
	BundleVersion   string    `json:"bundle_version" binding:"required"`
	PreviousVersion string    `json:"previous_version"`
	Status          string    `json:"status" binding:"required,oneof=INSTALL_SUCCESS INSTALL_FAIL"`
	LauncherVersion string    `json:"launcher_version"`
	InstalledAt     time.Time `json:"installed_at" binding:"required"`
}
