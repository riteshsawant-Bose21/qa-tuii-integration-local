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
	FirmwareVersion      string    `json:"firmwareVersion"`
	ReleaseNotes         string    `json:"releaseNotes"`
	MinDesktopAppVersion string    `json:"minDesktopAppVersion"`
	HwCompatibility      string    `json:"hwCompatibility"`
	ApiVersion           string    `json:"apiVersion"`
	Created              time.Time `json:"created"`
	Updated              time.Time `json:"updated"`
}

type FirmwareReleaseListResponse struct {
	Releases []FirmwareReleaseDetails `json:"releases"`
	Total    int64                    `json:"total"`
	Page     int                      `json:"page"`
	Limit    int                      `json:"limit"`
}
