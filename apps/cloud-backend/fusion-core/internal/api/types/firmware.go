package types

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
