package types

import "time"

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
