package types

import (
	"time"
)

const (
	BundleStatusPending  string = "PENDING"
	BundleStatusApproved string = "APPROVED"
	BundleStatusRevoked  string = "REVOKED"
)

type NotifyBundleUploadPayload struct {
	Version              string      `json:"version" binding:"required" example:"1.2.3-dev.4+build123"`
	Checksum             string      `json:"checksum" binding:"required"`
	ReleaseNotes         string      `json:"release_notes"`
	MinPrevVersion       string      `json:"min_prev_version" binding:"required" example:"0.0.0"`
	MinDesktopAppVersion string      `json:"min_desktop_app_version" binding:"required" example:"0.0.0"`
	S3Path               string      `json:"s3_path" binding:"required" example:"bundles/stable/bundle-1.2.3.zip"`
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
	ApprovalStatus       string    `json:"approval_status"`
	CreatedAt            time.Time `json:"created_at"`
	UpdatedAt            time.Time `json:"updated_at"`
}

type BundleListResponse struct {
	Bundles []BundleDetails `json:"bundles"`
	Total   int             `json:"total"`
	Page    int             `json:"page"`
	Limit   int             `json:"limit"`
}

type DownloadArtifactResponse struct {
	DownloadURL string `json:"download_url"`
	Checksum    string `json:"checksum"`
}

type FirmwareUpdateRequest struct {
	CurrentFirmwareVersion   string `form:"current_firmware_version" binding:"required"`
	CurrentDesktopAppVersion string `form:"current_desktop_app_version" binding:"required"`
	Channel                  string `form:"channel"` // Optional: "beta", "alpha", etc. Empty or omitted = stable (prerelease is null)
}

type FirmwareUpdateResponse struct {
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

type LogBundleUpdateStatusPayload struct {
	UpdateID              string    `json:"update_id" binding:"required,uuid"`
	ProjectID             string    `json:"project_id" binding:"required,uuid"`
	BundleVersion         string    `json:"bundle_version" binding:"required"`
	PreviousBundleVersion string    `json:"previous_bundle_version"`
	Status                string    `json:"status" binding:"required,oneof=INSTALL_SUCCESS INSTALL_FAIL"`
	DesktopAppVersion     string    `json:"desktop_app_version"`
	InstalledAt           time.Time `json:"installed_at" binding:"required"`
}
